import 'package:vai_marcia/core/error/failure.dart';

/// Resultado leve no estilo `Either`, para que a camada de domínio fique
/// livre de pacotes de terceiros de programação funcional (dartz, fpdart)
/// — uma dependência a menos para se preocupar em uma superfície de app
/// pequena.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) {
    final Result<T> self = this;
    if (self is Ok<T>) {
      return ok(self.value);
    }
    if (self is Err<T>) {
      return err(self.failure);
    }
    throw StateError('Unreachable Result subtype');
  }

  T? get valueOrNull => this is Ok<T> ? (this as Ok<T>).value : null;
  Failure? get failureOrNull => this is Err<T> ? (this as Err<T>).failure : null;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
