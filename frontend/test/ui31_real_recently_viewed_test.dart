import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/places/real_recently_viewed_screen.dart';
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

  Map<String, dynamic> itemJson({
    int placeId = 7,
    String name = 'Backend Villa',
    String category = 'Hotels',
    double ratingAvg = 4.6,
    int reviewCount = 12,
    String viewedAt = '2030-05-01T10:00:00Z',
  }) =>
      {
        'placeId': placeId,
        'name': name,
        'slug': 'backend-villa',
        'categoryName': category,
        'address': 'Da Lat, Lam Dong',
        'shortDescription': 'A villa.',
        'ratingAvg': ratingAvg,
        'reviewCount': reviewCount,
        'viewedAt': viewedAt,
      };

  Map<String, dynamic> listJson(List<Map<String, dynamic>> items) =>
      {'items': items};

  bool getPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/recently-viewed');
  bool clearPath(http.Request r) =>
      r.method == 'DELETE' && r.url.path.endsWith('/me/recently-viewed');
  bool removePath(http.Request r) =>
      r.method == 'DELETE' &&
      RegExp(r'/me/recently-viewed/\d+$').hasMatch(r.url.path);
  bool recordPath(http.Request r) =>
      r.method == 'POST' &&
      RegExp(r'/me/recently-viewed/\d+$').hasMatch(r.url.path);

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onGet,
    Future<http.Response> Function(http.Request)? onClear,
    Future<http.Response> Function(http.Request)? onRemove,
    Future<http.Response> Function(http.Request)? onRecord,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (recordPath(request)) {
          return (onRecord ??
              (_) async => jsonResponse(itemJson(), 201))(request);
        }
        if (removePath(request)) {
          return (onRemove ?? (_) async => http.Response('', 204))(request);
        }
        if (clearPath(request)) {
          return (onClear ?? (_) async => http.Response('', 204))(request);
        }
        if (getPath(request)) {
          return (onGet ??
              (_) async => jsonResponse(listJson([itemJson()]), 200))(request);
        }
        return jsonResponse(listJson(const []), 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('getRecentlyViewed GETs /api/me/recently-viewed and unwraps items',
        () async {
      http.Request? captured;
      final app = routedApp(onRequest: (r) {
        if (getPath(r)) captured = r;
      });
      final outcome = await app.loadRealRecentlyViewed();
      expect(outcome, RecentlyViewedOutcome.success);
      expect(captured!.url.path.endsWith('/me/recently-viewed'), isTrue);
      expect(app.realRecentlyViewed, hasLength(1));
    });

    test('RecentlyViewedRecord.fromJson maps every field', () async {
      final app = routedApp(
        onGet: (_) async => jsonResponse(listJson([itemJson()]), 200),
      );
      await app.loadRealRecentlyViewed();
      final r = app.realRecentlyViewed.single;
      expect(r.placeId, 7);
      expect(r.name, 'Backend Villa');
      expect(r.slug, 'backend-villa');
      expect(r.categoryName, 'Hotels');
      expect(r.address, 'Da Lat, Lam Dong');
      expect(r.ratingAvg, 4.6);
      expect(r.reviewCount, 12);
      expect(r.viewedAt, isNotNull);
    });

    test('a non-object body (missing items) is a malformed → serverError',
        () async {
      final app = routedApp(onGet: (_) async => jsonResponse(const [], 200));
      final outcome = await app.loadRealRecentlyViewed();
      expect(outcome, RecentlyViewedOutcome.serverError);
      expect(app.realRecentlyViewed, isEmpty);
    });
  });

  // ── Demo Mode ────────────────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all recently-viewed actions make zero HTTP in Demo Mode', () async {
      var calls = 0;
      final app = demoApp(MockClient((r) async {
        calls++;
        return jsonResponse(listJson(const []), 200);
      }));
      expect(await app.loadRealRecentlyViewed(),
          RecentlyViewedOutcome.demoUnavailable);
      expect(await app.recordRealRecentlyView(7),
          RecentlyViewedOutcome.demoUnavailable);
      expect(await app.clearRealRecentlyViewed(),
          RecentlyViewedOutcome.demoUnavailable);
      expect(await app.removeRealRecentlyViewed(7),
          RecentlyViewedOutcome.demoUnavailable);
      expect(calls, 0);
    });
  });

  // ── Load / mutations ──────────────────────────────────────────────────────

  group('Load and mutations', () {
    test('load stores the list; empty is an honest success', () async {
      final app =
          routedApp(onGet: (_) async => jsonResponse(listJson(const []), 200));
      final outcome = await app.loadRealRecentlyViewed();
      expect(outcome, RecentlyViewedOutcome.success);
      expect(app.realRecentlyViewedLoaded, isTrue);
      expect(app.realRecentlyViewed, isEmpty);
    });

    test('a second load without refresh does not re-fetch', () async {
      var calls = 0;
      final app = routedApp(onGet: (r) async {
        calls++;
        return jsonResponse(listJson([itemJson()]), 200);
      });
      await app.loadRealRecentlyViewed();
      await app.loadRealRecentlyViewed();
      expect(calls, 1);
    });

    test('clear-all empties the list only after the server confirms', () async {
      final app = routedApp(
        onGet: (_) async => jsonResponse(listJson([itemJson()]), 200),
        onClear: (_) async => http.Response('', 204),
      );
      await app.loadRealRecentlyViewed();
      expect(app.realRecentlyViewed, isNotEmpty);
      final outcome = await app.clearRealRecentlyViewed();
      expect(outcome, RecentlyViewedOutcome.success);
      expect(app.realRecentlyViewed, isEmpty);
    });

    test('remove-one drops only that place after the server confirms',
        () async {
      final app = routedApp(
        onGet: (_) async => jsonResponse(
            listJson([itemJson(placeId: 7), itemJson(placeId: 9)]), 200),
        onRemove: (_) async => http.Response('', 204),
      );
      await app.loadRealRecentlyViewed();
      expect(app.realRecentlyViewed, hasLength(2));
      final outcome = await app.removeRealRecentlyViewed(7);
      expect(outcome, RecentlyViewedOutcome.success);
      expect(app.realRecentlyViewed.map((r) => r.placeId), [9]);
    });

    test('recordView invalidates the list so it re-fetches', () async {
      final app = routedApp();
      await app.loadRealRecentlyViewed();
      expect(app.realRecentlyViewedLoaded, isTrue);
      final outcome = await app.recordRealRecentlyView(7);
      expect(outcome, RecentlyViewedOutcome.success);
      expect(app.realRecentlyViewedLoaded, isFalse);
    });

    test('a concurrent remove on the same id returns busy', () async {
      final gate = Completer<http.Response>();
      final app = routedApp(
        onGet: (_) async => jsonResponse(listJson([itemJson()]), 200),
        onRemove: (_) => gate.future,
      );
      await app.loadRealRecentlyViewed();
      final first = app.removeRealRecentlyViewed(7);
      final second = await app.removeRealRecentlyViewed(7);
      expect(second, RecentlyViewedOutcome.busy);
      gate.complete(http.Response('', 204));
      expect(await first, RecentlyViewedOutcome.success);
    });
  });

  // ── Errors ────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('load 401 → sessionExpired, no auto-logout / no demo switch',
        () async {
      final app = routedApp(
        onGet: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/recently-viewed'), 401),
      );
      app.email = 'mai@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealRecentlyViewed(),
          RecentlyViewedOutcome.sessionExpired);
      expect(app.email, 'mai@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('remove 404 → notFound; clear 500 → serverError; network', () async {
      final nf = routedApp(
        onGet: (_) async => jsonResponse(listJson([itemJson()]), 200),
        onRemove: (_) async =>
            jsonResponse(errorBody(404, 'x', '/api/me/recently-viewed/7'), 404),
      );
      await nf.loadRealRecentlyViewed();
      expect(
          await nf.removeRealRecentlyViewed(7), RecentlyViewedOutcome.notFound);

      final se = routedApp(
        onGet: (_) async => jsonResponse(listJson([itemJson()]), 200),
        onClear: (_) async =>
            jsonResponse(errorBody(500, 'x', '/api/me/recently-viewed'), 500),
      );
      await se.loadRealRecentlyViewed();
      expect(await se.clearRealRecentlyViewed(),
          RecentlyViewedOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealRecentlyViewed(), RecentlyViewedOutcome.network);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears the recently-viewed list', () async {
      final app = routedApp();
      await app.loadRealRecentlyViewed();
      expect(app.realRecentlyViewed, isNotEmpty);
      await app.logout();
      expect(app.realRecentlyViewed, isEmpty);
      expect(app.realRecentlyViewedLoaded, isFalse);
      expect(app.recentlyViewedActionInFlight, isEmpty);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders cards and removes one after confirmation', (t) async {
      final app = routedApp(
        onGet: (_) async => jsonResponse(listJson([itemJson()]), 200),
        onRemove: (_) async => http.Response('', 204),
      );
      await pumpSize(
        t,
        testApp(child: const RealRecentlyViewedScreen(), app: app),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('recently-viewed-content')), findsOneWidget);
      expect(find.byKey(const Key('recently-viewed-card-7')), findsOneWidget);

      await t.tap(find.byKey(const Key('recently-viewed-remove-7')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('recently-viewed-remove-confirm')),
          findsOneWidget);
      await t.tap(find.byKey(const Key('recently-viewed-remove-confirm')));
      await t.pumpAndSettle();
      expect(app.realRecentlyViewed, isEmpty);
    });

    testWidgets('empty list shows the empty state', (t) async {
      final app =
          routedApp(onGet: (_) async => jsonResponse(listJson(const []), 200));
      await pumpSize(
        t,
        testApp(child: const RealRecentlyViewedScreen(), app: app),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('recently-viewed-empty')), findsOneWidget);
    });

    testWidgets('clear-all empties the list after confirmation', (t) async {
      final app = routedApp(
        onGet: (_) async => jsonResponse(listJson([itemJson()]), 200),
        onClear: (_) async => http.Response('', 204),
      );
      await pumpSize(
        t,
        testApp(child: const RealRecentlyViewedScreen(), app: app),
        const Size(1200, 2000),
      );
      await t.tap(find.byKey(const Key('recently-viewed-clear')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('recently-viewed-clear-confirm')));
      await t.pumpAndSettle();
      expect(app.realRecentlyViewed, isEmpty);
      expect(find.byKey(const Key('recently-viewed-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onGet: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/recently-viewed'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealRecentlyViewedScreen(), app: app),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('recently-viewed-session-expired')),
          findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI31 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final values = <String>[
        en.recentlyViewedTitle,
        vi.recentlyViewedTitle,
        en.recentlyViewedLoadingMessage,
        vi.recentlyViewedLoadingMessage,
        en.recentlyViewedEmptyTitle,
        vi.recentlyViewedEmptyTitle,
        en.recentlyViewedClearConfirmMessage,
        vi.recentlyViewedClearConfirmMessage,
        en.recentlyViewedRemovedMessage,
        vi.recentlyViewedRemovedMessage,
        en.recentlyViewedNetworkMessage,
        vi.recentlyViewedNetworkMessage,
      ];
      for (final s in values) {
        expect(s.trim(), isNotEmpty);
      }
      expect(en.recentlyViewedTitle != vi.recentlyViewedTitle, isTrue);
      expect(en.recentlyViewedCardSemantic('X'), isNotEmpty);
      expect(en.recentlyViewedRemoveConfirmMessage('X'), isNotEmpty);
      expect(en.recentlyViewedRatingSemantic('4.6', 12), isNotEmpty);
    });
  });
}
