package com.togplay.vaimarcia.wear.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.togplay.vaimarcia.wear.domain.Category
import com.togplay.vaimarcia.wear.playback.PlaybackController
import com.togplay.vaimarcia.wear.playback.PlaybackResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class GameModeUiState(
    val lastTapFeedback: String? = null,
)

@HiltViewModel
class GameModeViewModel @Inject constructor(
    private val playbackController: PlaybackController,
) : ViewModel() {

    private val _uiState = MutableStateFlow(GameModeUiState())
    val uiState: StateFlow<GameModeUiState> = _uiState.asStateFlow()

    val strategy = playbackController.strategy

    init {
        viewModelScope.launch { playbackController.refreshStrategy() }
    }

    /** Um toque = um clipe a partir do audioId padrão/próximo da categoria informada. */
    fun onCategoryTapped(category: Category) {
        viewModelScope.launch {
            // A resolução de catálogo de "qual audioId dentro desta categoria toca agora"
            // (rodízio/aleatório/favorito mais recente) fica em um caso de uso apoiado em
            // AudioClipDao; omitido aqui para manter este esqueleto focado no contrato de
            // roteamento de reprodução, conectado da mesma forma que o caso de uso
            // equivalente do app mobile.
            val audioId = "${category.id}_default"
            when (val result = playbackController.play(audioId)) {
                is PlaybackResult.Started -> _uiState.value = GameModeUiState(lastTapFeedback = null)
                is PlaybackResult.Failed -> _uiState.value = GameModeUiState(lastTapFeedback = result.reason)
            }
        }
    }
}
