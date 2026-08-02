import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:vai_marcia/features/audio_playback/data/datasources/audio_local_database.dart';
import 'package:vai_marcia/features/audio_playback/data/models/audio_clip_model.dart';

/// Wraps [AudioLocalDatabase] (metadata) + filesystem (actual audio bytes).
/// Kept behind an interface so [AudioRepositoryImpl] never touches Drift or
/// dart:io directly.
abstract interface class AudioLocalDataSource {
  Stream<List<AudioClipModel>> watchClipsByCategory(String categoryId);
  Future<AudioClipModel?> getCachedClip(String clipId);
  Future<void> upsertMetadata(AudioClipModel model);
  Future<String> cacheFileBytes(String clipId, List<int> bytes);
  Future<bool> isFileCached(String clipId, String? localFilePath);
  Future<void> incrementPlayCount(String clipId);
}

@LazySingleton(as: AudioLocalDataSource)
class AudioLocalDataSourceImpl implements AudioLocalDataSource {
  AudioLocalDataSourceImpl(this._db);

  final AudioLocalDatabase _db;

  @override
  Stream<List<AudioClipModel>> watchClipsByCategory(String categoryId) {
    return _db.watchClipsForCategory(categoryId).map(
          (List<CachedAudioClip> rows) => rows.map(_rowToModel).toList(growable: false),
        );
  }

  @override
  Future<AudioClipModel?> getCachedClip(String clipId) async {
    final CachedAudioClip? row = await _db.clipById(clipId);
    return row == null ? null : _rowToModel(row);
  }

  @override
  Future<void> upsertMetadata(AudioClipModel model) {
    return _db.upsertClip(
      CachedAudioClipsCompanion.insert(
        id: model.id,
        title: model.title,
        categoryId: model.categoryId,
        remoteUrl: model.remoteUrl,
        durationMs: model.durationMs,
        localFilePath: Value<String?>(model.localFilePath),
        tagsCsv: Value<String>(model.tags.join(',')),
      ),
    );
  }

  @override
  Future<String> cacheFileBytes(String clipId, List<int> bytes) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory audioDir = Directory(p.join(dir.path, 'audio_cache'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final File file = File(p.join(audioDir.path, '$clipId.m4a'));
    await file.writeAsBytes(bytes, flush: true);
    await _db.markLocalPath(clipId, file.path);
    return file.path;
  }

  @override
  Future<bool> isFileCached(String clipId, String? localFilePath) async {
    if (localFilePath == null) {
      return false;
    }
    return File(localFilePath).exists();
  }

  @override
  Future<void> incrementPlayCount(String clipId) {
    return _db.incrementPlayCount(clipId);
  }

  AudioClipModel _rowToModel(CachedAudioClip row) {
    return AudioClipModel(
      id: row.id,
      title: row.title,
      categoryId: row.categoryId,
      remoteUrl: row.remoteUrl,
      durationMs: row.durationMs,
      localFilePath: row.localFilePath,
      isCustomRecording: row.isCustomRecording,
      ownerUserId: row.ownerUserId,
      tags: row.tagsCsv.isEmpty ? const <String>[] : row.tagsCsv.split(','),
      playCount: row.playCount,
    );
  }
}
