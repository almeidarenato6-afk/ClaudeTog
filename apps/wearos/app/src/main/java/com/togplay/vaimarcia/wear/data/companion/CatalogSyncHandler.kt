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
 * Parses a catalog-sync DataItem pushed from the phone and upserts it into the local Room
 * cache. Payload format mirrors the mobile app's incremental delta sync (docs/ARCHITECTURE.md
 * §7) but trimmed to just the fields the watch UI needs (id, category, title, favorite flag,
 * local file path once downloaded).
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
