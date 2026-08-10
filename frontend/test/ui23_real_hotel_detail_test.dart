import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/places/place_detail_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
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

  AppState realApp(http.Client client) => AppState(
        api: ApiClient(client: client)..demoMode = false,
      )..demoMode = false;

  AppState demoApp(http.Client client) =>
      AppState(api: ApiClient(client: client));

  // ── Backend PlaceDetailResponse fixtures (verified vs Plan-Your-Trip-backend-v1)

  Map<String, dynamic> hotelDetailJson() => {
        'id': 1,
        'starRating': 5,
        'checkInTime': '14:00:00',
        'checkOutTime': '12:00:00',
        'distanceToBeachMeters': 300,
        'distanceToCityCenterMeters': 1200,
        'totalRooms': 80,
        'availableRooms': 12,
        'freeCancellation': true,
        'cancellationPolicy': 'Free cancellation until 24h before check-in.',
        'prepaymentRequired': false,
        'paymentPolicy': 'Pay at the property.',
        'childrenPolicy': 'Children of all ages are welcome.',
        'petPolicy': 'Pets are not allowed.',
        'smokingPolicy': 'Non-smoking rooms available.',
        'breakfastIncluded': true,
        'airportShuttle': false,
        'facilities': [
          {
            'id': 1,
            'facilityName': 'Outdoor pool',
            'facilityGroup': 'OUTDOOR',
            'icon': 'pool',
            'sortOrder': 1
          },
          {
            'id': 2,
            'facilityName': 'Spa',
            'facilityGroup': 'WELLNESS',
            'icon': 'spa',
            'sortOrder': 0
          },
          {
            'id': 3,
            'facilityName': 'Front desk',
            'facilityGroup': null,
            'icon': null,
            'sortOrder': 2
          },
        ],
        'services': [
          {
            'id': 1,
            'serviceName': 'Concierge',
            'icon': null,
            'available': true
          },
          {
            'id': 2,
            'serviceName': 'Room service',
            'icon': null,
            'available': false
          },
        ],
        'languages': ['English', 'Vietnamese'],
        'paymentMethods': ['VISA', 'Cash'],
        'parking': {
          'parkingAvailable': true,
          'parkingFree': true,
          'parkingDescription': 'On-site private parking.'
        },
        'internet': {
          'wifiAvailable': true,
          'wifiFree': true,
          'internetDescription': 'Wi-Fi in all areas.'
        },
        'rooms': [
          {
            'id': 100,
            'roomName': 'Deluxe Garden View',
            'roomCode': 'DLX',
            'roomType': 'DELUXE',
            'bedType': 'KING',
            'bedCount': 1,
            'maxAdults': 2,
            'maxChildren': 1,
            'maxGuests': 2,
            'roomSizeSqm': 32,
            'breakfastIncluded': true,
            'freeCancellation': true,
            'instantConfirmation': true,
            'priceFrom': 1200000,
            'originalPrice': 1500000,
            'quantity': 5,
            'availableQuantity': 3,
            'active': true,
            'amenities': [
              {'id': 1, 'name': 'Wi-Fi', 'slug': 'wifi'},
            ],
            'coverImageUrl': 'https://img.example/room.jpg',
            'galleryImages': [],
          },
        ],
      };

  Map<String, dynamic> metadataJson() => {
        'id': 1,
        'travelStyles': ['COUPLE', 'LUXURY'],
        'bestVisitTimes': ['SUNSET'],
        'bestSeasons': ['SUMMER', 'ALL_YEAR'],
        'weatherTypes': ['SUNNY'],
        'estimatedVisitMinutes': 180,
        'estimatedBudgetLevel': 'HIGH',
        'difficultyLevel': 'EASY',
        'accessibilityLevel': 'HIGH',
        'crowdLevel': 'MEDIUM',
        'romantic': true,
        'familyFriendly': false,
        'kidFriendly': false,
        'petFriendly': false,
        'wheelchairFriendly': true,
        'photographySpot': true,
        'sunsetSpot': true,
        'sunriseSpot': false,
        'indoor': false,
        'outdoor': true,
        'rainyDaySuitable': false,
        'notes': 'Ask for a sea-view room.',
      };

  Map<String, dynamic> placeDetailJson({
    int id = 7,
    String name = 'Backend Villa',
    String address = '123 Hillside Road',
    String? description = 'A calm hillside villa with sea views.',
    String? googleMapUrl = 'https://maps.google.com/?q=backend-villa',
    double? latitude = 11.94,
    double? longitude = 108.44,
    bool openNow = true,
    List<Map<String, dynamic>> galleryImages = const [
      {
        'id': 1,
        'url': 'https://img.example/g1.jpg',
        'thumbnailUrl': null,
        'altText': 'Front',
        'sortOrder': 0,
        'cover': true
      },
      {
        'id': 2,
        'url': 'https://img.example/g2.jpg',
        'thumbnailUrl': null,
        'altText': 'Pool',
        'sortOrder': 1,
        'cover': false
      },
    ],
    String? coverImageUrl = 'https://img.example/cover.jpg',
    List<Map<String, dynamic>> amenities = const [
      {'id': 1, 'name': 'Free parking', 'slug': 'parking', 'groupName': null},
    ],
    List<Map<String, dynamic>> groupedOpeningHours = const [
      {
        'days': 'Monday - Friday',
        'openTime': '08:00:00',
        'closeTime': '22:00:00',
        'closed': false
      },
      {'days': 'Sunday', 'openTime': null, 'closeTime': null, 'closed': true},
    ],
    Object? metadata = _sentinel,
    Object? hotelDetail = _sentinel,
  }) =>
      {
        'id': id,
        'name': name,
        'slug': 'backend-villa',
        'shortDescription': 'Hillside villa.',
        'description': description,
        'address': address,
        'googleMapUrl': googleMapUrl,
        'latitude': latitude,
        'longitude': longitude,
        'category': {'id': 1, 'name': 'Hotels', 'slug': 'hotel'},
        'subcategory': null,
        'location': {'id': 1, 'name': 'Da Lat', 'fullPath': 'Da Lat, Lam Dong'},
        'ratingAvg': 4.6,
        'ratingCount': 128,
        'priceLevel': 3,
        'featured': true,
        'verified': true,
        'status': 'PUBLISHED',
        'tags': [
          {'id': 1, 'tag': 'romantic'},
        ],
        'amenities': amenities,
        'openingHours': const [],
        'groupedOpeningHours': groupedOpeningHours,
        'coverImageUrl': coverImageUrl,
        'galleryImages': galleryImages,
        'openNow': openNow,
        'similarPlaces': const [],
        'metadata': identical(metadata, _sentinel) ? metadataJson() : metadata,
        'hotelDetail':
            identical(hotelDetail, _sentinel) ? hotelDetailJson() : hotelDetail,
      };

  Place sampleHotel({int id = 7}) => Place(
        id: id,
        name: 'Backend Villa',
        category: 'Hotels',
        categorySlug: 'hotel',
        locationName: 'Da Lat',
        city: 'Da Lat',
        province: 'Lam Dong',
        description: 'A calm hillside villa.',
        imageUrl: '',
        rating: 4.6,
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('rich detail record maps every UI23 field from the backend JSON', () {
      final record = PlaceDetailRecord.fromJson(placeDetailJson());

      expect(record.googleMapUrl, 'https://maps.google.com/?q=backend-villa');
      expect(record.openNow, isTrue);
      expect(record.latitude, 11.94);
      expect(record.longitude, 108.44);

      // Gallery keeps every image + order + cover flag.
      expect(record.galleryImages.length, 2);
      expect(record.galleryImages.first.url, 'https://img.example/g1.jpg');
      expect(record.galleryImages.first.cover, isTrue);
      expect(record.galleryImages.last.sortOrder, 1);
      expect(record.galleryUrls,
          ['https://img.example/g1.jpg', 'https://img.example/g2.jpg']);

      // Place-level amenities.
      expect(record.amenities.single.name, 'Free parking');

      // Metadata block.
      final meta = record.metadata!;
      expect(meta.travelStyles, ['COUPLE', 'LUXURY']);
      expect(meta.bestSeasons, ['SUMMER', 'ALL_YEAR']);
      expect(meta.weatherTypes, ['SUNNY']);
      expect(meta.bestVisitTimes, ['SUNSET']);
      expect(meta.estimatedVisitMinutes, 180);
      expect(meta.budgetLevel, 'HIGH');
      expect(meta.difficultyLevel, 'EASY');
      expect(meta.accessibilityLevel, 'HIGH');
      expect(meta.crowdLevel, 'MEDIUM');
      expect(meta.romantic, isTrue);
      expect(meta.wheelchairFriendly, isTrue);
      expect(meta.activeFlags,
          containsAll(<String>['romantic', 'wheelchairFriendly', 'outdoor']));
      expect(meta.notes, 'Ask for a sea-view room.');
      expect(meta.isEmpty, isFalse);
    });

    test('rich hotelDetail preserves grouping, availability, parking booleans',
        () {
      final detail =
          PlaceDetailRecord.fromJson(placeDetailJson()).hotelDetailRich!;

      // Facility grouping (null group -> GENERAL; sorted by sortOrder).
      final groups = {for (final g in detail.groupedFacilities) g.key: g.value};
      expect(
          groups.keys, containsAll(<String>['OUTDOOR', 'WELLNESS', 'GENERAL']));
      expect(groups['WELLNESS']!.single.facilityName, 'Spa');
      expect(groups['GENERAL']!.single.facilityName, 'Front desk');

      // Service availability preserved.
      final concierge =
          detail.services.firstWhere((s) => s.serviceName == 'Concierge');
      final roomService =
          detail.services.firstWhere((s) => s.serviceName == 'Room service');
      expect(concierge.available, isTrue);
      expect(roomService.available, isFalse);

      // Parking / internet booleans.
      expect(detail.parking.available, isTrue);
      expect(detail.parking.free, isTrue);
      expect(detail.internet.wifiFree, isTrue);

      // Policies + rooms.
      expect(detail.cancellationPolicy, isNotNull);
      expect(detail.petPolicy, contains('not allowed'));
      expect(detail.rooms.single.roomName, 'Deluxe Garden View');
      expect(detail.checkInTime, '14:00'); // trimmed to HH:mm
    });

    test('null metadata and hotelDetail degrade to null (no fabrication)', () {
      final record = PlaceDetailRecord.fromJson(placeDetailJson(
        metadata: null,
        hotelDetail: null,
        galleryImages: const [],
        coverImageUrl: null,
        groupedOpeningHours: const [],
        latitude: null,
        longitude: null,
        googleMapUrl: null,
      ));
      expect(record.metadata, isNull);
      expect(record.hotelDetailRich, isNull);
      expect(record.galleryImages, isEmpty);
      expect(record.openNow, isTrue); // fixture default; explicit value honored
      expect(record.amenities.single.name, 'Free parking');
    });

    test('an empty metadata object reports isEmpty so the UI hides it', () {
      final record = PlaceDetailRecord.fromJson(placeDetailJson(metadata: {
        'id': 9,
        'travelStyles': [],
        'bestVisitTimes': [],
        'bestSeasons': [],
        'weatherTypes': [],
      }));
      expect(record.metadata, isNotNull);
      expect(record.metadata!.isEmpty, isTrue);
    });
  });

  // ── Hydration cache (UI19 reuse) ─────────────────────────────────────────────

  group('Hydration cache', () {
    test('hydration caches the record AND the projected place via one GET',
        () async {
      var calls = 0;
      var path = '';
      final app = realApp(MockClient((request) async {
        calls++;
        path = request.url.path;
        return jsonResponse(placeDetailJson(), 200);
      }));

      final result = await app.hydrateRealPlace(7);
      expect(result, PlaceHydrationResult.success);
      expect(path, '/api/places/7');
      expect(calls, 1);
      expect(app.getHydratedRealPlaceDetail(7), isNotNull);
      expect(app.getHydratedRealPlaceDetail(7)!.openNow, isTrue);
      expect(app.getHydratedRealPlace(7), isNotNull); // lossy Place still built

      // A cached hydrate issues no further HTTP.
      await app.hydrateRealPlace(7);
      expect(calls, 1);
    });

    test('refresh re-fetches and overwrites the cached record', () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(placeDetailJson(openNow: calls == 1), 200);
      }));
      await app.hydrateRealPlace(7);
      expect(app.getHydratedRealPlaceDetail(7)!.openNow, isTrue);
      await app.hydrateRealPlace(7, refresh: true);
      expect(calls, 2);
      expect(app.getHydratedRealPlaceDetail(7)!.openNow, isFalse);
    });

    test('malformed body maps to serverError and caches nothing', () async {
      final app = realApp(MockClient((request) async => http.Response(
          '["not-an-object"]', 200,
          headers: {'content-type': 'application/json'})));
      final result = await app.hydrateRealPlace(7);
      expect(result, PlaceHydrationResult.serverError);
      expect(app.getHydratedRealPlaceDetail(7), isNull);
    });

    test('404 maps to notFound; 401 to sessionExpired without logging out',
        () async {
      final notFoundApp = realApp(MockClient((request) async =>
          jsonResponse(errorBody(404, 'gone', '/api/places/7'), 404)));
      expect(
          await notFoundApp.hydrateRealPlace(7), PlaceHydrationResult.notFound);

      final app = realApp(MockClient((request) async =>
          jsonResponse(errorBody(401, 'nope', '/api/places/7'), 401)))
        ..email = 'real@example.com';
      expect(
          await app.hydrateRealPlace(7), PlaceHydrationResult.sessionExpired);
      expect(app.email, 'real@example.com',
          reason: 'a 401 must not clear the session');
    });

    test('logout clears the rich detail cache', () async {
      final app = realApp(
          MockClient((request) async => jsonResponse(placeDetailJson(), 200)));
      await app.hydrateRealPlace(7);
      expect(app.getHydratedRealPlaceDetail(7), isNotNull);
      await app.logout();
      expect(app.getHydratedRealPlaceDetail(7), isNull);
    });

    test('a double tap issues a single in-flight request (newest cached)',
        () async {
      var calls = 0;
      final completer = Completer<http.Response>();
      final app = realApp(MockClient((request) async {
        calls++;
        return completer.future;
      }));
      final f1 = app.hydrateRealPlace(7);
      final f2 = app.hydrateRealPlace(7);
      completer.complete(jsonResponse(placeDetailJson(), 200));
      await Future.wait([f1, f2]);
      expect(calls, 1);
      expect(app.getHydratedRealPlaceDetail(7), isNotNull);
    });
  });

  // ── Demo Mode isolation ─────────────────────────────────────────────────────

  group('Demo Mode isolation', () {
    test('Demo Mode never hits the network and reports unavailable', () async {
      var calls = 0;
      final app = demoApp(MockClient((request) async {
        calls++;
        return jsonResponse(placeDetailJson(), 200);
      }));
      expect(await app.hydrateRealPlace(7), PlaceHydrationResult.unavailable);
      expect(app.getHydratedRealPlaceDetail(7), isNull);
      expect(calls, 0);
    });

    testWidgets(
        'the demo detail screen keeps its own hero + availability button',
        (tester) async {
      ignoreNetworkImageErrors();
      final hotel = MockData.places.firstWhere((p) => p.hotelDetail != null);
      await pumpSize(
        tester,
        testApp(child: PlaceDetailScreen(place: hotel)),
        const Size(900, 1400),
      );
      // Demo path: the original hero image key and hotel button are unchanged,
      // and the rich Real-Mode section keys are absent.
      expect(find.byKey(const Key('place-detail-image')), findsOneWidget);
      expect(find.byKey(const Key('hotel-detail-check-availability')),
          findsOneWidget);
      expect(find.byKey(const Key('real-metadata')), findsNothing);
    });
  });

  // ── Real detail widget ──────────────────────────────────────────────────────

  group('Real detail view', () {
    testWidgets('renders every backend-backed section for a full hotel',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(
          MockClient((request) async => jsonResponse(placeDetailJson(), 200)));
      await pumpSize(
        tester,
        testApp(app: app, child: PlaceDetailScreen(place: sampleHotel())),
        const Size(900, 2000),
      );
      final en = AppLocalizationsEn();

      expect(find.byKey(const Key('place-detail-image')), findsOneWidget);
      expect(find.text(en.placeOpenNow), findsWidgets);
      expect(find.byKey(const Key('real-opening-hours')), findsOneWidget);
      expect(find.byKey(const Key('real-place-coordinates')), findsOneWidget);
      expect(find.byKey(const Key('real-place-amenities')), findsOneWidget);
      expect(find.byKey(const Key('real-metadata')), findsOneWidget);
      expect(find.byKey(const Key('real-hotel-detail')), findsOneWidget);
      expect(find.byKey(const Key('real-room-preview-100')), findsOneWidget);
      expect(find.byKey(const Key('hotel-detail-check-availability')),
          findsOneWidget);
      // Grouped facilities show their localized group header.
      expect(find.text(en.facilityGroupWellness), findsOneWidget);
      // Localized metadata labels appear.
      expect(find.text(en.travelStyleLuxury), findsOneWidget);
    });

    testWidgets('a bare place hides the optional rich sections',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async => jsonResponse(
            placeDetailJson(
              address: '',
              metadata: null,
              hotelDetail: null,
              amenities: const [],
              groupedOpeningHours: const [],
              galleryImages: const [],
              coverImageUrl: null,
              latitude: null,
              longitude: null,
              googleMapUrl: null,
            ),
            200,
          )));
      await pumpSize(
        tester,
        testApp(app: app, child: PlaceDetailScreen(place: sampleHotel())),
        const Size(900, 1600),
      );
      expect(find.byKey(const Key('real-metadata')), findsNothing);
      expect(find.byKey(const Key('real-hotel-detail')), findsNothing);
      expect(find.byKey(const Key('real-place-coordinates')), findsNothing);
      expect(find.byKey(const Key('real-opening-hours')), findsNothing);
      expect(find.byKey(const Key('real-place-amenities')), findsNothing);
      // No image -> gallery placeholder, not the primary image key.
      expect(
          find.byKey(const Key('place-detail-image-fallback')), findsOneWidget);
      expect(find.byKey(const Key('place-detail-image')), findsNothing);
    });

    testWidgets('shows a localized loading state while hydrating',
        (tester) async {
      ignoreNetworkImageErrors();
      final completer = Completer<http.Response>();
      final app = realApp(MockClient((request) async => completer.future));
      await tester.pumpWidget(
        testApp(app: app, child: PlaceDetailScreen(place: sampleHotel())),
      );
      await tester.pump(); // run the post-frame hydration kick-off
      await tester.pump();
      expect(find.text(AppLocalizationsEn().placeDetailRealLoadingMessage),
          findsOneWidget);
      completer.complete(jsonResponse(placeDetailJson(), 200));
      await tester.pumpAndSettle();
    });

    testWidgets('server error shows a retryable error state', (tester) async {
      ignoreNetworkImageErrors();
      var calls = 0;
      final app = realApp(MockClient((request) async {
        // The place-detail view records a recently-viewed POST on open; it is
        // independent of hydration, so don't let it consume the retry counter.
        if (request.method == 'POST' &&
            request.url.path.contains('/me/recently-viewed')) {
          return jsonResponse(const <String, dynamic>{}, 200);
        }
        calls++;
        if (calls == 1) {
          return jsonResponse(errorBody(500, 'boom', '/api/places/7'), 500);
        }
        return jsonResponse(placeDetailJson(), 200);
      }));
      await pumpSize(
        tester,
        testApp(app: app, child: PlaceDetailScreen(place: sampleHotel())),
        const Size(900, 1400),
      );
      expect(find.byKey(const Key('real-detail-error')), findsOneWidget);

      await tester.tap(find.text(AppLocalizationsEn().errorAction));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('real-detail-error')), findsNothing);
      expect(find.byKey(const Key('real-hotel-detail')), findsOneWidget);
    });
  });

  // ── Localization parity ─────────────────────────────────────────────────────

  group('Localization parity', () {
    test('new UI23 keys resolve in EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      for (final pair in <List<String>>[
        [en.placeDetailRealLoadingMessage, vi.placeDetailRealLoadingMessage],
        [en.placeOpenNow, vi.placeOpenNow],
        [en.placeClosedNow, vi.placeClosedNow],
        [en.placeOpeningHoursTitle, vi.placeOpeningHoursTitle],
        [en.placeCoordinatesTitle, vi.placeCoordinatesTitle],
        [en.placeAmenitiesTitle, vi.placeAmenitiesTitle],
        [en.placeMetadataTitle, vi.placeMetadataTitle],
        [en.travelStyleLuxury, vi.travelStyleLuxury],
        [en.bestSeasonSummer, vi.bestSeasonSummer],
        [en.facilityGroupWellness, vi.facilityGroupWellness],
        [en.hotelPolicyCancellation, vi.hotelPolicyCancellation],
        [en.hotelParkingFree, vi.hotelParkingFree],
        [en.hotelWifiFree, vi.hotelWifiFree],
      ]) {
        expect(pair[0].trim(), isNotEmpty);
        expect(pair[1].trim(), isNotEmpty);
        expect(pair[0], isNot(equals(pair[1])),
            reason: 'EN and VI should differ for a real translation');
      }
      expect(en.placeCoordinatesValue('1.0', '2.0'), '1.0, 2.0');
      expect(en.hotelServiceUnavailable('Spa'), contains('Spa'));
      expect(en.placeGallerySemantic('Villa', 2), contains('Villa'));
    });
  });
}

const Object _sentinel = Object();
