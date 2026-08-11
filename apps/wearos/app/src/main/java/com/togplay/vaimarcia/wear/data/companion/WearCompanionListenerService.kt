package com.togplay.vaimarcia.wear.data.companion

import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

private const val PATH_CATALOG_SYNC = "/vaimarcia/catalog"

/**
 * Receptor em segundo plano para sincronizações de catálogo enviadas pelo celular. Executa
 * independentemente da activity em primeiro plano para que áudios novos ou atualizados (e
 * alternâncias de favoritos feitas no celular) cheguem ao cache local antes da próxima vez que
 * o usuário abrir o Modo Jogo — mantendo o caminho de toque-até-som livre de latência de
 * rede/sincronização.
 */
@AndroidEntryPoint
class WearCompanionListenerService : WearableListenerService() {

    @Inject
    lateinit var catalogSyncHandler: CatalogSyncHandler

    override fun onMessageReceived(messageEvent: MessageEvent) {
        // Mensagens celular -> relógio se limitam a notificações de catálogo/controle;
        // comandos de reprodução fluem apenas relógio -> celular (veja WearCompanionClient.sendPlayCommand).
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
