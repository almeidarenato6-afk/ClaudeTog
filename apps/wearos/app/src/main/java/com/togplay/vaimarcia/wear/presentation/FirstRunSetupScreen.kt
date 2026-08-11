package com.togplay.vaimarcia.wear.presentation

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.material.Text
import com.togplay.vaimarcia.wear.domain.PlaybackStrategy

/**
 * Espelho mínimo, do lado do relógio, do assistente "Vamos configurar seu equipamento" do
 * celular (docs/DEVICE_DETECTION.md). O relógio nunca pergunta nada perceptível ao usuário —
 * apenas mostra o status ao vivo enquanto o celular (fonte da verdade para o pareamento) faz
 * o trabalho de fato.
 */
@Composable
fun FirstRunSetupScreen(viewModel: GameModeViewModel = hiltViewModel(), onDone: () -> Unit) {
    val strategy by viewModel.strategy.collectAsState()

    Column(
        modifier = Modifier.fillMaxSize().padding(12.dp),
        verticalArrangement = Arrangement.Center,
    ) {
        Text(text = "Vamos configurar seu equipamento", textAlign = TextAlign.Center)
        Text(text = statusLine(strategy), textAlign = TextAlign.Center, modifier = Modifier.padding(top = 8.dp))
    }
}

private fun statusLine(strategy: PlaybackStrategy): String = when (strategy) {
    PlaybackStrategy.DIRECT -> "Prontinho! Seu relógio vai tocar direto na sua caixa."
    PlaybackStrategy.RELAY -> "Prontinho! Seu relógio vai avisar seu celular, que toca na caixa."
    PlaybackStrategy.PHONE_ONLY -> "Abra o app no celular para tocar os áudios."
}
