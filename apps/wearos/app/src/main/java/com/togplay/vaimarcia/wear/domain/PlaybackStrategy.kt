package com.togplay.vaimarcia.wear.domain

/**
 * See docs/DEVICE_DETECTION.md — decided once per pairing change and persisted, never
 * recomputed synchronously in the tap-to-sound critical path.
 */
enum class PlaybackStrategy {
    /** Cenário A: watch plays locally cached audio straight to a paired Bluetooth speaker. */
    DIRECT,

    /** Cenário B: watch sends a lightweight command to the phone, which plays the audio. */
    RELAY,

    /** No usable output at all from the watch alone; UI should route the user to the phone. */
    PHONE_ONLY,
}

/**
 * Mirrors `DeviceCapabilityProfile` from docs/DEVICE_DETECTION.md. Populated on-device using
 * BluetoothAdapter/PackageManager introspection (see data/companion) — pure data holder here.
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
