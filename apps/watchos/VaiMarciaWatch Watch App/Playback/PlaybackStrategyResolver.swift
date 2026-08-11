import AVFoundation
import Foundation
import WatchKit

/// Implementa o algoritmo de decisão de docs/DEVICE_DETECTION.md §"Algoritmo" passo 3.
/// Resolvido uma vez por evento de inicialização / mudança de pareamento e mantido em cache —
/// nunca no caminho de toque-até-som (veja docs/ARCHITECTURE.md §4).
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

    /// docs/DEVICE_DETECTION.md passo 2 — sondagem watchOS: `AVAudioSession.currentRoute`
    /// mais verificação de uma saída Bluetooth diretamente pareada; watchOS ≥ 9 em Apple
    /// Watch Ultra/Series 8+ com áudio Bluetooth direto reporta `hasBluetoothClassicAudio = true`.
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
            hasBleAudioSupport: false, // Detecção de LC3/LE Audio precisa de dados específicos do dispositivo ainda não presentes na tabela de compatibilidade
            supportedCodecs: [.aac, .sbc],
            canPlayArbitraryLocalAudio: true, // AVAudioPlayer reproduz arquivos locais arbitrários em todas as versões de watchOS que suportamos
            hasPersistentCompanionChannel: connectivity.isReachable,
            estimatedLatencyMs: supportsDirectHardware ? 70 : 130,
        )
    }

    /// Lista de permissão estática conforme a tabela de compatibilidade de
    /// docs/DEVICE_DETECTION.md: o watchOS não expõe uma API em tempo de execução para
    /// perguntar "este hardware tem rádio de áudio Bluetooth Classic", então identificar
    /// Ultra/Series 8+ vs SE/≤7 depende de comparar com identificadores de modelo conhecidos,
    /// atualizados conforme a Apple lança novas gerações de relógio.
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

/// Watch5,x = Series 8, Watch6,x = famílias da classe Ultra/Series 9 no esquema de
/// identificadores da Apple; mantido como uma pequena tabela estática em vez de uma consulta
/// de capacidade via SDK, conforme docs/DEVICE_DETECTION.md (o SO não expõe "tem rádio de
/// áudio Bluetooth direto").
private enum DirectAudioCapableModels {
    static let identifiers: Set<String> = [
        "Watch6,1", "Watch6,2", "Watch6,3", "Watch6,4", // Series 8
        "Watch6,6", "Watch6,7", "Watch6,8", "Watch6,9", // Ultra
        "Watch7,1", "Watch7,2", "Watch7,3", "Watch7,4", // Series 9
        "Watch7,5", // Ultra 2
    ]
}
