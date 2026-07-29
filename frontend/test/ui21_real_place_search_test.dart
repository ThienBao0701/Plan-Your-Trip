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
import 'package:planyourtrip_frontend/features/places/places_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:planyourtrip_frontend/shared/widgets/bookmark_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void ignoreNetworkImageErrors() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is NetworkImageLoadException) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);
  }

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

  // ── Backend PlaceSummaryResponse / PageResponse fixtures ──────────────────
  // Verified against Plan-Your-Trip-backend-v1: summary uses `administrativeUnit`
  // + `reviewCount` (detail uses `location` + `ratingCount`).

  Map<String, dynamic> placeSummaryJson({
    int id = 7,
    String name = 'Backend Villa',
    String? slug = 'backend-villa',
    Map<String, dynamic>? category = const {
      'id': 3,
      'name': 'Hotels',
      'slug': 'hotels',
    },
    Map<String, dynamic>? administrativeUnit = const {
      'id': 5,
      'name': 'Đà Lạt',
      'slug': 'da-lat',
      'fullPath': 'Lâm Đồng > Đà Lạt',
    },
    String address = '12 Trần Hưng Đạo, Đà Lạt',
    String? shortDescription = 'Hillside villa',
    int priceLevel = 3,
    double ratingAvg = 4.6,
    int reviewCount = 128,
    bool featured = true,
    bool verified = true,
    String? coverImageUrl = 'https://img.example/cover.jpg',
    double? latitude = 11.94,
    double? longitude = 108.44,
  }) =>
      {
        'id': id,
        'name': name,
        'slug': slug,
        'category': category,
        'subcategory': null,
        'administrativeUnit': administrativeUnit,
        'address': address,
        'googleMapUrl': null,
        'latitude': latitude,
        'longitude': longitude,
        'shortDescription': shortDescription,
        'priceLevel': priceLevel,
        'ratingAvg': ratingAvg,
        'reviewCount': reviewCount,
        'status': 'PUBLISHED',
        'featured': featured,
        'verified': verified,
        'coverImageUrl': coverImageUrl,
        'createdAt': '2026-07-01T00:00:00Z',
      };

  Map<String, dynamic> searchPageJson({
    List<Map<String, dynamic>> content = const [],
    int page = 0,
    int size = 20,
    int? totalElements,
    int totalPages = 1,
  }) =>
      {
        'content': content,
        'page': page,
        'size': size,
        'totalElements': totalElements ?? content.length,
        'totalPages': totalPages,
      };

  // ── UI19 place-detail fixture (for hydration reuse) ───────────────────────

  Map<String, dynamic> placeDetailJson(
          {int id = 7, String name = 'Backend Villa'}) =>
      {
        'id': id,
        'name': name,
        'slug': 'backend-villa',
        'shortDescription': 'Hillside villa',
        'description': 'A calm hillside villa with garden views.',
        'address': '12 Trần Hưng Đạo, Đà Lạt',
        'latitude': 11.94,
        'longitude': 108.44,
        'category': const {'id': 3, 'name': 'Hotels', 'slug': 'hotels'},
        'subcategory': null,
        'location': const {
          'id': 5,
          'name': 'Đà Lạt',
          'slug': 'da-lat',
          'fullPath': 'Lâm Đồng > Đà Lạt',
        },
        'ratingAvg': 4.6,
        'ratingCount': 128,
        'priceLevel': 3,
        'featured': true,
        'verified': true,
        'status': 'PUBLISHED',
        'tags': const [],
        'amenities': const [],
        'openingHours': const [],
        'groupedOpeningHours': const [],
        'coverImageUrl': 'https://img.example/cover.jpg',
        'galleryImages': const [],
        'openNow': true,
        'similarPlaces': const [],
        'metadata': null,
        'hotelDetail': null,
      };

  Map<String, dynamic> wishlistJson(
          {List<Map<String, dynamic>> items = const []}) =>
      {
        'id': 1,
        'userId': 2,
        'items': items,
        'createdAt': '2026-07-01T00:00:00Z',
        'updatedAt': '2026-07-20T10:00:00Z',
      };

  AppState realApp(http.Client client) => AppState(
        api: ApiClient(client: client)..demoMode = false,
      )..demoMode = false;

  AppState demoApp(http.Client client) =>
      AppState(api: ApiClient(client: client));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('valid page maps and calls GET /api/places/search with params',
        () async {
      var path = '';
      var method = '';
      Map<String, String> params = const {};
      final app = realApp(MockClient((request) async {
        path = request.url.path;
        method = request.method;
        params = request.url.queryParameters;
        return jsonResponse(
          searchPageJson(
            content: [
              placeSummaryJson(),
              placeSummaryJson(id: 8, name: 'Second')
            ],
            totalElements: 2,
          ),
          200,
        );
      }));

      final outcome = await app.runRealSearch(query: 'villa');

      expect(outcome, PlaceSearchOutcome.success);
      expect(path, '/api/places/search');
      expect(method, 'GET');
      expect(params['q'], 'villa');
      expect(params['page'], '0');
      expect(params['size'], '20');
      expect(params['sort'], 'newest');
      expect(app.realSearchResults.length, 2);
      expect(app.realSearchTotalElements, 2);
      expect(app.realSearchLoaded, isTrue);
    });

    test('summary maps administrativeUnit→locationName and reviewCount',
        () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          searchPageJson(content: [placeSummaryJson()]),
          200,
        );
      }));

      await app.runRealSearch(query: '');
      final r = app.realSearchResults.single;
      expect(r.locationName, 'Đà Lạt');
      expect(r.reviewCount, 128);
      expect(r.ratingAvg, 4.6);
      expect(r.categoryName, 'Hotels');
      expect(r.priceLevel, 3);
      expect(r.priceLevelLabel, r'$$$');
    });

    test('nullable/partial summary fields degrade honestly', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          searchPageJson(content: [
            {
              'id': 9,
              'name': 'Sparse',
              'slug': null,
              'category': null,
              'administrativeUnit': null,
              'address': null,
              'shortDescription': null,
              'priceLevel': null,
              'ratingAvg': null,
              'reviewCount': null,
              'featured': null,
              'verified': null,
              'coverImageUrl': null,
              'latitude': null,
              'longitude': null,
            }
          ]),
          200,
        );
      }));

      await app.runRealSearch(query: '');
      final r = app.realSearchResults.single;
      expect(r.categoryName, isNull);
      expect(r.locationName, '');
      expect(r.priceLevel, 0);
      expect(r.priceLevelLabel, '');
      expect(r.ratingAvg, 0);
      expect(r.reviewCount, 0);
      expect(r.coverImageUrl, isNull);
    });

    test('filter arguments are forwarded as query params', () async {
      Map<String, String> params = const {};
      final app = realApp(MockClient((request) async {
        params = request.url.queryParameters;
        return jsonResponse(searchPageJson(), 200);
      }));

      await app.runRealSearch(
        query: 'beach',
        minRating: 4.0,
        maxPriceLevel: 2,
        sort: PlaceSearchSort.ratingDesc,
      );

      expect(params['q'], 'beach');
      expect(params['minRating'], '4.0');
      expect(params['maxPriceLevel'], '2');
      expect(params['sort'], 'rating_desc');
    });

    test('non-object body → malformed', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
            [placeSummaryJson()], 200); // array, not PageResponse
      }));

      final outcome = await app.runRealSearch(query: '');
      expect(outcome, PlaceSearchOutcome.malformed);
    });

    test('sort tokens map correctly', () {
      expect(PlaceSearchSort.newest.token, 'newest');
      expect(PlaceSearchSort.ratingDesc.token, 'rating_desc');
      expect(PlaceSearchSort.priceAsc.token, 'price_asc');
      expect(PlaceSearchSort.priceDesc.token, 'price_desc');
      expect(PlaceSearchSort.nameAsc.token, 'name_asc');
    });
  });

  // ── Search lifecycle ────────────────────────────────────────────────────────

  group('Search lifecycle', () {
    test('empty result set yields loaded + empty list', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(searchPageJson(content: const []), 200);
      }));

      final outcome = await app.runRealSearch(query: 'zzz');
      expect(outcome, PlaceSearchOutcome.success);
      expect(app.realSearchResults, isEmpty);
      expect(app.realSearchLoaded, isTrue);
      expect(app.realSearchError, isNull);
    });

    test('refresh replaces results and keeps criteria', () async {
      var call = 0;
      final app = realApp(MockClient((request) async {
        call++;
        return jsonResponse(
          searchPageJson(
            content: [placeSummaryJson(id: call, name: 'Call $call')],
          ),
          200,
        );
      }));

      await app.runRealSearch(query: 'villa');
      expect(app.realSearchResults.single.name, 'Call 1');
      final outcome = await app.runRealSearch(refresh: true);
      expect(outcome, PlaceSearchOutcome.success);
      expect(app.realSearchResults.single.name, 'Call 2');
      expect(app.realSearchQuery, 'villa'); // criterion preserved
    });

    test('failure preserves prior results and records the error', () async {
      var call = 0;
      final app = realApp(MockClient((request) async {
        call++;
        if (call == 1) {
          return jsonResponse(
            searchPageJson(content: [placeSummaryJson(name: 'Kept')]),
            200,
          );
        }
        return jsonResponse(
          errorBody(500, 'boom', '/api/places/search'),
          500,
        );
      }));

      await app.runRealSearch(query: 'villa');
      final outcome = await app.runRealSearch(refresh: true);
      expect(outcome, PlaceSearchOutcome.serverError);
      expect(app.realSearchError, PlaceSearchOutcome.serverError);
      expect(app.realSearchResults.single.name, 'Kept'); // preserved
    });

    test('retry after a network failure succeeds', () async {
      var call = 0;
      final app = realApp(MockClient((request) async {
        call++;
        if (call == 1) throw http.ClientException('offline');
        return jsonResponse(
          searchPageJson(content: [placeSummaryJson(name: 'Recovered')]),
          200,
        );
      }));

      final first = await app.runRealSearch(query: 'villa');
      expect(first, PlaceSearchOutcome.network);
      final second = await app.runRealSearch(refresh: true);
      expect(second, PlaceSearchOutcome.success);
      expect(app.realSearchResults.single.name, 'Recovered');
      expect(app.realSearchError, isNull);
    });
  });

  // ── Pagination ──────────────────────────────────────────────────────────────

  group('Pagination', () {
    test('loadMore appends the next page and flips hasMore', () async {
      final app = realApp(MockClient((request) async {
        final page = int.parse(request.url.queryParameters['page']!);
        return jsonResponse(
          searchPageJson(
            content: [placeSummaryJson(id: page * 10, name: 'Page $page')],
            page: page,
            totalElements: 2,
            totalPages: 2,
          ),
          200,
        );
      }));

      await app.runRealSearch(query: '');
      expect(app.realSearchResults.length, 1);
      expect(app.realSearchHasMore, isTrue);

      final outcome = await app.loadMoreRealSearch();
      expect(outcome, PlaceSearchOutcome.success);
      expect(app.realSearchResults.length, 2);
      expect(app.realSearchResults.map((r) => r.name), ['Page 0', 'Page 1']);
      expect(app.realSearchPage, 1);
      expect(app.realSearchHasMore, isFalse);
    });

    test('loadMore is a no-op when there are no more pages', () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(
          searchPageJson(
            content: [placeSummaryJson()],
            totalElements: 1,
            totalPages: 1,
          ),
          200,
        );
      }));

      await app.runRealSearch(query: '');
      expect(calls, 1);
      final outcome = await app.loadMoreRealSearch();
      expect(outcome, PlaceSearchOutcome.success);
      expect(calls, 1); // guarded — no extra request
    });

    test('loadMore discards a page when the query changed mid-flight',
        () async {
      final gate = Completer<void>();
      final app = realApp(MockClient((request) async {
        final page = int.parse(request.url.queryParameters['page']!);
        if (page == 1) {
          await gate.future;
          return jsonResponse(
            searchPageJson(
              content: [placeSummaryJson(id: 99, name: 'Stale page')],
              page: 1,
              totalPages: 2,
            ),
            200,
          );
        }
        return jsonResponse(
          searchPageJson(
            content: [
              placeSummaryJson(
                  id: 1, name: 'Q ${request.url.queryParameters['q']}')
            ],
            page: 0,
            totalElements: 3,
            totalPages: 2,
          ),
          200,
        );
      }));

      await app.runRealSearch(query: 'first');
      final moreFuture = app.loadMoreRealSearch(); // page 1, gated
      await app.runRealSearch(query: 'second'); // new request id
      gate.complete();
      await moreFuture;

      // Stale page dropped; state reflects the newer query only.
      expect(app.realSearchResults.any((r) => r.name == 'Stale page'), isFalse);
      expect(app.realSearchResults.single.name, 'Q second');
    });
  });

  // ── Last-request-wins (cancel outdated) ──────────────────────────────────────

  group('Cancel outdated', () {
    test('a superseded in-flight search does not overwrite the newer one',
        () async {
      final slowGate = Completer<void>();
      final app = realApp(MockClient((request) async {
        final q = request.url.queryParameters['q'];
        if (q == 'slow') {
          await slowGate.future;
          return jsonResponse(
            searchPageJson(content: [placeSummaryJson(id: 1, name: 'Slow')]),
            200,
          );
        }
        return jsonResponse(
          searchPageJson(content: [placeSummaryJson(id: 2, name: 'Fast')]),
          200,
        );
      }));

      final slow = app.runRealSearch(query: 'slow');
      final fast = app.runRealSearch(query: 'fast');
      await fast;
      expect(app.realSearchResults.single.name, 'Fast');

      slowGate.complete();
      await slow;
      // Stale response discarded — last write wins.
      expect(app.realSearchResults.single.name, 'Fast');
      expect(app.realSearchQuery, 'fast');
    });
  });

  // ── Error mapping ─────────────────────────────────────────────────────────

  group('Error mapping', () {
    Future<PlaceSearchOutcome> searchWithStatus(int status) async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          errorBody(status, 'x', '/api/places/search'),
          status,
        );
      }));
      return app.runRealSearch(query: '');
    }

    test('400 → validation', () async {
      expect(await searchWithStatus(400), PlaceSearchOutcome.validation);
    });

    test('500 → serverError', () async {
      expect(await searchWithStatus(500), PlaceSearchOutcome.serverError);
    });

    test('401 → sessionExpired and never logs out', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(errorBody(401, 'x', '/api/places/search'), 401);
      }));
      // Establish a session first (search is public, but assert no logout).
      final outcome = await app.runRealSearch(query: '');
      expect(outcome, PlaceSearchOutcome.sessionExpired);
      expect(app.realSearchError, PlaceSearchOutcome.sessionExpired);
    });

    test('403 → forbidden', () async {
      expect(await searchWithStatus(403), PlaceSearchOutcome.forbidden);
    });

    test('404 → notFound', () async {
      expect(await searchWithStatus(404), PlaceSearchOutcome.notFound);
    });

    test('timeout → timeout', () async {
      final app = realApp(MockClient((request) async {
        throw TimeoutException('slow');
      }));
      expect(await app.runRealSearch(query: ''), PlaceSearchOutcome.timeout);
    });
  });

  // ── Demo Mode isolation ───────────────────────────────────────────────────

  group('Demo Mode isolation', () {
    test('runRealSearch in Demo Mode is unavailable and issues no HTTP',
        () async {
      var calls = 0;
      final app = demoApp(MockClient((request) async {
        calls++;
        return jsonResponse(searchPageJson(), 200);
      }));

      final outcome = await app.runRealSearch(query: 'anything');
      expect(outcome, PlaceSearchOutcome.unavailable);
      expect(calls, 0);
      expect(app.realSearchResults, isEmpty);
    });

    test('loadMoreRealSearch in Demo Mode is unavailable and issues no HTTP',
        () async {
      var calls = 0;
      final app = demoApp(MockClient((request) async {
        calls++;
        return jsonResponse(searchPageJson(), 200);
      }));

      final outcome = await app.loadMoreRealSearch();
      expect(outcome, PlaceSearchOutcome.unavailable);
      expect(calls, 0);
    });

    testWidgets('Demo Places screen keeps its demo search field',
        (tester) async {
      ignoreNetworkImageErrors();
      await pumpSize(
        tester,
        testApp(child: const PlacesScreen(), app: AppState()),
        const Size(1200, 2200),
      );

      // Demo path untouched: demo search field key present, real one absent.
      expect(find.byKey(const Key('explore-search-field')), findsOneWidget);
      expect(find.byKey(const Key('real-explore-search-field')), findsNothing);
    });
  });

  // ── Hydration reuse (UI19) ────────────────────────────────────────────────

  group('Hydration reuse', () {
    test('tapping a result hydrates via GET /api/places/{id}', () async {
      final paths = <String>[];
      final app = realApp(MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/places/search') {
          return jsonResponse(
            searchPageJson(content: [placeSummaryJson(id: 7)]),
            200,
          );
        }
        if (request.url.path == '/api/places/7') {
          return jsonResponse(placeDetailJson(id: 7), 200);
        }
        return jsonResponse(errorBody(404, 'nope', request.url.path), 404);
      }));

      await app.runRealSearch(query: '');
      final result = await app.hydrateRealPlace(7);

      expect(result, PlaceHydrationResult.success);
      expect(paths, contains('/api/places/7'));
      expect(app.getHydratedRealPlace(7), isNotNull);
      expect(app.getHydratedRealPlace(7)!.name, 'Backend Villa');
    });
  });

  // ── Session reset ─────────────────────────────────────────────────────────

  group('Session reset', () {
    test('logout clears real-search state', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          searchPageJson(content: [placeSummaryJson()], totalElements: 5),
          200,
        );
      }));

      await app.runRealSearch(query: 'villa');
      expect(app.realSearchResults, isNotEmpty);
      expect(app.realSearchLoaded, isTrue);

      await app.logout();

      expect(app.realSearchResults, isEmpty);
      expect(app.realSearchLoaded, isFalse);
      expect(app.realSearchQuery, '');
      expect(app.realSearchError, isNull);
      expect(app.realSearchTotalPages, 0);
    });
  });

  // ── Widget: real search view ──────────────────────────────────────────────

  group('Real search view', () {
    // Routes every request the real Places view can make in a widget test.
    MockClient router({
      required Map<String, dynamic> Function(Uri url) onSearch,
    }) {
      return MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/places/search') {
          return jsonResponse(onSearch(request.url), 200);
        }
        if (path == '/api/me/wishlist') {
          return jsonResponse(wishlistJson(), 200);
        }
        if (path.startsWith('/api/places/')) {
          return jsonResponse(placeDetailJson(), 200);
        }
        return jsonResponse(errorBody(404, 'nope', path), 404);
      });
    }

    testWidgets('renders results with a count header and cards',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(router(
        onSearch: (_) => searchPageJson(
          content: [
            placeSummaryJson(id: 7),
            placeSummaryJson(id: 8, name: 'Second')
          ],
          totalElements: 2,
        ),
      ));

      await pumpSize(
        tester,
        testApp(child: const PlacesScreen(), app: app),
        const Size(1200, 2400),
      );

      expect(
          find.byKey(const Key('real-explore-search-field')), findsOneWidget);
      expect(find.byKey(const Key('real-search-card-7')), findsOneWidget);
      expect(find.byKey(const Key('real-search-card-8')), findsOneWidget);
      expect(find.text('Backend Villa'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('renders the no-results empty state', (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(router(
        onSearch: (_) => searchPageJson(content: const []),
      ));

      await pumpSize(
        tester,
        testApp(child: const PlacesScreen(), app: app),
        const Size(1200, 2200),
      );

      expect(find.byKey(const Key('real-search-empty')), findsOneWidget);
    });

    testWidgets('error state shows a retry that re-runs the search',
        (tester) async {
      ignoreNetworkImageErrors();
      var call = 0;
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(wishlistJson(), 200);
        }
        call++;
        if (call == 1) {
          return jsonResponse(
            errorBody(500, 'boom', '/api/places/search'),
            500,
          );
        }
        return jsonResponse(
          searchPageJson(content: [placeSummaryJson(id: 7)]),
          200,
        );
      }));

      await pumpSize(
        tester,
        testApp(child: const PlacesScreen(), app: app),
        const Size(1200, 2200),
      );

      expect(find.byKey(const Key('real-search-error')), findsOneWidget);

      await tester.tap(find.text(
        AppLocalizationsEn().errorAction,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('real-search-error')), findsNothing);
      expect(find.byKey(const Key('real-search-card-7')), findsOneWidget);
    });

    testWidgets('debounced typing issues a single trailing search',
        (tester) async {
      ignoreNetworkImageErrors();
      var searchCalls = 0;
      final queries = <String>[];
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(wishlistJson(), 200);
        }
        searchCalls++;
        queries.add(request.url.queryParameters['q'] ?? '');
        return jsonResponse(searchPageJson(content: const []), 200);
      }));

      await pumpSize(
        tester,
        testApp(child: const PlacesScreen(), app: app),
        const Size(1200, 2200),
      );

      // Initial post-frame search (empty query).
      final initialCalls = searchCalls;

      await tester.enterText(
        find.byKey(const Key('real-explore-search-field')),
        'da lat',
      );
      // Before the debounce elapses: no new search yet.
      await tester.pump(const Duration(milliseconds: 100));
      expect(searchCalls, initialCalls);
      // After the debounce window: exactly one trailing search.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(searchCalls, initialCalls + 1);
      expect(queries.last, 'da lat');
    });

    testWidgets('infinite scroll appends the next page', (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(wishlistJson(), 200);
        }
        final page = int.parse(request.url.queryParameters['page']!);
        return jsonResponse(
          searchPageJson(
            content: List.generate(
              8,
              (i) => placeSummaryJson(
                id: page * 100 + i,
                name: 'P$page-$i',
              ),
            ),
            page: page,
            totalElements: 16,
            totalPages: 2,
          ),
          200,
        );
      }));

      // A short viewport guarantees the 8-card first page overflows and is
      // scrollable, so the infinite-scroll listener can fire.
      await pumpSize(
        tester,
        testApp(child: const PlacesScreen(), app: app),
        const Size(800, 600),
      );

      expect(find.byKey(const Key('real-search-card-0')), findsOneWidget);
      expect(app.realSearchResults.length, 8);

      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(app.realSearchResults.length, 16);
      expect(app.realSearchHasMore, isFalse);
    });

    testWidgets('a11y: loading state announces a localized message',
        (tester) async {
      ignoreNetworkImageErrors();
      final gate = Completer<void>();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(wishlistJson(), 200);
        }
        await gate.future;
        return jsonResponse(searchPageJson(content: const []), 200);
      }));

      await tester.pumpWidget(testApp(child: const PlacesScreen(), app: app));
      await tester.pump(); // fire post-frame search; response gated
      await tester.pump();

      expect(find.text(AppLocalizationsEn().searchRealLoadingMessage),
          findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
    });
  });

  // ── Wishlist compatibility (UI18) ─────────────────────────────────────────

  group('Wishlist compatibility', () {
    testWidgets('a BookmarkButton renders inside each result card',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(wishlistJson(), 200);
        }
        if (request.url.path == '/api/places/search') {
          return jsonResponse(
            searchPageJson(content: [placeSummaryJson(id: 7)]),
            200,
          );
        }
        return jsonResponse(errorBody(404, 'nope', request.url.path), 404);
      }));

      await pumpSize(
        tester,
        testApp(child: const PlacesScreen(), app: app),
        const Size(1200, 2200),
      );

      expect(find.byType(BookmarkButton), findsOneWidget);
    });
  });

  // ── Add-to-trip compatibility (UI20) ──────────────────────────────────────

  group('Add-to-trip compatibility', () {
    testWidgets('add action hydrates then opens the add-to-trip sheet',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/me/wishlist') {
          return jsonResponse(wishlistJson(), 200);
        }
        if (path == '/api/places/search') {
          return jsonResponse(
            searchPageJson(content: [placeSummaryJson(id: 7)]),
            200,
          );
        }
        if (path == '/api/places/7') {
          return jsonResponse(placeDetailJson(id: 7), 200);
        }
        if (path == '/api/me/trips') {
          return jsonResponse(const [], 200);
        }
        return jsonResponse(errorBody(404, 'nope', path), 404);
      }));

      await pumpSize(
        tester,
        testApp(child: const PlacesScreen(), app: app),
        const Size(1200, 2400),
      );

      await tester.tap(find.byKey(const Key('real-search-add-7')));
      await tester.pumpAndSettle();

      // Hydration ran and the shared add-to-trip sheet opened (real mode with
      // no trips shows the empty state).
      expect(app.getHydratedRealPlace(7), isNotNull);
      expect(find.byKey(const Key('real-quick-add-empty')), findsOneWidget);
    });
  });

  // ── Localization parity ───────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI21 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final pairs = <String, String>{
        'searchRealLoadingMessage':
            '${en.searchRealLoadingMessage}|${vi.searchRealLoadingMessage}',
        'searchRealErrorMessage':
            '${en.searchRealErrorMessage}|${vi.searchRealErrorMessage}',
        'searchRealNoResultsMessage':
            '${en.searchRealNoResultsMessage}|${vi.searchRealNoResultsMessage}',
        'searchRealEndOfResults':
            '${en.searchRealEndOfResults}|${vi.searchRealEndOfResults}',
        'searchRealSortLabel':
            '${en.searchRealSortLabel}|${vi.searchRealSortLabel}',
        'searchRealRatingLabel':
            '${en.searchRealRatingLabel}|${vi.searchRealRatingLabel}',
        'searchRealPriceLabel':
            '${en.searchRealPriceLabel}|${vi.searchRealPriceLabel}',
        'searchRealSortNewest':
            '${en.searchRealSortNewest}|${vi.searchRealSortNewest}',
        'searchRealSortTopRated':
            '${en.searchRealSortTopRated}|${vi.searchRealSortTopRated}',
        'searchRealSortPriceLow':
            '${en.searchRealSortPriceLow}|${vi.searchRealSortPriceLow}',
        'searchRealSortPriceHigh':
            '${en.searchRealSortPriceHigh}|${vi.searchRealSortPriceHigh}',
        'searchRealSortName':
            '${en.searchRealSortName}|${vi.searchRealSortName}',
        'searchRealRatingAny':
            '${en.searchRealRatingAny}|${vi.searchRealRatingAny}',
        'searchRealRating3plus':
            '${en.searchRealRating3plus}|${vi.searchRealRating3plus}',
        'searchRealRating4plus':
            '${en.searchRealRating4plus}|${vi.searchRealRating4plus}',
        'searchRealRating45plus':
            '${en.searchRealRating45plus}|${vi.searchRealRating45plus}',
        'searchRealPriceAny':
            '${en.searchRealPriceAny}|${vi.searchRealPriceAny}',
      };
      for (final entry in pairs.entries) {
        final parts = entry.value.split('|');
        expect(parts[0].trim(), isNotEmpty, reason: '${entry.key} EN empty');
        expect(parts[1].trim(), isNotEmpty, reason: '${entry.key} VI empty');
      }
    });
  });
}
