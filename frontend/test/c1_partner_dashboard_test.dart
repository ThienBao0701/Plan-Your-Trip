import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_dashboard_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/dashboard/partner_dashboard_state.dart';
import 'package:planyourtrip_frontend/features/partner/dashboard/widgets/partner_dashboard_sections.dart';
import 'package:planyourtrip_frontend/features/partner/dashboard/widgets/partner_trend_chart.dart';
import 'package:planyourtrip_frontend/features/partner/partner_dashboard_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C1 — Partner Dashboard.
///
/// The dashboard's whole claim is that it shows real backend data, so these
/// tests assert against payloads shaped exactly like the records in
/// `backend-v1/develop`, and check that each backend outcome (200, empty, 401,
/// 403, 404, offline) produces its own distinct surface rather than one generic
/// failure. No test touches the network.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Fixtures — shaped from the backend DTOs, field for field ─────────────

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

  Map<String, dynamic> profileJson({String verificationStatus = 'APPROVED'}) => {
        'id': 7,
        'userId': 42,
        'businessName': 'Bay View Resorts',
        'representativeName': 'Le Minh',
        'email': 'ops@bayview.example',
        'verificationStatus': verificationStatus,
      };

  /// `PartnerFinanceDto.PartnerFinanceOverviewResponse`.
  Map<String, dynamic> financeJson({num gross = 125000}) => {
        'grossRevenue': gross,
        'netRevenue': gross * 0.85,
        'commissionAmount': gross * 0.15,
        'estimatedTax': 4200,
        'completedBookings': 18,
        'paidBookings': 21,
        'refundedAmount': 950,
        'pendingSettlement': 15400,
        'nextEstimatedPayoutDate': '2026-09-05',
      };

  /// `PartnerExtranetDto.PartnerExtranetHomeResponse`, including the embedded
  /// `financeSummary` and `quickActions` the real endpoint returns.
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
        'financeSummary': financeJson(),
        'quickActions': [
          {'label': "Review today's arrivals", 'route': '/partner/bookings'},
          {'label': 'Manage hotels', 'route': '/partner/hotels'},
        ],
      };

  List<Map<String, dynamic>> hotelsJson() => [
        {'id': 11, 'name': 'Bay View Danang', 'active': true},
        {'id': 12, 'name': 'Bay View Hoi An', 'active': true},
      ];

  List<Map<String, dynamic>> teamJson() => [
        {
          'id': 1,
          'partnerProfileId': 7,
          'userId': 42,
          'userName': 'Le Minh',
          'userEmail': 'ops@bayview.example',
          'role': 'OWNER',
          'active': true,
        },
      ];

  /// `PartnerBookingDto.PartnerDashboardResponse`.
  Map<String, dynamic> bookingDashboardJson() => {
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
      };

  /// `PartnerAnalyticsDto.PartnerAnalyticsOverviewResponse`.
  Map<String, dynamic> analyticsOverviewJson({
    int totalBookings = 64,
    Object? responseRate = 91.5,
    int reviewCount = 30,
  }) =>
      {
        'totalRevenue': 125000,
        'totalBookings': totalBookings,
        'confirmedBookings': 48,
        'cancelledBookings': 6,
        'completedBookings': 18,
        'occupancyRate': 68.25,
        'averageDailyRate': 1450.75,
        'averageStayNights': 2.4,
        'reviewAverage': 4.6,
        'reviewCount': reviewCount,
        'unreadMessages': 4,
        'responseRate': responseRate,
      };

  /// `PartnerAnalyticsDto.OccupancyAnalyticsResponse`.
  Map<String, dynamic> occupancyJson({
    List<Map<String, dynamic>>? byDay,
    int inventory = 34,
  }) =>
      {
        'occupancyByDay': byDay ??
            [
              {'date': '2026-08-25', 'value': 60.0},
              {'date': '2026-08-26', 'value': 72.5},
              {'date': '2026-08-27', 'value': 81.0},
            ],
        'totalRoomInventory': inventory,
        'soldRooms': 22,
        'availableRooms': 12,
        'stopSellDaysCount': 1,
      };

  /// `PartnerAnalyticsDto.RevenueAnalyticsResponse`.
  Map<String, dynamic> revenueJson({List<Map<String, dynamic>>? byDay}) => {
        'revenueByDay': byDay ??
            [
              {'date': '2026-08-25', 'value': 3100},
              {'date': '2026-08-26', 'value': 4200},
              {'date': '2026-08-27', 'value': 3900},
            ],
        'revenueByRoom': [
          {'label': 'Deluxe Sea View', 'value': 52000, 'count': 21},
        ],
        'revenueByHotel': [
          {'label': 'Bay View Danang', 'value': 78000, 'count': 40},
          {'label': 'Bay View Hoi An', 'value': 47000, 'count': 24},
        ],
        'revenueMonthToDate': 88000,
        'revenueLast30Days': 125000,
      };

  /// `PartnerExtranetDto.PartnerActivityLogResponse`.
  List<Map<String, dynamic>> activityJson() => [
        {
          'id': 501,
          'partnerProfileId': 7,
          'actorUserId': 42,
          'actorName': 'Le Minh',
          'action': 'SETTINGS_UPDATED',
          'entityType': 'PartnerSettings',
          'entityId': 7,
          'description': 'Updated check-in policy',
          'createdAt': '2026-08-28T09:15:00Z',
        },
        {
          'id': 500,
          'partnerProfileId': 7,
          'actorUserId': 42,
          'actorName': null,
          'action': 'PAYOUT_ACCOUNT_UPDATED',
          'entityType': null,
          'entityId': null,
          'description': null,
          'createdAt': '2026-08-27T04:00:00Z',
        },
      ];

  /// `PartnerExtranetDto.PartnerMenuResponse` — badge counts exactly as
  /// `getMenu` produces them: only four entries carry one, the rest are null.
  Map<String, dynamic> menuJson() => {
        'sections': [
          {'key': 'dashboard', 'label': 'Dashboard', 'route': '/partner/dashboard', 'enabled': true, 'badgeCount': null},
          {'key': 'promotions', 'label': 'Promotions', 'route': '/partner/promotions', 'enabled': true, 'badgeCount': 1},
          {'key': 'messages', 'label': 'Messages', 'route': '/partner/messages', 'enabled': true, 'badgeCount': 4},
          {'key': 'reviews', 'label': 'Reviews', 'route': '/partner/reviews', 'enabled': true, 'badgeCount': 2},
          {'key': 'notifications', 'label': 'Notifications', 'route': '/partner/notifications', 'enabled': true, 'badgeCount': 9},
          {'key': 'settings', 'label': 'Settings', 'route': '/partner/settings', 'enabled': true, 'badgeCount': null},
        ],
      };

  /// Records every path requested, so a test can assert which endpoints were
  /// (and were not) called.
  late List<String> requestLog;

  MockClient dashboardClient({
    Map<String, http.Response>? overrides,
    bool throwNetwork = false,
    String verificationStatus = 'APPROVED',
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requestLog.add(request.url.toString());
        if (throwNetwork) throw http.ClientException('offline');

        if (overrides != null) {
          for (final entry in overrides.entries) {
            if (path.endsWith(entry.key)) return entry.value;
          }
        }

        if (path.endsWith('/partner/profile')) {
          return jsonResponse(
              profileJson(verificationStatus: verificationStatus), 200);
        }
        if (path.endsWith('/partner/extranet/home')) {
          return jsonResponse(extranetHomeJson(), 200);
        }
        if (path.endsWith('/partner/extranet/menu')) {
          return jsonResponse(menuJson(), 200);
        }
        if (path.endsWith('/partner/extranet/activity-logs')) {
          return jsonResponse(activityJson(), 200);
        }
        if (path.endsWith('/partner/hotels')) {
          return jsonResponse(hotelsJson(), 200);
        }
        if (path.endsWith('/partner/team')) {
          return jsonResponse(teamJson(), 200);
        }
        if (path.endsWith('/partner/dashboard')) {
          return jsonResponse(bookingDashboardJson(), 200);
        }
        if (path.endsWith('/partner/analytics/overview')) {
          return jsonResponse(analyticsOverviewJson(), 200);
        }
        if (path.endsWith('/partner/analytics/occupancy')) {
          return jsonResponse(occupancyJson(), 200);
        }
        if (path.endsWith('/partner/analytics/revenue')) {
          return jsonResponse(revenueJson(), 200);
        }
        if (path.endsWith('/partner/finance/overview')) {
          return jsonResponse(financeJson(), 200);
        }
        return jsonResponse(errorBody(404, 'Not found', path), 404);
      });

  setUp(() => requestLog = <String>[]);

  AppState partnerApp(http.Client client) =>
      AppState(api: ApiClient(client: client)..demoMode = false)
        ..demoMode = false
        ..email = 'partner@planyourtrip.com'
        ..role = AppRole.partner;

  Widget testApp({
    required AppState app,
    required PartnerState partner,
    Locale? locale,
  }) =>
      AppScope(
        notifier: app,
        child: PartnerScope(
          notifier: partner,
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: PartnerDashboardScreen()),
            ),
          ),
        ),
      );

  /// Loads the workspace (C0) and then pumps the dashboard at [size].
  Future<({AppState app, PartnerState partner})> pumpDashboard(
    WidgetTester tester, {
    http.Client? client,
    Size size = const Size(1440, 1400),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? dashboardClient());
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp(app: app, partner: partner, locale: locale));
    await tester.pumpAndSettle();
    return (app: app, partner: partner);
  }

  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();

  // ── 1–2. The dashboard loads and renders real dashboard data ─────────────

  group('dashboard load', () {
    testWidgets('renders the workspace identity and today\'s operations',
        (tester) async {
      await pumpDashboard(tester);

      // WHO AM I / WHAT AM I OPERATING
      expect(find.text('Bay View Resorts'), findsOneWidget);
      expect(find.text(en.partnerVerificationApproved), findsOneWidget);

      // GET /api/partner/dashboard — values, not placeholders.
      expect(find.text(en.partnerDashboardTodayHeading), findsOneWidget);
      expect(find.text('12'), findsWidgets); // currentGuests
      expect(find.text('27'), findsWidgets); // upcoming
      expect(find.text('72.5%'), findsWidgets); // occupancyRate
      expect(find.text('2.4'), findsWidgets); // averageStayNights
    });

    testWidgets('calls every dashboard endpoint it needs', (tester) async {
      await pumpDashboard(tester);

      for (final path in [
        '/partner/dashboard',
        '/partner/analytics/overview',
        '/partner/analytics/occupancy',
        '/partner/analytics/revenue',
        '/partner/extranet/activity-logs',
        '/partner/extranet/menu',
      ]) {
        expect(requestLog.any((url) => url.contains(path)), isTrue,
            reason: 'expected a request to $path');
      }
    });

    testWidgets(
        'does NOT re-request finance at the default scope — extranet/home '
        'already embeds the identical record', (tester) async {
      await pumpDashboard(tester);

      expect(
        requestLog.where((url) => url.contains('/partner/finance/overview')),
        isEmpty,
        reason: 'financeSummary from extranet/home must be reused, not refetched',
      );
      // ...and the finance panel still renders from that embedded copy.
      expect(find.text(en.partnerFinanceGross), findsOneWidget);
    });
  });

  // ── 3. Finance ───────────────────────────────────────────────────────────

  group('finance', () {
    testWidgets('renders every field of the finance DTO', (tester) async {
      await pumpDashboard(tester);

      expect(find.text(en.partnerFinanceGross), findsOneWidget);
      expect(find.text(en.partnerFinanceNet), findsOneWidget);
      expect(find.text(en.partnerFinanceCommission), findsOneWidget);
      expect(find.text(en.partnerFinanceTax), findsOneWidget);
      expect(find.text(en.partnerFinanceRefunded), findsOneWidget);
      expect(find.text(en.partnerFinancePendingSettlement), findsOneWidget);
      expect(find.text(en.partnerFinanceNextPayout), findsOneWidget);
      expect(find.text('125,000'), findsWidgets); // grossRevenue
      expect(find.text('15,400'), findsWidgets); // pendingSettlement
    });

    testWidgets('a null nextEstimatedPayoutDate shows as unavailable, not today',
        (tester) async {
      final home = extranetHomeJson()
        ..['financeSummary'] = (financeJson()
          ..['nextEstimatedPayoutDate'] = null);
      await pumpDashboard(
        tester,
        client: dashboardClient(overrides: {
          '/partner/extranet/home': jsonResponse(home, 200),
        }),
      );

      expect(find.text(en.partnerValueUnavailable), findsWidgets);
    });

    testWidgets('narrowing the scope DOES fetch the scoped finance endpoint',
        (tester) async {
      final handles = await pumpDashboard(tester);
      requestLog.clear();

      // Selecting a 7-day window leaves the scope extranet/home described.
      final dashboard = tester
          .state<State<PartnerDashboardScreen>>(
              find.byType(PartnerDashboardScreen))
          .context;
      expect(dashboard, isNotNull);
      expect(handles.partner.isReady, isTrue);

      await tester.tap(find.text(en.partnerDashboardRangeLast7));
      await tester.pumpAndSettle();

      expect(
        requestLog.any((url) => url.contains('/partner/finance/overview')),
        isTrue,
        reason: 'a non-default window must query the scoped finance endpoint',
      );
      // and the analytics calls must carry the explicit window
      expect(
        requestLog.any((url) =>
            url.contains('/partner/analytics/overview') &&
            url.contains('from=') &&
            url.contains('to=')),
        isTrue,
      );
    });
  });

  // ── 4. Analytics ─────────────────────────────────────────────────────────

  group('analytics', () {
    testWidgets('renders overview, occupancy and revenue from the backend',
        (tester) async {
      await pumpDashboard(tester);

      expect(find.text(en.partnerDashboardPerformanceHeading), findsOneWidget);
      expect(find.text(en.partnerKpiAdr), findsOneWidget);
      expect(find.text('1,450.75'), findsWidgets); // averageDailyRate
      expect(find.text('68.3%'), findsWidgets); // occupancyRate, 1dp

      // "Occupancy" is legitimately both the panel heading and a KPI label in
      // two differently-scoped panels, so match on the unique labels instead.
      expect(find.text(en.partnerOccupancyInventory), findsOneWidget);
      expect(find.text(en.partnerOccupancySold), findsOneWidget);
      expect(find.text(en.partnerOccupancyStopSell), findsOneWidget);

      expect(find.text(en.partnerDashboardRevenueHeading), findsOneWidget);
      expect(find.text(en.partnerRevenueByProperty), findsOneWidget);
      expect(find.text('Bay View Danang'), findsWidgets);

      // Both charts painted from real series.
      expect(find.byType(PartnerTrendChart), findsNWidgets(2));
    });

    testWidgets('a null responseRate reads as unavailable, never 0%',
        (tester) async {
      await pumpDashboard(
        tester,
        client: dashboardClient(overrides: {
          '/partner/analytics/overview': jsonResponse(
              analyticsOverviewJson(responseRate: null), 200),
        }),
      );

      expect(find.text(en.partnerKpiResponseRate), findsOneWidget);
      expect(find.text('0.0%'), findsNothing);
      expect(find.text(en.partnerValueUnavailable), findsWidgets);
    });
  });

  // ── 5–6. Activity and menu ───────────────────────────────────────────────

  group('activity and menu', () {
    testWidgets('renders the audit trail newest-first with a null-safe actor',
        (tester) async {
      await pumpDashboard(tester);

      expect(find.text(en.partnerDashboardActivityHeading), findsOneWidget);
      expect(find.text('Updated check-in policy'), findsOneWidget);
      // description is null on the second row → the action stands in for it
      expect(find.text('PAYOUT_ACCOUNT_UPDATED'), findsWidgets);
      // actorName is null on the second row → labelled, not blank
      expect(
        find.textContaining(en.partnerDashboardActivityUnknownActor),
        findsWidgets,
      );
    });

    testWidgets('surfaces only positive menu badges, never a null as zero',
        (tester) async {
      await pumpDashboard(tester);

      expect(find.text(en.partnerDashboardAttentionHeading), findsOneWidget);
      // messages=4, reviews=2, promotions=1, notifications=9 carry badges
      expect(find.text(en.partnerNavMessages), findsWidgets);
      expect(find.text(en.partnerNavReviews), findsWidgets);
      // dashboard and settings have a null badgeCount → absent from the rail
      expect(find.text(en.partnerNavSettings), findsNothing);
    });

    testWidgets('renders backend-supplied quick actions verbatim',
        (tester) async {
      await pumpDashboard(tester);

      expect(find.text(en.partnerDashboardQuickActionsHeading), findsOneWidget);
      expect(find.text("Review today's arrivals"), findsOneWidget);
      expect(find.text('Manage hotels'), findsOneWidget);
    });
  });

  // ── 7. Empty data ────────────────────────────────────────────────────────

  group('empty data', () {
    testWidgets('an empty period shows an empty state, not a wall of zeros',
        (tester) async {
      await pumpDashboard(
        tester,
        client: dashboardClient(overrides: {
          '/partner/analytics/overview':
              jsonResponse(analyticsOverviewJson(totalBookings: 0), 200),
        }),
      );

      expect(find.text(en.partnerDashboardPerformanceEmpty), findsOneWidget);
      expect(find.text(en.partnerKpiAdr), findsNothing);
    });

    testWidgets('no inventory is distinguished from no sales', (tester) async {
      await pumpDashboard(
        tester,
        client: dashboardClient(overrides: {
          '/partner/analytics/occupancy':
              jsonResponse(occupancyJson(inventory: 0, byDay: []), 200),
        }),
      );

      expect(
          find.text(en.partnerDashboardOccupancyNoInventory), findsOneWidget);
    });

    testWidgets('an empty series shows the chart empty state', (tester) async {
      await pumpDashboard(
        tester,
        client: dashboardClient(overrides: {
          '/partner/analytics/revenue':
              jsonResponse(revenueJson(byDay: []), 200),
        }),
      );

      expect(find.text(en.partnerDashboardChartEmpty), findsWidgets);
    });

    testWidgets('an empty activity log says so', (tester) async {
      await pumpDashboard(
        tester,
        client: dashboardClient(overrides: {
          '/partner/extranet/activity-logs': jsonResponse(<Object>[], 200),
        }),
      );

      expect(find.text(en.partnerDashboardActivityEmpty), findsOneWidget);
    });

    testWidgets('an all-zero series still paints rather than dividing by zero',
        (tester) async {
      await pumpDashboard(
        tester,
        client: dashboardClient(overrides: {
          '/partner/analytics/revenue': jsonResponse(
              revenueJson(byDay: [
                {'date': '2026-08-25', 'value': 0},
                {'date': '2026-08-26', 'value': 0},
              ]),
              200),
        }),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PartnerTrendChart), findsWidgets);
    });
  });

  // ── 8–11. Error statuses ─────────────────────────────────────────────────

  group('error handling', () {
    testWidgets('401 on one panel shows the session message for that panel',
        (tester) async {
      await pumpDashboard(
        tester,
        client: dashboardClient(overrides: {
          '/partner/analytics/revenue': jsonResponse(
              errorBody(401, 'Unauthorized', '/api/partner/analytics/revenue'),
              401),
        }),
      );

      expect(find.text(en.partnerDashboardErrorUnauthorized), findsOneWidget);
      // ...and the rest of the console still works.
      expect(find.text(en.partnerDashboardTodayHeading), findsOneWidget);
    });

    testWidgets('403 is reported as an approval problem, not a generic error',
        (tester) async {
      await pumpDashboard(
        tester,
        client: dashboardClient(overrides: {
          '/partner/finance/overview': jsonResponse(
              errorBody(403, 'Partner profile is not approved',
                  '/api/partner/finance/overview'),
              403),
          // force the scoped finance call by removing the embedded copy
          '/partner/extranet/home': jsonResponse(
              extranetHomeJson()..remove('financeSummary'), 200),
        }),
      );

      expect(find.text(en.partnerDashboardErrorForbidden), findsOneWidget);
    });

    testWidgets('404 on one panel is distinct from 401 and 403',
        (tester) async {
      await pumpDashboard(
        tester,
        client: dashboardClient(overrides: {
          '/partner/extranet/activity-logs': jsonResponse(
              errorBody(404, 'Partner profile not found',
                  '/api/partner/extranet/activity-logs'),
              404),
        }),
      );

      expect(find.text(en.partnerDashboardErrorNotFound), findsOneWidget);
      expect(find.text(en.partnerDashboardErrorUnauthorized), findsNothing);
    });

    testWidgets('a 400 from an invalid range is its own message',
        (tester) async {
      await pumpDashboard(
        tester,
        client: dashboardClient(overrides: {
          '/partner/analytics/occupancy': jsonResponse(
              errorBody(400, 'from must not be after to',
                  '/api/partner/analytics/occupancy'),
              400),
        }),
      );

      expect(find.text(en.partnerDashboardErrorValidation), findsOneWidget);
    });

    testWidgets('a network failure is reported without crashing',
        (tester) async {
      final app = partnerApp(dashboardClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      expect(partner.isReady, isTrue);

      // Workspace loaded, then the connection drops before the dashboard loads.
      final offline = PartnerDashboardState(
        api: ApiClient(client: dashboardClient(throwNetwork: true))
          ..demoMode = false,
      );
      await offline.load(workspace: partner.overview);

      expect(offline.operations.isFailed, isTrue);
      expect(offline.operations.errorKind, ApiErrorKind.network);
      expect(offline.isWholeWorkspaceFailure, isFalse,
          reason: 'a network drop is retryable, not a session-level refusal');
    });

    testWidgets('every panel refused at session level defers to the workspace view',
        (tester) async {
      final app = partnerApp(dashboardClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final refused = PartnerDashboardState(
        api: ApiClient(
            client: MockClient((request) async => jsonResponse(
                errorBody(401, 'Unauthorized', request.url.path), 401)))
          ..demoMode = false,
      );
      await refused.load();

      expect(refused.isWholeWorkspaceFailure, isTrue);
      expect(refused.sessionFailureKind, ApiErrorKind.unauthorized);
    });
  });

  // ── 12. Partner lifecycle ────────────────────────────────────────────────

  group('partner status', () {
    testWidgets('a non-approved partner never reaches dashboard content',
        (tester) async {
      final app = partnerApp(dashboardClient(verificationStatus: 'SUBMITTED'));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      expect(partner.status, PartnerWorkspaceStatus.awaitingApproval);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerStatusAwaitingApprovalTitle), findsOneWidget);
      expect(find.text(en.partnerDashboardTodayHeading), findsNothing);
      // No dashboard request may be issued for an unapproved profile.
      expect(
        requestLog.any((url) => url.contains('/partner/analytics/')),
        isFalse,
      );
    });

    testWidgets('a rejected partner sees the rejected state', (tester) async {
      final app = partnerApp(dashboardClient(verificationStatus: 'REJECTED'));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerStatusRejectedTitle), findsOneWidget);
    });
  });

  // ── 13. Property context ─────────────────────────────────────────────────

  group('property scope', () {
    test('an unauthorized hotelId is never sent', () async {
      final api = ApiClient(client: dashboardClient())..demoMode = false;
      final dashboard = PartnerDashboardState(api: api);
      await dashboard.load();
      requestLog.clear();

      // 99 is not in the authorized list → ignored, no request, scope unchanged.
      await dashboard.selectProperty(99, authorizedIds: const [11, 12]);
      expect(dashboard.hotelId, isNull);
      expect(requestLog, isEmpty);

      // 11 is authorized → scope narrows and the calls carry it.
      await dashboard.selectProperty(11, authorizedIds: const [11, 12]);
      expect(dashboard.hotelId, 11);
      expect(
        requestLog.any((url) =>
            url.contains('/partner/analytics/overview') &&
            url.contains('hotelId=11')),
        isTrue,
      );
    });

    testWidgets('the property selector offers only backend-authorized entries',
        (tester) async {
      await pumpDashboard(tester);

      expect(find.byType(PartnerScopeBar), findsOneWidget);
      expect(find.text(en.partnerDashboardPropertyAll), findsWidgets);
    });

    test('the unscoped dashboard endpoint never receives scope parameters',
        () async {
      final api = ApiClient(client: dashboardClient())..demoMode = false;
      final dashboard = PartnerDashboardState(api: api);
      await dashboard.selectProperty(11, authorizedIds: const [11]);

      final dashboardCalls = requestLog
          .where((url) => url.contains('/partner/dashboard'))
          .toList();
      expect(dashboardCalls, isNotEmpty);
      for (final url in dashboardCalls) {
        expect(url.contains('hotelId'), isFalse,
            reason: '/partner/dashboard takes no parameters');
      }
    });
  });

  // ── 14–15. Responsive ────────────────────────────────────────────────────

  group('responsive', () {
    /// Collects layout errors as they are raised. `tester.takeException()` only
    /// surfaces the first, and an overflow is exactly the class of bug that
    /// hides at one breakpoint while every assertion still passes — so each
    /// breakpoint asserts on the full list.
    List<String> captureLayoutErrors(WidgetTester tester) {
      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details.toString());
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);
      return errors;
    }

    testWidgets('desktop renders every panel without overflowing',
        (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpDashboard(tester, size: const Size(1600, 1600));

      expect(find.text(en.partnerDashboardTodayHeading), findsOneWidget);
      expect(find.text(en.partnerDashboardPerformanceHeading), findsOneWidget);
      expect(find.text(en.partnerDashboardFinanceHeading), findsOneWidget);
      expect(find.text(en.partnerDashboardActivityHeading), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('mobile stacks the same panels with no horizontal overflow',
        (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpDashboard(tester, size: const Size(390, 2600));

      expect(find.text(en.partnerDashboardTodayHeading), findsOneWidget);
      expect(find.text(en.partnerDashboardFinanceHeading), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('a very narrow phone still does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpDashboard(tester, size: const Size(320, 3000));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('tablet renders without layout errors', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpDashboard(tester, size: const Size(820, 2200));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('a Vietnamese session at phone width does not overflow',
        (tester) async {
      // Vietnamese strings are materially longer than the English ones, which
      // is where a fixed-width row is most likely to break.
      final errors = captureLayoutErrors(tester);
      await pumpDashboard(
          tester, size: const Size(390, 3000), locale: const Locale('vi'));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });
  });

  // ── 16–17. Localization ──────────────────────────────────────────────────

  group('localization', () {
    testWidgets('English renders the English strings', (tester) async {
      await pumpDashboard(tester, locale: const Locale('en'));

      expect(find.text(en.partnerDashboardPerformanceHeading), findsOneWidget);
      expect(find.text(en.partnerDashboardFinanceHeading), findsOneWidget);
    });

    testWidgets('Vietnamese renders the Vietnamese strings', (tester) async {
      await pumpDashboard(tester, locale: const Locale('vi'));

      expect(find.text(vi.partnerDashboardPerformanceHeading), findsOneWidget);
      expect(find.text(vi.partnerDashboardFinanceHeading), findsOneWidget);
      expect(find.text(vi.partnerDashboardActivityHeading), findsOneWidget);
      // The English source strings must not leak through.
      expect(find.text(en.partnerDashboardFinanceHeading), findsNothing);
    });

    testWidgets(
        'backend English menu labels are localised by key in a Vietnamese session',
        (tester) async {
      await pumpDashboard(tester, locale: const Locale('vi'));

      // getMenu hard-codes "Messages"; the client must show the VI nav label.
      expect(find.text(vi.partnerNavMessages), findsWidgets);
      expect(find.text('Messages'), findsNothing);
    });

    test('every C1 string exists in both locales', () {
      // Reading a key that is missing from a locale throws at generation time,
      // so touching each in both proves parity for the strings C1 added.
      for (final l10n in <AppLocalizations>[en, vi]) {
        expect(l10n.partnerDashboardPerformanceHeading, isNotEmpty);
        expect(l10n.partnerDashboardOccupancyHeading, isNotEmpty);
        expect(l10n.partnerDashboardRevenueHeading, isNotEmpty);
        expect(l10n.partnerDashboardFinanceHeading, isNotEmpty);
        expect(l10n.partnerDashboardActivityHeading, isNotEmpty);
        expect(l10n.partnerDashboardAttentionHeading, isNotEmpty);
        expect(l10n.partnerDashboardErrorForbidden, isNotEmpty);
        expect(l10n.partnerKpiAdr, isNotEmpty);
        expect(l10n.partnerFinanceGross, isNotEmpty);
        expect(l10n.partnerDashboardPropertyCount(2), isNotEmpty);
        expect(l10n.partnerKpiReviewCount(0), isNotEmpty);
      }
    });
  });

  // ── Model mapping ────────────────────────────────────────────────────────

  group('DTO mapping', () {
    test('maps PartnerDashboardResponse field for field', () {
      final model = PartnerBookingDashboard.fromJson(bookingDashboardJson());
      expect(model.currentGuests, 12);
      expect(model.upcoming, 27);
      expect(model.cancelled, 2);
      expect(model.completed, 40);
      expect(model.occupancyRate, 72.5);
      expect(model.revenueToday, 3200);
      expect(model.revenueMonth, 88000);
      expect(model.averageStayNights, 2.4);
    });

    test('keeps a null responseRate null rather than defaulting to zero', () {
      final model = PartnerAnalyticsOverview.fromJson(
          analyticsOverviewJson(responseRate: null));
      expect(model.responseRate, isNull);
    });

    test('a null badgeCount is not attention-worthy', () {
      const withNull = PartnerMenuItem(
          key: 'settings', label: 'Settings', route: '/x', enabled: true);
      const withZero = PartnerMenuItem(
          key: 'reviews',
          label: 'Reviews',
          route: '/x',
          enabled: true,
          badgeCount: 0);
      const withCount = PartnerMenuItem(
          key: 'messages',
          label: 'Messages',
          route: '/x',
          enabled: true,
          badgeCount: 3);
      expect(withNull.needsAttention, isFalse);
      expect(withZero.needsAttention, isFalse);
      expect(withCount.needsAttention, isTrue);
    });

    test('the default range matches the backend resolveRange window', () {
      final now = DateTime(2026, 8, 29);
      final resolved = PartnerDashboardRange.last30.resolve(now);
      expect(resolved.to, DateTime(2026, 8, 29));
      // resolveRange: from = to.minusDays(29) for a 30-day inclusive window
      expect(resolved.from, DateTime(2026, 7, 31));
      expect(PartnerDashboardRange.last30.isBackendDefault, isTrue);
      expect(PartnerDashboardRange.last7.isBackendDefault, isFalse);
    });

    test('a malformed payload fails rather than rendering invented data',
        () async {
      final api = ApiClient(
          client: MockClient((_) async =>
              http.Response('not json', 200, headers: {
                'content-type': 'application/json; charset=utf-8'
              })))
        ..demoMode = false;
      final result = await api.getPartnerBookingDashboard();
      expect(result.success, isFalse);
      expect(result.errorKind, ApiErrorKind.malformed);
    });
  });
}
