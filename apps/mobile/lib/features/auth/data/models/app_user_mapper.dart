import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:vai_marcia/features/auth/domain/entities/app_user.dart';

extension FirebaseUserMapper on fb.User {
  AppUser toAppUser() {
    final AuthProviderType type = isAnonymous
        ? AuthProviderType.anonymous
        : providerData.any((fb.UserInfo info) => info.providerId == 'google.com')
            ? AuthProviderType.google
            : providerData.any((fb.UserInfo info) => info.providerId == 'apple.com')
                ? AuthProviderType.apple
                : AuthProviderType.email;

    return AppUser(
      uid: uid,
      providerType: type,
      displayName: displayName,
      email: email,
      photoUrl: photoURL,
      isAnonymous: isAnonymous,
    );
  }
}
