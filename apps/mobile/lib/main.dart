import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/core/router/app_router.dart';
import 'package:vai_marcia/core/theme/app_theme.dart';
import 'package:vai_marcia/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:vai_marcia/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();
  await getIt<NotificationsRepository>().initialize();

  runApp(const ProviderScope(child: VaiMarciaApp()));
}

class VaiMarciaApp extends ConsumerWidget {
  const VaiMarciaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Vai Márcia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
