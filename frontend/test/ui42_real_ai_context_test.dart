import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/ai/real_ai_context_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget testApp({required Widget child, AppState? app, Locale? locale}) {
    return AppScope(
      notifier: app ?? AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  Future<void> pumpSize(WidgetTester tester, Widget widget, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

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

  AppState realApp(http.Client client) => AppState(
        api: ApiClient(client: client)..demoMode = false,
      )..demoMode = false;

  AppState demoApp(http.Client client) =>
      AppState(api: ApiClient(client: client));

  Map<String, dynamic> contextJson({
    Map<String, dynamic>? currentTrip,
    Map<String, dynamic>? budgetSummary,
    List<Map<String, dynamic>>? upcomingTrips,
  }) =>
      {
        'userProfile': {'id': 1},
        'interestProfile': {'userId': 1},
        'recommendations': [],
        'currentTrip': currentTrip ??
            {
              'id': 5,
              'title': 'Da Nang getaway',
              'destination': 'Da Nang',
              'coverImage': null,
              'startDate': '2030-05-01',
              'endDate': '2030-05-05',
              'status': 'ACTIVE',
              'isPublic': false,
              'dayCount': 5,
              'updatedAt': '2030-04-01T00:00:00Z',
            },
        'upcomingTrips': upcomingTrips ??
            [
              {
                'id': 6,
                'title': 'Hue trip',
                'destination': 'Hue',
                'startDate': '2030-07-01',
                'endDate': '2030-07-03',
                'status': 'PLANNING',
                'dayCount': 3,
              },
            ],
        'bookings': [],
        'savedCollections': [],
        'wishlistSummary': {'itemCount': 4, 'items': []},
        'recentReviews': [],
        'budgetSummary': budgetSummary ??
            {
              'tripPlanId': 5,
              'totalBudget': 1000000,
              'totalSpent': 250000,
              'remainingBudget': 750000,
              'overBudget': false,
              'categoryBreakdown': [],
            },
        'activitySummary': {
          'totalTrips': 3,
          'activeTrips': 1,
          'upcomingTrips': 1,
          'completedTrips': 1,
          'totalPlannedDays': 12,
          'totalBookings': 2,
          'savedCollections': 1,
          'wishlistItems': 4,
          'reviews': 6,
          'recommendations': 8,
        },
        'preferences': {'userId': 1},
        'contextGeneratedAt': '2030-05-02T10:00:00Z',
      };

  bool contextPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/ai/context');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onContext,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (contextPath(request)) {
          return (onContext ??
              (_) async => jsonResponse(contextJson(), 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('aggregate parses; correct path', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (contextPath(r)) seen = r;
      });
      expect(await app.loadRealAiContext(), AiContextOutcome.success);
      expect(seen!.url.path.endsWith('/me/ai/context'), isTrue);
      final c = app.realAiContext!;
      expect(c.activitySummary.totalTrips, 3);
      expect(c.activitySummary.recommendations, 8);
      expect(c.activitySummary.totalPlannedDays, 12);
      expect(c.wishlistItemCount, 4);
      expect(c.currentTrip!.title, 'Da Nang getaway');
      expect(c.currentTrip!.dayCount, 5);
      expect(c.upcomingTrips.single.id, 6);
      expect(c.budgetSummary!.totalSpent, 250000);
      expect(c.budgetSummary!.hasBudget, isTrue);
      expect(c.contextGeneratedAt, isNotNull);
    });

    test('nullable currentTrip / budgetSummary tolerated', () async {
      final app = routedApp(
        onContext: (_) async {
          final j = contextJson();
          j['currentTrip'] = null;
          j['budgetSummary'] = null;
          j['upcomingTrips'] = [];
          return jsonResponse(j, 200);
        },
      );
      expect(await app.loadRealAiContext(), AiContextOutcome.success);
      final c = app.realAiContext!;
      expect(c.currentTrip, isNull);
      expect(c.budgetSummary, isNull);
      expect(c.upcomingTrips, isEmpty);
      expect(c.activitySummary.totalTrips, 3);
    });

    test('non-object body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('[]', 200)));
      expect(await app.loadRealAiContext(), AiContextOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('load returns demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(contextJson(), 200);
      }));
      expect(await app.loadRealAiContext(), AiContextOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realAiContext, isNull);
    });
  });

  // ── Load / cache ────────────────────────────────────────────────────────────

  group('Load', () {
    test('cached snapshot not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (contextPath(r)) gets++;
      });
      await app.loadRealAiContext();
      await app.loadRealAiContext();
      expect(gets, 1);
      await app.loadRealAiContext(refresh: true);
      expect(gets, 2);
    });

    test('a failed refresh preserves the previous snapshot', () async {
      var fail = false;
      final app = routedApp(
        onContext: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/me/ai/context'), 500)
            : jsonResponse(contextJson(), 200),
      );
      await app.loadRealAiContext();
      expect(app.realAiContext, isNotNull);
      fail = true;
      expect(await app.loadRealAiContext(refresh: true),
          AiContextOutcome.serverError);
      expect(app.realAiContext, isNotNull);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onContext: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/ai/context'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealAiContext(), AiContextOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('404 → notFound; 500 → serverError; network', () async {
      final nf = routedApp(
        onContext: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/ai/context'), 404),
      );
      expect(await nf.loadRealAiContext(), AiContextOutcome.notFound);

      final se = routedApp(
        onContext: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/ai/context'), 500),
      );
      expect(await se.loadRealAiContext(), AiContextOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealAiContext(), AiContextOutcome.network);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears the AI context', () async {
      final app = routedApp();
      await app.loadRealAiContext();
      expect(app.realAiContext, isNotNull);
      await app.logout();
      expect(app.realAiContext, isNull);
      expect(app.realAiContextLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders the snapshot content', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealAiContextScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('ai-context-content')), findsOneWidget);
      expect(find.byKey(const Key('ai-context-current-trip')), findsOneWidget);
      expect(find.byKey(const Key('ai-context-budget')), findsOneWidget);
      expect(find.byKey(const Key('ai-context-upcoming-6')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onContext: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/ai/context'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealAiContextScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(
          find.byKey(const Key('ai-context-session-expired')), findsOneWidget);
    });

    testWidgets('a 500 shows the recoverable error state', (t) async {
      final app = routedApp(
        onContext: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/ai/context'), 500),
      );
      await pumpSize(
        t,
        testApp(child: const RealAiContextScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('ai-context-error')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI42 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.aiContextTitle,
        en.aiContextLoadingMessage,
        en.aiContextErrorMessage,
        en.aiContextExplainer,
        en.aiContextActivityTitle,
        en.aiContextCurrentTripTitle,
        en.aiContextBudgetTitle,
        en.aiContextUpcomingTripsTitle,
        en.aiContextUntitledTrip,
        en.aiContextOverBudget,
        en.aiContextStatTrips,
        en.aiContextStatActiveTrips,
        en.aiContextStatUpcomingTrips,
        en.aiContextStatCompletedTrips,
        en.aiContextStatPlannedDays,
        en.aiContextStatBookings,
        en.aiContextStatCollections,
        en.aiContextStatWishlist,
        en.aiContextStatReviews,
        en.aiContextStatRecommendations,
      ];
      final viValues = <String>[
        vi.aiContextTitle,
        vi.aiContextLoadingMessage,
        vi.aiContextErrorMessage,
        vi.aiContextExplainer,
        vi.aiContextActivityTitle,
        vi.aiContextCurrentTripTitle,
        vi.aiContextBudgetTitle,
        vi.aiContextUpcomingTripsTitle,
        vi.aiContextUntitledTrip,
        vi.aiContextOverBudget,
        vi.aiContextStatTrips,
        vi.aiContextStatActiveTrips,
        vi.aiContextStatUpcomingTrips,
        vi.aiContextStatCompletedTrips,
        vi.aiContextStatPlannedDays,
        vi.aiContextStatBookings,
        vi.aiContextStatCollections,
        vi.aiContextStatWishlist,
        vi.aiContextStatReviews,
        vi.aiContextStatRecommendations,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.aiContextTitle, isNot(vi.aiContextTitle));
    });

    test('parameterized keys resolve in both locales', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      expect(en.aiContextGeneratedAt('May 2'), contains('May 2'));
      expect(vi.aiContextGeneratedAt('May 2'), contains('May 2'));
      expect(en.aiContextTripDays(5), contains('5'));
      expect(en.aiContextStatSemantic('Trips', 3), contains('3'));
      expect(en.aiContextSpent('250'), contains('250'));
      expect(vi.aiContextRemaining('750'), contains('750'));
    });
  });
}
