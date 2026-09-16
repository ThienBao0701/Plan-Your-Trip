import 'package:flutter/material.dart';

import '../../core/app_role.dart';
import '../../core/app_state.dart';
import '../../l10n/app_localizations.dart';
import 'admin_app_shell.dart';
import 'admin_navigation.dart';

/// The in-app admin route strings (`/admin/...`).
///
/// A "route" here is a stable path string identifying an admin destination,
/// matching the convention `PartnerRoutes` established so both consoles speak
/// one vocabulary. They are not browser locations: the Admin console is its own
/// application surface, whose router maps `/reference-data` in the address bar
/// to `/admin/reference-data` here (see `app/routing/admin_router.dart`).
/// `go_router` is still deliberately not introduced.
class AdminRoutes {
  const AdminRoutes._();

  static const String namespace = AdminRoutesRefs.namespace;

  /// Entry route. Everything else is reached from the shell.
  static const String dashboard = AdminRoutesRefs.dashboard;
  static const String bookings = AdminRoutesRefs.bookings;
  static const String payments = AdminRoutesRefs.payments;
  static const String reviews = AdminRoutesRefs.reviews;
  static const String invoices = AdminRoutesRefs.invoices;
  static const String activityLog = AdminRoutesRefs.activityLog;
  static const String partners = AdminRoutesRefs.partners;
  static const String catalog = AdminRoutesRefs.catalog;
  static const String media = AdminRoutesRefs.media;
  static const String referenceData = AdminRoutesRefs.referenceData;

  static bool isAdminRoute(String route) =>
      route == namespace || route.startsWith('$namespace/');

  /// Opens the Admin CMS at [route].
  ///
  /// Always goes through [AdminRouteGuard]; there is no way to push an admin
  /// screen that skips the check.
  static Route<void> route({String route = dashboard}) =>
      MaterialPageRoute<void>(
        settings: RouteSettings(name: route),
        builder: (_) => AdminRouteGuard(initialRoute: route),
      );

  /// Convenience for call sites that already have a [BuildContext].
  static Future<void> open(BuildContext context, {String to = dashboard}) =>
      Navigator.of(context).push(AdminRoutes.route(route: to));
}

/// Gate in front of every admin route.
///
/// Mirrors the backend's URL rule — `SecurityConfig` gates `/api/admin/**` on
/// `hasRole("ADMIN")` — and nothing looser. Note this is **stricter** than the
/// partner guard: `PARTNER` is refused here, which D0 confirmed live (a partner
/// token receives 403 on every admin route). A role the client does not
/// recognise, including the still-unimplemented `SUPER_ADMIN` /
/// `SUPER_PARTNER` names, parses to [AppRole.unknown] and is refused.
///
/// This is **UX routing, not authorization**. Passing this guard grants no
/// data: every `/api/admin/**` request is authorized independently by the
/// backend. Nothing here may ever become the only thing standing between a
/// non-admin and admin data.
class AdminRouteGuard extends StatelessWidget {
  final String initialRoute;

  /// Passed through to [AdminAppShell.onRouteChanged].
  final ValueChanged<String>? onRouteChanged;

  const AdminRouteGuard({
    super.key,
    this.initialRoute = AdminRoutes.dashboard,
    this.onRouteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    // On the Admin surface the SurfaceGate shows sign-in, and refuses every
    // other role, before this guard is built. Reaching it signed out or with any
    // role other than ADMIN means it was mounted directly — refuse, rather than
    // duplicate a sign-in flow here.
    if (app.email == null || !app.role.canEnterAdminConsole) {
      return AdminAccessDeniedScreen(role: app.role);
    }

    final destination = AdminNavigation.byRoute(initialRoute);
    return AdminAppShell(
      initialRoute: destination?.route ?? AdminRoutes.dashboard,
      onRouteChanged: onRouteChanged,
    );
  }
}

/// Shown when a non-admin reaches an admin route. Deliberately a dead end with
/// a single way back — it must never hint at what the console contains, nor at
/// whether the account merely lacks a role or the resource exists.
class AdminAccessDeniedScreen extends StatelessWidget {
  final AppRole role;

  const AdminAccessDeniedScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminConsoleTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    l10n.adminAccessDeniedTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.adminAccessDeniedBody,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.adminAccessDeniedAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
