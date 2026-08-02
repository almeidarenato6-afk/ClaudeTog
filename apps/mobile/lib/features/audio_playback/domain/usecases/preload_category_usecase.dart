import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/audio_playback/domain/repositories/audio_repository.dart';

/// Called when a category screen opens (or is predicted to open next) so
/// every clip in it is already file-cached and pool-warmed by the time the
/// user's finger reaches a button.
@injectable
class PreloadCategoryUseCase {
  const PreloadCategoryUseCase(this._repository);

  final AudioRepository _repository;

  Future<Result<void>> call(String categoryId) {
    return _repository.preloadCategory(categoryId);
  }
}
