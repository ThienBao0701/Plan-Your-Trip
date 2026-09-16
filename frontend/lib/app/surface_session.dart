import 'package:flutter/widgets.dart';

import '../core/app_state.dart';

/// Signs the current account out and returns to the running surface's root.
///
/// Every surface app's root route is its `SurfaceGate`, which shows that
/// surface's sign-in the moment the session is gone. So signing out is: clear
/// the session, then drop anything pushed above the root. It never navigates to
/// another surface.
Future<void> signOutToSurfaceRoot(BuildContext context) async {
  final app = AppScope.of(context);
  final navigator = Navigator.of(context);
  await app.logout();
  navigator.popUntil((route) => route.isFirst);
}
