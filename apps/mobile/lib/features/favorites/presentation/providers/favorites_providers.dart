import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/analytics/domain/analytics_service.dart';
import 'package:vai_marcia/features/favorites/domain/entities/favorite.dart';
import 'package:vai_marcia/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:vai_marcia/features/favorites/domain/usecases/toggle_favorite_usecase.dart';

final Provider<FavoritesRepository> favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (Ref ref) => getIt<FavoritesRepository>(),
);

final StreamProvider<List<Favorite>> favoritesProvider = StreamProvider<List<Favorite>>(
  (Ref ref) => ref.watch(favoritesRepositoryProvider).watchFavorites(),
);

final StreamProviderFamily<bool, String> isFavoriteStreamProvider = StreamProvider.family<bool, String>(
  (Ref ref, String clipId) => ref.watch(favoritesRepositoryProvider).watchIsFavorite(clipId),
);

/// Convenience sync accessor for widgets that only need "is this favorite
/// right now" without handling loading/error branches inline.
final ProviderFamily<bool, String> isFavoriteProvider = Provider.family<bool, String>(
  (Ref ref, String clipId) => ref.watch(isFavoriteStreamProvider(clipId)).valueOrNull ?? false,
);

final Provider<Future<void> Function(String)> toggleFavoriteProvider = Provider<Future<void> Function(String)>(
  (Ref ref) {
    final ToggleFavoriteUseCase useCase = getIt<ToggleFavoriteUseCase>();
    final AnalyticsService analytics = getIt<AnalyticsService>();
    return (String clipId) async {
      final result = await useCase(clipId);
      result.when(
        ok: (bool isFavorite) => analytics.logFavoriteToggled(clipId: clipId, isFavorite: isFavorite),
        err: (_) {},
      );
    };
  },
);
