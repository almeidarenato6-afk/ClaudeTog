enum BluetoothConnectionState { disconnected, connecting, connected, error }

class BluetoothDeviceInfo {
  const BluetoothDeviceInfo({required this.id, required this.name, this.brand});

  final String id;
  final String name;
  final String? brand;
}
