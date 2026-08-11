import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';
import 'package:vai_marcia/features/device_pairing/domain/repositories/device_pairing_repository.dart';
import 'package:vai_marcia/features/device_pairing/domain/usecases/run_capability_probe_usecase.dart';

final Provider<DevicePairingRepository> devicePairingRepositoryProvider = Provider<DevicePairingRepository>(
  (Ref ref) => getIt<DevicePairingRepository>(),
);

final Provider<RunCapabilityProbeUseCase> runCapabilityProbeUseCaseProvider = Provider<RunCapabilityProbeUseCase>(
  (Ref ref) => getIt<RunCapabilityProbeUseCase>(),
);

/// A estratégia já decidida, carregada uma vez na inicialização e
/// reexecutada sempre que [refreshCapabilityProbeProvider] é invocado
/// (pareamento/despareamento de Bluetooth, novo smartwatch pareado) —
/// nunca recalculada no caminho de tap-to-play.
final FutureProvider<PlaybackStrategy> playbackStrategyProvider = FutureProvider<PlaybackStrategy>(
  (Ref ref) async {
    final DevicePairingRepository repo = ref.watch(devicePairingRepositoryProvider);
    final PlaybackStrategy? persisted = (await repo.loadPersistedStrategy()).valueOrNull;
    if (persisted != null) {
      return persisted;
    }

    final RunCapabilityProbeUseCase probe = ref.watch(runCapabilityProbeUseCaseProvider);
    final CapabilityProbeOutcome? outcome = (await probe()).valueOrNull;
    return outcome?.strategy ?? PlaybackStrategy.phoneOnly;
  },
);

final NotifierProvider<CapabilityProbeController, AsyncValue<CapabilityProbeOutcome?>>
    capabilityProbeControllerProvider =
    NotifierProvider<CapabilityProbeController, AsyncValue<CapabilityProbeOutcome?>>(
  CapabilityProbeController.new,
);

/// Controla o assistente "Vamos configurar seu equipamento": executa a
/// sondagem sob demanda e republica [playbackStrategyProvider] assim que
/// ela termina.
class CapabilityProbeController extends Notifier<AsyncValue<CapabilityProbeOutcome?>> {
  @override
  AsyncValue<CapabilityProbeOutcome?> build() => const AsyncValue<CapabilityProbeOutcome?>.data(null);

  Future<void> runProbe() async {
    state = const AsyncValue<CapabilityProbeOutcome?>.loading();
    final RunCapabilityProbeUseCase probe = ref.read(runCapabilityProbeUseCaseProvider);
    final result = await probe();
    result.when(
      ok: (CapabilityProbeOutcome outcome) {
        state = AsyncValue<CapabilityProbeOutcome?>.data(outcome);
        ref.invalidate(playbackStrategyProvider);
      },
      err: (failure) {
        state = AsyncValue<CapabilityProbeOutcome?>.error(failure, StackTrace.current);
      },
    );
  }
}
