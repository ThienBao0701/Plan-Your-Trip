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
import 'package:planyourtrip_frontend/features/hotels/hotel_room_selection_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_utils.dart';
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

  // ── Backend RatePlanDto fixtures (verified against Plan-Your-Trip-backend-v1)

  Map<String, dynamic> availableRoomJson({
    int roomId = 100,
    String roomName = 'Deluxe Garden View',
    String? roomType = 'DELUXE',
    String? bedType = 'KING',
    int? maxGuests = 2,
    double roomSizeSqm = 32,
    bool breakfastIncluded = true,
    bool freeCancellation = true,
    bool instantConfirmation = false,
    double? pricePerNight = 1200000,
    double? originalPricePerNight = 1500000,
    double? totalPrice = 3600000,
    int nights = 3,
    String? coverImageUrl = 'https://img.example/room.jpg',
    List<Map<String, dynamic>> amenities = const [
      {
        'id': 1,
        'name': 'Wi-Fi',
        'slug': 'wifi',
        'icon': 'wifi',
        'groupName': 'Tech'
      },
      {
        'id': 2,
        'name': 'Air conditioning',
        'slug': 'ac',
        'icon': 'ac',
        'groupName': 'Comfort'
      },
    ],
  }) =>
      {
        'roomId': roomId,
        'roomName': roomName,
        'roomCode': 'DLX',
        'roomType': roomType,
        'bedType': bedType,
        'bedCount': 1,
        'maxAdults': 2,
        'maxChildren': 1,
        'maxGuests': maxGuests,
        'roomSizeSqm': roomSizeSqm,
        'breakfastIncluded': breakfastIncluded,
        'freeCancellation': freeCancellation,
        'instantConfirmation': instantConfirmation,
        'pricePerNight': pricePerNight,
        'originalPricePerNight': originalPricePerNight,
        'totalPrice': totalPrice,
        'nights': nights,
        'appliedRatePlan': 'Standard',
        'coverImageUrl': coverImageUrl,
        'amenities': amenities,
      };

  Map<String, dynamic> availabilityJson({
    int placeId = 7,
    String placeName = 'Backend Villa',
    int nights = 3,
    int adults = 2,
    int children = 0,
    List<Map<String, dynamic>>? rooms,
  }) =>
      {
        'placeId': placeId,
        'placeName': placeName,
        'checkIn': '2030-06-01',
        'checkOut': '2030-06-04',
        'nights': nights,
        'adults': adults,
        'children': children,
        'availableRooms': rooms ?? [availableRoomJson()],
      };

  AppState realApp(http.Client client) => AppState(
        api: ApiClient(client: client)..demoMode = false,
      )..demoMode = false;

  AppState demoApp(http.Client client) =>
      AppState(api: ApiClient(client: client));

  Place sampleHotel({int id = 7}) => Place(
        id: id,
        name: 'Backend Villa',
        category: 'Hotels',
        locationName: 'Da Lat',
        city: 'Da Lat',
        province: 'Lam Dong',
        description: 'A calm hillside villa.',
        imageUrl: '',
        rating: 4.6,
      );

  HotelStayCriteria criteria({
    DateTime? checkIn,
    DateTime? checkOut,
    int adults = 2,
    int children = 0,
  }) =>
      HotelStayCriteria(
        checkIn: checkIn ?? DateTime(2030, 6, 1),
        checkOut: checkOut ?? DateTime(2030, 6, 4),
        adults: adults,
        children: children,
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('valid availability maps and calls GET /{id}/availability with params',
        () async {
      var path = '';
      var method = '';
      Map<String, String> params = const {};
      final app = realApp(MockClient((request) async {
        path = request.url.path;
        method = request.method;
        params = request.url.queryParameters;
        return jsonResponse(availabilityJson(), 200);
      }));

      final outcome = await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 2,
        children: 1,
      );

      expect(outcome, HotelAvailabilityOutcome.success);
      expect(path, '/api/places/7/availability');
      expect(method, 'GET');
      expect(params['checkIn'], '2030-06-01');
      expect(params['checkOut'], '2030-06-04');
      expect(params['adults'], '2');
      expect(params['children'], '1');
      expect(app.realAvailability, isNotNull);
      expect(app.realAvailabilityPlaceId, 7);
      expect(app.realAvailability!.availableRooms.length, 1);
    });

    test('room fields map, amenities reduce to names, discount is derived',
        () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(availabilityJson(), 200);
      }));

      await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );

      final room = app.realAvailability!.availableRooms.single;
      expect(room.roomName, 'Deluxe Garden View');
      expect(room.roomType, 'DELUXE');
      expect(room.bedType, 'KING');
      expect(room.maxGuests, 2);
      expect(room.breakfastIncluded, isTrue);
      expect(room.freeCancellation, isTrue);
      expect(room.pricePerNight, 1200000);
      expect(room.totalPrice, 3600000);
      expect(room.nights, 3);
      expect(room.amenities, ['Wi-Fi', 'Air conditioning']);
      expect(room.hasDiscount, isTrue);
    });

    test('no discount when original price is not higher', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          availabilityJson(rooms: [
            availableRoomJson(
              pricePerNight: 1000000,
              originalPricePerNight: 1000000,
            ),
          ]),
          200,
        );
      }));

      await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      expect(app.realAvailability!.availableRooms.single.hasDiscount, isFalse);
    });

    test('nullable/partial room fields degrade honestly', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          availabilityJson(rooms: [
            {
              'roomId': 5,
              'roomName': 'Sparse',
              'roomType': null,
              'bedType': null,
              'maxGuests': null,
              'roomSizeSqm': null,
              'breakfastIncluded': null,
              'freeCancellation': null,
              'instantConfirmation': null,
              'pricePerNight': null,
              'originalPricePerNight': null,
              'totalPrice': null,
              'nights': null,
              'coverImageUrl': null,
              'amenities': null,
            }
          ]),
          200,
        );
      }));

      await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      final room = app.realAvailability!.availableRooms.single;
      expect(room.roomType, isNull);
      expect(room.maxGuests, isNull);
      expect(room.pricePerNight, isNull);
      expect(room.breakfastIncluded, isFalse);
      expect(room.amenities, isEmpty);
      expect(room.hasDiscount, isFalse);
    });

    test('non-object body → malformed', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse([availableRoomJson()], 200);
      }));
      final outcome = await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      expect(outcome, HotelAvailabilityOutcome.malformed);
    });
  });

  // ── Availability lifecycle ─────────────────────────────────────────────────

  group('Availability lifecycle', () {
    test('empty room list yields success with no rooms', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(availabilityJson(rooms: const []), 200);
      }));
      final outcome = await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      expect(outcome, HotelAvailabilityOutcome.success);
      expect(app.realAvailability!.availableRooms, isEmpty);
      expect(app.realAvailabilityError, isNull);
    });

    test('invalid dates are guarded client-side with no HTTP', () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(availabilityJson(), 200);
      }));

      final outcome = await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 4),
        checkOut: DateTime(2030, 6, 1), // check-out before check-in
      );
      expect(outcome, HotelAvailabilityOutcome.invalidDates);
      expect(app.realAvailabilityError, HotelAvailabilityOutcome.invalidDates);
      expect(calls, 0);
    });

    test('refresh reloads the same hotel', () async {
      var call = 0;
      final app = realApp(MockClient((request) async {
        call++;
        return jsonResponse(
          availabilityJson(rooms: [availableRoomJson(roomId: call)]),
          200,
        );
      }));

      await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      expect(app.realAvailability!.availableRooms.single.roomId, 1);
      final outcome = await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        refresh: true,
      );
      expect(outcome, HotelAvailabilityOutcome.success);
      expect(app.realAvailability!.availableRooms.single.roomId, 2);
    });

    test('retry after a network failure succeeds', () async {
      var call = 0;
      final app = realApp(MockClient((request) async {
        call++;
        if (call == 1) throw http.ClientException('offline');
        return jsonResponse(availabilityJson(), 200);
      }));

      final first = await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      expect(first, HotelAvailabilityOutcome.network);
      final second = await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        refresh: true,
      );
      expect(second, HotelAvailabilityOutcome.success);
      expect(app.realAvailability, isNotNull);
      expect(app.realAvailabilityError, isNull);
    });

    test('switching hotels clears the previous hotel result while loading',
        () async {
      final gate = Completer<void>();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/places/8/availability') {
          await gate.future;
          return jsonResponse(availabilityJson(placeId: 8), 200);
        }
        return jsonResponse(availabilityJson(placeId: 7), 200);
      }));

      await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      expect(app.realAvailability!.placeId, 7);

      final second = app.loadRealAvailability(
        placeId: 8,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      // Prior hotel's rooms are dropped immediately, not shown while loading.
      expect(app.realAvailability, isNull);
      expect(app.realAvailabilityPlaceId, 8);
      gate.complete();
      await second;
      expect(app.realAvailability!.placeId, 8);
    });
  });

  // ── Last-request-wins (cancel outdated) ──────────────────────────────────────

  group('Cancel outdated', () {
    test('a superseded in-flight lookup does not overwrite the newer one',
        () async {
      final slowGate = Completer<void>();
      final app = realApp(MockClient((request) async {
        if (request.url.queryParameters['adults'] == '2') {
          await slowGate.future;
          return jsonResponse(
            availabilityJson(adults: 2, rooms: [availableRoomJson(roomId: 1)]),
            200,
          );
        }
        return jsonResponse(
          availabilityJson(adults: 3, rooms: [availableRoomJson(roomId: 2)]),
          200,
        );
      }));

      final slow = app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 2,
      );
      final fast = app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 3,
      );
      await fast;
      expect(app.realAvailability!.availableRooms.single.roomId, 2);

      slowGate.complete();
      await slow;
      // Stale response discarded — last write wins.
      expect(app.realAvailability!.availableRooms.single.roomId, 2);
    });
  });

  // ── Error mapping ─────────────────────────────────────────────────────────

  group('Error mapping', () {
    Future<HotelAvailabilityOutcome> loadWithStatus(int status) async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          errorBody(status, 'x', '/api/places/7/availability'),
          status,
        );
      }));
      return app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
    }

    test('400 → validation', () async {
      expect(await loadWithStatus(400), HotelAvailabilityOutcome.validation);
    });

    test('404 → notFound', () async {
      expect(await loadWithStatus(404), HotelAvailabilityOutcome.notFound);
    });

    test('500 → serverError', () async {
      expect(await loadWithStatus(500), HotelAvailabilityOutcome.serverError);
    });

    test('401 → sessionExpired', () async {
      expect(
          await loadWithStatus(401), HotelAvailabilityOutcome.sessionExpired);
    });

    test('403 → forbidden', () async {
      expect(await loadWithStatus(403), HotelAvailabilityOutcome.forbidden);
    });

    test('timeout → timeout', () async {
      final app = realApp(MockClient((request) async {
        throw TimeoutException('slow');
      }));
      expect(
        await app.loadRealAvailability(
          placeId: 7,
          checkIn: DateTime(2030, 6, 1),
          checkOut: DateTime(2030, 6, 4),
        ),
        HotelAvailabilityOutcome.timeout,
      );
    });
  });

  // ── Demo Mode isolation ───────────────────────────────────────────────────

  group('Demo Mode isolation', () {
    test('loadRealAvailability in Demo Mode is unavailable and issues no HTTP',
        () async {
      var calls = 0;
      final app = demoApp(MockClient((request) async {
        calls++;
        return jsonResponse(availabilityJson(), 200);
      }));

      final outcome = await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      expect(outcome, HotelAvailabilityOutcome.unavailable);
      expect(calls, 0);
      expect(app.realAvailability, isNull);
    });

    testWidgets('demo hotel room screen still renders demo rooms',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = AppState(); // demo mode by default
      final hotel = accommodationPlaces(app.places).first;
      await pumpSize(
        tester,
        testApp(
          child: HotelRoomSelectionScreen(
            hotel: hotel,
            initialCriteria: criteria(),
            today: DateTime(2030, 5, 1),
          ),
          app: app,
        ),
        const Size(1200, 2400),
      );

      // Demo path untouched: demo room cards present, real cards absent.
      expect(find.byKey(const Key('hotel-rate-continue')), findsOneWidget);
      expect(
        find.byKey(const Key('real-room-card-100')),
        findsNothing,
      );
    });
  });

  // ── Session reset ─────────────────────────────────────────────────────────

  group('Session reset', () {
    test('logout clears real availability state', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(availabilityJson(), 200);
      }));

      await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      expect(app.realAvailability, isNotNull);

      await app.logout();

      expect(app.realAvailability, isNull);
      expect(app.realAvailabilityPlaceId, isNull);
      expect(app.realAvailabilityError, isNull);
    });
  });

  // ── Widget: real availability view ──────────────────────────────────────────

  group('Real availability view', () {
    testWidgets('renders real room cards for the hotel', (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          availabilityJson(rooms: [
            availableRoomJson(roomId: 100, roomName: 'Alpha Room'),
            availableRoomJson(roomId: 101, roomName: 'Beta Room'),
          ]),
          200,
        );
      }));

      await pumpSize(
        tester,
        testApp(
          child: HotelRoomSelectionScreen(
            hotel: sampleHotel(),
            initialCriteria: criteria(),
          ),
          app: app,
        ),
        const Size(1200, 2600),
      );

      expect(find.byKey(const Key('real-room-card-100')), findsOneWidget);
      expect(find.byKey(const Key('real-room-card-101')), findsOneWidget);
      expect(find.text('Alpha Room'), findsOneWidget);
      expect(find.text('Beta Room'), findsOneWidget);
      // Demo booking-continue button is not part of the real view.
      expect(find.byKey(const Key('hotel-rate-continue')), findsNothing);
    });

    testWidgets('renders the no-rooms empty state', (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        return jsonResponse(availabilityJson(rooms: const []), 200);
      }));

      await pumpSize(
        tester,
        testApp(
          child: HotelRoomSelectionScreen(
            hotel: sampleHotel(),
            initialCriteria: criteria(),
          ),
          app: app,
        ),
        const Size(1200, 2200),
      );

      expect(find.byKey(const Key('real-availability-empty')), findsOneWidget);
    });

    testWidgets('error state shows a retry that reloads', (tester) async {
      ignoreNetworkImageErrors();
      var call = 0;
      final app = realApp(MockClient((request) async {
        call++;
        if (call == 1) {
          return jsonResponse(
            errorBody(500, 'boom', '/api/places/7/availability'),
            500,
          );
        }
        return jsonResponse(availabilityJson(), 200);
      }));

      await pumpSize(
        tester,
        testApp(
          child: HotelRoomSelectionScreen(
            hotel: sampleHotel(),
            initialCriteria: criteria(),
          ),
          app: app,
        ),
        const Size(1200, 2400),
      );

      expect(find.byKey(const Key('real-availability-error')), findsOneWidget);

      await tester.tap(find.text(AppLocalizationsEn().errorAction));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('real-availability-error')), findsNothing);
      expect(find.byKey(const Key('real-room-card-100')), findsOneWidget);
    });

    testWidgets('changing guest count triggers a fresh availability load',
        (tester) async {
      ignoreNetworkImageErrors();
      final adultsSeen = <String>[];
      final app = realApp(MockClient((request) async {
        adultsSeen.add(request.url.queryParameters['adults'] ?? '');
        return jsonResponse(availabilityJson(), 200);
      }));

      await pumpSize(
        tester,
        testApp(
          child: HotelRoomSelectionScreen(
            hotel: sampleHotel(),
            initialCriteria: criteria(adults: 2),
          ),
          app: app,
        ),
        const Size(1200, 2600),
      );

      expect(adultsSeen.last, '2');
      await tester.tap(
        find.byKey(const Key('hotel-criteria-increment-adults')),
      );
      await tester.pumpAndSettle();
      expect(adultsSeen.last, '3');
    });

    testWidgets('a11y: loading state announces a localized message',
        (tester) async {
      ignoreNetworkImageErrors();
      final gate = Completer<void>();
      final app = realApp(MockClient((request) async {
        await gate.future;
        return jsonResponse(availabilityJson(rooms: const []), 200);
      }));

      await tester.pumpWidget(testApp(
        child: HotelRoomSelectionScreen(
          hotel: sampleHotel(),
          initialCriteria: criteria(),
        ),
        app: app,
      ));
      await tester.pump(); // fire post-frame load; response gated
      await tester.pump();

      expect(
        find.text(AppLocalizationsEn().availabilityRealLoadingMessage),
        findsOneWidget,
      );

      gate.complete();
      await tester.pumpAndSettle();
    });
  });

  // ── Localization parity ───────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI22 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final pairs = <String, List<String>>{
        'availabilityRealLoadingMessage': [
          en.availabilityRealLoadingMessage,
          vi.availabilityRealLoadingMessage,
        ],
        'availabilityRealErrorMessage': [
          en.availabilityRealErrorMessage,
          vi.availabilityRealErrorMessage,
        ],
        'availabilityRealInvalidDatesMessage': [
          en.availabilityRealInvalidDatesMessage,
          vi.availabilityRealInvalidDatesMessage,
        ],
        'availabilityRealFreeCancellation': [
          en.availabilityRealFreeCancellation,
          vi.availabilityRealFreeCancellation,
        ],
        'availabilityRealInstantConfirmation': [
          en.availabilityRealInstantConfirmation,
          vi.availabilityRealInstantConfirmation,
        ],
        'availabilityRealRoomCount': [
          en.availabilityRealRoomCount(3),
          vi.availabilityRealRoomCount(3),
        ],
        'availabilityRealPerNight': [
          en.availabilityRealPerNight('₫1'),
          vi.availabilityRealPerNight('₫1'),
        ],
        'availabilityRealTotalForNights': [
          en.availabilityRealTotalForNights('₫1', 3),
          vi.availabilityRealTotalForNights('₫1', 3),
        ],
      };
      for (final entry in pairs.entries) {
        expect(entry.value[0].trim(), isNotEmpty, reason: '${entry.key} EN');
        expect(entry.value[1].trim(), isNotEmpty, reason: '${entry.key} VI');
      }
    });
  });
}
