import 'dart:async' show unawaited;

import 'package:audio_session/audio_session.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';

/// Pool of pre-warmed [AudioPlayer] instances.
///
/// Why pool instead of one shared player: creating/disposing an
/// [AudioPlayer] (and the platform-side ExoPlayer/AVPlayer it wraps) has
/// non-trivial setup cost, and reusing a single player forces every tap to
/// wait for the previous clip's teardown. A small round-robin pool lets a
/// rapid double-tap on two different buttons start both clips with
/// overlapping playback instead of queueing, keeping tap-to-audible under
/// the 150ms budget (ARCHITECTURE.md §4).
@lazySingleton
class AudioPlayerPool {
  AudioPlayerPool() : _players = List<AudioPlayer>.generate(
          AppConstants.audioPlayerPoolSize,
          (_) => AudioPlayer(),
        );

  final List<AudioPlayer> _players;
  int _nextIndex = 0;
  bool _sessionConfigured = false;

  /// Keeps the OS audio route ("playback" category / AudioFocus) claimed
  /// once, up front, instead of negotiating it per tap — negotiation is
  /// the single largest source of avoidable latency on Android.
  Future<void> ensureAudioSessionConfigured() async {
    if (_sessionConfigured) {
      return;
    }
    final AudioSession session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
    _sessionConfigured = true;
  }

  /// Loads [filePath] into a player ahead of time (category preload) so
  /// [acquireAndPlay] only has to call `play()`, not `setFilePath()`.
  Future<AudioPlayer> preload(String cacheKey, String filePath) async {
    await ensureAudioSessionConfigured();
    final AudioPlayer player = _players[_nextIndex];
    _nextIndex = (_nextIndex + 1) % _players.length;
    await player.setFilePath(filePath, preload: true);
    return player;
  }

  Future<void> acquireAndPlay(String filePath) async {
    await ensureAudioSessionConfigured();
    final AudioPlayer player = _players[_nextIndex];
    _nextIndex = (_nextIndex + 1) % _players.length;

    final Duration? currentDuration = player.duration;
    final bool alreadyLoaded = player.audioSource != null && currentDuration != null;
    if (!alreadyLoaded) {
      await player.setFilePath(filePath);
    }
    await player.seek(Duration.zero);
    unawaited(player.play());
  }

  Future<void> stopAll() async {
    await Future.wait(_players.map((AudioPlayer p) => p.stop()));
  }

  Future<void> dispose() async {
    await Future.wait(_players.map((AudioPlayer p) => p.dispose()));
  }
}
