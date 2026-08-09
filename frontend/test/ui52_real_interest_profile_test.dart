import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/profile/real_interest_profile_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:planyourtrip_frontend/shared/enum_labels.dart';
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

  Map<String, dynamic> profileJson({
    int? userId = 1,
    List<String> travelStyles = const ['SOLO', 'COUPLE'],
    List<String> weatherTypes = const ['SUNNY'],
    String? budget = 'MEDIUM',
    String? crowd = 'LOW',
    String? accessibility = 'HIGH',
    List<String> provinces = const ['Da Nang', 'Hue'],
    List<String> categories = const ['Beach'],
    List<String> tags = const ['relaxing'],
    int signalCount = 12,
    String? lastRecalculatedAt = '2030-05-01T10:00:00Z',
  }) =>
      {
        'userId': userId,
        'preferredTravelStyles': travelStyles,
        'preferredWeatherTypes': weatherTypes,
        'preferredBudgetLevel': budget,
        'preferredCrowdLevel': crowd,
        'preferredAccessibilityLevel': accessibility,
        'favoriteProvinces': provinces,
        'favoriteCategories': categories,
        'favoriteTags': tags,
        'signalCount': signalCount,
        'lastRecalculatedAt': lastRecalculatedAt,
      };

  Map<String, dynamic> emptyProfileJson() => {
        'userId': 1,
        'preferredTravelStyles': const [],
        'preferredWeatherTypes': const [],
        'preferredBudgetLevel': null,
        'preferredCrowdLevel': null,
        'preferredAccessibilityLevel': null,
        'favoriteProvinces': const [],
        'favoriteCategories': const [],
        'favoriteTags': const [],
        'signalCount': 0,
        'lastRecalculatedAt': null,
      };

  bool getPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/interests');
  bool recalcPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/interests/recalculate');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onGet,
    Future<http.Response> Function(http.Request)? onRecalc,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (recalcPath(request)) {
          return (onRecalc ??
              (_) async => jsonResponse(profileJson(), 200))(request);
        }
        if (getPath(request)) {
          return (onGet ??
              (_) async => jsonResponse(profileJson(), 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('map parses; correct path + fields', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (getPath(r)) seen = r;
      });
      expect(
          await app.loadRealInterestProfile(), InterestProfileOutcome.success);
      expect(seen!.url.path.endsWith('/me/interests'), isTrue);
      final p = app.realInterestProfile!;
      expect(p.userId, 1);
      expect(p.preferredTravelStyles, ['SOLO', 'COUPLE']);
      expect(p.preferredWeatherTypes, ['SUNNY']);
      expect(p.preferredBudgetLevel, 'MEDIUM');
      expect(p.preferredCrowdLevel, 'LOW');
      expect(p.preferredAccessibilityLevel, 'HIGH');
      expect(p.favoriteProvinces, ['Da Nang', 'Hue']);
      expect(p.favoriteCategories, ['Beach']);
      expect(p.favoriteTags, ['relaxing']);
      expect(p.signalCount, 12);
      expect(p.lastRecalculatedAt, isNotNull);
      expect(p.isEmpty, isFalse);
    });

    test('empty snapshot → isEmpty true, null enums, empty lists', () {
      final p = RealInterestProfile.fromJson(emptyProfileJson());
      expect(p.isEmpty, isTrue);
      expect(p.preferredBudgetLevel, isNull);
      expect(p.preferredCrowdLevel, isNull);
      expect(p.preferredAccessibilityLevel, isNull);
      expect(p.preferredTravelStyles, isEmpty);
      expect(p.favoriteProvinces, isEmpty);
      expect(p.signalCount, 0);
      expect(p.lastRecalculatedAt, isNull);
    });

    test('missing/odd fields degrade safely (never crash)', () {
      final p = RealInterestProfile.fromJson(const {
        'preferredTravelStyles': 'not-a-list',
        'signalCount': null,
      });
      expect(p.userId, isNull);
      expect(p.preferredTravelStyles, isEmpty);
      expect(p.signalCount, 0);
      expect(p.isEmpty, isTrue);
    });

    test('unknown enum token passes through raw → humanized label fallback',
        () {
      final p = RealInterestProfile.fromJson(
          profileJson(travelStyles: const ['MOON_VOYAGE'], budget: 'ULTRA'));
      // Raw token preserved on the model…
      expect(p.preferredTravelStyles, ['MOON_VOYAGE']);
      expect(p.preferredBudgetLevel, 'ULTRA');
      // …and the shared labeller humanizes it rather than throwing.
      expect(humanizeEnumToken('MOON_VOYAGE'), 'Moon Voyage');
    });

    test('non-map body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('[]', 200)));
      expect(await app.loadRealInterestProfile(),
          InterestProfileOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('loadRealInterestProfile → demoUnavailable, zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(profileJson(), 200);
      }));
      expect(await app.loadRealInterestProfile(),
          InterestProfileOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realInterestProfile, isNull);
    });

    test('recalculateRealInterestProfile → demoUnavailable, zero HTTP',
        () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(profileJson(), 200);
      }));
      expect(await app.recalculateRealInterestProfile(),
          InterestProfileOutcome.demoUnavailable);
      expect(calls, 0);
    });
  });

  // ── Load / cache / refresh ────────────────────────────────────────────────────

  group('Load / cache / refresh', () {
    test('cached profile not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (getPath(r)) gets++;
      });
      await app.loadRealInterestProfile();
      await app.loadRealInterestProfile();
      expect(gets, 1);
      await app.loadRealInterestProfile(refresh: true);
      expect(gets, 2);
    });

    test('a failed refresh preserves the previously loaded profile', () async {
      var fail = false;
      final app = routedApp(
        onGet: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/me/interests'), 500)
            : jsonResponse(profileJson(), 200),
      );
      await app.loadRealInterestProfile();
      expect(app.realInterestProfile, isNotNull);
      final before = app.realInterestProfile;
      fail = true;
      expect(await app.loadRealInterestProfile(refresh: true),
          InterestProfileOutcome.serverError);
      expect(app.realInterestProfile, same(before));
    });
  });

  // ── Recalculate ──────────────────────────────────────────────────────────────

  group('Recalculate', () {
    test('POST recalculate has no body and replaces the profile', () async {
      http.Request? seen;
      final app = routedApp(
        onGet: (_) async => jsonResponse(profileJson(signalCount: 1), 200),
        onRecalc: (r) async {
          seen = r;
          return jsonResponse(profileJson(signalCount: 99), 200);
        },
        onRequest: (r) {},
      );
      await app.loadRealInterestProfile();
      expect(app.realInterestProfile!.signalCount, 1);
      expect(await app.recalculateRealInterestProfile(),
          InterestProfileOutcome.success);
      expect(seen!.method, 'POST');
      expect(seen!.body, isEmpty);
      expect(app.realInterestProfile!.signalCount, 99);
      expect(app.realInterestLoaded, isTrue);
    });

    test('201 Created is accepted', () async {
      final app = routedApp(
        onRecalc: (_) async => jsonResponse(profileJson(), 201),
      );
      expect(await app.recalculateRealInterestProfile(),
          InterestProfileOutcome.success);
      expect(app.realInterestProfile, isNotNull);
    });

    test('a failed recalculate preserves the previous profile', () async {
      final app = routedApp(
        onGet: (_) async => jsonResponse(profileJson(signalCount: 7), 200),
        onRecalc: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/interests/recalculate'), 500),
      );
      await app.loadRealInterestProfile();
      final before = app.realInterestProfile;
      expect(await app.recalculateRealInterestProfile(),
          InterestProfileOutcome.serverError);
      expect(app.realInterestProfile, same(before));
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onGet: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/interests'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealInterestProfile(),
          InterestProfileOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('403 → forbidden; 404 → notFound', () async {
      final f = routedApp(
        onGet: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/interests'), 403),
      );
      expect(
          await f.loadRealInterestProfile(), InterestProfileOutcome.forbidden);

      final nf = routedApp(
        onGet: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/interests'), 404),
      );
      expect(
          await nf.loadRealInterestProfile(), InterestProfileOutcome.notFound);
    });

    test('500 → serverError; network', () async {
      final se = routedApp(
        onGet: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/interests'), 500),
      );
      expect(await se.loadRealInterestProfile(),
          InterestProfileOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(
          await net.loadRealInterestProfile(), InterestProfileOutcome.network);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all interest state', () async {
      final app = routedApp();
      await app.loadRealInterestProfile();
      expect(app.realInterestProfile, isNotNull);
      await app.logout();
      expect(app.realInterestProfile, isNull);
      expect(app.realInterestLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders content, sections and recalculate button', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealInterestProfileScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('interest-content')), findsOneWidget);
      expect(find.byKey(const Key('interest-meta')), findsOneWidget);
      expect(find.byKey(const Key('interest-section-travel-styles')),
          findsOneWidget);
      expect(find.byKey(const Key('interest-recalculate')), findsOneWidget);
    });

    testWidgets('tapping recalculate issues a POST', (t) async {
      var recalcs = 0;
      final app = routedApp(onRequest: (r) {
        if (recalcPath(r)) recalcs++;
      });
      await pumpSize(
        t,
        testApp(child: const RealInterestProfileScreen(), app: app),
        const Size(1200, 2600),
      );
      await t.tap(find.byKey(const Key('interest-recalculate')));
      await t.pumpAndSettle();
      expect(recalcs, 1);
    });

    testWidgets('empty profile shows the empty state with a recalc action',
        (t) async {
      final app =
          routedApp(onGet: (_) async => jsonResponse(emptyProfileJson(), 200));
      await pumpSize(
        t,
        testApp(child: const RealInterestProfileScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('interest-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onGet: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/interests'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealInterestProfileScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('interest-session-expired')), findsOneWidget);
    });

    testWidgets('an error shows the recoverable error state', (t) async {
      final app = routedApp(
        onGet: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/interests'), 500),
      );
      await pumpSize(
        t,
        testApp(child: const RealInterestProfileScreen(), app: app),
        const Size(1200, 2600),
      );
      expect(find.byKey(const Key('interest-error')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI52 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.interestRealTitle,
        en.interestRealEntryTitle,
        en.interestRealLoadingMessage,
        en.interestRealErrorMessage,
        en.interestRealForbiddenMessage,
        en.interestRealGoneMessage,
        en.interestRealNetworkMessage,
        en.interestRealEmptyTitle,
        en.interestRealEmptyMessage,
        en.interestRealRecalculateAction,
        en.interestRealRecalculateSemantic,
        en.interestRealRecalculatedMessage,
        en.interestRealRecalculateErrorMessage,
        en.interestRealTravelStyles,
        en.interestRealWeather,
        en.interestRealBudget,
        en.interestRealCrowd,
        en.interestRealAccessibility,
        en.interestRealProvinces,
        en.interestRealCategories,
        en.interestRealTags,
      ];
      final viValues = <String>[
        vi.interestRealTitle,
        vi.interestRealEntryTitle,
        vi.interestRealLoadingMessage,
        vi.interestRealErrorMessage,
        vi.interestRealForbiddenMessage,
        vi.interestRealGoneMessage,
        vi.interestRealNetworkMessage,
        vi.interestRealEmptyTitle,
        vi.interestRealEmptyMessage,
        vi.interestRealRecalculateAction,
        vi.interestRealRecalculateSemantic,
        vi.interestRealRecalculatedMessage,
        vi.interestRealRecalculateErrorMessage,
        vi.interestRealTravelStyles,
        vi.interestRealWeather,
        vi.interestRealBudget,
        vi.interestRealCrowd,
        vi.interestRealAccessibility,
        vi.interestRealProvinces,
        vi.interestRealCategories,
        vi.interestRealTags,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.interestRealTitle, isNot(vi.interestRealTitle));
    });

    test('placeholder getters resolve', () {
      final en = AppLocalizationsEn();
      expect(en.interestRealSignalCount(0).trim(), isNotEmpty);
      expect(en.interestRealSignalCount(5), contains('5'));
      expect(en.interestRealLastUpdated('May 1'), contains('May 1'));
    });

    test('reused dimension label keys resolve via shared helpers', () {
      final en = AppLocalizationsEn();
      expect(travelStyleLabel(en, 'SOLO'), en.travelStyleSolo);
      expect(weatherTypeLabel(en, 'SUNNY'), en.weatherSunny);
      expect(budgetLevelLabel(en, 'MEDIUM'), en.budgetMedium);
      expect(crowdLevelLabel(en, 'LOW'), en.crowdLow);
      expect(accessibilityLevelLabel(en, 'HIGH'), en.accessibilityHigh);
    });
  });
}
