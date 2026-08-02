import 'dart:async' show unawaited;

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/analytics/domain/analytics_service.dart';
import 'package:vai_marcia/features/audio_playback/domain/usecases/play_audio_usecase.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';
import 'package:vai_marcia/features/device_pairing/presentation/providers/device_pairing_providers.dart';

class PlaybackState extends Equatable {
  const PlaybackState({this.currentlyPlayingClipId, this.lastFailure});

  final String? currentlyPlayingClipId;
  final Failure? lastFailure;

  PlaybackState copyWith({String? currentlyPlayingClipId, Failure? lastFailure}) {
    return PlaybackState(
      currentlyPlayingClipId: currentlyPlayingClipId,
      lastFailure: lastFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[currentlyPlayingClipId, lastFailure];
}

/// Bridges the UI tap event to [PlayAudioUseCase], resolving the current
/// [PlaybackStrategy] first (already-computed, never probed synchronously
/// here — see device_pairing feature) and logging the analytics event.
class PlaybackController extends Notifier<PlaybackState> {
  late final PlayAudioUseCase _playAudioUseCase = getIt<PlayAudioUseCase>();
  late final AnalyticsService _analytics = getIt<AnalyticsService>();

  @override
  PlaybackState build() => const PlaybackState();

  Future<void> playClip(String clipId) async {
    state = state.copyWith(currentlyPlayingClipId: clipId);

    final PlaybackStrategy strategy = ref.read(playbackStrategyProvider).valueOrNull ?? PlaybackStrategy.phoneOnly;

    final Result<void> result = await _playAudioUseCase(clipId, strategy: strategy);

    result.when(
      ok: (_) {
        state = state.copyWith(currentlyPlayingClipId: clipId);
        unawaited(_analytics.logAudioPlayed(clipId: clipId, strategy: strategy.name));
      },
      err: (Failure failure) {
        state = state.copyWith(lastFailure: failure);
      },
    );
  }
}
