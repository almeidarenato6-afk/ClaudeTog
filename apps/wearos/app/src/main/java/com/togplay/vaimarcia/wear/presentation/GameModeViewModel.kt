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

    /** One tap = one clip from the given category's default/next audioId. */
    fun onCategoryTapped(category: Category) {
        viewModelScope.launch {
            // The catalog resolution of "which audioId within this category plays now"
            // (round-robin/random/most-recent-favorite) lives in a use case backed by
            // AudioClipDao; omitted here to keep this scaffold focused on the playback
            // routing contract, wired the same way the mobile app's use case is.
            val audioId = "${category.id}_default"
            when (val result = playbackController.play(audioId)) {
                is PlaybackResult.Started -> _uiState.value = GameModeUiState(lastTapFeedback = null)
                is PlaybackResult.Failed -> _uiState.value = GameModeUiState(lastTapFeedback = result.reason)
            }
        }
    }
}
