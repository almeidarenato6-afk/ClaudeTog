import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/bluetooth/domain/entities/bluetooth_connection_state.dart';

/// Abstraction over the platform's Bluetooth Classic A2DP stack.
///
/// Full native control (keeping the A2DP route "hot" between plays per
/// ARCHITECTURE.md §4, reading connected-device metadata) is NOT
/// implementable purely in Dart — Flutter has no first-party A2DP plugin
/// with the level of control this product needs (persistent route,
/// device brand introspection). This interface is the contract the
/// `data` layer implementation talks to; the concrete implementation
/// forwards to platform channel `AppConstants.methodChannelBluetoothTransport`,
/// whose native (Kotlin/Swift) side is scaffolded with TODOs — see
/// android/app/src/main/kotlin and ios/Runner.
abstract interface class BluetoothTransport {
  Future<Result<List<BluetoothDeviceInfo>>> listPairedAudioDevices();

  Stream<BluetoothConnectionState> watchConnectionState();

  /// Ensures the A2DP route to [deviceId] is active and stays active
  /// (never torn down between plays) — the "warm connection" latency
  /// tactic from ARCHITECTURE.md §4.
  Future<Result<void>> keepRouteWarm(String deviceId);

  Future<Result<void>> openSystemBluetoothSettings();
}
