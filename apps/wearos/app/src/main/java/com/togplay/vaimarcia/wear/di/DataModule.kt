package com.togplay.vaimarcia.wear.di

import android.content.Context
import androidx.room.Room
import com.togplay.vaimarcia.wear.data.local.AudioClipDao
import com.togplay.vaimarcia.wear.data.local.VaiMarciaDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DataModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): VaiMarciaDatabase =
        Room.databaseBuilder(context, VaiMarciaDatabase::class.java, VaiMarciaDatabase.DATABASE_NAME)
            .fallbackToDestructiveMigration()
            .build()

    @Provides
    fun provideAudioClipDao(database: VaiMarciaDatabase): AudioClipDao = database.audioClipDao()
}
