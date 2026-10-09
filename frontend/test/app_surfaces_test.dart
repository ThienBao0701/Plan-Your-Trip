import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planyourtrip_frontend/app/app_surface.dart';
import 'package:planyourtrip_frontend/app/routing/admin_router.dart';
import 'package:planyourtrip_frontend/app/routing/partner_router.dart';
import 'package:planyourtrip_frontend/app/routing/surface_router.dart';
import 'package:planyourtrip_frontend/app/routing/user_router.dart';
import 'package:planyourtrip_frontend/app/surface_app.dart';
import 'package:planyourtrip_frontend/app/surface_gate.dart';
import 'package:planyourtrip_frontend/core/admin/admin_state.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/admin/admin_app_shell.dart';
import 'package:planyourtrip_frontend/features/admin/admin_navigation.dart';
import 'package:planyourtrip_frontend/features/admin/admin_routes.dart';
import 'package:planyourtrip_frontend/features/auth/login_screen.dart';
import 'package:planyourtrip_frontend/features/auth/onboarding_screen.dart';
import 'package:planyourtrip_frontend/features/home/app_shell.dart';
import 'package:planyourtrip_frontend/features/partner/partner_app_shell.dart';
import 'package:planyourtrip_frontend/features/partner/partner_navigation.dart';
import 'package:planyourtrip_frontend/features/partner/partner_routes.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:planyourtrip_frontend/shared/widgets/glass_widgets.dart';
import 'support/admin_access_stub.dart';

/// App surfaces — User, Partner and Admin as three applications from one
/// codebase, each on its own origin and admitting exactly one role family.
///
/// What is pinned here is the boundary, not the features behind it: the
/// feature screens keep their own suites. In particular:
///
///  * every browser path resolves inside its own surface, never to another;
///  * a wrong or unrecognised role never builds a protected shell — so no
///    partner or admin request is ever issued for it;
///  * sign-in and sign-out never leave the surface;
///  * a surface that cannot be determined fails closed.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();

  late List<String> requestLog;
  setUp(() => requestLog = <String>[]);

  void ignoreNetworkImageErrors() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  /// A backend that answers sign-in with [loginRole] and 404 for everything
  /// else, recording every path it is asked for.
  http.Client backend({String? loginRole}) => MockClient((request) async {
        requestLog.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({
              'token': 'surface-test-token',
              'user': {'role': loginRole},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'status': 404, 'message': 'Not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

  AppState signedOut({String? loginRole}) => AppState(
      api: ApiClient(client: withAdminAccess(backend(loginRole: loginRole))))
    ..demoMode = false;

  AppState signedIn(AppRole role) => signedOut()
    ..email = 'someone@example.com'
    ..role = role;

  /// The traveller demo session: role USER, local mock data, no backend.
  AppState travellerDemo() => AppState()
    ..email = MockData.demoEmail
    ..role = AppRole.user;

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  /// Mounts [surface] the way `bootstrapSurface` does: the session, then only
  /// the domain state that surface uses, then the surface app.
  Future<void> pumpSurface(
    WidgetTester tester, {
    required AppSurface surface,
    required AppState app,
    String? location,
    Size size = const Size(1600, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget child = SurfaceApp(surface: surface, initialLocation: location);
    if (surface == AppSurface.partner) {
      child = PartnerScope(
        notifier: PartnerState(api: app.api)..bindSession(app),
        child: child,
      );
    } else if (surface == AppSurface.admin) {
      child = AdminScope(
        notifier: AdminState(api: app.api)..bindSession(app),
        child: child,
      );
    }
    await tester.pumpWidget(AppScope(notifier: app, child: child));
    await settle(tester);
  }

  /// Records every location the app reports to the browser.
  List<String> captureBrowserLocations(WidgetTester tester) {
    final reported = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.navigation, (call) async {
      if (call.method == 'routeInformationUpdated') {
        final arguments = call.arguments as Map<Object?, Object?>;
        reported.add('${arguments['uri'] ?? arguments['location']}');
      }
      return null;
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(SystemChannels.navigation, null));
    return reported;
  }

  void expectNoProtectedShell() {
    expect(find.byType(PartnerAppShell), findsNothing);
    expect(find.byType(AdminAppShell), findsNothing);
    expect(find.byType(AppShell), findsNothing);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. The surface model
  // ══════════════════════════════════════════════════════════════════════════

  group('AppSurface', () {
    test('parsing is exact and fails closed', () {
      expect(AppSurface.parse('user'), AppSurface.user);
      expect(AppSurface.parse('partner'), AppSurface.partner);
      expect(AppSurface.parse('admin'), AppSurface.admin);
      for (final raw in [null, '', 'USER', 'Partner', 'super_admin', 'owner']) {
        expect(AppSurface.parse(raw), isNull,
            reason: '"$raw" names no surface');
      }
    });

    test('each surface admits exactly one role family, and unknown nowhere',
        () {
      const admitted = {
        AppSurface.user: AppRole.user,
        AppSurface.partner: AppRole.partner,
        AppSurface.admin: AppRole.admin,
      };
      for (final surface in AppSurface.values) {
        for (final role in AppRole.values) {
          expect(surface.admits(role), admitted[surface] == role,
              reason: '$surface admitting $role');
        }
      }
    });

    test('without APP_SURFACE an entrypoint boots the surface it names', () {
      for (final surface in AppSurface.values) {
        expect(AppSurface.fromEnvironment(fallback: surface), surface);
      }
    });

    test('Demo Mode and self sign-up belong to the traveller app only', () {
      expect(AppSurface.user.offersDemoMode, isTrue);
      expect(AppSurface.user.offersSelfRegistration, isTrue);
      for (final surface in [AppSurface.partner, AppSurface.admin]) {
        expect(surface.offersDemoMode, isFalse);
        expect(surface.offersSelfRegistration, isFalse);
      }
    });

    test('no public origin is assumed when none is configured', () {
      for (final surface in AppSurface.values) {
        expect(surface.publicUrl, isNull);
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 2. Routers — root-relative locations, owned per surface
  // ══════════════════════════════════════════════════════════════════════════

  group('surface routers', () {
    test('the Partner workspace serves all fourteen destinations at the root',
        () {
      // Thirteen backend menu keys plus R5's permission-gated `team`.
      expect(PartnerNavigation.destinations, hasLength(14));
      for (final destination in PartnerNavigation.destinations) {
        final location = '/${destination.key}';
        expect(PartnerSurfaceRouter.locationOf(destination.route), location);
        expect(PartnerSurfaceRouter.routeOf(location), destination.route);
        expect(const PartnerSurfaceRouter().resolve(location), location);
      }
      expect(PartnerSurfaceRouter.routeOf('/'), PartnerRoutes.dashboard);
    });

    test('the Admin console serves every destination, Reference Data included',
        () {
      for (final destination in AdminNavigation.destinations) {
        final location = AdminSurfaceRouter.locationOf(destination.route);
        expect(location.startsWith('/admin'), isFalse, reason: location);
        expect(AdminSurfaceRouter.routeOf(location), destination.route);
      }
      expect(AdminSurfaceRouter.routeOf('/reference-data'),
          AdminRoutes.referenceData);
      expect(AdminSurfaceRouter.routeOf('/'), AdminRoutes.dashboard);
    });

    test('the traveller app serves its four tabs', () {
      expect(UserSurfaceRouter.tabLocations,
          ['/', '/trips', '/planner', '/profile']);
      for (final location in UserSurfaceRouter.tabLocations) {
        expect(const UserSurfaceRouter().resolve(location), location);
      }
    });

    test('role-prefixed and foreign paths resolve to the surface\'s own root',
        () {
      const partner = PartnerSurfaceRouter();
      const admin = AdminSurfaceRouter();
      const user = UserSurfaceRouter();
      expect(partner.resolve('/partner/bookings'), '/');
      expect(partner.resolve('/trips'), '/');
      expect(partner.resolve('/reference-data'), '/');
      expect(admin.resolve('/admin/reference-data'), '/');
      expect(admin.resolve('/hotels'), '/');
      expect(admin.resolve('/trips'), '/');
      expect(user.resolve('/user/trips'), '/');
      expect(user.resolve('/dashboard'), '/');
      expect(user.resolve('/reference-data'), '/');
    });

    test('a location ignores its query, fragment and trailing slash', () {
      expect(SurfaceRouter.normalize(null), '/');
      expect(SurfaceRouter.normalize(''), '/');
      expect(SurfaceRouter.normalize('/bookings/'), '/bookings');
      expect(
          SurfaceRouter.normalize('/bookings?arrivalToday=true'), '/bookings');
      expect(SurfaceRouter.normalize('/messages#thread-4'), '/messages');
      expect(SurfaceRouter.normalize('settings'), '/settings');
    });

    test('each surface resolves to its own router', () {
      for (final surface in AppSurface.values) {
        expect(SurfaceRouter.of(surface).surface, surface);
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 3. The gate
  // ══════════════════════════════════════════════════════════════════════════

  group('signed out', () {
    testWidgets('the traveller app opens on its onboarding', (tester) async {
      ignoreNetworkImageErrors();
      await pumpSurface(tester, surface: AppSurface.user, app: signedOut());
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expectNoProtectedShell();
    });

    testWidgets('the Partner workspace opens on its own sign-in, without demo',
        (tester) async {
      await pumpSurface(tester, surface: AppSurface.partner, app: signedOut());
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(en.authPartnerLoginTitle), findsOneWidget);
      expect(find.byKey(const Key('login-demo')), findsNothing);
      expect(find.byKey(const Key('login-account-required')), findsOneWidget);
      expect(find.text(en.authCreateAccountAction), findsNothing);
      expectNoProtectedShell();
      expect(requestLog, isEmpty, reason: 'nothing is loaded before sign-in');
    });

    testWidgets('the Admin console opens on its own sign-in, without demo',
        (tester) async {
      await pumpSurface(tester, surface: AppSurface.admin, app: signedOut());
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(en.authAdminLoginTitle), findsOneWidget);
      expect(find.byKey(const Key('login-demo')), findsNothing);
      expect(find.text(en.authCreateAccountAction), findsNothing);
      expectNoProtectedShell();
      expect(requestLog, isEmpty);
    });
  });

  group('a role the surface does not admit never builds a shell', () {
    for (final surface in AppSurface.values) {
      for (final role in AppRole.values.where((r) => !surface.admits(r))) {
        testWidgets('${surface.id} refuses $role', (tester) async {
          await pumpSurface(tester, surface: surface, app: signedIn(role));

          expect(find.byType(SurfaceAccessDeniedScreen), findsOneWidget);
          expect(
            find.text(switch (surface) {
              AppSurface.user => en.surfaceAccessDeniedUser,
              AppSurface.partner => en.surfaceAccessDeniedPartner,
              AppSurface.admin => en.surfaceAccessDeniedAdmin,
            }),
            findsOneWidget,
          );
          expectNoProtectedShell();
          expect(
            requestLog.where((e) =>
                e.contains('/api/partner/') || e.contains('/api/admin/')),
            isEmpty,
            reason: 'a refused session must not reach protected endpoints',
          );
        });
      }
    }

    testWidgets('signing out of a refusal returns to that surface\'s sign-in',
        (tester) async {
      final app = signedIn(AppRole.user);
      await pumpSurface(tester, surface: AppSurface.partner, app: app);

      await tester.tap(find.byKey(const Key('surface-sign-out')));
      await settle(tester);

      expect(app.email, isNull);
      expect(find.text(en.authPartnerLoginTitle), findsOneWidget);
      expectNoProtectedShell();
    });
  });

  group('an admitted role opens its own shell at the requested location', () {
    testWidgets('Partner at /bookings', (tester) async {
      await pumpSurface(tester,
          surface: AppSurface.partner,
          app: signedIn(AppRole.partner),
          location: '/bookings');
      final shell =
          tester.widget<PartnerAppShell>(find.byType(PartnerAppShell));
      expect(shell.initialRoute, '/partner/bookings');
      expect(find.byType(AppShell), findsNothing);
      expect(find.byType(AdminAppShell), findsNothing);
    });

    testWidgets('Partner at its root opens the dashboard', (tester) async {
      await pumpSurface(tester,
          surface: AppSurface.partner, app: signedIn(AppRole.partner));
      expect(
          tester
              .widget<PartnerAppShell>(find.byType(PartnerAppShell))
              .initialRoute,
          PartnerRoutes.dashboard);
    });

    testWidgets('an unknown Partner path stays in the Partner workspace',
        (tester) async {
      await pumpSurface(tester,
          surface: AppSurface.partner,
          app: signedIn(AppRole.partner),
          location: '/not-a-destination');
      expect(
          tester
              .widget<PartnerAppShell>(find.byType(PartnerAppShell))
              .initialRoute,
          PartnerRoutes.dashboard);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('Admin at /reference-data', (tester) async {
      await pumpSurface(tester,
          surface: AppSurface.admin,
          app: signedIn(AppRole.admin),
          location: '/reference-data');
      expect(
          tester.widget<AdminAppShell>(find.byType(AdminAppShell)).initialRoute,
          AdminRoutes.referenceData);
      expect(find.byType(AppShell), findsNothing);
      expect(find.byType(PartnerAppShell), findsNothing);
    });

    testWidgets('User at /trips', (tester) async {
      ignoreNetworkImageErrors();
      await pumpSurface(tester,
          surface: AppSurface.user, app: travellerDemo(), location: '/trips');
      expect(tester.widget<AppShell>(find.byType(AppShell)).initialTab, 1);
      expect(find.byType(PartnerAppShell), findsNothing);
      expect(find.byType(AdminAppShell), findsNothing);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 4. Sign-in and sign-out stay on the surface
  // ══════════════════════════════════════════════════════════════════════════

  group('sign-in and sign-out', () {
    Future<void> signIn(WidgetTester tester) async {
      await tester.enterText(
          find.byKey(const Key('login-email-field')), 'someone@example.com');
      await tester.enterText(
          find.byKey(const Key('login-password-field')), 'password123');
      await tester.ensureVisible(find.byKey(const Key('login-submit')));
      await tester.tap(find.byKey(const Key('login-submit')));
      await settle(tester);
    }

    testWidgets('a partner signs in to the workspace at the deep link',
        (tester) async {
      final app = signedOut(loginRole: 'PARTNER');
      await pumpSurface(tester,
          surface: AppSurface.partner, app: app, location: '/messages');

      await signIn(tester);

      expect(app.role, AppRole.partner);
      expect(find.byType(LoginScreen), findsNothing);
      expect(
          tester
              .widget<PartnerAppShell>(find.byType(PartnerAppShell))
              .initialRoute,
          '/partner/messages');
    });

    testWidgets('a traveller signing in to the Partner workspace is refused',
        (tester) async {
      await pumpSurface(tester,
          surface: AppSurface.partner, app: signedOut(loginRole: 'USER'));
      await signIn(tester);
      expect(find.byType(SurfaceAccessDeniedScreen), findsOneWidget);
      expectNoProtectedShell();
    });

    testWidgets('a partner signing in to the Admin console is refused',
        (tester) async {
      await pumpSurface(tester,
          surface: AppSurface.admin, app: signedOut(loginRole: 'PARTNER'));
      await signIn(tester);
      expect(find.byType(SurfaceAccessDeniedScreen), findsOneWidget);
      expectNoProtectedShell();
    });

    testWidgets(
        'an unrecognised role is refused, not sent to the traveller app',
        (tester) async {
      ignoreNetworkImageErrors();
      await pumpSurface(tester,
          surface: AppSurface.user, app: signedOut(loginRole: 'SUPER_ADMIN'));
      // The traveller app opens on onboarding; its sign-in is one step in.
      await tester.tap(find.text('Start planning'));
      await settle(tester);
      await signIn(tester);
      expect(find.byType(SurfaceAccessDeniedScreen), findsOneWidget);
      expectNoProtectedShell();
    });

    testWidgets('Demo Mode opens the traveller app', (tester) async {
      ignoreNetworkImageErrors();
      final app = AppState();
      await pumpSurface(tester, surface: AppSurface.user, app: app);
      await tester.tap(find.text('Start planning'));
      await settle(tester);
      await tester.ensureVisible(find.byKey(const Key('login-demo')));
      await tester.tap(find.byKey(const Key('login-demo')));
      await settle(tester);

      expect(app.demoMode, isTrue);
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(PartnerAppShell), findsNothing);
      expect(find.byType(AdminAppShell), findsNothing);
    });

    testWidgets('signing out of the Partner workspace returns to its sign-in',
        (tester) async {
      final app = signedIn(AppRole.partner);
      await pumpSurface(tester, surface: AppSurface.partner, app: app);

      await tester.ensureVisible(find.byKey(const Key('partner-sign-out')));
      await tester.tap(find.byKey(const Key('partner-sign-out')));
      await settle(tester);

      expect(app.email, isNull);
      expect(find.text(en.authPartnerLoginTitle), findsOneWidget);
      expectNoProtectedShell();
    });

    testWidgets('signing out of the Admin console returns to its sign-in',
        (tester) async {
      final app = signedIn(AppRole.admin);
      await pumpSurface(tester, surface: AppSurface.admin, app: app);

      await tester.ensureVisible(find.byKey(const Key('admin-sign-out')));
      await tester.tap(find.byKey(const Key('admin-sign-out')));
      await settle(tester);

      expect(app.email, isNull);
      expect(find.text(en.authAdminLoginTitle), findsOneWidget);
      expectNoProtectedShell();
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 5. The browser location follows the shell
  // ══════════════════════════════════════════════════════════════════════════

  group('browser location', () {
    testWidgets('the Partner workspace reports the destination it moves to',
        (tester) async {
      final reported = captureBrowserLocations(tester);
      await pumpSurface(tester,
          surface: AppSurface.partner, app: signedIn(AppRole.partner));

      await tester.tap(find.text(en.partnerNavMessages).first);
      await settle(tester);

      expect(reported, contains('/messages'));
    });

    testWidgets('the Admin console reports the destination it moves to',
        (tester) async {
      final reported = captureBrowserLocations(tester);
      await pumpSurface(tester,
          surface: AppSurface.admin, app: signedIn(AppRole.admin));

      await tester.tap(find.text(en.adminNavReferenceData).first);
      await settle(tester);

      expect(reported, contains('/reference-data'));
    });

    testWidgets('the traveller app reports the tab it moves to',
        (tester) async {
      ignoreNetworkImageErrors();
      final reported = captureBrowserLocations(tester);
      await pumpSurface(tester, surface: AppSurface.user, app: travellerDemo());

      await tester.tap(find.descendant(
        of: find.byType(OceanBottomNavigationBar),
        matching: find.byIcon(Icons.person_outline_rounded),
      ));
      await settle(tester);

      expect(reported, contains('/profile'));
    });

    testWidgets('a prefixed path is corrected to the surface root',
        (tester) async {
      final reported = captureBrowserLocations(tester);
      await pumpSurface(tester,
          surface: AppSurface.partner,
          app: signedIn(AppRole.partner),
          location: '/partner/bookings');
      expect(reported, contains('/'));
      expect(reported, isNot(contains('/partner/bookings')));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // 6. An undetermined surface fails closed
  // ══════════════════════════════════════════════════════════════════════════

  group('configuration', () {
    Widget bare(AppState app, Widget home) => AppScope(
          notifier: app,
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        );

    testWidgets('a gate outside any surface is the configuration error',
        (tester) async {
      await tester
          .pumpWidget(bare(signedIn(AppRole.admin), const SurfaceGate()));
      await settle(tester);
      expect(find.byType(SurfaceConfigErrorScreen), findsOneWidget);
      expectNoProtectedShell();
    });

    testWidgets(
        'a sign-in outside any surface hands off to the error, not a shell',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = AppState();
      await tester.pumpWidget(bare(app, const LoginScreen()));
      await settle(tester);

      await tester.ensureVisible(find.byKey(const Key('login-demo')));
      await tester.tap(find.byKey(const Key('login-demo')));
      await settle(tester);

      expect(app.email, MockData.demoEmail);
      expect(find.byType(SurfaceConfigErrorScreen), findsOneWidget);
      expectNoProtectedShell();
    });

    testWidgets('the configuration-error app boots nothing else',
        (tester) async {
      await tester.pumpWidget(const SurfaceConfigErrorApp());
      await settle(tester);
      expect(find.text(en.surfaceConfigErrorTitle), findsOneWidget);
      expectNoProtectedShell();
    });
  });

  test('surface strings exist in both locales and differ', () {
    expect(vi.surfaceSignOut, isNot(en.surfaceSignOut));
    expect(vi.surfaceAccessDeniedTitle, isNot(en.surfaceAccessDeniedTitle));
    expect(vi.authPartnerLoginTitle, isNot(en.authPartnerLoginTitle));
    expect(vi.authAdminLoginTitle, isNot(en.authAdminLoginTitle));
    expect(vi.surfaceSignedInAs('a@b.c'), contains('a@b.c'));
  });
}
