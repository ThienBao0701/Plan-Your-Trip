import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../home/app_shell.dart';
import '../partner/partner_routes.dart';

/// Chooses the post-authentication landing surface for the signed-in account.
///
/// This is the *only* place role affects where the app starts. It is a
/// selection between two existing shells, not a router: `main.dart` and
/// `LoginScreen` both hand off here instead of naming `AppShell` directly, so
/// there is one decision point rather than two drifting ones.
///
/// - `PARTNER` lands in the Partner Extranet, which is that account's actual
///   workspace.
/// - `USER`, `ADMIN` and every unrecognised role land in the traveller app,
///   unchanged. `ADMIN` is deliberately included: admins may *reach* partner
///   routes (the backend admits `ROLE_ADMIN` on `/api/partner/**`), but partner
///   controllers self-scope to the caller's own partner profile, which an admin
///   normally does not have — landing them in an empty workspace would be
///   wrong. Cross-partner administration is the Admin CMS's job, and that has
///   no frontend yet.
class RoleHome extends StatelessWidget {
  const RoleHome({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (app.role.landsOnPartnerExtranet) {
      return const PartnerRouteGuard();
    }
    return const AppShell();
  }
}
