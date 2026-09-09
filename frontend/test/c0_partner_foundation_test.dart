import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/partner_app_shell.dart';
import 'package:planyourtrip_frontend/features/partner/partner_dashboard_screen.dart';
import 'package:planyourtrip_frontend/features/partner/partner_module_screen.dart';
import 'package:planyourtrip_frontend/features/partner/partner_navigation.dart';
import 'package:planyourtrip_frontend/features/partner/partner_routes.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:planyourtrip_frontend/shared/widgets/glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C0 — Partner Extranet foundation.
///
/// Covers the five things the foundation has to get right before any partner
/// module is built on top of it: role detection fails closed, the route guard
/// mirrors the backend's rule, `PartnerState` maps every real backend outcome to
/// exactly one status, the shell renders responsively without borrowing the
/// traveller app's navigation, and no partner surface ever invents data.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Fixtures ─────────────────────────────────────────────────────────────

  http.Response jsonResponse(Object body, int status) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> errorBody(int status, String message, String path) => {
        'timestamp': DateTime.now().toIso8601String(),
        'status': status,
        'error': 'Error',
        'message': message,
        'path': path,
      };

  Map<String, dynamic> profileJson({
    String verificationStatus = 'APPROVED',
    String? rejectReason,
  }) =>
      {
        'id': 7,
        'userId': 42,
        'userName': 'Partner Owner',
        'userEmail': 'partner@planyourtrip.com',
        'businessName': 'Bay View Resorts',
        'businessType': 'COMPANY',
        'representativeName': 'Le Minh',
        'phone': '0900000000',
        'email': 'ops@bayview.example',
        'address': '1 Beach Road',
        'taxCode': null,
        'website': null,
        'verificationStatus': verificationStatus,
        'rejectReason': rejectReason,
        'submittedAt': '2026-08-01T02:00:00Z',
        'approvedAt': '2026-08-02T02:00:00Z',
        'rejectedAt': null,
        'approvedById': 1,
        'approvedByName': 'Admin',
        'createdAt': '2026-07-30T02:00:00Z',
        'updatedAt': '2026-08-02T02:00:00Z',
      };

  Map<String, dynamic> extranetHomeJson() => {
        'profile': {
          'id': 7,
          'businessName': 'Bay View Resorts',
          'representativeName': 'Le Minh',
          'email': 'ops@bayview.example',
        },
        'verificationStatus': 'APPROVED',
        'ownedHotelCount': 2,
        'activeRoomCount': 34,
        'todaysArrivals': 5,
        'todaysDepartures': 3,
        'unreadMessages': 4,
        'unreadNotifications': 9,
        'pendingReviews': 2,
        'activePromotions': 1,
        'financeSummary': null,
        'quickActions': const [],
      };

  List<Map<String, dynamic>> hotelsJson() => [
        {
          'id': 101,
          'name': 'Bay View Da Nang',
          'slug': 'bay-view-da-nang',
          'shortDescription': null,
          'address': '1 Beach Road',
          'active': true,
          'featured': false,
          'verified': true,
          'ratingAvg': 4.5,
          'reviewCount': 120,
          'status': 'PUBLISHED',
          'createdAt': '2026-07-30T02:00:00Z',
          'updatedAt': '2026-08-02T02:00:00Z',
        },
        {
          'id': 102,
          'name': 'Bay View Hue',
          'slug': 'bay-view-hue',
          'shortDescription': null,
          'address': '9 River Street',
          'active': false,
          'featured': false,
          'verified': false,
          'ratingAvg': 4.1,
          'reviewCount': 30,
          'status': 'DRAFT',
          'createdAt': '2026-07-30T02:00:00Z',
          'updatedAt': '2026-08-02T02:00:00Z',
        },
      ];

  List<Map<String, dynamic>> teamJson(String role) => [
        {
          'id': 55,
          'partnerProfileId': 7,
          'userId': 43,
          'userName': 'Front Desk',
          'userEmail': 'desk@bayview.example',
          'role': role,
          'active': true,
          'invitedAt': '2026-08-03T02:00:00Z',
          'joinedAt': '2026-08-03T02:00:00Z',
          'createdAt': '2026-08-03T02:00:00Z',
          'updatedAt': '2026-08-03T02:00:00Z',
        },
      ];

  /// Serves the four `/api/partner/**` endpoints C0 uses. Any override maps a
  /// path suffix to a canned response so a single test can fail exactly one
  /// call.
  MockClient partnerClient({
    Map<String, http.Response>? overrides,
    bool throwNetwork = false,
  }) =>
      MockClient((request) async {
        if (throwNetwork) throw http.ClientException('offline');
        final path = request.url.path;
        final override = overrides?.entries
            .where((entry) => path.endsWith(entry.key))
            .map((entry) => entry.value)
            .cast<http.Response?>()
            .firstWhere((value) => true, orElse: () => null);
        if (override != null) return override;

        if (path.endsWith('/partner/profile')) {
          return jsonResponse(profileJson(), 200);
        }
        if (path.endsWith('/partner/extranet/home')) {
          return jsonResponse(extranetHomeJson(), 200);
        }
        if (path.endsWith('/partner/hotels')) {
          return jsonResponse(hotelsJson(), 200);
        }
        if (path.endsWith('/partner/team')) {
          return jsonResponse(teamJson('OWNER'), 200);
        }

        // C1 — the dashboard screen now also consumes these. They are served
        // here so the C0 shell assertions still exercise a fully-loaded
        // dashboard; the C0 expectations themselves are unchanged.
        if (path.endsWith('/partner/dashboard')) {
          return jsonResponse({
            // todaysArrivals/todaysDepartures are the same values
            // `extranet/home` reports: PartnerExtranetService.getHome reads
            // them straight off bookingService.getDashboard.
            'todaysArrivals': 5,
            'todaysDepartures': 3,
            'currentGuests': 12,
            'upcoming': 27,
            'cancelled': 2,
            'completed': 40,
            'occupancyRate': 72.5,
            'revenueToday': 3200,
            'revenueMonth': 88000,
            'averageStayNights': 2.4,
          }, 200);
        }
        if (path.endsWith('/partner/analytics/overview')) {
          return jsonResponse({
            'totalRevenue': 125000,
            'totalBookings': 64,
            'confirmedBookings': 48,
            'cancelledBookings': 6,
            'completedBookings': 18,
            'occupancyRate': 68.25,
            'averageDailyRate': 1450.75,
            'averageStayNights': 2.4,
            'reviewAverage': 4.6,
            'reviewCount': 30,
            'unreadMessages': 4,
            'responseRate': 91.5,
          }, 200);
        }
        if (path.endsWith('/partner/analytics/occupancy')) {
          return jsonResponse({
            'occupancyByDay': [
              {'date': '2026-08-26', 'value': 72.5},
            ],
            'totalRoomInventory': 34,
            'soldRooms': 22,
            'availableRooms': 12,
            'stopSellDaysCount': 1,
          }, 200);
        }
        if (path.endsWith('/partner/analytics/revenue')) {
          return jsonResponse({
            'revenueByDay': [
              {'date': '2026-08-26', 'value': 4200},
            ],
            'revenueByRoom': <Object>[],
            'revenueByHotel': <Object>[],
            'revenueMonthToDate': 88000,
            'revenueLast30Days': 125000,
          }, 200);
        }
        if (path.endsWith('/partner/extranet/activity-logs')) {
          return jsonResponse(<Object>[], 200);
        }
        if (path.endsWith('/partner/extranet/menu')) {
          // Deliberately no badged entries here. C0's assertions are about the
          // shell's own sidebar, and a badged entry would render the same
          // destination name a second time in C1's "needs attention" rail,
          // making those `findsOneWidget` checks ambiguous for reasons that
          // have nothing to do with the shell. C1's own suite covers badges.
          return jsonResponse({'sections': <Object>[]}, 200);
        }
        return jsonResponse(errorBody(404, 'Not found', path), 404);
      });

  AppState partnerApp(http.Client client, {AppRole role = AppRole.partner}) =>
      AppState(api: ApiClient(client: client)..demoMode = false)
        ..demoMode = false
        ..email = 'partner@planyourtrip.com'
        ..role = role;

  Widget testApp({
    required Widget child,
    required AppState app,
    PartnerState? partner,
    Locale? locale,
  }) {
    return AppScope(
      notifier: app,
      child: PartnerScope(
        notifier: partner ?? (PartnerState(api: app.api)..bindSession(app)),
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
  }

  Future<void> pumpSized(
    WidgetTester tester,
    Widget widget,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  // ── 1. Role detection ────────────────────────────────────────────────────

  group('role detection', () {
    test('parses exactly the three roles the backend models', () {
      expect(AppRole.parse('USER'), AppRole.user);
      expect(AppRole.parse('PARTNER'), AppRole.partner);
      expect(AppRole.parse('ADMIN'), AppRole.admin);
    });

    test('fails closed for anything else, including the TBD super-roles', () {
      for (final raw in <Object?>[
        null,
        '',
        'partner',
        'Partner',
        'ROLE_PARTNER',
        'SUPER_ADMIN',
        'SUPER_PARTNER',
        'OWNER',
        42,
      ]) {
        expect(
          AppRole.parse(raw),
          AppRole.unknown,
          reason: 'role $raw must not be recognised',
        );
      }
      expect(AppRole.unknown.canEnterPartnerExtranet, isFalse);
      expect(AppRole.unknown.landsOnPartnerExtranet, isFalse);
      expect(AppRole.unknown.wireValue, isNull);
    });

    test('partner-route admission mirrors the backend URL rule', () {
      // SecurityConfig: /api/partner/** => hasAnyRole("PARTNER", "ADMIN")
      expect(AppRole.partner.canEnterPartnerExtranet, isTrue);
      expect(AppRole.admin.canEnterPartnerExtranet, isTrue);
      expect(AppRole.user.canEnterPartnerExtranet, isFalse);
      // ...but only PARTNER *lands* there by default.
      expect(AppRole.partner.landsOnPartnerExtranet, isTrue);
      expect(AppRole.admin.landsOnPartnerExtranet, isFalse);
    });

    testWidgets('login stores the role, logout clears it, restore reads it',
        (tester) async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return jsonResponse({
            'token': 'jwt-token',
            'user': {
              'id': 42,
              'fullName': 'Partner Owner',
              'email': 'partner@planyourtrip.com',
              'role': 'PARTNER',
            },
          }, 200);
        }
        return jsonResponse(errorBody(404, 'nope', request.url.path), 404);
      });
      final app = AppState(api: ApiClient(client: client));

      final result = await app.login('partner@planyourtrip.com', 'secret');
      expect(result['success'], isTrue);
      expect(app.role, AppRole.partner);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_role'), 'PARTNER');

      // A fresh AppState restoring the same session sees the same role.
      final restored = AppState(api: ApiClient(client: client));
      await restored.restore();
      expect(restored.role, AppRole.partner);

      await app.logout();
      expect(app.role, AppRole.unknown);
      final after = await SharedPreferences.getInstance();
      expect(after.getString('user_role'), isNull);
    });

    testWidgets('the demo account is never treated as a partner',
        (tester) async {
      final app = AppState(
        api: ApiClient(client: MockClient((_) async => http.Response('', 500))),
      );
      final result = await app.login(MockData.demoEmail, MockData.demoPassword);
      expect(result['success'], isTrue);
      expect(app.demoMode, isTrue);
      expect(app.role, AppRole.user);
      expect(app.role.canEnterPartnerExtranet, isFalse);
    });
  });

  // ── 2. Route protection ──────────────────────────────────────────────────

  group('partner route protection', () {
    testWidgets('a traveller account is refused', (tester) async {
      final app = partnerApp(partnerClient(), role: AppRole.user);
      await pumpSized(
        tester,
        testApp(child: const PartnerRouteGuard(), app: app),
        const Size(1400, 1000),
      );

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.partnerStatusNotPartnerTitle), findsOneWidget);
      expect(find.byType(PartnerAppShell), findsNothing);
    });

    testWidgets('an unrecognised role is refused (fail closed)',
        (tester) async {
      final app = partnerApp(partnerClient(), role: AppRole.unknown);
      await pumpSized(
        tester,
        testApp(child: const PartnerRouteGuard(), app: app),
        const Size(1400, 1000),
      );

      expect(
        find.text(AppLocalizationsEn().partnerStatusNotPartnerTitle),
        findsOneWidget,
      );
      expect(find.byType(PartnerAppShell), findsNothing);
    });

    testWidgets('a signed-out session is refused', (tester) async {
      final app = partnerApp(partnerClient())..email = null;
      await pumpSized(
        tester,
        testApp(child: const PartnerRouteGuard(), app: app),
        const Size(1400, 1000),
      );

      expect(
        find.text(AppLocalizationsEn().partnerStatusNotPartnerTitle),
        findsOneWidget,
      );
      expect(find.byType(PartnerAppShell), findsNothing);
    });

    testWidgets('a partner account reaches the shell', (tester) async {
      final app = partnerApp(partnerClient());
      await pumpSized(
        tester,
        testApp(child: const PartnerRouteGuard(), app: app),
        const Size(1400, 1000),
      );

      expect(find.byType(PartnerAppShell), findsOneWidget);
      expect(
        find.text(AppLocalizationsEn().partnerStatusNotPartnerTitle),
        findsNothing,
      );
    });

    test('the route namespace only claims /partner paths', () {
      expect(PartnerRoutes.isPartnerRoute('/partner'), isTrue);
      expect(PartnerRoutes.isPartnerRoute('/partner/bookings'), isTrue);
      expect(PartnerRoutes.isPartnerRoute('/partners'), isFalse);
      expect(PartnerRoutes.isPartnerRoute('/admin/partners'), isFalse);
      expect(PartnerRoutes.dashboard, '/partner/dashboard');
    });
  });

  // ── 3. PartnerState ──────────────────────────────────────────────────────

  group('PartnerState', () {
    test('starts idle and holds nothing', () {
      final state = PartnerState(api: ApiClient(client: partnerClient()));
      expect(state.status, PartnerWorkspaceStatus.idle);
      expect(state.overview, isNull);
      expect(state.properties, isEmpty);
      expect(state.teamRole, PartnerTeamRole.unknown);
      expect(state.isReady, isFalse);
    });

    test('demo mode never fabricates a workspace', () async {
      final app = AppState(api: ApiClient(client: partnerClient()))
        ..email = 'demo@planyourtrip.com'
        ..role = AppRole.user;
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.demoUnavailable);
      expect(state.overview, isNull);
      expect(state.properties, isEmpty);
    });

    test('a non-partner role is rejected before any request', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return jsonResponse(const {}, 200);
      });
      final app = partnerApp(client, role: AppRole.user);
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.notPartner);
      expect(calls, 0, reason: 'must not probe the partner API');
    });

    test('an approved owner loads overview, properties and team role',
        () async {
      final app = partnerApp(partnerClient());
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.ready);
      expect(state.isReady, isTrue);
      expect(state.profile?.businessName, 'Bay View Resorts');
      expect(state.overview?.todaysArrivals, 5);
      expect(state.overview?.unreadMessages, 4);
      expect(state.overview?.activeRoomCount, 34);
      expect(state.properties.length, 2);
      expect(state.selectedPropertyId, 101);
      expect(state.teamRole, PartnerTeamRole.owner);
      expect(state.propertiesUnavailable, isFalse);
    });

    test('a submitted profile waits for approval instead of erroring',
        () async {
      final app = partnerApp(partnerClient(overrides: {
        '/partner/profile':
            jsonResponse(profileJson(verificationStatus: 'SUBMITTED'), 200),
      }));
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.awaitingApproval);
      expect(state.overview, isNull);
      expect(state.isRetryable, isFalse);
    });

    test('a rejected profile keeps the reason available', () async {
      final app = partnerApp(partnerClient(overrides: {
        '/partner/profile': jsonResponse(
          profileJson(
            verificationStatus: 'REJECTED',
            rejectReason: 'Business licence unreadable',
          ),
          200,
        ),
      }));
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.rejected);
      expect(state.profile?.rejectReason, 'Business licence unreadable');
    });

    test('a suspended profile is surfaced as suspended', () async {
      final app = partnerApp(partnerClient(overrides: {
        '/partner/profile':
            jsonResponse(profileJson(verificationStatus: 'SUSPENDED'), 200),
      }));
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.suspended);
    });

    test('an unrecognised verification status is not treated as approved',
        () async {
      final app = partnerApp(partnerClient(overrides: {
        '/partner/profile':
            jsonResponse(profileJson(verificationStatus: 'PROBATION'), 200),
      }));
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.forbidden);
      expect(state.overview, isNull);
    });

    test('no profile and no membership means onboarding is required', () async {
      final app = partnerApp(partnerClient(overrides: {
        '/partner/profile': jsonResponse(
            errorBody(404, 'Partner profile not found', '/p'), 404),
        '/partner/team': jsonResponse(
            errorBody(404, 'Partner profile not found', '/t'), 404),
      }));
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.onboardingRequired);
    });

    test(
        'a team member without an owned profile is told the truth, '
        'not asked to onboard', () async {
      // Backend gap: PartnerExtranetService resolves owner-only, so a
      // MANAGER/FRONT_DESK/FINANCE/VIEWER gets 404 from /extranet/home even
      // though /partner/team serves them.
      final app = partnerApp(partnerClient(overrides: {
        '/partner/profile': jsonResponse(
            errorBody(404, 'Partner profile not found', '/p'), 404),
        '/partner/team': jsonResponse(teamJson('MANAGER'), 200),
      }));
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.teamMemberUnsupported);
      expect(
        state.teamRole,
        PartnerTeamRole.unknown,
        reason: 'the team list does not identify the caller — fail closed',
      );
    });

    test('401 maps to unauthorized', () async {
      final app = partnerApp(partnerClient(overrides: {
        '/partner/profile':
            jsonResponse(errorBody(401, 'Unauthorized', '/p'), 401),
      }));
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.unauthorized);
    });

    test('403 from the extranet maps to forbidden and is retryable', () async {
      final app = partnerApp(partnerClient(overrides: {
        '/partner/extranet/home': jsonResponse(
          errorBody(403, 'Partner profile is not approved', '/h'),
          403,
        ),
      }));
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.forbidden);
      expect(state.errorMessage, 'Partner profile is not approved');
      expect(state.isRetryable, isTrue);
    });

    test('a network failure is a retryable error, not a wrong workspace',
        () async {
      final app = partnerApp(partnerClient(throwNetwork: true));
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.error);
      expect(state.isRetryable, isTrue);
      expect(state.overview, isNull);
    });

    test('a failed property list degrades without failing the workspace',
        () async {
      final app = partnerApp(partnerClient(overrides: {
        '/partner/hotels': jsonResponse(errorBody(500, 'boom', '/h'), 500),
      }));
      final state = PartnerState(api: app.api);

      await state.loadWorkspace(app);

      expect(state.status, PartnerWorkspaceStatus.ready);
      expect(state.propertiesUnavailable, isTrue);
      expect(state.properties, isEmpty);
      expect(state.selectedPropertyId, isNull);
    });

    test('property selection is confined to what the backend authorized',
        () async {
      final app = partnerApp(partnerClient());
      final state = PartnerState(api: app.api);
      await state.loadWorkspace(app);

      state.selectProperty(102);
      expect(state.selectedPropertyId, 102);

      state.selectProperty(999);
      expect(
        state.selectedPropertyId,
        102,
        reason: 'an unauthorized property id must be ignored',
      );
    });

    test('changing session identity drops the loaded workspace', () async {
      final app = partnerApp(partnerClient());
      final state = PartnerState(api: app.api)..bindSession(app);
      await state.loadWorkspace(app);
      expect(state.isReady, isTrue);

      await app.logout();

      expect(state.status, PartnerWorkspaceStatus.idle);
      expect(state.overview, isNull);
      expect(state.properties, isEmpty);
      expect(state.teamRole, PartnerTeamRole.unknown);
    });
  });

  // ── 4. Navigation model ──────────────────────────────────────────────────

  group('partner navigation model', () {
    test('uses the backend menu keys and routes verbatim', () {
      // PartnerExtranetService.getMenu returns exactly these thirteen keys.
      const backendKeys = [
        'dashboard',
        'hotels',
        'rooms',
        'calendar',
        'pricing',
        'promotions',
        'bookings',
        'messages',
        'analytics',
        'finance',
        'reviews',
        'notifications',
        'settings',
      ];
      final clientKeys =
          PartnerNavigation.destinations.map((d) => d.key).toList();
      expect(clientKeys.toSet(), backendKeys.toSet());
      expect(clientKeys.length, backendKeys.length);

      for (final destination in PartnerNavigation.destinations) {
        expect(destination.route, '/partner/${destination.key}');
      }
    });

    test('every destination belongs to exactly one group', () {
      final grouped = <String>[];
      for (final group in PartnerNavigation.groups) {
        grouped.addAll(PartnerNavigation.ofGroup(group).map((d) => d.key));
      }
      expect(grouped.length, PartnerNavigation.destinations.length);
      expect(grouped.toSet().length, grouped.length);
    });

    test('only modules that are actually built are marked implemented', () {
      // The point of this assertion is that no destination claims to be built
      // before it is — an unbuilt module must fall through to the honest
      // "planned" view rather than render a fabricated screen. The list grows
      // as phases land: C0 shipped the shell + dashboard, C2 shipped hotels
      // (Properties), C3 shipped rooms, C4 shipped calendar (Inventory),
      // C5 shipped pricing (Rates), C6 shipped settings (Policies), C7 shipped
      // promotions (Promotions & voucher check), C8 shipped bookings
      // (Reservations & front desk), C9 added the property-calendar view to
      // the calendar destination C4 already held (leaving the ledger unchanged),
      // C10 concluded no new destination was warranted, C11 shipped finance and
      // analytics, C12 shipped reviews, D5 shipped messages (the guest↔host
      // conversation module) and D6 shipped notifications, completing the set.
      // This
      // list is a deliberate ledger — it
      // must be updated consciously each phase, so a destination flipped to
      // implemented without a real screen behind it fails here first.
      final implemented = PartnerNavigation.destinations
          .where((d) => d.implemented)
          .map((d) => d.key)
          .toList();
      expect(implemented, [
        'dashboard', 'hotels', 'rooms', 'calendar', 'pricing', 'bookings',
        'messages', 'promotions', 'reviews', 'finance', 'analytics',
        'notifications', 'settings',
      ]);

      // D6 shipped the last one, so nothing remains planned. The ledger stays
      // exhaustive: a destination flipped to implemented without a real screen
      // behind it still fails the list assertion above.
      final planned = PartnerNavigation.destinations
          .where((d) => !d.implemented)
          .map((d) => d.key)
          .toSet();
      expect(planned, isEmpty);
    });

    test('settings write access mirrors the backend team-role rule', () {
      final settings = PartnerNavigation.byRoute('/partner/settings')!;
      expect(settings.isWritableBy(PartnerTeamRole.owner), isTrue);
      expect(settings.isWritableBy(PartnerTeamRole.manager), isTrue);
      expect(settings.isWritableBy(PartnerTeamRole.frontDesk), isFalse);
      expect(settings.isWritableBy(PartnerTeamRole.viewer), isFalse);
      expect(settings.isWritableBy(PartnerTeamRole.unknown), isFalse);
    });
  });

  // ── 5. Shell rendering ───────────────────────────────────────────────────

  group('partner shell', () {
    testWidgets('renders a grouped sidebar on desktop and no bottom nav bar',
        (tester) async {
      final app = partnerApp(partnerClient());
      await pumpSized(
        tester,
        testApp(child: const PartnerRouteGuard(), app: app),
        const Size(1400, 1000),
      );

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.partnerExtranetTitle), findsWidgets);
      expect(
        find.text(l10n.partnerNavGroupOverview.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(l10n.partnerNavGroupOperations.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(l10n.partnerNavBookings), findsOneWidget);

      // The traveller app's consumer navigation must not leak into the console.
      expect(find.byType(OceanBottomNavigationBar), findsNothing);
    });

    testWidgets('renders backend counts on the dashboard, nothing invented',
        (tester) async {
      final app = partnerApp(partnerClient());
      await pumpSized(
        tester,
        testApp(child: const PartnerRouteGuard(), app: app),
        const Size(1400, 1000),
      );

      expect(find.byType(PartnerDashboardScreen), findsOneWidget);
      expect(find.text('Bay View Resorts'), findsWidgets);
      expect(find.text('5'), findsWidgets); // todaysArrivals
      expect(find.text('34'), findsWidgets); // activeRoomCount
      expect(find.text('Bay View Da Nang'), findsOneWidget);
      expect(find.text('Bay View Hue'), findsOneWidget);
    });

    testWidgets('a planned module shows a placeholder, not data',
        (tester) async {
      // Every shipped destination is now built — Finance in C11, Reviews in
      // C12, Messages in D5, Notifications in D6 — so there is no real
      // destination left to tap for this. The guarantee still matters for the
      // next unbuilt module, so it is asserted against the placeholder itself
      // with a destination that is deliberately not in the shipped set.
      //
      // Every original expectation is retained: planned badge, the route it
      // names, and no fabricated data.
      const planned = PartnerDestination(
        key: 'not-yet-built',
        route: '/partner/not-yet-built',
        icon: Icons.construction_outlined,
        selectedIcon: Icons.construction_rounded,
        group: PartnerNavGroup.account,
      );
      expect(planned.implemented, isFalse,
          reason: 'destinations default to unbuilt');
      expect(
        PartnerNavigation.destinations.any((d) => d.key == planned.key),
        isFalse,
        reason: 'this destination must not be one of the shipped thirteen',
      );

      final app = partnerApp(partnerClient());
      await pumpSized(
        tester,
        testApp(
          child: const PartnerModuleScreen(destination: planned),
          app: app,
        ),
        const Size(1400, 1000),
      );

      final l10n = AppLocalizationsEn();
      expect(find.byType(PartnerModuleScreen), findsOneWidget);
      expect(find.byType(PartnerDashboardScreen), findsNothing);
      expect(find.text(l10n.partnerModulePlannedBadge), findsOneWidget);
      expect(find.text('Route: /partner/not-yet-built'), findsOneWidget);
    });

    testWidgets('collapses to a drawer on a phone without breaking layout',
        (tester) async {
      final app = partnerApp(partnerClient());
      await pumpSized(
        tester,
        testApp(child: const PartnerRouteGuard(), app: app),
        const Size(390, 844),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(OceanBottomNavigationBar), findsNothing);
      // The sidebar is behind the drawer, so its group headers are not painted.
      expect(
        find.text(AppLocalizationsEn().partnerNavGroupOverview.toUpperCase()),
        findsNothing,
      );

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizationsEn().partnerNavGroupOverview.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('a workspace failure offers a retry instead of empty content',
        (tester) async {
      final app = partnerApp(partnerClient(throwNetwork: true));
      await pumpSized(
        tester,
        testApp(child: const PartnerRouteGuard(), app: app),
        const Size(1400, 1000),
      );

      final l10n = AppLocalizationsEn();
      expect(find.text(l10n.partnerStatusErrorTitle), findsOneWidget);
      expect(find.text(l10n.partnerActionRetry), findsOneWidget);
      expect(find.byType(PartnerDashboardScreen), findsNothing);
    });

    testWidgets('is fully localized in Vietnamese', (tester) async {
      final app = partnerApp(partnerClient());
      await pumpSized(
        tester,
        testApp(
          child: const PartnerRouteGuard(),
          app: app,
          locale: const Locale('vi'),
        ),
        const Size(1400, 1000),
      );

      final vi = AppLocalizationsVi();
      expect(find.text(vi.partnerExtranetTitle), findsWidgets);
      expect(
          find.text(vi.partnerNavGroupOverview.toUpperCase()), findsOneWidget);
      expect(find.text(vi.partnerMetricArrivals), findsOneWidget);
      expect(find.text(vi.partnerDashboardTodayHeading), findsOneWidget);
    });
  });
}
