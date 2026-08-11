package com.togplay.vaimarcia.wear.playback

import com.togplay.vaimarcia.wear.domain.PlaybackStrategy
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Único ponto de entrada que a camada de apresentação chama ao tocar em um botão. Guarda a
 * estratégia já resolvida (definida na inicialização / mudança de pareamento, veja
 * PlaybackStrategyResolver) e roteia para o engine correspondente — sem cálculo de estratégia
 * a cada toque.
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
