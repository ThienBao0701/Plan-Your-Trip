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

  Map<String, dynamic> membershipJson({
    String currentTier = 'SILVER',
    String effectiveTier = 'SILVER',
    bool active = true,
    bool expired = false,
  }) =>
      {
        'id': 3,
        'userId': 9,
        'currentTier': currentTier,
        'effectiveTier': effectiveTier,
        'qualifiedAt': '2030-01-01T00:00:00Z',
        'validFrom': '2030-01-01T00:00:00Z',
        'validUntil': '2031-01-01T00:00:00Z',
        'manuallyAssigned': false,
        'active': active,
        'expired': expired,
        'createdAt': '2030-01-01T00:00:00Z',
        'updatedAt': '2030-01-01T00:00:00Z',
      };

  Map<String, dynamic> progressJson({
    String currentTier = 'SILVER',
    String effectiveTier = 'SILVER',
    String? nextTier = 'GOLD',
    int? pointsRequired = 500,
    int? bookingsRequired = 2,
    double percentage = 40.0,
  }) =>
      {
        'currentTier': currentTier,
        'effectiveTier': effectiveTier,
        'lifetimePointsEarned': 1500,
        'completedBookings': 4,
        'nextTier': nextTier,
        'pointsRequiredForNextTier': pointsRequired,
        'bookingsRequiredForNextTier': bookingsRequired,
        'progressPercentage': percentage,
        'validUntil': '2031-01-01T00:00:00Z',
        'expired': false,
        'manuallyAssigned': false,
      };

  Map<String, dynamic> benefitJson({
    int id = 1,
    String type = 'FREE_BREAKFAST',
    String name = 'Free breakfast',
  }) =>
      {
        'id': id,
        'tier': 'SILVER',
        'benefitType': type,
        'name': name,
        'description': 'Complimentary breakfast for members.',
        'numericValue': null,
        'textValue': 'Daily',
        'active': true,
        'sortOrder': 0,
      };

  Map<String, dynamic> historyJson({
    int id = 1,
    String newTier = 'SILVER',
    String changeType = 'INITIAL_ENROLLMENT',
  }) =>
      {
        'id': id,
        'membershipId': 3,
        'previousTier': null,
        'newTier': newTier,
        'changeType': changeType,
        'reason': 'Initial enrollment',
        'effectiveAt': '2030-01-01T00:00:00Z',
        'expiresAt': '2031-01-01T00:00:00Z',
        'referenceType': 'LOYALTY_ACCOUNT',
        'referenceId': 5,
        'createdAt': '2030-01-01T00:00:00Z',
      };

  bool progressPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/membership/progress');
  bool benefitsPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/membership/benefits');
  bool historyPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/membership/history');
  bool membershipGetPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/membership');
  bool enrollPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/membership/enroll');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onMembership,
    Future<http.Response> Function(http.Request)? onProgress,
    Future<http.Response> Function(http.Request)? onBenefits,
    Future<http.Response> Function(http.Request)? onHistory,
    Future<http.Response> Function(http.Request)? onEnroll,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (enrollPath(request)) {
          return (onEnroll ??
              (_) async => jsonResponse(membershipJson(), 201))(request);
        }
        if (progressPath(request)) {
          return (onProgress ??
              (_) async => jsonResponse(progressJson(), 200))(request);
        }
        if (benefitsPath(request)) {
          return (onBenefits ??
              (_) async => jsonResponse([benefitJson()], 200))(request);
        }
        if (historyPath(request)) {
          return (onHistory ??
              (_) async => jsonResponse([historyJson()], 200))(request);
        }
        if (membershipGetPath(request)) {
          return (onMembership ??
              (_) async => jsonResponse(membershipJson(), 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('membership + progress + benefits + history parse; correct paths',
        () async {
      final seen = <String>{};
      final app = routedApp(onRequest: (r) => seen.add(r.url.path));
      expect(await app.loadRealMembership(), MembershipOutcome.success);
      expect(app.realMembershipEnrolled, isTrue);
      expect(app.realMembership!.effectiveTierView, MembershipTier.silver);
      expect(app.realMembershipProgress!.nextTierView, MembershipTier.gold);
      expect(app.realMembershipProgress!.clampedProgress, 40);
      expect(app.realMembershipBenefits.single.benefitTypeView,
          MembershipBenefitType.freeBreakfast);
      expect(
          app.realMembershipHistory.single.newTierView, MembershipTier.silver);
      expect(seen.any((p) => p.endsWith('/me/membership/progress')), isTrue);
      expect(seen.any((p) => p.endsWith('/me/membership/benefits')), isTrue);
      expect(seen.any((p) => p.endsWith('/me/membership/history')), isTrue);
      expect(seen.any((p) => p.endsWith('/me/membership')), isTrue);
    });

    test('tier + benefit mappers, unknown → null', () {
      expect(membershipTierFromCode('DIAMOND'), MembershipTier.diamond);
      expect(membershipTierFromCode('MYTHIC'), isNull);
      expect(membershipBenefitTypeFromCode('ROOM_UPGRADE'),
          MembershipBenefitType.roomUpgrade);
      expect(membershipBenefitTypeFromCode('NOPE'), isNull);
    });

    test('non-object progress body → serverError (malformed)', () async {
      final app = realApp(MockClient((r) async {
        if (progressPath(r)) return http.Response('null', 200);
        return jsonResponse(const <String, dynamic>{}, 200);
      }));
      expect(await app.loadRealMembership(), MembershipOutcome.serverError);
    });
  });

  // ── Not-enrolled (404 tolerated) ─────────────────────────────────────────────

  group('Not enrolled', () {
    test('GET membership 404 is tolerated as "not enrolled", not an error',
        () async {
      final app = routedApp(
        onMembership: (_) async =>
            jsonResponse(errorBody(404, 'x', '/api/me/membership'), 404),
      );
      expect(await app.loadRealMembership(), MembershipOutcome.success);
      expect(app.realMembershipEnrolled, isFalse);
      expect(app.realMembership, isNull);
      // Progress preview still loaded.
      expect(app.realMembershipProgress, isNotNull);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all membership methods return demoUnavailable with zero HTTP',
        () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(membershipJson(), 200);
      }));
      expect(await app.loadRealMembership(), MembershipOutcome.demoUnavailable);
      expect(
          await app.enrollRealMembership(), MembershipOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realMembershipProgress, isNull);
    });
  });

  // ── Load, cache, enroll ──────────────────────────────────────────────────────

  group('Load and enroll', () {
    test('cached load is not re-fetched unless refreshed', () async {
      var progressGets = 0;
      final app = routedApp(onRequest: (r) {
        if (progressPath(r)) progressGets++;
      });
      await app.loadRealMembership();
      await app.loadRealMembership();
      expect(progressGets, 1);
      await app.loadRealMembership(refresh: true);
      expect(progressGets, 2);
    });

    test('enroll POSTs and reloads the surface', () async {
      var enrollPosts = 0;
      final app = routedApp(
        onMembership: (r) async {
          // First load: not enrolled; after enroll: enrolled.
          return enrollPosts == 0
              ? jsonResponse(errorBody(404, 'x', '/api/me/membership'), 404)
              : jsonResponse(membershipJson(), 200);
        },
        onEnroll: (_) async {
          enrollPosts++;
          return jsonResponse(membershipJson(), 201);
        },
      );
      await app.loadRealMembership();
      expect(app.realMembershipEnrolled, isFalse);
      expect(await app.enrollRealMembership(), MembershipOutcome.success);
      expect(enrollPosts, 1);
      expect(app.realMembershipEnrolled, isTrue);
    });

    test('enroll 400 (no loyalty account) → validation', () async {
      final app = routedApp(
        onMembership: (_) async =>
            jsonResponse(errorBody(404, 'x', '/api/me/membership'), 404),
        onEnroll: (_) async =>
            jsonResponse(errorBody(400, 'x', '/api/me/membership/enroll'), 400),
      );
      await app.loadRealMembership();
      expect(await app.enrollRealMembership(), MembershipOutcome.validation);
      expect(app.realMembershipEnrolled, isFalse);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onProgress: (_) async => jsonResponse(
            errorBody(401, 'x', '/api/me/membership/progress'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealMembership(), MembershipOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('benefits 500 → serverError; network', () async {
      final se = routedApp(
        onBenefits: (_) async => jsonResponse(
            errorBody(500, 'x', '/api/me/membership/benefits'), 500),
      );
      expect(await se.loadRealMembership(), MembershipOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealMembership(), MembershipOutcome.network);
    });

    test('a failed refresh preserves the previously loaded state', () async {
      var fail = false;
      final app = routedApp(
        onProgress: (_) async => fail
            ? jsonResponse(
                errorBody(500, 'x', '/api/me/membership/progress'), 500)
            : jsonResponse(progressJson(), 200),
      );
      await app.loadRealMembership();
      expect(app.realMembershipProgress, isNotNull);
      fail = true;
      expect(await app.loadRealMembership(refresh: true),
          MembershipOutcome.serverError);
      expect(app.realMembershipProgress, isNotNull);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all membership state', () async {
      final app = routedApp();
      await app.loadRealMembership();
      expect(app.realMembershipProgress, isNotNull);
      expect(app.realMembershipBenefits, isNotEmpty);
      await app.logout();
      expect(app.realMembership, isNull);
      expect(app.realMembershipProgress, isNull);
      expect(app.realMembershipBenefits, isEmpty);
      expect(app.realMembershipHistory, isEmpty);
      expect(app.realMembershipLoaded, isFalse);
      expect(app.realMembershipEnrolled, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('real membership screen renders tier, progress, benefits',
        (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const MembershipScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('membership-content')), findsOneWidget);
      expect(find.byKey(const Key('membership-progress')), findsOneWidget);
      expect(
          find.text(AppLocalizationsEn().membershipTierSilver), findsWidgets);
      expect(find.byKey(const Key('membership-enroll')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onProgress: (_) async => jsonResponse(
            errorBody(401, 'x', '/api/me/membership/progress'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const MembershipScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(
          find.byKey(const Key('membership-session-expired')), findsOneWidget);
    });

    testWidgets('not-enrolled preview shows an enabled enroll button',
        (t) async {
      final app = routedApp(
        onMembership: (_) async =>
            jsonResponse(errorBody(404, 'x', '/api/me/membership'), 404),
      );
      await pumpSize(
        t,
        testApp(child: const MembershipScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('membership-content')), findsOneWidget);
      expect(find.text(AppLocalizationsEn().membershipRealEnrollAction),
          findsOneWidget);
    });

    testWidgets(
        'demo membership screen is unchanged (no real content / zero HTTP)',
        (t) async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(membershipJson(), 200);
      }));
      await pumpSize(
        t,
        testApp(child: const MembershipScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('membership-content')), findsNothing);
      expect(calls, 0);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI36 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.membershipRealLoadingMessage,
        en.membershipRealErrorMessage,
        en.membershipRealActiveMessage,
        en.membershipRealPreviewMessage,
        en.membershipRealEnrollAction,
        en.membershipRealEnrolledAction,
        en.membershipRealEnrollSemantic,
        en.membershipRealEnrollSuccess,
        en.membershipRealEnrollError,
        en.membershipRealEnrollNeedsLoyalty,
        en.membershipRealNoBenefits,
      ];
      final viValues = <String>[
        vi.membershipRealLoadingMessage,
        vi.membershipRealErrorMessage,
        vi.membershipRealActiveMessage,
        vi.membershipRealPreviewMessage,
        vi.membershipRealEnrollAction,
        vi.membershipRealEnrolledAction,
        vi.membershipRealEnrollSemantic,
        vi.membershipRealEnrollSuccess,
        vi.membershipRealEnrollError,
        vi.membershipRealEnrollNeedsLoyalty,
        vi.membershipRealNoBenefits,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(
          en.membershipRealEnrollAction, isNot(vi.membershipRealEnrollAction));
    });

    test('parameterized keys resolve in both locales', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      expect(en.membershipRealPointsToNext(500), contains('500'));
      expect(vi.membershipRealPointsToNext(500), contains('500'));
      expect(en.membershipRealBookingsToNext(2), contains('2'));
      expect(vi.membershipRealBookingsToNext(2), contains('2'));
    });
  });
}
