package com.togplay.vaimarcia.wear.data.local

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages cached audio files on watch storage (a subdirectory of `filesDir`, not external
 * storage — watch apps commonly have no removable storage and app-private space is small,
 * so eviction of least-recently-played clips outside the starter pack is expected here).
 */
@Singleton
class AudioCacheStore @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private val cacheDir: File by lazy {
        File(context.filesDir, "audio_cache").apply { mkdirs() }
    }

    fun fileFor(audioId: String): File = File(cacheDir, "$audioId.m4a")

    fun isCached(audioId: String): Boolean = fileFor(audioId).exists()

    fun write(audioId: String, bytes: ByteArray): File {
        val file = fileFor(audioId)
        file.writeBytes(bytes)
        return file
    }

    fun evict(audioId: String) {
        fileFor(audioId).delete()
    }
}
