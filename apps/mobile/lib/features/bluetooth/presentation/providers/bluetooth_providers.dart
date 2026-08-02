import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/bluetooth/domain/entities/bluetooth_connection_state.dart';
import 'package:vai_marcia/features/bluetooth/domain/repositories/bluetooth_transport.dart';

final Provider<BluetoothTransport> bluetoothTransportProvider = Provider<BluetoothTransport>(
  (Ref ref) => getIt<BluetoothTransport>(),
);

final StreamProvider<BluetoothConnectionState> bluetoothConnectionStateProvider =
    StreamProvider<BluetoothConnectionState>(
  (Ref ref) => ref.watch(bluetoothTransportProvider).watchConnectionState(),
);
