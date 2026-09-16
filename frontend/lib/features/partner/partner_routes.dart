import 'package:flutter/material.dart';

import '../../core/app_role.dart';
import '../../core/app_state.dart';
import '../../core/partner/partner_state.dart';
import 'partner_app_shell.dart';
import 'partner_navigation.dart';
import 'widgets/partner_state_views.dart';

/// The in-app partner route strings (`/partner/...`).
///
/// A "route" is a stable path string that identifies a partner destination,
/// kept identical to the ones `PartnerExtranetService.getMenu` returns so the
/// backend's menu, a backend quick-action URL and this client agree on one
/// vocabulary. They are not browser locations: the Partner workspace is its own
/// application surface, whose router maps `/bookings` in the address bar to
/// `/partner/bookings` here (see `app/routing/partner_router.dart`).
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

  /// Passed through to [PartnerAppShell.onRouteChanged].
  final ValueChanged<String>? onRouteChanged;

  const PartnerRouteGuard({
    super.key,
    this.initialRoute = PartnerRoutes.dashboard,
    this.onRouteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    // On the Partner surface the SurfaceGate shows sign-in, and refuses every
    // other role, before this guard is built. Reaching it signed out or with the
    // wrong role means it was mounted directly — refuse, rather than duplicate a
    // sign-in flow here.
    if (app.email == null || !app.role.canEnterPartnerExtranet) {
      return PartnerAccessDeniedScreen(role: app.role);
    }

    final destination = PartnerNavigation.byRoute(initialRoute);
    return PartnerAppShell(
      initialRoute: destination?.route ?? PartnerRoutes.dashboard,
      onRouteChanged: onRouteChanged,
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
