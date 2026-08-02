import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/categories/domain/entities/audio_category.dart';
import 'package:vai_marcia/features/categories/domain/repositories/category_repository.dart';

final Provider<CategoryRepository> categoryRepositoryProvider = Provider<CategoryRepository>(
  (Ref ref) => getIt<CategoryRepository>(),
);

final StreamProvider<List<AudioCategory>> categoriesProvider = StreamProvider<List<AudioCategory>>(
  (Ref ref) => ref.watch(categoryRepositoryProvider).watchCategories(),
);

final StateProvider<String?> selectedCategoryIdProvider = StateProvider<String?>((Ref ref) => null);
