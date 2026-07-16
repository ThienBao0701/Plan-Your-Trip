import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/home/app_shell.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/main.dart';
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

  Future<void> pumpTall(
    WidgetTester tester,
    Widget widget, {
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
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

  Widget localizedApp({
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

  testWidgets('Plan Your Trip app starts', (tester) async {
    ignoreNetworkImageErrors();

    await pumpTall(
      tester,
      AppScope(notifier: AppState(), child: const PlanYourTripApp()),
    );

    expect(find.text('Start planning'), findsOneWidget);
  });

  testWidgets('demo login succeeds', (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState();

    await pumpTall(
      tester,
      AppScope(notifier: app, child: const PlanYourTripApp()),
    );

    await tester.tap(find.text('Start planning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Demo Mode'));
    await tester.pumpAndSettle();

    expect(app.demoMode, isTrue);
    expect(app.email, MockData.demoEmail);
    expect(
      find.textContaining('Where will you', skipOffstage: false),
      findsOneWidget,
    );
  });

  test('real login failure does not enable demo mode', () async {
    final api = ApiClient(
      client: MockClient((request) async => http.Response(
            jsonEncode({'message': 'Invalid credentials'}),
            401,
            headers: {'content-type': 'application/json'},
          )),
    )..demoMode = false;
    final app = AppState(api: api)..demoMode = false;

    final result = await app.login('real@example.com', 'bad-password');

    expect(result['success'], isFalse);
    expect(result['code'], 'invalid_credentials');
    expect(api.demoMode, isFalse);
    expect(app.demoMode, isFalse);
  });

  test('logout clears persisted and in-memory API session', () async {
    String? authorizationAfterLogout;
    final api = ApiClient(
      client: MockClient((request) async {
        authorizationAfterLogout = request.headers['Authorization'];
        return http.Response(
          jsonEncode({'message': 'Invalid credentials'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
    )
      ..token = 'previous-token'
      ..demoMode = false;
    final app = AppState(api: api)
      ..email = 'real@example.com'
      ..demoMode = false;
    await app.storage.save(
      email: 'real@example.com',
      token: 'previous-token',
      demo: false,
    );
    final prefsBefore = await SharedPreferences.getInstance();

    expect(api.token, 'previous-token');
    expect(prefsBefore.getString('jwt_token'), 'previous-token');

    await app.logout();

    final prefsAfter = await SharedPreferences.getInstance();
    expect(prefsAfter.getString('jwt_token'), isNull);
    expect(prefsAfter.getString('last_login_email'), isNull);
    expect(prefsAfter.getBool('demo_mode'), isNull);
    expect(app.api.token, isNull);
    expect(app.api.demoMode, isTrue);
    expect(app.demoMode, isTrue);
    expect(app.email, isNull);

    await app.api.login('real@example.com', 'bad-password');
    expect(authorizationAfterLogout, isNull);
  });

  test('UTF-8 backend message parsing preserves Vietnamese text', () async {
    final api = ApiClient(
      client: MockClient((request) async => http.Response.bytes(
            utf8.encode(jsonEncode({'message': 'Sai mật khẩu'})),
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          )),
    );

    final result = await api.login('real@example.com', 'bad-password');

    expect(result['success'], isFalse);
    expect(result['message'], 'Sai mật khẩu');
  });

  testWidgets('empty add-to-trip create CTA opens create trip screen',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState()
      ..trips = []
      ..timeline = []
      ..expenses = [];

    await pumpTall(
      tester,
      AppScope(
        notifier: app,
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showAddToTripSheet(context, MockData.places.first),
                  child: const Text('Add'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a trip'));
    await tester.pumpAndSettle();

    expect(find.text('New trip'), findsOneWidget);
  });

  testWidgets('bottom tabs preserve Home state', (tester) async {
    ignoreNetworkImageErrors();

    await pumpTall(
      tester,
      localizedApp(child: const AppShell()),
    );

    final initialField = tester.widget<TextField>(
      find.byType(TextField, skipOffstage: false).first,
    );
    initialField.controller!.text = 'Ha Noi';
    await tester.pump();
    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byType(TextField, skipOffstage: false).first,
    );
    expect(field.controller?.text, 'Ha Noi');
  });

  testWidgets('four-tab shell renders expected destinations', (tester) async {
    ignoreNetworkImageErrors();

    await pumpTall(tester, localizedApp(child: const AppShell()));

    expect(
      find.textContaining('Where will you', skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();
    expect(find.text('My trips', skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('Planner'));
    await tester.pumpAndSettle();
    expect(
      find.text('Da Lat 3 days 2 nights', skipOffstage: false),
      findsWidgets,
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(
      find.text('Demo Traveler', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('shell does not overflow on a narrow phone viewport',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      localizedApp(child: const AppShell()),
      const Size(320, 680),
    );

    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shell constrains content on a wide viewport', (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      localizedApp(child: const AppShell()),
      const Size(1280, 820),
    );

    final firstFieldWidth =
        tester.getSize(find.byType(TextField, skipOffstage: false).first).width;
    expect(firstFieldWidth, lessThan(920));
    expect(tester.takeException(), isNull);
  });

  testWidgets('localized Vietnamese tab labels render', (tester) async {
    ignoreNetworkImageErrors();

    await pumpTall(
      tester,
      localizedApp(
        child: const AppShell(),
        locale: const Locale('vi'),
      ),
    );

    expect(find.text('Khám phá'), findsOneWidget);
    expect(find.text('Chuyến đi'), findsOneWidget);
    expect(find.text('Lịch trình'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
  });

  testWidgets('loading state renders semantic progress indication',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpTall(
        tester,
        localizedApp(
          child: const Scaffold(
            body: Center(
              child: SizedBox(width: 420, child: OceanLoadingState()),
            ),
          ),
        ),
        settle: false,
      );

      expect(
        find.bySemanticsLabel(RegExp('Content is loading')),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('empty state renders and invokes CTA', (tester) async {
    var tapped = false;

    await pumpTall(
      tester,
      localizedApp(
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: OceanEmptyState(
                actionLabel: 'Explore now',
                onAction: () => tapped = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('No data yet'), findsOneWidget);
    await tester.tap(find.text('Explore now'));
    expect(tapped, isTrue);
  });

  testWidgets('offline state invokes retry', (tester) async {
    var retries = 0;

    await pumpTall(
      tester,
      localizedApp(
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: OceanOfflineState(onRetry: () => retries++),
            ),
          ),
        ),
      ),
    );

    expect(find.text('You are offline'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('recoverable error state invokes reload', (tester) async {
    var reloads = 0;

    await pumpTall(
      tester,
      localizedApp(
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: OceanRecoverableErrorState(onReload: () => reloads++),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('Reload'));
    expect(reloads, 1);
  });

  testWidgets('session-expired state invokes login', (tester) async {
    var logins = 0;

    await pumpTall(
      tester,
      localizedApp(
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: OceanSessionExpiredState(onLogin: () => logins++),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Session expired'), findsOneWidget);
    await tester.tap(find.text('Log in again'));
    expect(logins, 1);
  });

  testWidgets('shared components support increased text scaling',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      localizedApp(
        child: const AppShell(),
        textScaleFactor: 1.8,
      ),
      const Size(360, 760),
    );

    expect(find.text('Explore'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('important shell controls expose semantic labels',
      (tester) async {
    ignoreNetworkImageErrors();
    final semantics = tester.ensureSemantics();
    try {
      await pumpTall(tester, localizedApp(child: const AppShell()));

      expect(find.bySemanticsLabel('Primary navigation'), findsOneWidget);
      expect(find.bySemanticsLabel('Explore tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Trips tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Planner tab'), findsOneWidget);
      expect(find.bySemanticsLabel('Profile tab'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  test('expense cannot be created without a valid trip and amount', () {
    final app = AppState()..trips = [];
    final orphan = Expense(
      id: 100,
      tripId: 0,
      title: 'Taxi',
      category: 'Transport',
      amount: 100000,
      date: DateTime(2026, 1, 1),
    );
    final zeroAmount = Expense(
      id: 101,
      tripId: MockData.trips.first.id,
      title: 'Coffee',
      category: 'Food',
      amount: 0,
      date: DateTime(2026, 1, 1),
    );

    expect(app.addExpense(orphan), isFalse);
    app.trips = List.from(MockData.trips);
    expect(app.addExpense(zeroAmount), isFalse);
    expect(app.expenses.any((e) => e.id == orphan.id), isFalse);
    expect(app.expenses.any((e) => e.id == zeroAmount.id), isFalse);
  });

  test('timeline rejects end time earlier than or equal to start time', () {
    final app = AppState();
    final invalid = TimelineItem(
      id: 200,
      tripId: MockData.trips.first.id,
      dayNumber: 1,
      startTime: '12:00',
      endTime: '12:00',
      title: 'Invalid',
    );

    expect(app.addTimeline(invalid), isFalse);
    expect(app.timeline.any((item) => item.id == invalid.id), isFalse);
  });

  test('shortening trip dates moves invalid days to the new last day', () {
    final app = AppState();
    final trip = MockData.trips.first;
    final shortened = trip.copyWith(endDate: trip.startDate);

    app.updateTrip(shortened);

    expect(app.tripById(trip.id)?.days, 1);
    expect(
      app.timeline
          .where((item) => item.tripId == trip.id)
          .every((item) => item.dayNumber == 1),
      isTrue,
    );
  });

  test('tag filtering works', () {
    final app = AppState();

    final results = app.filteredPlaces(const PlaceQuery(tags: ['coffee']));

    expect(results.map((p) => p.name), contains('Túi Mơ To Cafe'));
    expect(results.every((p) => p.tags.contains('coffee')), isTrue);
  });

  test('deleting a trip cascades timeline items and expenses', () {
    final app = AppState();

    app.deleteTrip(1);

    expect(app.trips.any((trip) => trip.id == 1), isFalse);
    expect(app.timeline.any((item) => item.tripId == 1), isFalse);
    expect(app.expenses.any((expense) => expense.tripId == 1), isFalse);
  });
}
