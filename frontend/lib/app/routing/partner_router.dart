import 'package:flutter/widgets.dart';

import '../../features/auth/login_screen.dart';
import '../../features/partner/partner_navigation.dart';
import '../../features/partner/partner_routes.dart';
import '../../l10n/app_localizations.dart';
import '../app_surface.dart';
import 'surface_router.dart';

/// The Partner workspace's locations: `/`, and `/{key}` for each of the
/// thirteen [PartnerNavigation] destinations — `/dashboard`, `/hotels`,
/// `/rooms`, `/calendar`, `/pricing`, `/bookings`, `/messages`, `/promotions`,
/// `/reviews`, `/finance`, `/analytics`, `/notifications`, `/settings`.
///
/// Inside the app the destinations keep their established route strings
/// (`/partner/bookings`), which are also the routes the backend's extranet menu
/// returns. Only the browser location drops the prefix, because the Partner
/// host already is the partner namespace.
class PartnerSurfaceRouter extends SurfaceRouter {
  const PartnerSurfaceRouter();

  @override
  AppSurface get surface => AppSurface.partner;

  /// The browser location of an in-app partner route; the root when unknown.
  static String locationOf(String route) {
    final destination = PartnerNavigation.byRoute(route);
    return destination == null ? SurfaceRouter.root : '/${destination.key}';
  }

  /// The in-app partner route for a browser location, or null when this
  /// surface does not serve it.
  static String? routeOf(String? location) {
    final path = SurfaceRouter.normalize(location);
    if (path == SurfaceRouter.root) return PartnerRoutes.dashboard;
    for (final destination in PartnerNavigation.destinations) {
      if ('/${destination.key}' == path) return destination.route;
    }
    return null;
  }

  @override
  String resolve(String? location) => routeOf(location) == null
      ? SurfaceRouter.root
      : SurfaceRouter.normalize(location);

  @override
  String title(AppLocalizations l10n) => l10n.surfaceTitlePartner;

  @override
  Widget signedOutEntry() => const LoginScreen(embeddedInSurfaceGate: true);

  @override
  Widget shellAt(String location) => PartnerRouteGuard(
        initialRoute: routeOf(location) ?? PartnerRoutes.dashboard,
        onRouteChanged: (route) =>
            SurfaceRouter.reportLocation(locationOf(route)),
      );
}
