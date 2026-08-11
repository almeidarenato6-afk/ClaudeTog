import 'dart:async' show unawaited;

import 'package:audio_session/audio_session.dart';
import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vai_marcia/core/constants/app_constants.dart';

/// Pool de instâncias [AudioPlayer] pré-aquecidas.
///
/// Por que usar pool em vez de um player compartilhado único: criar/
/// descartar um [AudioPlayer] (e o ExoPlayer/AVPlayer do lado da
/// plataforma que ele encapsula) tem um custo de setup não trivial, e
/// reutilizar um único player força cada toque a esperar o desmonte do
/// clipe anterior. Um pequeno pool round-robin permite que um duplo toque
/// rápido em dois botões diferentes inicie ambos os clipes com reprodução
/// sobreposta em vez de enfileirar, mantendo o toque-até-audível dentro
/// do orçamento de 150ms (ARCHITECTURE.md §4).
@lazySingleton
class AudioPlayerPool {
  AudioPlayerPool() : _players = List<AudioPlayer>.generate(
          AppConstants.audioPlayerPoolSize,
          (_) => AudioPlayer(),
        );

  final List<AudioPlayer> _players;
  int _nextIndex = 0;
  bool _sessionConfigured = false;

  /// Mantém a rota de áudio do SO (categoria "playback" / AudioFocus)
  /// reservada uma vez, de antemão, em vez de negociá-la a cada toque — a
  /// negociação é a maior fonte isolada de latência evitável no Android.
  Future<void> ensureAudioSessionConfigured() async {
    if (_sessionConfigured) {
      return;
    }
    final AudioSession session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
    _sessionConfigured = true;
  }

  /// Carrega [filePath] em um player antecipadamente (preload de
  /// categoria) para que [acquireAndPlay] só precise chamar `play()`, não
  /// `setFilePath()`.
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
