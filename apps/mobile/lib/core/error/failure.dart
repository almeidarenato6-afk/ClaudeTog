import 'package:equatable/equatable.dart';

/// Base type for all domain-level failures. The `domain` layer never throws
/// raw exceptions across its boundary — `data` implementations catch
/// platform/plugin exceptions and translate them into a [Failure] so the
/// `presentation` layer never needs to know about Firebase, just_audio, etc.
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
