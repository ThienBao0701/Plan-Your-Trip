import 'package:flutter/foundation.dart';

import 'surface_router.dart';

/// The one-time token an account link carries.
///
/// Phase A puts it in the URL **fragment** — `/verify-email#token=…`,
/// `/reset-password#token=…` — never in the path or the query, so it is not sent
/// to any server in a request line and never lands in an HTTP access log or a
/// `Referer` header.
///
/// This reads it once at start-up and the screen clears it from the address bar
/// as soon as it has been used, so the link is not left behind in history or
/// copied out of the address bar afterwards. The token is held only in the
/// screen's own state: nothing stores it, logs it or sends it anywhere except to
/// the endpoint that consumes it.
class AuthLinkToken {
  const AuthLinkToken._();

  static const String _parameter = 'token';

  /// The token in [from]'s fragment (defaulting to the current browser URL), or
  /// null when there is none. A malformed fragment is simply no token.
  static String? read({Uri? from}) {
    final uri = from ?? Uri.base;
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
    if (!kIsWeb) return;
    SurfaceRouter.reportLocation(location);
  }
}
