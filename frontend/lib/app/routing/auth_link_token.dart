import 'package:flutter/foundation.dart';

import 'surface_router.dart';

/// The one-time token an account link carries.
///
/// Phase A puts it in the URL **fragment** — `/verify-email#token=…`,
/// `/reset-password#token=…` — never in the path or the query, so it is not sent
/// to any server in a request line and never lands in an HTTP access log or a
/// `Referer` header.
///
/// This reads it once at start-up ([captureLaunch]) and the screen clears it from the address bar
/// as soon as it has been used, so the link is not left behind in history or
/// copied out of the address bar afterwards. The token is held only in the
/// screen's own state: nothing stores it, logs it or sends it anywhere except to
/// the endpoint that consumes it.
class AuthLinkToken {
  const AuthLinkToken._();

  static const String _parameter = 'token';

  /// The address the app was opened at, while it still carries its fragment.
  static Uri? _launch;

  /// Remembers the address the app was opened at. Called once by the bootstrap
  /// before the framework starts: on the web, Flutter's history setup rewrites
  /// the address bar to the bare path before the first screen is built, which
  /// drops the `#token=…` a link screen would otherwise read. Kept only in
  /// memory, and only until [clear].
  static void captureLaunch({Uri? from}) {
    final uri = from ?? Uri.base;
    _launch = uri.fragment.isEmpty ? null : uri;
  }

  /// The token in [from]'s fragment, or null when there is none. Without [from]
  /// it is the fragment the app was opened with ([captureLaunch]) while the
  /// address bar still shows that same path, else the current browser URL's.
  /// A malformed fragment is simply no token.
  static String? read({Uri? from}) {
    final launch = _launch;
    final current = Uri.base;
    final uri = from ??
        (launch != null && launch.path == current.path ? launch : current);
    final fragment = uri.fragment;
    if (fragment.isEmpty) return null;
    try {
      final value = Uri.splitQueryString(fragment)[_parameter]?.trim();
      return value == null || value.isEmpty ? null : value;
    } on FormatException {
      return null;
    }
  }

  /// Rewrites the address bar to [location] with no fragment, so the token stops
  /// being visible and is not carried into the next navigation. Off the web this
  /// is a no-op, like every other location report.
  static void clear(String location) {
    _launch = null;
    if (!kIsWeb) return;
    SurfaceRouter.reportLocation(location);
  }
}
