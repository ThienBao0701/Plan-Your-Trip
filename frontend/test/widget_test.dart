import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/features/home/app_shell.dart';
import 'package:planyourtrip_frontend/main.dart';
import 'package:planyourtrip_frontend/shared/widgets/add_to_trip_sheet.dart';
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

  Future<void> pumpTall(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
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
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(app.demoMode, isTrue);
    expect(app.email, MockData.demoEmail);
    expect(find.textContaining('Where will you'), findsOneWidget);
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
    await tester.tap(find.text('Create a trip first'));
    await tester.pumpAndSettle();

    expect(find.text('New trip'), findsOneWidget);
  });

  testWidgets('bottom tabs preserve Home state', (tester) async {
    ignoreNetworkImageErrors();

    await pumpTall(
      tester,
      AppScope(
          notifier: AppState(), child: const MaterialApp(home: AppShell())),
    );

    await tester.enterText(find.byType(TextField).first, 'Ha Noi');
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'Ha Noi');
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
