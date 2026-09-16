import 'package:flutter/widgets.dart';

import 'app/app_surface.dart';
import 'app/bootstrap.dart';
import 'app/surface_app.dart';

/// Backward-compatible entrypoint.
///
/// Boots the surface named by `--dart-define=APP_SURFACE=user|partner|admin`,
/// or the traveller app when the define is absent, which keeps a plain
/// `flutter run` working as it always has. An `APP_SURFACE` value that is not
/// one of the three boots the configuration error, never a guess.
///
/// Prefer the dedicated entrypoints — `lib/main_user.dart`,
/// `lib/main_partner.dart`, `lib/main_admin.dart`. See `docs/APP_SURFACES.md`.
Future<void> main() async {
  final surface = AppSurface.fromEnvironment(fallback: AppSurface.user);
  if (surface == null) {
    runSurfaceConfigError();
    return;
  }
  await bootstrapSurface(surface);
}

/// The traveller app's application widget, under the name it has always had.
class PlanYourTripApp extends StatelessWidget {
  const PlanYourTripApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const SurfaceApp(surface: AppSurface.user);
}
