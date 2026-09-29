/// Result type used at every repository/service boundary so that failures
/// never surface as uncaught exceptions in the UI.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  R when<R>({required R Function(T value) ok, required R Function(String message) err}) =>
      switch (this) {
        Ok<T>(:final value) => ok(value),
        Err<T>(:final message) => err(message),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() => 'Err($message)';
}
