package com.togplay.vaimarcia.wear.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.togplay.vaimarcia.wear.domain.AudioClip

/** Linha do Room para o subconjunto local do catálogo sincronizado a partir do celular (pacote inicial + deltas). */
@Entity(tableName = "audio_clips")
data class AudioClipEntity(
    @PrimaryKey val id: String,
    val categoryId: String,
    val title: String,
    val localFilePath: String?,
    val durationMs: Int,
    val isFavorite: Boolean,
) {
    fun toDomain() = AudioClip(
        id = id,
        categoryId = categoryId,
        title = title,
        localFilePath = localFilePath,
        durationMs = durationMs,
        isFavorite = isFavorite,
    )

    companion object {
        fun fromDomain(clip: AudioClip) = AudioClipEntity(
            id = clip.id,
            categoryId = clip.categoryId,
            title = clip.title,
            localFilePath = clip.localFilePath,
            durationMs = clip.durationMs,
            isFavorite = clip.isFavorite,
        )
    }
}
