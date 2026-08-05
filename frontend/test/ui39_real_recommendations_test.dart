import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/profile/profile_screen.dart';
import 'package:planyourtrip_frontend/features/recommendations/real_recommendations_screen.dart';
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

  Map<String, dynamic> recJson({
    int id = 1,
    String type = 'PLACE',
    int score = 88,
    String engagementState = 'ACTIVE',
    String targetSummary = 'Hoi An Old Town',
    bool withPlace = true,
  }) =>
      {
        'id': id,
        'type': type,
        'score': score,
        'reasonCode': 'SAVED_SIMILAR_PLACE',
        'reasonText': 'Because you saved similar places',
        'generatedAt': '2030-02-01T00:00:00Z',
        'expiresAt': '2030-03-01T00:00:00Z',
        'engagementState': engagementState,
        'dismissedAt': null,
        'clickedAt':
            engagementState == 'CLICKED' ? '2030-02-02T00:00:00Z' : null,
        'convertedAt': null,
        'sourceRuleId': 5,
        'sourceRuleCode': 'WISHLIST_AFFINITY',
        'targetSummary': targetSummary,
        'place': withPlace
            ? {'id': 42, 'name': targetSummary, 'slug': 'hoi-an'}
            : null,
        'hotel': null,
        'room': null,
        'promotion': null,
        'coupon': null,
        'metadataJson': null,
      };

  Map<String, dynamic> pageJson(List<Map<String, dynamic>> items,
          {int page = 0, int totalPages = 1}) =>
      {
        'content': items,
        'page': page,
        'size': 20,
        'totalElements': items.length,
        'totalPages': totalPages,
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/recommendations');
  bool detailPath(http.Request r) =>
      r.method == 'GET' &&
      RegExp(r'/me/recommendations/\d+$').hasMatch(r.url.path);
  bool generatePath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/recommendations/generate');
  bool dismissPath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/dismiss');
  bool clickPath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/click');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onDetail,
    Future<http.Response> Function(http.Request)? onGenerate,
    Future<http.Response> Function(http.Request)? onDismiss,
    Future<http.Response> Function(http.Request)? onClick,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (generatePath(request)) {
          return (onGenerate ??
              (_) async => jsonResponse(
                    {
                      'generatedCount': 3,
                      'totalActive': 5,
                      'generatedAt': '2030-02-01T00:00:00Z',
                      'recommendations': const [],
                    },
                    200,
                  ))(request);
        }
        if (dismissPath(request)) {
          return (onDismiss ??
              (_) async => jsonResponse(
                  recJson(engagementState: 'DISMISSED'), 200))(request);
        }
        if (clickPath(request)) {
          return (onClick ??
              (_) async => jsonResponse(
                  recJson(engagementState: 'CLICKED'), 200))(request);
        }
        if (detailPath(request)) {
          return (onDetail ??
              (_) async => jsonResponse(recJson(), 200))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse(pageJson([recJson()]), 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('page + nested place parse; correct path', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) seen = r;
      });
      expect(
          await app.loadRealRecommendations(), RecommendationOutcome.success);
      expect(seen!.url.path.endsWith('/me/recommendations'), isTrue);
      final r = app.realRecommendations.single;
      expect(r.id, 1);
      expect(r.typeView, RecommendationTypeView.place);
      expect(r.score, 88);
      expect(r.engagementView, RecommendationEngagementView.active);
      expect(r.targetSummary, 'Hoi An Old Town');
      expect(r.placeId, 42);
      expect(r.placeName, 'Hoi An Old Town');
      expect(r.reasonText, 'Because you saved similar places');
      expect(app.realRecommendationsTotalPages, 1);
    });

    test('type / engagement mappers, unknown → unknown', () {
      expect(recommendationTypeViewFromCode('HOTEL'),
          RecommendationTypeView.hotel);
      expect(recommendationTypeViewFromCode('TRIP_IDEA'),
          RecommendationTypeView.tripIdea);
      expect(recommendationTypeViewFromCode('???'),
          RecommendationTypeView.unknown);
      expect(recommendationEngagementViewFromCode('CONVERTED'),
          RecommendationEngagementView.converted);
      expect(recommendationEngagementViewFromCode('???'),
          RecommendationEngagementView.unknown);
    });

    test('non-page body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('[]', 200)));
      expect(await app.loadRealRecommendations(),
          RecommendationOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(pageJson([recJson()]), 200);
      }));
      expect(await app.loadRealRecommendations(),
          RecommendationOutcome.demoUnavailable);
      expect(await app.loadMoreRealRecommendations(),
          RecommendationOutcome.demoUnavailable);
      expect(await app.loadRealRecommendationDetail(1),
          RecommendationOutcome.demoUnavailable);
      expect(await app.generateRealRecommendations(),
          RecommendationOutcome.demoUnavailable);
      expect(await app.dismissRealRecommendation(1),
          RecommendationOutcome.demoUnavailable);
      expect(await app.trackRealRecommendationClick(1),
          RecommendationOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realRecommendations, isEmpty);
    });
  });

  // ── Load, paginate, detail ───────────────────────────────────────────────────

  group('Load and paginate', () {
    test('cached list is not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) gets++;
      });
      await app.loadRealRecommendations();
      await app.loadRealRecommendations();
      expect(gets, 1);
      await app.loadRealRecommendations(refresh: true);
      expect(gets, 2);
    });

    test('load more appends the next page', () async {
      final app = routedApp(
        onList: (r) async {
          final page = int.tryParse(r.url.queryParameters['page'] ?? '0') ?? 0;
          if (page == 0) {
            return jsonResponse(pageJson([recJson(id: 1)], totalPages: 2), 200);
          }
          return jsonResponse(
              pageJson([recJson(id: 2)], page: 1, totalPages: 2), 200);
        },
      );
      await app.loadRealRecommendations();
      expect(app.realRecommendations.length, 1);
      expect(app.realRecommendationsHasMore, isTrue);
      expect(await app.loadMoreRealRecommendations(),
          RecommendationOutcome.success);
      expect(app.realRecommendations.map((r) => r.id), [1, 2]);
      expect(app.realRecommendationsHasMore, isFalse);
    });

    test('detail caches (2nd read no HTTP)', () async {
      var detailGets = 0;
      final app = routedApp(onRequest: (r) {
        if (detailPath(r)) detailGets++;
      });
      await app.loadRealRecommendationDetail(1);
      await app.loadRealRecommendationDetail(1);
      expect(detailGets, 1);
      expect(app.recommendationDetailCache.containsKey(1), isTrue);
    });
  });

  // ── Generate, dismiss, click ───────────────────────────────────────────────────

  group('Engagement', () {
    test('generate POSTs and reloads the feed', () async {
      var listGets = 0;
      var generated = 0;
      final app = routedApp(
        onRequest: (r) {
          if (listPath(r)) listGets++;
          if (generatePath(r)) generated++;
        },
      );
      await app.loadRealRecommendations();
      expect(listGets, 1);
      expect(await app.generateRealRecommendations(),
          RecommendationOutcome.success);
      expect(generated, 1);
      expect(listGets, 2); // reloaded after generate
    });

    test('dismiss PATCHes and drops the item locally', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (dismissPath(r)) seen = r;
      });
      await app.loadRealRecommendations();
      expect(app.realRecommendations, isNotEmpty);
      expect(await app.dismissRealRecommendation(1),
          RecommendationOutcome.success);
      expect(seen!.url.path.endsWith('/me/recommendations/1/dismiss'), isTrue);
      expect(app.realRecommendations.any((r) => r.id == 1), isFalse);
    });

    test('click PATCHes best-effort and merges the update', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (clickPath(r)) seen = r;
      });
      await app.loadRealRecommendations();
      expect(await app.trackRealRecommendationClick(1),
          RecommendationOutcome.success);
      expect(seen!.url.path.endsWith('/me/recommendations/1/click'), isTrue);
      expect(app.realRecommendations.single.engagementView,
          RecommendationEngagementView.clicked);
    });

    test('dismiss 404 → notFound, keeps the item', () async {
      final app = routedApp(
        onDismiss: (_) async => jsonResponse(
            errorBody(404, 'x', '/api/me/recommendations/1/dismiss'), 404),
      );
      await app.loadRealRecommendations();
      expect(await app.dismissRealRecommendation(1),
          RecommendationOutcome.notFound);
      expect(app.realRecommendations.any((r) => r.id == 1), isTrue);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/recommendations'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealRecommendations(),
          RecommendationOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('list 500 → serverError; network', () async {
      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/api/me/recommendations'), 500),
      );
      expect(await se.loadRealRecommendations(),
          RecommendationOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(
          await net.loadRealRecommendations(), RecommendationOutcome.network);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onList: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/api/me/recommendations'), 500)
            : jsonResponse(pageJson([recJson()]), 200),
      );
      await app.loadRealRecommendations();
      expect(app.realRecommendations, isNotEmpty);
      fail = true;
      expect(await app.loadRealRecommendations(refresh: true),
          RecommendationOutcome.serverError);
      expect(app.realRecommendations, isNotEmpty);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all recommendation state', () async {
      final app = routedApp();
      await app.loadRealRecommendations();
      await app.loadRealRecommendationDetail(1);
      expect(app.realRecommendations, isNotEmpty);
      expect(app.recommendationDetailCache, isNotEmpty);
      await app.logout();
      expect(app.realRecommendations, isEmpty);
      expect(app.recommendationDetailCache, isEmpty);
      expect(app.realRecommendationsLoaded, isFalse);
      expect(app.realRecommendationsTotalPages, 0);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders content + cards', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealRecommendationsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('recommendations-content')), findsOneWidget);
      expect(find.byKey(const Key('recommendation-card-1')), findsOneWidget);
    });

    testWidgets('tapping a card opens the detail sheet', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealRecommendationsScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('recommendation-card-1')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('recommendation-detail-content')),
          findsOneWidget);
    });

    testWidgets('dismiss removes the card', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealRecommendationsScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('recommendation-dismiss-1')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('recommendation-card-1')), findsNothing);
    });

    testWidgets('empty feed shows the empty state', (t) async {
      final app =
          routedApp(onList: (_) async => jsonResponse(pageJson(const []), 200));
      await pumpSize(
        t,
        testApp(child: const RealRecommendationsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('recommendations-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/recommendations'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealRecommendationsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('recommendations-session-expired')),
          findsOneWidget);
    });

    testWidgets('profile card present in Real Mode', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const Scaffold(body: ProfileScreen()), app: app),
        const Size(1200, 2800),
      );
      expect(find.byKey(const Key('profile-recommendations')), findsOneWidget);
    });

    testWidgets('profile card absent in Demo Mode (zero HTTP)', (t) async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(const <String, dynamic>{}, 200);
      }));
      await pumpSize(
        t,
        testApp(child: const Scaffold(body: ProfileScreen()), app: app),
        const Size(1200, 2800),
      );
      expect(find.byKey(const Key('profile-recommendations')), findsNothing);
      expect(calls, 0);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI39 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.recommendationsTitle,
        en.recommendationsLoadingMessage,
        en.recommendationsErrorMessage,
        en.recommendationsEmptyTitle,
        en.recommendationsEmptyMessage,
        en.recommendationsGenerateSemantic,
        en.recommendationsGeneratedMessage,
        en.recommendationsGenerateErrorMessage,
        en.recommendationsLoadMore,
        en.recommendationsDismissedMessage,
        en.recommendationsActionErrorMessage,
        en.recommendationsNetworkMessage,
        en.recommendationsGoneMessage,
        en.recommendationUntitled,
        en.recommendationTypePlace,
        en.recommendationTypeHotel,
        en.recommendationTypeRoom,
        en.recommendationTypePromotion,
        en.recommendationTypeCoupon,
        en.recommendationTypeTripIdea,
        en.recommendationTypeOther,
        en.recommendationStateClicked,
        en.recommendationStateConverted,
        en.recommendationDetailReason,
      ];
      final viValues = <String>[
        vi.recommendationsTitle,
        vi.recommendationsLoadingMessage,
        vi.recommendationsErrorMessage,
        vi.recommendationsEmptyTitle,
        vi.recommendationsEmptyMessage,
        vi.recommendationsGenerateSemantic,
        vi.recommendationsGeneratedMessage,
        vi.recommendationsGenerateErrorMessage,
        vi.recommendationsLoadMore,
        vi.recommendationsDismissedMessage,
        vi.recommendationsActionErrorMessage,
        vi.recommendationsNetworkMessage,
        vi.recommendationsGoneMessage,
        vi.recommendationUntitled,
        vi.recommendationTypePlace,
        vi.recommendationTypeHotel,
        vi.recommendationTypeRoom,
        vi.recommendationTypePromotion,
        vi.recommendationTypeCoupon,
        vi.recommendationTypeTripIdea,
        vi.recommendationTypeOther,
        vi.recommendationStateClicked,
        vi.recommendationStateConverted,
        vi.recommendationDetailReason,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.recommendationsTitle, isNot(vi.recommendationsTitle));
    });

    test('parameterized keys resolve in both locales', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      expect(en.recommendationsDismissSemantic('Hoi An'), contains('Hoi An'));
      expect(vi.recommendationsDismissSemantic('Hoi An'), contains('Hoi An'));
      expect(en.recommendationCardSemantic('Hoi An'), contains('Hoi An'));
      expect(en.recommendationScoreSemantic(88), contains('88'));
      expect(vi.recommendationScoreSemantic(88), contains('88'));
      expect(en.recommendationDetailGenerated('Feb 1'), contains('Feb 1'));
      expect(vi.recommendationDetailExpires('Mar 1'), contains('Mar 1'));
    });
  });
}
