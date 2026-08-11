import Foundation

/// Veja docs/DEVICE_DETECTION.md — decidido uma vez a cada mudança de pareamento e
/// persistido, nunca recalculado de forma síncrona no caminho crítico de toque-até-som.
enum PlaybackStrategy: String, Codable {
    /// Cenário A: o relógio reproduz áudio em cache localmente direto para uma caixa Bluetooth pareada.
    case direct

    /// Cenário B: o relógio envia um comando leve para o celular, que reproduz o áudio.
    case relay

    /// Nenhuma saída utilizável a partir do relógio sozinho; a UI deve direcionar o usuário ao celular.
    case phoneOnly
}

enum AudioCodec: String, Codable {
    case sbc, aac, aptx, aptxHd, lc3
}

/// Espelha `DeviceCapabilityProfile` de docs/DEVICE_DETECTION.md. Preenchido no dispositivo
/// usando introspecção via AVAudioSession (veja Data/Companion) — aqui é apenas um contêiner
/// de dados.
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
