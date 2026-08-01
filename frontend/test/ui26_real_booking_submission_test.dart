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
import 'package:planyourtrip_frontend/features/hotels/booking_result_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/booking_review_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:planyourtrip_frontend/shared/widgets/glass_widgets.dart';
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
        'amenities': const [],
      };

  Map<String, dynamic> availabilityJson() => {
        'placeId': 7,
        'placeName': 'Backend Villa',
        'checkIn': '2030-06-01',
        'checkOut': '2030-06-04',
        'nights': 3,
        'adults': 2,
        'children': 0,
        'availableRooms': [availableRoomJson()],
      };

  Map<String, dynamic> pricingQuoteJson() => {
        'roomId': 100,
        'roomName': 'Deluxe Garden View',
        'roomCode': 'DLX',
        'placeId': 7,
        'hotelId': 7,
        'checkIn': '2030-06-01',
        'checkOut': '2030-06-04',
        'nights': 3,
        'adults': 2,
        'children': 0,
        'extraBeds': 0,
        'selectedRatePlanId': 500,
        'selectedRatePlanCode': 'FLEX',
        'selectedRatePlanName': 'Flexible',
        'mealPlanType': 'BREAKFAST',
        'cancellationPolicyType': 'FREE_CANCELLATION',
        'refundable': true,
        'cancellationDeadline': '2030-05-30T12:00:00Z',
        'baseNightlyRate': 1300000,
        'finalNightlyRate': 1200000,
        'staySubtotal': 3600000,
        'promotionDiscount': 300000,
        'totalBeforeCustomerBenefits': 3300000,
        'finalQuotedPrice': 3300000,
        'currency': 'VND',
        'inventoryAvailable': true,
        'availableRooms': 5,
        'quoteGeneratedAt': '2030-05-01T10:00:00Z',
        'quoteExpiresAt': '2030-05-01T10:15:00Z',
        'warnings': const [],
      };

  // Mirror of BookingDto.BookingResponse (POST /api/bookings → 201).
  Map<String, dynamic> bookingResponseJson({
    String status = 'PENDING',
    num finalPrice = 3300000,
    bool ratePlan = true,
    String bookingCode = 'PYT-20300601-000055',
  }) =>
      {
        'id': 55,
        'bookingCode': bookingCode,
        'userId': 9,
        'userFullName': 'Mai Nguyen',
        'userEmail': 'mai@example.com',
        'hotelId': 7,
        'hotelName': 'Backend Villa',
        'roomId': 100,
        'roomName': 'Deluxe Garden View',
        'roomCode': 'DLX',
        'checkIn': '2030-06-01',
        'checkOut': '2030-06-04',
        'nights': 3,
        'adults': 2,
        'children': 0,
        'numberOfRooms': 1,
        'status': status,
        'currency': 'VND',
        'basePrice': 3600000,
        'ratePlanPrice': 3600000,
        'discountAmount': 300000,
        'finalPrice': finalPrice,
        'specialRequest': 'High floor',
        'createdAt': '2030-05-01T10:00:00Z',
        'confirmedAt': null,
        if (ratePlan) 'selectedRatePlanId': 500,
        if (ratePlan) 'selectedRatePlanCode': 'FLEX',
        if (ratePlan) 'selectedRatePlanName': 'Flexible',
        if (ratePlan) 'mealPlanType': 'BREAKFAST',
        if (ratePlan) 'cancellationPolicyType': 'FREE_CANCELLATION',
        if (ratePlan) 'refundable': true,
      };

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

  HotelStayCriteria criteria({int? tripId}) => HotelStayCriteria(
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 2,
        children: 0,
        tripId: tripId,
      );

  Future<void> seedAvailability(AppState app) => app.loadRealAvailability(
        placeId: 7,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 2,
        children: 0,
      );

  Future<void> seedSelected(AppState app) async {
    await seedAvailability(app);
    app.selectRoom(100);
  }

  /// A routing client: availability GET and quote POST are answered from the
  /// verified fixtures; only `POST /api/bookings` is delegated to [onBooking] so
  /// each test controls just the create response.
  AppState routedApp(Future<http.Response> Function(http.Request) onBooking) =>
      realApp(MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' && path.endsWith('/bookings')) {
          return onBooking(request);
        }
        if (request.method == 'POST' && path.contains('/pricing/quote')) {
          return jsonResponse(pricingQuoteJson(), 200);
        }
        return jsonResponse(availabilityJson(), 200);
      }));

  /// A realApp with availability + selection + a loaded quote + a valid guest
  /// form — ready to submit a real booking. [onBooking] answers the create call.
  Future<AppState> seedSubmitReady(
    Future<http.Response> Function(http.Request) onBooking,
  ) async {
    final app = routedApp(onBooking);
    await seedSelected(app);
    app.bookingQuote = HotelPricingQuote.fromJson(pricingQuoteJson());
    app.bookingQuoteRoomId = 100;
    app.updateBookingGuestField(
      name: 'Mai Nguyen',
      email: 'mai@example.com',
      phone: '+84 90 123 4567',
      country: 'Vietnam',
    );
    return app;
  }

  Future<http.Response> okBooking(http.Request _) async =>
      jsonResponse(bookingResponseJson(), 201);

  Future<BookingSubmissionOutcome> submit(AppState app) =>
      app.submitRealBooking(specialRequest: 'High floor', tripId: null);

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('createBooking POSTs to /api/bookings with the exact JSON body',
        () async {
      http.Request? captured;
      final app = await seedSubmitReady((request) async {
        captured = request;
        return jsonResponse(bookingResponseJson(), 201);
      });
      await submit(app);
      expect(captured, isNotNull);
      expect(captured!.method, 'POST');
      expect(captured!.url.path.endsWith('/api/bookings'), isTrue);
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['roomId'], 100);
      expect(body['checkIn'], '2030-06-01');
      expect(body['checkOut'], '2030-06-04');
      expect(body['adults'], 2);
      expect(body['children'], 0);
      expect(body['numberOfRooms'], 1);
      expect(body['extraBeds'], 0);
      expect(body['ratePlanId'], 500);
      expect(body['specialRequest'], 'High floor');
    });

    test('a success response parses every field', () {
      final record = BookingCreateRecord.fromJson(bookingResponseJson());
      expect(record.id, 55);
      expect(record.bookingCode, 'PYT-20300601-000055');
      expect(record.hotelName, 'Backend Villa');
      expect(record.roomName, 'Deluxe Garden View');
      expect(record.nights, 3);
      expect(record.status, 'PENDING');
      expect(record.statusView, BookingStatusView.pending);
      expect(record.currency, 'VND');
      expect(record.finalPrice, 3300000);
      expect(record.selectedRatePlanName, 'Flexible');
      expect(record.refundable, true);
      expect(record.createdAt, isNotNull);
    });

    test('an unknown status degrades to unknown but keeps the raw string', () {
      final record = BookingCreateRecord.fromJson(
          bookingResponseJson(status: 'FUTURE_STATE'));
      expect(record.statusView, BookingStatusView.unknown);
      expect(record.status, 'FUTURE_STATE');
    });

    test('a missing rate-plan snapshot is null (not fabricated)', () {
      final record =
          BookingCreateRecord.fromJson(bookingResponseJson(ratePlan: false));
      expect(record.selectedRatePlanId, isNull);
      expect(record.selectedRatePlanName, isNull);
      expect(record.refundable, isNull);
    });

    test('a malformed 201 body maps to uncertain (may have committed)',
        () async {
      final app =
          await seedSubmitReady((request) async => http.Response('nope', 201));
      final outcome = await submit(app);
      expect(outcome, BookingSubmissionOutcome.uncertain);
      expect(app.lastCreatedBooking, isNull);
    });

    test('payload omits guest name/email/phone/country (no backend field)', () {
      final payload = BookingCreatePayload(
        roomId: 100,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 2,
        specialRequest: 'High floor',
      );
      final body = payload.toJson();
      expect(body.containsKey('fullName'), isFalse);
      expect(body.containsKey('email'), isFalse);
      expect(body.containsKey('phone'), isFalse);
      expect(body.containsKey('country'), isFalse);
    });
  });

  // ── Demo Mode ────────────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('submitRealBooking issues no HTTP and returns demoUnavailable',
        () async {
      var calls = 0;
      final app = demoApp(MockClient((request) async {
        calls++;
        return jsonResponse(bookingResponseJson(), 201);
      }));
      final outcome =
          await app.submitRealBooking(specialRequest: 'x', tripId: null);
      expect(outcome, BookingSubmissionOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.lastCreatedBooking, isNull);
    });
  });

  // ── Real submission ──────────────────────────────────────────────────────

  group('Real submission', () {
    test('a successful submit stores the server booking record', () async {
      final app = await seedSubmitReady(okBooking);
      final outcome = await submit(app);
      expect(outcome, BookingSubmissionOutcome.success);
      expect(app.lastCreatedBooking, isNotNull);
      expect(app.lastCreatedBooking!.bookingCode, 'PYT-20300601-000055');
      expect(app.lastCreatedBooking!.statusView, BookingStatusView.pending);
      expect(app.realBookingSubmissionError, isNull);
    });

    test('a PENDING booking stays pending (no fabricated confirmation)',
        () async {
      final app = await seedSubmitReady(okBooking);
      await submit(app);
      expect(app.lastCreatedBooking!.status, 'PENDING');
      expect(app.lastCreatedBooking!.statusView, BookingStatusView.pending);
    });

    test('a second submit while one is in flight returns busy (no 2nd HTTP)',
        () async {
      var calls = 0;
      final gate = Completer<http.Response>();
      final app = await seedSubmitReady((request) {
        calls++;
        return gate.future;
      });
      final first = submit(app);
      await Future<void>.delayed(Duration.zero);
      final second = await submit(app);
      expect(second, BookingSubmissionOutcome.busy);
      expect(calls, 1);
      gate.complete(jsonResponse(bookingResponseJson(), 201));
      expect(await first, BookingSubmissionOutcome.success);
    });

    test('the draft and guest form survive a failed submit', () async {
      final app = await seedSubmitReady((request) async =>
          jsonResponse(errorBody(500, 'boom', '/api/bookings'), 500));
      final outcome = await submit(app);
      expect(outcome, BookingSubmissionOutcome.serverError);
      expect(app.bookingGuestName, 'Mai Nguyen');
      expect(app.bookingContactEmail, 'mai@example.com');
      expect(app.bookingQuote, isNotNull);
      expect(app.lastCreatedBooking, isNull);
    });

    test('quoteMissing when there is no loaded quote', () async {
      final app = routedApp(okBooking);
      await seedSelected(app);
      app.updateBookingGuestField(
          name: 'A', email: 'a@b.co', phone: '+84 90 111 2222');
      // No bookingQuote seeded.
      expect(await submit(app), BookingSubmissionOutcome.quoteMissing);
    });
  });

  // ── Errors ─────────────────────────────────────────────────────────────────

  group('Errors', () {
    Future<BookingSubmissionOutcome> submitWith(http.Response response) async {
      final app = await seedSubmitReady((request) async => response);
      return submit(app);
    }

    test('400 maps to validation', () async {
      expect(
        await submitWith(
            jsonResponse(errorBody(400, 'bad', '/api/bookings'), 400)),
        BookingSubmissionOutcome.validation,
      );
    });

    test('401 maps to sessionExpired without logging out or leaving Real Mode',
        () async {
      final app = await seedSubmitReady((request) async =>
          jsonResponse(errorBody(401, 'nope', '/api/bookings'), 401));
      app.email = 'signed-in@example.com';
      app.api.token = 'jwt-token';
      final outcome = await submit(app);
      expect(outcome, BookingSubmissionOutcome.sessionExpired);
      expect(app.email, 'signed-in@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
      expect(app.lastCreatedBooking, isNull);
    });

    test('403 maps to forbidden', () async {
      expect(
        await submitWith(
            jsonResponse(errorBody(403, 'denied', '/api/bookings'), 403)),
        BookingSubmissionOutcome.forbidden,
      );
    });

    test('404 maps to notFound (room/rate plan unavailable)', () async {
      expect(
        await submitWith(
            jsonResponse(errorBody(404, 'gone', '/api/bookings'), 404)),
        BookingSubmissionOutcome.notFound,
      );
    });

    test('409 maps to conflict', () async {
      expect(
        await submitWith(
            jsonResponse(errorBody(409, 'taken', '/api/bookings'), 409)),
        BookingSubmissionOutcome.conflict,
      );
    });

    test('422 maps to unprocessable', () async {
      expect(
        await submitWith(
            jsonResponse(errorBody(422, 'no inv', '/api/bookings'), 422)),
        BookingSubmissionOutcome.unprocessable,
      );
    });

    test('500 maps to serverError', () async {
      expect(
        await submitWith(
            jsonResponse(errorBody(500, 'boom', '/api/bookings'), 500)),
        BookingSubmissionOutcome.serverError,
      );
    });

    test('a network failure maps to network', () async {
      final app = await seedSubmitReady(
          (request) async => throw http.ClientException('down'));
      expect(await submit(app), BookingSubmissionOutcome.network);
    });

    test('a timeout after submit maps to uncertain (never a clean failure)',
        () async {
      final app = await seedSubmitReady(
          (request) async => throw TimeoutException('slow'));
      final outcome = await submit(app);
      expect(outcome, BookingSubmissionOutcome.uncertain);
      expect(app.realBookingSubmissionUncertain, isTrue);
      // Draft preserved so the user can recover.
      expect(app.bookingQuote, isNotNull);
      expect(app.lastCreatedBooking, isNull);
    });
  });

  // ── State / session isolation ────────────────────────────────────────────

  group('State', () {
    test('logout clears the created booking and submission state', () async {
      final app = await seedSubmitReady(okBooking);
      await submit(app);
      expect(app.lastCreatedBooking, isNotNull);
      await app.logout();
      expect(app.lastCreatedBooking, isNull);
      expect(app.realBookingSubmissionError, isNull);
      expect(app.realBookingSubmitting, isFalse);
    });

    test('a created booking never leaks across a different login', () async {
      final app = await seedSubmitReady(okBooking);
      app.email = 'user-a@example.com';
      await submit(app);
      expect(app.lastCreatedBooking, isNotNull);
      await app.logout();
      app.email = 'user-b@example.com';
      expect(app.lastCreatedBooking, isNull);
    });

    test('a successful booking creates no fake payment and no fake code',
        () async {
      final app = await seedSubmitReady(okBooking);
      await submit(app);
      // The stored code is the server's own — nothing fabricated locally.
      expect(app.lastCreatedBooking!.bookingCode, 'PYT-20300601-000055');
      expect(app.realBookingSubmissionError, isNull);
    });

    test('clearBookingSubmissionError dismisses a prior error', () async {
      final app = await seedSubmitReady((request) async =>
          jsonResponse(errorBody(409, 'taken', '/api/bookings'), 409));
      await submit(app);
      expect(app.realBookingSubmissionError, BookingSubmissionOutcome.conflict);
      app.clearBookingSubmissionError();
      expect(app.realBookingSubmissionError, isNull);
    });
  });

  // ── UI ─────────────────────────────────────────────────────────────────────

  group('Review + result widgets', () {
    testWidgets('terms gate the create action', (tester) async {
      ignoreNetworkImageErrors();
      final app = await seedSubmitReady(okBooking);
      await pumpSize(
        tester,
        testApp(
          app: app,
          child:
              BookingReviewScreen(hotel: sampleHotel(), criteria: criteria()),
        ),
        const Size(900, 2400),
      );
      final button = tester.widget<OceanPrimaryButton>(
          find.byKey(const Key('booking-submit-action')));
      expect(button.onPressed, isNull);
    });

    testWidgets('creating opens the result screen with the server code',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = await seedSubmitReady(okBooking);
      await pumpSize(
        tester,
        testApp(
          app: app,
          child:
              BookingReviewScreen(hotel: sampleHotel(), criteria: criteria()),
        ),
        const Size(900, 2400),
      );
      await tester.tap(find.byKey(const Key('booking-terms-checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('booking-submit-action')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booking-result-content')), findsOneWidget);
      expect(find.text('PYT-20300601-000055'), findsOneWidget);
      // PENDING wording, never "confirmed".
      expect(find.text(AppLocalizationsEn().bookingStatusPendingHeadline),
          findsOneWidget);
      expect(find.text(AppLocalizationsEn().bookingStatusConfirmedHeadline),
          findsNothing);
    });

    testWidgets('no navigation before the backend responds', (tester) async {
      ignoreNetworkImageErrors();
      final gate = Completer<http.Response>();
      final app = await seedSubmitReady((request) => gate.future);
      await pumpSize(
        tester,
        testApp(
          app: app,
          child:
              BookingReviewScreen(hotel: sampleHotel(), criteria: criteria()),
        ),
        const Size(900, 2400),
      );
      await tester.tap(find.byKey(const Key('booking-terms-checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('booking-submit-action')));
      await tester.pump();
      // Still on review, no result yet, progress shown.
      expect(find.byKey(const Key('booking-review-content')), findsOneWidget);
      expect(find.byKey(const Key('booking-result-content')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete(jsonResponse(bookingResponseJson(), 201));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booking-result-content')), findsOneWidget);
    });

    testWidgets('an uncertain submit shows the warning and gates resubmit',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = await seedSubmitReady(
          (request) async => throw TimeoutException('slow'));
      await pumpSize(
        tester,
        testApp(
          app: app,
          child:
              BookingReviewScreen(hotel: sampleHotel(), criteria: criteria()),
        ),
        const Size(900, 2600),
      );
      await tester.tap(find.byKey(const Key('booking-terms-checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('booking-submit-action')));
      await tester.pumpAndSettle();
      // Warning shown, still on review, resubmit disabled until acknowledged.
      expect(find.byKey(const Key('booking-submit-uncertain')), findsOneWidget);
      expect(find.byKey(const Key('booking-review-content')), findsOneWidget);
      final blocked = tester.widget<OceanPrimaryButton>(
          find.byKey(const Key('booking-submit-action')));
      expect(blocked.onPressed, isNull);
      await tester.tap(find.byKey(const Key('booking-submit-uncertain-ack')));
      await tester.pumpAndSettle();
      final unblocked = tester.widget<OceanPrimaryButton>(
          find.byKey(const Key('booking-submit-action')));
      expect(unblocked.onPressed, isNotNull);
    });

    testWidgets('the result screen shows a price-changed advisory', (
      tester,
    ) async {
      ignoreNetworkImageErrors();
      final app = await seedSubmitReady(okBooking);
      // The seeded quote total is 3,300,000; the server booking came back at a
      // different final price — the result screen must surface that honestly.
      app.lastCreatedBooking = BookingCreateRecord.fromJson(
          bookingResponseJson(finalPrice: 3900000));
      await pumpSize(
        tester,
        testApp(
          app: app,
          child:
              BookingResultScreen(hotel: sampleHotel(), criteria: criteria()),
        ),
        const Size(900, 2400),
      );
      expect(find.byKey(const Key('booking-result-price-changed')),
          findsOneWidget);
    });

    testWidgets('the result screen renders a missing state without a booking', (
      tester,
    ) async {
      ignoreNetworkImageErrors();
      final app = realApp(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      await pumpSize(
        tester,
        testApp(
          app: app,
          child: BookingResultScreen(hotel: sampleHotel()),
        ),
        const Size(900, 1400),
      );
      expect(find.byKey(const Key('booking-result-missing')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('new UI26 keys resolve in EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      for (final pair in <List<String>>[
        [en.bookingCreateAction, vi.bookingCreateAction],
        [en.bookingCreatingLabel, vi.bookingCreatingLabel],
        [en.bookingResultTitle, vi.bookingResultTitle],
        [en.bookingResultCodeLabel, vi.bookingResultCodeLabel],
        [en.bookingResultDoneAction, vi.bookingResultDoneAction],
        [en.bookingResultPaymentNextNote, vi.bookingResultPaymentNextNote],
        [en.bookingStatusPendingHeadline, vi.bookingStatusPendingHeadline],
        [en.bookingStatusPendingBody, vi.bookingStatusPendingBody],
        [en.bookingStatusConfirmedHeadline, vi.bookingStatusConfirmedHeadline],
        [en.bookingSubmitConflictMessage, vi.bookingSubmitConflictMessage],
        [en.bookingSubmitUncertainTitle, vi.bookingSubmitUncertainTitle],
        [en.bookingSubmitUncertainBody, vi.bookingSubmitUncertainBody],
        [en.bookingPriceChangedNote, vi.bookingPriceChangedNote],
      ]) {
        expect(pair[0].trim(), isNotEmpty);
        expect(pair[1].trim(), isNotEmpty);
        expect(pair[0], isNot(equals(pair[1])));
      }
      expect(en.bookingStatusGenericHeadline('X'), contains('X'));
      expect(vi.bookingStatusGenericHeadline('X'), contains('X'));
    });
  });
}
