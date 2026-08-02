import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/favorites/domain/repositories/favorites_repository.dart';

@injectable
class ToggleFavoriteUseCase {
  const ToggleFavoriteUseCase(this._repository);

  final FavoritesRepository _repository;

  Future<Result<bool>> call(String clipId) => _repository.toggleFavorite(clipId);
}
