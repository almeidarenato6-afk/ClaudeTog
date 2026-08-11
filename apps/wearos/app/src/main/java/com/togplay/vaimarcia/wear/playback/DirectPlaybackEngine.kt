package com.togplay.vaimarcia.wear.playback

import android.content.Context
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import com.togplay.vaimarcia.wear.data.local.AudioCacheStore
import com.togplay.vaimarcia.wear.data.local.AudioClipDao
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Cenário A: reproduz um clipe em cache localmente direto pelo Media3/ExoPlayer, roteado pelo
 * SO para qualquer saída Bluetooth Classic A2DP / LE Audio atualmente conectada ao relógio.
 * Uma única instância de longa duração do ExoPlayer é reutilizada entre os toques
 * (docs/ARCHITECTURE.md §4 — buffers pré-carregados eliminam I/O de disco e o custo de
 * inicialização do player do caminho crítico).
 */
@Singleton
class DirectPlaybackEngine @Inject constructor(
    @ApplicationContext private val context: Context,
    private val audioClipDao: AudioClipDao,
    private val cacheStore: AudioCacheStore,
) : PlaybackEngine {

    private val player: ExoPlayer by lazy {
        ExoPlayer.Builder(context).build().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_SONIFICATION)
                    .build(),
                /* handleAudioFocus = */ true,
            )
        }
    }

    override suspend fun play(audioId: String): PlaybackResult {
        val clip = audioClipDao.getById(audioId)
            ?: return PlaybackResult.Failed("unknown_audio_id")

        val file = clip.localFilePath?.let { java.io.File(it) }
            ?.takeIf { it.exists() }
            ?: cacheStore.fileFor(audioId).takeIf { it.exists() }
            ?: return PlaybackResult.Failed("not_cached_locally")

        // Interrompe o que estiver tocando no momento — um clipe motivacional por vez,
        // nunca enfileirado, para manter a sensação de resposta instantânea aos toques.
        player.stop()
        player.setMediaItem(MediaItem.fromUri(file.toURI().toString()))
        player.prepare()
        player.play()
        return PlaybackResult.Started
    }

    fun release() {
        player.release()
    }
}
