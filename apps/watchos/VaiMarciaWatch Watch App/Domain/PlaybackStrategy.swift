import Foundation

/// See docs/DEVICE_DETECTION.md — decided once per pairing change and persisted, never
/// recomputed synchronously in the tap-to-sound critical path.
enum PlaybackStrategy: String, Codable {
    /// Cenário A: watch plays locally cached audio straight to a paired Bluetooth speaker.
    case direct

    /// Cenário B: watch sends a lightweight command to the phone, which plays the audio.
    case relay

    /// No usable output at all from the watch alone; UI should route the user to the phone.
    case phoneOnly
}

enum AudioCodec: String, Codable {
    case sbc, aac, aptx, aptxHd, lc3
}

/// Mirrors `DeviceCapabilityProfile` from docs/DEVICE_DETECTION.md. Populated on-device
/// using AVAudioSession introspection (see Data/Companion) — pure data holder here.
struct DeviceCapabilityProfile: Codable {
    let manufacturer: String
    let model: String
    let osFamily: String
    let osVersion: String
    let hasBluetoothClassicAudio: Bool
    let hasBleAudioSupport: Bool
    let supportedCodecs: Set<AudioCodec>
    let canPlayArbitraryLocalAudio: Bool
    let hasPersistentCompanionChannel: Bool
    let estimatedLatencyMs: Int

    init(
        manufacturer: String = "Apple",
        model: String,
        osFamily: String = "watchos",
        osVersion: String,
        hasBluetoothClassicAudio: Bool,
        hasBleAudioSupport: Bool,
        supportedCodecs: Set<AudioCodec>,
        canPlayArbitraryLocalAudio: Bool,
        hasPersistentCompanionChannel: Bool,
        estimatedLatencyMs: Int
    ) {
        self.manufacturer = manufacturer
        self.model = model
        self.osFamily = osFamily
        self.osVersion = osVersion
        self.hasBluetoothClassicAudio = hasBluetoothClassicAudio
        self.hasBleAudioSupport = hasBleAudioSupport
        self.supportedCodecs = supportedCodecs
        self.canPlayArbitraryLocalAudio = canPlayArbitraryLocalAudio
        self.hasPersistentCompanionChannel = hasPersistentCompanionChannel
        self.estimatedLatencyMs = estimatedLatencyMs
    }
}
