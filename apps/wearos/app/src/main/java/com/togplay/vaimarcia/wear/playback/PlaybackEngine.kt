package com.togplay.vaimarcia.wear.playback

/** Contrato comum implementado tanto pelo engine DIRECT quanto pelo RELAY, para que a
 *  camada de UI nunca precise ramificar com base na estratégia — ela apenas pede ao engine
 *  selecionado pelo resolver para reproduzir. */
interface PlaybackEngine {
    suspend fun play(audioId: String): PlaybackResult
}

sealed class PlaybackResult {
    data object Started : PlaybackResult()
    data class Failed(val reason: String) : PlaybackResult()
}
