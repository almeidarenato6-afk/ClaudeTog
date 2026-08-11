import Flutter
import Foundation
import UIKit

/// Contraparte nativa de `BluetoothPlatformDataSource`
/// (lib/features/bluetooth/data/datasources/bluetooth_platform_datasource.dart)
/// e `DeviceCapabilityProbeDataSource`
/// (lib/features/device_pairing/data/datasources/device_capability_probe_datasource.dart).
///
/// STATUS: APENAS SCAFFOLD. O iOS não tem API pública para enumerar
/// *todos* os dispositivos Bluetooth Classic pareados nem para forçar a
/// manutenção de uma rota A2DP como o proxy `BluetoothA2dp` do Android
/// faz — tudo abaixo passa por `AVAudioSession`, que só expõe a rota de
/// saída *atualmente ativa*, não a lista completa de dispositivos
/// pareados. Nomes de método/canal batem com o lado Dart; os corpos são
/// TODOs.
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
    // TODO: implementar FlutterStreamHandler, observando
    // AVAudioSession.routeChangeNotification e mapeando
    // AVAudioSession.sharedInstance().currentRoute.outputs para eventos
    // "connected"/"disconnected" correspondendo a BluetoothConnectionState
    // no lado Dart.
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "listPairedAudioDevices", "listPairedSpeakers":
      // TODO: AVAudioSession.sharedInstance().currentRoute.outputs só
      // expõe a saída *ativa*, não todos os dispositivos pareados — não
      // existe API pública no iOS para uma lista completa de dispositivos
      // pareados. Na prática isso retorna no máximo um dispositivo (o que
      // estiver roteado no momento); documentar essa limitação para
      // produto/design.
      result(FlutterMethodNotImplemented)

    case "keepRouteWarm":
      // TODO: AVAudioSession.sharedInstance().setCategory(.playback,
      // options: [.allowBluetoothA2DP]) uma vez, ao iniciar o app, e nunca
      // desativar a sessão entre reproduções (ARCHITECTURE.md §4).
      result(FlutterMethodNotImplemented)

    case "openBluetoothSettings":
      // O iOS não permite deep-link direto para Ajustes > Bluetooth a
      // partir de um app de terceiros (App-Prefs:Bluetooth é um esquema de
      // URL privado que a Apple rejeita na revisão da App Store) — recorrer
      // à entrada geral do app em Ajustes.
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
