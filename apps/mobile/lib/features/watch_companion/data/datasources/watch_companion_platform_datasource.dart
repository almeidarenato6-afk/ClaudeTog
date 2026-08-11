import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';

/// TODO(platform-channel): implementações nativas necessárias —
/// android/app/src/main/kotlin/.../WatchCompanionPlugin.kt (Data Layer do
/// Wear OS) e ios/Runner/WatchCompanionPlugin.swift (WatchConnectivity).
/// Ambas estão com scaffold com nomes de método correspondendo a esta
/// classe, mas lançam `MissingPluginException` até serem implementadas.
@lazySingleton
class WatchCompanionPlatformDataSource {
  WatchCompanionPlatformDataSource()
      : _methodChannel = const MethodChannel(AppConstants.methodChannelWatchCompanion),
        _eventChannel = const EventChannel(AppConstants.eventChannelWatchCompanionEvents);

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Future<bool> isWatchPaired() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isWatchPaired') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> isCompanionAppInstalled() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isCompanionAppInstalled') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Stream<Map<Object?, Object?>> incomingCommands() {
    return _eventChannel.receiveBroadcastStream().map((Object? event) => event as Map<Object?, Object?>).handleError(
          (Object _) {},
        );
  }

  Future<void> sendCommand(Map<String, Object?> command) async {
    try {
      await _methodChannel.invokeMethod<void>('sendCommand', command);
    } on MissingPluginException {
      // Sem efeito até que o lado nativo seja implementado — veja a
      // documentação da classe.
    }
  }
}
