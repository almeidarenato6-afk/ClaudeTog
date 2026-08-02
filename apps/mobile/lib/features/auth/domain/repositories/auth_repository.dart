import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> watchAuthState();

  AppUser? get currentUser;

  Future<Result<AppUser>> signInWithGoogle();

  Future<Result<AppUser>> signInWithApple();

  Future<Result<AppUser>> signInWithEmail({required String email, required String password});

  Future<Result<AppUser>> registerWithEmail({required String email, required String password});

  Future<Result<AppUser>> continueAnonymously();

  /// Upgrades an anonymous account to a permanent one, preserving uid
  /// (and therefore favorites/recordings) — ARCHITECTURE.md §6.
  Future<Result<AppUser>> linkAnonymousToEmail({required String email, required String password});

  Future<Result<void>> signOut();
}
