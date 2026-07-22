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
import 'package:planyourtrip_frontend/features/hotels/hotel_booking_review_screen.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_utils.dart';
import 'package:planyourtrip_frontend/features/payments/secure_checkout_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 22, 10);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppState demoState({bool emptyBookings = false}) {
    final app = AppState(
      now: () => fixedNow,
      bookingCodeGenerator: (sequence) =>
          'UI13-${sequence.toString().padLeft(2, '0')}',
    )
      ..demoMode = true
      ..email = MockData.demoEmail;
    if (emptyBookings) {
      app.demoBookings = [];
      app.demoPaymentAttempts = [];
    }
    return app;
  }

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
        today: fixedNow,
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
      generatedAt: fixedNow,
    );
    return (hotel: hotel, room: room, plan: plan, quote: quote);
  }

  DemoCheckoutResult startCheckout(AppState app, {String key = 'ui13-key'}) {
    final fixture = quoteFixture();
    return app.startDemoCheckout(
      hotel: fixture.hotel,
      room: fixture.room,
      ratePlan: fixture.plan,
      quote: fixture.quote,
      criteria: criteria(),
      specialRequest: 'High floor',
      provider: CheckoutPaymentProvider.mock,
      idempotencyKey: key,
    );
  }

  test('backend payment wire values and unknown fallbacks are stable', () {
    expect(
      CheckoutPaymentMethod.values.map((method) => method.code),
      [
        'MOCK',
        'CASH',
        'CARD',
        'BANK_TRANSFER',
        'VNPAY',
        'MOMO',
        'STRIPE',
        'PAYOS',
      ],
    );
    expect(
      CheckoutPaymentProvider.values.map((provider) => provider.code),
      [
        'MOCK',
        'VNPAY',
        'PAYOS',
        'MOMO',
        'STRIPE',
        'APPLE_PAY',
        'GOOGLE_PAY',
        'MANUAL',
      ],
    );
    expect(
      PaymentSessionStatus.values.map((status) => status.code),
      [
        'NEW',
        'PENDING',
        'AUTHORIZED',
        'CAPTURED',
        'FAILED',
        'CANCELLED',
        'EXPIRED'
      ],
    );
    expect(bookingStatusFromWire('CONFIRMED'), BookingStatus.confirmed);
    expect(bookingPaymentStatusFromWire('PAID'), BookingPaymentStatus.paid);
    expect(paymentSessionStatusFromWire('CAPTURED'),
        PaymentSessionStatus.captured);
    expect(checkoutPaymentProviderFromWire('PAYOS'),
        CheckoutPaymentProvider.payos);
    expect(checkoutPaymentMethodFromWire('BANK_TRANSFER'),
        CheckoutPaymentMethod.bankTransfer);
    expect(bookingStatusFromWire('UNKNOWN'), isNull);
    expect(bookingPaymentStatusFromWire('PAIDISH'), isNull);
    expect(paymentSessionStatusFromWire('DONE'), isNull);
  });

  test('demo checkout creates one pending booking and attempt idempotently',
      () {
    final app = demoState(emptyBookings: true);
    final walletCount = app.travelWalletItems.length;
    final rewardBalance = app.travelCreditAccount?.balanceMinor;
    final reviewCount = app.reviews.length;

    final created = startCheckout(app);
    final duplicate = startCheckout(app);

    expect(created.result, DemoPaymentActionResult.success);
    expect(duplicate.result, DemoPaymentActionResult.duplicate);
    expect(app.demoBookings, hasLength(1));
    expect(app.demoPaymentAttempts, hasLength(1));
    expect(created.booking!.status, BookingStatus.pending);
    expect(created.booking!.paymentStatus, BookingPaymentStatus.pending);
    expect(created.attempt!.sessionStatus, PaymentSessionStatus.pending);
    expect(created.attempt!.amount, created.booking!.quote.finalQuotedPrice);
    expect(created.attempt!.currency, created.booking!.quote.currency);
    expect(app.travelWalletItems.length, walletCount);
    expect(app.travelCreditAccount?.balanceMinor, rewardBalance);
    expect(app.reviews.length, reviewCount);
  });

  test('successful demo payment confirms booking without changing snapshot',
      () {
    final app = demoState(emptyBookings: true);
    final result = startCheckout(app);
    final booking = result.booking!;
    final attempt = result.attempt!;
    final total = booking.quote.finalQuotedPrice;
    final roomId = booking.room.id;
    final ratePlanId = booking.ratePlan.ratePlanId;

    expect(
        app.completeDemoPayment(attempt.id), DemoPaymentActionResult.success);
    expect(
        app.completeDemoPayment(attempt.id), DemoPaymentActionResult.success);

    final paidBooking = app.demoBookingByCode(booking.code)!;
    final paidAttempt = app.paymentAttemptById(attempt.id)!;
    expect(paidBooking.status, BookingStatus.confirmed);
    expect(paidBooking.paymentStatus, BookingPaymentStatus.paid);
    expect(paidAttempt.paymentStatus, BookingPaymentStatus.paid);
    expect(paidAttempt.sessionStatus, PaymentSessionStatus.captured);
    expect(paidBooking.quote.finalQuotedPrice, total);
    expect(paidBooking.room.id, roomId);
    expect(paidBooking.ratePlan.ratePlanId, ratePlanId);
  });

  test('failed, cancelled, and retried payments do not confirm booking', () {
    final app = demoState(emptyBookings: true);
    final first = startCheckout(app).attempt!;

    expect(app.failDemoPayment(first.id, reason: 'Declined'),
        DemoPaymentActionResult.success);
    var booking = app.demoBookings.single;
    expect(booking.status, BookingStatus.pending);
    expect(booking.paymentStatus, BookingPaymentStatus.failed);
    expect(app.paymentAttemptById(first.id)!.failedAt, fixedNow.toUtc());

    final retry = app.retryDemoPayment(booking.code);
    expect(retry.result, DemoPaymentActionResult.success);
    expect(app.demoBookings.single.status, BookingStatus.pending);
    expect(app.demoPaymentAttempts, hasLength(2));

    expect(app.cancelDemoPaymentAttempt(retry.attempt!.id),
        DemoPaymentActionResult.success);
    booking = app.demoBookings.single;
    expect(booking.status, BookingStatus.pending);
    expect(booking.paymentStatus, BookingPaymentStatus.failed);
    final cancelledAttempt = app.paymentAttemptById(retry.attempt!.id)!;
    expect(cancelledAttempt.paymentStatus, BookingPaymentStatus.failed);
    expect(cancelledAttempt.sessionStatus, PaymentSessionStatus.cancelled);
  });

  test('authorized sessions stay unpaid and terminal transitions are rejected',
      () {
    final app = demoState(emptyBookings: true);
    final pending = startCheckout(app).attempt!;
    final authorized = pending.copyWith(
      paymentStatus: null,
      sessionStatus: PaymentSessionStatus.authorized,
    );
    expect(authorized.isPending, isTrue);
    expect(authorized.isSuccessful, isFalse);
    expect(authorized.canRetry, isFalse);

    expect(app.failDemoPayment(pending.id), DemoPaymentActionResult.success);
    expect(
      app.completeDemoPayment(pending.id),
      DemoPaymentActionResult.invalidState,
    );
    expect(
      app.cancelDemoPaymentAttempt(pending.id),
      DemoPaymentActionResult.invalidState,
    );

    final retry = app.retryDemoPayment(app.demoBookings.single.code).attempt!;
    expect(
      app.cancelDemoPaymentAttempt(retry.id),
      DemoPaymentActionResult.success,
    );
    expect(
      app.completeDemoPayment(retry.id),
      DemoPaymentActionResult.invalidState,
    );
  });

  test('booking cancellation never implies payment refund', () {
    final app = demoState();
    final booking = app.demoBookings.singleWhere(
      (item) => item.code == MockData.demoCancellationBookingCode,
    );
    final attempt = app.latestPaymentAttemptForBooking(booking.code)!;

    expect(app.cancelDemoBookingWithResult(booking.code),
        BookingCancellationResult.eligible);

    final cancelled = app.demoBookingByCode(booking.code)!;
    final payment = app.paymentAttemptById(attempt.id)!;
    expect(cancelled.status, BookingStatus.cancelled);
    expect(cancelled.paymentStatus, BookingPaymentStatus.paid);
    expect(payment.paymentStatus, BookingPaymentStatus.paid);
    expect(payment.refundedAt, isNull);
  });

  test('real mode cannot create payment data and logout resets demo attempts',
      () async {
    final fixture = quoteFixture();
    final real = realState();
    final result = real.startDemoCheckout(
      hotel: fixture.hotel,
      room: fixture.room,
      ratePlan: fixture.plan,
      quote: fixture.quote,
      criteria: criteria(),
      specialRequest: '',
      provider: CheckoutPaymentProvider.mock,
      idempotencyKey: 'real-denied',
    );
    expect(result.result, DemoPaymentActionResult.unavailable);
    expect(real.demoBookings, isEmpty);
    expect(real.demoPaymentAttempts, isEmpty);

    final app = demoState(emptyBookings: true);
    startCheckout(app);
    expect(app.demoPaymentAttempts, hasLength(1));
    await app.logout();
    expect(app.demoMode, isTrue);
    expect(app.demoPaymentAttempts.map((attempt) => attempt.id),
        contains('PAY-DEMO-8801'));
    expect(app.demoPaymentAttempts.map((attempt) => attempt.id),
        contains('PAY-DEMO-9901'));
  });

  testWidgets('booking review enters secure checkout without credential fields',
      (tester) async {
    final app = demoState(emptyBookings: true);
    final fixture = quoteFixture();

    await pumpSize(
      tester,
      HotelBookingReviewScreen(
        hotel: fixture.hotel,
        room: fixture.room,
        ratePlan: fixture.plan,
        criteria: criteria(),
        quote: fixture.quote,
      ),
      const Size(430, 932),
      app: app,
    );

    final terms = find.byKey(const Key('booking-terms-checkbox'));
    await scrollToAndTap(tester, terms);
    final confirm = find.byKey(const Key('booking-confirm'));
    await scrollToAndTap(tester, confirm);

    expect(find.byKey(const Key('secure-checkout-screen')), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
    expect(find.text('Final quoted price'), findsNothing);
    expect(find.text('Secure checkout'), findsWidgets);
    expect(find.textContaining('card number'), findsOneWidget);
    expect(app.demoBookings, isEmpty);
  });

  testWidgets('demo checkout result navigates through payment and confirmation',
      (tester) async {
    final app = demoState(emptyBookings: true);
    final fixture = quoteFixture();

    await pumpSize(
      tester,
      SecureCheckoutScreen(
        hotel: fixture.hotel,
        room: fixture.room,
        ratePlan: fixture.plan,
        criteria: criteria(),
        quote: fixture.quote,
      ),
      const Size(900, 1400),
      app: app,
    );

    final submit = find.byKey(const Key('checkout-submit'));
    await scrollToAndTap(tester, submit);

    expect(app.demoBookings, hasLength(1));
    expect(app.demoPaymentAttempts, hasLength(1));
    expect(find.byKey(const Key('payment-status-screen')), findsOneWidget);
    expect(find.text('Payment pending'), findsWidgets);

    final complete = find.byKey(const Key('payment-complete-demo'));
    await scrollToAndTap(tester, complete);
    expect(find.text('Payment completed'), findsWidgets);
    expect(app.demoBookings.single.status, BookingStatus.confirmed);

    final confirmation = find.byKey(const Key('payment-open-confirmation'));
    await scrollToAndTap(tester, confirmation);
    expect(find.text('Demo booking confirmed'), findsWidgets);
  });

  testWidgets('payment failure exposes retry and does not confirm booking',
      (tester) async {
    final app = demoState(emptyBookings: true);
    final fixture = quoteFixture();

    await pumpSize(
      tester,
      SecureCheckoutScreen(
        hotel: fixture.hotel,
        room: fixture.room,
        ratePlan: fixture.plan,
        criteria: criteria(),
        quote: fixture.quote,
      ),
      const Size(900, 1400),
      app: app,
    );

    final submit = find.byKey(const Key('checkout-submit'));
    await scrollToAndTap(tester, submit);
    final fail = find.byKey(const Key('payment-fail-demo'));
    await scrollToAndTap(tester, fail);

    expect(app.demoBookings.single.status, BookingStatus.pending);
    expect(find.text('Payment failed'), findsWidgets);
    expect(find.byKey(const Key('payment-retry')), findsOneWidget);

    final retry = find.byKey(const Key('payment-retry'));
    await scrollToAndTap(tester, retry);
    await tester.pumpAndSettle();
    expect(app.demoPaymentAttempts, hasLength(2));
    expect(app.demoBookings.single.paymentStatus, BookingPaymentStatus.pending);
    expect(find.text('Payment pending'), findsWidgets);
  });

  testWidgets('booking detail shows payment integration and refund boundary',
      (tester) async {
    final app = demoState();

    await pumpSize(
      tester,
      BookingDetailScreen(
        bookingCode: MockData.demoCancellationBookingCode,
        today: fixedNow,
      ),
      const Size(1440, 900),
      app: app,
    );

    expect(find.text('Payment details'), findsOneWidget);
    expect(find.text('Mock provider'), findsOneWidget);
    expect(
        find.byKey(const Key('booking-detail-payment-action')), findsOneWidget);
    expect(find.textContaining('not shown as refunded'), findsOneWidget);

    await tester.tap(find.byKey(const Key('booking-detail-payment-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('payment-status-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real checkout and responsive payment layouts render safely',
      (tester) async {
    final fixture = quoteFixture();
    await pumpSize(
      tester,
      SecureCheckoutScreen(
        hotel: fixture.hotel,
        room: fixture.room,
        ratePlan: fixture.plan,
        criteria: criteria(),
        quote: fixture.quote,
      ),
      const Size(430, 932),
      app: realState(),
    );
    expect(find.text('Payment security'), findsOneWidget);
    expect(find.textContaining('will not simulate success'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final app = demoState();
    await pumpSize(
      tester,
      const PaymentStatusScreen(
        bookingCode: MockData.demoCancellationBookingCode,
        attemptId: 'PAY-DEMO-9901',
      ),
      const Size(1920, 1080),
      app: app,
      textScaleFactor: 1.4,
    );
    expect(find.byKey(const Key('payment-status-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpSize(
      tester,
      const PaymentStatusScreen(
        bookingCode: MockData.demoCancellationBookingCode,
        attemptId: 'PAY-DEMO-9901',
      ),
      const Size(430, 932),
      app: app,
      locale: const Locale('vi'),
    );
    expect(find.text('Trạng thái thanh toán'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment status semantics and four-tab shell remain intact',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final app = demoState(emptyBookings: true);
      final checkout = startCheckout(app);
      await pumpSize(
        tester,
        PaymentStatusScreen(
          bookingCode: checkout.booking!.code,
          attemptId: checkout.attempt!.id,
        ),
        const Size(900, 1400),
        app: app,
      );

      final complete = find.byKey(const Key('payment-complete-demo'));
      await tester.scrollUntilVisible(
        complete,
        900,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Complete this local demo payment'),
        findsOneWidget,
      );

      await pumpSize(
        tester,
        const AppShell(),
        const Size(900, 1400),
        app: app,
      );
      for (final label in ['Explore', 'Trips', 'Planner', 'Profile']) {
        expect(find.bySemanticsLabel('$label tab'), findsOneWidget);
      }
      expect(find.bySemanticsLabel('Home tab'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  test('English and Vietnamese UI-13 localization keys stay in parity', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vi = jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
        as Map<String, dynamic>;
    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    final viKeys = vi.keys.where((key) => !key.startsWith('@')).toSet();

    expect(enKeys.difference(viKeys), isEmpty);
    expect(viKeys.difference(enKeys), isEmpty);
    expect(enKeys, contains('checkoutTitle'));
    expect(enKeys, contains('paymentSessionStatusCaptured'));
    expect(enKeys, contains('paymentNoRefundInference'));

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
