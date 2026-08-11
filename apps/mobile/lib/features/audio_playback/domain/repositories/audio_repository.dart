import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/audio_playback/domain/entities/audio_clip.dart';
import 'package:vai_marcia/features/device_pairing/domain/entities/playback_strategy.dart';

abstract interface class AudioRepository {
  Stream<List<AudioClip>> watchClipsByCategory(String categoryId);

  Future<Result<AudioClip>> getClipById(String clipId);

  /// Baixa e fixa todo clipe em [categoryId] no cache local + aquece uma
  /// entrada de pool [AudioPlayer] para cada um, para que a categoria
  /// inteira esteja pronta para reprodução instantânea assim que o
  /// usuário a abrir (ARCHITECTURE.md §4).
  Future<Result<void>> preloadCategory(String categoryId);

  /// Reproduz [clipId] com latência mínima. [strategy] diz à
  /// implementação se deve também retransmitir o comando a um relógio
  /// pareado (RELAY) ou apenas reproduzir localmente (DIRECT é apenas do
  /// lado do relógio na perspectiva do celular; PHONE_ONLY é sempre
  /// somente local).
  Future<Result<void>> play(String clipId, {required PlaybackStrategy strategy});

  Future<Result<void>> stopAll();

  Future<Result<void>> incrementPlayCount(String clipId);
}
