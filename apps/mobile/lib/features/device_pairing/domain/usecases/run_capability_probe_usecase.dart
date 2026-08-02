import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/device_capability_profile.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/paired_speaker.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';
import 'package:vai_marcia/features/device_pairing/domain/repositories/device_pairing_repository.dart';
import 'package:vai_marcia/features/device_pairing/domain/usecases/decide_playback_strategy_usecase.dart';

class CapabilityProbeOutcome {
  const CapabilityProbeOutcome({
    required this.watchProfile,
    required this.pairedSpeakers,
    required this.strategy,
  });

  final DeviceCapabilityProfile? watchProfile;
  final List<PairedSpeaker> pairedSpeakers;
  final PlaybackStrategy strategy;
}

/// Orchestrates DEVICE_DETECTION.md steps 1-5: discover watch, decide
/// strategy, discover speaker, persist. Runs at app boot, on Bluetooth
/// pair/unpair system events, and on watch-pairing change — never
/// synchronously in the tap-to-play path (ARCHITECTURE.md §4).
@lazySingleton
class RunCapabilityProbeUseCase {
  const RunCapabilityProbeUseCase(
    this._repository, {
    DecidePlaybackStrategyUseCase decide = const DecidePlaybackStrategyUseCase(),
  }) : _decide = decide;

  final DevicePairingRepository _repository;
  final DecidePlaybackStrategyUseCase _decide;

  Future<Result<CapabilityProbeOutcome>> call() async {
    final Result<DeviceCapabilityProfile?> watchResult = await _repository.discoverPairedWatch();
    if (watchResult.isErr) {
      return Result<CapabilityProbeOutcome>.err(watchResult.failureOrNull!);
    }

    final Result<List<PairedSpeaker>> speakersResult = await _repository.discoverPairedSpeakers();
    if (speakersResult.isErr) {
      return Result<CapabilityProbeOutcome>.err(speakersResult.failureOrNull!);
    }

    final DeviceCapabilityProfile? watchProfile = watchResult.valueOrNull;
    final PlaybackStrategy strategy = _decide(watchProfile);

    final Result<void> persistResult = await _repository.persistStrategy(strategy);
    if (persistResult.isErr) {
      return Result<CapabilityProbeOutcome>.err(persistResult.failureOrNull!);
    }

    return Result<CapabilityProbeOutcome>.ok(
      CapabilityProbeOutcome(
        watchProfile: watchProfile,
        pairedSpeakers: speakersResult.valueOrNull ?? const <PairedSpeaker>[],
        strategy: strategy,
      ),
    );
  }
}
