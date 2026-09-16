import 'app/app_surface.dart';
import 'app/bootstrap.dart';

/// The traveller app (User surface).
///
/// ```sh
/// flutter run -d chrome -t lib/main_user.dart --web-port 64117
/// ```
Future<void> main() => runSurfaceEntrypoint(AppSurface.user);
