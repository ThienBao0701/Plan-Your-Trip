import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  Map<String, dynamic> summaryJson({
    int id = 1,
    String name = 'Da Lat shortlist',
    String? description = 'Hillside stays and coffee',
    String? coverImageUrl,
    bool privateCollection = true,
    int sortOrder = 0,
    int placeCount = 0,
    String createdAt = '2026-07-01T00:00:00Z',
    String updatedAt = '2026-07-01T00:00:00Z',
  }) =>
      {
        'id': id,
        'name': name,
        'description': description,
        'coverImageUrl': coverImageUrl,
        'privateCollection': privateCollection,
        'sortOrder': sortOrder,
        'placeCount': placeCount,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  Map<String, dynamic> placeJson({
    int placeId = 1,
    String name = 'Mây Lang Thang Villa',
    String slug = 'may-lang-thang-villa',
    String? categoryName = 'Hotels',
    String? address = '12 Trần Hưng Đạo, Đà Lạt',
    String? shortDescription = 'Hillside villa',
    double ratingAvg = 4.5,
    int reviewCount = 10,
    int position = 0,
    String addedAt = '2026-07-01T00:00:00Z',
  }) =>
      {
        'placeId': placeId,
        'name': name,
        'slug': slug,
        'categoryName': categoryName,
        'address': address,
        'shortDescription': shortDescription,
        'ratingAvg': ratingAvg,
        'reviewCount': reviewCount,
        'position': position,
        'addedAt': addedAt,
      };

  Map<String, dynamic> detailJson({
    int id = 1,
    String name = 'Da Lat shortlist',
    String? description = 'Hillside stays and coffee',
    String? coverImageUrl,
    bool privateCollection = true,
    int sortOrder = 0,
    List<Map<String, dynamic>> places = const [],
    String createdAt = '2026-07-01T00:00:00Z',
    String updatedAt = '2026-07-01T00:00:00Z',
  }) =>
      {
        'id': id,
        'name': name,
        'description': description,
        'coverImageUrl': coverImageUrl,
        'privateCollection': privateCollection,
        'sortOrder': sortOrder,
        'placeCount': places.length,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'places': places,
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

  group('list collections', () {
    test('loading then ready populates typed summaries in server order',
        () async {
      var calls = 0;
      final app = realApp(
        MockClient((request) async {
          calls++;
          expect(request.method, 'GET');
          expect(request.url.path, '/api/me/collections');
          return jsonResponse([
            summaryJson(id: 2, name: 'B', sortOrder: 1, placeCount: 3),
            summaryJson(id: 1, name: 'A', sortOrder: 0, placeCount: 0),
          ], 200);
        }),
      );

      expect(app.realSavedCollectionsLoading, isFalse);
      final future = app.loadRealSavedCollections();
      expect(app.realSavedCollectionsLoading, isTrue);
      final outcome = await future;

      expect(outcome, SavedCollectionActionResult.success);
      expect(calls, 1);
      expect(app.realSavedCollectionsLoading, isFalse);
      expect(app.realSavedCollections.map((c) => c.id), [2, 1]);
      expect(app.realSavedCollections.first.placeCount, 3);
    });

    test('empty list is a legitimate ready state, not fabricated', () async {
      final app = realApp(MockClient((request) async => jsonResponse([], 200)));
      final outcome = await app.loadRealSavedCollections();
      expect(outcome, SavedCollectionActionResult.success);
      expect(app.realSavedCollections, isEmpty);
      expect(app.realSavedCollectionsLoaded, isTrue);
    });

    test('network timeout preserves prior state and reports network', () async {
      var calls = 0;
      final app = realApp(
        MockClient((request) async {
          calls++;
          if (calls == 1) return jsonResponse([summaryJson()], 200);
          throw TimeoutException('simulated timeout');
        }),
      );

      await app.loadRealSavedCollections();
      expect(app.realSavedCollections, hasLength(1));

      final outcome = await app.loadRealSavedCollections(refresh: true);
      expect(outcome, SavedCollectionActionResult.network);
      expect(
        app.realSavedCollections,
        hasLength(1),
        reason: 'stale data must be preserved on a failed refresh',
      );
    });

    test('5xx maps to serverError', () async {
      final app = realApp(
        MockClient(
          (request) async =>
              jsonResponse(errorBody(500, 'boom', '/api/me/collections'), 500),
        ),
      );
      expect(
        await app.loadRealSavedCollections(),
        SavedCollectionActionResult.serverError,
      );
    });

    test('401 signals unauthenticated without logout or state loss', () async {
      final app = realApp(
        MockClient(
          (request) async => jsonResponse(
            errorBody(401, 'Authentication required', '/api/me/collections'),
            401,
          ),
        ),
      )..email = 'real@example.com';
      app.api.token = 'stale-token';

      final outcome = await app.loadRealSavedCollections();

      expect(outcome, SavedCollectionActionResult.unauthenticated);
      expect(app.email, 'real@example.com', reason: 'logout() must not run');
      expect(app.api.token, 'stale-token');
      expect(app.demoMode, isFalse);
    });

    test('pull-to-refresh re-issues the request even when already loaded',
        () async {
      var calls = 0;
      final app = realApp(
        MockClient((request) async {
          calls++;
          return jsonResponse([summaryJson(placeCount: calls)], 200);
        }),
      );
      await app.loadRealSavedCollections();
      expect(calls, 1);
      await app.loadRealSavedCollections();
      expect(calls, 1, reason: 'already-loaded list is cached without refresh');
      await app.loadRealSavedCollections(refresh: true);
      expect(calls, 2);
      expect(app.realSavedCollections.first.placeCount, 2);
    });

    test('no double submission while a list request is in flight', () async {
      var calls = 0;
      final completer = Completer<http.Response>();
      final app = realApp(
        MockClient((request) async {
          calls++;
          return completer.future;
        }),
      );

      final first = app.loadRealSavedCollections();
      final second = app.loadRealSavedCollections();
      completer.complete(jsonResponse([], 200));
      await Future.wait([first, second]);

      expect(calls, 1);
    });
  });

  group('collection detail', () {
    test('200 keeps places in backend position order', () async {
      final app = realApp(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/me/collections/7');
          return jsonResponse(
            detailJson(
              id: 7,
              places: [
                placeJson(placeId: 10, position: 0),
                placeJson(placeId: 11, position: 1),
              ],
            ),
            200,
          );
        }),
      );

      final outcome = await app.loadRealCollectionDetail(7);
      expect(outcome, SavedCollectionActionResult.success);
      expect(
        app.realSelectedCollectionDetail?.places.map((p) => p.placeId),
        [10, 11],
      );
    });

    test('404 for an unknown id maps to collectionNotFound', () async {
      final app = realApp(
        MockClient(
          (request) async => jsonResponse(
            errorBody(
                404, 'Collection not found: 999', '/api/me/collections/999'),
            404,
          ),
        ),
      );
      expect(
        await app.loadRealCollectionDetail(999),
        SavedCollectionActionResult.collectionNotFound,
      );
    });

    test(
        '404 for a foreign collection also maps to collectionNotFound, never forbidden',
        () async {
      final app = realApp(
        MockClient(
          (request) async => jsonResponse(
            errorBody(404, 'Collection not found: 5', '/api/me/collections/5'),
            404,
          ),
        ),
      );
      final outcome = await app.loadRealCollectionDetail(5);
      expect(outcome, SavedCollectionActionResult.collectionNotFound);
      expect(outcome, isNot(SavedCollectionActionResult.unavailable));
    });
  });

  group('create collection', () {
    test('201 upserts the new summary into the real list', () async {
      final app = realApp(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/me/collections');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['name'], 'Japan 2027');
          return jsonResponse(detailJson(id: 42, name: 'Japan 2027'), 201);
        }),
      );

      final outcome = await app.createRealSavedCollection(name: 'Japan 2027');
      expect(outcome, SavedCollectionActionResult.success);
      expect(app.realSavedCollections.single.id, 42);
    });

    test('blank/overlong fields are rejected before any network call',
        () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(detailJson(), 201);
      }));

      expect(
        await app.createRealSavedCollection(name: '   '),
        SavedCollectionActionResult.invalidName,
      );
      expect(
        await app.createRealSavedCollection(
          name: 'x' * (SavedCollectionRecord.maxNameLength + 1),
        ),
        SavedCollectionActionResult.invalidName,
      );
      expect(
        await app.createRealSavedCollection(
          name: 'Valid',
          description: 'x' * (SavedCollectionRecord.maxDescriptionLength + 1),
        ),
        SavedCollectionActionResult.invalidDescription,
      );
      expect(
        await app.createRealSavedCollection(
          name: 'Valid',
          coverImageUrl:
              'x' * (SavedCollectionRecord.maxCoverImageUrlLength + 1),
        ),
        SavedCollectionActionResult.invalidCover,
      );
      expect(calls, 0);
    });

    test('409 collection limit maps to collectionLimitReached', () async {
      final app = realApp(
        MockClient(
          (request) async => jsonResponse(
            errorBody(
              409,
              'You have reached the maximum of 100 collections',
              '/api/me/collections',
            ),
            409,
          ),
        ),
      );
      expect(
        await app.createRealSavedCollection(name: 'One too many'),
        SavedCollectionActionResult.collectionLimitReached,
      );
    });

    test('no double submission while a create request is in flight', () async {
      var calls = 0;
      final completer = Completer<http.Response>();
      final app = realApp(
        MockClient((request) async {
          calls++;
          return completer.future;
        }),
      );

      final first = app.createRealSavedCollection(name: 'First');
      final second = app.createRealSavedCollection(name: 'Second');
      completer.complete(jsonResponse(detailJson(name: 'First'), 201));
      await Future.wait([first, second]);

      expect(calls, 1);
    });
  });

  group('update collection', () {
    test('200 always sends the full name/description/coverImageUrl payload',
        () async {
      Map<String, dynamic>? sentBody;
      final app = realApp(
        MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/me/collections/3');
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return jsonResponse(
            detailJson(
              id: 3,
              name: 'Renamed',
              description: 'New description',
              coverImageUrl: 'https://example.com/cover.jpg',
            ),
            200,
          );
        }),
      );

      final outcome = await app.updateRealSavedCollection(
        collectionId: 3,
        name: 'Renamed',
        description: 'New description',
        coverImageUrl: 'https://example.com/cover.jpg',
        privateCollection: false,
        sortOrder: 2,
      );

      expect(outcome, SavedCollectionActionResult.success);
      expect(sentBody, isNotNull);
      expect(sentBody!['name'], 'Renamed');
      expect(sentBody!['description'], 'New description');
      expect(sentBody!['coverImageUrl'], 'https://example.com/cover.jpg');
      expect(sentBody!['privateCollection'], isFalse);
      expect(sentBody!['sortOrder'], 2);
    });

    test('404 maps to collectionNotFound', () async {
      final app = realApp(
        MockClient(
          (request) async => jsonResponse(
            errorBody(404, 'Collection not found: 9', '/api/me/collections/9'),
            404,
          ),
        ),
      );
      expect(
        await app.updateRealSavedCollection(
          collectionId: 9,
          name: 'X',
          privateCollection: true,
          sortOrder: 0,
        ),
        SavedCollectionActionResult.collectionNotFound,
      );
    });
  });

  group('delete collection', () {
    test('204 removes the collection from the real list', () async {
      final app = realApp(
        MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/api/me/collections/4');
          return http.Response('', 204);
        }),
      );
      await app.loadRealSavedCollections();
      app.realSavedCollections =
          [summaryJson(id: 4)].map(CollectionSummaryRecord.fromJson).toList();

      final outcome = await app.deleteRealSavedCollection(4);
      expect(outcome, SavedCollectionActionResult.success);
      expect(app.realSavedCollections, isEmpty);
    });
  });

  group('add place to collection', () {
    test('201 appends the returned place and bumps the local count', () async {
      final app = realApp(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/me/collections/1/places/5');
          return jsonResponse(placeJson(placeId: 5), 201);
        }),
      );
      app.realSavedCollections = [summaryJson(id: 1, placeCount: 0)]
          .map(CollectionSummaryRecord.fromJson)
          .toList();

      final outcome =
          await app.addRealCollectionPlace(collectionId: 1, placeId: 5);
      expect(outcome, SavedCollectionActionResult.success);
      expect(app.realSavedCollections.single.placeCount, 1);
    });

    test('409 with unknown local count maps to duplicateItem', () async {
      final app = realApp(
        MockClient(
          (request) async => jsonResponse(
            errorBody(
              409,
              'This place is already in the collection',
              '/api/me/collections/1/places/5',
            ),
            409,
          ),
        ),
      );
      expect(
        await app.addRealCollectionPlace(collectionId: 1, placeId: 5),
        SavedCollectionActionResult.duplicateItem,
      );
    });

    test(
        'locally-known placeCount at the cap short-circuits to itemLimitReached '
        'without a network call', () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(placeJson(), 201);
      }));
      app.realSavedCollections = [
        summaryJson(
          id: 1,
          placeCount: SavedCollectionPlaceRecord.maxPlacesPerCollection,
        ),
      ].map(CollectionSummaryRecord.fromJson).toList();

      final outcome =
          await app.addRealCollectionPlace(collectionId: 1, placeId: 5);
      expect(outcome, SavedCollectionActionResult.itemLimitReached);
      expect(calls, 0);
    });

    test('404 place not found maps to placeNotFound', () async {
      final app = realApp(
        MockClient(
          (request) async => jsonResponse(
            errorBody(
              404,
              'Place not found: 999',
              '/api/me/collections/1/places/999',
            ),
            404,
          ),
        ),
      );
      expect(
        await app.addRealCollectionPlace(collectionId: 1, placeId: 999),
        SavedCollectionActionResult.placeNotFound,
      );
    });
  });

  group('remove place from collection', () {
    test('204 removes the place and decrements the local count', () async {
      final app = realApp(
        MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/api/me/collections/1/places/5');
          return http.Response('', 204);
        }),
      );
      app.realSavedCollections = [summaryJson(id: 1, placeCount: 1)]
          .map(CollectionSummaryRecord.fromJson)
          .toList();

      final outcome =
          await app.removeRealCollectionPlace(collectionId: 1, placeId: 5);
      expect(outcome, SavedCollectionActionResult.success);
      expect(app.realSavedCollections.single.placeCount, 0);
    });

    test('404 not-in-collection maps to itemNotFound', () async {
      final app = realApp(
        MockClient(
          (request) async => jsonResponse(
            errorBody(
              404,
              'Place not in collection: 5',
              '/api/me/collections/1/places/5',
            ),
            404,
          ),
        ),
      );
      expect(
        await app.removeRealCollectionPlace(collectionId: 1, placeId: 5),
        SavedCollectionActionResult.itemNotFound,
      );
    });
  });

  group('Demo Mode isolation', () {
    test('Demo Mode issues zero HTTP calls for any real collection method',
        () async {
      var calls = 0;
      final app = AppState(
        api: ApiClient(client: MockClient((request) async {
          calls++;
          return jsonResponse([], 200);
        })),
      )..demoMode = true;

      expect(
        await app.loadRealSavedCollections(),
        SavedCollectionActionResult.unavailable,
      );
      expect(
        await app.loadRealCollectionDetail(1),
        SavedCollectionActionResult.unavailable,
      );
      expect(
        await app.createRealSavedCollection(name: 'X'),
        SavedCollectionActionResult.unavailable,
      );
      expect(
        await app.updateRealSavedCollection(
          collectionId: 1,
          name: 'X',
          privateCollection: true,
          sortOrder: 0,
        ),
        SavedCollectionActionResult.unavailable,
      );
      expect(
        await app.deleteRealSavedCollection(1),
        SavedCollectionActionResult.unavailable,
      );
      expect(
        await app.addRealCollectionPlace(collectionId: 1, placeId: 1),
        SavedCollectionActionResult.unavailable,
      );
      expect(
        await app.removeRealCollectionPlace(collectionId: 1, placeId: 1),
        SavedCollectionActionResult.unavailable,
      );

      expect(calls, 0);
    });
  });

  group('Wishlist regression guard', () {
    test('demo Wishlist behaviour is unchanged by the UI-17 collections wiring',
        () {
      final app = AppState();
      expect(app.visibleSavedPlaces, isNotEmpty);
      final placeId = app.visibleSavedPlaces.first.placeId;
      expect(app.isPlaceSaved(placeId), isTrue);
      expect(
        app.removeSavedPlace(placeId),
        SavedPlaceActionResult.success,
      );
      expect(app.isPlaceSaved(placeId), isFalse);
    });

    test('real mode Wishlist stays unavailable regardless of collections state',
        () async {
      final app = realApp(MockClient((request) async => jsonResponse([], 200)));
      await app.loadRealSavedCollections();
      expect(
        app.savePlace(1),
        SavedPlaceActionResult.unavailable,
      );
      expect(app.visibleSavedPlaces, isEmpty);
    });
  });

  group('widget flows', () {
    testWidgets(
        'dialog values are preserved after a recoverable create error, then succeed',
        (tester) async {
      ignoreNetworkImageErrors();
      var calls = 0;
      final app = realApp(MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse([], 200);
        }
        calls++;
        if (calls == 1) {
          throw TimeoutException('simulated');
        }
        return jsonResponse(detailJson(id: 1, name: 'Retry Trip'), 201);
      }));

      await pumpSize(
        tester,
        testApp(child: const SavedPlacesScreen(), app: app),
        const Size(430, 932),
      );

      await tester.tap(find.byKey(const Key('saved-places-tab-collections')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('real-collection-create')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('saved-collection-name-field')),
        'Retry Trip',
      );
      await tester.enterText(
        find.byKey(const Key('saved-collection-description-field')),
        'Kept across the retry',
      );
      await tester.tap(find.byKey(const Key('saved-collection-save')));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.text('Retry Trip'), findsOneWidget);
      expect(find.text('Kept across the retry'), findsOneWidget);

      await tester.tap(find.byKey(const Key('saved-collection-save')));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(app.realSavedCollections, hasLength(1));
    });

    testWidgets('real collections empty state renders without a fake success',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async => jsonResponse([], 200)));

      await pumpSize(
        tester,
        testApp(child: const SavedPlacesScreen(), app: app),
        const Size(430, 932),
      );

      await tester.tap(find.byKey(const Key('saved-places-tab-collections')));
      await tester.pumpAndSettle();

      expect(find.text('No collections yet'), findsOneWidget);
    });

    testWidgets('401 while viewing collections shows the session-expired sheet',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(
        MockClient(
          (request) async => jsonResponse(
            errorBody(401, 'Authentication required', '/api/me/collections'),
            401,
          ),
        ),
      );

      await pumpSize(
        tester,
        testApp(child: const SavedPlacesScreen(), app: app),
        const Size(430, 932),
      );

      await tester.tap(find.byKey(const Key('saved-places-tab-collections')));
      await tester.pumpAndSettle();

      expect(find.text('Session expired'), findsOneWidget);
    });
  });

  test('English and Vietnamese UI-17 collection strings hold parity', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vi = jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
        as Map<String, dynamic>;

    const newKeys = [
      'savedPlacesCollectionNetworkErrorMessage',
      'savedPlacesCollectionServerErrorMessage',
      'savedPlacesCollectionUnauthenticatedMessage',
      'savedPlacesCollectionPlaceHydrationMessage',
      'savedPlacesCollectionAddPlaceDeferredTitle',
      'savedPlacesCollectionAddPlaceDeferredMessage',
      'savedPlacesCollectionsBoundaryMessage',
      'savedPlacesRealEmptyMessage',
    ];
    for (final key in newKeys) {
      expect(en.containsKey(key), isTrue, reason: 'missing EN key $key');
      expect(vi.containsKey(key), isTrue, reason: 'missing VI key $key');
      expect((en[key] as String).isNotEmpty, isTrue);
      expect((vi[key] as String).isNotEmpty, isTrue);
    }
  });
}
