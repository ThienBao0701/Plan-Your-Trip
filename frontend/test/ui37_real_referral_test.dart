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
    String code = 'PYT-REF-ABCD',
    int successful = 3,
    int pending = 1,
  }) =>
      {
        'code': code,
        'successfulReferrals': successful,
        'pendingReferrals': pending,
        'createdAt': '2030-01-01T00:00:00Z',
      };

  Map<String, dynamic> rewardJson({
    int id = 1,
    String role = 'INVITER',
    String status = 'REWARDED',
    int? bookingId = 42,
  }) =>
      {
        'id': id,
        'role': role,
        'campaignCode': 'WELCOME',
        'inviterUserId': 9,
        'inviteeUserId': 12,
        'status': status,
        'usedAt': '2030-02-01T00:00:00Z',
        'qualifiedAt': '2030-02-05T00:00:00Z',
        'qualifyingBookingId': bookingId,
        'rewardedAt': '2030-02-06T00:00:00Z',
        'createdAt': '2030-02-01T00:00:00Z',
      };

  bool historyPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/referral/history');
  bool summaryPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/referral');
  bool usePath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/referral/use');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onSummary,
    Future<http.Response> Function(http.Request)? onHistory,
    Future<http.Response> Function(http.Request)? onUse,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (usePath(request)) {
          return (onUse ??
              (_) async => jsonResponse(rewardJson(), 200))(request);
        }
        if (historyPath(request)) {
          return (onHistory ??
              (_) async => jsonResponse([rewardJson()], 200))(request);
        }
        if (summaryPath(request)) {
          return (onSummary ??
              (_) async => jsonResponse(summaryJson(), 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('summary + history parse; correct paths', () async {
      final seen = <String>{};
      final app = routedApp(onRequest: (r) => seen.add(r.url.path));
      expect(await app.loadRealReferral(), ReferralOutcome.success);
      expect(app.realReferralSummary!.code, 'PYT-REF-ABCD');
      expect(app.realReferralSummary!.successfulReferrals, 3);
      expect(app.realReferralSummary!.pendingReferrals, 1);
      final reward = app.realReferralHistory.single;
      expect(reward.roleView, ReferralRole.inviter);
      expect(reward.statusView, ReferralStatus.rewarded);
      expect(reward.qualifyingBookingId, 42);
      expect(seen.any((p) => p.endsWith('/me/referral/history')), isTrue);
      expect(seen.any((p) => p.endsWith('/me/referral')), isTrue);
    });

    test('role + status mappers, unknown → null', () {
      expect(referralRoleFromCode('INVITEE'), ReferralRole.invitee);
      expect(referralRoleFromCode('OTHER'), isNull);
      expect(referralStatusFromCode('USED'), ReferralStatus.used);
      expect(referralStatusFromCode('NOPE'), isNull);
    });

    test('non-object summary body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('null', 200)));
      expect(await app.loadRealReferral(), ReferralOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all referral methods return demoUnavailable with zero HTTP',
        () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(summaryJson(), 200);
      }));
      expect(await app.loadRealReferral(), ReferralOutcome.demoUnavailable);
      expect(
          await app.useRealReferralCode('X'), ReferralOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realReferralSummary, isNull);
    });
  });

  // ── Load, cache, use ─────────────────────────────────────────────────────────

  group('Load and use', () {
    test('cached load is not re-fetched unless refreshed', () async {
      var summaryGets = 0;
      final app = routedApp(onRequest: (r) {
        if (summaryPath(r)) summaryGets++;
      });
      await app.loadRealReferral();
      await app.loadRealReferral();
      expect(summaryGets, 1);
      await app.loadRealReferral(refresh: true);
      expect(summaryGets, 2);
    });

    test('use POSTs the code and refreshes the surface', () async {
      Map<String, dynamic>? sentBody;
      var summaryGets = 0;
      final app = routedApp(
        onRequest: (r) {
          if (summaryPath(r)) summaryGets++;
        },
        onUse: (r) async {
          sentBody = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(rewardJson(role: 'INVITEE', status: 'USED'), 200);
        },
      );
      await app.loadRealReferral();
      expect(summaryGets, 1);
      expect(await app.useRealReferralCode('  FRIEND-9 '),
          ReferralOutcome.success);
      expect(sentBody!['code'], 'FRIEND-9');
      expect(summaryGets, 2);
    });

    test('empty code → validation, no HTTP', () async {
      var calls = 0;
      final app = routedApp(onRequest: (_) => calls++);
      expect(await app.useRealReferralCode('   '), ReferralOutcome.validation);
      expect(calls, 0);
    });

    test('use errors: 404 notFound, 400 validation, 409 conflict', () async {
      final nf = routedApp(
        onUse: (_) async =>
            jsonResponse(errorBody(404, 'x', '/api/me/referral/use'), 404),
      );
      await nf.loadRealReferral();
      expect(await nf.useRealReferralCode('X'), ReferralOutcome.notFound);

      final own = routedApp(
        onUse: (_) async =>
            jsonResponse(errorBody(400, 'x', '/api/me/referral/use'), 400),
      );
      await own.loadRealReferral();
      expect(await own.useRealReferralCode('X'), ReferralOutcome.validation);

      final dup = routedApp(
        onUse: (_) async =>
            jsonResponse(errorBody(409, 'x', '/api/me/referral/use'), 409),
      );
      await dup.loadRealReferral();
      expect(await dup.useRealReferralCode('X'), ReferralOutcome.conflict);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onSummary: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/referral'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealReferral(), ReferralOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('history 500 → serverError; network', () async {
      final se = routedApp(
        onHistory: (_) async =>
            jsonResponse(errorBody(500, 'x', '/api/me/referral/history'), 500),
      );
      expect(await se.loadRealReferral(), ReferralOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealReferral(), ReferralOutcome.network);
    });

    test('a failed refresh preserves the previously loaded state', () async {
      var fail = false;
      final app = routedApp(
        onSummary: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/api/me/referral'), 500)
            : jsonResponse(summaryJson(), 200),
      );
      await app.loadRealReferral();
      expect(app.realReferralSummary, isNotNull);
      fail = true;
      expect(await app.loadRealReferral(refresh: true),
          ReferralOutcome.serverError);
      expect(app.realReferralSummary, isNotNull);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all referral state', () async {
      final app = routedApp();
      await app.loadRealReferral();
      expect(app.realReferralSummary, isNotNull);
      expect(app.realReferralHistory, isNotEmpty);
      await app.logout();
      expect(app.realReferralSummary, isNull);
      expect(app.realReferralHistory, isEmpty);
      expect(app.realReferralLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('real referral screen renders code, stats, history', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const ReferralScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('referral-content')), findsOneWidget);
      expect(find.byKey(const Key('referral-code')), findsOneWidget);
      expect(find.text('PYT-REF-ABCD'), findsOneWidget);
      expect(find.byKey(const Key('referral-copy')), findsOneWidget);
    });

    testWidgets('empty history shows the empty state', (t) async {
      final app = routedApp(
        onHistory: (_) async => jsonResponse(const [], 200),
      );
      await pumpSize(
        t,
        testApp(child: const ReferralScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('referral-history-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onSummary: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/referral'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const ReferralScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('referral-session-expired')), findsOneWidget);
    });

    testWidgets(
        'demo referral screen is unchanged (no real content / zero HTTP)',
        (t) async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(summaryJson(), 200);
      }));
      await pumpSize(
        t,
        testApp(child: const ReferralScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('referral-content')), findsNothing);
      expect(calls, 0);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI37 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.referralRealLoadingMessage,
        en.referralRealErrorMessage,
        en.referralRealUseHelper,
        en.referralRealUseSuccess,
        en.referralRealUseError,
        en.referralRealAlreadyUsed,
        en.referralRealCodeNotFound,
        en.referralRealNoHistory,
      ];
      final viValues = <String>[
        vi.referralRealLoadingMessage,
        vi.referralRealErrorMessage,
        vi.referralRealUseHelper,
        vi.referralRealUseSuccess,
        vi.referralRealUseError,
        vi.referralRealAlreadyUsed,
        vi.referralRealCodeNotFound,
        vi.referralRealNoHistory,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.referralRealNoHistory, isNot(vi.referralRealNoHistory));
    });
  });
}
