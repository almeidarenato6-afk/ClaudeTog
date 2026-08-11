import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:vai_marcia/features/audio_playback/data/datasources/audio_local_database.dart';

import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

/// `@InjectableInit` gera [_configureDependencies] em
/// `injection.config.dart` (via `build_runner`) escaneando cada anotação
/// `@injectable`/`@lazySingleton`/`@LazySingleton(as: ...)` do projeto —
/// veja os arquivos individuais de datasource/repository.
@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
Future<void> configureDependencies() async {
  // Singletons de terceiros que o `injectable` não consegue construir
  // sozinho (precisam que Firebase.initializeApp() já tenha rodado, ou não
  // recebem argumentos de construtor relevantes) são registrados
  // manualmente, antes que o `$initGetIt(getIt)` gerado conecte tudo que
  // depende deles.
  getIt
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance)
    ..registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance)
    ..registerLazySingleton<FirebaseAnalytics>(() => FirebaseAnalytics.instance)
    ..registerLazySingleton<GoogleSignIn>(GoogleSignIn.new)
    ..registerLazySingleton<AudioLocalDatabase>(AudioLocalDatabase.new);

  await $initGetIt(getIt);
}
