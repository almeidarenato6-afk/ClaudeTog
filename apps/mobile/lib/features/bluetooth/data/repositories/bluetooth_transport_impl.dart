import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/bluetooth/data/datasources/bluetooth_platform_datasource.dart';
import 'package:vai_marcia/features/bluetooth/domain/entities/bluetooth_connection_state.dart';
import 'package:vai_marcia/features/bluetooth/domain/repositories/bluetooth_transport.dart';

@LazySingleton(as: BluetoothTransport)
class BluetoothTransportImpl implements BluetoothTransport {
  BluetoothTransportImpl(this._platform);

  final BluetoothPlatformDataSource _platform;

  @override
  Future<Result<List<BluetoothDeviceInfo>>> listPairedAudioDevices() async {
    try {
      final List<Map<Object?, Object?>> raw = await _platform.listPairedAudioDevices();
      final List<BluetoothDeviceInfo> devices = raw
          .map(
            (Map<Object?, Object?> m) => BluetoothDeviceInfo(
              id: m['id'] as String? ?? '',
              name: m['name'] as String? ?? 'Caixa Bluetooth',
              brand: m['brand'] as String?,
            ),
          )
          .toList(growable: false);
      return Result<List<BluetoothDeviceInfo>>.ok(devices);
    } on Object catch (e) {
      return Result<List<BluetoothDeviceInfo>>.err(BluetoothFailure('Falha ao listar dispositivos Bluetooth', cause: e));
    }
  }

  @override
  Stream<BluetoothConnectionState> watchConnectionState() => _platform.watchConnectionState();

  @override
  Future<Result<void>> keepRouteWarm(String deviceId) async {
    try {
      await _platform.keepRouteWarm(deviceId);
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(BluetoothFailure('Falha ao manter conexão Bluetooth ativa', cause: e));
    }
  }

  @override
  Future<Result<void>> openSystemBluetoothSettings() async {
    try {
      await _platform.openSystemBluetoothSettings();
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(BluetoothFailure('Falha ao abrir configurações de Bluetooth', cause: e));
    }
  }
}
