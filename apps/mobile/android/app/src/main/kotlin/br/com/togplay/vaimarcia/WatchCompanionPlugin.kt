package br.com.togplay.vaimarcia

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Contraparte nativa de `DeviceCapabilityProbeDataSource` (descoberta do
 * relógio) e `WatchCompanionPlatformDataSource`
 * (lib/features/watch_companion/data/datasources/watch_companion_platform_datasource.dart).
 *
 * STATUS: APENAS SCAFFOLD. A implementação real precisa da dependência
 * Wear OS `com.google.android.gms:play-services-wearable` (já declarada
 * em app/build.gradle) e, conforme docs/DEVICE_DETECTION.md §2, da
 * cooperação do app companion Wear OS (um app *separado* — veja
 * apps/wearos/ neste monorepo), que deve responder a uma mensagem
 * `GET_CAPABILITIES` no seu próprio listener de MessageClient.
 */
class WatchCompanionPlugin(private val context: Context) {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    fun attach(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "br.com.togplay.vaimarcia/watch_companion",
        )
        methodChannel.setMethodCallHandler { call, result -> onMethodCall(call, result) }

        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "br.com.togplay.vaimarcia/watch_companion_events",
        )
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                // TODO: registrar aqui um OnMessageReceivedListener de
                // Wearable.getMessageClient(context), mantendo-o vivo pelo
                // tempo de vida do app (ARCHITECTURE.md §4 — "canal
                // companion persistente, nunca reconectado a cada comando").
                // Repassar as mensagens `playAudio` recebidas como mapas
                // {"type": "playAudio", "audioId": "<id>"} correspondendo a
                // WatchCommand.fromMap no lado Dart.
            }

            override fun onCancel(arguments: Any?) {
                // TODO: remover o OnMessageReceivedListener registrado acima.
            }
        })
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isWatchPaired" -> {
                // TODO: Wearable.getNodeClient(context).connectedNodes,
                // filtrando pela capability anunciada pelo app companion
                // Wear OS (Wearable.getCapabilityClient()).
                result.notImplemented()
            }

            "isCompanionAppInstalled" -> {
                // TODO: CapabilityClient.getCapability(...) — o app
                // companion Wear OS anuncia uma string de capability (ex.
                // "vai_marcia_watch_app") que isso verifica.
                result.notImplemented()
            }

            "getCapabilities" -> {
                // TODO: enviar uma mensagem GET_CAPABILITIES via
                // Wearable.getMessageClient(context).sendMessage(...) para
                // o nó conectado e aguardar sua resposta DeviceCapabilityProfile
                // (veja docs/DEVICE_DETECTION.md §2), retornando-a no formato
                // de mapa que DeviceCapabilityProbeDataSource espera.
                result.notImplemented()
            }

            "sendCommand" -> {
                // TODO: Wearable.getMessageClient(context).sendMessage()
                // com o payload (pequeno!) vindo de call.arguments — deve
                // permanecer com poucos bytes conforme ARCHITECTURE.md §4
                // ("apenas audioId").
                result.notImplemented()
            }

            else -> result.notImplemented()
        }
    }
}
