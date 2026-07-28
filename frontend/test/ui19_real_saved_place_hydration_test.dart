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

  // Full backend `PlaceDetailResponse` shape (verified read-only against
  // Plan-Your-Trip-backend-v1).
  Map<String, dynamic> placeDetailJson({
    int id = 7,
    String name = 'Backend Villa',
    String? slug = 'backend-villa',
    String? shortDescription = 'Hillside villa',
    String? description = 'A calm hillside villa with garden views.',
    String address = '12 Trần Hưng Đạo, Đà Lạt',
    double? latitude = 11.94,
    double? longitude = 108.44,
    Map<String, dynamic>? category = const {
      'id': 3,
      'name': 'Hotels',
      'slug': 'hotels',
    },
    Map<String, dynamic>? subcategory,
    Map<String, dynamic>? location = const {
      'id': 5,
      'name': 'Đà Lạt',
      'slug': 'da-lat',
      'fullPath': 'Lâm Đồng > Đà Lạt',
    },
    double ratingAvg = 4.6,
    int ratingCount = 128,
    int priceLevel = 3,
    bool featured = true,
    bool verified = true,
    List<Map<String, dynamic>> tags = const [
      {'id': 1, 'tag': 'romantic'},
      {'id': 2, 'tag': 'view'},
    ],
    String? coverImageUrl = 'https://img.example/cover.jpg',
    List<Map<String, dynamic>> galleryImages = const [],
    Map<String, dynamic>? metadata = const {'estimatedVisitMinutes': 90},
    List<Map<String, dynamic>> groupedOpeningHours = const [
      {
        'days': 'Monday - Friday',
        'openTime': '08:00:00',
        'closeTime': '22:00:00',
        'closed': false,
      },
    ],
    Map<String, dynamic>? hotelDetail,
  }) =>
      {
        'id': id,
        'name': name,
        'slug': slug,
        'shortDescription': shortDescription,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'subcategory': subcategory,
        'location': location,
        'ratingAvg': ratingAvg,
        'ratingCount': ratingCount,
        'priceLevel': priceLevel,
        'featured': featured,
        'verified': verified,
        'status': 'PUBLISHED',
        'tags': tags,
        'amenities': const [],
        'openingHours': const [],
        'groupedOpeningHours': groupedOpeningHours,
        'coverImageUrl': coverImageUrl,
        'galleryImages': galleryImages,
        'openNow': true,
        'similarPlaces': const [],
        'metadata': metadata,
        'hotelDetail': hotelDetail,
      };

  Map<String, dynamic> wishlistItemJson({int placeId = 7, String? name}) => {
        'id': placeId + 1000,
        'place': {
          'id': placeId,
          'name': name ?? 'Backend Villa',
          'slug': 'backend-villa',
          'categoryName': 'Hotels',
          'address': '12 Trần Hưng Đạo, Đà Lạt',
          'shortDescription': 'Hillside villa',
          'ratingAvg': 4.5,
          'reviewCount': 10,
        },
        'note': null,
        'createdAt': '2026-07-20T10:00:00Z',
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

  Map<String, dynamic> collectionSummaryJson({
    int id = 1,
    String name = 'Da Lat shortlist',
    int placeCount = 1,
  }) =>
      {
        'id': id,
        'name': name,
        'description': 'Hillside stays',
        'coverImageUrl': null,
        'privateCollection': true,
        'sortOrder': 0,
        'placeCount': placeCount,
        'createdAt': '2026-07-01T00:00:00Z',
        'updatedAt': '2026-07-01T00:00:00Z',
      };

  Map<String, dynamic> collectionPlaceJson(
          {int placeId = 7, String name = 'Backend Villa'}) =>
      {
        'placeId': placeId,
        'name': name,
        'slug': 'backend-villa',
        'categoryName': 'Hotels',
        'address': '12 Trần Hưng Đạo, Đà Lạt',
        'shortDescription': 'Hillside villa',
        'ratingAvg': 4.5,
        'reviewCount': 10,
        'position': 0,
        'addedAt': '2026-07-01T00:00:00Z',
      };

  Map<String, dynamic> collectionDetailJson({
    int id = 1,
    List<Map<String, dynamic>> places = const [],
  }) =>
      {
        'id': id,
        'name': 'Da Lat shortlist',
        'description': 'Hillside stays',
        'coverImageUrl': null,
        'privateCollection': true,
        'sortOrder': 0,
        'placeCount': places.length,
        'createdAt': '2026-07-01T00:00:00Z',
        'updatedAt': '2026-07-01T00:00:00Z',
        'places': places,
      };

  AppState realApp(http.Client client) => AppState(
        api: ApiClient(client: client)..demoMode = false,
      )..demoMode = false;

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('valid detail response maps into a full Place honestly', () async {
      var path = '';
      var method = '';
      final app = realApp(MockClient((request) async {
        path = request.url.path;
        method = request.method;
        return jsonResponse(placeDetailJson(), 200);
      }));

      final outcome = await app.hydrateRealPlace(7);

      expect(outcome, PlaceHydrationResult.success);
      expect(path, '/api/places/7');
      expect(method, 'GET');
      final place = app.getHydratedRealPlace(7)!;
      expect(place.id, 7);
      expect(place.name, 'Backend Villa');
      expect(place.category, 'Hotels');
      expect(place.categorySlug, 'hotels');
      expect(place.locationName, 'Đà Lạt');
      expect(place.city, 'Đà Lạt');
      expect(place.province, 'Lâm Đồng'); // parent of fullPath, not fabricated
      expect(place.rating, 4.6);
      expect(place.reviewCount, 128);
      expect(place.priceLevel, r'$$$'); // priceLevel 3 -> three markers
      expect(place.estimatedDurationMinutes, 90);
      expect(place.imageUrl, 'https://img.example/cover.jpg');
      expect(place.tags, containsAll(<String>['romantic', 'view']));
      expect(place.isFeatured, isTrue);
      expect(place.verified, isTrue);
      expect(place.openingHours, contains('Monday - Friday'));
      expect(place.openingHours, contains('08:00'));
    });

    test('null/optional fields degrade to honest neutral defaults', () async {
      final app = realApp(MockClient((request) async => jsonResponse(
            placeDetailJson(
              shortDescription: null,
              description: null,
              metadata: null,
              coverImageUrl: null,
              galleryImages: const [],
              latitude: null,
              longitude: null,
              groupedOpeningHours: const [],
            ),
            200,
          )));

      await app.hydrateRealPlace(7);
      final place = app.getHydratedRealPlace(7)!;
      expect(place.description, ''); // no description/shortDescription
      expect(place.imageUrl, ''); // no cover, empty gallery -> placeholder
      expect(place.latitude, isNull);
      expect(place.estimatedDurationMinutes, 60); // model default = unknown
      expect(place.openingHours, isNull); // no open groups
      expect(place.hotelDetail, isNull);
    });

    test('empty gallery with no cover yields an empty imageUrl', () async {
      final app = realApp(MockClient((request) async => jsonResponse(
            placeDetailJson(coverImageUrl: null, galleryImages: const []),
            200,
          )));
      await app.hydrateRealPlace(7);
      expect(app.getHydratedRealPlace(7)!.imageUrl, '');
    });

    test('gallery first image is used when no cover is set', () async {
      final app = realApp(MockClient((request) async => jsonResponse(
            placeDetailJson(coverImageUrl: null, galleryImages: const [
              {
                'id': 1,
                'url': 'https://img/g1.jpg',
                'sortOrder': 0,
                'cover': false
              },
            ]),
            200,
          )));
      await app.hydrateRealPlace(7);
      expect(app.getHydratedRealPlace(7)!.imageUrl, 'https://img/g1.jpg');
    });

    test('hotel detail is mapped from provided fields without fabrication',
        () async {
      final app = realApp(MockClient((request) async => jsonResponse(
            placeDetailJson(hotelDetail: {
              'id': 1,
              'starRating': 5,
              'checkInTime': '14:00:00',
              'checkOutTime': '12:00:00',
              'breakfastIncluded': true,
              'airportShuttle': false,
              'facilities': [
                {'id': 1, 'facilityName': 'Pool'},
              ],
              'services': [
                {'id': 1, 'serviceName': 'Concierge'},
              ],
              'languages': ['English', 'Vietnamese'],
              'paymentMethods': ['VISA'],
              'parking': {
                'parkingAvailable': true,
                'parkingDescription': 'Free lot'
              },
              'internet': {
                'wifiAvailable': true,
                'internetDescription': 'Free WiFi'
              },
              'rooms': [
                {
                  'id': 9,
                  'roomName': 'Deluxe King',
                  'roomCode': 'DLX',
                  'roomType': 'DELUXE',
                  'bedType': 'KING',
                  'priceFrom': 1200000,
                },
              ],
            }),
            200,
          )));

      await app.hydrateRealPlace(7);
      final detail = app.getHydratedRealPlace(7)!.hotelDetail!;
      expect(detail.starRating, 5);
      expect(detail.checkInTime, '14:00'); // trimmed from HH:mm:ss
      expect(detail.breakfastIncluded, isTrue);
      expect(detail.facilities, ['Pool']);
      expect(detail.services, ['Concierge']);
      expect(detail.parking, 'Free lot');
      expect(detail.internet, 'Free WiFi');
      expect(detail.rooms.single.roomType, RoomType.deluxe);
      expect(detail.rooms.single.bedType, BedType.king);
      expect(
          detail.rooms.single.ratePlans, isEmpty); // deferred, not fabricated
    });

    test('404 maps to notFound and caches nothing', () async {
      final app = realApp(MockClient((request) async => jsonResponse(
          errorBody(404, 'Place not found', '/api/places/7'), 404)));
      expect(await app.hydrateRealPlace(7), PlaceHydrationResult.notFound);
      expect(app.getHydratedRealPlace(7), isNull);
    });

    test('5xx maps to serverError', () async {
      final app = realApp(MockClient((request) async =>
          jsonResponse(errorBody(500, 'boom', '/api/places/7'), 500)));
      expect(await app.hydrateRealPlace(7), PlaceHydrationResult.serverError);
    });

    test('network failure maps to network', () async {
      final app = realApp(MockClient((request) async {
        throw http.ClientException('offline');
      }));
      expect(await app.hydrateRealPlace(7), PlaceHydrationResult.network);
    });

    test('malformed (non-object) body is not treated as success', () async {
      final app = realApp(
          MockClient((request) async => jsonResponse(<dynamic>[], 200)));
      final outcome = await app.hydrateRealPlace(7);
      expect(outcome, isNot(PlaceHydrationResult.success));
      expect(app.getHydratedRealPlace(7), isNull);
    });
  });

  // ── Hydration cache ────────────────────────────────────────────────────────

  group('Hydration cache', () {
    test('first request calls the API, second reuses the cache', () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(placeDetailJson(), 200);
      }));

      expect(await app.hydrateRealPlace(7), PlaceHydrationResult.success);
      expect(await app.hydrateRealPlace(7), PlaceHydrationResult.success);
      expect(calls, 1, reason: 'cached place must not re-hit the network');
    });

    test('concurrent callers share a single in-flight request', () async {
      var calls = 0;
      final completer = Completer<http.Response>();
      final app = realApp(MockClient((request) async {
        calls++;
        return completer.future;
      }));

      final f1 = app.hydrateRealPlace(7);
      final f2 = app.hydrateRealPlace(7);
      expect(app.isRealPlaceHydrationInFlight(7), isTrue);
      completer.complete(jsonResponse(placeDetailJson(), 200));
      expect(await f1, PlaceHydrationResult.success);
      expect(await f2, PlaceHydrationResult.success);
      expect(calls, 1, reason: 'duplicate concurrent taps must dedupe');
      expect(app.isRealPlaceHydrationInFlight(7), isFalse);
    });

    test('failed hydration is not cached and a retry can succeed', () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        if (calls == 1) {
          return jsonResponse(errorBody(500, 'boom', '/api/places/7'), 500);
        }
        return jsonResponse(placeDetailJson(), 200);
      }));

      expect(await app.hydrateRealPlace(7), PlaceHydrationResult.serverError);
      expect(app.getHydratedRealPlace(7), isNull);
      expect(await app.hydrateRealPlace(7), PlaceHydrationResult.success);
      expect(calls, 2, reason: 'retry must actually re-issue the request');
      expect(app.getHydratedRealPlace(7), isNotNull);
    });

    test('logout clears the hydration cache', () async {
      final app = realApp(
          MockClient((request) async => jsonResponse(placeDetailJson(), 200)));
      await app.hydrateRealPlace(7);
      expect(app.getHydratedRealPlace(7), isNotNull);

      await app.logout();

      expect(app.getHydratedRealPlace(7), isNull);
    });

    test('Demo Mode never issues a hydration request', () async {
      var calls = 0;
      final app = AppState(
        api: ApiClient(client: MockClient((request) async {
          calls++;
          return jsonResponse(placeDetailJson(), 200);
        })),
      );
      // Default AppState is demo mode.
      expect(app.demoMode, isTrue);
      expect(await app.hydrateRealPlace(7), PlaceHydrationResult.unavailable);
      expect(calls, 0);
      expect(app.getHydratedRealPlace(7), isNull);
    });
  });

  // ── Wishlist: hydrate-then-navigate ─────────────────────────────────────────

  group('Wishlist hydration actions', () {
    Future<void> pumpWishlist(
      WidgetTester tester,
      AppState app,
    ) async {
      await pumpSize(
        tester,
        testApp(app: app, child: const SavedPlacesScreen()),
        const Size(430, 932),
      );
    }

    testWidgets('View Details hydrates then navigates to the detail screen',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(
              wishlistJson(items: [wishlistItemJson(placeId: 7)]), 200);
        }
        if (request.url.path == '/api/places/7') {
          return jsonResponse(placeDetailJson(), 200);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      await pumpWishlist(tester, app);

      await tester.tap(find.byKey(const Key('real-wishlist-place-details-7')));
      await tester.pumpAndSettle();

      // The pushed PlaceDetailScreen renders the hero image with this key.
      expect(find.byKey(const Key('place-detail-image')), findsOneWidget);
    });

    testWidgets('failed hydration stays on the wishlist and keeps membership',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(
              wishlistJson(items: [wishlistItemJson(placeId: 7)]), 200);
        }
        if (request.url.path == '/api/places/7') {
          return jsonResponse(
              errorBody(404, 'Place not found', '/api/places/7'), 404);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpWishlist(tester, app);

      await tester.tap(find.byKey(const Key('real-wishlist-place-details-7')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('place-detail-image')), findsNothing);
      expect(find.byKey(const Key('real-wishlist-item-7')), findsOneWidget);
      expect(find.text(l10n.placeHydrationUnavailableMessage), findsOneWidget);
      expect(app.isPlaceInRealWishlist(7), isTrue,
          reason: 'a failed hydration must not remove the saved item');
    });

    testWidgets('a double tap issues only one hydration request',
        (tester) async {
      ignoreNetworkImageErrors();
      var placeCalls = 0;
      final completer = Completer<http.Response>();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(
              wishlistJson(items: [wishlistItemJson(placeId: 7)]), 200);
        }
        if (request.url.path == '/api/places/7') {
          placeCalls++;
          return completer.future;
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      await pumpWishlist(tester, app);

      final button = find.byKey(const Key('real-wishlist-place-details-7'));
      await tester.tap(button);
      await tester.pump();
      // Button is now disabled/in-flight; a second tap must not re-issue.
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();

      expect(placeCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete(jsonResponse(placeDetailJson(), 200));
      await tester.pumpAndSettle();
    });

    testWidgets('Add to trip hydrates before opening the sheet',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(
              wishlistJson(items: [wishlistItemJson(placeId: 7)]), 200);
        }
        if (request.url.path == '/api/places/7') {
          return jsonResponse(placeDetailJson(), 200);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpWishlist(tester, app);

      await tester.tap(find.byKey(const Key('real-wishlist-place-add-trip-7')));
      await tester.pumpAndSettle();

      expect(app.getHydratedRealPlace(7), isNotNull);
      expect(find.text(l10n.quickAddTitle), findsOneWidget);
    });
  });

  // ── Saved Collections: hydrate-then-navigate ────────────────────────────────

  group('Collection hydration actions', () {
    testWidgets('View Details on a collection place hydrates then navigates',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/me/wishlist') {
          return jsonResponse(wishlistJson(), 200);
        }
        if (path == '/api/me/collections') {
          return jsonResponse([collectionSummaryJson(id: 1)], 200);
        }
        if (path == '/api/me/collections/1') {
          return jsonResponse(
              collectionDetailJson(
                  id: 1, places: [collectionPlaceJson(placeId: 7)]),
              200);
        }
        if (path == '/api/places/7') {
          return jsonResponse(placeDetailJson(), 200);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      await pumpSize(
        tester,
        testApp(app: app, child: const SavedPlacesScreen()),
        const Size(430, 932),
      );

      await tester.tap(find.byKey(const Key('saved-places-tab-collections')));
      await tester.pumpAndSettle();
      final openBtn = find.byKey(const Key('real-collection-open-1'));
      await tester.ensureVisible(openBtn);
      await tester.pumpAndSettle();
      await tester.tap(openBtn);
      await tester.pumpAndSettle();

      final details = find.byKey(const Key('real-collection-place-details-7'));
      await tester.ensureVisible(details);
      await tester.pumpAndSettle();
      await tester.tap(details);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('place-detail-image')), findsOneWidget);
    });

    testWidgets('missing collection place surfaces an honest error, no nav',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/me/wishlist') {
          return jsonResponse(wishlistJson(), 200);
        }
        if (path == '/api/me/collections') {
          return jsonResponse([collectionSummaryJson(id: 1)], 200);
        }
        if (path == '/api/me/collections/1') {
          return jsonResponse(
              collectionDetailJson(
                  id: 1, places: [collectionPlaceJson(placeId: 7)]),
              200);
        }
        if (path == '/api/places/7') {
          return jsonResponse(
              errorBody(404, 'Place not found', '/api/places/7'), 404);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpSize(
        tester,
        testApp(app: app, child: const SavedPlacesScreen()),
        const Size(430, 932),
      );

      await tester.tap(find.byKey(const Key('saved-places-tab-collections')));
      await tester.pumpAndSettle();
      final openBtn = find.byKey(const Key('real-collection-open-1'));
      await tester.ensureVisible(openBtn);
      await tester.pumpAndSettle();
      await tester.tap(openBtn);
      await tester.pumpAndSettle();
      final details = find.byKey(const Key('real-collection-place-details-7'));
      await tester.ensureVisible(details);
      await tester.pumpAndSettle();
      await tester.tap(details);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('place-detail-image')), findsNothing);
      expect(find.text(l10n.placeHydrationUnavailableMessage), findsOneWidget);
    });
  });

  // ── Session behaviour ───────────────────────────────────────────────────────

  group('Session behaviour', () {
    test('a 401 during hydration is surfaced without logging out', () async {
      final app = realApp(MockClient((request) async => jsonResponse(
            errorBody(401, 'Authentication required', '/api/places/7'),
            401,
          )))
        ..email = 'real@example.com';
      app.api.token = 'stale-token';

      final outcome = await app.hydrateRealPlace(7);

      expect(outcome, PlaceHydrationResult.sessionExpired);
      expect(app.email, 'real@example.com', reason: 'logout() must not run');
      expect(app.api.token, 'stale-token');
      expect(app.demoMode, isFalse);
      expect(app.getHydratedRealPlace(7), isNull);
    });

    testWidgets('a 401 during hydration shows the session-expired sheet',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/wishlist') {
          return jsonResponse(
              wishlistJson(items: [wishlistItemJson(placeId: 7)]), 200);
        }
        if (request.url.path == '/api/places/7') {
          return jsonResponse(
              errorBody(401, 'Authentication required', '/api/places/7'), 401);
        }
        return jsonResponse(wishlistJson(), 200);
      }));
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpSize(
        tester,
        testApp(app: app, child: const SavedPlacesScreen()),
        const Size(430, 932),
      );

      await tester.tap(find.byKey(const Key('real-wishlist-place-details-7')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.sessionExpiredTitle), findsOneWidget);
    });
  });

  // ── Localization parity ─────────────────────────────────────────────────────

  test('UI19 hydration strings hold EN/VI parity', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final vi = await AppLocalizations.delegate.load(const Locale('vi'));
    expect(en.placeHydrationUnavailableMessage.isNotEmpty, isTrue);
    expect(vi.placeHydrationUnavailableMessage.isNotEmpty, isTrue);
    expect(en.placeHydrationErrorMessage.isNotEmpty, isTrue);
    expect(vi.placeHydrationErrorMessage.isNotEmpty, isTrue);
    expect(en.placeHydrationLoadingSemantic('X').isNotEmpty, isTrue);
    expect(vi.placeHydrationLoadingSemantic('X').isNotEmpty, isTrue);
    expect(
      en.placeHydrationUnavailableMessage,
      isNot(vi.placeHydrationUnavailableMessage),
      reason: 'VI should be a real translation, not the EN string',
    );
  });
}
