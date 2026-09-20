import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../app_surface.dart';
import '../surface_gate.dart';
import 'admin_router.dart';
import 'partner_router.dart';
import 'user_router.dart';

/// The route table of one application surface.
///
/// Each surface owns its locations outright. There is no shared namespace and
/// no `/user`, `/partner` or `/admin` prefix: the origin already says which
/// application this is, so `/bookings` on the Partner host and `/trips` on the
/// User host are both plain root-relative paths.
///
/// A router answers three questions — which location it serves for a browser
/// path, what a signed-out visitor sees, and which shell opens at a location.
/// Authorization is not one of them: [SurfaceGate] stands in front of every
/// location a router produces.
abstract class SurfaceRouter {
  const SurfaceRouter();

  /// Every surface's application root.
  static const String root = '/';

  /// Account locations, shared by the surfaces that offer them (Phase B). They
  /// are root-relative like every other location: the origin is the surface.
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String account = '/account';

  static SurfaceRouter of(AppSurface surface) => switch (surface) {
        AppSurface.user => const UserSurfaceRouter(),
        AppSurface.partner => const PartnerSurfaceRouter(),
        AppSurface.admin => const AdminSurfaceRouter(),
      };

  AppSurface get surface;

  /// The location this surface serves for [location]. Anything it does not
  /// own resolves to [root] — its own root, never another surface's.
  String resolve(String? location);

  /// The browser tab title.
  String title(AppLocalizations l10n);

  /// What a signed-out visitor sees.
  Widget signedOutEntry();

  /// Locations this surface serves to a visitor with no session — registration,
  /// verification and password recovery. They are reachable by link, because the
  /// emails that carry their tokens are opened by someone who is signed out.
  Set<String> get publicLocations => const {};

  /// The screen for a public location, or null when this surface does not serve
  /// one there. [SurfaceGate] shows it only while signed out; a signed-in visitor
  /// gets the shell instead, so these can never hide an authenticated session.
  Widget? publicScreenAt(String location) => null;

  /// The authenticated shell opened at [location], which [resolve] produced.
  Widget shellAt(String location);

  /// The one kind of route a surface app contains: its gate at a location.
  Route<void> routeTo(String? location) {
    final resolved = resolve(location);
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: resolved),
      builder: (_) => SurfaceGate(location: resolved),
    );
  }

  /// Reduces a browser location to a path: query and fragment dropped, a
  /// trailing slash removed, a leading slash guaranteed.
  static String normalize(String? location) {
    if (location == null || location.isEmpty) return root;
    final path = Uri.tryParse(location)?.path ?? root;
    if (path.isEmpty || path == root) return root;
    final rooted = path.startsWith('/') ? path : '/$path';
    return rooted.length > 1 && rooted.endsWith('/')
        ? rooted.substring(0, rooted.length - 1)
        : rooted;
  }

  /// Tells the browser the surface now shows [location].
  ///
  /// Replaces the current history entry rather than adding one: the shells
  /// switch destinations in place rather than through the navigator, so a
  /// history stack of destinations would make the browser's back button
  /// disagree with the screen. What this buys is that refreshing, or sharing
  /// the address, reopens the same destination. Ignored off the web.
  static void reportLocation(String location) {
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(location),
      replace: true,
    );
  }
}
