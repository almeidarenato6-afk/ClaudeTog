package com.togplay.vaimarcia.wear.data.local

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Gerencia os arquivos de áudio em cache no armazenamento do relógio (um subdiretório de
 * `filesDir`, não armazenamento externo — apps de relógio geralmente não têm armazenamento
 * removível e o espaço privado do app é pequeno, então é esperado que haja expurgo dos clipes
 * reproduzidos há mais tempo fora do pacote inicial).
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
