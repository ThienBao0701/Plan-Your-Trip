import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/home/app_shell.dart';
import 'package:planyourtrip_frontend/features/hotels/hotel_utils.dart';
import 'package:planyourtrip_frontend/features/profile/profile_screen.dart';
import 'package:planyourtrip_frontend/features/trips/trip_detail_screen.dart';
import 'package:planyourtrip_frontend/features/wallet/travel_wallet_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 7, 16, 10);

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

  AppState demoState() => AppState(now: () => today)
    ..demoMode = true
    ..email = MockData.demoEmail;

  AppState realState() => AppState(now: () => today)
    ..demoMode = false
    ..email = 'real@example.com'
    ..trips = []
    ..timeline = []
    ..expenses = []
    ..demoBookings = []
    ..travelWalletItems = []
    ..tripDocuments = [];

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
    await tester.pumpWidget(harness(
      child: child,
      app: app,
      locale: locale,
      textScaleFactor: textScaleFactor,
    ));
    await tester.pumpAndSettle();
  }

  DemoBooking bookingFixture() {
    final hotel = MockData.places.first;
    final room = hotel.hotelDetail!.rooms.first;
    final plan = room.ratePlans.first;
    final criteria =
        defaultHotelCriteria(today: today, trip: MockData.trips.first);
    final quote = buildLocalHotelQuote(
      hotel: hotel,
      room: room,
      ratePlan: plan,
      criteria: criteria,
      generatedAt: today,
    );
    return DemoBooking(
      code: 'PYT-DEMO-2048',
      hotel: hotel,
      room: room,
      ratePlan: plan,
      quote: quote,
      criteria: criteria,
      createdAt: today,
    );
  }

  test('wallet types, organizer categories, and effective statuses are stable',
      () {
    expect(WalletItemType.values.map((type) => type.code), [
      'PASSPORT',
      'VISA',
      'BOARDING_PASS',
      'FLIGHT_TICKET',
      'TRAIN_TICKET',
      'BUS_TICKET',
      'HOTEL_VOUCHER',
      'TOUR_VOUCHER',
      'INSURANCE',
      'BOOKING_CONFIRMATION',
      'INVOICE',
      'RECEIPT',
      'ITINERARY',
      'OTHER',
    ]);
    expect(
        WalletItemType.passport.organizerCategory, OrganizerCategory.identity);
    expect(WalletItemType.hotelVoucher.organizerCategory,
        OrganizerCategory.accommodation);
    expect(WalletItemType.bookingConfirmation.organizerCategory,
        OrganizerCategory.financial);

    expect(
      computeWalletEffectiveStatus(
        archived: true,
        storedStatus: WalletItemStatus.cancelled,
        validUntil: DateTime(2026, 1, 1),
        today: today,
      ),
      WalletItemStatus.archived,
    );
    expect(
      computeWalletEffectiveStatus(
        archived: false,
        storedStatus: WalletItemStatus.cancelled,
        validUntil: DateTime(2026, 1, 1),
        today: today,
      ),
      WalletItemStatus.cancelled,
    );
    expect(
      computeWalletEffectiveStatus(
        archived: false,
        storedStatus: WalletItemStatus.active,
        validUntil: DateTime(2026, 7, 16),
        today: DateTime(2026, 7, 16, 23, 59),
      ),
      WalletItemStatus.active,
    );
    expect(
      computeWalletEffectiveStatus(
        archived: false,
        storedStatus: WalletItemStatus.active,
        validFrom: DateTime(2026, 7, 17),
        today: today,
      ),
      WalletItemStatus.upcoming,
    );
    expect(
      computeWalletEffectiveStatus(
        archived: false,
        storedStatus: WalletItemStatus.active,
        validFrom: null,
        validUntil: null,
        today: today,
      ),
      WalletItemStatus.active,
    );
  });

  test('wallet privacy masks raw references before storage', () {
    final app = demoState();
    const raw = 'VN 1234 5678 9012';
    final result = app.addWalletItem(
      TravelWalletItem(
        id: 'wallet-raw-test',
        type: WalletItemType.passport,
        title: 'Privacy test',
        maskedReference: raw,
        createdAt: today,
        updatedAt: today,
      ),
    );

    expect(result, WalletActionResult.success);
    final stored = app.travelWalletItems
        .firstWhere((item) => item.id == 'wallet-raw-test');
    expect(stored.maskedReference, '****-9012');
    expect(
      app.travelWalletItems.any((item) => item.maskedReference.contains(raw)),
      isFalse,
    );
    expect(maskSensitiveReference(''), '');
    expect(maskSensitiveReference('AB-12'), '****-AB12');
    expect(maskSensitiveReference('****-123456'), '****-3456');

    expect(
      app.addWalletItem(
        TravelWalletItem(
          id: 'wallet-masked-long',
          type: WalletItemType.visa,
          title: 'Masked normalization',
          maskedReference: '****-123456',
          status: WalletItemStatus.expired,
          createdAt: today,
          updatedAt: today,
        ),
      ),
      WalletActionResult.success,
    );
    final normalized = app.travelWalletItems
        .firstWhere((item) => item.id == 'wallet-masked-long');
    expect(normalized.maskedReference, '****-3456');
    expect(normalized.status, WalletItemStatus.active);
  });

  test('wallet summaries, sorting, favorite, archive, and real guards work',
      () {
    final app = demoState();
    final summary = WalletSummary.fromItems(app.travelWalletItems, today);

    expect(summary.total, app.travelWalletItems.length);
    expect(summary.favorites, greaterThanOrEqualTo(1));
    expect(summary.expiringSoon, greaterThanOrEqualTo(1));
    expect(app.sortedWalletItems(today: today).first.favorite, isTrue);

    final target = app.travelWalletItems.first;
    expect(app.setWalletFavorite(target.id, !target.favorite),
        WalletActionResult.success);
    expect(app.setWalletArchived(target.id, true), WalletActionResult.success);
    expect(
      app.travelWalletItems
          .firstWhere((item) => item.id == target.id)
          .effectiveStatus(today),
      WalletItemStatus.archived,
    );

    final real = realState();
    final attempt = TravelWalletItem(
      id: 'real-blocked',
      type: WalletItemType.passport,
      title: 'Should not save',
      createdAt: today,
      updatedAt: today,
    );
    expect(real.addWalletItem(attempt), WalletActionResult.unavailable);
    expect(real.travelWalletItems, isEmpty);
  });

  test('trip documents are pinned first, URL-safe, and source links are safe',
      () {
    final app = demoState();
    final trip = app.trips.first;
    final initial = app.documentsForTrip(trip.id);

    expect(initial.first.pinned, isTrue);
    expect(isSafeDocumentMediaUrl('https://example.com/demo.pdf'), isTrue);
    expect(isSafeDocumentMediaUrl('http://example.com/demo.pdf'), isTrue);
    expect(isSafeDocumentMediaUrl(''), isFalse);
    expect(isSafeDocumentMediaUrl('https://'), isFalse);
    expect(isSafeDocumentMediaUrl('https://user:pass@example.com/demo.pdf'),
        isFalse);
    expect(isSafeDocumentMediaUrl('javascript:alert(1)'), isFalse);
    expect(
      app.addTripDocument(
        TripDocument(
          id: 'doc-unsafe',
          tripId: trip.id,
          type: TripDocumentType.pdf,
          title: 'Unsafe URL',
          mediaUrl: 'file:///secret.pdf',
          createdAt: today,
          updatedAt: today,
        ),
      ),
      WalletActionResult.unsafeUrl,
    );
    expect(
      app.addTripDocument(
        TripDocument(
          id: 'doc-unsafe-with-label',
          tripId: trip.id,
          type: TripDocumentType.pdf,
          title: 'Unsafe URL with label',
          mediaLabel: 'unsafe.pdf',
          mediaUrl: 'https://user:pass@example.com/demo.pdf',
          createdAt: today,
          updatedAt: today,
        ),
      ),
      WalletActionResult.unsafeUrl,
    );

    final document = TripDocument(
      id: 'doc-local-safe',
      tripId: trip.id,
      type: TripDocumentType.hotelBooking,
      title: 'Local safe metadata',
      mediaLabel: 'Hotel confirmation link',
      mediaUrl: 'https://example.com/confirmation',
      createdAt: today,
      updatedAt: today,
    );
    expect(app.addTripDocument(document), WalletActionResult.success);
    expect(
      app.addTripDocument(
        TripDocument(
          id: 'doc-local-metadata-only',
          tripId: trip.id,
          type: TripDocumentType.pdf,
          title: 'Metadata only',
          mediaLabel: 'Local PDF metadata',
          createdAt: today,
          updatedAt: today,
        ),
      ),
      WalletActionResult.success,
    );
    expect(app.setTripDocumentPinned(document.id, true),
        WalletActionResult.success);
    expect(app.documentsForTrip(trip.id).first.id, document.id);

    final imported = app.importTripDocumentToWallet(document.id);
    expect(imported, isNotNull);
    expect(imported!.linkedDocumentId, document.id);
    expect(imported.maskedReference, isNot(contains(document.id)));
    expect(app.importTripDocumentToWallet(document.id)!.id, imported.id);
    expect(app.deleteTripDocument(document.id), WalletActionResult.success);
    expect(
      app.travelWalletItems.any((item) => item.linkedDocumentId == document.id),
      isFalse,
    );
    expect(app.tripById(trip.id), isNotNull);
  });

  test('demo booking import is idempotent and preserves booking data', () {
    final app = demoState();
    final booking = bookingFixture();
    app.demoBookings = [booking];
    final beforeTotal = booking.quote.finalQuotedPrice;
    final beforeStatus = booking.status;

    final imported = app.importDemoBookingToWallet(booking.code);
    final duplicate = app.importDemoBookingToWallet(booking.code);

    expect(imported, isNotNull);
    expect(duplicate!.id, imported!.id);
    expect(
      app.travelWalletItems
          .where((item) => item.linkedBookingId == booking.code)
          .length,
      1,
    );
    expect(app.demoBookings.single.quote.finalQuotedPrice, beforeTotal);
    expect(app.demoBookings.single.status, beforeStatus);

    final real = realState()..demoBookings = [booking];
    expect(real.importDemoBookingToWallet(booking.code), isNull);
    expect(real.travelWalletItems, isEmpty);
  });

  test('trip deletion cascades local documents and wallet document links', () {
    final app = demoState();
    final trip = app.trips.first;
    final document = app.documentsForTrip(trip.id).first;
    final imported = app.importTripDocumentToWallet(document.id);
    expect(imported, isNotNull);

    app.deleteTrip(trip.id);

    expect(app.tripById(trip.id), isNull);
    expect(app.documentsForTrip(trip.id), isEmpty);
    expect(
      app.travelWalletItems.any((item) => item.linkedDocumentId == document.id),
      isFalse,
    );
  });

  testWidgets('Profile opens Travel Wallet and AppShell keeps four tabs',
      (tester) async {
    ignoreNetworkImageErrors();
    final semantics = tester.ensureSemantics();
    await pumpSize(tester, const AppShell(), const Size(1440, 900));
    try {
      expect(find.bySemanticsLabel('Explore tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Trips tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Planner tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Profile tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Travel Wallet tab'), findsNothing);
    } finally {
      semantics.dispose();
    }

    await pumpSize(tester, const ProfileScreen(), const Size(900, 1400));
    await tester.ensureVisible(find.byKey(const Key('profile-wallet')));
    await tester.tap(find.byKey(const Key('profile-wallet')));
    await tester.pumpAndSettle();

    final root = find.byKey(const Key('travel-wallet-screen'));
    expect(root, findsOneWidget);
    expect(tester.getSize(root).height, greaterThan(0));
    expect(find.text('Travel Wallet'), findsWidgets);
    expect(find.text('Passport'), findsWidgets);
  });

  testWidgets('Travel Wallet renders real empty state and localized Vietnamese',
      (tester) async {
    await pumpSize(
      tester,
      TravelWalletScreen(today: DateTime(2026, 7, 16)),
      const Size(430, 932),
      app: realState(),
    );

    expect(find.text('Travel Wallet is not connected yet'), findsOneWidget);
    expect(find.text('Passport'), findsNothing);

    await pumpSize(
      tester,
      TravelWalletScreen(today: DateTime(2026, 7, 16)),
      const Size(430, 932),
      locale: const Locale('vi'),
      textScaleFactor: 1.35,
    );

    expect(find.text('Ví du lịch'), findsWidgets);
    expect(find.text('Hộ chiếu'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Trip Detail opens Documents and document actions are local only',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = demoState();
    final trip = app.trips.first;

    await pumpSize(
      tester,
      TripDetailScreen(trip: trip),
      const Size(900, 1400),
      app: app,
    );

    await tester.ensureVisible(find.byKey(const Key('trip-documents-action')));
    await tester.tap(find.byKey(const Key('trip-documents-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trip-documents-screen')), findsOneWidget);
    expect(find.text('Trip Documents'), findsWidgets);
    expect(find.byKey(const Key('trip-document-add')), findsOneWidget);

    await tester.tap(find.byKey(const Key('trip-document-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trip-document-title-field')),
      'Unsafe upload metadata',
    );
    await tester.enterText(
      find.byKey(const Key('trip-document-media-url-field')),
      'file:///private/passport.pdf',
    );
    await tester.tap(find.byKey(const Key('trip-document-save')));
    await tester.pumpAndSettle();

    expect(find.text('Use a valid http or https URL with a host.'),
        findsOneWidget);
    expect(
        app.tripDocuments.any((doc) => doc.title == 'Unsafe upload metadata'),
        isFalse);
  });

  testWidgets(
      'wide wallet layout, search empty state, and semantics are stable',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSize(
      tester,
      TravelWalletScreen(today: DateTime(2026, 7, 16)),
      const Size(1920, 1080),
      textScaleFactor: 1.25,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('wallet-item-wallet-passport-favorites')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    try {
      expect(
          find.bySemanticsLabel(RegExp('Wallet item Demo passport metadata')),
          findsWidgets);
      expect(find.bySemanticsLabel(RegExp(r'Masked reference \*\*\*\*-2048')),
          findsWidgets);
    } finally {
      semantics.dispose();
    }

    await tester.enterText(
        find.byKey(const Key('wallet-search-field')), 'not-present-in-wallet');
    await tester.pumpAndSettle();

    expect(find.text('No wallet items match'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('English and Vietnamese ARB files keep UI-8 key parity', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vi = jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
        as Map<String, dynamic>;
    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    final viKeys = vi.keys.where((key) => !key.startsWith('@')).toSet();

    expect(enKeys.difference(viKeys), isEmpty);
    expect(viKeys.difference(enKeys), isEmpty);
    expect(enKeys, contains('travelWalletTitle'));
    expect(enKeys, contains('tripDocumentsTitle'));
  });
}
