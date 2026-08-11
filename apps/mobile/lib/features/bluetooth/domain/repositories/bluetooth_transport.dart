import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/bluetooth/domain/entities/bluetooth_connection_state.dart';

/// Abstração sobre a pilha Bluetooth Classic A2DP da plataforma.
///
/// O controle nativo completo (manter a rota A2DP "quente" entre
/// reproduções conforme ARCHITECTURE.md §4, ler metadados de
/// dispositivos conectados) NÃO é implementável puramente em Dart — o
/// Flutter não tem um plugin A2DP first-party com o nível de controle que
/// este produto precisa (rota persistente, introspecção de marca do
/// dispositivo). Esta interface é o contrato com o qual a implementação
/// da camada `data` conversa; a implementação concreta repassa para o
/// platform channel `AppConstants.methodChannelBluetoothTransport`, cujo
/// lado nativo (Kotlin/Swift) está com o scaffold pronto e TODOs — veja
/// android/app/src/main/kotlin e ios/Runner.
abstract interface class BluetoothTransport {
  Future<Result<List<BluetoothDeviceInfo>>> listPairedAudioDevices();

  Stream<BluetoothConnectionState> watchConnectionState();

  /// Garante que a rota A2DP para [deviceId] esteja ativa e permaneça
  /// ativa (nunca derrubada entre reproduções) — a tática de latência de
  /// "conexão quente" do ARCHITECTURE.md §4.
  Future<Result<void>> keepRouteWarm(String deviceId);

  Future<Result<void>> openSystemBluetoothSettings();
}
