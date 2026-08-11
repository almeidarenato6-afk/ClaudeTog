import 'dart:async';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';
import 'package:vai_marcia/features/bluetooth/domain/entities/bluetooth_connection_state.dart';

/// Wrapper fino de method/event-channel. Cada método aqui tem uma
/// contraparte nativa real e documentada a implementar — veja
/// android/app/src/main/kotlin/.../BluetoothTransportPlugin.kt (stub
/// TODO) e ios/Runner/BluetoothTransportPlugin.swift (stub TODO). Até que
/// o lado nativo chegue, as chamadas lançam [MissingPluginException], que
/// os chamadores tratam como "nenhum dado disponível" em vez de quebrar.
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
      // Keepalive de rota A2DP nativa ainda não implementado — veja a
      // documentação da classe.
    }
  }

  Future<void> openSystemBluetoothSettings() async {
    try {
      await _methodChannel.invokeMethod<void>('openBluetoothSettings');
    } on MissingPluginException {
      // Fallback no-op; o assistente de configuração mostra instruções
      // manuais em vez disso.
    }
  }
}
