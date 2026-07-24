import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/home/home_screen.dart';
import 'package:planyourtrip_frontend/features/places/place_detail_screen.dart';
import 'package:planyourtrip_frontend/features/places/places_screen.dart';
import 'package:planyourtrip_frontend/features/trips/create_trip_screen.dart';
import 'package:planyourtrip_frontend/features/trips/trip_detail_screen.dart';
import 'package:planyourtrip_frontend/features/trips/trip_sections.dart';
import 'package:planyourtrip_frontend/features/trips/trips_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
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

  Widget testApp({
    required Widget child,
    AppState? app,
    Locale? locale,
    double textScaleFactor = 1,
  }) {
    final state = app ?? AppState();
    return AppScope(
      notifier: state,
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
    Widget widget,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  Future<void> tapCreatePrimary(
    WidgetTester tester, {
    bool settle = true,
  }) async {
    tester
        .widget<OceanPrimaryButton>(
          find.byKey(const Key('create-primary-action')),
        )
        .onPressed
        ?.call();
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Finder editableIn(Key key) => find.descendant(
        of: find.byKey(key),
        matching: find.byType(EditableText),
      );

  Trip trip({
    required int id,
    required String title,
    required DateTime start,
    required DateTime end,
  }) =>
      Trip(
        id: id,
        title: title,
        destination: 'Da Lat',
        imageUrl: MockData.places.first.imageUrl,
        startDate: start,
        endDate: end,
        travelers: 2,
        budget: 1200000,
      );

  test('trip sections derive status from date boundaries', () {
    final today = DateTime(2026, 7, 16);
    final ongoing = trip(id: 1, title: 'Ongoing', start: today, end: today);
    final upcoming = trip(
      id: 2,
      title: 'Upcoming',
      start: today.add(const Duration(days: 1)),
      end: today.add(const Duration(days: 3)),
    );
    final past = trip(
      id: 3,
      title: 'Past',
      start: today.subtract(const Duration(days: 3)),
      end: today.subtract(const Duration(days: 1)),
    );

    expect(sectionForTrip(ongoing, today), TripSection.ongoing);
    expect(sectionForTrip(upcoming, today), TripSection.upcoming);
    expect(sectionForTrip(past, today), TripSection.past);

    final grouped = groupTripsBySection([past, upcoming, ongoing], today);
    expect(grouped[TripSection.ongoing], [ongoing]);
    expect(grouped[TripSection.upcoming], [upcoming]);
    expect(grouped[TripSection.past], [past]);
  });

  testWidgets('explore home shows upcoming trip and empty state',
      (tester) async {
    ignoreNetworkImageErrors();
    final today = DateTime(2026, 7, 16);
    final app = AppState()
      ..trips = [
        trip(
          id: 10,
          title: 'Hue weekend',
          start: today.add(const Duration(days: 7)),
          end: today.add(const Duration(days: 9)),
        ),
      ]
      ..timeline = [];

    await pumpSize(
      tester,
      testApp(child: Scaffold(body: HomeScreen(today: today)), app: app),
      const Size(390, 900),
    );

    expect(find.text('Hue weekend'), findsOneWidget);
    expect(find.textContaining('Where will you'), findsOneWidget);

    app.trips = [];
    app.timeline = [];
    await pumpSize(
      tester,
      testApp(child: Scaffold(body: HomeScreen(today: today)), app: app),
      const Size(390, 900),
    );

    expect(find.text('No upcoming trip'), findsOneWidget);
  });

  testWidgets('explore search filters tags and clears to empty results',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      testApp(child: const PlacesScreen()),
      const Size(420, 920),
    );

    await tester.enterText(
      find.byKey(const Key('explore-search-field')),
      'cafe',
    );
    await tester.pumpAndSettle();
    expect(find.text('Túi Mơ To Cafe'), findsOneWidget);
    expect(find.text('Marina Bay Resort'), findsNothing);

    await tester.tap(find.byTooltip('Open search filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('coffee'));
    await tester.ensureVisible(find.text('Apply filters'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(find.text('Túi Mơ To Cafe'), findsOneWidget);

    await tester.ensureVisible(find.text('Clear filters'));
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('explore-search-field')),
      'zzzzzz',
    );
    await tester.pumpAndSettle();
    expect(find.text('No places found'), findsOneWidget);
  });

  testWidgets('list and map modes preserve query and show fallback',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      testApp(child: const PlacesScreen(initialQuery: 'Da Lat')),
      const Size(420, 920),
    );

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.text('Map provider not connected'), findsOneWidget);
    expect(find.text('Mây Lang Thang Villa'), findsOneWidget);

    final field = tester.widget<TextField>(
      find.byKey(const Key('explore-search-field')),
    );
    expect(field.controller?.text, 'Da Lat');

    await tester.tap(find.text('Back to list'));
    await tester.pumpAndSettle();
    expect(find.text('Map provider not connected'), findsNothing);
    expect(find.text('Túi Mơ To Cafe'), findsOneWidget);
  });

  testWidgets('place detail hides unsupported fields and has image fallback',
      (tester) async {
    ignoreNetworkImageErrors();
    const place = Place(
      id: 90,
      name: 'Quiet Garden',
      category: 'Nature',
      locationName: 'Da Lat',
      city: 'Da Lat',
      province: 'Lam Dong',
      description: 'A calm local garden.',
      imageUrl: 'https://127.0.0.1/missing.jpg',
      rating: 0,
      reviewCount: 0,
      priceLevel: '',
      estimatedDurationMinutes: 0,
    );

    await pumpSize(
      tester,
      testApp(child: const PlaceDetailScreen(place: place)),
      const Size(390, 900),
    );

    expect(find.text('Quiet Garden'), findsWidgets);
    expect(find.text('Useful information'), findsNothing);
    expect(find.textContaining('reviews'), findsNothing);
    expect(find.text('0.0'), findsNothing);
    expect(find.text('0 min'), findsNothing);
    final image = tester.widget<Image>(
      find.byKey(const Key('place-detail-image')),
    );
    expect(image.errorBuilder, isNotNull);
  });

  testWidgets('saved-place messaging separates demo and real mode',
      (tester) async {
    ignoreNetworkImageErrors();
    final place = MockData.places[3];
    final demoApp = AppState()
      ..demoMode = true
      ..email = MockData.demoEmail;

    await pumpSize(
      tester,
      testApp(
        child: PlaceDetailScreen(place: place),
        app: demoApp,
      ),
      const Size(390, 900),
    );

    await tester.tap(
      find.byTooltip('Save ${place.name}').first,
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.text('Saved ${place.name} locally.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final realApp = AppState()
      ..demoMode = false
      ..email = 'real@example.com';
    await pumpSize(
      tester,
      testApp(
        child: PlaceDetailScreen(place: place),
        app: realApp,
      ),
      const Size(390, 900),
    );

    await tester.tap(
      find.byTooltip('Save ${place.name}').first,
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('not connected to the backend'), findsOneWidget);
  });

  testWidgets('smart trips sections and real empty boundary render',
      (tester) async {
    ignoreNetworkImageErrors();
    final today = DateTime(2026, 7, 16);
    final app = AppState()
      ..trips = [
        trip(
          id: 1,
          title: 'Today trip',
          start: today,
          end: today.add(const Duration(days: 1)),
        ),
        trip(
          id: 2,
          title: 'Future trip',
          start: today.add(const Duration(days: 6)),
          end: today.add(const Duration(days: 8)),
        ),
        trip(
          id: 3,
          title: 'Past trip',
          start: today.subtract(const Duration(days: 5)),
          end: today.subtract(const Duration(days: 3)),
        ),
      ];

    await pumpSize(
      tester,
      testApp(child: TripsScreen(today: today), app: app),
      const Size(420, 920),
    );

    expect(find.text('Ongoing'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.text('Today trip'), findsOneWidget);
    expect(find.text('Future trip'), findsOneWidget);
    expect(find.text('Past trip'), findsOneWidget);

    final realApp = AppState()
      ..demoMode = false
      ..email = 'real@example.com';
    await pumpSize(
      tester,
      testApp(child: TripsScreen(today: today), app: realApp),
      const Size(420, 920),
    );

    expect(
      find.text(
          'Personal trip history is not connected to a backend repository yet.'),
      findsOneWidget,
    );
    expect(find.text(MockData.trips.first.title), findsNothing);
  });

  testWidgets('create trip validation rejects missing and invalid dates',
      (tester) async {
    await pumpSize(
      tester,
      testApp(child: const CreateTripScreen(key: ValueKey('create-fresh'))),
      const Size(390, 1400),
    );

    await tapCreatePrimary(tester, settle: false);
    expect(find.text('Please enter a destination.'), findsOneWidget);

    await pumpSize(
      tester,
      testApp(
        child: const CreateTripScreen(key: ValueKey('create-invalid-dates')),
      ),
      const Size(390, 1400),
    );

    await tester.enterText(
      find.byKey(const Key('create-destination-field')),
      'Da Lat',
    );
    await tester.enterText(
      find.byKey(const Key('create-title-field')),
      'Family Da Lat',
    );
    await tapCreatePrimary(tester);

    await tester.enterText(
      editableIn(const Key('create-start-date-field')),
      '01/01/2099',
    );
    await tester.enterText(
      editableIn(const Key('create-end-date-field')),
      '31/12/2098',
    );
    await tapCreatePrimary(tester, settle: false);
    expect(find.byKey(const ValueKey('create-step-2')), findsOneWidget);
    expect(find.text('Shape the trip your way'), findsNothing);
  });

  testWidgets('create trip preserves draft values between steps',
      (tester) async {
    await pumpSize(
      tester,
      testApp(child: const CreateTripScreen()),
      const Size(390, 1400),
    );

    await tester.enterText(
      find.byKey(const Key('create-destination-field')),
      'Da Lat',
    );
    await tester.enterText(
      find.byKey(const Key('create-title-field')),
      'Family Da Lat',
    );
    await tapCreatePrimary(tester);
    await tester.enterText(
      editableIn(const Key('create-start-date-field')),
      '01/01/2099',
    );
    await tester.enterText(
      editableIn(const Key('create-end-date-field')),
      '03/01/2099',
    );
    await tapCreatePrimary(tester);
    expect(find.text('Shape the trip your way'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to previous step'));
    await tester.pumpAndSettle();
    final startField = tester.widget<EditableText>(
      editableIn(const Key('create-start-date-field')),
    );
    expect(startField.controller.text, '01/01/2099');
  });

  testWidgets('duplicate create submit creates one trip and no server prefs',
      (tester) async {
    final app = AppState()
      ..trips = []
      ..timeline = []
      ..expenses = [];

    await pumpSize(
      tester,
      testApp(child: const CreateTripScreen(), app: app),
      const Size(390, 1400),
    );

    await tester.enterText(
      find.byKey(const Key('create-destination-field')),
      'Da Lat',
    );
    await tester.enterText(
      find.byKey(const Key('create-title-field')),
      'Da Lat local draft',
    );
    await tapCreatePrimary(tester);
    await tester.enterText(
      editableIn(const Key('create-start-date-field')),
      '01/01/2099',
    );
    await tester.enterText(
      editableIn(const Key('create-end-date-field')),
      '03/01/2099',
    );
    await tapCreatePrimary(tester);

    await tester.tap(find.text('Food'));
    await tester.pump();
    expect(
      find.text(
        'Preferences are kept in this draft only and are not sent to any backend.',
      ),
      findsOneWidget,
    );

    final primary = tester.widget<OceanPrimaryButton>(
      find.byKey(const Key('create-primary-action')),
    );
    primary.onPressed?.call();
    primary.onPressed?.call();
    await tester.pumpAndSettle();

    expect(app.trips, hasLength(1));
    expect(app.trips.single.title, 'Da Lat local draft');
    expect(app.trips.single.notes.contains('Food'), isFalse);
  });

  testWidgets('trip overview uses actual activity and expense data',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState();
    final trip = MockData.trips.first;

    await pumpSize(
      tester,
      testApp(child: TripDetailScreen(trip: trip), app: app),
      const Size(420, 920),
    );

    expect(find.text(trip.title), findsOneWidget);
    expect(find.text('Trip progress'), findsOneWidget);
    expect(find.text('Activities'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
    expect(find.textContaining('Booking'), findsNothing);
  });

  testWidgets('UI-3 screens handle narrow, wide, text scale, and semantics',
      (tester) async {
    ignoreNetworkImageErrors();
    final semantics = tester.ensureSemantics();
    try {
      await pumpSize(
        tester,
        testApp(
          child: const PlacesScreen(initialQuery: 'Da Lat'),
          textScaleFactor: 1.7,
        ),
        const Size(320, 700),
      );
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Clear search'), findsOneWidget);
      expect(find.bySemanticsLabel('Search presentation mode'), findsOneWidget);

      await pumpSize(
        tester,
        testApp(child: const TripsScreen()),
        const Size(1280, 820),
      );
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Create a new trip'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Vietnamese UI-3 labels render', (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      testApp(
        child: const PlacesScreen(),
        locale: const Locale('vi'),
      ),
      const Size(420, 920),
    );

    expect(find.text('Khám phá địa điểm'), findsOneWidget);
    expect(find.text('Danh sách'), findsOneWidget);
    expect(find.text('Bản đồ'), findsOneWidget);
  });
}
