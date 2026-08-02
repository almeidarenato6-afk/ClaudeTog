package com.togplay.vaimarcia.wear.domain

/**
 * Mirrors the mobile app's `AudioClip` domain entity conceptually (see
 * apps/mobile/lib/features/audio_playback/domain). Kept dependency-free so it can be
 * unit-tested without Android framework classes.
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
