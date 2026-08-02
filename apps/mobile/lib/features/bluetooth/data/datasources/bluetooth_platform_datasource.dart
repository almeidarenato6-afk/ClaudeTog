import 'dart:async';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';
import 'package:vai_marcia/features/bluetooth/domain/entities/bluetooth_connection_state.dart';

/// Thin method/event-channel wrapper. Every method here has a real,
/// documented native counterpart to implement — see
/// android/app/src/main/kotlin/.../BluetoothTransportPlugin.kt (TODO
/// stub) and ios/Runner/BluetoothTransportPlugin.swift (TODO stub).
/// Until the native side lands, calls throw [MissingPluginException],
/// which callers treat as "no data available" rather than crashing.
@lazySingleton
class BluetoothPlatformDataSource {
  BluetoothPlatformDataSource()
      : _methodChannel = const MethodChannel(AppConstants.methodChannelBluetoothTransport),
        _eventChannel = const EventChannel(AppConstants.eventChannelBluetoothEvents);

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Future<List<Map<Object?, Object?>>> listPairedAudioDevices() async {
    try {
      final List<Object?>? raw = await _methodChannel.invokeListMethod<Object?>('listPairedAudioDevices');
      return raw?.cast<Map<Object?, Object?>>() ?? const <Map<Object?, Object?>>[];
    } on MissingPluginException {
      return const <Map<Object?, Object?>>[];
    }
  }

  Stream<BluetoothConnectionState> watchConnectionState() {
    return _eventChannel.receiveBroadcastStream().map((Object? event) {
      final String raw = event as String? ?? 'disconnected';
      return BluetoothConnectionState.values.firstWhere(
        (BluetoothConnectionState s) => s.name == raw,
        orElse: () => BluetoothConnectionState.disconnected,
      );
    }).handleError((Object _) {});
  }

  Future<void> keepRouteWarm(String deviceId) async {
    try {
      await _methodChannel.invokeMethod<void>('keepRouteWarm', <String, String>{'deviceId': deviceId});
    } on MissingPluginException {
      // Native A2DP route-keepalive not yet implemented — see class doc.
    }
  }

  Future<void> openSystemBluetoothSettings() async {
    try {
      await _methodChannel.invokeMethod<void>('openBluetoothSettings');
    } on MissingPluginException {
      // No-op fallback; setup wizard shows manual instructions instead.
    }
  }
}
