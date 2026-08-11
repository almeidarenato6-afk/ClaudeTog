import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:vai_marcia/features/categories/data/models/audio_category_model.dart';
import 'package:vai_marcia/features/categories/domain/entities/audio_category.dart';
import 'package:vai_marcia/features/categories/domain/repositories/category_repository.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._remote);

  final CategoryRemoteDataSource _remote;

  @override
  Stream<List<AudioCategory>> watchCategories() {
    return _remote.watchCategories().map(
          (List<AudioCategoryModel> models) {
            final List<AudioCategory> entities = models.map((AudioCategoryModel m) => m.toEntity()).toList();
            // Fallback offline-first: se o remoto ainda não entregou nada
            // (primeira abertura, sem rede), mostrar as categorias padrão
            // pré-carregadas em vez de uma grade vazia.
            return entities.isEmpty ? DefaultCategories.seed : entities;
          },
        );
  }

  @override
  Future<Result<AudioCategory>> createCustomCategory(String name) async {
    try {
      final AudioCategoryModel model = await _remote.createCustomCategory(name);
      return Result<AudioCategory>.ok(model.toEntity());
    } on Object catch (e) {
      return Result<AudioCategory>.err(NetworkFailure('Falha ao criar categoria', cause: e));
    }
  }
}
