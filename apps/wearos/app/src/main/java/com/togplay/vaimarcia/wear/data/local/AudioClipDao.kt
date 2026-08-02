package com.togplay.vaimarcia.wear.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface AudioClipDao {
    @Query("SELECT * FROM audio_clips WHERE categoryId = :categoryId ORDER BY title ASC")
    fun observeByCategory(categoryId: String): Flow<List<AudioClipEntity>>

    @Query("SELECT * FROM audio_clips WHERE isFavorite = 1 ORDER BY title ASC")
    fun observeFavorites(): Flow<List<AudioClipEntity>>

    @Query("SELECT * FROM audio_clips WHERE id = :id LIMIT 1")
    suspend fun getById(id: String): AudioClipEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(clips: List<AudioClipEntity>)
}
