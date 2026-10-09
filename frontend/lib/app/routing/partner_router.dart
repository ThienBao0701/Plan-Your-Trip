import 'package:flutter/widgets.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/partner_register_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/partner/account/partner_account_screen.dart';
import '../../features/partner/team/accept_invitation_screen.dart';
import 'invitation_link.dart';
import '../surface_gate.dart';
import '../../features/partner/partner_navigation.dart';
import '../../features/partner/partner_routes.dart';
import '../../l10n/app_localizations.dart';
import '../app_surface.dart';
import 'surface_router.dart';

/// The Partner workspace's locations: `/`, and `/{key}` for each of the
/// fourteen [PartnerNavigation] destinations — `/dashboard`, `/hotels`,
/// `/rooms`, `/calendar`, `/pricing`, `/bookings`, `/messages`, `/promotions`,
/// `/reviews`, `/finance`, `/analytics`, `/notifications`, `/team`, `/settings`
/// — plus RBAC R5's `/accept-invitation`, the emailed invitation link.
///
/// Inside the app the destinations keep their established route strings
/// (`/partner/bookings`), which are also the routes the backend's extranet menu
/// returns. Only the browser location drops the prefix, because the Partner
/// host already is the partner namespace.
class PartnerSurfaceRouter extends SurfaceRouter {
  const PartnerSurfaceRouter();

  @override
  AppSurface get surface => AppSurface.partner;

  /// The browser location of an in-app partner route; the root when unknown.
  static String locationOf(String route) {
    final destination = PartnerNavigation.byRoute(route);
    return destination == null ? SurfaceRouter.root : '/${destination.key}';
  }

  /// The in-app partner route for a browser location, or null when this
  /// surface does not serve it.
  static String? routeOf(String? location) {
    final path = SurfaceRouter.normalize(location);
    if (path == SurfaceRouter.root) return PartnerRoutes.dashboard;
    for (final destination in PartnerNavigation.destinations) {
      if ('/${destination.key}' == path) return destination.route;
    }
    return null;
  }

  /// Phase B — the account locations a signed-out Partner may open: registration,
  /// and the two link-driven flows whose emails are opened without a session.
  ///
  /// RBAC R5 adds `/accept-invitation`: the invitation email is opened signed
  /// out as often as signed in. Signed out it shows the Partner sign-in with the
  /// invitation guidance; once signed in, the same location opens the
  /// acceptance screen ([shellAt]).
  @override
  Set<String> get publicLocations => const {
        SurfaceRouter.register,
        SurfaceRouter.verifyEmail,
        SurfaceRouter.forgotPassword,
        SurfaceRouter.resetPassword,
        PartnerInvitationLink.location,
      };

  @override
  Widget? publicScreenAt(String location) => switch (location) {
        SurfaceRouter.register => const PartnerRegisterScreen(),
        SurfaceRouter.verifyEmail => const VerifyEmailScreen(),
        SurfaceRouter.forgotPassword => const ForgotPasswordScreen(),
        SurfaceRouter.resetPassword => const ResetPasswordScreen(),
        PartnerInvitationLink.location => const PartnerInvitationSignInScreen(),
        _ => null,
      };

  @override
  String resolve(String? location) {
    final path = SurfaceRouter.normalize(location);
    if (publicLocations.contains(path) || path == SurfaceRouter.account) {
      return path;
    }
    return routeOf(path) == null ? SurfaceRouter.root : path;
  }

  @override
  String title(AppLocalizations l10n) => l10n.surfaceTitlePartner;

  @override
  Widget signedOutEntry() => const LoginScreen(embeddedInSurfaceGate: true);

  @override
  Widget shellAt(String location) {
    // RBAC R5: the invitation link, opened signed in — or reached at the root
    // after a sign-in that started on the link — goes to the acceptance screen
    // while a token captured from that link is waiting in memory.
    if (location == PartnerInvitationLink.location ||
        (location == SurfaceRouter.root && PartnerInvitationLink.hasPending)) {
      return const AcceptInvitationScreen();
    }
    // The account area is a screen of its own rather than a workspace
    // destination: a Partner whose business profile is missing, in review,
    // rejected or suspended has no workspace, and still needs to reach it.
    if (location == SurfaceRouter.account) {
      return Builder(
        builder: (context) => PartnerAccountScreen(
          onBack: () => SurfaceNavigation.goHome(context),
        ),
      );
    }
    return PartnerRouteGuard(
      initialRoute: routeOf(location) ?? PartnerRoutes.dashboard,
      onRouteChanged: (route) =>
          SurfaceRouter.reportLocation(locationOf(route)),
    );
  }
}
