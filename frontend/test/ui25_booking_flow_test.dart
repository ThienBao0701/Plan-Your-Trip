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
import 'package:planyourtrip_frontend/features/hotels/booking_guest_info_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/booking_ready_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/booking_review_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/booking_summary_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_room_selection_screen.dart';
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

  // Mirror of RoomPricingQuoteResponse (POST /api/rooms/{id}/pricing/quote).
  Map<String, dynamic> pricingQuoteJson({
    String? mealPlanType = 'BREAKFAST',
    String currency = 'VND',
    num promotionDiscount = 300000,
    num finalQuotedPrice = 3300000,
  }) =>
      {
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
        'mealPlanType': mealPlanType,
        'cancellationPolicyType': 'FREE_CANCELLATION',
        'refundable': true,
        'cancellationDeadline': '2030-05-30T12:00:00Z',
        'baseNightlyRate': 1300000,
        'derivedAdjustment': 0,
        'occupancyAdjustment': 0,
        'childSupplement': 0,
        'extraBedSupplement': 0,
        'finalNightlyRate': 1200000,
        'staySubtotal': 3600000,
        'promotionDiscount': promotionDiscount,
        'totalBeforeCustomerBenefits': 3300000,
        'finalQuotedPrice': finalQuotedPrice,
        'currency': currency,
        'inventoryAvailable': true,
        'availableRooms': 5,
        'quoteGeneratedAt': '2030-05-01T10:00:00Z',
        'quoteExpiresAt': '2030-05-01T10:15:00Z',
        'warnings': const [],
        'eligibilityReason': null,
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

  /// Seeds availability and selects room 100 so the booking flow is enterable.
  Future<void> seedSelected(AppState app) async {
    await seedAvailability(app);
    app.selectRoom(100);
  }

  /// A realApp with availability + room selection + a loaded quote and a valid
  /// guest form — ready to render the review/ready steps without HTTP.
  Future<AppState> seedReviewReady(http.Client client) async {
    final app = realApp(client);
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

  Future<BookingQuoteOutcome> loadQuote(AppState app) => app.loadBookingQuote(
        roomId: 100,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('HotelPricingQuote.fromJson maps every field incl. enums + currency',
        () {
      final q = HotelPricingQuote.fromJson(pricingQuoteJson(currency: 'USD'));
      expect(q.roomId, 100);
      expect(q.roomName, 'Deluxe Garden View');
      expect(q.placeId, 7);
      expect(q.nights, 3);
      expect(q.selectedRatePlanId, 500);
      expect(q.selectedRatePlanName, 'Flexible');
      expect(q.mealPlanType, MealPlanType.breakfast);
      expect(q.cancellationPolicyType, CancellationPolicyType.freeCancellation);
      expect(q.refundable, isTrue);
      expect(q.finalNightlyRate, 1200000);
      expect(q.staySubtotal, 3600000);
      expect(q.promotionDiscount, 300000);
      expect(q.finalQuotedPrice, 3300000);
      expect(q.currency, 'USD');
      expect(q.checkIn, DateTime(2030, 6, 1));
      expect(q.cancellationDeadline, isNotNull);
    });

    test('null mealPlanType degrades to null (no fabricated meal plan)', () {
      final q =
          HotelPricingQuote.fromJson(pricingQuoteJson(mealPlanType: null));
      expect(q.mealPlanType, isNull);
    });

    test('getRoomPricingQuote POSTs to the quote path with a JSON body',
        () async {
      String? method;
      String? path;
      Map<String, dynamic>? body;
      final app = realApp(MockClient((request) async {
        method = request.method;
        path = request.url.path;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(pricingQuoteJson(), 200);
      }));
      final result = await app.api.getRoomPricingQuote(
        roomId: 100,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        adults: 2,
      );
      expect(result.success, isTrue);
      expect(method, 'POST');
      expect(path, '/api/rooms/100/pricing/quote');
      expect(body?['checkIn'], '2030-06-01');
      expect(body?['checkOut'], '2030-06-04');
      expect(body?['adults'], 2);
    });

    test('a non-object quote response maps to malformed', () async {
      final app = realApp(
          MockClient((request) async => jsonResponse('not-an-object', 200)));
      final result = await app.api.getRoomPricingQuote(
        roomId: 100,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
      );
      expect(result.success, isFalse);
      expect(result.errorKind, ApiErrorKind.malformed);
    });
  });

  // ── Quote loading ──────────────────────────────────────────────────────────

  group('loadBookingQuote', () {
    test('success stores the quote', () async {
      final app = realApp(
          MockClient((request) async => jsonResponse(pricingQuoteJson(), 200)));
      expect(await loadQuote(app), BookingQuoteOutcome.success);
      expect(app.bookingQuote?.finalQuotedPrice, 3300000);
      expect(app.bookingQuoteRoomId, 100);
    });

    test('a cached quote for the same room is reused (no second HTTP)',
        () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(pricingQuoteJson(), 200);
      }));
      expect(await loadQuote(app), BookingQuoteOutcome.success);
      expect(await loadQuote(app), BookingQuoteOutcome.success);
      expect(calls, 1);
    });

    test('refresh re-fetches', () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(pricingQuoteJson(), 200);
      }));
      await loadQuote(app);
      await app.loadBookingQuote(
        roomId: 100,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        refresh: true,
      );
      expect(calls, 2);
    });

    test('invalid dates are guarded client-side with no HTTP', () async {
      var calls = 0;
      final app = realApp(MockClient((request) async {
        calls++;
        return jsonResponse(pricingQuoteJson(), 200);
      }));
      final outcome = await app.loadBookingQuote(
        roomId: 100,
        checkIn: DateTime(2030, 6, 4),
        checkOut: DateTime(2030, 6, 1),
      );
      expect(outcome, BookingQuoteOutcome.invalidDates);
      expect(calls, 0);
    });

    test('error statuses map to booking quote outcomes', () async {
      Future<BookingQuoteOutcome> run(int status) {
        final app = realApp(MockClient((request) async => jsonResponse(
            errorBody(status, 'x', '/api/rooms/100/pricing/quote'), status)));
        return app.loadBookingQuote(
          roomId: 100,
          checkIn: DateTime(2030, 6, 1),
          checkOut: DateTime(2030, 6, 4),
        );
      }

      expect(await run(404), BookingQuoteOutcome.notFound);
      expect(await run(400), BookingQuoteOutcome.validation);
      expect(await run(500), BookingQuoteOutcome.serverError);
      expect(await run(401), BookingQuoteOutcome.sessionExpired);
    });

    test('newest load supersedes an older in-flight one (last wins)', () async {
      var calls = 0;
      final completer = Completer<http.Response>();
      final app = realApp(MockClient((request) async {
        calls++;
        if (calls == 1) return completer.future;
        return jsonResponse(pricingQuoteJson(finalQuotedPrice: 999), 200);
      }));
      final first = loadQuote(app);
      final second = app.loadBookingQuote(
        roomId: 100,
        checkIn: DateTime(2030, 6, 1),
        checkOut: DateTime(2030, 6, 4),
        refresh: true,
      );
      completer.complete(jsonResponse(pricingQuoteJson(), 200));
      await Future.wait([first, second]);
      expect(app.bookingQuote?.finalQuotedPrice, 999);
    });

    test('Demo Mode returns unavailable and issues no HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((request) async {
        calls++;
        return jsonResponse(pricingQuoteJson(), 200);
      }));
      expect(await loadQuote(app), BookingQuoteOutcome.unavailable);
      expect(calls, 0);
    });
  });

  // ── Validation ─────────────────────────────────────────────────────────────

  group('validateBookingDraft', () {
    test('empty name and email are required', () {
      final app = realApp(MockClient((request) async => jsonResponse({}, 200)));
      final v = app.validateBookingDraft();
      expect(v.nameRequired, isTrue);
      expect(v.emailRequired, isTrue);
      expect(v.isValid, isFalse);
    });

    test('a malformed email is flagged', () {
      final app = realApp(MockClient((request) async => jsonResponse({}, 200)));
      app.updateBookingGuestField(name: 'A', email: 'not-an-email');
      expect(app.validateBookingDraft().emailInvalid, isTrue);
    });

    test('a malformed phone is flagged', () {
      final app = realApp(MockClient((request) async => jsonResponse({}, 200)));
      app.updateBookingGuestField(name: 'A', email: 'a@b.com', phone: 'abc');
      expect(app.validateBookingDraft().phoneInvalid, isTrue);
    });

    test('an over-length name is flagged', () {
      final app = realApp(MockClient((request) async => jsonResponse({}, 200)));
      app.updateBookingGuestField(
        name: 'x' * (BookingValidation.maxNameLength + 1),
        email: 'a@b.com',
      );
      expect(app.validateBookingDraft().nameTooLong, isTrue);
    });

    test('a complete form is valid', () {
      final app = realApp(MockClient((request) async => jsonResponse({}, 200)));
      app.updateBookingGuestField(
          name: 'Mai Nguyen', email: 'mai@example.com', phone: '+84901234567');
      expect(app.validateBookingDraft().isValid, isTrue);
    });
  });

  // ── Autosave + draft ───────────────────────────────────────────────────────

  group('Autosave and draft', () {
    test('guest fields autosave in-session', () {
      final app = realApp(MockClient((request) async => jsonResponse({}, 200)));
      app.updateBookingGuestField(name: 'Mai', email: 'mai@example.com');
      expect(app.bookingGuestName, 'Mai');
      expect(app.bookingContactEmail, 'mai@example.com');
    });

    test('contact email is prefilled from the account when blank', () {
      final app = realApp(MockClient((request) async => jsonResponse({}, 200)));
      app.email = 'account@example.com';
      app.prefillBookingContactEmail();
      expect(app.bookingContactEmail, 'account@example.com');
      // Does not overwrite an existing value.
      app.updateBookingGuestField(email: 'typed@example.com');
      app.prefillBookingContactEmail();
      expect(app.bookingContactEmail, 'typed@example.com');
    });

    test('toggling a special-request preset adds then removes it', () {
      final app = realApp(MockClient((request) async => jsonResponse({}, 200)));
      app.toggleBookingSpecialRequest(SpecialRequestPreset.highFloor);
      expect(app.bookingSpecialRequestPresets,
          contains(SpecialRequestPreset.highFloor));
      app.toggleBookingSpecialRequest(SpecialRequestPreset.highFloor);
      expect(app.bookingSpecialRequestPresets, isEmpty);
    });

    test('finalizeBookingDraft builds a ready draft from the loaded quote',
        () async {
      final app = realApp(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      await seedSelected(app);
      app.bookingQuote = HotelPricingQuote.fromJson(pricingQuoteJson());
      app.bookingQuoteRoomId = 100;
      app.updateBookingGuestField(
        name: 'Mai Nguyen',
        email: 'mai@example.com',
        phone: '+84901234567',
      );
      app.toggleBookingSpecialRequest(SpecialRequestPreset.quietRoom);
      app.setBookingSpecialRequestNote('Please face the garden.');
      final outcome = app.finalizeBookingDraft(tripId: 42);
      expect(outcome, BookingDraftOutcome.ready);
      final draft = app.bookingDraft!;
      expect(draft.roomId, 100);
      expect(draft.guest.fullName, 'Mai Nguyen');
      expect(draft.guest.email, 'mai@example.com');
      expect(draft.specialRequestPresets,
          contains(SpecialRequestPreset.quietRoom));
      expect(draft.specialRequestNote, 'Please face the garden.');
      expect(draft.quote.finalQuotedPrice, 3300000);
      expect(draft.tripId, 42);
      expect(draft.nights, 3);
    });

    test('finalizeBookingDraft rejects an invalid guest form', () async {
      final app = realApp(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      await seedSelected(app);
      app.bookingQuote = HotelPricingQuote.fromJson(pricingQuoteJson());
      // No guest name/email.
      expect(app.finalizeBookingDraft(), BookingDraftOutcome.invalid);
      expect(app.bookingDraft, isNull);
    });

    test('finalizeBookingDraft reports quoteMissing without a quote', () async {
      final app = realApp(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      await seedSelected(app);
      app.updateBookingGuestField(name: 'Mai', email: 'mai@example.com');
      expect(app.finalizeBookingDraft(), BookingDraftOutcome.quoteMissing);
    });

    test('Demo Mode never prepares a draft', () {
      final app = demoApp(MockClient((request) async => jsonResponse({}, 200)));
      app.updateBookingGuestField(name: 'Mai', email: 'mai@example.com');
      expect(app.finalizeBookingDraft(), BookingDraftOutcome.unavailable);
    });
  });

  // ── Reset ──────────────────────────────────────────────────────────────────

  group('Reset', () {
    test('logout clears the draft, guest form and quote', () async {
      final app = await seedReviewReady(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      app.setBookingSpecialRequestNote('note');
      app.finalizeBookingDraft();
      expect(app.bookingDraft, isNotNull);
      await app.logout();
      expect(app.bookingDraft, isNull);
      expect(app.bookingQuote, isNull);
      expect(app.bookingGuestName, '');
      expect(app.bookingContactEmail, '');
      expect(app.bookingSpecialRequestPresets, isEmpty);
      expect(app.bookingSpecialRequestNote, '');
    });
  });

  // ── Widgets ────────────────────────────────────────────────────────────────

  group('Booking summary widget', () {
    testWidgets('renders the backend-priced summary and continue', (
      tester,
    ) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path.contains('/pricing/quote')) {
          return jsonResponse(pricingQuoteJson(), 200);
        }
        return jsonResponse(availabilityJson(), 200);
      }));
      await seedSelected(app);
      await pumpSize(
        tester,
        testApp(
          app: app,
          child:
              BookingSummaryScreen(hotel: sampleHotel(), criteria: criteria()),
        ),
        const Size(900, 1800),
      );
      expect(find.byKey(const Key('booking-summary-content')), findsOneWidget);
      expect(find.byKey(const Key('booking-summary-continue')), findsOneWidget);
      expect(find.text(AppLocalizationsEn().bookingFinalQuotedPrice),
          findsOneWidget);

      // Continue advances to the guest step.
      await tester.tap(find.byKey(const Key('booking-summary-continue')));
      await tester.pumpAndSettle();
      expect(find.text(AppLocalizationsEn().bookingGuestSectionTitle),
          findsOneWidget);
    });

    testWidgets('shows a loading state while the quote is in flight', (
      tester,
    ) async {
      ignoreNetworkImageErrors();
      final completer = Completer<http.Response>();
      final app = realApp(MockClient((request) async {
        if (request.url.path.contains('/pricing/quote')) {
          return completer.future;
        }
        return jsonResponse(availabilityJson(), 200);
      }));
      await seedSelected(app);
      await tester.pumpWidget(testApp(
        app: app,
        child: BookingSummaryScreen(hotel: sampleHotel(), criteria: criteria()),
      ));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('booking-summary-loading')), findsOneWidget);
      completer.complete(jsonResponse(pricingQuoteJson(), 200));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booking-summary-content')), findsOneWidget);
    });

    testWidgets('a server error shows a retryable state', (tester) async {
      ignoreNetworkImageErrors();
      var calls = 0;
      final app = realApp(MockClient((request) async {
        if (request.url.path.contains('/pricing/quote')) {
          calls++;
          if (calls == 1) {
            return jsonResponse(
                errorBody(500, 'boom', '/api/rooms/100/pricing/quote'), 500);
          }
          return jsonResponse(pricingQuoteJson(), 200);
        }
        return jsonResponse(availabilityJson(), 200);
      }));
      await seedSelected(app);
      await pumpSize(
        tester,
        testApp(
          app: app,
          child:
              BookingSummaryScreen(hotel: sampleHotel(), criteria: criteria()),
        ),
        const Size(900, 1600),
      );
      expect(find.byKey(const Key('booking-summary-error')), findsOneWidget);
      await tester.tap(find.text(AppLocalizationsEn().errorAction));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booking-summary-content')), findsOneWidget);
    });
  });

  group('Guest info widget', () {
    testWidgets('empty form blocks continue and surfaces validation', (
      tester,
    ) async {
      final app = realApp(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      await seedSelected(app);
      await pumpSize(
        tester,
        testApp(
          app: app,
          child: BookingGuestInfoScreen(
              hotel: sampleHotel(), criteria: criteria()),
        ),
        const Size(900, 1800),
      );
      await tester.tap(find.byKey(const Key('booking-guest-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booking-guest-validation')), findsOneWidget);
      // Still on the guest step (no review content pushed).
      expect(find.byKey(const Key('booking-review-content')), findsNothing);
    });

    testWidgets('entered guest details autosave to AppState', (tester) async {
      final app = realApp(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      await seedSelected(app);
      await pumpSize(
        tester,
        testApp(
          app: app,
          child: BookingGuestInfoScreen(
              hotel: sampleHotel(), criteria: criteria()),
        ),
        const Size(900, 1800),
      );
      await tester.enterText(
          find.byKey(const Key('booking-guest-name')), 'Mai Nguyen');
      await tester.enterText(
          find.byKey(const Key('booking-guest-email')), 'mai@example.com');
      await tester.pump();
      expect(app.bookingGuestName, 'Mai Nguyen');
      expect(app.bookingContactEmail, 'mai@example.com');
      expect(app.validateBookingDraft().isValid, isTrue);
    });
  });

  group('Booking review widget', () {
    // UI26: the review CTA now performs the real POST /api/bookings submission
    // (was the UI25 draft-prepare step). Terms still gate it; success opens the
    // real booking-result screen. (Full submit coverage lives in the UI26 test.)
    testWidgets('terms gate the create action; creating opens the result',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = await seedReviewReady(MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.endsWith('/bookings')) {
          return jsonResponse({
            'id': 55,
            'bookingCode': 'PYT-20300601-000055',
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
            'status': 'PENDING',
            'currency': 'VND',
            'finalPrice': 3300000,
          }, 201);
        }
        return jsonResponse(availabilityJson(), 200);
      }));
      await pumpSize(
        tester,
        testApp(
          app: app,
          child:
              BookingReviewScreen(hotel: sampleHotel(), criteria: criteria()),
        ),
        const Size(900, 2000),
      );
      expect(find.byKey(const Key('booking-review-content')), findsOneWidget);

      // Create is disabled until the terms are acknowledged.
      final button = tester.widget<OceanPrimaryButton>(
          find.byKey(const Key('booking-submit-action')));
      expect(button.onPressed, isNull);

      await tester.tap(find.byKey(const Key('booking-terms-checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('booking-submit-action')));
      await tester.pumpAndSettle();

      expect(app.lastCreatedBooking, isNotNull);
      expect(find.byKey(const Key('booking-result-content')), findsOneWidget);
    });
  });

  group('Booking ready widget', () {
    testWidgets('presents an honest non-confirmation (no fabricated number)', (
      tester,
    ) async {
      ignoreNetworkImageErrors();
      final app = await seedReviewReady(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      app.finalizeBookingDraft();
      await pumpSize(
        tester,
        testApp(
          app: app,
          child: BookingReadyScreen(hotel: sampleHotel()),
        ),
        const Size(900, 2000),
      );
      expect(find.byKey(const Key('booking-ready-content')), findsOneWidget);
      expect(
          find.text(AppLocalizationsEn().bookingReadyHeadline), findsOneWidget);
      expect(find.text(AppLocalizationsEn().bookingReadyBody), findsOneWidget);
      expect(find.byKey(const Key('booking-ready-done')), findsOneWidget);
    });
  });

  group('Continue-to-booking CTA', () {
    testWidgets('appears only once a room is selected', (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(
          MockClient((request) async => jsonResponse(availabilityJson(), 200)));
      await seedAvailability(app);
      await pumpSize(
        tester,
        testApp(
          app: app,
          child: HotelRoomSelectionScreen(
            hotel: sampleHotel(),
            initialCriteria: criteria(),
          ),
        ),
        const Size(900, 1800),
      );
      // No selection yet → no CTA.
      expect(find.byKey(const Key('booking-continue-action')), findsNothing);

      app.selectRoom(100);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booking-continue-action')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('new UI25 keys resolve in EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      for (final pair in <List<String>>[
        [en.bookingContinueAction, vi.bookingContinueAction],
        [en.bookingSummaryTitle, vi.bookingSummaryTitle],
        [en.bookingGuestInfoTitle, vi.bookingGuestInfoTitle],
        [en.bookingReadyTitle, vi.bookingReadyTitle],
        [en.bookingReadyHeadline, vi.bookingReadyHeadline],
        [en.bookingPrepareAction, vi.bookingPrepareAction],
        [en.specialRequestLateCheckIn, vi.specialRequestLateCheckIn],
        [en.bookingValidationEmailInvalid, vi.bookingValidationEmailInvalid],
        [en.bookingGuestLocalOnlyNote, vi.bookingGuestLocalOnlyNote],
      ]) {
        expect(pair[0].trim(), isNotEmpty);
        expect(pair[1].trim(), isNotEmpty);
        expect(pair[0], isNot(equals(pair[1])));
      }
      expect(en.bookingStepLabel(1, 3), contains('1'));
      expect(vi.bookingStepLabel(2, 3), contains('2'));
    });
  });
}
