package br.com.togplay.vaimarcia

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Native counterpart of `BluetoothPlatformDataSource`
 * (lib/features/bluetooth/data/datasources/bluetooth_platform_datasource.dart)
 * and `DeviceCapabilityProbeDataSource`
 * (lib/features/device_pairing/data/datasources/device_capability_probe_datasource.dart).
 *
 * STATUS: SCAFFOLD ONLY. Method names/channel wiring match the Dart side;
 * every method below is a documented TODO, not a working implementation.
 * `openBluetoothSettings` is the one method implemented for real since it
 * needs no Bluetooth Classic API access, just an Intent.
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
                // TODO: register a BroadcastReceiver for
                // BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED and forward
                // "connected"/"connecting"/"disconnected"/"error" strings
                // matching BluetoothConnectionState.name on the Dart side.
            }

            override fun onCancel(arguments: Any?) {
                // TODO: unregister the BroadcastReceiver registered above.
            }
        })
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listPairedAudioDevices", "listPairedSpeakers" -> {
                // TODO: BluetoothAdapter.getBondedDevices() filtered by
                // BluetoothClass.Device.AUDIO_VIDEO_* (per
                // docs/DEVICE_DETECTION.md §4), map to
                // [{"id":..., "name":..., "isA2dpActive":..., "brand":...}].
                // Requires BLUETOOTH_CONNECT (already declared in
                // AndroidManifest.xml) granted at runtime.
                result.notImplemented()
            }

            "keepRouteWarm" -> {
                // TODO: obtain a BluetoothA2dp proxy via
                // BluetoothAdapter.getProfileProxy(context, listener, A2DP)
                // and avoid ever calling closeProfileProxy() between plays
                // — this is the "connection kept warm" tactic in
                // ARCHITECTURE.md §4. Likely needs to run inside a
                // foreground service (see AndroidManifest.xml TODO) so
                // Android doesn't tear down the proxy when backgrounded.
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
