import 'package:equatable/equatable.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/audio_codec.dart';

/// Espelha o modelo documentado em docs/DEVICE_DETECTION.md — mantido
/// como uma entidade Dart pura (sem import de Flutter/Firebase) para que
/// o algoritmo de decisão em [DecidePlaybackStrategyUseCase] seja
/// trivialmente testável unitariamente.
class DeviceCapabilityProfile extends Equatable {
  const DeviceCapabilityProfile({
    required this.manufacturer,
    required this.model,
    required this.osFamily,
    required this.osVersion,
    required this.hasBluetoothClassicAudio,
    required this.hasBleAudioSupport,
    required this.supportedCodecs,
    required this.canPlayArbitraryLocalAudio,
    required this.hasPersistentCompanionChannel,
    required this.estimatedLatencyMs,
  });

  factory DeviceCapabilityProfile.unknownPhoneOnly({
    required String manufacturer,
    required String model,
    required String osFamily,
    required String osVersion,
  }) {
    return DeviceCapabilityProfile(
      manufacturer: manufacturer,
      model: model,
      osFamily: osFamily,
      osVersion: osVersion,
      hasBluetoothClassicAudio: false,
      hasBleAudioSupport: false,
      supportedCodecs: const <AudioCodec>{},
      canPlayArbitraryLocalAudio: true,
      hasPersistentCompanionChannel: false,
      estimatedLatencyMs: 0,
    );
  }

  final String manufacturer;
  final String model;

  /// "wearos" | "watchos" | "garminOs" | "android" | "ios"
  final String osFamily;
  final String osVersion;

  /// Capacidade de fonte A2DP.
  final bool hasBluetoothClassicAudio;

  /// LE Audio (Bluetooth 5.2+).
  final bool hasBleAudioSupport;
  final Set<AudioCodec> supportedCodecs;

  /// Se o SO/API permite reproduzir um arquivo de áudio local arbitrário.
  final bool canPlayArbitraryLocalAudio;

  /// Se Data Layer / WatchConnectivity está disponível para comandos
  /// leves.
  final bool hasPersistentCompanionChannel;
  final int estimatedLatencyMs;

  bool get hasAnyBluetoothAudioRadio => hasBluetoothClassicAudio || hasBleAudioSupport;

  @override
  List<Object?> get props => <Object?>[
        manufacturer,
        model,
        osFamily,
        osVersion,
        hasBluetoothClassicAudio,
        hasBleAudioSupport,
        supportedCodecs,
        canPlayArbitraryLocalAudio,
        hasPersistentCompanionChannel,
        estimatedLatencyMs,
      ];
}
