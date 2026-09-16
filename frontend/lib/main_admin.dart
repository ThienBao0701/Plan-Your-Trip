import 'app/app_surface.dart';
import 'app/bootstrap.dart';

/// The Admin console (Admin surface).
///
/// ```sh
/// flutter run -d chrome -t lib/main_admin.dart --web-port 64119
/// ```
Future<void> main() => runSurfaceEntrypoint(AppSurface.admin);
