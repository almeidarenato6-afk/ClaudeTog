package com.togplay.vaimarcia.wear.presentation

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.togplay.vaimarcia.wear.presentation.theme.VaiMarciaWearTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            VaiMarciaWearTheme {
                val navController = rememberSwipeDismissableNavController()
                var setupComplete by remember { mutableStateOf(false) }

                SwipeDismissableNavHost(
                    navController = navController,
                    startDestination = if (setupComplete) "game_mode" else "first_run_setup",
                ) {
                    composable("first_run_setup") {
                        FirstRunSetupScreen(onDone = {
                            setupComplete = true
                            navController.navigate("game_mode")
                        })
                    }
                    composable("game_mode") {
                        GameModeScreen()
                    }
                }
            }
        }
    }
}
