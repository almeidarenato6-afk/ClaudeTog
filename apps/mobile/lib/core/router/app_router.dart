import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vai_marcia/features/audio_playback/presentation/pages/home_shell_page.dart';
import 'package:vai_marcia/features/auth/presentation/pages/sign_in_page.dart';
import 'package:vai_marcia/features/auth/presentation/providers/auth_providers.dart';
import 'package:vai_marcia/features/device_pairing/presentation/pages/setup_wizard_page.dart';
import 'package:vai_marcia/features/notifications/presentation/pages/notifications_page.dart';
import 'package:vai_marcia/features/recording/presentation/pages/recording_page.dart';
import 'package:vai_marcia/features/store/presentation/pages/store_page.dart';

abstract final class AppRoutes {
  static const String signIn = '/sign-in';
  static const String home = '/';
  static const String setupWizard = '/setup';
  static const String recording = '/recording';
  static const String store = '/store';
  static const String notifications = '/notifications';
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>(
  (Ref ref) {
    return GoRouter(
      initialLocation: AppRoutes.home,
      redirect: (BuildContext context, GoRouterState state) {
        final bool isSignedIn = ref.read(authStateProvider).valueOrNull != null;
        final bool goingToSignIn = state.matchedLocation == AppRoutes.signIn;
        if (!isSignedIn && !goingToSignIn) {
          return AppRoutes.signIn;
        }
        if (isSignedIn && goingToSignIn) {
          return AppRoutes.home;
        }
        return null;
      },
      routes: <GoRoute>[
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, __) => const SignInPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const HomeShellPage(),
        ),
        GoRoute(
          path: AppRoutes.setupWizard,
          builder: (_, __) => const SetupWizardPage(),
        ),
        GoRoute(
          path: AppRoutes.recording,
          builder: (_, __) => const RecordingPage(),
        ),
        GoRoute(
          path: AppRoutes.store,
          builder: (_, __) => const StorePage(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (_, __) => const NotificationsPage(),
        ),
      ],
    );
  },
);
