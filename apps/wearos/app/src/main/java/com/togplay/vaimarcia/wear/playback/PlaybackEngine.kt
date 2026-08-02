package com.togplay.vaimarcia.wear.playback

/** Common contract implemented by both DIRECT and RELAY engines so the UI layer never
 *  branches on strategy — it just asks the resolver-selected engine to play. */
interface PlaybackEngine {
    suspend fun play(audioId: String): PlaybackResult
}

sealed class PlaybackResult {
    data object Started : PlaybackResult()
    data class Failed(val reason: String) : PlaybackResult()
}
