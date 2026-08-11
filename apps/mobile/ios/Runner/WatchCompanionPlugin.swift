import Flutter
import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// Contraparte nativa de `WatchCompanionPlatformDataSource`
/// (lib/features/watch_companion/data/datasources/watch_companion_platform_datasource.dart).
///
/// STATUS: APENAS SCAFFOLD. A implementação real precisa de uma
/// conformidade `WCSessionDelegate`, mantida viva pelo tempo de vida do
/// processo do app conforme ARCHITECTURE.md §4 ("canal companion
/// persistente, nunca reconectado a cada comando"). O app companion do
/// lado watchOS (apps/watchos/ neste monorepo) deve implementar o
/// `WCSessionDelegate` correspondente e responder a uma mensagem
/// `getCapabilities` conforme docs/DEVICE_DETECTION.md §2.
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
    // TODO: implementar FlutterStreamHandler apoiado no
    // `session(_:didReceiveMessage:)` de um WCSessionDelegate, repassando
    // as mensagens `playAudio` como dicionários
    // ["type": "playAudio", "audioId": "<id>"] correspondendo a
    // WatchCommand.fromMap no lado Dart.
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
      // TODO: WCSession.default.isPaired (requer que
      // WCSession.default.activate() já tenha sido chamado uma vez ao
      // iniciar o app).
      result(FlutterMethodNotImplemented)

    case "isCompanionAppInstalled":
      // TODO: WCSession.default.isWatchAppInstalled.
      result(FlutterMethodNotImplemented)

    case "getCapabilities":
      // TODO: WCSession.default.sendMessage(["type": "getCapabilities"],
      // replyHandler:) para o app do relógio, mapeando sua resposta
      // DeviceCapabilityProfile para o formato que
      // DeviceCapabilityProbeDataSource espera. Recorrer a
      // `transferUserInfo` se `WCSession.default.isReachable == false`
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
