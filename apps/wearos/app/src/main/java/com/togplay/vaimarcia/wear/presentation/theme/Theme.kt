package com.togplay.vaimarcia.wear.presentation.theme

import androidx.compose.runtime.Composable
import androidx.wear.compose.material.Colors
import androidx.wear.compose.material.MaterialTheme

// Cores provisórias da marca TogPlay — coral/laranja + navy. Substituir pelos valores finais
// do brand kit assim que o design entregar a paleta oficial.
val TogPlayCoral = androidx.compose.ui.graphics.Color(0xFFFF6B4A)
val TogPlayNavy = androidx.compose.ui.graphics.Color(0xFF17213A)
val TogPlaySurface = androidx.compose.ui.graphics.Color(0xFF1F2B4A)

private val VaiMarciaColors = Colors(
    primary = TogPlayCoral,
    primaryVariant = TogPlayCoral,
    secondary = TogPlayNavy,
    background = TogPlayNavy,
    surface = TogPlaySurface,
    error = androidx.compose.ui.graphics.Color(0xFFCF6679),
    onPrimary = androidx.compose.ui.graphics.Color.White,
    onSecondary = androidx.compose.ui.graphics.Color.White,
    onBackground = androidx.compose.ui.graphics.Color.White,
    onSurface = androidx.compose.ui.graphics.Color.White,
    onError = androidx.compose.ui.graphics.Color.Black,
)

@Composable
fun VaiMarciaWearTheme(content: @Composable () -> Unit) {
    MaterialTheme(colors = VaiMarciaColors, content = content)
}
