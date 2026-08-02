import 'package:injectable/injectable.dart';
import 'package:vai_marcia/features/audio_playback/data/datasources/audio_local_database.dart';

abstract interface class FavoritesLocalDataSource {
  Stream<List<String>> watchFavoriteClipIds();
  Future<bool> isFavorite(String clipId);
  Future<void> setFavorite(String clipId, bool isFavorite);
}

@LazySingleton(as: FavoritesLocalDataSource)
class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  FavoritesLocalDataSourceImpl(this._db);

  final AudioLocalDatabase _db;

  @override
  Stream<List<String>> watchFavoriteClipIds() {
    return _db
        .watchFavorites()
        .map((List<CachedAudioClip> rows) => rows.map((CachedAudioClip r) => r.id).toList(growable: false));
  }

  @override
  Future<bool> isFavorite(String clipId) async {
    final CachedAudioClip? clip = await _db.clipById(clipId);
    return clip?.isFavorite ?? false;
  }

  @override
  Future<void> setFavorite(String clipId, bool isFavorite) {
    return _db.setFavorite(clipId, isFavorite);
  }
}
