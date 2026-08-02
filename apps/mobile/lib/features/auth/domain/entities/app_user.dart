import 'package:equatable/equatable.dart';

enum AuthProviderType { google, apple, email, anonymous }

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.providerType,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isAnonymous = false,
  });

  final String uid;
  final AuthProviderType providerType;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isAnonymous;

  @override
  List<Object?> get props => <Object?>[uid, providerType, displayName, email, photoUrl, isAnonymous];
}
