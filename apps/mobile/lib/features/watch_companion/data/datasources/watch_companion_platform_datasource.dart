import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';

/// TODO(platform-channel): native implementations required —
/// android/app/src/main/kotlin/.../WatchCompanionPlugin.kt (Wear OS Data
/// Layer) and ios/Runner/WatchCompanionPlugin.swift (WatchConnectivity).
/// Both are scaffolded with method names matching this class but throw
/// `MissingPluginException` until implemented.
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
      // No-op until native side is implemented — see class doc.
    }
  }
}
