/// Route paths. Tabs live inside the StatefulShellRoute; everything else is a
/// full-screen route on the root navigator.
abstract final class Routes {
  // Gate
  static const onboarding = '/onboarding';
  static const lock = '/lock';
  static const decoy = '/notes';

  // Tabs
  static const home = '/home';
  static const map = '/map';
  static const escort = '/escort';
  static const guard = '/guard';
  static const settings = '/settings';

  // Full-screen
  static const sos = '/sos';
  static const contacts = '/contacts';
  static const fakeCall = '/fake-call';
  static const siren = '/siren';
  static const evidence = '/evidence';
  static const fir = '/fir';
  static const safePlaces = '/safe-places';
  static const history = '/history';
}
