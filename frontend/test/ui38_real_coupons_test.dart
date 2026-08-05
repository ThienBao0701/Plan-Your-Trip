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

  Map<String, dynamic> couponJson({
    int id = 1,
    String code = 'SUMMER15',
    String discountType = 'PERCENTAGE',
    double discountValue = 15,
    String targetType = 'ALL',
    String effectiveStatus = 'AVAILABLE',
    double? minimumSpend = 100,
  }) =>
      {
        'id': id,
        'userId': 9,
        'coupon': {
          'id': 3,
          'code': code,
          'name': 'Summer sale',
          'description': 'Save on summer stays.',
          'discountType': discountType,
          'discountValue': discountValue,
          'maxDiscountAmount': 50,
          'minimumSpend': minimumSpend,
          'validFrom': '2030-01-01',
          'validUntil': '2031-01-01',
          'active': true,
          'totalUsageLimit': 1000,
          'usageLimitPerUser': 2,
          'currentUsageCount': 5,
          'targetType': targetType,
          'targetId': null,
          'placeType': null,
          'minimumStayNights': 2,
          'bookingDateFrom': null,
          'bookingDateTo': null,
          'customerSegment': 'ALL_USERS',
          'firstBookingOnly': false,
          'combinableWithPromotions': true,
          'combinableWithTravelCredits': false,
          'minimumTier': null,
        },
        'status': 'AVAILABLE',
        'effectiveStatus': effectiveStatus,
        'claimedAt': '2030-02-01T00:00:00Z',
        'usedAt': null,
        'expiresAt': '2031-01-01',
        'effectiveExpiresAt': '2031-01-01',
        'bookingId': null,
        'createdAt': '2030-02-01T00:00:00Z',
        'updatedAt': '2030-02-01T00:00:00Z',
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/coupons');
  bool detailPath(http.Request r) =>
      r.method == 'GET' && RegExp(r'/me/coupons/\d+$').hasMatch(r.url.path);
  bool claimPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/coupons/claim');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onDetail,
    Future<http.Response> Function(http.Request)? onClaim,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (claimPath(request)) {
          return (onClaim ??
              (_) async => jsonResponse(couponJson(), 201))(request);
        }
        if (detailPath(request)) {
          return (onDetail ??
              (_) async => jsonResponse(couponJson(), 200))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([couponJson()], 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('list parses nested definition + status; correct path', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) seen = r;
      });
      expect(await app.loadRealCoupons(), CouponOutcome.success);
      expect(seen!.url.path.endsWith('/me/coupons'), isTrue);
      final c = app.realCoupons.single;
      expect(c.id, 1);
      expect(c.statusView, CouponStatusView.available);
      expect(c.coupon.code, 'SUMMER15');
      expect(c.coupon.discountTypeView, CouponDiscountType.percentage);
      expect(c.coupon.discountValue, 15);
      expect(c.coupon.targetTypeView, CouponTargetType.all);
      expect(c.coupon.usageLimitPerUser, 2);
      expect(c.coupon.minimumSpend, 100);
    });

    test('mappers, unknown → null / unknown', () {
      expect(couponDiscountTypeFromCode('FIXED_AMOUNT'),
          CouponDiscountType.fixedAmount);
      expect(couponDiscountTypeFromCode('NOPE'), isNull);
      expect(couponTargetTypeFromCode('HOTEL'), CouponTargetType.hotel);
      expect(couponTargetTypeFromCode('NOPE'), isNull);
      expect(couponStatusViewFromCode('REVOKED'), CouponStatusView.revoked);
      expect(couponStatusViewFromCode('???'), CouponStatusView.unknown);
    });

    test('non-list body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('{}', 200)));
      expect(await app.loadRealCoupons(), CouponOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all coupon methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse([couponJson()], 200);
      }));
      expect(await app.loadRealCoupons(), CouponOutcome.demoUnavailable);
      expect(await app.loadRealCouponDetail(1), CouponOutcome.demoUnavailable);
      expect(await app.claimRealCoupon('X'), CouponOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realCoupons, isEmpty);
    });
  });

  // ── Load, cache, claim ───────────────────────────────────────────────────────

  group('Load and claim', () {
    test('cached list is not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) gets++;
      });
      await app.loadRealCoupons();
      await app.loadRealCoupons();
      expect(gets, 1);
      await app.loadRealCoupons(refresh: true);
      expect(gets, 2);
    });

    test('detail caches (2nd read no HTTP)', () async {
      var detailGets = 0;
      final app = routedApp(onRequest: (r) {
        if (detailPath(r)) detailGets++;
      });
      await app.loadRealCouponDetail(1);
      await app.loadRealCouponDetail(1);
      expect(detailGets, 1);
      expect(app.couponDetailCache.containsKey(1), isTrue);
    });

    test('claim POSTs the code and refreshes the list', () async {
      Map<String, dynamic>? body;
      var listGets = 0;
      final app = routedApp(
        onRequest: (r) {
          if (listPath(r)) listGets++;
        },
        onClaim: (r) async {
          body = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(couponJson(id: 7), 201);
        },
      );
      await app.loadRealCoupons();
      expect(listGets, 1);
      expect(await app.claimRealCoupon('  SUMMER15 '), CouponOutcome.success);
      expect(body!['code'], 'SUMMER15');
      expect(app.couponDetailCache.containsKey(7), isTrue);
      expect(listGets, 2);
    });

    test('empty code → validation, no HTTP', () async {
      var calls = 0;
      final app = routedApp(onRequest: (_) => calls++);
      expect(await app.claimRealCoupon('   '), CouponOutcome.validation);
      expect(calls, 0);
    });

    test('claim errors: 404 notFound, 400 validation, 409 conflict', () async {
      final nf = routedApp(
        onClaim: (_) async =>
            jsonResponse(errorBody(404, 'x', '/api/me/coupons/claim'), 404),
      );
      expect(await nf.claimRealCoupon('X'), CouponOutcome.notFound);

      final inv = routedApp(
        onClaim: (_) async =>
            jsonResponse(errorBody(400, 'x', '/api/me/coupons/claim'), 400),
      );
      expect(await inv.claimRealCoupon('X'), CouponOutcome.validation);

      final lim = routedApp(
        onClaim: (_) async =>
            jsonResponse(errorBody(409, 'x', '/api/me/coupons/claim'), 409),
      );
      expect(await lim.claimRealCoupon('X'), CouponOutcome.conflict);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/coupons'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealCoupons(), CouponOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('list 500 → serverError; network', () async {
      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/api/me/coupons'), 500),
      );
      expect(await se.loadRealCoupons(), CouponOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealCoupons(), CouponOutcome.network);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onList: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/api/me/coupons'), 500)
            : jsonResponse([couponJson()], 200),
      );
      await app.loadRealCoupons();
      expect(app.realCoupons, isNotEmpty);
      fail = true;
      expect(
          await app.loadRealCoupons(refresh: true), CouponOutcome.serverError);
      expect(app.realCoupons, isNotEmpty);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all coupon state', () async {
      final app = routedApp();
      await app.loadRealCoupons();
      await app.loadRealCouponDetail(1);
      expect(app.realCoupons, isNotEmpty);
      expect(app.couponDetailCache, isNotEmpty);
      await app.logout();
      expect(app.realCoupons, isEmpty);
      expect(app.couponDetailCache, isEmpty);
      expect(app.realCouponsLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('real coupons screen renders claim card + tiles', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const CouponsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('coupons-content')), findsOneWidget);
      expect(find.byKey(const Key('coupon-tile-1')), findsOneWidget);
      expect(find.text(AppLocalizationsEn().couponStatusAvailable),
          findsOneWidget);
    });

    testWidgets('tapping a tile opens the detail sheet', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const CouponsScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('coupon-tile-1')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('coupon-detail-content')), findsOneWidget);
    });

    testWidgets('empty list shows the empty state', (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const CouponsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('coupons-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/coupons'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const CouponsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('coupons-session-expired')), findsOneWidget);
    });

    testWidgets(
        'demo coupons screen is unchanged (no real content / zero HTTP)',
        (t) async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse([couponJson()], 200);
      }));
      await pumpSize(
        t,
        testApp(child: const CouponsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('coupons-content')), findsNothing);
      expect(calls, 0);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI38 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.couponsRealLoadingMessage,
        en.couponsRealErrorMessage,
        en.couponsRealClaimHelper,
        en.couponsRealClaimSuccess,
        en.couponsRealClaimError,
        en.couponsRealNotFound,
        en.couponsRealInvalidCode,
        en.couponsRealLimitReached,
        en.couponStatusAvailable,
        en.couponStatusUsed,
        en.couponStatusExpired,
        en.couponStatusRevoked,
        en.couponStatusUnknown,
      ];
      final viValues = <String>[
        vi.couponsRealLoadingMessage,
        vi.couponsRealErrorMessage,
        vi.couponsRealClaimHelper,
        vi.couponsRealClaimSuccess,
        vi.couponsRealClaimError,
        vi.couponsRealNotFound,
        vi.couponsRealInvalidCode,
        vi.couponsRealLimitReached,
        vi.couponStatusAvailable,
        vi.couponStatusUsed,
        vi.couponStatusExpired,
        vi.couponStatusRevoked,
        vi.couponStatusUnknown,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.couponsRealClaimHelper, isNot(vi.couponsRealClaimHelper));
    });

    test('parameterized keys resolve in both locales', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      expect(en.couponDetailMinimumSpend('100.00'), contains('100.00'));
      expect(vi.couponDetailMinimumSpend('100.00'), contains('100.00'));
      expect(en.couponDetailUsagePerUser(2), contains('2'));
      expect(vi.couponDetailUsagePerUser(2), contains('2'));
    });
  });
}
