package com.togplay.vaimarcia.wear.playback

import com.togplay.vaimarcia.wear.data.companion.WearCompanionClient
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Scenario B: dispatches the play command to the phone over the persistent Data Layer
 * connection. The phone already has the audio cached and plays it to the paired Bluetooth
 * speaker — from the user's perspective this is indistinguishable from Scenario A.
 */
@Singleton
class RelayPlaybackDispatcher @Inject constructor(
    private val companionClient: WearCompanionClient,
) : PlaybackEngine {

    override suspend fun play(audioId: String): PlaybackResult {
        val delivered = companionClient.sendPlayCommand(audioId)
        return if (delivered) {
            PlaybackResult.Started
        } else {
            PlaybackResult.Failed("phone_unreachable")
        }
    }
}
