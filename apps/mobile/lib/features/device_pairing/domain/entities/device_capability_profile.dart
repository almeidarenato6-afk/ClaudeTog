import 'package:equatable/equatable.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/audio_codec.dart';

/// Mirrors the model documented in docs/DEVICE_DETECTION.md — kept as a
/// pure Dart entity (no Flutter/Firebase import) so the decision algorithm
/// in [DecidePlaybackStrategyUseCase] is trivially unit-testable.
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

  /// A2DP source capability.
  final bool hasBluetoothClassicAudio;

  /// LE Audio (Bluetooth 5.2+).
  final bool hasBleAudioSupport;
  final Set<AudioCodec> supportedCodecs;

  /// Whether the OS/API allows playing an arbitrary local audio file.
  final bool canPlayArbitraryLocalAudio;

  /// Whether Data Layer / WatchConnectivity is available for lightweight
  /// commands.
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
