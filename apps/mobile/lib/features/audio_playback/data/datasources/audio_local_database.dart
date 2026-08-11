import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'audio_local_database.g.dart';

/// Tabela de áudio em cache: a única fonte de verdade para "este clipe
/// pode ser reproduzido instantaneamente agora" (`localFilePath` não nulo
/// + arquivo existe). Propositalmente plana/desnormalizada (id da
/// categoria como uma coluna simples, não um join de chave estrangeira) —
/// leituras no caminho de toque-para-reproduzir devem ser uma única busca
/// indexada, nunca um join.
class CachedAudioClips extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get categoryId => text()();
  TextColumn get remoteUrl => text()();
  IntColumn get durationMs => integer()();
  TextColumn get localFilePath => text().nullable()();
  BoolColumn get isCustomRecording => boolean().withDefault(const Constant<bool>(false))();
  TextColumn get ownerUserId => text().nullable()();
  TextColumn get tagsCsv => text().withDefault(const Constant<String>(''))();
  IntColumn get playCount => integer().withDefault(const Constant<int>(0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant<bool>(false))();
  DateTimeColumn get cachedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(tables: <Type>[CachedAudioClips])
class AudioLocalDatabase extends _$AudioLocalDatabase {
  AudioLocalDatabase() : super(_openConnection());

  AudioLocalDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File(p.join(dir.path, 'vai_marcia_audio_cache.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  Future<List<CachedAudioClip>> clipsForCategory(String categoryId) {
    return (select(cachedAudioClips)..where((CachedAudioClips t) => t.categoryId.equals(categoryId))).get();
  }

  Stream<List<CachedAudioClip>> watchClipsForCategory(String categoryId) {
    return (select(cachedAudioClips)..where((CachedAudioClips t) => t.categoryId.equals(categoryId))).watch();
  }

  Future<CachedAudioClip?> clipById(String id) {
    return (select(cachedAudioClips)..where((CachedAudioClips t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertClip(CachedAudioClipsCompanion companion) {
    return into(cachedAudioClips).insertOnConflictUpdate(companion);
  }

  Future<void> markLocalPath(String id, String localFilePath) {
    return (update(cachedAudioClips)..where((CachedAudioClips t) => t.id.equals(id))).write(
      CachedAudioClipsCompanion(
        localFilePath: Value<String?>(localFilePath),
        cachedAt: Value<DateTime?>(DateTime.now()),
      ),
    );
  }

  Future<void> setFavorite(String id, bool isFavorite) {
    return (update(cachedAudioClips)..where((CachedAudioClips t) => t.id.equals(id))).write(
      CachedAudioClipsCompanion(isFavorite: Value<bool>(isFavorite)),
    );
  }

  Future<List<CachedAudioClip>> favorites() {
    return (select(cachedAudioClips)..where((CachedAudioClips t) => t.isFavorite.equals(true))).get();
  }

  Stream<List<CachedAudioClip>> watchFavorites() {
    return (select(cachedAudioClips)..where((CachedAudioClips t) => t.isFavorite.equals(true))).watch();
  }

  Future<void> incrementPlayCount(String id) async {
    final CachedAudioClip? clip = await clipById(id);
    if (clip == null) {
      return;
    }
    await (update(cachedAudioClips)..where((CachedAudioClips t) => t.id.equals(id))).write(
      CachedAudioClipsCompanion(playCount: Value<int>(clip.playCount + 1)),
    );
  }
}
