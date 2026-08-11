package com.togplay.vaimarcia.wear.playback

import com.togplay.vaimarcia.wear.data.companion.WearCompanionClient
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Cenário B: envia o comando de reprodução para o celular pela conexão persistente do Data
 * Layer. O celular já tem o áudio em cache e o reproduz na caixa Bluetooth pareada — da
 * perspectiva do usuário, isso é indistinguível do Cenário A.
 */
@Singleton
class RelayPlaybackDispatcher @Inject constructor(
    private val companionClient: WearCompanionClient,
) : PlaybackEngine {

    override suspend fun play(audioId: String): PlaybackResult {
        val delivered = companionClient.sendPlayCommand(audioId)
        return if (delivered) {
            PlaybackResult.Started
        } else {
            PlaybackResult.Failed("phone_unreachable")
        }
    }
}
