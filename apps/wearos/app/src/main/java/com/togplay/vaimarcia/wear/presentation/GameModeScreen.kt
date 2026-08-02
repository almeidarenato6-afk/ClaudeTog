package com.togplay.vaimarcia.wear.presentation

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.Text
import com.togplay.vaimarcia.wear.domain.Category

/**
 * "Modo Jogo" — a handful of huge, glanceable buttons. One tap starts playback immediately;
 * no confirmation dialogs, no nested navigation, minimal chrome so it stays usable mid-match.
 */
@Composable
fun GameModeScreen(viewModel: GameModeViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    ScalingLazyColumn(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        items(Category.entries.toList()) { category ->
            CategoryButton(category = category, onClick = { viewModel.onCategoryTapped(category) })
        }
        if (uiState.lastTapFeedback != null) {
            item {
                Text(
                    text = "Ops, tente de novo",
                    modifier = Modifier.fillMaxWidth().padding(top = 4.dp),
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

@Composable
private fun CategoryButton(category: Category, onClick: () -> Unit) {
    Chip(
        onClick = onClick,
        label = { Text(text = categoryLabel(category), textAlign = TextAlign.Center) },
        colors = ChipDefaults.primaryChipColors(),
        modifier = Modifier.fillMaxWidth(),
    )
}

private fun categoryLabel(category: Category): String = when (category) {
    Category.ENERGIA -> "🔥 Energia"
    Category.BORA -> "💪 Bora"
    Category.PALMAS -> "👏 Palmas"
    Category.HUMOR -> "😂 Humor"
    Category.FAVORITOS -> "❤️ Favoritos"
}
