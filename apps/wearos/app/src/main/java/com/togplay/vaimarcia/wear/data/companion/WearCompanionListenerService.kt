package com.togplay.vaimarcia.wear.data.companion

import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

private const val PATH_CATALOG_SYNC = "/vaimarcia/catalog"

/**
 * Background receiver for phone-pushed catalog syncs. Runs independent of the foreground
 * activity so newly-added or updated audio (and favorite toggles made on the phone) land in
 * the local cache before the user next opens Modo Jogo — keeping the tap-to-sound path free
 * of network/sync latency.
 */
@AndroidEntryPoint
class WearCompanionListenerService : WearableListenerService() {

    @Inject
    lateinit var catalogSyncHandler: CatalogSyncHandler

    override fun onMessageReceived(messageEvent: MessageEvent) {
        // Phone -> watch messages are limited to catalog/control notifications; playback
        // commands only ever flow watch -> phone (see WearCompanionClient.sendPlayCommand).
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        dataEvents.forEach { event ->
            if (event.dataItem.uri.path == PATH_CATALOG_SYNC) {
                catalogSyncHandler.onCatalogSyncReceived(event.dataItem)
            }
        }
        dataEvents.release()
    }
}
