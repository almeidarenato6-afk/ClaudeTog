import 'package:vai_marcia/features/device_pairing/domain/entities/device_capability_profile.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';

/// Pure decision function transcribed 1:1 from docs/DEVICE_DETECTION.md
/// §"Decisão de estratégia":
///
/// ```
/// se watch.hasBluetoothClassicAudio ou watch.hasBleAudioSupport:
///     se watch.canPlayArbitraryLocalAudio:
///         estrategia = DIRECT
///     senao:
///         estrategia = RELAY
/// senao:
///     estrategia = RELAY se watch.hasPersistentCompanionChannel
///     senao: PHONE_ONLY
/// ```
///
/// Kept as a standalone use case (no I/O, no async) so the branch table is
/// exhaustively unit-testable without mocking any repository.
class DecidePlaybackStrategyUseCase {
  const DecidePlaybackStrategyUseCase();

  PlaybackStrategy call(DeviceCapabilityProfile? watchProfile) {
    if (watchProfile == null) {
      return PlaybackStrategy.phoneOnly;
    }

    if (watchProfile.hasAnyBluetoothAudioRadio) {
      return watchProfile.canPlayArbitraryLocalAudio
          ? PlaybackStrategy.direct
          : PlaybackStrategy.relay;
    }

    return watchProfile.hasPersistentCompanionChannel
        ? PlaybackStrategy.relay
        : PlaybackStrategy.phoneOnly;
  }
}
