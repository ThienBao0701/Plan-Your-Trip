import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/bookings/my_bookings_screen.dart';
import 'package:planyourtrip_frontend/features/home/app_shell.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_utils.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _unset = Object();

void main() {
  final fixedNow = DateTime(2026, 7, 22, 10);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppState demoState() => AppState(now: () => fixedNow)
    ..demoMode = true
    ..email = MockData.demoEmail;

  AppState realState() => AppState(now: () => fixedNow)
    ..demoMode = false
    ..email = 'real@example.com'
    ..trips = []
    ..timeline = []
    ..expenses = []
    ..demoBookings = []
    ..travelWalletItems = []
    ..tripDocuments = []
    ..tripCollaborators = []
    ..sharedTrips = []
    ..tripNotes = []
    ..packingItems = []
    ..tripReminders = []
    ..reviews = []
    ..publicTripIds = {};

  Widget harness({
    required Widget child,
    AppState? app,
    Locale? locale,
    double textScaleFactor = 1,
  }) {
    return AppScope(
      notifier: app ?? demoState(),
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
    await tester.pumpWidget(
      harness(
        child: child,
        app: app,
        locale: locale,
        textScaleFactor: textScaleFactor,
      ),
    );
    await tester.pumpAndSettle();
  }

  DemoBooking bookingByCode(AppState app, String code) =>
      app.demoBookings.singleWhere((booking) => booking.code == code);

  HotelPricingQuote quoteWithPolicy(
    HotelPricingQuote quote, {
    CancellationPolicyType? cancellationPolicyType,
    bool? refundable,
    Object? cancellationDeadline = _unset,
  }) =>
      HotelPricingQuote(
        roomId: quote.roomId,
        roomName: quote.roomName,
        roomCode: quote.roomCode,
        placeId: quote.placeId,
        hotelId: quote.hotelId,
        checkIn: quote.checkIn,
        checkOut: quote.checkOut,
        nights: quote.nights,
        adults: quote.adults,
        children: quote.children,
        extraBeds: quote.extraBeds,
        selectedRatePlanId: quote.selectedRatePlanId,
        selectedRatePlanCode: quote.selectedRatePlanCode,
        selectedRatePlanName: quote.selectedRatePlanName,
        mealPlanType: quote.mealPlanType,
        cancellationPolicyType:
            cancellationPolicyType ?? quote.cancellationPolicyType,
        refundable: refundable ?? quote.refundable,
        cancellationDeadline: identical(cancellationDeadline, _unset)
            ? quote.cancellationDeadline
            : cancellationDeadline as DateTime?,
        baseNightlyRate: quote.baseNightlyRate,
        derivedAdjustment: quote.derivedAdjustment,
        occupancyAdjustment: quote.occupancyAdjustment,
        childSupplement: quote.childSupplement,
        extraBedSupplement: quote.extraBedSupplement,
        finalNightlyRate: quote.finalNightlyRate,
        staySubtotal: quote.staySubtotal,
        promotionDiscount: quote.promotionDiscount,
        totalBeforeCustomerBenefits: quote.totalBeforeCustomerBenefits,
        finalQuotedPrice: quote.finalQuotedPrice,
        currency: quote.currency,
        inventoryAvailable: quote.inventoryAvailable,
        availableRooms: quote.availableRooms,
        quoteGeneratedAt: quote.quoteGeneratedAt,
        quoteExpiresAt: quote.quoteExpiresAt,
        warnings: quote.warnings,
        eligibilityReason: quote.eligibilityReason,
      );

  test('backend booking and payment wire values remain stable', () {
    expect(
      BookingStatus.values.map((status) => status.code),
      [
        'PENDING',
        'CONFIRMED',
        'CHECK_IN_READY',
        'CHECKED_IN',
        'CHECKED_OUT',
        'COMPLETED',
        'CANCELLED',
        'REFUNDED',
        'ARCHIVED',
        'NO_SHOW',
      ],
    );
    expect(
      BookingPaymentStatus.values.map((status) => status.code),
      ['PENDING', 'PAID', 'FAILED', 'CANCELLED', 'REFUNDED'],
    );
    expect(BookingStatus.pending.canCancel, isTrue);
    expect(BookingStatus.confirmed.canCancel, isTrue);
    expect(BookingStatus.checkInReady.canCancel, isFalse);
    expect(BookingStatus.completed.canCancel, isFalse);
  });

  test('seeded bookings classify by backend-aligned sections', () {
    final app = demoState();
    final completed = bookingByCode(app, MockData.demoReviewBookingCode);
    final upcoming = bookingByCode(app, MockData.demoCancellationBookingCode);

    expect(completed.status, BookingStatus.completed);
    expect(bookingInSection(completed, BookingSection.history, today: fixedNow),
        isTrue);
    expect(
        bookingInSection(completed, BookingSection.upcoming, today: fixedNow),
        isFalse);
    expect(bookingInSection(completed, BookingSection.active, today: fixedNow),
        isFalse);
    expect(
        bookingInSection(completed, BookingSection.cancelled, today: fixedNow),
        isFalse);

    expect(upcoming.status, BookingStatus.confirmed);
    expect(bookingInSection(upcoming, BookingSection.upcoming, today: fixedNow),
        isTrue);
    expect(bookingInSection(upcoming, BookingSection.history, today: fixedNow),
        isFalse);
    expect(bookingInSection(upcoming, BookingSection.active, today: fixedNow),
        isFalse);
  });

  test('timeline uses only supported timestamps and stable ordering', () {
    final app = demoState();
    final completed = bookingByCode(app, MockData.demoReviewBookingCode);
    final upcoming = bookingByCode(app, MockData.demoCancellationBookingCode);

    expect(
      bookingTimelineFor(completed).map((event) => event.code),
      [
        'CREATED',
        'CONFIRMED',
        'PAID',
        'CHECKED_IN',
        'CHECKED_OUT',
        'COMPLETED',
      ],
    );
    expect(
      bookingTimelineFor(upcoming).map((event) => event.code),
      ['CREATED', 'CONFIRMED', 'PAID'],
    );

    final cancelled = upcoming.copyWith(
      status: BookingStatus.cancelled,
      cancelledAt: DateTime(2026, 7, 22, 10),
    );
    expect(bookingTimelineFor(cancelled).last.code, 'CANCELLED');
  });

  test('cancellation eligibility enforces owner and backend status rules', () {
    final app = demoState();
    final completed = bookingByCode(app, MockData.demoReviewBookingCode);
    final confirmed = bookingByCode(app, MockData.demoCancellationBookingCode);

    expect(app.cancellationEligibilityForBooking(confirmed).result,
        BookingCancellationResult.eligible);
    expect(app.cancellationEligibilityForBooking(completed).result,
        BookingCancellationResult.completed);

    app.demoBookings = [confirmed.copyWith(ownerUserId: 'other-user')];
    expect(
      app.cancellationEligibilityForBooking(app.demoBookings.single).result,
      BookingCancellationResult.forbidden,
    );

    app.demoBookings = [confirmed.copyWith(status: BookingStatus.checkInReady)];
    expect(
      app.cancellationEligibilityForBooking(app.demoBookings.single).result,
      BookingCancellationResult.checkInStarted,
    );

    final real = realState()..demoBookings = [confirmed];
    expect(real.cancellationEligibilityForBooking(confirmed).result,
        BookingCancellationResult.unavailable);
  });

  test(
      'cancellation remains status-based after deadline and non-refundable policy',
      () {
    final expiredApp = demoState();
    final confirmed =
        bookingByCode(expiredApp, MockData.demoCancellationBookingCode);
    final expiredFreeCancellation = confirmed.copyWith(
      quote: quoteWithPolicy(
        confirmed.quote,
        cancellationPolicyType: CancellationPolicyType.freeCancellation,
        refundable: true,
        cancellationDeadline: DateTime(2026, 7, 1, 9),
      ),
    );
    expiredApp.demoBookings = [expiredFreeCancellation];

    expect(
      expiredApp
          .cancellationEligibilityForBooking(expiredFreeCancellation)
          .result,
      BookingCancellationResult.eligible,
    );
    expect(
      expiredApp.cancelDemoBookingWithResult(expiredFreeCancellation.code),
      BookingCancellationResult.eligible,
    );
    final cancelled = bookingByCode(expiredApp, expiredFreeCancellation.code);
    expect(cancelled.status, BookingStatus.cancelled);
    expect(cancelled.cancellationReason, isNull);
    expect(cancelled.paymentStatus, BookingPaymentStatus.paid);

    final nonRefundableApp = demoState();
    final nonRefundable =
        bookingByCode(nonRefundableApp, MockData.demoCancellationBookingCode)
            .copyWith(
      quote: quoteWithPolicy(
        confirmed.quote,
        cancellationPolicyType: CancellationPolicyType.nonRefundable,
        refundable: false,
        cancellationDeadline: null,
      ),
    );
    nonRefundableApp.demoBookings = [nonRefundable];

    expect(
      nonRefundableApp.cancellationEligibilityForBooking(nonRefundable).result,
      BookingCancellationResult.eligible,
    );
    expect(
      nonRefundableApp.cancelDemoBookingWithResult(
        nonRefundable.code,
        reason: ' ',
      ),
      BookingCancellationResult.eligible,
    );
    expect(
      bookingByCode(nonRefundableApp, nonRefundable.code).cancellationReason,
      isNull,
    );
  });

  test('demo cancellation preserves booking snapshot and related state', () {
    final app = demoState();
    final booking = bookingByCode(app, MockData.demoCancellationBookingCode);
    final totalBefore = booking.quote.finalQuotedPrice;
    final currencyBefore = booking.quote.currency;
    final roomBefore = booking.room.id;
    final rateBefore = booking.ratePlan.ratePlanId;
    final paymentBefore = booking.paymentStatus;
    final reviewCount = app.reviews.length;
    final walletCount = app.travelWalletItems.length;
    final rewardsBalance = app.travelCreditAccount?.balanceMinor;
    final expenseCount = app.expenses.length;

    final imported = app.importDemoBookingToWallet(booking.code);
    expect(imported, isNotNull);
    final walletSnapshot = imported!;

    expect(
      app.cancelDemoBookingWithResult(booking.code, reason: 'Changed plan'),
      BookingCancellationResult.eligible,
    );
    final cancelled = bookingByCode(app, booking.code);

    expect(cancelled.status, BookingStatus.cancelled);
    expect(cancelled.cancelledAt, fixedNow.toUtc());
    expect(cancelled.cancellationReason, 'Changed plan');
    expect(cancelled.quote.finalQuotedPrice, totalBefore);
    expect(cancelled.quote.currency, currencyBefore);
    expect(cancelled.room.id, roomBefore);
    expect(cancelled.ratePlan.ratePlanId, rateBefore);
    expect(cancelled.paymentStatus, paymentBefore);
    expect(cancelled.refundedAt, isNull);
    expect(app.reviews.length, reviewCount);
    expect(app.travelWalletItems.length, walletCount + 1);
    expect(
      app.travelWalletItems.singleWhere((item) => item.id == walletSnapshot.id),
      same(walletSnapshot),
    );
    expect(app.travelCreditAccount?.balanceMinor, rewardsBalance);
    expect(app.expenses.length, expenseCount);
    expect(
      app.cancelDemoBookingWithResult(booking.code),
      BookingCancellationResult.alreadyCancelled,
    );
  });

  test('review eligibility and public aggregates survive booking management',
      () {
    final app = demoState();
    final booking = bookingByCode(app, MockData.demoReviewBookingCode);
    final summaryBefore = app.reviewSummaryForPlace(booking.hotel.id);

    expect(app.reviewEligibilityForBooking(booking).canReview, isTrue);
    expect(
      app.createDemoReviewForBooking(
        bookingCode: booking.code,
        ratingOverall: 5,
        title: 'Pending stay note',
        content: 'Local pending review remains private.',
      ),
      ReviewActionResult.success,
    );

    final updated = bookingByCode(app, booking.code);
    final summaryAfter = app.reviewSummaryForPlace(booking.hotel.id);
    expect(updated.status, BookingStatus.completed);
    expect(app.reviewEligibilityForBooking(updated).result,
        ReviewActionResult.duplicate);
    expect(summaryAfter.total, summaryBefore.total);
    expect(summaryAfter.average, summaryBefore.average);
    expect(app.myReviews(status: ReviewStatus.pending), isNotEmpty);
    expect(
        app.publicReviewsForPlace(booking.hotel.id).any(
              (review) => review.bookingCode == booking.code,
            ),
        isFalse);
  });

  test('demo and real mode remain isolated through reset and logout', () async {
    final real = realState();
    expect(real.demoBookings, isEmpty);
    expect(
      real.cancelDemoBookingWithResult(MockData.demoCancellationBookingCode),
      BookingCancellationResult.notFound,
    );

    final app = demoState();
    app.demoBookings = [];
    app.api.token = 'token';
    await app.logout();

    expect(app.api.token, isNull);
    expect(app.demoMode, isTrue);
    expect(
      app.demoBookings
          .where((booking) => booking.code == MockData.demoReviewBookingCode),
      hasLength(1),
    );
    expect(
      app.demoBookings.where(
          (booking) => booking.code == MockData.demoCancellationBookingCode),
      hasLength(1),
    );
  });

  test('wallet and itinerary actions are idempotent', () {
    final app = demoState();
    final booking = bookingByCode(app, MockData.demoCancellationBookingCode);

    final wallet = app.importDemoBookingToWallet(booking.code);
    final duplicateWallet = app.importDemoBookingToWallet(booking.code);
    expect(wallet, isNotNull);
    expect(duplicateWallet!.id, wallet!.id);
    expect(
      app.travelWalletItems
          .where((item) => item.linkedBookingId == booking.code),
      hasLength(1),
    );

    expect(itineraryAlreadyHasBooking(app.timeline, booking), isFalse);
    final trip = app.tripById(booking.criteria.tripId!);
    expect(trip, isNotNull);
    app.addTimeline(TimelineItem(
      id: app.newId,
      tripId: trip!.id,
      dayNumber: 1,
      startTime: '15:00',
      endTime: '16:00',
      title: booking.hotel.name,
      notes: 'Local booking',
      place: booking.hotel,
      placeId: booking.hotel.id,
      category: 'Hotel',
      estimatedCost: booking.quote.finalQuotedPrice ?? 0,
    ));
    expect(itineraryAlreadyHasBooking(app.timeline, booking), isTrue);
    expect(app.markDemoBookingItineraryAdded(booking.code), isTrue);
    expect(app.markDemoBookingItineraryAdded(booking.code), isTrue);
    expect(bookingByCode(app, booking.code).itineraryAdded, isTrue);
    expect(
      app.timeline.where((item) =>
          item.tripId == trip.id &&
          item.placeId == booking.hotel.id &&
          item.title == booking.hotel.name),
      hasLength(1),
    );
  });

  test('UI-11 review media and property replies remain available', () {
    final app = demoState();
    final public = app.publicReviewsForPlace(1);

    expect(public.any((review) => review.visibleMedia.isNotEmpty), isTrue);
    expect(public.any((review) => review.hasPartnerReply), isTrue);
  });

  testWidgets('My Bookings filters and detail route expose stay details',
      (tester) async {
    final app = demoState();

    await pumpSize(
      tester,
      MyBookingsScreen(today: fixedNow),
      const Size(900, 1400),
      app: app,
    );

    expect(
      find.byKey(const Key('booking-card-${MockData.demoReviewBookingCode}')),
      findsOneWidget,
    );
    expect(
      find.byKey(
          const Key('booking-card-${MockData.demoCancellationBookingCode}')),
      findsOneWidget,
    );

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('booking-card-${MockData.demoReviewBookingCode}')),
      findsOneWidget,
    );
    expect(
      find.byKey(
          const Key('booking-card-${MockData.demoCancellationBookingCode}')),
      findsNothing,
    );

    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    final card = find.byKey(
        const Key('booking-card-${MockData.demoCancellationBookingCode}'));
    expect(card, findsOneWidget);

    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('booking-detail-screen')), findsOneWidget);
    expect(find.text('Stay overview'), findsOneWidget);
    expect(find.text('Room and rate snapshot'), findsOneWidget);
    expect(find.text('Premier Ocean Twin'), findsWidgets);
    expect(find.text('Ocean breakfast'), findsOneWidget);
    expect(find.text('Status timeline'), findsOneWidget);
    expect(find.text('Booking actions'), findsOneWidget);
    expect(find.text('Paid'), findsWidgets);
    expect(find.textContaining('Refund calculation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('booking detail cancellation flow is explicit and local',
      (tester) async {
    final app = demoState();
    final booking = bookingByCode(app, MockData.demoCancellationBookingCode);
    final totalBefore = booking.quote.finalQuotedPrice;

    await pumpSize(
      tester,
      BookingDetailScreen(bookingCode: booking.code, today: fixedNow),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.byKey(const Key('booking-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('Cancel demo booking?'), findsOneWidget);
    expect(find.textContaining('no backend request is sent'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('booking-cancel-reason-field')),
      'Weather changed',
    );
    await tester.tap(find.byKey(const Key('booking-cancel-confirm')));
    await tester.pumpAndSettle();

    final cancelled = bookingByCode(app, booking.code);
    expect(cancelled.status, BookingStatus.cancelled);
    expect(cancelled.cancellationReason, 'Weather changed');
    expect(cancelled.quote.finalQuotedPrice, totalBefore);
    expect(find.text('Cancelled'), findsWidgets);
    expect(find.byKey(const Key('booking-cancel')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'expired free-cancellation deadline warns without blocking cancel',
      (tester) async {
    final app = demoState();
    final booking = bookingByCode(app, MockData.demoCancellationBookingCode);
    final expired = booking.copyWith(
      quote: quoteWithPolicy(
        booking.quote,
        cancellationPolicyType: CancellationPolicyType.freeCancellation,
        refundable: true,
        cancellationDeadline: DateTime(2026, 7, 1, 9),
      ),
    );
    app.demoBookings = [expired];

    await pumpSize(
      tester,
      BookingDetailScreen(bookingCode: expired.code, today: fixedNow),
      const Size(900, 1400),
      app: app,
    );

    expect(find.text('Free-cancellation window passed'), findsOneWidget);
    expect(find.textContaining('full-penalty cancellation'), findsWidgets);
    expect(find.byKey(const Key('booking-cancel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('booking-cancel')));
    await tester.pumpAndSettle();

    expect(find.textContaining('full-penalty cancellation'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('booking detail does not render stale fallback after reset',
      (tester) async {
    final app = demoState();
    final stale = bookingByCode(app, MockData.demoCancellationBookingCode);
    app.demoBookings = [];

    await pumpSize(
      tester,
      BookingDetailScreen(
        bookingCode: stale.code,
        fallbackBooking: stale,
        today: fixedNow,
      ),
      const Size(900, 1400),
      app: app,
    );

    expect(find.text('Booking unavailable'), findsOneWidget);
    expect(find.text(stale.hotel.name), findsNothing);
    expect(find.byKey(const Key('booking-cancel')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed booking cannot cancel and still opens review composer',
      (tester) async {
    final app = demoState();
    final booking = bookingByCode(app, MockData.demoReviewBookingCode);

    await pumpSize(
      tester,
      BookingDetailScreen(bookingCode: booking.code, today: fixedNow),
      const Size(900, 1400),
      app: app,
    );

    expect(
      find.text('Completed and historical stays cannot be cancelled.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('booking-cancel')), findsNothing);

    await tester.tap(find.byKey(const Key('booking-detail-write-review')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('write-review-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real mode shows unavailable booking state', (tester) async {
    await pumpSize(
      tester,
      const MyBookingsScreen(),
      const Size(900, 1400),
      app: realState(),
    );

    expect(find.text('Bookings not connected'), findsOneWidget);
    expect(find.byKey(const Key('booking-detail-screen')), findsNothing);
  });

  testWidgets(
      'booking screens support narrow, wide, Vietnamese, and large text',
      (tester) async {
    final app = demoState();

    await pumpSize(
      tester,
      MyBookingsScreen(today: fixedNow),
      const Size(430, 932),
      app: app,
    );
    expect(find.text('My Bookings'), findsWidgets);
    expect(tester.takeException(), isNull);

    await pumpSize(
      tester,
      BookingDetailScreen(
        bookingCode: MockData.demoCancellationBookingCode,
        today: fixedNow,
      ),
      const Size(1440, 900),
      app: app,
    );
    expect(find.text('Booking details'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpSize(
      tester,
      BookingDetailScreen(
        bookingCode: MockData.demoCancellationBookingCode,
        today: fixedNow,
      ),
      const Size(1920, 1080),
      app: app,
      textScaleFactor: 1.4,
    );
    expect(find.byKey(const Key('booking-detail-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpSize(
      tester,
      BookingDetailScreen(
        bookingCode: MockData.demoCancellationBookingCode,
        today: fixedNow,
      ),
      const Size(430, 932),
      app: app,
      locale: const Locale('vi'),
    );
    expect(find.text('Chi tiết đặt phòng'), findsOneWidget);
    expect(find.text('Dòng thời gian trạng thái'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppShell remains four tabs and nonblank after switching',
      (tester) async {
    await pumpSize(
      tester,
      const AppShell(),
      const Size(900, 1400),
      app: demoState(),
    );

    for (final label in ['Explore', 'Trips', 'Planner', 'Profile']) {
      expect(find.bySemanticsLabel('$label tab'), findsOneWidget);
    }
    for (final label in ['Trips', 'Planner', 'Profile', 'Explore']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test('English and Vietnamese booking localization stays in parity', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vi = jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
        as Map<String, dynamic>;
    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    final viKeys = vi.keys.where((key) => !key.startsWith('@')).toSet();

    expect(enKeys.difference(viKeys), isEmpty);
    expect(viKeys.difference(enKeys), isEmpty);

    final bookingKeys = enKeys.where((key) => key.startsWith('booking'));
    expect(bookingKeys, contains('bookingStayOverviewTitle'));
    expect(bookingKeys, contains('bookingTimelineTitle'));
    expect(bookingKeys, contains('bookingCancellationUnavailableCompleted'));

    for (final key in enKeys) {
      final enMeta = en['@$key'];
      final viMeta = vi['@$key'];
      if (enMeta is Map && enMeta['placeholders'] != null) {
        expect(viMeta, isA<Map>(), reason: key);
        expect(
          (enMeta['placeholders'] as Map).keys.toSet(),
          ((viMeta as Map)['placeholders'] as Map).keys.toSet(),
          reason: key,
        );
      }
    }
  });
}
