import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../design/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'app_surface.dart';
import 'routing/surface_router.dart';
import 'surface_gate.dart';
import 'surface_scope.dart';

/// One surface's application: shared theme, localization and session, with the
/// surface's own routes.
///
/// Every browser location — including the very first one, so a deep link or a
/// refresh lands where it pointed — is resolved by the surface's
/// [SurfaceRouter] into a single [SurfaceGate] route. A location the surface
/// does not serve resolves to the surface's own root; nothing resolves to
/// another surface.
class SurfaceApp extends StatelessWidget {
  final AppSurface surface;

  /// Overrides the browser's location as the first route. Null uses the
  /// platform's, which on the web is the address the app was opened at.
  final String? initialLocation;

  const SurfaceApp({super.key, required this.surface, this.initialLocation});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final router = SurfaceRouter.of(surface);
    return SurfaceScope(
      surface: surface,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) =>
            router.title(AppLocalizations.of(context)!),
        theme: AppTheme.light(),
        locale: app.localeOverride,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: initialLocation,
        // One route for the first location — not the default split of
        // `/bookings` into `/` plus `/bookings`, which would stack two gates.
        onGenerateInitialRoutes: (location) => [router.routeTo(location)],
        onGenerateRoute: (settings) => router.routeTo(settings.name),
      ),
    );
  }
}

/// Booted instead of any surface when the surface cannot be determined.
class SurfaceConfigErrorApp extends StatelessWidget {
  const SurfaceConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SurfaceConfigErrorScreen(),
      );
}
