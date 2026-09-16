import 'package:flutter/widgets.dart';

import '../../features/auth/onboarding_screen.dart';
import '../../features/home/app_shell.dart';
import '../../l10n/app_localizations.dart';
import '../app_surface.dart';
import 'surface_router.dart';

/// The traveller app's locations: one per [AppShell] tab.
///
/// `/` is Explore; `/trips`, `/planner` and `/profile` are the other three tabs.
/// Screens reached from a tab are pushed on the navigator as they always were
/// and keep the tab's location.
class UserSurfaceRouter extends SurfaceRouter {
  const UserSurfaceRouter();

  /// Tab locations in [AppShell] order: Explore, Trips, Planner, Profile.
  static const List<String> tabLocations = [
    SurfaceRouter.root,
    '/trips',
    '/planner',
    '/profile',
  ];

  @override
  AppSurface get surface => AppSurface.user;

  @override
  String resolve(String? location) {
    final path = SurfaceRouter.normalize(location);
    return tabLocations.contains(path) ? path : SurfaceRouter.root;
  }

  @override
  String title(AppLocalizations l10n) => l10n.appTitle;

  /// Unchanged traveller flow: onboarding first, then sign-in.
  @override
  Widget signedOutEntry() => const OnboardingScreen();

  @override
  Widget shellAt(String location) => AppShell(
        initialTab: tabLocations.indexOf(resolve(location)),
        onTabChanged: (tab) => SurfaceRouter.reportLocation(tabLocations[tab]),
      );
}
