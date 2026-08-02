import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/constants/app_strings.dart';
import 'package:vai_marcia/features/audio_playback/presentation/providers/audio_providers.dart';
import 'package:vai_marcia/features/favorites/domain/entities/favorite.dart';
import 'package:vai_marcia/features/favorites/presentation/providers/favorites_providers.dart';

class FavoritesList extends ConsumerWidget {
  const FavoritesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Favorite>> favoritesAsync = ref.watch(favoritesProvider);

    return favoritesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => const Center(child: Text(AppStrings.genericError)),
      data: (List<Favorite> favorites) {
        if (favorites.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(AppStrings.noFavoritesYet, textAlign: TextAlign.center),
          ),);
        }
        return ListView.builder(
          itemCount: favorites.length,
          itemBuilder: (BuildContext context, int index) {
            final Favorite favorite = favorites[index];
            return ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(favorite.clipId),
              onTap: () => ref.read(playbackControllerProvider.notifier).playClip(favorite.clipId),
            );
          },
        );
      },
    );
  }
}
