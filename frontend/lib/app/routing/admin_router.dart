import 'package:flutter/widgets.dart';

import '../../features/admin/admin_navigation.dart';
import '../../features/admin/admin_routes.dart';
import '../../features/account/account_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../surface_gate.dart';
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
  /// Phase B — the Admin console has **no public registration**: only the two
  /// link-driven password flows are reachable without a session. Admin accounts
  /// are provisioned, never self-created.
  @override
  Set<String> get publicLocations => const {
        SurfaceRouter.forgotPassword,
        SurfaceRouter.resetPassword,
      };

  @override
  Widget? publicScreenAt(String location) => switch (location) {
        SurfaceRouter.forgotPassword => const ForgotPasswordScreen(),
        SurfaceRouter.resetPassword => const ResetPasswordScreen(),
        _ => null,
      };

  @override
  String resolve(String? location) {
    final path = SurfaceRouter.normalize(location);
    if (publicLocations.contains(path) || path == SurfaceRouter.account) {
      return path;
    }
    return routeOf(path) == null ? SurfaceRouter.root : path;
  }

  @override
  String title(AppLocalizations l10n) => l10n.surfaceTitleAdmin;

  @override
  Widget signedOutEntry() => const LoginScreen(embeddedInSurfaceGate: true);

  @override
  Widget shellAt(String location) {
    if (location == SurfaceRouter.account) {
      return Builder(
        builder: (context) => AccountScreen(
          title: AppLocalizations.of(context)!.accountTitle,
          backLabel: AppLocalizations.of(context)!.accountBackToConsole,
          onBack: () => SurfaceNavigation.goHome(context),
        ),
      );
    }
    return AdminRouteGuard(
      initialRoute: routeOf(location) ?? AdminRoutes.dashboard,
      onRouteChanged: (route) =>
          SurfaceRouter.reportLocation(locationOf(route)),
    );
  }
}
