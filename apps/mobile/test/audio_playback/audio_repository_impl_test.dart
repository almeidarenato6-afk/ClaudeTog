import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vai_marcia/features/audio_playback/data/datasources/audio_local_datasource.dart';
import 'package:vai_marcia/features/audio_playback/data/datasources/audio_player_pool.dart';
import 'package:vai_marcia/features/audio_playback/data/datasources/audio_remote_datasource.dart';
import 'package:vai_marcia/features/audio_playback/data/models/audio_clip_model.dart';
import 'package:vai_marcia/features/audio_playback/data/repositories/audio_repository_impl.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';

class MockAudioLocalDataSource extends Mock implements AudioLocalDataSource {}

class MockAudioRemoteDataSource extends Mock implements AudioRemoteDataSource {}

class MockAudioPlayerPool extends Mock implements AudioPlayerPool {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockAudioLocalDataSource local;
  late MockAudioRemoteDataSource remote;
  late MockAudioPlayerPool pool;
  late AudioRepositoryImpl repository;

  const AudioClipModel remoteClip = AudioClipModel(
    id: 'clip-1',
    title: 'Vai Márcia!',
    categoryId: 'motivacao',
    remoteUrl: 'audios/clip-1.m4a',
    durationMs: 1200,
  );

  setUp(() {
    local = MockAudioLocalDataSource();
    remote = MockAudioRemoteDataSource();
    pool = MockAudioPlayerPool();
    repository = AudioRepositoryImpl(local, remote, pool);

    registerFallbackValue(remoteClip);
  });

  group('play', () {
    test('plays instantly from cache without hitting network when file already cached', () async {
      final AudioClipModel cached = AudioClipModel(
        id: 'clip-1',
        title: 'Vai Márcia!',
        categoryId: 'motivacao',
        remoteUrl: 'audios/clip-1.m4a',
        durationMs: 1200,
        localFilePath: '/cache/clip-1.m4a',
      );
      when(() => local.getCachedClip('clip-1')).thenAnswer((_) async => cached);
      when(() => local.isFileCached('clip-1', '/cache/clip-1.m4a')).thenAnswer((_) async => true);
      when(() => pool.acquireAndPlay('/cache/clip-1.m4a')).thenAnswer((_) async {});
      when(() => local.incrementPlayCount('clip-1')).thenAnswer((_) async {});
      when(() => remote.incrementPlayCount('clip-1')).thenAnswer((_) async {});

      final result = await repository.play('clip-1', strategy: PlaybackStrategy.phoneOnly);

      expect(result.isOk, isTrue);
      verify(() => pool.acquireAndPlay('/cache/clip-1.m4a')).called(1);
      verifyNever(() => remote.downloadClipBytes(any()));
    });

    test('downloads and caches before playing when clip is not yet cached', () async {
      when(() => local.getCachedClip('clip-1')).thenAnswer((_) async => null);
      when(() => local.isFileCached('clip-1', null)).thenAnswer((_) async => false);
      when(() => remote.getClipById('clip-1')).thenAnswer((_) async => remoteClip);
      when(() => remote.downloadClipBytes('audios/clip-1.m4a')).thenAnswer((_) async => <int>[1, 2, 3]);
      when(() => local.cacheFileBytes('clip-1', <int>[1, 2, 3])).thenAnswer((_) async => '/cache/clip-1.m4a');
      when(() => local.upsertMetadata(any())).thenAnswer((_) async {});
      when(() => pool.acquireAndPlay('/cache/clip-1.m4a')).thenAnswer((_) async {});
      when(() => local.incrementPlayCount('clip-1')).thenAnswer((_) async {});
      when(() => remote.incrementPlayCount('clip-1')).thenAnswer((_) async {});

      final result = await repository.play('clip-1', strategy: PlaybackStrategy.direct);

      expect(result.isOk, isTrue);
      verify(() => remote.downloadClipBytes('audios/clip-1.m4a')).called(1);
      verify(() => pool.acquireAndPlay('/cache/clip-1.m4a')).called(1);
    });

    test('returns PlaybackFailure when the player pool throws', () async {
      when(() => local.getCachedClip('clip-1')).thenAnswer((_) async => null);
      when(() => local.isFileCached('clip-1', null)).thenAnswer((_) async => false);
      when(() => remote.getClipById('clip-1')).thenThrow(StateError('network down'));

      final result = await repository.play('clip-1', strategy: PlaybackStrategy.phoneOnly);

      expect(result.isErr, isTrue);
    });
  });

  group('preloadCategory', () {
    test('downloads only clips missing a valid local file and warms the pool for every clip', () async {
      const AudioClipModel alreadyCached = AudioClipModel(
        id: 'clip-2',
        title: 'Bora!',
        categoryId: 'motivacao',
        remoteUrl: 'audios/clip-2.m4a',
        durationMs: 900,
      );

      when(() => remote.watchClipsByCategory('motivacao'))
          .thenAnswer((_) => Stream<List<AudioClipModel>>.value(<AudioClipModel>[remoteClip, alreadyCached]));

      when(() => local.getCachedClip('clip-1')).thenAnswer((_) async => null);
      when(() => local.isFileCached('clip-1', null)).thenAnswer((_) async => false);
      when(() => remote.downloadClipBytes('audios/clip-1.m4a')).thenAnswer((_) async => <int>[9]);
      when(() => local.cacheFileBytes('clip-1', <int>[9])).thenAnswer((_) async => '/cache/clip-1.m4a');

      final AudioClipModel cachedTwo = AudioClipModel(
        id: 'clip-2',
        title: 'Bora!',
        categoryId: 'motivacao',
        remoteUrl: 'audios/clip-2.m4a',
        durationMs: 900,
        localFilePath: '/cache/clip-2.m4a',
      );
      when(() => local.getCachedClip('clip-2')).thenAnswer((_) async => cachedTwo);
      when(() => local.isFileCached('clip-2', '/cache/clip-2.m4a')).thenAnswer((_) async => true);

      when(() => local.upsertMetadata(any())).thenAnswer((_) async {});
      final MockAudioPlayer fakePlayer = MockAudioPlayer();
      when(() => pool.preload('clip-1', '/cache/clip-1.m4a')).thenAnswer((_) async => fakePlayer);
      when(() => pool.preload('clip-2', '/cache/clip-2.m4a')).thenAnswer((_) async => fakePlayer);

      final result = await repository.preloadCategory('motivacao');

      expect(result.isOk, isTrue);
      verify(() => remote.downloadClipBytes('audios/clip-1.m4a')).called(1);
      verifyNever(() => remote.downloadClipBytes('audios/clip-2.m4a'));
      verify(() => pool.preload('clip-1', '/cache/clip-1.m4a')).called(1);
      verify(() => pool.preload('clip-2', '/cache/clip-2.m4a')).called(1);
    });
  });
}
