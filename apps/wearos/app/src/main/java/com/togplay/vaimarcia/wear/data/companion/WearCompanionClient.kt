package com.togplay.vaimarcia.wear.data.companion

import android.content.Context
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.Wearable
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

private const val CAPABILITY_PHONE_APP = "vaimarcia_phone_app"
private const val PATH_PLAY_COMMAND = "/vaimarcia/play"
private const val PATH_GET_CAPABILITIES = "/vaimarcia/get_capabilities"
private const val PATH_CATALOG_SYNC = "/vaimarcia/catalog"

/**
 * Wraps the Wearable Data Layer API (MessageClient/DataClient/CapabilityClient) — the
 * companion channel used both for Scenario B command relay and for first-run pairing /
 * catalog sync metadata in Scenario A.
 *
 * The underlying `MessageClient` connection to Google Play services is kept alive by the
 * OS for the app's lifetime; we deliberately do not tear it down between plays (see
 * docs/ARCHITECTURE.md §4 — persistent companion channel avoids per-tap handshake cost).
 */
@Singleton
class WearCompanionClient @Inject constructor(
    @ApplicationContext context: Context,
) {
    private val messageClient: MessageClient = Wearable.getMessageClient(context)
    private val dataClient: DataClient = Wearable.getDataClient(context)
    private val capabilityClient: CapabilityClient = Wearable.getCapabilityClient(context)

    /** Resolves the connected phone node advertising the companion app capability. */
    private suspend fun findPhoneNodeId(): String? {
        val info = capabilityClient
            .getCapability(CAPABILITY_PHONE_APP, CapabilityClient.FILTER_REACHABLE)
            .await()
        return info.nodes.firstOrNull()?.id
    }

    /**
     * Scenario B critical path: sends only the audioId (a few bytes), never the audio
     * itself — the phone already has the file cached locally (docs/ARCHITECTURE.md §4).
     */
    suspend fun sendPlayCommand(audioId: String): Boolean {
        val nodeId = findPhoneNodeId() ?: return false
        messageClient.sendMessage(nodeId, PATH_PLAY_COMMAND, audioId.toByteArray(Charsets.UTF_8)).await()
        return true
    }

    /** GET_CAPABILITIES probe (docs/DEVICE_DETECTION.md step 2) — round trip expected < 200ms. */
    suspend fun requestPhoneCapabilities(): ByteArray? {
        val nodeId = findPhoneNodeId() ?: return null
        val response = messageClient.sendRequest(nodeId, PATH_GET_CAPABILITIES, ByteArray(0)).await()
        return response
    }

    /** Pulls the latest catalog-sync DataItem written by the phone (favorites, new clips, etc). */
    suspend fun fetchLatestCatalogSync(): DataClient.DataItem? {
        val items = dataClient.dataItems.await()
        return items.firstOrNull { it.uri.path == PATH_CATALOG_SYNC }.also { items.release() }
    }

    suspend fun isPhoneReachable(): Boolean = findPhoneNodeId() != null
}
