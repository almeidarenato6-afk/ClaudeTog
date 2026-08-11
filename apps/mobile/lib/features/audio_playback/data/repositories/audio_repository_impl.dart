import 'dart:async' show unawaited;

import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/audio_playback/data/datasources/audio_local_datasource.dart';
import 'package:vai_marcia/features/audio_playback/data/datasources/audio_player_pool.dart';
import 'package:vai_marcia/features/audio_playback/data/datasources/audio_remote_datasource.dart';
import 'package:vai_marcia/features/audio_playback/data/models/audio_clip_model.dart';
import 'package:vai_marcia/features/audio_playback/domain/entities/audio_clip.dart';
import 'package:vai_marcia/features/audio_playback/domain/repositories/audio_repository.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';

@LazySingleton(as: AudioRepository)
class AudioRepositoryImpl implements AudioRepository {
  AudioRepositoryImpl(
    this._local,
    this._remote,
    this._playerPool,
  );

  final AudioLocalDataSource _local;
  final AudioRemoteDataSource _remote;
  final AudioPlayerPool _playerPool;

  @override
  Stream<List<AudioClip>> watchClipsByCategory(String categoryId) {
    // Offline-first (ARCHITECTURE.md §2): o cache local emite
    // imediatamente; a sincronização remota abaixo o atualiza em segundo
    // plano sem bloquear a UI.
    unawaited(_syncCategoryFromRemote(categoryId));
    return _local
        .watchClipsByCategory(categoryId)
        .map((List<AudioClipModel> models) => models.map((AudioClipModel m) => m.toEntity()).toList(growable: false));
  }

  Future<void> _syncCategoryFromRemote(String categoryId) async {
    try {
      await for (final List<AudioClipModel> remoteModels in _remote.watchClipsByCategory(categoryId).take(1)) {
        for (final AudioClipModel model in remoteModels) {
          final AudioClipModel? cached = await _local.getCachedClip(model.id);
          await _local.upsertMetadata(
            AudioClipModel(
              id: model.id,
              title: model.title,
              categoryId: model.categoryId,
              remoteUrl: model.remoteUrl,
              durationMs: model.durationMs,
              localFilePath: cached?.localFilePath,
              isCustomRecording: model.isCustomRecording,
              ownerUserId: model.ownerUserId,
              tags: model.tags,
              playCount: model.playCount,
            ),
          );
        }
      }
    } on Object {
      // Sincronização em segundo plano de melhor esforço; offline-first
      // significa que uma sincronização falha nunca deve aparecer como
      // erro na UI — os dados em cache continuam válidos.
    }
  }

  @override
  Future<Result<AudioClip>> getClipById(String clipId) async {
    try {
      final AudioClipModel? cached = await _local.getCachedClip(clipId);
      if (cached != null) {
        return Result<AudioClip>.ok(cached.toEntity());
      }
      final AudioClipModel remote = await _remote.getClipById(clipId);
      await _local.upsertMetadata(remote);
      return Result<AudioClip>.ok(remote.toEntity());
    } on Object catch (e) {
      return Result<AudioClip>.err(NetworkFailure('Falha ao buscar áudio $clipId', cause: e));
    }
  }

  @override
  Future<Result<void>> preloadCategory(String categoryId) async {
    try {
      final List<AudioClipModel> remoteModels = await _remote.watchClipsByCategory(categoryId).first;
      for (final AudioClipModel model in remoteModels) {
        final AudioClipModel? cached = await _local.getCachedClip(model.id);
        String? localFilePath = cached?.localFilePath;
        final bool fileStillExists = await _local.isFileCached(model.id, localFilePath);

        if (localFilePath == null || !fileStillExists) {
          final List<int> bytes = await _remote.downloadClipBytes(model.remoteUrl);
          localFilePath = await _local.cacheFileBytes(model.id, bytes);
        }

        await _local.upsertMetadata(
          AudioClipModel(
            id: model.id,
            title: model.title,
            categoryId: model.categoryId,
            remoteUrl: model.remoteUrl,
            durationMs: model.durationMs,
            localFilePath: localFilePath,
            isCustomRecording: model.isCustomRecording,
            ownerUserId: model.ownerUserId,
            tags: model.tags,
            playCount: model.playCount,
          ),
        );

        await _playerPool.preload(model.id, localFilePath);
      }
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(NetworkFailure('Falha ao pré-carregar categoria $categoryId', cause: e));
    }
  }

  @override
  Future<Result<void>> play(String clipId, {required PlaybackStrategy strategy}) async {
    try {
      final AudioClipModel? cached = await _local.getCachedClip(clipId);
      final bool fileExists = await _local.isFileCached(clipId, cached?.localFilePath);

      String? localFilePath = cached?.localFilePath;
      if (cached == null || !fileExists) {
        final AudioClipModel remote = await _remote.getClipById(clipId);
        final List<int> bytes = await _remote.downloadClipBytes(remote.remoteUrl);
        localFilePath = await _local.cacheFileBytes(clipId, bytes);
        await _local.upsertMetadata(
          AudioClipModel(
            id: remote.id,
            title: remote.title,
            categoryId: remote.categoryId,
            remoteUrl: remote.remoteUrl,
            durationMs: remote.durationMs,
            localFilePath: localFilePath,
            isCustomRecording: remote.isCustomRecording,
            ownerUserId: remote.ownerUserId,
            tags: remote.tags,
            playCount: remote.playCount,
          ),
        );
      }

      await _playerPool.acquireAndPlay(localFilePath!);
      unawaited(incrementPlayCount(clipId));
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(PlaybackFailure('Falha ao reproduzir áudio $clipId', cause: e));
    }
  }

  @override
  Future<Result<void>> stopAll() async {
    try {
      await _playerPool.stopAll();
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(PlaybackFailure('Falha ao parar reprodução', cause: e));
    }
  }

  @override
  Future<Result<void>> incrementPlayCount(String clipId) async {
    try {
      await _local.incrementPlayCount(clipId);
      unawaited(_remote.incrementPlayCount(clipId));
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(CacheFailure('Falha ao registrar reprodução', cause: e));
    }
  }
}
