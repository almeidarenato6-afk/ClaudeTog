package br.com.togplay.vaimarcia

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Native counterpart of `DeviceCapabilityProbeDataSource` (watch
 * discovery) and `WatchCompanionPlatformDataSource`
 * (lib/features/watch_companion/data/datasources/watch_companion_platform_datasource.dart).
 *
 * STATUS: SCAFFOLD ONLY. Real implementation needs the Wear OS
 * `com.google.android.gms:play-services-wearable` dependency (already
 * declared in app/build.gradle) and, per docs/DEVICE_DETECTION.md §2,
 * cooperation from the Wear OS companion app (a *separate* app — see
 * apps/wearos/ in this monorepo) which must respond to a
 * `GET_CAPABILITIES` message on its own MessageClient listener.
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
                // TODO: register a Wearable.getMessageClient(context)
                // OnMessageReceivedListener here, keeping it alive for the
                // app's lifetime (ARCHITECTURE.md §4 — "persistent
                // companion channel, never reconnected per command").
                // Forward incoming `playAudio` messages as
                // {"type": "playAudio", "audioId": "<id>"} maps matching
                // WatchCommand.fromMap on the Dart side.
            }

            override fun onCancel(arguments: Any?) {
                // TODO: remove the OnMessageReceivedListener registered above.
            }
        })
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isWatchPaired" -> {
                // TODO: Wearable.getNodeClient(context).connectedNodes,
                // filter by capability advertised by the Wear OS companion
                // app (Wearable.getCapabilityClient()).
                result.notImplemented()
            }

            "isCompanionAppInstalled" -> {
                // TODO: CapabilityClient.getCapability(...) — the Wear OS
                // companion app advertises a capability string (e.g.
                // "vai_marcia_watch_app") that this checks for.
                result.notImplemented()
            }

            "getCapabilities" -> {
                // TODO: send a GET_CAPABILITIES message via
                // Wearable.getMessageClient(context).sendMessage(...) to
                // the connected node and await its DeviceCapabilityProfile
                // response (see docs/DEVICE_DETECTION.md §2), returning it
                // as the map shape DeviceCapabilityProbeDataSource expects.
                result.notImplemented()
            }

            "sendCommand" -> {
                // TODO: Wearable.getMessageClient(context).sendMessage()
                // with the (small!) payload from call.arguments — must stay
                // a few bytes per ARCHITECTURE.md §4 ("audioId only").
                result.notImplemented()
            }

            else -> result.notImplemented()
        }
    }
}
