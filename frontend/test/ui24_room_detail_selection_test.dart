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
import 'package:planyourtrip_frontend/features/hotels/real_room_detail_screen.dart';
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

  // ── Backend fixtures (verified vs Plan-Your-Trip-backend-v1) ─────────────────

  Map<String, dynamic> availableRoomJson({int roomId = 100}) => {
        'roomId': roomId,
        'roomName': 'Deluxe Garden View',
        'roomCode': 'DLX',
        'roomType': 'DELUXE',
        'bedType': 'KING',
        'bedCount': 1,
        'maxAdults': 2,
        'maxChildren': 1,
        'maxGuests': 3,
        'roomSizeSqm': 32.0,
        'breakfastIncluded': true,
        'freeCancellation': true,
        'instantConfirmation': true,
        'pricePerNight': 1200000,
        'originalPricePerNight': 1500000,
        'totalPrice': 3600000,
        'nights': 3,
        'appliedRatePlan': 'Flexible',
        'coverImageUrl': 'https://img.example/room.jpg',
        'amenities': [
          {'id': 1, 'name': 'Wi-Fi', 'slug': 'wifi'},
        ],
      };

  Map<String, dynamic> availabilityJson({List<Map<String, dynamic>>? rooms}) =>
      {
        'placeId': 7,
        'placeName': 'Backend Villa',
        'checkIn': '2030-06-01',
        'checkOut': '2030-06-04',
        'nights': 3,
        'adults': 2,
        'children': 0,
        'availableRooms': rooms ?? [availableRoomJson()],
      };

  Map<String, dynamic> ratePlanJson({
    int ratePlanId = 500,
    String rateName = 'Flexible',
    bool eligible = true,
    String? reason,
    String mealPlan = 'BREAKFAST',
    String cancellationPolicy = 'FREE_CANCELLATION',
    bool refundable = true,
  }) =>
      {
        'ratePlanId': ratePlanId,
        'code': 'FLEX',
        'rateName': rateName,
        'roomId': 100,
        'roomName': 'Deluxe Garden View',
        'sourceType': 'BASE',
        'parentRatePlanId': null,
        'eligible': eligible,
        'reason': reason,
        'nights': 3,
        'baseNightlyRate': 1300000,
        'derivedAdjustment': 0,
        'occupancyAdjustment': 0,
        'childSupplement': 0,
        'extraBedSupplement': 0,
        'finalNightlyRate': 1200000,
        'staySubtotal': 3600000,
        'mealPlan': mealPlan,
        'cancellationPolicy': cancellationPolicy,
        'refundable': refundable,
        'cancellationDeadline': '2030-05-30T12:00:00Z',
        'policySummary': 'Free cancellation until 30 May.',
      };

  List<Map<String, dynamic>> ratePlansJson() => [
        ratePlanJson(),
        ratePlanJson(
          ratePlanId: 501,
          rateName: 'Non-refundable saver',
          mealPlan: 'ROOM_ONLY',
          cancellationPolicy: 'NON_REFUNDABLE',
          refundable: false,
        ),
        ratePlanJson(
          ratePlanId: 502,
          rateName: 'Group rate',
          eligible: false,
          reason: 'Minimum 5 rooms required.',
        ),
      ];

  Place sampleHotel({int id = 7}) => Place(
        id: id,
        name: 'Backend Villa',
        category: 'Hotels',
        categorySlug: 'hotel',
        locationName: 'Da Lat',
        city: 'Da Lat',
        province: 'Lam Dong',
        description: 'Villa.',
        imageUrl: '',
        rating: 4.6,
      );

  HotelStayCriteria criteria() => HotelStayCriteria(
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 2,
        children: 0,
      );

  AvailableRoomRecord sampleRoom() =>
      AvailableRoomRecord.fromJson(availableRoomJson());

  /// Loads UI22 availability into [app] so a room selection is valid.
  Future<void> seedAvailability(AppState app) => app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 2,
        children: 0,
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('rate plan JSON maps every field incl. meal/cancellation enums', () {
      final plan = HotelRatePlan.fromJson(ratePlanJson());
      expect(plan.ratePlanId, 500);
      expect(plan.rateName, 'Flexible');
      expect(plan.roomId, 100);
      expect(plan.sourceType, 'BASE');
      expect(plan.eligible, isTrue);
      expect(plan.nights, 3);
      expect(plan.baseNightlyRate, 1300000);
      expect(plan.finalNightlyRate, 1200000);
      expect(plan.staySubtotal, 3600000);
      expect(plan.mealPlan, MealPlanType.breakfast);
      expect(
          plan.cancellationPolicyType, CancellationPolicyType.freeCancellation);
      expect(plan.refundable, isTrue);
      expect(plan.cancellationDeadline, isNotNull);
      expect(plan.policySummary, contains('Free cancellation'));
      expect(plan.hasBreakdown, isTrue);
    });

    test('ineligible plan keeps its reason; unknown enums fall back safely',
        () {
      final plan = HotelRatePlan.fromJson(ratePlanJson(
        eligible: false,
        reason: 'Minimum 5 rooms required.',
        mealPlan: 'MYSTERY',
        cancellationPolicy: 'MYSTERY',
      ));
      expect(plan.eligible, isFalse);
      expect(plan.reason, 'Minimum 5 rooms required.');
      expect(plan.mealPlan, MealPlanType.roomOnly);
      expect(plan.cancellationPolicyType, CancellationPolicyType.custom);
    });

    test('getRoomRatePlans calls GET /api/rooms/{id}/rate-plans with params',
        () async {
      var path = '';
      var method = '';
      Map<String, String> params = const {};
      final app = realApp(MockClient((request) async {
        path = request.url.path;
        method = request.method;
        params = request.url.queryParameters;
        return jsonResponse(ratePlansJson(), 200);
      }));
      final outcome = await app.loadRoomRatePlans(
        roomId: 100,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 2,
      );
      expect(outcome, RatePlanOutcome.success);
      expect(path, '/api/rooms/100/rate-plans');
      expect(method, 'GET');
      expect(params['checkIn'], '2030-06-01');
      expect(params['checkOut'], '2030-06-04');
      expect(params['adults'], '2');
      expect(app.roomRatePlans.length, 3);
    });

    test('a non-array body is malformed', () async {
      final app = realApp(MockClient(
          (request) async => jsonResponse({'not': 'an array'}, 200)));
      final outcome = await app.loadRoomRatePlans(
        roomId: 100,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      expect(outcome, RatePlanOutcome.malformed);
      expect(app.roomRatePlans, isEmpty);
    });
  });

  // ── Rate-plan loading ────────────────────────────────────────────────────────

  group('Rate-plan loading', () {
    test('caches per room and does not re-fetch or duplicate requests',
        () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(ratePlansJson(), 200);
      }));
      await app.loadRoomRatePlans(
          roomId: 100,
          checkIn: DateTime(2030, 6, 1),
          checkOut: DateTime(2030, 6, 4));
      expect(calls, 1);
      // Cached — no second request.
      await app.loadRoomRatePlans(
          roomId: 100,
          checkIn: DateTime(2030, 6, 1),
          checkOut: DateTime(2030, 6, 4));
      expect(calls, 1);
      // Refresh forces a re-fetch.
      await app.loadRoomRatePlans(
          roomId: 100,
          checkIn: DateTime(2030, 6, 1),
          checkOut: DateTime(2030, 6, 4),
          refresh: true);
      expect(calls, 2);
    });

    test('invalid dates are guarded client-side with no HTTP', () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(ratePlansJson(), 200);
      }));
      final outcome = await app.loadRoomRatePlans(
        roomId: 100,
        checkIn: DateTime(2030, 6, 4),
        checkOut: DateTime(2030, 6, 4),
      );
      expect(outcome, RatePlanOutcome.invalidDates);
      expect(calls, 0);
    });

    test('error statuses map to outcomes', () async {
      Future<RatePlanOutcome> run(int status) async {
        final app = realApp(MockClient((request) async => jsonResponse(
            errorBody(status, 'x', '/api/rooms/100/rate-plans'), status)));
        return app.loadRoomRatePlans(
            roomId: 100,
            checkIn: DateTime(2030, 6, 1),
            checkOut: DateTime(2030, 6, 4));
      }

      expect(await run(404), RatePlanOutcome.notFound);
      expect(await run(400), RatePlanOutcome.validation);
      expect(await run(500), RatePlanOutcome.serverError);
      expect(await run(401), RatePlanOutcome.sessionExpired);
    });

    test('newest load supersedes an older in-flight one (last wins)', () async {
      var calls = 0;
      final completer = Completer<http.Response>();
      final app = realApp(MockClient((request) async {
        calls++;
        if (calls == 1) return completer.future;
        return jsonResponse([ratePlanJson(ratePlanId: 999)], 200);
      }));
      final first = app.loadRoomRatePlans(
          roomId: 100,
          checkIn: DateTime(2030, 6, 1),
          checkOut: DateTime(2030, 6, 4));
      final second = app.loadRoomRatePlans(
          roomId: 100,
          checkIn: DateTime(2030, 6, 1),
          checkOut: DateTime(2030, 6, 4),
          refresh: true);
      completer.complete(jsonResponse(ratePlansJson(), 200));
      await Future.wait([first, second]);
      // The later refresh result wins.
      expect(app.roomRatePlans.single.ratePlanId, 999);
    });

    test('Demo Mode returns unavailable and issues no HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((request) async {
        calls++;
        return jsonResponse(ratePlansJson(), 200);
      }));
      expect(
        await app.loadRoomRatePlans(
            roomId: 100,
            checkIn: DateTime(2030, 6, 1),
            checkOut: DateTime(2030, 6, 4)),
        RatePlanOutcome.unavailable,
      );
      expect(calls, 0);
    });
  });

  // ── Selection ────────────────────────────────────────────────────────────────

  group('Selection', () {
    test('selectRoom picks a room in availability and resolves the getter',
        () async {
      final app = realApp(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      await seedAvailability(app);
      app.selectRoom(100);
      expect(app.selectedRoomId, 100);
      expect(app.selectedRoom?.roomName, 'Deluxe Garden View');
      expect(app.selectedGuestCount, 2);
      expect(app.selectedNightCount, 3);
    });

    test('selectRoom ignores a room not in the availability result', () async {
      final app = realApp(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      await seedAvailability(app);
      app.selectRoom(999);
      expect(app.selectedRoomId, isNull);
    });

    test('selecting a rate plan sets it and clearRoomSelection resets',
        () async {
      final app = realApp(MockClient((request) async {
        if (request.url.path.contains('/rate-plans')) {
          return jsonResponse(ratePlansJson(), 200);
        }
        return jsonResponse(availabilityJson(), 200);
      }));
      await seedAvailability(app);
      await app.loadRoomRatePlans(
          roomId: 100,
          checkIn: DateTime(2030, 6, 1),
          checkOut: DateTime(2030, 6, 4));
      app.selectRoom(100, ratePlanId: 500);
      expect(app.selectedRatePlanId, 500);
      expect(app.selectedRatePlan?.rateName, 'Flexible');
      app.clearRoomSelection();
      expect(app.selectedRoomId, isNull);
      expect(app.selectedRatePlanId, isNull);
    });

    test('a date/guest change that drops the room invalidates the selection',
        () async {
      var call = 0;
      final app = realApp(MockClient((request) async {
        call++;
        // First availability has room 100; the re-run (guest change) does not.
        return jsonResponse(
          availabilityJson(rooms: call == 1 ? null : const []),
          200,
        );
      }));
      await seedAvailability(app);
      app.selectRoom(100);
      expect(app.selectedRoomId, 100);
      // Guest change re-runs availability; room 100 is gone → selection cleared.
      await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 4,
        children: 0,
        refresh: true,
      );
      expect(app.selectedRoomId, isNull);
      expect(app.selectedRatePlanId, isNull);
    });

    test('a re-run that still offers the room keeps the selection', () async {
      final app = realApp(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      await seedAvailability(app);
      app.selectRoom(100);
      await app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 3,
        children: 0,
        refresh: true,
      );
      expect(app.selectedRoomId, 100);
    });

    test('logout clears the room selection and rate plans', () async {
      final app = realApp(MockClient((request) async {
        if (request.url.path.contains('/rate-plans')) {
          return jsonResponse(ratePlansJson(), 200);
        }
        return jsonResponse(availabilityJson(), 200);
      }));
      await seedAvailability(app);
      await app.loadRoomRatePlans(
          roomId: 100,
          checkIn: DateTime(2030, 6, 1),
          checkOut: DateTime(2030, 6, 4));
      app.selectRoom(100, ratePlanId: 500);
      await app.logout();
      expect(app.selectedRoomId, isNull);
      expect(app.roomRatePlans, isEmpty);
      expect(app.roomRatePlansRoomId, isNull);
    });
  });

  // ── Widget ───────────────────────────────────────────────────────────────────

  group('Room detail widget', () {
    Future<AppState> seededApp(http.Client client) async {
      final app = realApp(client);
      await seedAvailability(app);
      return app;
    }

    testWidgets('renders room info, price and rate plans, and selects', (
      tester,
    ) async {
      ignoreNetworkImageErrors();
      final app = await seededApp(MockClient((request) async {
        if (request.url.path.contains('/rate-plans')) {
          return jsonResponse(ratePlansJson(), 200);
        }
        return jsonResponse(availabilityJson(), 200);
      }));
      await pumpSize(
        tester,
        testApp(
          app: app,
          child: RealRoomDetailScreen(
            hotel: sampleHotel(),
            room: sampleRoom(),
            criteria: criteria(),
          ),
        ),
        const Size(900, 1800),
      );
      final en = AppLocalizationsEn();

      expect(find.byKey(const Key('real-rate-plans')), findsOneWidget);
      expect(find.byKey(const Key('real-rate-plan-500')), findsOneWidget);
      expect(find.byKey(const Key('real-rate-plan-502')), findsOneWidget);
      // Ineligible plan shows its backend reason.
      expect(find.text('Minimum 5 rooms required.'), findsOneWidget);
      // Price from availability.
      expect(find.textContaining('/ night'), findsWidgets);

      // Pick an eligible rate plan, then confirm the selection.
      await tester.tap(find.byKey(const Key('real-rate-plan-500')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('real-room-select-action')));
      await tester.pumpAndSettle();
      expect(app.selectedRoomId, 100);
      expect(app.selectedRatePlanId, 500);
      // Ignore an unused localization to keep the linter honest.
      expect(en.roomRatePlansTitle, isNotEmpty);
    });

    testWidgets('shows a loading state then the plans', (tester) async {
      ignoreNetworkImageErrors();
      final completer = Completer<http.Response>();
      final app = await seededApp(MockClient((request) async {
        if (request.url.path.contains('/rate-plans')) return completer.future;
        return jsonResponse(availabilityJson(), 200);
      }));
      await tester.pumpWidget(testApp(
        app: app,
        child: RealRoomDetailScreen(
          hotel: sampleHotel(),
          room: sampleRoom(),
          criteria: criteria(),
        ),
      ));
      await tester.pump();
      await tester.pump();
      expect(find.text(AppLocalizationsEn().roomRatePlansLoadingMessage),
          findsOneWidget);
      completer.complete(jsonResponse(ratePlansJson(), 200));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('real-rate-plan-500')), findsOneWidget);
    });

    testWidgets('rate-plan server error shows a retryable state', (
      tester,
    ) async {
      ignoreNetworkImageErrors();
      var calls = 0;
      final app = await seededApp(MockClient((request) async {
        if (request.url.path.contains('/rate-plans')) {
          calls++;
          if (calls == 1) {
            return jsonResponse(
                errorBody(500, 'boom', '/api/rooms/100/rate-plans'), 500);
          }
          return jsonResponse(ratePlansJson(), 200);
        }
        return jsonResponse(availabilityJson(), 200);
      }));
      await pumpSize(
        tester,
        testApp(
          app: app,
          child: RealRoomDetailScreen(
            hotel: sampleHotel(),
            room: sampleRoom(),
            criteria: criteria(),
          ),
        ),
        const Size(900, 1600),
      );
      expect(find.byKey(const Key('real-rate-plans-error')), findsOneWidget);
      await tester.tap(find.text(AppLocalizationsEn().errorAction));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('real-rate-plan-500')), findsOneWidget);
    });
  });

  // ── Localization parity ───────────────────────────────────────────────────────

  group('Localization parity', () {
    test('new UI24 keys resolve in EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      for (final pair in <List<String>>[
        [en.roomSelectAction, vi.roomSelectAction],
        [en.roomSelectedBadge, vi.roomSelectedBadge],
        [en.roomRatePlansTitle, vi.roomRatePlansTitle],
        [en.roomRatePlansLoadingMessage, vi.roomRatePlansLoadingMessage],
        [en.roomOccupancyTitle, vi.roomOccupancyTitle],
        [en.roomPriceTitle, vi.roomPriceTitle],
        [en.ratePlanRefundable, vi.ratePlanRefundable],
        [en.ratePlanNonRefundable, vi.ratePlanNonRefundable],
        [en.roomRatePlanIneligible, vi.roomRatePlanIneligible],
      ]) {
        expect(pair[0].trim(), isNotEmpty);
        expect(pair[1].trim(), isNotEmpty);
        expect(pair[0], isNot(equals(pair[1])));
      }
      expect(en.ratePlanFinalNightly('X'), contains('X'));
      expect(en.ratePlanStaySubtotal('X', 3), contains('X'));
      expect(en.roomOccupancyAdults(2), contains('2'));
    });
  });
}
