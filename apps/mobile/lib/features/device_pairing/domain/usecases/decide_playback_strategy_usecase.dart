import 'package:vai_marcia/features/device_pairing/domain/entities/device_capability_profile.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';

/// Função de decisão pura transcrita 1:1 de docs/DEVICE_DETECTION.md
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
/// Mantida como um use case independente (sem I/O, sem async) para que a
/// tabela de ramos seja testável unitariamente de forma exaustiva sem
/// mockar nenhum repositório.
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
