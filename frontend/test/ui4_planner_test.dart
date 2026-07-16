import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/planner/planner_tab_screen.dart';
import 'package:planyourtrip_frontend/features/planner/planner_utils.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/shared/widgets/add_to_trip_sheet.dart';
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
    return AppScope(
      notifier: app ?? AppState(),
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

  Finder editableIn(Key key) => find.descendant(
        of: find.byKey(key),
        matching: find.byType(EditableText),
      );

  Trip trip({
    int id = 100,
    String title = 'Planner Trip',
    DateTime? start,
    DateTime? end,
  }) {
    final startDate = start ?? DateTime(2026, 7, 20);
    return Trip(
      id: id,
      title: title,
      destination: 'Da Lat',
      imageUrl: MockData.places.first.imageUrl,
      startDate: startDate,
      endDate: end ?? startDate.add(const Duration(days: 2)),
      travelers: 2,
      budget: 1000000,
    );
  }

  TimelineItem item({
    int id = 1,
    int tripId = 100,
    int day = 1,
    String start = '09:00',
    String end = '10:00',
    String title = 'Morning stop',
    int sortOrder = 0,
  }) =>
      TimelineItem(
        id: id,
        tripId: tripId,
        dayNumber: day,
        startTime: start,
        endTime: end,
        title: title,
        sortOrder: sortOrder,
      );

  test('planner helpers sort safely and detect interval conflicts', () {
    final items = [
      item(id: 3, start: 'bad', title: 'Legacy bad time', sortOrder: 1),
      item(id: 2, start: '08:00', end: '09:00', title: 'First'),
      item(id: 1, start: '08:00', end: '08:30', title: 'Stable first'),
    ];

    final sorted = sortedPlannerItems(items, tripId: 100, dayNumber: 1);
    expect(sorted.map((e) => e.id), [1, 2, 3]);
    expect(plannerHasValidInterval(sorted.last), isFalse);

    final conflict = findPlannerConflict(
      items,
      item(id: 99, start: '08:15', end: '08:45'),
    );
    expect(conflict?.id, 2);
    expect(
      findPlannerConflict(items, item(id: 99, day: 2, start: '08:15')),
      isNull,
    );
    expect(
      findPlannerConflict(
        items,
        item(id: 1, start: '08:15', end: '08:45'),
        ignoreId: 1,
      )?.id,
      2,
    );
  });

  test('planner day helpers use date-only clamping', () {
    final t = trip(
      start: DateTime(2026, 7, 20, 18),
      end: DateTime(2026, 7, 22, 6),
    );

    expect(plannerDateForDay(t, 1), DateTime(2026, 7, 20));
    expect(plannerDayForDate(t, DateTime(2026, 7, 22, 23)), 3);
    expect(clampPlannerDay(t, 99), 3);
  });

  testWidgets('Planner no-trip state and create CTA are safe', (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState()
      ..trips = []
      ..timeline = []
      ..expenses = [];

    await pumpSize(
      tester,
      testApp(child: const Scaffold(body: PlannerTabScreen()), app: app),
      const Size(390, 900),
    );

    expect(find.text('No trips to plan yet'), findsOneWidget);
    await tester.tap(find.text('Create a trip'));
    await tester.pumpAndSettle();
    expect(find.text('New trip'), findsOneWidget);
  });

  testWidgets('trip selection, day selector, and route fallback preserve state',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState()
      ..trips = [
        trip(
          id: 2,
          title: 'Long trip',
          start: DateTime(2026, 7, 19),
          end: DateTime(2026, 8, 15),
        ),
        trip(id: 1, title: 'Short trip', end: DateTime(2026, 7, 20)),
      ]
      ..timeline = [item(id: 10, tripId: 2, day: 2, title: 'Day two stop')];

    await pumpSize(
      tester,
      testApp(child: const Scaffold(body: PlannerTabScreen()), app: app),
      const Size(420, 1400),
    );

    expect(find.byKey(const Key('planner-trip-selector')), findsOneWidget);
    await tester.tap(find.byKey(const Key('planner-day-2')));
    await tester.pumpAndSettle();
    expect(find.text('Day two stop'), findsOneWidget);

    await tester.tap(find.text('Route'));
    await tester.pumpAndSettle();
    expect(find.text('Map provider not connected'), findsOneWidget);
    expect(find.text('Day two stop'), findsOneWidget);

    app.updateTrip(app.tripById(2)!.copyWith(endDate: DateTime(2026, 7, 19)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('planner-day-2')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline renders empty, sorted, invalid, and semantic states',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState()
      ..trips = [trip()]
      ..timeline = [
        item(id: 3, start: 'invalid', title: 'Legacy broken'),
        item(id: 2, start: '07:30', end: '08:00', title: 'First activity'),
        item(id: 1, start: '09:00', end: '10:00', title: 'Second activity'),
      ];
    final semantics = tester.ensureSemantics();
    try {
      await pumpSize(
        tester,
        testApp(child: const Scaffold(body: PlannerTabScreen()), app: app),
        const Size(390, 920),
      );

      final firstTop = tester.getTopLeft(find.text('First activity')).dy;
      final secondTop = tester.getTopLeft(find.text('Second activity')).dy;
      expect(firstTop, lessThan(secondTop));
      expect(find.text('Invalid time'), findsOneWidget);
      expect(
        find.bySemanticsLabel('First activity, 07:30 - 08:00'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('planner-day-2')));
      await tester.pumpAndSettle();
      expect(find.text('No activities this day'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('manual add validates input and duplicate submit creates one',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState()
      ..trips = [trip()]
      ..timeline = [];

    await pumpSize(
      tester,
      testApp(child: const Scaffold(body: PlannerTabScreen()), app: app),
      const Size(420, 1000),
    );

    await tester.tap(find.byKey(const Key('planner-add-activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-save-button')));
    await tester.pump();
    expect(find.text('Enter an activity title.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('activity-title-field')),
      'Sunrise walk',
    );
    await tester.enterText(
        editableIn(const Key('activity-start-field')), '11:00');
    await tester.enterText(
        editableIn(const Key('activity-end-field')), '10:00');
    await tester.tap(find.byKey(const Key('activity-save-button')));
    await tester.pump();
    expect(app.timeline, isEmpty);

    await tester.enterText(
        editableIn(const Key('activity-start-field')), '08:00');
    await tester.enterText(
        editableIn(const Key('activity-end-field')), '09:00');
    final save = tester.widget<OceanPrimaryButton>(
      find.byKey(const Key('activity-save-button')),
    );
    save.onPressed?.call();
    save.onPressed?.call();
    await tester.pumpAndSettle();

    expect(app.timeline, hasLength(1));
    expect(app.timeline.single.title, 'Sunrise walk');
  });

  testWidgets(
      'conflict resolution change time cancels then add anyway keeps both',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState()
      ..trips = [trip()]
      ..timeline = [item(id: 10, start: '08:00', end: '09:00')];

    await pumpSize(
      tester,
      testApp(child: const Scaffold(body: PlannerTabScreen()), app: app),
      const Size(420, 1000),
    );

    await tester.tap(find.byKey(const Key('planner-add-activity')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('activity-title-field')),
      'Overlap breakfast',
    );
    await tester.enterText(
        editableIn(const Key('activity-start-field')), '08:30');
    await tester.enterText(
        editableIn(const Key('activity-end-field')), '09:30');
    await tester.tap(find.byKey(const Key('activity-save-button')));
    await tester.pumpAndSettle();
    expect(find.text('Schedule conflict'), findsOneWidget);

    await tester.tap(find.byKey(const Key('conflict-change-time')));
    await tester.pumpAndSettle();
    expect(app.timeline, hasLength(1));
    await tester.enterText(
        editableIn(const Key('activity-start-field')), '09:30');
    await tester.enterText(
        editableIn(const Key('activity-end-field')), '10:30');
    await tester.tap(find.byKey(const Key('activity-save-button')));
    await tester.pumpAndSettle();
    expect(app.timeline, hasLength(2));

    await tester.tap(find.byKey(const Key('planner-add-activity')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('activity-title-field')),
      'Keep overlap',
    );
    await tester.enterText(
        editableIn(const Key('activity-start-field')), '08:15');
    await tester.enterText(
        editableIn(const Key('activity-end-field')), '08:45');
    await tester.tap(find.byKey(const Key('activity-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('conflict-add-anyway')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('conflict-confirm-add-anyway')));
    await tester.pumpAndSettle();
    expect(app.timeline.map((e) => e.title), contains('Keep overlap'));
    expect(app.timeline, hasLength(3));
  });

  testWidgets('Quick Add handles no trip and creates one linked activity',
      (tester) async {
    ignoreNetworkImageErrors();
    final emptyApp = AppState()
      ..trips = []
      ..timeline = [];

    await pumpSize(
      tester,
      testApp(
        app: emptyApp,
        child: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () =>
                  showAddToTripSheet(context, MockData.places.first),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
      const Size(390, 920),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('No trip available'), findsOneWidget);

    final app = AppState()
      ..trips = [trip()]
      ..timeline = [];
    await pumpSize(
      tester,
      testApp(child: const Scaffold(body: PlannerTabScreen()), app: app),
      const Size(430, 1000),
    );

    tester
        .widget<OceanSecondaryButton>(
          find.byKey(const Key('planner-quick-add')),
        )
        .onPressed
        ?.call();
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(Key('planner-quick-place-${MockData.places.first.id}')));
    await tester.pumpAndSettle();
    final submit = tester.widget<OceanPrimaryButton>(
      find.byKey(const Key('planner-quick-place-submit')),
    );
    submit.onPressed?.call();
    submit.onPressed?.call();
    await tester.pumpAndSettle();

    expect(app.timeline, hasLength(1));
    expect(app.timeline.single.placeId, MockData.places.first.id);
  });

  testWidgets('activity detail edit move and delete preserve identity',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState()
      ..trips = [trip()]
      ..timeline = [item(id: 77, title: 'Museum visit')];

    await pumpSize(
      tester,
      testApp(child: const Scaffold(body: PlannerTabScreen()), app: app),
      const Size(420, 1000),
    );

    await tester.tap(find.byKey(const Key('activity-card-77')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-edit-77')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-day-2')));
    await tester.enterText(
      find.byKey(const Key('activity-title-field')),
      'Museum visit updated',
    );
    await tester.tap(find.byKey(const Key('activity-save-button')));
    await tester.pumpAndSettle();

    expect(app.timeline, hasLength(1));
    expect(app.timeline.single.id, 77);
    expect(app.timeline.single.dayNumber, 2);
    expect(app.timeline.single.title, 'Museum visit updated');

    await tester.tap(find.byKey(const Key('planner-day-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-card-77')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-delete-77')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-confirm-delete')));
    await tester.pumpAndSettle();
    expect(app.timeline, isEmpty);
  });

  testWidgets(
      'selected trip deletion falls back without retaining invalid trip',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState()
      ..trips = [
        trip(id: 1, title: 'Keep trip'),
        trip(id: 2, title: 'Delete trip'),
      ]
      ..timeline = [];

    await pumpSize(
      tester,
      testApp(child: const Scaffold(body: PlannerTabScreen()), app: app),
      const Size(420, 920),
    );
    await tester.tap(find.byKey(const Key('planner-trip-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete trip').last);
    await tester.pumpAndSettle();

    app.deleteTrip(2);
    await tester.pumpAndSettle();
    expect(find.text('Keep trip'), findsWidgets);
    expect(find.text('Delete trip'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Planner tab mode state survives AppState rebuilds',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState()
      ..trips = [trip()]
      ..timeline = [item(id: 1, day: 2, title: 'Day two plan')];

    await pumpSize(
      tester,
      testApp(child: const Scaffold(body: PlannerTabScreen()), app: app),
      const Size(420, 1400),
    );

    await tester.tap(find.text('Route'));
    await tester.pumpAndSettle();
    expect(find.text('Map provider not connected'), findsOneWidget);
    app.addTrip(trip(id: 200, title: 'Second trip'));
    await tester.pumpAndSettle();
    expect(find.text('Map provider not connected'), findsOneWidget);
  });

  testWidgets('planner responsive layouts, localization, and semantics',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState()
      ..trips = [trip(title: 'Chuyến Đà Lạt')]
      ..timeline = [item(title: 'Ăn sáng')];
    final semantics = tester.ensureSemantics();
    try {
      await pumpSize(
        tester,
        testApp(
          child: const Scaffold(body: PlannerTabScreen()),
          app: app,
          locale: const Locale('vi'),
          textScaleFactor: 1.6,
        ),
        const Size(320, 760),
      );
      expect(find.text('Lịch trình'), findsWidgets);
      expect(find.text('Dòng thời gian'), findsOneWidget);
      expect(find.bySemanticsLabel('Bộ chọn ngày'), findsOneWidget);
      expect(find.bySemanticsLabel('Thêm hoạt động thủ công'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpSize(
        tester,
        testApp(child: const Scaffold(body: PlannerTabScreen()), app: app),
        const Size(1280, 840),
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  test('trip shortening and delete cascade regressions remain intact', () {
    final app = AppState();
    final trip = MockData.trips.first;
    final shortened = trip.copyWith(endDate: trip.startDate);

    app.updateTrip(shortened);
    expect(
      app.timeline
          .where((timeline) => timeline.tripId == trip.id)
          .every((timeline) => timeline.dayNumber == 1),
      isTrue,
    );

    app.deleteTrip(trip.id);
    expect(app.timeline.any((timeline) => timeline.tripId == trip.id), isFalse);
    expect(app.expenses.any((expense) => expense.tripId == trip.id), isFalse);
  });
}
