import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/audio_playback/domain/repositories/audio_repository.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';

/// A chamada mais sensível a latência de todo o app: toque no botão -> isto.
/// Propositalmente enxuta — todo o trabalho real de latência (players em
/// pool, rota Bluetooth quente, arquivos pré-cacheados) vive no
/// repository/datasource, para que este use case não adicione overhead
/// próprio ao caminho crítico.
@injectable
class PlayAudioUseCase {
  const PlayAudioUseCase(this._repository);

  final AudioRepository _repository;

  Future<Result<void>> call(String clipId, {required PlaybackStrategy strategy}) {
    return _repository.play(clipId, strategy: strategy);
  }
}
