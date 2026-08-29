import 'package:flutter/material.dart';

import '../../core/app_role.dart';
import '../../core/app_state.dart';
import '../../core/partner/partner_state.dart';
import 'partner_app_shell.dart';
import 'partner_navigation.dart';
import 'widgets/partner_state_views.dart';

/// The `/partner/...` route namespace.
///
/// The app navigates imperatively with `MaterialPageRoute` (there is no named
/// router and none is introduced here), so a "route" is a stable path string
/// that identifies a partner destination. Keeping the strings identical to the
/// ones `PartnerExtranetService.getMenu` returns means a future deep link, a
/// backend quick-action URL (`/partner/bookings?arrivalToday=true`) and this
/// client all agree on one vocabulary.
class PartnerRoutes {
  const PartnerRoutes._();

  static const String namespace = '/partner';

  /// Entry route. Everything else is reached from the shell.
  static const String dashboard = '/partner/dashboard';

  static bool isPartnerRoute(String route) =>
      route == namespace || route.startsWith('$namespace/');

  /// Opens the Partner Extranet at [route].
  ///
  /// Always goes through [PartnerRouteGuard]; there is no way to push a partner
  /// screen that skips the check.
  static Route<void> route({String route = dashboard}) =>
      MaterialPageRoute<void>(
        settings: RouteSettings(name: route),
        builder: (_) => PartnerRouteGuard(initialRoute: route),
      );

  /// Convenience for call sites that already have a [BuildContext].
  static Future<void> open(BuildContext context, {String to = dashboard}) =>
      Navigator.of(context).push(PartnerRoutes.route(route: to));
}

/// Gate in front of every partner route.
///
/// Mirrors the backend's URL rule — `SecurityConfig` gates `/api/partner/**` on
/// `hasAnyRole("PARTNER", "ADMIN")` — and nothing looser. A role the client does
/// not recognise (including the still-TBD `SUPER_ADMIN` / `SUPER_PARTNER`
/// names) parses to [AppRole.unknown] and is refused here.
///
/// This is **UX routing, not authorization**. Passing this guard grants no data:
/// each `/api/partner/**` request is authorized independently by the backend,
/// which additionally self-scopes the caller to their own partner profile.
class PartnerRouteGuard extends StatelessWidget {
  final String initialRoute;

  const PartnerRouteGuard(
      {super.key, this.initialRoute = PartnerRoutes.dashboard});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    // Signed out: the traveller app's own session handling owns this case, so
    // just refuse rather than duplicating a login flow here.
    if (app.email == null || !app.role.canEnterPartnerExtranet) {
      return PartnerAccessDeniedScreen(role: app.role);
    }

    final destination = PartnerNavigation.byRoute(initialRoute);
    return PartnerAppShell(
      initialRoute: destination?.route ?? PartnerRoutes.dashboard,
    );
  }
}

/// Shown when a non-partner reaches a partner route. Deliberately a dead end
/// with a single way back — it must never hint at what the workspace contains.
class PartnerAccessDeniedScreen extends StatelessWidget {
  final AppRole role;

  const PartnerAccessDeniedScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: PartnerWorkspaceStatusView(
                  status: PartnerWorkspaceStatus.notPartner,
                  onPrimaryAction: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ),
      );
}
