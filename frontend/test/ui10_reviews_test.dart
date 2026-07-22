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
import 'package:planyourtrip_frontend/features/places/place_detail_screen.dart';
import 'package:planyourtrip_frontend/features/profile/profile_screen.dart';
import 'package:planyourtrip_frontend/features/reviews/reviews_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 18, 10);

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
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(
      child: child,
      app: app,
      locale: locale,
      textScaleFactor: textScaleFactor,
    ));
    await tester.pumpAndSettle();
  }

  test('UI-10 stable review values match committed backend contract', () {
    expect(ReviewStatus.values.map((status) => status.code), [
      'PENDING',
      'APPROVED',
      'REJECTED',
      'HIDDEN',
      'REPORTED',
    ]);
    expect(ReviewRatingCategory.values.map((category) => category.code), [
      'ratingCleanliness',
      'ratingService',
      'ratingLocation',
      'ratingValue',
      'ratingFacilities',
    ]);
  });

  test('public summaries include only approved reviews and derive aggregates',
      () {
    final app = demoState();
    final summary = app.reviewSummaryForPlace(1);

    expect(summary.total, 2);
    expect(summary.average, 4.5);
    expect(summary.distribution[5], 1);
    expect(summary.distribution[4], 1);
    expect(summary.distribution[1], 0);
    expect(
      app.publicReviewsForPlace(1).every((review) => review.status.isPublic),
      isTrue,
    );
    expect(app.publicReviewsForPlace(6), isEmpty);
  });

  test('review sorting, filters, and real mode are deterministic', () {
    final app = demoState();

    expect(app.publicReviewsForPlace(1).first.id, 2);
    expect(
      app
          .publicReviewsForPlace(1, sort: ReviewSort.highestRating)
          .first
          .ratingOverall,
      5,
    );
    expect(app.publicReviewsForPlace(1, rating: 5), hasLength(1));
    expect(app.publicReviewsForPlace(1, verifiedOnly: true), hasLength(2));

    final real = realState();
    expect(real.publicReviewsForPlace(1), isEmpty);
    expect(real.myReviews(), isEmpty);
  });

  test('completed booking review creation is guarded and does not alter value',
      () {
    final app = demoState();
    final booking = completedBooking();
    app.demoBookings = [booking];
    final totalBefore = booking.quote.finalQuotedPrice;
    final statusBefore = booking.status;

    expect(app.reviewEligibilityForBooking(booking).canReview, isTrue);
    expect(
      app.createDemoReviewForBooking(
        bookingCode: booking.code,
        ratingOverall: 5,
        ratingCleanliness: 4,
        title: 'Local verified stay',
        content: 'Local demo review content',
      ),
      ReviewActionResult.success,
    );

    final created = app.myReviews().firstWhere(
          (review) => review.bookingCode == booking.code,
        );
    expect(created.status, ReviewStatus.pending);
    expect(created.hasVerifiedBooking, isTrue);
    expect(
        app.publicReviewsForPlace(booking.hotel.id), isNot(contains(created)));
    expect(app.demoBookings.single.quote.finalQuotedPrice, totalBefore);
    expect(app.demoBookings.single.status, statusBefore);
    expect(
      app.createDemoReviewForBooking(
        bookingCode: booking.code,
        ratingOverall: 5,
      ),
      ReviewActionResult.duplicate,
    );
    expect(
      app.createDemoReviewForBooking(
        bookingCode: 'missing',
        ratingOverall: 5,
      ),
      ReviewActionResult.notFound,
    );
    expect(
      app.createDemoReviewForBooking(
        bookingCode: booking.code,
        ratingOverall: 6,
      ),
      ReviewActionResult.duplicate,
      reason: 'duplicate review is rejected before payload validation',
    );
  });

  test('fresh demo state seeds the completed reviewable booking safely', () {
    expect(MockData.buildDemoBookings(sourcePlaces: const <Place>[]), isEmpty);
    final app = demoState();
    expect(
      app.demoBookings
          .where((booking) => booking.code == MockData.demoReviewBookingCode),
      hasLength(1),
    );
    final booking = app.demoBookings.singleWhere(
      (booking) => booking.code == MockData.demoReviewBookingCode,
    );
    final summaryBefore = app.reviewSummaryForPlace(booking.hotel.id);
    final totalBefore = booking.quote.finalQuotedPrice;
    final currencyBefore = booking.quote.currency;
    final statusBefore = booking.status;
    final placeBefore = booking.hotel.id;

    expect(booking.code, MockData.demoReviewBookingCode);
    expect(booking.status, BookingStatus.completed);
    expect(booking.hotel.id, MockData.places.first.id);
    expect(booking.room.id, 101);
    expect(booking.ratePlan.ratePlanId, 1001);
    expect(booking.hotel.effectiveCategorySlug, 'accommodation');
    expect(booking.criteria.checkIn, DateTime(2026, 6, 10));
    expect(booking.criteria.checkOut, DateTime(2026, 6, 12));
    expect(booking.criteria.checkOut.isBefore(fixedNow), isTrue);
    expect(booking.criteria.adults, greaterThan(0));
    expect(booking.criteria.adults, lessThanOrEqualTo(booking.room.maxAdults));
    expect(booking.criteria.guests, lessThanOrEqualTo(booking.room.maxGuests));
    expect(booking.quote.currency, 'VND');
    expect(booking.quote.finalQuotedPrice, 2500000);
    expect(booking.quote.finalQuotedPrice!.isFinite, isTrue);
    expect(booking.quote.finalQuotedPrice, greaterThan(0));
    expect(booking.quote.staySubtotal, booking.quote.finalQuotedPrice);
    expect(booking.quote.totalBeforeCustomerBenefits,
        booking.quote.finalQuotedPrice);
    expect(
      app.reviews.any((review) => review.bookingCode == booking.code),
      isFalse,
    );
    expect(app.reviewEligibilityForBooking(booking).canReview, isTrue);

    expect(
        bookingInSection(booking, BookingSection.all, today: fixedNow), isTrue);
    expect(bookingInSection(booking, BookingSection.history, today: fixedNow),
        isTrue);
    expect(bookingInSection(booking, BookingSection.upcoming, today: fixedNow),
        isFalse);
    expect(bookingInSection(booking, BookingSection.active, today: fixedNow),
        isFalse);

    expect(
      app.createDemoReviewForBooking(
        bookingCode: booking.code,
        ratingOverall: 5,
        title: 'Fresh demo booking',
        content:
            'The seeded booking makes the local write-review flow visible.',
      ),
      ReviewActionResult.success,
    );

    final created = app.myReviews().firstWhere(
          (review) => review.bookingCode == booking.code,
        );
    expect(created.status, ReviewStatus.pending);
    expect(created.placeId, placeBefore);
    expect(created.authorUserId, app.currentDemoUser.id);
    expect(created.hasVerifiedBooking, isTrue);
    expect(
        app.reviewSummaryForPlace(booking.hotel.id).total, summaryBefore.total);
    expect(app.reviewSummaryForPlace(booking.hotel.id).average,
        summaryBefore.average);
    expect(
      app.createDemoReviewForBooking(
        bookingCode: booking.code,
        ratingOverall: 5,
      ),
      ReviewActionResult.duplicate,
    );
    expect(
      app.reviews.where((review) => review.bookingCode == booking.code),
      hasLength(1),
    );

    final preserved = app.demoBookings.singleWhere(
      (item) => item.code == booking.code,
    );
    expect(preserved.status, statusBefore);
    expect(preserved.quote.finalQuotedPrice, totalBefore);
    expect(preserved.quote.currency, currencyBefore);
    expect(preserved.hotel.id, placeBefore);
  });

  test('seeded demo booking stays isolated from real and reset states',
      () async {
    final real = realState();
    expect(real.demoBookings, isEmpty);
    expect(
      real.createDemoReviewForBooking(
        bookingCode: MockData.demoReviewBookingCode,
        ratingOverall: 5,
      ),
      ReviewActionResult.unavailable,
    );

    final app = demoState();
    expect(
      app.demoBookings
          .where((booking) => booking.code == MockData.demoReviewBookingCode),
      hasLength(1),
    );
    await app.logout();
    expect(
      app.demoBookings
          .where((booking) => booking.code == MockData.demoReviewBookingCode),
      hasLength(1),
    );

    final nextSession = demoState();
    expect(
      nextSession.demoBookings
          .where((booking) => booking.code == MockData.demoReviewBookingCode),
      hasLength(1),
    );
  });

  test('ineligible and real-mode review creation cannot mutate state', () {
    final confirmed = completedBooking().copyWith(
      code: 'PYT-DEMO-9100',
      status: BookingStatus.confirmed,
    );
    final app = demoState()..demoBookings = [confirmed];

    expect(app.reviewEligibilityForBooking(confirmed).result,
        ReviewActionResult.ineligible);
    expect(
      app.createDemoReviewForBooking(
        bookingCode: confirmed.code,
        ratingOverall: 5,
      ),
      ReviewActionResult.ineligible,
    );
    expect(app.reviews.length, MockData.reviews.length);

    final real = realState()..demoBookings = [completedBooking()];
    expect(
      real.createDemoReviewForBooking(
        bookingCode: completedBooking().code,
        ratingOverall: 5,
      ),
      ReviewActionResult.unavailable,
    );
    expect(real.reviews, isEmpty);
  });

  test('foreign bookings and invalid ratings are rejected by state', () {
    final app = demoState();
    final booking = completedBooking().copyWith(code: 'PYT-DEMO-9200');
    final foreignBooking =
        completedBooking().copyWith(code: 'PYT-DEMO-FOREIGN');
    app.demoBookings = [booking];

    expect(
      app.reviewEligibilityForBooking(foreignBooking).result,
      ReviewActionResult.notFound,
    );
    expect(
      app.createDemoReviewForBooking(
        bookingCode: foreignBooking.code,
        ratingOverall: 5,
      ),
      ReviewActionResult.notFound,
    );
    expect(
      app.createDemoReviewForBooking(
        bookingCode: booking.code,
        ratingOverall: 0,
      ),
      ReviewActionResult.invalidRating,
    );
    expect(
      app.createDemoReviewForBooking(
        bookingCode: booking.code,
        ratingOverall: 4,
        ratingFacilities: 6,
      ),
      ReviewActionResult.invalidRating,
    );
    expect(app.reviews.length, MockData.reviews.length);
  });

  testWidgets('fresh Demo Mode My Bookings exposes sample review flow',
      (tester) async {
    final app = demoState();

    await pumpSize(
      tester,
      MyBookingsScreen(today: fixedNow),
      const Size(900, 1400),
      app: app,
    );

    final card =
        find.byKey(const Key('booking-card-${MockData.demoReviewBookingCode}'));
    expect(card, findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);

    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    expect(card, findsNothing);

    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(card, findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking-detail-write-review')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('write-review-screen')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('review-title-field')),
      'Seeded demo stay',
    );
    await tester.enterText(
      find.byKey(const Key('review-content-field')),
      'This pending review is created from the fresh demo booking.',
    );
    await tester.tap(find.byKey(const Key('review-submit-action')));
    await tester.pumpAndSettle();

    expect(
      app.reviews.where(
          (review) => review.bookingCode == MockData.demoReviewBookingCode),
      hasLength(1),
    );
    expect(
      app
          .reviewEligibilityForBooking(
            app.demoBookings.singleWhere(
              (booking) => booking.code == MockData.demoReviewBookingCode,
            ),
          )
          .result,
      ReviewActionResult.duplicate,
    );
  });

  testWidgets(
      'narrow Demo Mode My Bookings shows seeded booking without overflow',
      (tester) async {
    final app = demoState();

    await pumpSize(
      tester,
      MyBookingsScreen(today: fixedNow),
      const Size(430, 932),
      app: app,
    );

    expect(
      find.byKey(const Key('booking-card-${MockData.demoReviewBookingCode}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'wide Demo Mode My Bookings shows seeded booking without overflow',
      (tester) async {
    final app = demoState();

    await pumpSize(
      tester,
      MyBookingsScreen(today: fixedNow),
      const Size(1440, 900),
      app: app,
    );

    expect(
      find.byKey(const Key('booking-card-${MockData.demoReviewBookingCode}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Place Detail shows review summary and public list is sanitized',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = demoState();

    await pumpSize(
      tester,
      PlaceDetailScreen(place: MockData.places.first),
      const Size(900, 1400),
      app: app,
    );

    await tester.ensureVisible(find.byKey(const Key('place-review-summary')));
    expect(find.text('Traveler trust'), findsOneWidget);
    expect(find.text('4.5 average'), findsOneWidget);
    expect(find.text('2 approved reviews'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('place-see-all-reviews')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('place-see-all-reviews')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reviews-list-screen')), findsOneWidget);
    expect(find.text('Quiet hillside stay'), findsOneWidget);
    expect(find.textContaining('PYT-DEMO'), findsNothing);
    expect(find.textContaining('local demo service notes'), findsNothing);
  });

  testWidgets('public review detail remains summary-only', (tester) async {
    final app = demoState();

    await pumpSize(
      tester,
      PlaceReviewsScreen(place: MockData.places.first),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.byKey(const Key('review-card-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('review-detail-screen')), findsOneWidget);
    expect(
        find.text(
            'The public backend contract exposes sanitized summaries only. Full review text is shown only in the author\'s review view.'),
        findsOneWidget);
    expect(find.textContaining('distribution tests'), findsNothing);
  });

  testWidgets('non-hotel review summary hides hotel category averages',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = demoState();
    final cafe = MockData.places.firstWhere((place) => place.id == 3);

    await pumpSize(
      tester,
      PlaceDetailScreen(place: cafe),
      const Size(900, 1400),
      app: app,
    );

    await tester.ensureVisible(find.byKey(const Key('place-review-summary')));
    expect(find.text('Traveler trust'), findsOneWidget);
    expect(find.textContaining('Cleanliness'), findsNothing);
  });

  testWidgets('My Bookings opens eligible write-review flow once',
      (tester) async {
    final app = demoState();
    final booking = completedBooking();
    app.demoBookings = [booking];

    await pumpSize(
      tester,
      const MyBookingsScreen(),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.byKey(Key('booking-card-${booking.code}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking-detail-write-review')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('write-review-screen')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('review-title-field')),
      'Verified local stay',
    );
    await tester.enterText(
      find.byKey(const Key('review-content-field')),
      'A deterministic UI-10 review.',
    );
    await tester.tap(find.byKey(const Key('review-submit-action')));
    await tester.pumpAndSettle();

    expect(
      app.reviews.where((review) => review.bookingCode == booking.code),
      hasLength(1),
    );
    expect(
      app.reviewEligibilityForBooking(booking).result,
      ReviewActionResult.duplicate,
    );
  });

  testWidgets('ineligible booking write review shows contract reason',
      (tester) async {
    final app = demoState();
    final booking = completedBooking().copyWith(
      code: 'PYT-DEMO-9200',
      status: BookingStatus.confirmed,
    );
    app.demoBookings = [booking];

    await pumpSize(
      tester,
      const MyBookingsScreen(),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.byKey(Key('booking-card-${booking.code}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('booking-detail-write-review')));
    await tester.pumpAndSettle();
    expect(
      find.text(
          'Only completed local demo bookings owned by you can be reviewed.'),
      findsOneWidget,
    );
    expect(app.reviews.length, MockData.reviews.length);
  });

  testWidgets('Profile opens My Reviews and real sessions stay unavailable',
      (tester) async {
    final app = demoState();

    await pumpSize(
      tester,
      const ProfileScreen(),
      const Size(900, 1400),
      app: app,
    );

    await tester.ensureVisible(find.byKey(const Key('profile-my-reviews')));
    await tester.tap(find.byKey(const Key('profile-my-reviews')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('my-reviews-screen')), findsOneWidget);
    expect(find.text('Pending (1)'), findsOneWidget);
    expect(find.text('Approved (2)'), findsOneWidget);

    await pumpSize(
      tester,
      const MyReviewsScreen(),
      const Size(900, 1400),
      app: realState(),
    );
    expect(find.text('My Reviews is not connected yet'), findsOneWidget);
  });

  testWidgets('author review detail masks booking code and shows safe status',
      (tester) async {
    final app = demoState();

    await pumpSize(
      tester,
      const MyReviewsScreen(),
      const Size(900, 1400),
      app: app,
    );

    await tester.tap(find.byKey(const Key('review-card-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('review-detail-screen')), findsOneWidget);
    expect(find.text('****-7001'), findsOneWidget);
    expect(find.text('PYT-DEMO-7001'), findsNothing);
    expect(find.text('Review metadata'), findsOneWidget);
    expect(find.text('Local moderation feedback preview.'), findsNothing);
  });

  testWidgets('AppShell remains four tabs and review navigation is not a tab',
      (tester) async {
    ignoreNetworkImageErrors();
    final semantics = tester.ensureSemantics();
    try {
      await pumpSize(
        tester,
        const AppShell(),
        const Size(1920, 1080),
        app: demoState(),
      );

      expect(find.bySemanticsLabel('Explore tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Trips tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Planner tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Profile tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Reviews tab'), findsNothing);
      expect(tester.getSize(find.byKey(const ValueKey('shell-tab-0'))).height,
          greaterThan(0));

      for (final label in ['Profile', 'Explore', 'Trips', 'Planner']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('reviews render in Vietnamese and large text layouts',
      (tester) async {
    await pumpSize(
      tester,
      const MyReviewsScreen(),
      const Size(430, 932),
      locale: const Locale('vi'),
      textScaleFactor: 1.35,
    );

    expect(find.text('Đánh giá của tôi'), findsWidgets);
    expect(find.text('Chờ duyệt (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('English and Vietnamese ARB files keep UI-10 key parity', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vi = jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
        as Map<String, dynamic>;
    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    final viKeys = vi.keys.where((key) => !key.startsWith('@')).toSet();

    expect(enKeys.difference(viKeys), isEmpty);
    expect(viKeys.difference(enKeys), isEmpty);
    expect(enKeys, contains('reviewsTitle'));
    expect(enKeys, contains('myReviewsTitle'));
  });
}

DemoBooking completedBooking() {
  final hotel = MockData.places.first;
  final room = hotel.hotelDetail!.rooms.first;
  final plan = room.ratePlans.first;
  final criteria = HotelStayCriteria(
    destination: hotel.city,
    checkIn: DateTime(2026, 7, 1),
    checkOut: DateTime(2026, 7, 3),
    adults: 2,
    children: 0,
    tripId: 1,
  );
  final quote = buildLocalHotelQuote(
    hotel: hotel,
    room: room,
    ratePlan: plan,
    criteria: criteria,
    generatedAt: DateTime(2026, 6, 20, 9),
  );
  return DemoBooking(
    code: 'PYT-DEMO-9001',
    hotel: hotel,
    room: room,
    ratePlan: plan,
    quote: quote,
    criteria: criteria,
    status: BookingStatus.completed,
    createdAt: DateTime(2026, 6, 20, 9),
  );
}
