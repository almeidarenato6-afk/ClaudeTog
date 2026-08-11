import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/audio_playback/domain/repositories/audio_repository.dart';

/// Chamado quando a tela de uma categoria abre (ou é prevista para abrir
/// em seguida), para que cada clipe nela já esteja em cache de arquivo e
/// aquecido no pool quando o dedo do usuário alcançar um botão.
@injectable
class PreloadCategoryUseCase {
  const PreloadCategoryUseCase(this._repository);

  final AudioRepository _repository;

  Future<Result<void>> call(String categoryId) {
    return _repository.preloadCategory(categoryId);
  }
}
