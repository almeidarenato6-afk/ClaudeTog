import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/audio_playback/domain/entities/audio_clip.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';

abstract interface class AudioRepository {
  Stream<List<AudioClip>> watchClipsByCategory(String categoryId);

  Future<Result<AudioClip>> getClipById(String clipId);

  /// Downloads and pins every clip in [categoryId] into local cache +
  /// warms an [AudioPlayer] pool entry for each, so the whole category is
  /// instant-play the moment the user opens it (ARCHITECTURE.md §4).
  Future<Result<void>> preloadCategory(String categoryId);

  /// Plays [clipId] with minimal latency. [strategy] tells the
  /// implementation whether to also relay the command to a paired watch
  /// (RELAY) or just play locally (DIRECT is watch-side only from the
  /// phone's perspective; PHONE_ONLY is always local-only).
  Future<Result<void>> play(String clipId, {required PlaybackStrategy strategy});

  Future<Result<void>> stopAll();

  Future<Result<void>> incrementPlayCount(String clipId);
}
