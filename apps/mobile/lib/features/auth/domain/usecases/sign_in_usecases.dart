import 'package:injectable/injectable.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/auth/domain/entities/app_user.dart';
import 'package:vai_marcia/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository);
  final AuthRepository _repository;
  Future<Result<AppUser>> call() => _repository.signInWithGoogle();
}

@injectable
class SignInWithAppleUseCase {
  const SignInWithAppleUseCase(this._repository);
  final AuthRepository _repository;
  Future<Result<AppUser>> call() => _repository.signInWithApple();
}

@injectable
class SignInWithEmailUseCase {
  const SignInWithEmailUseCase(this._repository);
  final AuthRepository _repository;
  Future<Result<AppUser>> call({required String email, required String password}) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}

@injectable
class ContinueAnonymouslyUseCase {
  const ContinueAnonymouslyUseCase(this._repository);
  final AuthRepository _repository;
  Future<Result<AppUser>> call() => _repository.continueAnonymously();
}

@injectable
class SignOutUseCase {
  const SignOutUseCase(this._repository);
  final AuthRepository _repository;
  Future<Result<void>> call() => _repository.signOut();
}
