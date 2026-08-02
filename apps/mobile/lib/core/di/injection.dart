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

/// `@InjectableInit` generates [_configureDependencies] in
/// `injection.config.dart` (via `build_runner`) by scanning every
/// `@injectable`/`@lazySingleton`/`@LazySingleton(as: ...)` annotation in
/// the project — see individual datasource/repository files.
@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
Future<void> configureDependencies() async {
  // Third-party singletons that `injectable` can't construct on its own
  // (they need Firebase.initializeApp() to have already run, or take no
  // meaningful constructor args) are registered by hand, before the
  // generated `$initGetIt(getIt)` wires everything that depends on them.
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
