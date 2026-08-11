import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/constants/app_strings.dart';
import 'package:vai_marcia/core/extensions/context_extensions.dart';
import 'package:vai_marcia/features/audio_playback/domain/entities/audio_clip.dart';
import 'package:vai_marcia/features/audio_playback/presentation/providers/audio_providers.dart';
import 'package:vai_marcia/features/favorites/presentation/providers/favorites_providers.dart';

/// A superfície de interação central do app: uma grade de grandes áreas
/// de toque, uma por clipe na categoria ativa. Cada toque vai direto para
/// [PlaybackController.playClip] — sem tela de confirmação intermediária,
/// já que cada frame extra aqui consome o orçamento de 150ms.
class BigButtonGrid extends ConsumerWidget {
  const BigButtonGrid({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AudioClip>> clipsAsync = ref.watch(clipsByCategoryProvider(categoryId));

    return clipsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => Center(
        child: Text(AppStrings.genericError, style: context.textStyles.bodyLarge),
      ),
      data: (List<AudioClip> clips) {
        if (clips.isEmpty) {
          return Center(
            child: Text(AppStrings.noClipsInCategory, style: context.textStyles.bodyLarge),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: clips.length,
          itemBuilder: (BuildContext context, int index) => _BigButton(clip: clips[index]),
        );
      },
    );
  }
}

class _BigButton extends ConsumerWidget {
  const _BigButton({required this.clip});

  final AudioClip clip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? playingId = ref.watch(playbackControllerProvider).currentlyPlayingClipId;
    final bool isPlaying = playingId == clip.id;
    final bool isFavorite = ref.watch(isFavoriteProvider(clip.id));

    return Material(
      color: isPlaying ? context.colors.primary : context.colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => ref.read(playbackControllerProvider.notifier).playClip(clip.id),
        onLongPress: () => ref.read(toggleFavoriteProvider)(clip.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: <Widget>[
              Center(
                child: Text(
                  clip.title,
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleMedium?.copyWith(
                    color: isPlaying ? context.colors.onPrimary : context.colors.onSurface,
                  ),
                ),
              ),
              if (isFavorite)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.favorite,
                    size: 18,
                    color: isPlaying ? context.colors.onPrimary : context.colors.primary,
                  ),
                ),
              if (!clip.isReadyForInstantPlayback)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Icon(
                    Icons.cloud_download_outlined,
                    size: 16,
                    color: (isPlaying ? context.colors.onPrimary : context.colors.onSurface).withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
