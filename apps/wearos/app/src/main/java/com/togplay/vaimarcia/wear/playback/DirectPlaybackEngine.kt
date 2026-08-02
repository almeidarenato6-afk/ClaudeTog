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
 * Scenario A: plays a locally cached clip directly through Media3/ExoPlayer, routed by the
 * OS to whatever Bluetooth Classic A2DP / LE Audio output is currently connected to the
 * watch. A single long-lived ExoPlayer instance is reused across taps (docs/ARCHITECTURE.md
 * §4 — pre-loaded buffers eliminate disk I/O and player-init cost from the critical path).
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

        // Interrupts whatever is currently playing — one motivational clip at a time,
        // never queued, to keep taps feeling instantaneous.
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
