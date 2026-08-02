import Flutter
import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// Native counterpart of `WatchCompanionPlatformDataSource`
/// (lib/features/watch_companion/data/datasources/watch_companion_platform_datasource.dart).
///
/// STATUS: SCAFFOLD ONLY. Real implementation needs a `WCSessionDelegate`
/// conformance, kept alive for the app's process lifetime per
/// ARCHITECTURE.md §4 ("persistent companion channel, never reconnected
/// per command"). The watchOS-side companion app (apps/watchos/ in this
/// monorepo) must implement the matching `WCSessionDelegate` and respond
/// to a `getCapabilities` message per docs/DEVICE_DETECTION.md §2.
final class WatchCompanionPlugin: NSObject {
  private let messenger: FlutterBinaryMessenger
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  func register() {
    methodChannel = FlutterMethodChannel(
      name: "br.com.togplay.vaimarcia/watch_companion",
      binaryMessenger: messenger
    )
    methodChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }

    eventChannel = FlutterEventChannel(
      name: "br.com.togplay.vaimarcia/watch_companion_events",
      binaryMessenger: messenger
    )
    // TODO: implement FlutterStreamHandler backed by a WCSessionDelegate's
    // `session(_:didReceiveMessage:)`, forwarding `playAudio` messages as
    // ["type": "playAudio", "audioId": "<id>"] dictionaries matching
    // WatchCommand.fromMap on the Dart side.
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    #if canImport(WatchConnectivity)
    guard WCSession.isSupported() else {
      result(false)
      return
    }
    #endif

    switch call.method {
    case "isWatchPaired":
      // TODO: WCSession.default.isPaired (requires
      // WCSession.default.activate() to have been called once at launch).
      result(FlutterMethodNotImplemented)

    case "isCompanionAppInstalled":
      // TODO: WCSession.default.isWatchAppInstalled.
      result(FlutterMethodNotImplemented)

    case "getCapabilities":
      // TODO: WCSession.default.sendMessage(["type": "getCapabilities"],
      // replyHandler:) to the watch app, mapping its
      // DeviceCapabilityProfile reply to the shape
      // DeviceCapabilityProbeDataSource expects. Fall back to
      // `transferUserInfo` if `WCSession.default.isReachable == false`
      // (ARCHITECTURE.md §3).
      result(FlutterMethodNotImplemented)

    case "sendCommand":
      // TODO: WCSession.default.sendMessage(call.arguments as! [String: Any], ...)
      result(FlutterMethodNotImplemented)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
