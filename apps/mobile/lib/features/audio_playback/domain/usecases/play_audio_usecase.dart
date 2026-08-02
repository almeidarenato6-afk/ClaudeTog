import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/audio_playback/domain/repositories/audio_repository.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';

/// The single most latency-sensitive call in the app: button tap -> this.
/// Deliberately thin — all the actual latency work (pooled players, warm
/// Bluetooth route, pre-cached files) lives in the repository/datasource so
/// this use case adds zero overhead of its own on the critical path.
@injectable
class PlayAudioUseCase {
  const PlayAudioUseCase(this._repository);

  final AudioRepository _repository;

  Future<Result<void>> call(String clipId, {required PlaybackStrategy strategy}) {
    return _repository.play(clipId, strategy: strategy);
  }
}
