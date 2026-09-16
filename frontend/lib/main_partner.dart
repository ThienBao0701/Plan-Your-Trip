import 'app/app_surface.dart';
import 'app/bootstrap.dart';

/// The Partner workspace (Partner surface).
///
/// ```sh
/// flutter run -d chrome -t lib/main_partner.dart --web-port 64118
/// ```
Future<void> main() => runSurfaceEntrypoint(AppSurface.partner);
