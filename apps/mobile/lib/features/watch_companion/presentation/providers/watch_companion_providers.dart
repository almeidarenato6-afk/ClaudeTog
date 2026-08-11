import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/audio_playback/presentation/providers/audio_providers.dart';
import 'package:vai_marcia/features/watch_companion/domain/entities/watch_command.dart';
import 'package:vai_marcia/features/watch_companion/domain/repositories/watch_companion_channel.dart';

final Provider<WatchCompanionChannel> watchCompanionChannelProvider = Provider<WatchCompanionChannel>(
  (Ref ref) => getIt<WatchCompanionChannel>(),
);

/// Inscreve-se no stream de comandos do smartwatch pela vida útil do
/// provider e repassa comandos `playAudio` diretamente para
/// [PlaybackController] — este é todo o caminho de relay do Cenário B no
/// lado do telefone. Mantido vivo desde a inicialização do app (veja
/// main.dart) para que o canal em si permaneça "aquecido", conforme
/// ARCHITECTURE.md §4.
final Provider<void> watchCommandRelayProvider = Provider<void>(
  (Ref ref) {
    final WatchCompanionChannel channel = ref.watch(watchCompanionChannelProvider);
    final subscription = channel.watchIncomingCommands().listen((WatchCommand command) {
      if (command.type == WatchCommandType.playAudio && command.audioId != null) {
        ref.read(playbackControllerProvider.notifier).playClip(command.audioId!);
      }
    });
    ref.onDispose(subscription.cancel);
  },
);
