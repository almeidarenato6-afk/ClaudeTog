import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vai_marcia/core/di/injection.dart';
import 'package:vai_marcia/features/auth/domain/entities/app_user.dart';
import 'package:vai_marcia/features/auth/domain/repositories/auth_repository.dart';
import 'package:vai_marcia/features/auth/domain/usecases/sign_in_usecases.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => getIt<AuthRepository>(),
);

final StreamProvider<AppUser?> authStateProvider = StreamProvider<AppUser?>(
  (Ref ref) => ref.watch(authRepositoryProvider).watchAuthState(),
);

final NotifierProvider<AuthController, AsyncValue<void>> authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  late final SignInWithGoogleUseCase _google = getIt<SignInWithGoogleUseCase>();
  late final SignInWithAppleUseCase _apple = getIt<SignInWithAppleUseCase>();
  late final SignInWithEmailUseCase _email = getIt<SignInWithEmailUseCase>();
  late final ContinueAnonymouslyUseCase _anonymous = getIt<ContinueAnonymouslyUseCase>();
  late final SignOutUseCase _signOut = getIt<SignOutUseCase>();

  @override
  AsyncValue<void> build() => const AsyncValue<void>.data(null);

  Future<void> signInWithGoogle() => _run(_google.call);

  Future<void> signInWithApple() => _run(_apple.call);

  Future<void> signInWithEmail(String email, String password) {
    return _run(() => _email(email: email, password: password));
  }

  Future<void> continueAnonymously() => _run(_anonymous.call);

  Future<void> signOut() => _run(_signOut.call);

  Future<void> _run(Future<dynamic> Function() action) async {
    state = const AsyncValue<void>.loading();
    final result = await action();
    result.when(
      ok: (_) => state = const AsyncValue<void>.data(null),
      err: (failure) => state = AsyncValue<void>.error(failure, StackTrace.current),
    );
  }
}
