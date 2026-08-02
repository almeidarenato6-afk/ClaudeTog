package com.togplay.vaimarcia.wear.playback

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.pm.PackageManager
import com.togplay.vaimarcia.wear.data.companion.WearCompanionClient
import com.togplay.vaimarcia.wear.domain.AudioCodec
import com.togplay.vaimarcia.wear.domain.DeviceCapabilityProfile
import com.togplay.vaimarcia.wear.domain.PlaybackStrategy
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.suspendCancellableCoroutine
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume

/**
 * Implements the decision algorithm from docs/DEVICE_DETECTION.md §"Algoritmo" step 3.
 * Resolved once per boot / pairing-change event and cached — never on the tap-to-sound path
 * (see docs/ARCHITECTURE.md §4).
 */
@Singleton
class PlaybackStrategyResolver @Inject constructor(
    @ApplicationContext private val context: Context,
    private val companionClient: WearCompanionClient,
) {

    suspend fun resolve(): PlaybackStrategy {
        val profile = probeLocalCapabilities()
        return decide(profile)
    }

    internal fun decide(profile: DeviceCapabilityProfile): PlaybackStrategy = when {
        profile.hasBluetoothClassicAudio || profile.hasBleAudioSupport ->
            if (profile.canPlayArbitraryLocalAudio) PlaybackStrategy.DIRECT else PlaybackStrategy.RELAY
        profile.hasPersistentCompanionChannel -> PlaybackStrategy.RELAY
        else -> PlaybackStrategy.PHONE_ONLY
    }

    /**
     * docs/DEVICE_DETECTION.md step 2 — Wear OS probe: `BluetoothAdapter.getProfileProxy(A2DP)`
     * plus verification that a device is connected directly to *this* watch (not relayed
     * through the phone), and `PackageManager.hasSystemFeature(FEATURE_AUDIO_OUTPUT)` for
     * arbitrary local-audio playback capability.
     */
    private suspend fun probeLocalCapabilities(): DeviceCapabilityProfile {
        val adapter = BluetoothAdapter.getDefaultAdapter()
        val hasA2dpConnectedDevice = adapter?.let { probeA2dpConnected(it) } ?: false
        val canPlayLocalAudio = context.packageManager.hasSystemFeature(PackageManager.FEATURE_AUDIO_OUTPUT)

        return DeviceCapabilityProfile(
            manufacturer = android.os.Build.MANUFACTURER,
            model = android.os.Build.MODEL,
            osVersion = android.os.Build.VERSION.RELEASE,
            hasBluetoothClassicAudio = hasA2dpConnectedDevice,
            hasBleAudioSupport = false, // LE Audio detection needs BluetoothLeAudioCodecConfig, API 33+; TODO
            supportedCodecs = setOf(AudioCodec.SBC, AudioCodec.AAC),
            canPlayArbitraryLocalAudio = canPlayLocalAudio,
            hasPersistentCompanionChannel = companionClient.isPhoneReachable(),
            estimatedLatencyMs = if (hasA2dpConnectedDevice) 60 else 120,
        )
    }

    private suspend fun probeA2dpConnected(adapter: BluetoothAdapter): Boolean =
        suspendCancellableCoroutine { continuation ->
            adapter.getProfileProxy(
                context,
                object : BluetoothProfile.ServiceListener {
                    override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                        val connected = (proxy as? BluetoothA2dp)?.connectedDevices?.isNotEmpty() ?: false
                        adapter.closeProfileProxy(BluetoothProfile.A2DP, proxy)
                        if (continuation.isActive) continuation.resume(connected)
                    }

                    override fun onServiceDisconnected(profile: Int) {
                        if (continuation.isActive) continuation.resume(false)
                    }
                },
                BluetoothProfile.A2DP,
            )
        }
}
