package com.togplay.vaimarcia.wear.playback

import com.togplay.vaimarcia.wear.domain.PlaybackStrategy
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Single entry point the presentation layer calls on button tap. Holds the
 * already-resolved strategy (set at boot / pairing-change, see PlaybackStrategyResolver)
 * and routes to the matching engine — no per-tap strategy computation.
 */
@Singleton
class PlaybackController @Inject constructor(
    private val strategyResolver: PlaybackStrategyResolver,
    private val directEngine: DirectPlaybackEngine,
    private val relayDispatcher: RelayPlaybackDispatcher,
) {
    private val _strategy = MutableStateFlow(PlaybackStrategy.PHONE_ONLY)
    val strategy: StateFlow<PlaybackStrategy> = _strategy.asStateFlow()

    suspend fun refreshStrategy() {
        _strategy.value = strategyResolver.resolve()
    }

    suspend fun play(audioId: String): PlaybackResult = when (_strategy.value) {
        PlaybackStrategy.DIRECT -> directEngine.play(audioId)
        PlaybackStrategy.RELAY -> relayDispatcher.play(audioId)
        PlaybackStrategy.PHONE_ONLY -> PlaybackResult.Failed("phone_only_no_watch_output")
    }
}
