package com.togplay.vaimarcia.wear.domain

/**
 * Espelha conceitualmente a entidade de domínio `AudioClip` do app mobile (veja
 * apps/mobile/lib/features/audio_playback/domain). Mantida livre de dependências para que
 * possa ser testada unitariamente sem classes do framework Android.
 */
data class AudioClip(
    val id: String,
    val categoryId: String,
    val title: String,
    val localFilePath: String?,
    val durationMs: Int,
    val isFavorite: Boolean = false,
) {
    val isCachedLocally: Boolean get() = !localFilePath.isNullOrBlank()
}
