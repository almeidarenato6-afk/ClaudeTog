import 'package:equatable/equatable.dart';

/// Tipo base para todas as falhas em nível de domínio. A camada `domain`
/// nunca lança exceções brutas através de sua fronteira — as
/// implementações de `data` capturam exceções de plataforma/plugin e as
/// traduzem para um [Failure], para que a camada `presentation` nunca
/// precise saber sobre Firebase, just_audio, etc.
abstract class Failure extends Equatable {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => <Object?>[message, cause];
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.cause});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

class PlaybackFailure extends Failure {
  const PlaybackFailure(super.message, {super.cause});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause});
}

class BluetoothFailure extends Failure {
  const BluetoothFailure(super.message, {super.cause});
}

class WatchCompanionFailure extends Failure {
  const WatchCompanionFailure(super.message, {super.cause});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause});
}

class RecordingFailure extends Failure {
  const RecordingFailure(super.message, {super.cause});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.cause});
}
