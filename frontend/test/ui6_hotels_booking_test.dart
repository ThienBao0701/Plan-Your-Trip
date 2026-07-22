import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/bookings/my_bookings_screen.dart';
import 'package:planyourtrip_frontend/features/home/home_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_booking_confirmation_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_booking_review_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_room_selection_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_search_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_utils.dart';
import 'package:planyourtrip_frontend/features/places/place_detail_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/shared/widgets/glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 7, 16, 9);

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

  AppState testState({bool demoMode = true}) {
    final app = AppState(
      now: () => today,
      bookingCodeGenerator: (sequence) =>
          'DEMO-${sequence.toString().padLeft(2, '0')}',
    )
      ..demoMode = demoMode
      ..email = demoMode ? MockData.demoEmail : 'real@example.com';
    app.demoBookings = [];
    app.demoPaymentAttempts = [];
    if (!demoMode) {
      app.trips = [];
      app.timeline = [];
      app.expenses = [];
    }
    return app;
  }

  Widget appHarness({
    required Widget child,
    AppState? app,
    Locale? locale,
    double textScaleFactor = 1,
  }) {
    return AppScope(
      notifier: app ?? testState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: child!,
          );
        },
        home: child,
      ),
    );
  }

  Future<void> pumpSize(
    WidgetTester tester,
    Widget child,
    Size size, {
    AppState? app,
    Locale? locale,
    double textScaleFactor = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(appHarness(
      child: child,
      app: app,
      locale: locale,
      textScaleFactor: textScaleFactor,
    ));
    await tester.pumpAndSettle();
  }

  Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      900,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  HotelStayCriteria criteria() => defaultHotelCriteria(
        today: today,
        trip: MockData.trips.first,
      );

  ({Place hotel, HotelRoom room, HotelRatePlan plan, HotelPricingQuote quote})
      quoteFixture() {
    final hotel = MockData.places.first;
    final room = hotel.hotelDetail!.rooms.first;
    final plan = room.ratePlans.first;
    final quote = buildLocalHotelQuote(
      hotel: hotel,
      room: room,
      ratePlan: plan,
      criteria: criteria(),
      generatedAt: today,
    );
    return (hotel: hotel, room: room, plan: plan, quote: quote);
  }

  DemoBooking bookingFixture({BookingStatus status = BookingStatus.confirmed}) {
    final fixture = quoteFixture();
    return DemoBooking(
      code: 'DEMO-01',
      hotel: fixture.hotel,
      room: fixture.room,
      ratePlan: fixture.plan,
      quote: fixture.quote,
      criteria: criteria(),
      status: status,
      createdAt: today,
    );
  }

  test('hotel criteria validation is date-only and guest-safe', () {
    final base = criteria();
    final endingToday = Trip(
      id: 99,
      title: 'Ending Today',
      destination: 'Hue',
      imageUrl: '',
      startDate: today.subtract(const Duration(days: 2)),
      endDate: today,
      travelers: 2,
      budget: 0,
    );
    final endingTodayCriteria = defaultHotelCriteria(
      today: today,
      trip: endingToday,
    );

    expect(endingTodayCriteria.checkIn, DateTime(2026, 7, 16));
    expect(endingTodayCriteria.checkOut, DateTime(2026, 7, 17));
    expect(
      validateHotelCriteria(endingTodayCriteria, today: today),
      isNull,
    );

    expect(
      validateHotelCriteria(
        base.copyWith(
            checkIn: DateTime(2026, 7, 15), checkOut: DateTime(2026, 7, 16)),
        today: today,
      ),
      HotelCriteriaError.pastCheckIn,
    );
    expect(
      validateHotelCriteria(
        base.copyWith(checkOut: base.checkIn),
        today: today,
      ),
      HotelCriteriaError.checkOutNotAfterCheckIn,
    );
    expect(
      validateHotelCriteria(base.copyWith(adults: 0), today: today),
      HotelCriteriaError.invalidAdults,
    );
    expect(
      validateHotelCriteria(base.copyWith(children: -1), today: today),
      HotelCriteriaError.invalidChildren,
    );
  });

  test('hotel discovery uses accommodation places only', () {
    final hotels = accommodationPlaces(MockData.places);

    expect(hotels, isNotEmpty);
    expect(
        hotels.every((place) => place.effectiveCategorySlug == 'accommodation'),
        isTrue);
    expect(hotels.map((place) => place.name), contains('Mây Lang Thang Villa'));
    expect(hotels.map((place) => place.name), isNot(contains('Bếp Quảng')));
  });

  test('room capacity and empty availability are deterministic', () {
    final hotel = MockData.places.first;

    expect(availableRoomsFor(hotel, criteria()), isNotEmpty);
    expect(
      availableRoomsFor(hotel, criteria().copyWith(adults: 12, children: 4)),
      isEmpty,
    );
  });

  test('canonical local quote uses finalQuotedPrice and no tax fields', () {
    final fixture = quoteFixture();

    expect(fixture.quote.finalQuotedPrice, fixture.quote.staySubtotal);
    expect(fixture.quote.finalQuotedPrice, greaterThan(0));
    expect(fixture.quote.warnings.single, contains('No inventory is reserved'));
  });

  test('booking sections are derived from dates and status', () {
    final upcoming = bookingFixture();
    final active = bookingFixture(status: BookingStatus.checkedIn).copyWith(
      criteria: HotelStayCriteria(
        destination: 'Da Lat',
        checkIn: today,
        checkOut: today.add(const Duration(days: 2)),
        adults: 2,
        tripId: 1,
      ),
    );
    final history = bookingFixture(status: BookingStatus.completed).copyWith(
      criteria: HotelStayCriteria(
        destination: 'Da Lat',
        checkIn: today.subtract(const Duration(days: 5)),
        checkOut: today.subtract(const Duration(days: 2)),
        adults: 2,
        tripId: 1,
      ),
    );
    final cancelled = bookingFixture(status: BookingStatus.cancelled);

    expect(bookingInSection(upcoming, BookingSection.upcoming, today: today),
        isTrue);
    expect(
        bookingInSection(active, BookingSection.active, today: today), isTrue);
    expect(bookingInSection(history, BookingSection.history, today: today),
        isTrue);
    expect(bookingInSection(cancelled, BookingSection.cancelled, today: today),
        isTrue);
  });

  testWidgets('hotel entry opens from Explore category', (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      Scaffold(body: HomeScreen(today: today)),
      const Size(900, 1400),
    );

    await tester.tap(find.text('Hotels').first);
    await tester.pumpAndSettle();

    expect(find.text('Search stays'), findsOneWidget);
    expect(find.text('Hotels'), findsWidgets);
  });

  testWidgets('hotel search is trip-aware and manual edits do not mutate trip',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = testState();

    await pumpSize(
      tester,
      HotelSearchScreen(today: today),
      const Size(900, 1400),
      app: app,
    );

    expect(find.text('Prefilled from Da Lat 3 days 2 nights'), findsOneWidget);
    final field = tester
        .widget<TextField>(find.byKey(const Key('hotel-destination-field')));
    expect(field.controller!.text, 'Da Lat');

    await tester.tap(find.byKey(const Key('hotel-adults-increment')));
    await tester.pumpAndSettle();

    expect(app.trips.first.travelers, 2);
    expect(find.text('3'), findsWidgets);
  });

  testWidgets('hotel search empty state is reachable', (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      HotelSearchScreen(
        today: today,
        initialCriteria: criteria().copyWith(destination: 'Nowhere'),
      ),
      const Size(900, 1400),
    );

    expect(find.text('No stays found'), findsOneWidget);
  });

  testWidgets('non-hotel place detail keeps hotel section hidden',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      PlaceDetailScreen(place: MockData.places[2]),
      const Size(900, 1400),
    );

    expect(find.text('Hotel details'), findsNothing);
    expect(find.text('Add to trip'), findsOneWidget);
  });

  testWidgets('hotel detail shows supported metadata and availability action',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      PlaceDetailScreen(place: MockData.places.first),
      const Size(900, 1400),
    );

    expect(find.text('Hotel details'), findsOneWidget);
    expect(find.text('4 stars'), findsOneWidget);
    expect(find.text('Check availability'), findsOneWidget);
    expect(find.textContaining('tax'), findsNothing);
  });

  testWidgets(
      'room selection blocks ineligible plans and continues with eligible plan',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      HotelRoomSelectionScreen(
        hotel: MockData.places.first,
        initialCriteria: criteria(),
        today: today,
        quoteTime: today,
      ),
      const Size(900, 1400),
    );

    await tester.tap(find.byKey(const Key('room-card-101')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rate-plan-1003')));
    await tester.pumpAndSettle();
    final disabledContinue = tester.widget<OceanPrimaryButton>(
      find.byKey(const Key('hotel-rate-continue')),
    );
    expect(disabledContinue.onPressed, isNull);
    expect(find.text('Booking review'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('rate-plan-1001')));
    await tester.tap(find.byKey(const Key('rate-plan-1001')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('hotel-rate-continue')));
    await tester.tap(find.byKey(const Key('hotel-rate-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Booking review'), findsOneWidget);
  });

  testWidgets('criteria changes invalidate stale room and rate selection',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      HotelRoomSelectionScreen(
        hotel: MockData.places.first,
        initialCriteria: criteria(),
        today: today,
        quoteTime: today,
      ),
      const Size(900, 1400),
    );

    await tester.tap(find.byKey(const Key('room-card-101')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rate-plan-1001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hotel-criteria-increment-adults')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hotel-rate-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Booking review'), findsNothing);
  });

  testWidgets('booking review omits taxes and shows customer benefits boundary',
      (tester) async {
    ignoreNetworkImageErrors();
    final semantics = tester.ensureSemantics();
    final fixture = quoteFixture();

    try {
      await pumpSize(
        tester,
        HotelBookingReviewScreen(
          hotel: fixture.hotel,
          room: fixture.room,
          ratePlan: fixture.plan,
          criteria: criteria(),
          quote: fixture.quote,
        ),
        const Size(900, 1400),
      );

      expect(find.text('Final quoted price'), findsOneWidget);
      expect(find.textContaining('Coupons, loyalty'), findsOneWidget);
      expect(find.textContaining('Tax'), findsNothing);
      expect(
          find.bySemanticsLabel(RegExp('Booking price quote')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('expired quote blocks confirmation', (tester) async {
    ignoreNetworkImageErrors();
    final fixture = quoteFixture();
    final expiredQuote = buildLocalHotelQuote(
      hotel: fixture.hotel,
      room: fixture.room,
      ratePlan: fixture.plan,
      criteria: criteria(),
      generatedAt: today.subtract(const Duration(hours: 1)),
    );
    final app = testState();

    await pumpSize(
      tester,
      HotelBookingReviewScreen(
        hotel: fixture.hotel,
        room: fixture.room,
        ratePlan: fixture.plan,
        criteria: criteria(),
        quote: expiredQuote,
      ),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.byKey(const Key('booking-terms-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking-confirm')));
    await tester.pumpAndSettle();

    expect(app.demoBookings, isEmpty);
    expect(
        find.text(
            'This quote has expired. Refresh criteria before confirming.'),
        findsOneWidget);
  });

  testWidgets('real mode shows checkout unavailable without fake booking',
      (tester) async {
    ignoreNetworkImageErrors();
    final fixture = quoteFixture();
    final app = testState(demoMode: false);

    await pumpSize(
      tester,
      HotelBookingReviewScreen(
        hotel: fixture.hotel,
        room: fixture.room,
        ratePlan: fixture.plan,
        criteria: criteria(),
        quote: fixture.quote,
      ),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.byKey(const Key('booking-terms-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking-confirm')));
    await tester.pumpAndSettle();

    expect(app.demoBookings, isEmpty);
    expect(find.byKey(const Key('secure-checkout-screen')), findsOneWidget);
    expect(
        find.textContaining(
            'Real checkout requires API/repository integration'),
        findsWidgets);
    final submit = tester.widget<OceanPrimaryButton>(
      find.byKey(const Key('checkout-submit')),
    );
    expect(submit.onPressed, isNull);
  });

  testWidgets('demo checkout creates one pending attempt then confirms on pay',
      (tester) async {
    ignoreNetworkImageErrors();
    final fixture = quoteFixture();
    final app = testState();

    await pumpSize(
      tester,
      HotelBookingReviewScreen(
        hotel: fixture.hotel,
        room: fixture.room,
        ratePlan: fixture.plan,
        criteria: criteria(),
        quote: fixture.quote,
      ),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.byKey(const Key('booking-terms-checkbox')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('secure-checkout-screen')), findsOneWidget);

    await scrollToAndTap(tester, find.byKey(const Key('checkout-submit')));

    expect(app.demoBookings.length, 1);
    expect(app.demoBookings.single.code, 'DEMO-01');
    expect(app.demoBookings.single.status, BookingStatus.pending);
    expect(app.demoPaymentAttempts.length, 1);
    expect(app.demoPaymentAttempts.single.paymentStatus,
        BookingPaymentStatus.pending);
    expect(find.byKey(const Key('payment-status-screen')), findsOneWidget);

    await scrollToAndTap(
        tester, find.byKey(const Key('payment-complete-demo')));
    expect(app.demoBookings.single.status, BookingStatus.confirmed);
    expect(app.demoBookings.single.paymentStatus, BookingPaymentStatus.paid);

    await scrollToAndTap(
        tester, find.byKey(const Key('payment-open-confirmation')));
    expect(find.text('Local demo booking'), findsOneWidget);
  });

  testWidgets('confirmation add-to-itinerary is explicit and duplicate-safe',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = testState();
    final booking = bookingFixture();
    app.demoBookings = [booking];

    await pumpSize(
      tester,
      HotelBookingConfirmationScreen(booking: booking),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.byKey(const Key('booking-add-itinerary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking-add-itinerary')));
    await tester.pumpAndSettle();

    final hotelItems = app.timeline.where((item) =>
        item.placeId == booking.hotel.id &&
        item.category == 'Hotel' &&
        item.title == booking.hotel.name);
    expect(hotelItems.length, 1);
    expect(app.demoBookings.single.itineraryAdded, isTrue);
  });

  testWidgets('My Bookings separates real and demo data', (tester) async {
    ignoreNetworkImageErrors();
    final real = testState(demoMode: false);

    await pumpSize(
      tester,
      const MyBookingsScreen(),
      const Size(900, 1400),
      app: real,
    );
    expect(find.text('Bookings not connected'), findsOneWidget);

    final demo = testState()..demoBookings = [bookingFixture()];
    await pumpSize(
      tester,
      const MyBookingsScreen(),
      const Size(900, 1400),
      app: demo,
    );
    expect(find.byKey(const Key('booking-card-DEMO-01')), findsOneWidget);
  });

  testWidgets('demo cancellation is local and safe', (tester) async {
    ignoreNetworkImageErrors();
    final app = testState()..demoBookings = [bookingFixture()];

    await pumpSize(
      tester,
      const MyBookingsScreen(),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.byKey(const Key('booking-card-DEMO-01')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking-cancel')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Changed plan');
    await tester.tap(find.text('Cancel booking').last);
    await tester.pumpAndSettle();

    expect(app.demoBookings.single.status, BookingStatus.cancelled);
    expect(app.demoBookings.single.cancellationReason, 'Changed plan');
  });

  testWidgets('Vietnamese hotel labels render', (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      HotelSearchScreen(today: today),
      const Size(900, 1400),
      locale: const Locale('vi'),
    );

    expect(find.text('Khách sạn'), findsWidgets);
    expect(find.text('Tìm chỗ ở'), findsOneWidget);
  });

  testWidgets('hotel flow supports narrow phone layout', (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      HotelSearchScreen(today: today),
      const Size(330, 720),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hotel flow supports wide layout', (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      HotelSearchScreen(today: today),
      const Size(1280, 820),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hotel booking supports enlarged text and key semantics',
      (tester) async {
    ignoreNetworkImageErrors();
    final semantics = tester.ensureSemantics();
    try {
      await pumpSize(
        tester,
        HotelSearchScreen(today: today),
        const Size(390, 820),
        textScaleFactor: 1.6,
      );

      expect(find.bySemanticsLabel('Search hotel stays'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Check availability for')),
          findsWidgets);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
