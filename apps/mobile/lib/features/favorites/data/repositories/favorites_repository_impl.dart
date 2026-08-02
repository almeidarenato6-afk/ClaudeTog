import 'dart:async' show unawaited;

import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/favorites/data/datasources/favorites_local_datasource.dart';
import 'package:vai_marcia/features/favorites/data/datasources/favorites_remote_datasource.dart';
import 'package:vai_marcia/features/favorites/domain/entities/favorite.dart';
import 'package:vai_marcia/features/favorites/domain/repositories/favorites_repository.dart';

@LazySingleton(as: FavoritesRepository)
class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._local, this._remote);

  final FavoritesLocalDataSource _local;
  final FavoritesRemoteDataSource _remote;

  @override
  Stream<List<Favorite>> watchFavorites() {
    return _local.watchFavoriteClipIds().map(
          (List<String> ids) =>
              ids.map((String id) => Favorite(clipId: id, addedAt: DateTime.now())).toList(growable: false),
        );
  }

  @override
  Stream<bool> watchIsFavorite(String clipId) {
    return _local.watchFavoriteClipIds().map((List<String> ids) => ids.contains(clipId));
  }

  @override
  Future<Result<bool>> toggleFavorite(String clipId) async {
    try {
      final bool current = await _local.isFavorite(clipId);
      final bool next = !current;
      await _local.setFavorite(clipId, next);
      // Local (Drift) is authoritative for the toggle's success — remote
      // mirroring is best-effort and must never fail the user-visible
      // action just because the device is offline.
      unawaited(_remote.setFavorite(clipId, next).catchError((_) {}));
      return Result<bool>.ok(next);
    } on Object catch (e) {
      return Result<bool>.err(CacheFailure('Falha ao favoritar áudio', cause: e));
    }
  }
}
