package com.togplay.vaimarcia.wear.data.companion

import com.google.android.gms.wearable.DataItem
import com.togplay.vaimarcia.wear.data.local.AudioClipDao
import com.togplay.vaimarcia.wear.data.local.AudioClipEntity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Analisa um DataItem de sincronização de catálogo enviado pelo celular e faz o upsert no
 * cache local do Room. O formato do payload espelha a sincronização incremental por delta do
 * app mobile (docs/ARCHITECTURE.md §7), mas reduzido apenas aos campos que a UI do relógio
 * precisa (id, categoria, título, flag de favorito, caminho do arquivo local uma vez baixado).
 */
@Singleton
class CatalogSyncHandler @Inject constructor(
    private val audioClipDao: AudioClipDao,
) {
    private val scope = CoroutineScope(Dispatchers.IO)

    fun onCatalogSyncReceived(dataItem: DataItem) {
        scope.launch {
            val entities = CatalogSyncPayload.parse(dataItem.data ?: return@launch)
                .map(AudioClipEntity::fromDomain)
            audioClipDao.upsertAll(entities)
        }
    }
}
