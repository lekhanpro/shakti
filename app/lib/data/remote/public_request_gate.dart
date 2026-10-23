/// Serializes public geocoding/routing requests with at least one second
/// between starts, as required by the community providers' usage policies.
class PublicRequestGate {
  Future<void> _tail = Future.value();
  DateTime? _lastStart;

  Future<T> run<T>(Future<T> Function() request) {
    final result = _tail.then((_) async {
      final last = _lastStart;
      if (last != null) {
        final wait =
            const Duration(seconds: 1) - DateTime.now().difference(last);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _lastStart = DateTime.now();
      return request();
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
