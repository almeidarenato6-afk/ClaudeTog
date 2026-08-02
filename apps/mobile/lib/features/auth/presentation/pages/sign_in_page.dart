import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/constants/app_strings.dart';
import 'package:vai_marcia/core/extensions/context_extensions.dart';
import 'package:vai_marcia/features/auth/presentation/providers/auth_providers.dart';

class SignInPage extends ConsumerWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<void> authState = ref.watch(authControllerProvider);
    final AuthController controller = ref.read(authControllerProvider.notifier);

    ref.listen<AsyncValue<void>>(authControllerProvider, (AsyncValue<void>? previous, AsyncValue<void> next) {
      if (next.hasError) {
        context.showSnack(AppStrings.genericError);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(AppStrings.appName, style: context.textStyles.headlineLarge),
              const SizedBox(height: 8),
              Text(AppStrings.appTagline, style: context.textStyles.bodyLarge),
              const SizedBox(height: 48),
              if (authState.isLoading)
                const CircularProgressIndicator()
              else ...<Widget>[
                ElevatedButton.icon(
                  onPressed: controller.signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text(AppStrings.authSignInGoogle),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: controller.signInWithApple,
                  icon: const Icon(Icons.apple),
                  label: const Text(AppStrings.authSignInApple),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: controller.continueAnonymously,
                  child: const Text(AppStrings.authContinueAnonymous),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
