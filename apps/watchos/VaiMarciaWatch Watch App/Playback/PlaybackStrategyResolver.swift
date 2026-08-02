import AVFoundation
import Foundation
import WatchKit

/// Implements the decision algorithm from docs/DEVICE_DETECTION.md §"Algoritmo" step 3.
/// Resolved once per launch / pairing-change event and cached — never on the tap-to-sound
/// path (see docs/ARCHITECTURE.md §4).
final class PlaybackStrategyResolver {
    private let connectivity: WatchConnectivityManager

    init(connectivity: WatchConnectivityManager = .shared) {
        self.connectivity = connectivity
    }

    func resolve() -> PlaybackStrategy {
        decide(probeLocalCapabilities())
    }

    func decide(_ profile: DeviceCapabilityProfile) -> PlaybackStrategy {
        if profile.hasBluetoothClassicAudio || profile.hasBleAudioSupport {
            return profile.canPlayArbitraryLocalAudio ? .direct : .relay
        }
        if profile.hasPersistentCompanionChannel {
            return .relay
        }
        return .phoneOnly
    }

    /// docs/DEVICE_DETECTION.md step 2 — watchOS probe: `AVAudioSession.currentRoute` plus
    /// checking for a directly-paired Bluetooth output; watchOS ≥ 9 on Apple Watch
    /// Ultra/Series 8+ with direct Bluetooth audio reports `hasBluetoothClassicAudio = true`.
    private func probeLocalCapabilities() -> DeviceCapabilityProfile {
        let session = AVAudioSession.sharedInstance()
        let hasDirectBluetoothRoute = session.currentRoute.outputs.contains { output in
            output.portType == .bluetoothA2DP || output.portType == .bluetoothLE
        }
        let supportsDirectHardware = watchSupportsDirectBluetoothAudio()

        return DeviceCapabilityProfile(
            model: WKInterfaceDevice.current().model,
            osVersion: WKInterfaceDevice.current().systemVersion,
            hasBluetoothClassicAudio: hasDirectBluetoothRoute && supportsDirectHardware,
            hasBleAudioSupport: false, // LC3/LE Audio detection needs device-specific data not yet in the compatibility table
            supportedCodecs: [.aac, .sbc],
            canPlayArbitraryLocalAudio: true, // AVAudioPlayer plays arbitrary local files on all watchOS versions we target
            hasPersistentCompanionChannel: connectivity.isReachable,
            estimatedLatencyMs: supportsDirectHardware ? 70 : 130,
        )
    }

    /// Static allow-list per docs/DEVICE_DETECTION.md compatibility table: watchOS does not
    /// expose a runtime API to ask "does this hardware have a Bluetooth Classic audio radio",
    /// so identifying Ultra/Series 8+ vs SE/≤7 relies on matching against known model
    /// identifiers, refreshed as Apple ships new watch generations.
    private func watchSupportsDirectBluetoothAudio() -> Bool {
        let identifier = watchModelIdentifier()
        return DirectAudioCapableModels.identifiers.contains(identifier)
    }

    private func watchModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { partial, element in
            guard let value = element.value as? Int8, value != 0 else { return partial }
            return partial + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

/// Watch5,x = Series 8, Watch6,x = Ultra/Series 9-class families in Apple's identifier
/// scheme; kept as a small static table rather than an SDK capability query per
/// docs/DEVICE_DETECTION.md (the OS doesn't expose "has direct Bluetooth audio radio").
private enum DirectAudioCapableModels {
    static let identifiers: Set<String> = [
        "Watch6,1", "Watch6,2", "Watch6,3", "Watch6,4", // Series 8
        "Watch6,6", "Watch6,7", "Watch6,8", "Watch6,9", // Ultra
        "Watch7,1", "Watch7,2", "Watch7,3", "Watch7,4", // Series 9
        "Watch7,5", // Ultra 2
    ]
}
