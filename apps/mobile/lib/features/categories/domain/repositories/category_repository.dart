import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/categories/domain/entities/audio_category.dart';

abstract interface class CategoryRepository {
  Stream<List<AudioCategory>> watchCategories();

  Future<Result<AudioCategory>> createCustomCategory(String name);
}
