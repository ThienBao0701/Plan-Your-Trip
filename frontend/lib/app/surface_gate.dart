import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../design/app_colors.dart';
import '../design/app_spacing.dart';
import '../l10n/app_localizations.dart';
import '../shared/widgets/glass_widgets.dart';
import 'app_surface.dart';
import 'routing/surface_router.dart';
import 'surface_scope.dart';
import 'surface_session.dart';

/// The root of every surface app, in front of every location it serves.
///
/// Decides, from the session already restored before the first frame, which of
/// exactly three things this origin shows:
///
///  1. **No session** — the surface's own sign-in (401).
///  2. **A session the surface does not admit** — a wrong or unrecognised role —
///     [SurfaceAccessDeniedScreen] (403). No shell is built, so nothing
///     protected is rendered first and hidden afterwards.
///  3. **An admitted session** — the surface's shell at [location].
///
/// It rebuilds whenever the session changes, so signing in and signing out
/// swap what the root shows without any navigation. This is UX routing, not
/// authorization: the backend authorizes every request, and the Partner and
/// Admin shells keep their own role guards underneath as a second check.
class SurfaceGate extends StatelessWidget {
  final String location;

  const SurfaceGate({super.key, this.location = SurfaceRouter.root});

  @override
  Widget build(BuildContext context) {
    final surface = SurfaceScope.maybeOf(context);
    if (surface == null) return const SurfaceConfigErrorScreen();

    final app = AppScope.of(context);
    final router = SurfaceRouter.of(surface);
    if (app.email == null) {
      // Account locations a visitor with no session may open — registration and
      // the link-driven verification and reset flows. Everything else that is not
      // the sign-in screen has already been resolved away by the router.
      return router.publicScreenAt(location) ?? router.signedOutEntry();
    }
    if (!surface.admits(app.role)) {
      return SurfaceAccessDeniedScreen(surface: surface);
    }
    return router.shellAt(location);
  }
}

/// Navigation that must stay inside the running surface.
class SurfaceNavigation {
  const SurfaceNavigation._();

  /// Opens [location] on the running surface, keeping the address bar in step.
  ///
  /// Used for the account locations, which are ordinary pushes rather than shell
  /// destinations. Outside a surface app it does nothing: there is no surface to
  /// navigate within.
  static Future<void> open(BuildContext context, String location) async {
    final surface = SurfaceScope.maybeOf(context);
    if (surface == null) return;
    final router = SurfaceRouter.of(surface);
    final navigator = Navigator.of(context);
    SurfaceRouter.reportLocation(location);
    await navigator.push(router.routeTo(location));
    SurfaceRouter.reportLocation(SurfaceRouter.root);
  }

  /// Returns to the surface's root — the way back from any account screen.
  ///
  /// A screen reached by link has nothing behind it, so there the root replaces
  /// it instead of popping to a stack that does not exist.
  static void goHome(BuildContext context) {
    final navigator = Navigator.of(context);
    SurfaceRouter.reportLocation(SurfaceRouter.root);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    final surface = SurfaceScope.maybeOf(context);
    if (surface == null) return;
    navigator.pushReplacement(
      SurfaceRouter.of(surface).routeTo(SurfaceRouter.root),
    );
  }

  /// The running surface's root route — where a sign-in pushed on top of other
  /// screens hands over once it succeeds. Outside a surface app there is no
  /// root to return to, so it is the configuration error rather than a guess.
  static Route<void> home(BuildContext context) {
    final surface = SurfaceScope.maybeOf(context);
    if (surface == null) {
      return MaterialPageRoute<void>(
        builder: (_) => const SurfaceConfigErrorScreen(),
      );
    }
    return SurfaceRouter.of(surface).routeTo(SurfaceRouter.root);
  }
}

/// Shown when the signed-in account's role does not belong to this surface.
///
/// A dead end with one way out — signing out, which returns to this surface's
/// sign-in. It never links to another surface and never describes what the
/// refused application contains.
class SurfaceAccessDeniedScreen extends StatelessWidget {
  final AppSurface surface;

  const SurfaceAccessDeniedScreen({super.key, required this.surface});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = AppScope.of(context).email;
    final body = switch (surface) {
      AppSurface.user => l10n.surfaceAccessDeniedUser,
      AppSurface.partner => l10n.surfaceAccessDeniedPartner,
      AppSurface.admin => l10n.surfaceAccessDeniedAdmin,
    };
    return _SurfaceStatusScaffold(
      icon: Icons.shield_outlined,
      title: l10n.surfaceAccessDeniedTitle,
      body: body,
      detail: email == null ? null : l10n.surfaceSignedInAs(email),
      action: OceanPrimaryButton(
        key: const Key('surface-sign-out'),
        label: l10n.surfaceSignOut,
        icon: Icons.logout_rounded,
        semanticLabel: l10n.surfaceSignOut,
        onPressed: () => signOutToSurfaceRoot(context),
      ),
    );
  }
}

/// Shown when no surface can be determined — an `APP_SURFACE` value that is not
/// one of the three, or an entrypoint and `APP_SURFACE` that disagree. Nothing
/// is guessed and no application boots.
class SurfaceConfigErrorScreen extends StatelessWidget {
  const SurfaceConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SurfaceStatusScaffold(
      icon: Icons.error_outline_rounded,
      title: l10n.surfaceConfigErrorTitle,
      body: l10n.surfaceConfigErrorBody,
    );
  }
}

class _SurfaceStatusScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? detail;
  final Widget? action;

  const _SurfaceStatusScaffold({
    required this.icon,
    required this.title,
    required this.body,
    this.detail,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: BubbleBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: OceanContentConstraint(
                maxWidth: 560,
                child: OceanGlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(icon, size: 48, color: AppColors.ocean),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        body,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (detail != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          detail!,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (action != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        action!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
