package com.togplay.vaimarcia.wear.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

/**
 * Pequeno banco Room local contendo o pacote inicial (empacotado no momento da instalação)
 * mais qualquer subconjunto do catálogo completo que tenha sido sincronizado a partir do
 * celular. Isso NÃO é, propositalmente, um espelho de toda a coleção `audios` do Firestore —
 * o armazenamento do relógio é limitado.
 */
@Database(entities = [AudioClipEntity::class], version = 1, exportSchema = false)
abstract class VaiMarciaDatabase : RoomDatabase() {
    abstract fun audioClipDao(): AudioClipDao

    companion object {
        const val DATABASE_NAME = "vaimarcia_wear.db"
    }
}
