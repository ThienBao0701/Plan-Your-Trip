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

  Map<String, dynamic> summaryJson({
    int id = 1,
    String maskedCode = 'PYT-GC-****-****-1234',
    String productName = 'Holiday Card',
    double originalAmount = 100.0,
    double currentBalance = 60.0,
    String currency = 'USD',
    String status = 'ACTIVE',
    String effectiveStatus = 'ACTIVE',
  }) =>
      {
        'id': id,
        'maskedCode': maskedCode,
        'productName': productName,
        'originalAmount': originalAmount,
        'currentBalance': currentBalance,
        'currency': currency,
        'status': status,
        'effectiveStatus': effectiveStatus,
        'issuedAt': '2030-01-01T00:00:00Z',
        'expiresAt': '2031-01-01T00:00:00Z',
      };

  Map<String, dynamic> pageJson(
    List<Map<String, dynamic>> content, {
    int page = 0,
    int size = 20,
    int totalElements = 1,
    int totalPages = 1,
  }) =>
      {
        'content': content,
        'page': page,
        'size': size,
        'totalElements': totalElements,
        'totalPages': totalPages,
      };

  Map<String, dynamic> detailJson({
    int id = 1,
    String status = 'ISSUED',
    String effectiveStatus = 'ISSUED',
    double currentBalance = 100.0,
  }) =>
      {
        'id': id,
        'maskedCode': 'PYT-GC-****-****-1234',
        'fullCode': 'PYT-GC-SECRET-1234',
        'product': {
          'id': 3,
          'productCode': 'HOL',
          'name': 'Holiday Card',
          'currency': 'USD'
        },
        'purchaser': {'id': 9, 'fullName': 'Bao'},
        'recipient': {'id': 10, 'fullName': 'Mai'},
        'recipientEmail': 'mai@example.com',
        'originalAmount': 100.0,
        'currentBalance': currentBalance,
        'currency': 'USD',
        'status': status,
        'effectiveStatus': effectiveStatus,
        'personalMessage': 'Enjoy!',
        'issuedAt': '2030-01-01T00:00:00Z',
        'activatedAt': null,
        'expiresAt': '2031-01-01T00:00:00Z',
      };

  Map<String, dynamic> txJson({
    int id = 1,
    String type = 'ISSUE',
    double amount = 100.0,
    double before = 0.0,
    double after = 100.0,
  }) =>
      {
        'id': id,
        'giftCardId': 1,
        'transactionType': type,
        'amount': amount,
        'balanceBefore': before,
        'balanceAfter': after,
        'description': 'Issued',
        'createdAt': '2030-01-01T00:00:00Z',
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/gift-cards');
  bool txPath(http.Request r) =>
      r.method == 'GET' &&
      RegExp(r'/me/gift-cards/\d+/transactions$').hasMatch(r.url.path);
  bool detailPath(http.Request r) =>
      r.method == 'GET' && RegExp(r'/me/gift-cards/\d+$').hasMatch(r.url.path);
  bool claimPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/gift-cards/claim');
  bool activatePath(http.Request r) =>
      r.method == 'POST' &&
      RegExp(r'/me/gift-cards/\d+/activate$').hasMatch(r.url.path);

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onDetail,
    Future<http.Response> Function(http.Request)? onTransactions,
    Future<http.Response> Function(http.Request)? onClaim,
    Future<http.Response> Function(http.Request)? onActivate,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (claimPath(request)) {
          return (onClaim ??
              (_) async => jsonResponse(detailJson(), 200))(request);
        }
        if (activatePath(request)) {
          return (onActivate ??
              (_) async => jsonResponse(
                  detailJson(status: 'ACTIVE', effectiveStatus: 'ACTIVE'),
                  200))(request);
        }
        if (txPath(request)) {
          return (onTransactions ??
              (_) async => jsonResponse(pageJson([txJson()]), 200))(request);
        }
        if (detailPath(request)) {
          return (onDetail ??
              (_) async => jsonResponse(detailJson(), 200))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async =>
                  jsonResponse(pageJson([summaryJson()]), 200))(request);
        }
        return jsonResponse(pageJson(const []), 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('getMyGiftCards GETs /me/gift-cards with page/size and unwraps page',
        () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) seen = r;
      });
      expect(await app.loadRealGiftCards(), GiftCardActionOutcome.success);
      expect(seen!.url.path.endsWith('/me/gift-cards'), isTrue);
      expect(seen!.url.queryParameters['page'], '0');
      expect(seen!.url.queryParameters['size'], '20');
      expect(app.realGiftCards.length, 1);
      expect(app.realGiftCards.first.id, 1);
      expect(app.realGiftCards.first.currentBalance, 60.0);
      expect(app.realGiftCards.first.statusView, GiftCardStatusView.active);
    });

    test('RealGiftCardDetail.fromJson flattens product/parties, drops fullCode',
        () async {
      final app = routedApp();
      await app.loadRealGiftCardDetail(1);
      final d = app.giftCardDetailCache[1]!;
      expect(d.productName, 'Holiday Card');
      expect(d.purchaserName, 'Bao');
      expect(d.recipientName, 'Mai');
      expect(d.recipientEmail, 'mai@example.com');
      expect(d.personalMessage, 'Enjoy!');
      expect(d.statusView, GiftCardStatusView.issued);
      // The raw fullCode is never exposed on the typed model.
      expect(d.maskedCode, 'PYT-GC-****-****-1234');
    });

    test('transaction parsing + status view fallback', () async {
      final app = routedApp(
        onTransactions: (_) async => jsonResponse(
            pageJson([
              txJson(type: 'REDEMPTION', amount: 40, before: 100, after: 60)
            ]),
            200),
      );
      await app.loadRealGiftCardTransactions(1);
      final tx = app.giftCardTransactionsCache[1]!.first;
      expect(tx.transactionType, 'REDEMPTION');
      expect(tx.increasesBalance, isFalse);
      expect(
          giftCardStatusViewFromCode('WHATEVER'), GiftCardStatusView.unknown);
      expect(giftCardStatusViewFromCode('FULLY_REDEEMED'),
          GiftCardStatusView.fullyRedeemed);
    });

    test('non-object list body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('[]', 200)));
      expect(await app.loadRealGiftCards(), GiftCardActionOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all gift-card methods return demoUnavailable with zero HTTP',
        () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(pageJson(const []), 200);
      }));
      expect(
          await app.loadRealGiftCards(), GiftCardActionOutcome.demoUnavailable);
      expect(await app.loadMoreRealGiftCards(),
          GiftCardActionOutcome.demoUnavailable);
      expect(await app.loadRealGiftCardDetail(1),
          GiftCardActionOutcome.demoUnavailable);
      expect(await app.loadRealGiftCardTransactions(1),
          GiftCardActionOutcome.demoUnavailable);
      expect(await app.claimRealGiftCard('X'),
          GiftCardActionOutcome.demoUnavailable);
      expect(await app.activateRealGiftCard(1),
          GiftCardActionOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realGiftCards, isEmpty);
    });
  });

  // ── Load, pagination, actions ────────────────────────────────────────────────

  group('Load and pagination', () {
    test('load stores first page; load-more appends the next page', () async {
      final app = routedApp(
        onList: (r) async {
          final page = r.url.queryParameters['page'];
          if (page == '1') {
            return jsonResponse(
                pageJson([summaryJson(id: 2)],
                    page: 1, totalElements: 2, totalPages: 2),
                200);
          }
          return jsonResponse(
              pageJson([summaryJson(id: 1)],
                  page: 0, totalElements: 2, totalPages: 2),
              200);
        },
      );
      await app.loadRealGiftCards();
      expect(app.realGiftCards.map((c) => c.id), [1]);
      expect(app.realGiftCardsHasMore, isTrue);
      expect(await app.loadMoreRealGiftCards(), GiftCardActionOutcome.success);
      expect(app.realGiftCards.map((c) => c.id), [1, 2]);
      expect(app.realGiftCardsHasMore, isFalse);
    });

    test('cached list is not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) gets++;
      });
      await app.loadRealGiftCards();
      await app.loadRealGiftCards();
      expect(gets, 1);
      await app.loadRealGiftCards(refresh: true);
      expect(gets, 2);
    });

    test('claim POSTs the code and refreshes the list', () async {
      Map<String, dynamic>? claimBody;
      var listGets = 0;
      final app = routedApp(
        onRequest: (r) {
          if (listPath(r)) listGets++;
        },
        onClaim: (r) async {
          claimBody = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(detailJson(id: 7), 200);
        },
      );
      await app.loadRealGiftCards();
      expect(listGets, 1);
      expect(await app.claimRealGiftCard('  ABC-123 '),
          GiftCardActionOutcome.success);
      expect(claimBody!['code'], 'ABC-123');
      expect(app.giftCardDetailCache.containsKey(7), isTrue);
      // Success triggers a list refresh.
      expect(listGets, 2);
    });

    test('empty claim code → validation, no HTTP', () async {
      var calls = 0;
      final app = routedApp(onRequest: (_) => calls++);
      expect(
          await app.claimRealGiftCard('   '), GiftCardActionOutcome.validation);
      expect(calls, 0);
    });

    test('activate POSTs and updates cached detail', () async {
      final app = routedApp(
        onActivate: (_) async => jsonResponse(
            detailJson(id: 1, status: 'ACTIVE', effectiveStatus: 'ACTIVE'),
            200),
      );
      await app.loadRealGiftCards();
      expect(await app.activateRealGiftCard(1), GiftCardActionOutcome.success);
      expect(app.giftCardDetailCache[1]!.statusView, GiftCardStatusView.active);
    });

    test('a second concurrent claim returns busy', () async {
      final gate = Completer<http.Response>();
      final app = routedApp(onClaim: (_) => gate.future);
      final first = app.claimRealGiftCard('ABC');
      final second = await app.claimRealGiftCard('DEF');
      expect(second, GiftCardActionOutcome.busy);
      gate.complete(jsonResponse(detailJson(id: 5), 200));
      expect(await first, GiftCardActionOutcome.success);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/gift-cards'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(
          await app.loadRealGiftCards(), GiftCardActionOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('claim 404 → notFound; 409 → conflict; 400 → validation', () async {
      final nf = routedApp(
        onClaim: (_) async =>
            jsonResponse(errorBody(404, 'x', '/api/me/gift-cards/claim'), 404),
      );
      expect(await nf.claimRealGiftCard('X'), GiftCardActionOutcome.notFound);

      final cf = routedApp(
        onClaim: (_) async =>
            jsonResponse(errorBody(409, 'x', '/api/me/gift-cards/claim'), 409),
      );
      expect(await cf.claimRealGiftCard('X'), GiftCardActionOutcome.conflict);

      final val = routedApp(
        onClaim: (_) async =>
            jsonResponse(errorBody(400, 'x', '/api/me/gift-cards/claim'), 400),
      );
      expect(
          await val.claimRealGiftCard('X'), GiftCardActionOutcome.validation);
    });

    test('list 500 → serverError; network', () async {
      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/api/me/gift-cards'), 500),
      );
      expect(await se.loadRealGiftCards(), GiftCardActionOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealGiftCards(), GiftCardActionOutcome.network);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onList: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/api/me/gift-cards'), 500)
            : jsonResponse(pageJson([summaryJson()]), 200),
      );
      await app.loadRealGiftCards();
      expect(app.realGiftCards, isNotEmpty);
      fail = true;
      expect(await app.loadRealGiftCards(refresh: true),
          GiftCardActionOutcome.serverError);
      expect(app.realGiftCards, isNotEmpty);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all gift-card state', () async {
      final app = routedApp();
      await app.loadRealGiftCards();
      await app.loadRealGiftCardDetail(1);
      expect(app.realGiftCards, isNotEmpty);
      expect(app.giftCardDetailCache, isNotEmpty);
      await app.logout();
      expect(app.realGiftCards, isEmpty);
      expect(app.realGiftCardsLoaded, isFalse);
      expect(app.giftCardDetailCache, isEmpty);
      expect(app.giftCardActionInFlight, isEmpty);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('real gift cards screen renders tiles and claim card',
        (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const GiftCardsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('gift-cards-content')), findsOneWidget);
      expect(find.byKey(const Key('gift-card-tile-1')), findsOneWidget);
      expect(find.byKey(const Key('gift-cards-claim-submit')), findsOneWidget);
    });

    testWidgets('empty list shows the real empty state', (t) async {
      final app =
          routedApp(onList: (_) async => jsonResponse(pageJson(const []), 200));
      await pumpSize(
        t,
        testApp(child: const GiftCardsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('gift-cards-empty')), findsOneWidget);
    });

    testWidgets('tapping a tile opens the detail sheet with an activate action',
        (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse(
            pageJson(
                [summaryJson(status: 'ISSUED', effectiveStatus: 'ISSUED')]),
            200),
      );
      await pumpSize(
        t,
        testApp(child: const GiftCardsScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('gift-card-tile-1')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('gift-card-detail-content')), findsOneWidget);
      expect(find.byKey(const Key('gift-card-activate')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/gift-cards'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const GiftCardsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(
          find.byKey(const Key('gift-cards-session-expired')), findsOneWidget);
    });

    testWidgets('demo gift cards screen is unchanged (demo claim card shows)',
        (t) async {
      final app = demoApp(MockClient((_) async {
        return jsonResponse(pageJson(const []), 200);
      }));
      await pumpSize(
        t,
        testApp(child: const GiftCardsScreen(), app: app),
        const Size(1200, 2400),
      );
      // Demo path renders the demo claim card, not the real content key.
      expect(find.byKey(const Key('gift-cards-content')), findsNothing);
      expect(
          find.text(AppLocalizationsEn().giftCardClaimTitle), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI33 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.giftCardsRealClaimTitle,
        en.giftCardsRealClaimHelper,
        en.giftCardsRealClaimSuccess,
        en.giftCardsRealLoadingMessage,
        en.giftCardsRealErrorMessage,
        en.giftCardsRealEmptyMessage,
        en.giftCardsRealLoadMore,
        en.giftCardsRealActivateAction,
        en.giftCardsRealActivateSuccess,
        en.giftCardsRealActionError,
        en.giftCardsRealNotFound,
        en.giftCardsRealConflict,
        en.giftCardsRealNetwork,
        en.giftCardsRealValidation,
        en.giftCardStatusUnknown,
      ];
      final viValues = <String>[
        vi.giftCardsRealClaimTitle,
        vi.giftCardsRealClaimHelper,
        vi.giftCardsRealClaimSuccess,
        vi.giftCardsRealLoadingMessage,
        vi.giftCardsRealErrorMessage,
        vi.giftCardsRealEmptyMessage,
        vi.giftCardsRealLoadMore,
        vi.giftCardsRealActivateAction,
        vi.giftCardsRealActivateSuccess,
        vi.giftCardsRealActionError,
        vi.giftCardsRealNotFound,
        vi.giftCardsRealConflict,
        vi.giftCardsRealNetwork,
        vi.giftCardsRealValidation,
        vi.giftCardStatusUnknown,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.giftCardsRealClaimTitle, isNot(vi.giftCardsRealClaimTitle));
    });

    test('balance semantic placeholder resolves in both locales', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      expect(en.giftCardsRealBalanceSemantic('60.00 USD'), contains('60.00'));
      expect(vi.giftCardsRealBalanceSemantic('60.00 USD'), contains('60.00'));
    });
  });
}
