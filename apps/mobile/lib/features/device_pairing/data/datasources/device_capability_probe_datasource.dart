import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/audio_codec.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/device_capability_profile.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/paired_speaker.dart';

/// Conversa com o lado da plataforma (Android/iOS) através do mesmo
/// method channel que a feature [watch_companion] tem como scaffold, além
/// de [device_info_plus] para metadados locais do celular. As
/// implementações nativas de `GET_CAPABILITIES` / `LIST_PAIRED_SPEAKERS`
/// são TODOs documentados — veja android/app/src/main/kotlin e ios/Runner
/// para o scaffold.
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
    // TODO(platform-channel): o lado nativo deve implementar
    // `getCapabilities` conforme o passo 2 de docs/DEVICE_DETECTION.md
    // (Wear OS: CapabilityClient + proxy BluetoothA2dp; watchOS: WCSession
    // + introspecção de rota AVAudioSession repassada pelo app do
    // relógio). Até que seja implementado, isso lança um
    // MissingPluginException, que tratamos como "nenhum relógio pareado"
    // em vez de derrubar o app — o padrão seguro é PHONE_ONLY.
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
    // TODO(platform-channel): o lado nativo deve implementar
    // `listPairedSpeakers` — Android: BluetoothAdapter.getBondedDevices()
    // filtrado por BluetoothClass.Device.AUDIO_VIDEO_*; iOS:
    // AVAudioSession.currentRoute outputs (+ metadados MFi/AVRCP quando
    // disponíveis para a marca).
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
      // Scaffold ainda não conectado nesta plataforma — no-op é um
      // fallback aceitável já que o assistente também mostra instruções
      // manuais.
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
