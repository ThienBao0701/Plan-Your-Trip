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
import 'package:planyourtrip_frontend/features/profile/saved_places_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
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

  Map<String, dynamic> placeSummaryJson({
    int id = 1,
    String name = 'Mây Lang Thang Villa',
    String? slug = 'may-lang-thang-villa',
    String? categoryName = 'Hotels',
    String? address = '12 Trần Hưng Đạo, Đà Lạt',
    String? shortDescription = 'Hillside villa',
    double ratingAvg = 4.5,
    int reviewCount = 10,
  }) =>
      {
        'id': id,
        'name': name,
        'slug': slug,
        'categoryName': categoryName,
        'address': address,
        'shortDescription': shortDescription,
        'ratingAvg': ratingAvg,
        'reviewCount': reviewCount,
      };

  Map<String, dynamic> itemJson({
    int id = 100,
    int placeId = 1,
    String name = 'Mây Lang Thang Villa',
    String? note,
    String createdAt = '2026-07-20T10:00:00Z',
    Map<String, dynamic>? place,
  }) =>
      {
        'id': id,
        'place': place ?? placeSummaryJson(id: placeId, name: name),
        'note': note,
        'createdAt': createdAt,
      };

  Map<String, dynamic> wishlistJson({
    int id = 1,
    int userId = 2,
    List<Map<String, dynamic>> items = const [],
    String createdAt = '2026-07-01T00:00:00Z',
    String updatedAt = '2026-07-20T10:00:00Z',
  }) =>
      {
        'id': id,
        'userId': userId,
        'items': items,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

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

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('valid wishlist response parses into typed items in server order',
        () async {
      final app = realApp(MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/me/wishlist');
        return jsonResponse(
          wishlistJson(items: [
            itemJson(id: 100, placeId: 5, name: 'B'),
            itemJson(id: 101, placeId: 9, name: 'A'),
          ]),
          200,
        );
      }));
      final outcome = await app.loadRealWishlist();
      expect(outcome, WishlistActionResult.success);
      expect(app.realWishlist.map((i) => i.placeId), [5, 9]);
      expect(app.realWishlist.first.place.name, 'B');
      expect(app.realWishlistLoaded, isTrue);
    });

    test('partial/null optional fields parse without error', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          wishlistJson(items: [
            {
              'id': 100,
              'place': {
                'id': 5,
                'name': 'Sparse Place',
                // slug/categoryName/address/shortDescription omitted or null
                'slug': null,
                'categoryName': null,
                'address': null,
                'shortDescription': null,
                // ratingAvg / reviewCount omitted entirely
              },
              'note': null,
              'createdAt': null,
            },
          ]),
          200,
        );
      }));
      final outcome = await app.loadRealWishlist();
      expect(outcome, WishlistActionResult.success);
      final item = app.realWishlist.single;
      expect(item.place.name, 'Sparse Place');
      expect(item.place.categoryName, isNull);
      expect(item.place.ratingAvg, 0);
      expect(item.place.reviewCount, 0);
      expect(item.note, isNull);
      expect(item.createdAt, isNull);
    });

    test('malformed body maps to serverError and leaves list empty', () async {
      final app = realApp(MockClient((request) async {
        return http.Response('not json at all', 200);
      }));
      final outcome = await app.loadRealWishlist();
      expect(outcome, WishlistActionResult.serverError);
      expect(app.realWishlist, isEmpty);
      expect(app.realWishlistLoaded, isFalse);
    });

    test('add uses POST /items with placeId; remove uses DELETE by placeId',
        () async {
      var addPath = '';
      var addBody = '';
      var deletePath = '';
      final app = realApp(MockClient((request) async {
        if (request.method == 'POST') {
          addPath = request.url.path;
          addBody = request.body;
          return jsonResponse(itemJson(id: 100, placeId: 7), 201);
        }
        if (request.method == 'DELETE') {
          deletePath = request.url.path;
          return http.Response('', 204);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      await app.addPlaceToRealWishlist(7);
      await app.removePlaceFromRealWishlist(7);
      expect(addPath, '/api/me/wishlist/items');
      expect(jsonDecode(addBody)['placeId'], 7);
      expect(deletePath, '/api/me/wishlist/items/7');
    });
  });

  // ── Demo Mode isolation ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('every real wishlist method is a no-op with zero HTTP in demo mode',
        () async {
      var calls = 0;
      final app = AppState(
        api: ApiClient(client: MockClient((request) async {
          calls++;
          return jsonResponse(wishlistJson(), 200);
        })),
      )..demoMode = true;

      expect(await app.loadRealWishlist(), WishlistActionResult.unavailable);
      expect(await app.refreshRealWishlist(), WishlistActionResult.unavailable);
      expect(await app.ensureRealWishlistLoaded(),
          WishlistActionResult.unavailable);
      expect(await app.addPlaceToRealWishlist(1),
          WishlistActionResult.unavailable);
      expect(await app.removePlaceFromRealWishlist(1),
          WishlistActionResult.unavailable);
      expect(calls, 0);
    });

    test('toggleBookmark stays local in demo mode (zero HTTP)', () async {
      var calls = 0;
      final app = AppState(
        api: ApiClient(client: MockClient((request) async {
          calls++;
          return jsonResponse(wishlistJson(), 200);
        })),
      )..demoMode = true;
      final placeId = app.places.firstWhere((p) => !app.isPlaceSaved(p.id)).id;

      expect(app.isPlaceBookmarked(placeId), isFalse);
      expect(await app.toggleBookmark(placeId), BookmarkOutcome.added);
      expect(app.isPlaceBookmarked(placeId), isTrue);
      expect(app.isPlaceSaved(placeId), isTrue);
      expect(await app.toggleBookmark(placeId), BookmarkOutcome.removed);
      expect(app.isPlaceBookmarked(placeId), isFalse);
      expect(calls, 0);
    });

    test('UI16 demo savePlace/removeSavedPlace behavior is unchanged',
        () async {
      final app = AppState()..demoMode = true;
      final placeId = app.places.firstWhere((p) => !app.isPlaceSaved(p.id)).id;
      expect(app.savePlace(placeId), SavedPlaceActionResult.success);
      expect(app.isPlaceSaved(placeId), isTrue);
      expect(app.savePlace(placeId), SavedPlaceActionResult.duplicate);
      expect(app.removeSavedPlace(placeId), SavedPlaceActionResult.success);
      expect(app.isPlaceSaved(placeId), isFalse);
      // Real-wishlist queries never leak demo state.
      expect(app.isPlaceInRealWishlist(placeId), isFalse);
    });
  });

  // ── Real Mode loading ──────────────────────────────────────────────────────

  group('Real Mode loading', () {
    test('loading flag flips true synchronously then false on success',
        () async {
      final app = realApp(MockClient((request) async =>
          jsonResponse(wishlistJson(items: [itemJson()]), 200)));
      expect(app.realWishlistLoading, isFalse);
      final future = app.loadRealWishlist();
      expect(app.realWishlistLoading, isTrue);
      expect(await future, WishlistActionResult.success);
      expect(app.realWishlistLoading, isFalse);
      expect(app.realWishlist, hasLength(1));
    });

    test('empty wishlist is a loaded success', () async {
      final app = realApp(
          MockClient((request) async => jsonResponse(wishlistJson(), 200)));
      expect(await app.loadRealWishlist(), WishlistActionResult.success);
      expect(app.realWishlist, isEmpty);
      expect(app.realWishlistLoaded, isTrue);
    });

    test('load caches; refresh re-fetches', () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(wishlistJson(), 200);
      }));
      await app.loadRealWishlist();
      await app.loadRealWishlist(); // cached, no second call
      expect(calls, 1);
      await app.refreshRealWishlist();
      expect(calls, 2);
    });

    test('network failure sets error; retry then succeeds', () async {
      var attempt = 0;
      final app = realApp(MockClient((request) async {
        attempt++;
        if (attempt == 1) throw TimeoutException('simulated');
        return jsonResponse(wishlistJson(items: [itemJson()]), 200);
      }));
      expect(await app.loadRealWishlist(), WishlistActionResult.network);
      expect(app.realWishlistError, WishlistActionResult.network);
      expect(app.realWishlist, isEmpty);
      expect(await app.loadRealWishlist(refresh: true),
          WishlistActionResult.success);
      expect(app.realWishlist, hasLength(1));
      expect(app.realWishlistError, isNull);
    });

    test('5xx maps to serverError', () async {
      final app = realApp(MockClient((request) async =>
          jsonResponse(errorBody(500, 'boom', '/api/me/wishlist'), 500)));
      expect(await app.loadRealWishlist(), WishlistActionResult.serverError);
    });
  });

  // ── Real Mode actions ──────────────────────────────────────────────────────

  group('Real Mode actions', () {
    test('add success inserts item and reports membership', () async {
      final app = realApp(MockClient((request) async {
        if (request.method == 'POST') {
          return jsonResponse(
              itemJson(id: 100, placeId: 7, name: 'Added'), 201);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      expect(app.isPlaceInRealWishlist(7), isFalse);
      expect(await app.addPlaceToRealWishlist(7), WishlistActionResult.success);
      expect(app.isPlaceInRealWishlist(7), isTrue);
      expect(app.realWishlist.first.placeId, 7);
    });

    test('remove success drops the item', () async {
      final app = realApp(MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse(wishlistJson(items: [itemJson(placeId: 7)]), 200);
        }
        return http.Response('', 204);
      }));
      await app.loadRealWishlist();
      expect(app.isPlaceInRealWishlist(7), isTrue);
      expect(await app.removePlaceFromRealWishlist(7),
          WishlistActionResult.success);
      expect(app.isPlaceInRealWishlist(7), isFalse);
    });

    test('failed add retains unsaved state', () async {
      final app = realApp(MockClient((request) async =>
          jsonResponse(errorBody(500, 'boom', '/api/me/wishlist/items'), 500)));
      expect(await app.addPlaceToRealWishlist(7),
          WishlistActionResult.serverError);
      expect(app.isPlaceInRealWishlist(7), isFalse);
    });

    test('failed remove retains saved state', () async {
      final app = realApp(MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse(wishlistJson(items: [itemJson(placeId: 7)]), 200);
        }
        return jsonResponse(
            errorBody(500, 'boom', '/api/me/wishlist/items/7'), 500);
      }));
      await app.loadRealWishlist();
      expect(await app.removePlaceFromRealWishlist(7),
          WishlistActionResult.serverError);
      expect(app.isPlaceInRealWishlist(7), isTrue);
    });

    test('double-tap add is de-duplicated by the in-flight guard', () async {
      var posts = 0;
      final completer = Completer<http.Response>();
      final app = realApp(MockClient((request) async {
        if (request.method == 'POST') {
          posts++;
          return completer.future;
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      final first = app.addPlaceToRealWishlist(7);
      final second = app.addPlaceToRealWishlist(7); // guarded, no 2nd POST
      expect(app.isWishlistActionInFlight(7), isTrue);
      expect(await second, WishlistActionResult.success);
      completer.complete(jsonResponse(itemJson(placeId: 7), 201));
      expect(await first, WishlistActionResult.success);
      expect(posts, 1);
    });

    test('401 on add maps to unauthenticated and never logs out', () async {
      final app = realApp(MockClient((request) async => jsonResponse(
          errorBody(401, 'Authentication required', '/api/me/wishlist/items'),
          401)));
      app.email = 'real@example.com';
      app.api.token = 'stale-token';
      expect(await app.addPlaceToRealWishlist(7),
          WishlistActionResult.unauthenticated);
      // No logout side-effects.
      expect(app.email, 'real@example.com');
      expect(app.api.token, 'stale-token');
      expect(app.demoMode, isFalse);
    });

    test('404 disambiguates add (placeNotFound) vs remove (itemNotFound)',
        () async {
      final app = realApp(MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse(wishlistJson(items: [itemJson(placeId: 7)]), 200);
        }
        return jsonResponse(errorBody(404, 'nope', request.url.path), 404);
      }));
      expect(await app.addPlaceToRealWishlist(9),
          WishlistActionResult.placeNotFound);
      await app.loadRealWishlist();
      expect(await app.removePlaceFromRealWishlist(7),
          WishlistActionResult.itemNotFound);
    });

    test('409 on add maps to duplicate', () async {
      final app = realApp(MockClient((request) async => jsonResponse(
          errorBody(409, 'already in your wishlist', '/api/me/wishlist/items'),
          409)));
      expect(
          await app.addPlaceToRealWishlist(7), WishlistActionResult.duplicate);
    });

    test('422 on add maps to notPublished', () async {
      final app = realApp(MockClient((request) async => jsonResponse(
          errorBody(422, 'Only published places can be added',
              '/api/me/wishlist/items'),
          422)));
      expect(await app.addPlaceToRealWishlist(7),
          WishlistActionResult.notPublished);
      expect(app.isPlaceInRealWishlist(7), isFalse);
    });
  });

  // ── Mode-aware toggle + cross-screen sync ─────────────────────────────────

  group('Cross-screen synchronization', () {
    test('real toggleBookmark add/remove flips membership for all readers',
        () async {
      final app = realApp(MockClient((request) async {
        if (request.method == 'POST') {
          return jsonResponse(itemJson(placeId: 7), 201);
        }
        if (request.method == 'DELETE') return http.Response('', 204);
        return jsonResponse(wishlistJson(), 200);
      }));
      expect(await app.toggleBookmark(7), BookmarkOutcome.added);
      expect(app.isPlaceBookmarked(7), isTrue);
      expect(await app.toggleBookmark(7), BookmarkOutcome.removed);
      expect(app.isPlaceBookmarked(7), isFalse);
    });

    testWidgets('two BookmarkButtons for the same place stay in sync',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.method == 'POST') {
          return jsonResponse(itemJson(placeId: 7, name: 'Shared'), 201);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      await pumpSize(
        tester,
        testApp(
          app: app,
          child: const Scaffold(
            body: Column(
              children: [
                BookmarkButton(placeId: 7, placeName: 'Shared'),
                BookmarkButton(placeId: 7, placeName: 'Shared'),
              ],
            ),
          ),
        ),
        const Size(430, 932),
      );
      expect(find.byIcon(Icons.bookmark_border_rounded), findsNWidgets(2));
      // Tap the first; the backend confirms, then BOTH reflect saved.
      await tester.tap(find.byType(BookmarkButton).first);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_rounded), findsNWidgets(2));
      expect(app.isPlaceInRealWishlist(7), isTrue);
    });

    test('demo and real wishlist state do not leak into each other', () async {
      final app = AppState()..demoMode = true;
      final placeId = app.places.first.id;
      app.savePlace(placeId);
      expect(app.isPlaceSaved(placeId), isTrue);
      // Real-mode membership is independent and empty in demo.
      expect(app.isPlaceInRealWishlist(placeId), isFalse);
    });

    test('logout clears real wishlist so no other user data lingers', () async {
      final app = realApp(MockClient((request) async =>
          jsonResponse(wishlistJson(items: [itemJson(placeId: 7)]), 200)));
      await app.loadRealWishlist();
      expect(app.realWishlist, hasLength(1));
      await app.logout();
      expect(app.realWishlist, isEmpty);
      expect(app.realWishlistLoaded, isFalse);
      expect(app.demoMode, isTrue);
    });
  });

  // ── Widget behaviour: no optimistic flip, in-flight, session sheet ────────

  group('BookmarkButton widget', () {
    testWidgets('does not flip the icon before backend confirmation',
        (tester) async {
      ignoreNetworkImageErrors();
      final completer = Completer<http.Response>();
      final app = realApp(MockClient((request) async {
        if (request.method == 'POST') return completer.future;
        return jsonResponse(wishlistJson(), 200);
      }));
      await pumpSize(
        tester,
        testApp(
          app: app,
          child: const Scaffold(
            body: BookmarkButton(placeId: 7, placeName: 'Pending Place'),
          ),
        ),
        const Size(430, 932),
      );
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      await tester.tap(find.byType(BookmarkButton));
      await tester.pump(); // in-flight, POST not yet resolved
      // No filled bookmark yet — a progress indicator shows instead.
      expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(app.isPlaceInRealWishlist(7), isFalse);
      completer.complete(jsonResponse(itemJson(placeId: 7), 201));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });

    testWidgets('401 on a bookmark tap shows the session-expired sheet',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.method == 'POST') {
          return jsonResponse(
              errorBody(
                  401, 'Authentication required', '/api/me/wishlist/items'),
              401);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      app.email = 'real@example.com';
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpSize(
        tester,
        testApp(
          app: app,
          child: const Scaffold(
            body: BookmarkButton(placeId: 7, placeName: 'Guarded'),
          ),
        ),
        const Size(430, 932),
      );
      await tester.tap(find.byType(BookmarkButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.sessionExpiredTitle), findsOneWidget);
      // Never logged out.
      expect(app.email, 'real@example.com');
      expect(app.demoMode, isFalse);
    });

    testWidgets('exposes a localized toggle semantics label', (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(
          MockClient((request) async => jsonResponse(wishlistJson(), 200)));
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpSize(
        tester,
        testApp(
          app: app,
          child: const Scaffold(
            body: BookmarkButton(placeId: 7, placeName: 'Semantic Place'),
          ),
        ),
        const Size(430, 932),
      );
      expect(find.byTooltip(l10n.savedPlacesSaveSemantic('Semantic Place')),
          findsOneWidget);
    });
  });

  // ── Wishlist screen (Real Mode) ───────────────────────────────────────────

  group('Real Mode wishlist screen', () {
    testWidgets('renders backend items and the partial-details note',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(
            wishlistJson(items: [itemJson(placeId: 7, name: 'Backend Villa')]),
            200,
          );
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpSize(
        tester,
        testApp(app: app, child: const SavedPlacesScreen()),
        const Size(430, 932),
      );
      expect(find.text('Backend Villa'), findsOneWidget);
      expect(find.text(l10n.wishlistRealPartialDetailsNote), findsWidgets);
    });

    testWidgets('empty real wishlist shows the empty state', (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(wishlistJson(), 200);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpSize(
        tester,
        testApp(app: app, child: const SavedPlacesScreen()),
        const Size(430, 932),
      );
      expect(find.text(l10n.wishlistRealEmptyTitle), findsOneWidget);
    });

    testWidgets('load 401 on the wishlist tab shows the session sheet',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(
              errorBody(401, 'Authentication required', '/api/me/wishlist'),
              401);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpSize(
        tester,
        testApp(app: app, child: const SavedPlacesScreen()),
        const Size(430, 932),
      );
      expect(find.text(l10n.sessionExpiredTitle), findsOneWidget);
    });
  });

  // ── UI17 regression ────────────────────────────────────────────────────────

  group('UI17 regression', () {
    test('real collections still load independently of the wishlist', () async {
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/collections') {
          return jsonResponse(<Map<String, dynamic>>[
            {
              'id': 1,
              'name': 'Japan 2027',
              'description': null,
              'coverImageUrl': null,
              'privateCollection': true,
              'sortOrder': 0,
              'placeCount': 0,
              'createdAt': '2026-07-01T00:00:00Z',
              'updatedAt': '2026-07-01T00:00:00Z',
            }
          ], 200);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      expect(await app.loadRealSavedCollections(),
          SavedCollectionActionResult.success);
      expect(app.realSavedCollections, hasLength(1));
      // Wishlist load is a separate path.
      expect(await app.loadRealWishlist(), WishlistActionResult.success);
    });
  });
}
