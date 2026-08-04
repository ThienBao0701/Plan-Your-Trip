import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/rewards/rewards_screen.dart';
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

  Map<String, dynamic> accountJson({
    int currentBalance = 250,
    int lifetimePointsEarned = 400,
  }) =>
      {
        'id': 5,
        'userId': 9,
        'currentBalance': currentBalance,
        'lifetimePointsEarned': lifetimePointsEarned,
        'createdAt': '2030-01-01T00:00:00Z',
        'updatedAt': '2030-02-01T00:00:00Z',
      };

  Map<String, dynamic> txJson({
    int id = 1,
    String type = 'EARN_BOOKING',
    int points = 100,
    int before = 0,
    int after = 100,
  }) =>
      {
        'id': id,
        'accountId': 5,
        'transactionType': type,
        'points': points,
        'balanceBefore': before,
        'balanceAfter': after,
        'description': 'Booking #123',
        'referenceType': 'BOOKING',
        'referenceId': 123,
        'idempotencyKey': null,
        'createdAt': '2030-01-05T00:00:00Z',
      };

  Map<String, dynamic> txPageJson(
    List<Map<String, dynamic>> content, {
    int page = 0,
    int totalPages = 1,
  }) =>
      {
        'content': content,
        'page': page,
        'size': 20,
        'totalElements': content.length,
        'totalPages': totalPages,
      };

  bool txPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/loyalty/transactions');
  bool accountPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/loyalty');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onAccount,
    Future<http.Response> Function(http.Request)? onTransactions,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (txPath(request)) {
          return (onTransactions ??
              (_) async => jsonResponse(txPageJson([txJson()]), 200))(request);
        }
        if (accountPath(request)) {
          return (onAccount ??
              (_) async => jsonResponse(accountJson(), 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('account + transactions parse; paths carry page/size', () async {
      final seen = <String>[];
      final app = routedApp(onRequest: (r) {
        if (r.method == 'GET') seen.add('${r.url.path}?${r.url.query}');
      });
      expect(await app.loadRealLoyalty(), LoyaltyOutcome.success);
      expect(app.realLoyaltyAccount!.currentBalance, 250);
      expect(app.realLoyaltyAccount!.lifetimePointsEarned, 400);
      expect(app.realLoyaltyTransactions.single.points, 100);
      expect(app.realLoyaltyTransactions.single.typeView,
          LoyaltyTransactionType.earnBooking);
      expect(app.realLoyaltyTransactions.single.increasesBalance, isTrue);
      expect(seen.any((s) => s.contains('/me/loyalty/transactions')), isTrue);
      expect(seen.any((s) => s.contains('page=0') && s.contains('size=20')),
          isTrue);
    });

    test('type mapper + direction fallback', () {
      expect(loyaltyTransactionTypeFromCode('REDEMPTION_DEBIT'),
          LoyaltyTransactionType.redemptionDebit);
      expect(loyaltyTransactionTypeFromCode('WHATEVER'), isNull);
      // Debit decreases; an unknown type falls back to the balance delta.
      final debit = RealLoyaltyTransaction.fromJson(
          txJson(type: 'REDEMPTION_DEBIT', points: 50, before: 100, after: 50));
      expect(debit.increasesBalance, isFalse);
      final unknown = RealLoyaltyTransaction.fromJson(
          txJson(type: 'MYSTERY', points: 5, before: 10, after: 15));
      expect(unknown.typeView, isNull);
      expect(unknown.increasesBalance, isTrue);
    });

    test('non-object account body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('null', 200)));
      expect(await app.loadRealLoyalty(), LoyaltyOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all loyalty methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(accountJson(), 200);
      }));
      expect(await app.loadRealLoyalty(), LoyaltyOutcome.demoUnavailable);
      expect(await app.loadMoreRealLoyaltyTransactions(),
          LoyaltyOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realLoyaltyAccount, isNull);
      expect(app.realLoyaltyTransactions, isEmpty);
    });
  });

  // ── Load, cache, pagination ──────────────────────────────────────────────────

  group('Load and pagination', () {
    test('cached load is not re-fetched unless refreshed', () async {
      var accountGets = 0;
      final app = routedApp(onRequest: (r) {
        if (accountPath(r)) accountGets++;
      });
      await app.loadRealLoyalty();
      await app.loadRealLoyalty();
      expect(accountGets, 1);
      await app.loadRealLoyalty(refresh: true);
      expect(accountGets, 2);
    });

    test('load-more appends the next transaction page', () async {
      final app = routedApp(
        onTransactions: (r) async {
          final page = r.url.queryParameters['page'];
          if (page == '1') {
            return jsonResponse(
                txPageJson([txJson(id: 2)], page: 1, totalPages: 2), 200);
          }
          return jsonResponse(
              txPageJson([txJson(id: 1)], page: 0, totalPages: 2), 200);
        },
      );
      await app.loadRealLoyalty();
      expect(app.realLoyaltyTransactions.map((t) => t.id), [1]);
      expect(app.realLoyaltyTxHasMore, isTrue);
      expect(
          await app.loadMoreRealLoyaltyTransactions(), LoyaltyOutcome.success);
      expect(app.realLoyaltyTransactions.map((t) => t.id), [1, 2]);
      expect(app.realLoyaltyTxHasMore, isFalse);
    });

    test('both calls must succeed: a transactions failure is not committed',
        () async {
      final app = routedApp(
        onTransactions: (_) async => jsonResponse(
            errorBody(500, 'x', '/api/me/loyalty/transactions'), 500),
      );
      expect(await app.loadRealLoyalty(), LoyaltyOutcome.serverError);
      expect(app.realLoyaltyLoaded, isFalse);
      expect(app.realLoyaltyAccount, isNull);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onAccount: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/loyalty'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealLoyalty(), LoyaltyOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('404 → notFound; 500 → serverError; network', () async {
      final nf = routedApp(
        onAccount: (_) async =>
            jsonResponse(errorBody(404, 'x', '/api/me/loyalty'), 404),
      );
      expect(await nf.loadRealLoyalty(), LoyaltyOutcome.notFound);

      final se = routedApp(
        onAccount: (_) async =>
            jsonResponse(errorBody(500, 'x', '/api/me/loyalty'), 500),
      );
      expect(await se.loadRealLoyalty(), LoyaltyOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealLoyalty(), LoyaltyOutcome.network);
    });

    test('a failed refresh preserves the previously loaded state', () async {
      var fail = false;
      final app = routedApp(
        onAccount: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/api/me/loyalty'), 500)
            : jsonResponse(accountJson(), 200),
      );
      await app.loadRealLoyalty();
      expect(app.realLoyaltyAccount, isNotNull);
      fail = true;
      expect(
          await app.loadRealLoyalty(refresh: true), LoyaltyOutcome.serverError);
      expect(app.realLoyaltyAccount, isNotNull);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all loyalty state', () async {
      final app = routedApp();
      await app.loadRealLoyalty();
      expect(app.realLoyaltyAccount, isNotNull);
      expect(app.realLoyaltyTransactions, isNotEmpty);
      await app.logout();
      expect(app.realLoyaltyAccount, isNull);
      expect(app.realLoyaltyTransactions, isEmpty);
      expect(app.realLoyaltyLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('real loyalty screen renders metrics + ledger', (t) async {
      final app = routedApp(
        onTransactions: (_) async =>
            jsonResponse(txPageJson([txJson()], totalPages: 2), 200),
      );
      await pumpSize(
        t,
        testApp(child: const LoyaltyScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('loyalty-content')), findsOneWidget);
      expect(find.text(AppLocalizationsEn().loyaltyTxnEarnBooking),
          findsOneWidget);
      // totalPages == 2 → load-more appears.
      expect(find.byKey(const Key('loyalty-load-more')), findsOneWidget);
    });

    testWidgets('empty ledger shows the empty state', (t) async {
      final app = routedApp(
        onTransactions: (_) async => jsonResponse(txPageJson(const []), 200),
      );
      await pumpSize(
        t,
        testApp(child: const LoyaltyScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(
          find.byKey(const Key('loyalty-transactions-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onAccount: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/loyalty'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const LoyaltyScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('loyalty-session-expired')), findsOneWidget);
    });

    testWidgets(
        'demo loyalty screen is unchanged (no real content / zero HTTP)',
        (t) async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(accountJson(), 200);
      }));
      await pumpSize(
        t,
        testApp(child: const LoyaltyScreen(), app: app),
        const Size(1200, 2400),
      );
      // Demo path does not render the real body and makes no HTTP call.
      expect(find.byKey(const Key('loyalty-content')), findsNothing);
      expect(calls, 0);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI34 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.loyaltyRealLoadingMessage,
        en.loyaltyRealErrorMessage,
        en.loyaltyRealLoadMore,
        en.loyaltyRealEarnNote,
      ];
      final viValues = <String>[
        vi.loyaltyRealLoadingMessage,
        vi.loyaltyRealErrorMessage,
        vi.loyaltyRealLoadMore,
        vi.loyaltyRealEarnNote,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.loyaltyRealEarnNote, isNot(vi.loyaltyRealEarnNote));
    });
  });
}
