import 'package:flutter/widgets.dart';

import '../../features/admin/admin_navigation.dart';
import '../../features/admin/admin_routes.dart';
import '../../features/auth/login_screen.dart';
import '../../l10n/app_localizations.dart';
import '../app_surface.dart';
import 'surface_router.dart';

/// The Admin console's locations: `/`, and one path per [AdminNavigation]
/// destination — `/dashboard`, `/bookings`, `/partners`, `/catalog`, `/media`,
/// `/reference-data`, `/payments`, `/invoices`, `/reviews`, `/activity-log`.
///
/// As with the Partner workspace, destinations keep their in-app route strings
/// (`/admin/reference-data`); the browser location drops the `/admin` prefix
/// because the Admin host already is the admin namespace.
class AdminSurfaceRouter extends SurfaceRouter {
  const AdminSurfaceRouter();

  @override
  AppSurface get surface => AppSurface.admin;

  static String _pathOf(AdminDestination destination) =>
      destination.route.substring(AdminRoutes.namespace.length);

  /// The browser location of an in-app admin route; the root when unknown.
  static String locationOf(String route) {
    final destination = AdminNavigation.byRoute(route);
    return destination == null ? SurfaceRouter.root : _pathOf(destination);
  }

  /// The in-app admin route for a browser location, or null when this surface
  /// does not serve it.
  static String? routeOf(String? location) {
    final path = SurfaceRouter.normalize(location);
    if (path == SurfaceRouter.root) return AdminRoutes.dashboard;
    for (final destination in AdminNavigation.destinations) {
      if (_pathOf(destination) == path) return destination.route;
    }
    return null;
  }

  @override
  String resolve(String? location) => routeOf(location) == null
      ? SurfaceRouter.root
      : SurfaceRouter.normalize(location);

  @override
  String title(AppLocalizations l10n) => l10n.surfaceTitleAdmin;

  @override
  Widget signedOutEntry() => const LoginScreen(embeddedInSurfaceGate: true);

  @override
  Widget shellAt(String location) => AdminRouteGuard(
        initialRoute: routeOf(location) ?? AdminRoutes.dashboard,
        onRouteChanged: (route) =>
            SurfaceRouter.reportLocation(locationOf(route)),
      );
}
