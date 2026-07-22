import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/bookings/modify_booking_screen.dart';
import 'package:planyourtrip_frontend/features/bookings/my_bookings_screen.dart';
import 'package:planyourtrip_frontend/features/home/app_shell.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_utils.dart';
import 'package:planyourtrip_frontend/features/payments/secure_checkout_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 22, 10);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppState demoState() => AppState(
        now: () => fixedNow,
        bookingCodeGenerator: (sequence) =>
            'UI14-${sequence.toString().padLeft(2, '0')}',
      )
        ..demoMode = true
        ..email = MockData.demoEmail;

  AppState realState() => AppState(now: () => fixedNow)
    ..demoMode = false
    ..email = 'real@example.com'
    ..trips = []
    ..timeline = []
    ..expenses = []
    ..demoBookings = []
    ..demoPaymentAttempts = []
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

  DemoBooking modificationBooking(AppState app) => app.demoBookings.singleWhere(
        (booking) => booking.code == MockData.demoModificationBookingCode,
      );

  BookingModificationDraft draftFor(
    DemoBooking booking, {
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
    int? children,
    int? extraBeds,
    int? ratePlanId,
  }) =>
      BookingModificationDraft(
        checkIn: checkIn ?? booking.criteria.checkIn,
        checkOut: checkOut ?? booking.criteria.checkOut,
        adults: adults ?? booking.criteria.adults,
        children: children ?? booking.criteria.children,
        extraBeds: extraBeds ?? booking.criteria.extraBeds,
        ratePlanId: ratePlanId ?? booking.ratePlan.ratePlanId,
      );

  HotelPricingQuote quoteFor(
    DemoBooking booking,
    BookingModificationDraft draft, {
    HotelRatePlan? ratePlan,
  }) {
    final selected = ratePlan ??
        booking.room.ratePlans.singleWhere(
          (plan) => plan.ratePlanId == draft.ratePlanId,
        );
    return buildLocalHotelQuote(
      hotel: booking.hotel,
      room: booking.room,
      ratePlan: selected,
      criteria: booking.criteria.copyWith(
        checkIn: draft.checkIn,
        checkOut: draft.checkOut,
        adults: draft.adults,
        children: draft.children,
        extraBeds: draft.extraBeds,
      ),
      generatedAt: fixedNow,
      currency: booking.quote.currency,
    );
  }

  BookingModificationResult applyDraft(
    AppState app,
    DemoBooking booking,
    BookingModificationDraft draft, {
    HotelRatePlan? ratePlan,
    HotelPricingQuote? quote,
    DateTime? expectedVersion,
  }) {
    final selected = ratePlan ??
        booking.room.ratePlans.singleWhere(
          (plan) => plan.ratePlanId == draft.ratePlanId,
        );
    return app.modifyDemoBooking(
      bookingCode: booking.code,
      expectedVersion: expectedVersion ?? booking.modificationVersion,
      draft: draft,
      ratePlan: selected,
      proposedQuote: quote ?? quoteFor(booking, draft, ratePlan: selected),
    );
  }

  Future<void> enterModifyValue(
    WidgetTester tester,
    int fieldIndex,
    String value,
  ) async {
    await tester.enterText(find.byType(TextFormField).at(fieldIndex), value);
    await tester.pump();
  }

  Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      700,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test('backend modification request fields and status wire values are stable',
      () {
    expect(
      BookingModificationDraft.backendRequestFields,
      ['checkIn', 'checkOut', 'adults', 'children', 'extraBeds', 'ratePlanId'],
    );
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
  });

  test('eligibility allows only current-owner pending bookings before payment',
      () {
    final app = demoState();
    final pending = modificationBooking(app);

    expect(pending.status, BookingStatus.pending);
    expect(app.latestPaymentAttemptForBooking(pending.code), isNull);
    expect(app.modificationEligibilityForBooking(pending).result,
        BookingModificationResult.available);

    for (final status in BookingStatus.values.where(
      (status) => status != BookingStatus.pending,
    )) {
      app.demoBookings = [pending.copyWith(status: status)];
      expect(
        app.modificationEligibilityForBooking(app.demoBookings.single).result,
        BookingModificationResult.onlyPending,
        reason: status.code,
      );
    }

    app.demoBookings = [pending.copyWith(ownerUserId: 'demo-editor')];
    expect(
        app.modificationEligibilityForBooking(app.demoBookings.single).result,
        BookingModificationResult.forbidden);

    expect(
      app
          .modificationEligibilityForBooking(
            pending.copyWith(code: 'PYT-DEMO-MISSING'),
          )
          .result,
      BookingModificationResult.notFound,
    );

    final real = realState()..demoBookings = [pending];
    expect(real.modificationEligibilityForBooking(pending).result,
        BookingModificationResult.unavailable);
  });

  test('date, guest, capacity, no-change, and stale submissions are rejected',
      () {
    final app = demoState();
    final booking = modificationBooking(app);
    final valid = draftFor(
      booking,
      checkOut: booking.criteria.checkOut.add(const Duration(days: 1)),
    );

    expect(
      applyDraft(app, booking, draftFor(booking)),
      BookingModificationResult.noChanges,
    );
    expect(
      applyDraft(
        app,
        booking,
        draftFor(
          booking,
          checkIn: fixedNow.subtract(const Duration(days: 1)),
        ),
      ),
      BookingModificationResult.invalidDates,
    );
    expect(
      applyDraft(app, booking, draftFor(booking, adults: 0)),
      BookingModificationResult.invalidGuests,
    );
    expect(
      applyDraft(app, booking, draftFor(booking, adults: 4)),
      BookingModificationResult.capacityExceeded,
    );

    app.updateDemoBooking(booking.copyWith(
      updatedAt: fixedNow.add(const Duration(minutes: 1)),
    ));
    expect(
      applyDraft(app, modificationBooking(app), valid,
          expectedVersion: booking.modificationVersion),
      BookingModificationResult.stale,
    );
  });

  test('successful demo modification preserves identity and unrelated state',
      () {
    final app = demoState();
    final booking = modificationBooking(app);
    final walletCount = app.travelWalletItems.length;
    final rewardBalance = app.travelCreditAccount?.balanceMinor;
    final reviewCount = app.reviews.length;
    final tripCount = app.trips.length;
    final paymentCount = app.demoPaymentAttempts.length;
    final draft = draftFor(
      booking,
      checkOut: DateTime(2026, 8, 15),
      children: 1,
    );

    final result = applyDraft(app, booking, draft);

    expect(result, BookingModificationResult.available);
    final changed = modificationBooking(app);
    expect(changed.code, booking.code);
    expect(changed.ownerUserId, booking.ownerUserId);
    expect(changed.hotel.id, booking.hotel.id);
    expect(changed.room.id, booking.room.id);
    expect(changed.status, BookingStatus.pending);
    expect(changed.paymentStatus, isNull);
    expect(changed.criteria.checkOut, DateTime(2026, 8, 15));
    expect(changed.criteria.children, 1);
    expect(changed.quote.currency, booking.quote.currency);
    expect(changed.quote.finalQuotedPrice, 3750000);
    expect(changed.modifiedAt, fixedNow.toUtc());
    expect(bookingTimelineFor(changed).map((event) => event.code),
        ['CREATED', 'MODIFIED']);
    expect(app.travelWalletItems.length, walletCount);
    expect(app.travelCreditAccount?.balanceMinor, rewardBalance);
    expect(app.reviews.length, reviewCount);
    expect(app.trips.length, tripCount);
    expect(app.demoPaymentAttempts.length, paymentCount);
  });

  test('price-affecting changes use local estimate and never invent refunds',
      () {
    final app = demoState();
    final booking = modificationBooking(app);
    final cheaperPlan = booking.room.ratePlans.singleWhere(
      (plan) => plan.ratePlanId == 1002,
    );
    final draft = draftFor(booking, ratePlanId: cheaperPlan.ratePlanId);

    expect(
      app.demoPaymentAttempts.where((item) => item.bookingCode == booking.code),
      isEmpty,
    );
    expect(
        app.travelCreditTransactions
            .where((item) => item.referenceId == booking.code),
        isEmpty);

    final result = applyDraft(app, booking, draft, ratePlan: cheaperPlan);

    final changed = modificationBooking(app);
    expect(result, BookingModificationResult.available);
    expect(changed.ratePlan.ratePlanId, cheaperPlan.ratePlanId);
    expect(changed.quote.finalQuotedPrice, 2200000);
    expect(changed.paymentStatus, isNull);
    expect(changed.refundedAt, isNull);
    expect(app.demoPaymentAttempts.length, MockData.demoPaymentAttempts.length);
    expect(
        app.travelCreditTransactions
            .where((item) => item.referenceId == booking.code),
        isEmpty);
  });

  test('extra beds are preserved unless reset explicitly', () {
    final app = demoState();
    final original = modificationBooking(app);
    app.updateDemoBooking(original.copyWith(
      criteria: original.criteria.copyWith(extraBeds: 1),
    ));

    expect(
      applyDraft(
        app,
        modificationBooking(app),
        draftFor(
          modificationBooking(app),
          checkOut: DateTime(2026, 8, 15),
        ),
      ),
      BookingModificationResult.available,
    );
    expect(modificationBooking(app).criteria.extraBeds, 1);

    final afterDate = modificationBooking(app);
    expect(
      applyDraft(
        app,
        afterDate,
        draftFor(afterDate, adults: 1, children: 1),
      ),
      BookingModificationResult.available,
    );
    expect(modificationBooking(app).criteria.extraBeds, 1);

    final afterGuests = modificationBooking(app);
    final cheaperPlan = afterGuests.room.ratePlans.singleWhere(
      (plan) => plan.ratePlanId == 1002,
    );
    expect(
      applyDraft(
        app,
        afterGuests,
        draftFor(afterGuests, ratePlanId: cheaperPlan.ratePlanId),
        ratePlan: cheaperPlan,
      ),
      BookingModificationResult.available,
    );
    expect(modificationBooking(app).criteria.extraBeds, 1);

    final afterRate = modificationBooking(app);
    expect(
      applyDraft(
        app,
        afterRate,
        draftFor(afterRate, extraBeds: 0),
      ),
      BookingModificationResult.available,
    );
    expect(modificationBooking(app).criteria.extraBeds, 0);

    final afterReset = modificationBooking(app);
    expect(
      applyDraft(
        app,
        afterReset,
        draftFor(afterReset, extraBeds: 3),
      ),
      BookingModificationResult.available,
    );
    expect(modificationBooking(app).criteria.extraBeds, 3);
    expect(
      applyDraft(
        app,
        modificationBooking(app),
        draftFor(modificationBooking(app), adults: 4),
      ),
      BookingModificationResult.capacityExceeded,
    );
  });

  test(
      'payment attempts lock modification and checkout attaches to same booking',
      () {
    final app = demoState();
    final booking = modificationBooking(app);
    final draft = draftFor(
      booking,
      checkOut: DateTime(2026, 8, 15),
    );
    expect(
        applyDraft(app, booking, draft), BookingModificationResult.available);
    final changed = modificationBooking(app);

    final result = app.startDemoPaymentForExistingBooking(
      bookingCode: changed.code,
      provider: CheckoutPaymentProvider.mock,
      idempotencyKey: 'ui14-existing-checkout',
    );
    final duplicate = app.startDemoPaymentForExistingBooking(
      bookingCode: changed.code,
      provider: CheckoutPaymentProvider.mock,
      idempotencyKey: 'ui14-existing-checkout',
    );

    expect(result.result, DemoPaymentActionResult.success);
    expect(duplicate.result, DemoPaymentActionResult.duplicate);
    expect(app.demoBookings.where((item) => item.code == changed.code),
        hasLength(1));
    expect(result.attempt!.bookingCode, changed.code);
    expect(result.attempt!.amount, changed.quote.finalQuotedPrice);
    expect(app.modificationEligibilityForBooking(changed).result,
        BookingModificationResult.activePaymentStarted);
  });

  testWidgets('modify screen pre-fills, reviews, and confirms explicitly',
      (tester) async {
    final app = demoState();
    final booking = modificationBooking(app);

    await pumpSize(
      tester,
      ModifyBookingScreen(bookingCode: booking.code, today: fixedNow),
      const Size(430, 932),
      app: app,
    );

    expect(find.text('Modify booking'), findsWidgets);
    expect(find.text('2026-08-12'), findsOneWidget);
    expect(find.text('2026-08-14'), findsOneWidget);
    await enterModifyValue(tester, 1, '2026-08-15');
    await scrollToAndTap(tester, find.byKey(const Key('modify-review-action')));

    expect(modificationBooking(app).criteria.checkOut, DateTime(2026, 8, 14));
    expect(find.text('Review changes'), findsWidgets);
    expect(find.text('Changed'), findsWidgets);
    expect(find.textContaining('Current'), findsWidgets);
    expect(find.textContaining('Proposed'), findsWidgets);

    await scrollToAndTap(
        tester, find.byKey(const Key('modify-confirm-action')));

    expect(find.byType(ModifyBookingScreen), findsNothing);
    expect(modificationBooking(app).criteria.checkOut, DateTime(2026, 8, 15));
  });

  testWidgets('extra-bed reset is explicit and visible in review',
      (tester) async {
    final app = demoState();
    final booking = modificationBooking(app);
    app.updateDemoBooking(booking.copyWith(
      criteria: booking.criteria.copyWith(extraBeds: 1),
    ));

    await pumpSize(
      tester,
      ModifyBookingScreen(bookingCode: booking.code, today: fixedNow),
      const Size(430, 932),
      app: app,
    );

    expect(find.text('Extra beds'), findsWidgets);
    expect(find.widgetWithText(TextFormField, '1'), findsOneWidget);
    await enterModifyValue(tester, 4, '0');
    await scrollToAndTap(tester, find.byKey(const Key('modify-review-action')));

    expect(modificationBooking(app).criteria.extraBeds, 1);
    expect(find.text('Review changes'), findsWidgets);
    expect(find.text('Extra beds'), findsWidgets);
    expect(find.text('Current: 1'), findsOneWidget);
    expect(find.text('Proposed: 0'), findsOneWidget);

    await scrollToAndTap(
        tester, find.byKey(const Key('modify-confirm-action')));

    expect(modificationBooking(app).criteria.extraBeds, 0);
  });

  testWidgets('back from review keeps the original booking unchanged',
      (tester) async {
    final app = demoState();
    final booking = modificationBooking(app);

    await pumpSize(
      tester,
      ModifyBookingScreen(bookingCode: booking.code, today: fixedNow),
      const Size(1440, 900),
      app: app,
    );
    await enterModifyValue(tester, 1, '2026-08-15');
    await scrollToAndTap(tester, find.byKey(const Key('modify-review-action')));
    await scrollToAndTap(
        tester, find.byKey(const Key('modify-back-edit-action')));

    expect(find.text('Edit supported fields'), findsOneWidget);
    expect(modificationBooking(app).criteria.checkOut, DateTime(2026, 8, 14));
  });

  testWidgets('booking detail shows modify action and updated values',
      (tester) async {
    final app = demoState();
    final booking = modificationBooking(app);

    await pumpSize(
      tester,
      BookingDetailScreen(bookingCode: booking.code, today: fixedNow),
      const Size(1920, 1080),
      app: app,
    );

    expect(find.byKey(const Key('booking-detail-modify')), findsOneWidget);
    await scrollToAndTap(
        tester, find.byKey(const Key('booking-detail-modify')));
    await enterModifyValue(tester, 1, '2026-08-15');
    await scrollToAndTap(tester, find.byKey(const Key('modify-review-action')));
    await scrollToAndTap(
        tester, find.byKey(const Key('modify-confirm-action')));

    expect(find.byType(BookingDetailScreen), findsOneWidget);
    expect(find.textContaining('Aug 15'), findsWidgets);
    expect(find.text('Booking modified'), findsOneWidget);
  });

  testWidgets('secure checkout continues from modified pending booking',
      (tester) async {
    final app = demoState();
    final booking = modificationBooking(app);
    final draft = draftFor(booking, checkOut: DateTime(2026, 8, 15));
    expect(
        applyDraft(app, booking, draft), BookingModificationResult.available);
    final changed = modificationBooking(app);

    await pumpSize(
      tester,
      SecureCheckoutScreen(
        hotel: changed.hotel,
        room: changed.room,
        ratePlan: changed.ratePlan,
        criteria: changed.criteria,
        quote: changed.quote,
        existingBookingCode: changed.code,
      ),
      const Size(430, 932),
      app: app,
    );

    expect(find.text('Secure checkout'), findsWidgets);
    await scrollToAndTap(tester, find.byKey(const Key('checkout-submit')));

    expect(app.demoBookings.where((item) => item.code == changed.code),
        hasLength(1));
    expect(app.latestPaymentAttemptForBooking(changed.code), isNotNull);
    expect(find.byKey(const Key('payment-status-screen')), findsOneWidget);
  });

  testWidgets('settled bookings show unavailable modification reason',
      (tester) async {
    final app = demoState();
    final confirmed = app.demoBookings.singleWhere(
      (booking) => booking.code == MockData.demoCancellationBookingCode,
    );

    await pumpSize(
      tester,
      BookingDetailScreen(bookingCode: confirmed.code, today: fixedNow),
      const Size(430, 932),
      app: app,
      textScaleFactor: 1.35,
    );

    expect(find.byKey(const Key('booking-detail-modify')), findsNothing);
    expect(find.text('Only pending bookings can be changed.'), findsOneWidget);
  });

  testWidgets('accessibility semantics include safe modification labels',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final app = demoState();
    final booking = modificationBooking(app);
    try {
      await pumpSize(
        tester,
        ModifyBookingScreen(bookingCode: booking.code, today: fixedNow),
        const Size(430, 932),
        app: app,
      );

      expect(find.bySemanticsLabel('Modify this pending demo booking'),
          findsOneWidget);
      expect(find.bySemanticsLabel('Local booking reference'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('AppShell remains four tabs and nonblank after tab switching',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final app = demoState();
    try {
      await pumpSize(
        tester,
        const AppShell(),
        const Size(430, 932),
        app: app,
      );

      for (final label in ['Explore', 'Trips', 'Planner', 'Profile']) {
        expect(find.bySemanticsLabel('$label tab'), findsOneWidget);
      }
      for (final label in ['Trips', 'Planner', 'Profile', 'Explore']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsWidgets);
        expect(find.byType(Scrollable), findsWidgets);
      }
    } finally {
      semantics.dispose();
    }
  });

  test('English and Vietnamese ARB keys and placeholders remain in parity', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vi = jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
        as Map<String, dynamic>;
    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    final viKeys = vi.keys.where((key) => !key.startsWith('@')).toSet();

    expect(enKeys.difference(viKeys), isEmpty);
    expect(viKeys.difference(enKeys), isEmpty);
    expect(enKeys.length, viKeys.length);

    for (final key in enKeys) {
      final enPlaceholders =
          (en['@$key']?['placeholders'] as Map?)?.keys.cast<String>().toSet() ??
              <String>{};
      final viPlaceholders =
          (vi['@$key']?['placeholders'] as Map?)?.keys.cast<String>().toSet() ??
              <String>{};
      expect(enPlaceholders, viPlaceholders, reason: key);
    }
  });
}
