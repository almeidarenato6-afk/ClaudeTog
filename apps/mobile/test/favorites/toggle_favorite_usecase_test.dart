import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vai_marcia/features/favorites/data/datasources/favorites_local_datasource.dart';
import 'package:vai_marcia/features/favorites/data/datasources/favorites_remote_datasource.dart';
import 'package:vai_marcia/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:vai_marcia/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:vai_marcia/features/favorites/domain/usecases/toggle_favorite_usecase.dart';

class MockFavoritesLocalDataSource extends Mock implements FavoritesLocalDataSource {}

class MockFavoritesRemoteDataSource extends Mock implements FavoritesRemoteDataSource {}

void main() {
  late MockFavoritesLocalDataSource local;
  late MockFavoritesRemoteDataSource remote;
  late FavoritesRepository repository;
  late ToggleFavoriteUseCase useCase;

  setUp(() {
    local = MockFavoritesLocalDataSource();
    remote = MockFavoritesRemoteDataSource();
    repository = FavoritesRepositoryImpl(local, remote);
    useCase = ToggleFavoriteUseCase(repository);
  });

  test('toggling a non-favorite clip marks it favorite locally and mirrors to remote', () async {
    when(() => local.isFavorite('clip-1')).thenAnswer((_) async => false);
    when(() => local.setFavorite('clip-1', true)).thenAnswer((_) async {});
    when(() => remote.setFavorite('clip-1', true)).thenAnswer((_) async {});

    final result = await useCase('clip-1');

    expect(result.isOk, isTrue);
    expect(result.valueOrNull, isTrue);
    verify(() => local.setFavorite('clip-1', true)).called(1);
    verify(() => remote.setFavorite('clip-1', true)).called(1);
  });

  test('toggling an already-favorite clip unfavorites it', () async {
    when(() => local.isFavorite('clip-1')).thenAnswer((_) async => true);
    when(() => local.setFavorite('clip-1', false)).thenAnswer((_) async {});
    when(() => remote.setFavorite('clip-1', false)).thenAnswer((_) async {});

    final result = await useCase('clip-1');

    expect(result.isOk, isTrue);
    expect(result.valueOrNull, isFalse);
    verify(() => local.setFavorite('clip-1', false)).called(1);
  });

  test('local write is authoritative: toggle still succeeds even if remote sync throws', () async {
    when(() => local.isFavorite('clip-1')).thenAnswer((_) async => false);
    when(() => local.setFavorite('clip-1', true)).thenAnswer((_) async {});
    when(() => remote.setFavorite('clip-1', true)).thenAnswer((_) async => throw StateError('offline'));

    final result = await useCase('clip-1');

    expect(result.isOk, isTrue);
  });

  test('a local write failure surfaces as CacheFailure', () async {
    when(() => local.isFavorite('clip-1')).thenThrow(StateError('db locked'));

    final result = await useCase('clip-1');

    expect(result.isErr, isTrue);
  });
}
