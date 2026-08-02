import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/audio_codec.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/device_capability_profile.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/paired_speaker.dart';

/// Talks to the platform side (Android/iOS) via the same method channel the
/// [watch_companion] feature scaffolds, plus [device_info_plus] for local
/// phone metadata. The native implementations of `GET_CAPABILITIES` /
/// `LIST_PAIRED_SPEAKERS` are documented TODOs — see
/// android/app/src/main/kotlin and ios/Runner for scaffolding.
abstract interface class DeviceCapabilityProbeDataSource {
  Future<DeviceCapabilityProfile?> probePairedWatch();
  Future<List<PairedSpeaker>> listPairedSpeakers();
  Future<void> openBluetoothSettings();
}

@LazySingleton(as: DeviceCapabilityProbeDataSource)
class DeviceCapabilityProbeDataSourceImpl implements DeviceCapabilityProbeDataSource {
  DeviceCapabilityProbeDataSourceImpl()
      : _channel = const MethodChannel(AppConstants.methodChannelWatchCompanion),
        _bluetoothChannel = const MethodChannel(AppConstants.methodChannelBluetoothTransport);

  final MethodChannel _channel;
  final MethodChannel _bluetoothChannel;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  Future<DeviceCapabilityProfile?> probePairedWatch() async {
    // TODO(platform-channel): native side must implement `getCapabilities`
    // per docs/DEVICE_DETECTION.md step 2 (Wear OS: CapabilityClient +
    // BluetoothA2dp proxy; watchOS: WCSession + AVAudioSession route
    // introspection forwarded from the watch app). Until implemented this
    // throws a MissingPluginException, which we treat as "no watch paired"
    // rather than crash the app — safe default is PHONE_ONLY.
    try {
      final Map<Object?, Object?>? raw = await _channel.invokeMapMethod<Object?, Object?>(
        'getCapabilities',
      );
      if (raw == null) {
        return null;
      }
      return DeviceCapabilityProfile(
        manufacturer: raw['manufacturer'] as String? ?? 'unknown',
        model: raw['model'] as String? ?? 'unknown',
        osFamily: raw['osFamily'] as String? ?? 'unknown',
        osVersion: raw['osVersion'] as String? ?? 'unknown',
        hasBluetoothClassicAudio: raw['hasBluetoothClassicAudio'] as bool? ?? false,
        hasBleAudioSupport: raw['hasBleAudioSupport'] as bool? ?? false,
        supportedCodecs: _parseCodecs(raw['supportedCodecs']),
        canPlayArbitraryLocalAudio: raw['canPlayArbitraryLocalAudio'] as bool? ?? false,
        hasPersistentCompanionChannel: raw['hasPersistentCompanionChannel'] as bool? ?? false,
        estimatedLatencyMs: raw['estimatedLatencyMs'] as int? ?? 0,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<List<PairedSpeaker>> listPairedSpeakers() async {
    // TODO(platform-channel): native side must implement `listPairedSpeakers`
    // — Android: BluetoothAdapter.getBondedDevices() filtered by
    // BluetoothClass.Device.AUDIO_VIDEO_*; iOS: AVAudioSession.currentRoute
    // outputs (+ MFi/AVRCP metadata where available for brand).
    try {
      final List<Object?>? raw = await _bluetoothChannel.invokeListMethod<Object?>('listPairedSpeakers');
      if (raw == null) {
        return const <PairedSpeaker>[];
      }
      return raw
          .cast<Map<Object?, Object?>>()
          .map(
            (Map<Object?, Object?> m) => PairedSpeaker(
              id: m['id'] as String? ?? '',
              name: m['name'] as String? ?? 'Caixa Bluetooth',
              isA2dpActive: m['isA2dpActive'] as bool? ?? false,
              brand: m['brand'] as String?,
            ),
          )
          .toList(growable: false);
    } on MissingPluginException {
      return const <PairedSpeaker>[];
    } on PlatformException {
      return const <PairedSpeaker>[];
    }
  }

  @override
  Future<void> openBluetoothSettings() async {
    try {
      await _bluetoothChannel.invokeMethod<void>('openBluetoothSettings');
    } on MissingPluginException {
      // Scaffold not wired on this platform yet — no-op is an acceptable
      // fallback since the wizard also surfaces manual instructions.
    }
  }

  Set<AudioCodec> _parseCodecs(Object? raw) {
    if (raw is! List) {
      return const <AudioCodec>{};
    }
    return raw
        .cast<String>()
        .map(
          (String name) => AudioCodec.values.firstWhere(
            (AudioCodec c) => c.name == name,
            orElse: () => AudioCodec.sbc,
          ),
        )
        .toSet();
  }

  Future<String> currentPhoneModel() async {
    try {
      final AndroidDeviceInfo android = await _deviceInfo.androidInfo;
      return '${android.manufacturer} ${android.model}';
    } on Object {
      try {
        final IosDeviceInfo ios = await _deviceInfo.iosInfo;
        return '${ios.name} ${ios.utsname.machine}';
      } on Object {
        return 'unknown';
      }
    }
  }
}
