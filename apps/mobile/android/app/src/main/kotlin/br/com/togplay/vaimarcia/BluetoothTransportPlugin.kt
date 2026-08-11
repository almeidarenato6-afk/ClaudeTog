package br.com.togplay.vaimarcia

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Contraparte nativa de `BluetoothPlatformDataSource`
 * (lib/features/bluetooth/data/datasources/bluetooth_platform_datasource.dart)
 * e `DeviceCapabilityProbeDataSource`
 * (lib/features/device_pairing/data/datasources/device_capability_probe_datasource.dart).
 *
 * STATUS: APENAS SCAFFOLD. Nomes de método/conexão de canal batem com o
 * lado Dart; cada método abaixo é um TODO documentado, não uma
 * implementação funcional. `openBluetoothSettings` é o único método
 * implementado de verdade, já que não precisa de acesso à API Bluetooth
 * Classic, apenas um Intent.
 */
class BluetoothTransportPlugin(private val context: Context) {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    fun attach(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "br.com.togplay.vaimarcia/bluetooth_transport",
        )
        methodChannel.setMethodCallHandler { call, result -> onMethodCall(call, result) }

        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "br.com.togplay.vaimarcia/bluetooth_events",
        )
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                // TODO: registrar um BroadcastReceiver para
                // BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED e repassar
                // as strings "connected"/"connecting"/"disconnected"/"error"
                // correspondendo a BluetoothConnectionState.name no lado Dart.
            }

            override fun onCancel(arguments: Any?) {
                // TODO: cancelar o registro do BroadcastReceiver registrado acima.
            }
        })
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listPairedAudioDevices", "listPairedSpeakers" -> {
                // TODO: BluetoothAdapter.getBondedDevices() filtrado por
                // BluetoothClass.Device.AUDIO_VIDEO_* (conforme
                // docs/DEVICE_DETECTION.md §4), mapeando para
                // [{"id":..., "name":..., "isA2dpActive":..., "brand":...}].
                // Requer BLUETOOTH_CONNECT (já declarado no
                // AndroidManifest.xml) concedido em tempo de execução.
                result.notImplemented()
            }

            "keepRouteWarm" -> {
                // TODO: obter um proxy BluetoothA2dp via
                // BluetoothAdapter.getProfileProxy(context, listener, A2DP)
                // e evitar chamar closeProfileProxy() entre reproduções
                // — essa é a tática de "conexão mantida quente" descrita em
                // ARCHITECTURE.md §4. Provavelmente precisa rodar dentro de
                // um foreground service (veja o TODO em AndroidManifest.xml)
                // para que o Android não derrube o proxy em segundo plano.
                result.notImplemented()
            }

            "openBluetoothSettings" -> {
                val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}
