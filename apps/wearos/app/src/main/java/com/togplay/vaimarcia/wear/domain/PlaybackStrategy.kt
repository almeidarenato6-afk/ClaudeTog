package com.togplay.vaimarcia.wear.domain

/**
 * Veja docs/DEVICE_DETECTION.md — decidido uma vez a cada mudança de pareamento e persistido,
 * nunca recalculado de forma síncrona no caminho crítico de toque-até-som.
 */
enum class PlaybackStrategy {
    /** Cenário A: o relógio reproduz áudio em cache localmente direto para uma caixa Bluetooth pareada. */
    DIRECT,

    /** Cenário B: o relógio envia um comando leve para o celular, que reproduz o áudio. */
    RELAY,

    /** Nenhuma saída utilizável a partir do relógio sozinho; a UI deve direcionar o usuário ao celular. */
    PHONE_ONLY,
}

/**
 * Espelha `DeviceCapabilityProfile` de docs/DEVICE_DETECTION.md. Preenchido no dispositivo
 * usando introspecção via BluetoothAdapter/PackageManager (veja data/companion) — aqui é apenas
 * um contêiner de dados.
 */
data class DeviceCapabilityProfile(
    val manufacturer: String,
    val model: String,
    val osFamily: String = "wearos",
    val osVersion: String,
    val hasBluetoothClassicAudio: Boolean,
    val hasBleAudioSupport: Boolean,
    val supportedCodecs: Set<AudioCodec>,
    val canPlayArbitraryLocalAudio: Boolean,
    val hasPersistentCompanionChannel: Boolean,
    val estimatedLatencyMs: Int,
)

enum class AudioCodec { SBC, AAC, APTX, APTX_HD, LC3 }
