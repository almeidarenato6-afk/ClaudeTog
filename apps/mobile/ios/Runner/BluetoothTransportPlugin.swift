import Flutter
import Foundation
import UIKit

/// Native counterpart of `BluetoothPlatformDataSource`
/// (lib/features/bluetooth/data/datasources/bluetooth_platform_datasource.dart)
/// and `DeviceCapabilityProbeDataSource`
/// (lib/features/device_pairing/data/datasources/device_capability_probe_datasource.dart).
///
/// STATUS: SCAFFOLD ONLY. iOS has no public API to enumerate *all* paired
/// Bluetooth Classic devices or force-hold an A2DP route the way Android's
/// `BluetoothA2dp` proxy does — everything below routes through
/// `AVAudioSession`, which only exposes the *currently active* output
/// route, not the full paired-devices list. Method/channel names match
/// the Dart side; bodies are TODOs.
final class BluetoothTransportPlugin: NSObject {
  private let messenger: FlutterBinaryMessenger
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  func register() {
    methodChannel = FlutterMethodChannel(
      name: "br.com.togplay.vaimarcia/bluetooth_transport",
      binaryMessenger: messenger
    )
    methodChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }

    eventChannel = FlutterEventChannel(
      name: "br.com.togplay.vaimarcia/bluetooth_events",
      binaryMessenger: messenger
    )
    // TODO: implement FlutterStreamHandler, observing
    // AVAudioSession.routeChangeNotification and mapping
    // AVAudioSession.sharedInstance().currentRoute.outputs to
    // "connected"/"disconnected" events matching BluetoothConnectionState
    // on the Dart side.
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "listPairedAudioDevices", "listPairedSpeakers":
      // TODO: AVAudioSession.sharedInstance().currentRoute.outputs only
      // exposes the *active* output, not all paired devices — there is no
      // public iOS API for a full paired-devices list. Practically this
      // returns at most one device (whatever's currently routed); document
      // that limitation to product/design.
      result(FlutterMethodNotImplemented)

    case "keepRouteWarm":
      // TODO: AVAudioSession.sharedInstance().setCategory(.playback,
      // options: [.allowBluetoothA2DP]) once, at app start, and never
      // deactivate the session between plays (ARCHITECTURE.md §4).
      result(FlutterMethodNotImplemented)

    case "openBluetoothSettings":
      // iOS does not allow deep-linking directly into Settings > Bluetooth
      // from a third-party app (App-Prefs:Bluetooth is a private URL
      // scheme Apple rejects on App Store review) — fall back to the
      // general Settings app entry for this app.
      if let url = URL(string: UIApplication.openSettingsURLString) {
        DispatchQueue.main.async {
          UIApplication.shared.open(url)
        }
      }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
