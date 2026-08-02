package com.togplay.vaimarcia.wear.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

/**
 * Small local Room DB holding the starter pack (bundled at install time) plus whatever
 * subset of the full catalog has been synced down from the phone. This is intentionally
 * NOT a mirror of the entire Firestore `audios` collection — watch storage is limited.
 */
@Database(entities = [AudioClipEntity::class], version = 1, exportSchema = false)
abstract class VaiMarciaDatabase : RoomDatabase() {
    abstract fun audioClipDao(): AudioClipDao

    companion object {
        const val DATABASE_NAME = "vaimarcia_wear.db"
    }
}
