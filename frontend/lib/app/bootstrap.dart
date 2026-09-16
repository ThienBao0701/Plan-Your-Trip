import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../core/admin/admin_state.dart';
import '../core/app_state.dart';
import '../core/partner/partner_state.dart';
import 'app_surface.dart';
import 'surface_app.dart';

/// Entry for a dedicated `lib/main_<surface>.dart`.
///
/// The entrypoint fixes the surface. If `APP_SURFACE` is also defined it must
/// name the same one; a disagreement is a misconfiguration and boots the
/// configuration error instead of either surface.
Future<void> runSurfaceEntrypoint(AppSurface surface) async {
  if (AppSurface.fromEnvironment(fallback: surface) != surface) {
    runSurfaceConfigError();
    return;
  }
  await bootstrapSurface(surface);
}

/// Boots [surface] as a standalone application.
///
/// Shared across all three: the session ([AppState], restored before the first
/// frame so the gate never renders a guess), the API client, theme and
/// localization. Surface-specific: the routes, and the domain state only that
/// surface uses — [PartnerState] exists only in the Partner workspace and
/// [AdminState] only in the Admin console, so the traveller app does no partner
/// or admin work at start-up.
Future<void> bootstrapSurface(AppSurface surface) async {
  // Path URLs (`/bookings`, not `/#/bookings`): the origin's root is the
  // surface's root, and a location survives a refresh. A no-op off the web.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  final app = AppState();
  await app.restore();

  final Widget surfaceApp = SurfaceApp(surface: surface);
  runApp(
    AppScope(
      notifier: app,
      child: switch (surface) {
        AppSurface.user => surfaceApp,
        AppSurface.partner => PartnerScope(
            notifier: PartnerState(api: app.api)..bindSession(app),
            child: surfaceApp,
          ),
        AppSurface.admin => AdminScope(
            notifier: AdminState(api: app.api)..bindSession(app),
            child: surfaceApp,
          ),
      },
    ),
  );
}

/// Boots only the configuration error.
void runSurfaceConfigError() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SurfaceConfigErrorApp());
}
