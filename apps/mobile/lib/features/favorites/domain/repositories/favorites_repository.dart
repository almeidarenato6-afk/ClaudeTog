import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/favorites/domain/entities/favorite.dart';

abstract interface class FavoritesRepository {
  Stream<List<Favorite>> watchFavorites();

  Stream<bool> watchIsFavorite(String clipId);

  Future<Result<bool>> toggleFavorite(String clipId);
}
