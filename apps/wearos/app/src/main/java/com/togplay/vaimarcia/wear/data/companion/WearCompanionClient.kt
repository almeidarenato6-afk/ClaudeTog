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
 * Envolve a Wearable Data Layer API (MessageClient/DataClient/CapabilityClient) — o canal
 * companion usado tanto para o relay de comandos do Cenário B quanto para o pareamento de
 * primeira execução / metadados de sincronização de catálogo no Cenário A.
 *
 * A conexão subjacente do `MessageClient` com os serviços do Google Play é mantida viva pelo
 * SO durante todo o ciclo de vida do app; deliberadamente não a encerramos entre reproduções
 * (veja docs/ARCHITECTURE.md §4 — o canal companion persistente evita o custo de handshake a
 * cada toque).
 */
@Singleton
class WearCompanionClient @Inject constructor(
    @ApplicationContext context: Context,
) {
    private val messageClient: MessageClient = Wearable.getMessageClient(context)
    private val dataClient: DataClient = Wearable.getDataClient(context)
    private val capabilityClient: CapabilityClient = Wearable.getCapabilityClient(context)

    /** Resolve o node do celular conectado que anuncia a capacidade do app companion. */
    private suspend fun findPhoneNodeId(): String? {
        val info = capabilityClient
            .getCapability(CAPABILITY_PHONE_APP, CapabilityClient.FILTER_REACHABLE)
            .await()
        return info.nodes.firstOrNull()?.id
    }

    /**
     * Caminho crítico do Cenário B: envia apenas o audioId (poucos bytes), nunca o áudio
     * em si — o celular já tem o arquivo em cache localmente (docs/ARCHITECTURE.md §4).
     */
    suspend fun sendPlayCommand(audioId: String): Boolean {
        val nodeId = findPhoneNodeId() ?: return false
        messageClient.sendMessage(nodeId, PATH_PLAY_COMMAND, audioId.toByteArray(Charsets.UTF_8)).await()
        return true
    }

    /** Sondagem GET_CAPABILITIES (docs/DEVICE_DETECTION.md passo 2) — round trip esperado < 200ms. */
    suspend fun requestPhoneCapabilities(): ByteArray? {
        val nodeId = findPhoneNodeId() ?: return null
        val response = messageClient.sendRequest(nodeId, PATH_GET_CAPABILITIES, ByteArray(0)).await()
        return response
    }

    /** Busca o DataItem de sincronização de catálogo mais recente gravado pelo celular (favoritos, novos clipes, etc). */
    suspend fun fetchLatestCatalogSync(): DataClient.DataItem? {
        val items = dataClient.dataItems.await()
        return items.firstOrNull { it.uri.path == PATH_CATALOG_SYNC }.also { items.release() }
    }

    suspend fun isPhoneReachable(): Boolean = findPhoneNodeId() != null
}
