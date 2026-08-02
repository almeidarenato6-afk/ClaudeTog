import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:vai_marcia/core/error/failure.dart';
import 'package:vai_marcia/core/error/result.dart';
import 'package:vai_marcia/features/auth/data/models/app_user_mapper.dart';
import 'package:vai_marcia/features/auth/domain/entities/app_user.dart';
import 'package:vai_marcia/features/auth/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._firebaseAuth, this._googleSignIn);

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<AppUser?> watchAuthState() {
    return _firebaseAuth.authStateChanges().map((fb.User? user) => user?.toAppUser());
  }

  @override
  AppUser? get currentUser => _firebaseAuth.currentUser?.toAppUser();

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        return const Result<AppUser>.err(AuthFailure('Login com Google cancelado'));
      }
      final GoogleSignInAuthentication auth = await account.authentication;
      final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final fb.UserCredential result = await _firebaseAuth.signInWithCredential(credential);
      return Result<AppUser>.ok(result.user!.toAppUser());
    } on Object catch (e) {
      return Result<AppUser>.err(AuthFailure('Falha ao entrar com Google', cause: e));
    }
  }

  @override
  Future<Result<AppUser>> signInWithApple() async {
    try {
      final AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final fb.OAuthCredential credential = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final fb.UserCredential result = await _firebaseAuth.signInWithCredential(credential);
      return Result<AppUser>.ok(result.user!.toAppUser());
    } on Object catch (e) {
      return Result<AppUser>.err(AuthFailure('Falha ao entrar com Apple', cause: e));
    }
  }

  @override
  Future<Result<AppUser>> signInWithEmail({required String email, required String password}) async {
    try {
      final fb.UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result<AppUser>.ok(result.user!.toAppUser());
    } on Object catch (e) {
      return Result<AppUser>.err(AuthFailure('Falha ao entrar com e-mail', cause: e));
    }
  }

  @override
  Future<Result<AppUser>> registerWithEmail({required String email, required String password}) async {
    try {
      final fb.UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result<AppUser>.ok(result.user!.toAppUser());
    } on Object catch (e) {
      return Result<AppUser>.err(AuthFailure('Falha ao criar conta', cause: e));
    }
  }

  @override
  Future<Result<AppUser>> continueAnonymously() async {
    try {
      final fb.UserCredential result = await _firebaseAuth.signInAnonymously();
      return Result<AppUser>.ok(result.user!.toAppUser());
    } on Object catch (e) {
      return Result<AppUser>.err(AuthFailure('Falha ao continuar sem conta', cause: e));
    }
  }

  @override
  Future<Result<AppUser>> linkAnonymousToEmail({required String email, required String password}) async {
    try {
      final fb.User? user = _firebaseAuth.currentUser;
      if (user == null || !user.isAnonymous) {
        return const Result<AppUser>.err(AuthFailure('Nenhuma sessão anônima ativa para vincular'));
      }
      final fb.AuthCredential credential = fb.EmailAuthProvider.credential(email: email, password: password);
      final fb.UserCredential result = await user.linkWithCredential(credential);
      return Result<AppUser>.ok(result.user!.toAppUser());
    } on Object catch (e) {
      return Result<AppUser>.err(AuthFailure('Falha ao vincular conta', cause: e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await Future.wait<void>(<Future<void>>[
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Result<void>.ok(null);
    } on Object catch (e) {
      return Result<void>.err(AuthFailure('Falha ao sair', cause: e));
    }
  }
}
