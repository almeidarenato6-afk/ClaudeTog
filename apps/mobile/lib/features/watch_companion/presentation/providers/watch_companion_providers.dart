import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/audio_playback/presentation/providers/audio_providers.dart';
import 'package:vai_marcia/features/watch_companion/domain/entities/watch_command.dart';
import 'package:vai_marcia/features/watch_companion/domain/repositories/watch_companion_channel.dart';

final Provider<WatchCompanionChannel> watchCompanionChannelProvider = Provider<WatchCompanionChannel>(
  (Ref ref) => getIt<WatchCompanionChannel>(),
);

/// Subscribes to the watch's command stream for the lifetime of the
/// provider and forwards `playAudio` commands straight to
/// [PlaybackController] — this is the entire Cenário B relay path on the
/// phone side. Kept alive from app boot (see main.dart) so the channel
/// itself stays "warm", per ARCHITECTURE.md §4.
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
