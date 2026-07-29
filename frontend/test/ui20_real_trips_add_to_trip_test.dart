import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/trips/trips_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
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

  Widget testApp({required Widget child, AppState? app, Locale? locale}) {
    return AppScope(
      notifier: app ?? AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  Future<void> pumpSize(WidgetTester tester, Widget widget, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  http.Response jsonResponse(Object body, int status) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> errorBody(int status, String message, String path) => {
        'timestamp': DateTime.now().toIso8601String(),
        'status': status,
        'error': 'Error',
        'message': message,
        'path': path,
      };

  // ── Backend TripPlan DTO fixtures (verified against Plan-Your-Trip-backend-v1)

  Map<String, dynamic> tripSummaryJson({
    int id = 1,
    String title = 'Da Lat Getaway',
    String? destination = 'Da Lat',
    String status = 'PLANNING',
    int dayCount = 2,
  }) =>
      {
        'id': id,
        'title': title,
        'destination': destination,
        'coverImage': null,
        'startDate': '2026-08-01',
        'endDate': '2026-08-03',
        'status': status,
        'isPublic': false,
        'dayCount': dayCount,
        'updatedAt': '2026-07-25T10:00:00Z',
      };

  Map<String, dynamic> tripItemJson({
    int id = 100,
    int? placeId = 7,
    String? placeName = 'Backend Villa',
    String? customTitle,
    String? customDescription,
    int sortOrder = 0,
    String? startTime = '09:00:00',
  }) =>
      {
        'id': id,
        'placeId': placeId,
        'placeName': placeName,
        'placeSlug': placeId == null ? null : 'backend-villa',
        'customTitle': customTitle,
        'customDescription': customDescription,
        'startTime': startTime,
        'endTime': '11:00:00',
        'sortOrder': sortOrder,
        'estimatedCost': null,
        'latitude': null,
        'longitude': null,
        'transportationNote': null,
        'createdAt': '2026-07-25T10:00:00Z',
      };

  Map<String, dynamic> tripDayJson({
    int id = 9,
    int dayNumber = 1,
    String? date = '2026-08-01',
    List<Map<String, dynamic>> items = const [],
  }) =>
      {
        'id': id,
        'dayNumber': dayNumber,
        'date': date,
        'title': null,
        'notes': null,
        'items': items,
      };

  Map<String, dynamic> tripDetailJson({
    int id = 1,
    String title = 'Da Lat Getaway',
    String status = 'PLANNING',
    List<Map<String, dynamic>> days = const [],
  }) =>
      {
        'id': id,
        'userId': 2,
        'title': title,
        'description': 'Weekend trip',
        'destination': 'Da Lat',
        'coverImage': null,
        'startDate': '2026-08-01',
        'endDate': '2026-08-03',
        'status': status,
        'isPublic': false,
        'days': days,
        'createdAt': '2026-07-25T10:00:00Z',
        'updatedAt': '2026-07-25T10:00:00Z',
      };

  AppState realApp(http.Client client) => AppState(
        api: ApiClient(client: client)..demoMode = false,
      )..demoMode = false;

  AppState demoApp(http.Client client) =>
      AppState(api: ApiClient(client: client));

  Place samplePlace({int id = 7}) => Place(
        id: id,
        name: 'Backend Villa',
        category: 'Hotels',
        locationName: 'Da Lat',
        city: 'Da Lat',
        province: 'Lam Dong',
        description: 'A calm hillside villa.',
        imageUrl: '',
        rating: 4.6,
      );

  // ── Contract parsing ────────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('valid trip list maps and calls GET /api/me/trips', () async {
      var path = '';
      var method = '';
      final app = realApp(MockClient((request) async {
        path = request.url.path;
        method = request.method;
        return jsonResponse([tripSummaryJson(), tripSummaryJson(id: 2)], 200);
      }));

      final result = await app.loadRealTrips();

      expect(result, TripActionResult.success);
      expect(path, '/api/me/trips');
      expect(method, 'GET');
      expect(app.realTrips.length, 2);
      expect(app.realTrips.first.title, 'Da Lat Getaway');
      expect(app.realTrips.first.dayCount, 2);
      expect(app.realTrips.first.status, TripPlanStatusValue.planning);
    });

    test('valid detail preserves day and item ordering', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          tripDetailJson(days: [
            tripDayJson(id: 20, dayNumber: 2, items: [
              tripItemJson(id: 201, sortOrder: 1, placeName: 'Second'),
              tripItemJson(id: 200, sortOrder: 0, placeName: 'First'),
            ]),
            tripDayJson(id: 10, dayNumber: 1, items: const []),
          ]),
          200,
        );
      }));

      final result = await app.loadRealTripDetail(1);

      expect(result, TripActionResult.success);
      final detail = app.realSelectedTripDetail!;
      expect(detail.days.map((d) => d.dayNumber), [1, 2]);
      expect(detail.days[1].items.map((i) => i.sortOrder), [0, 1]);
      expect(detail.days[1].items.first.displayTitle, 'First');
    });

    test('nullable/partial fields degrade honestly', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse([
          {
            'id': 5,
            'title': 'Sparse',
            'destination': null,
            'coverImage': null,
            'startDate': null,
            'endDate': null,
            'status': null,
            'isPublic': false,
            'dayCount': 0,
            'updatedAt': null,
          }
        ], 200);
      }));

      await app.loadRealTrips();
      final t = app.realTrips.single;
      expect(t.destination, isNull);
      expect(t.startDate, isNull);
      expect(t.status, TripPlanStatusValue.unknown);
      expect(t.dayCount, 0);
    });

    test('custom-only item parses without a place link', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          tripDetailJson(days: [
            tripDayJson(items: [
              tripItemJson(
                id: 301,
                placeId: null,
                placeName: null,
                customTitle: 'Free time',
                customDescription: 'Relax by the lake',
              ),
            ]),
          ]),
          200,
        );
      }));

      await app.loadRealTripDetail(1);
      final item = app.realSelectedTripDetail!.days.single.items.single;
      expect(item.hasPlace, isFalse);
      expect(item.displayTitle, 'Free time');
    });

    test('unknown status keeps the raw backend value', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse([tripSummaryJson(status: 'ARCHIVED')], 200);
      }));

      await app.loadRealTrips();
      expect(app.realTrips.single.status, TripPlanStatusValue.unknown);
      expect(app.realTrips.single.statusRaw, 'ARCHIVED');
    });

    test('LocalTime HH:mm:ss trims to HH:mm and dates parse', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          tripDetailJson(days: [
            tripDayJson(date: '2026-08-01', items: [
              tripItemJson(startTime: '09:30:00'),
            ]),
          ]),
          200,
        );
      }));

      await app.loadRealTripDetail(1);
      final detail = app.realSelectedTripDetail!;
      expect(detail.startDate, DateTime(2026, 8, 1));
      expect(detail.days.single.items.single.startTime, '09:30');
    });

    test('malformed (non-array) list body surfaces a typed error', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse({'not': 'a list'}, 200);
      }));

      final result = await app.loadRealTrips();
      expect(result, TripActionResult.malformed);
      expect(app.realTrips, isEmpty);
    });

    test('create posts TripRequest to POST /api/me/trips', () async {
      var path = '';
      var method = '';
      Map<String, dynamic> body = {};
      final app = realApp(MockClient((request) async {
        path = request.url.path;
        method = request.method;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(tripDetailJson(id: 42, title: 'New Trip'), 201);
      }));

      final result = await app.createRealTrip(
        title: 'New Trip',
        destination: 'Hue',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 4),
      );

      expect(result, TripActionResult.success);
      expect(path, '/api/me/trips');
      expect(method, 'POST');
      expect(body['title'], 'New Trip');
      expect(body['startDate'], '2026-09-01');
      expect(body['endDate'], '2026-09-04');
      expect(body['isPublic'], false);
      expect(app.realTrips.first.id, 42);
    });

    test('addTripItem posts {placeId} to the day items endpoint', () async {
      var path = '';
      var method = '';
      Map<String, dynamic> body = {};
      final app = realApp(MockClient((request) async {
        path = request.url.path;
        method = request.method;
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse(tripItemJson(), 201);
      }));

      final result = await app.addRealTripPlace(dayId: 9, placeId: 7);

      expect(result, TripActionResult.success);
      expect(path, '/api/me/trips/days/9/items');
      expect(method, 'POST');
      expect(body, {'placeId': 7});
    });

    test('authenticated requests send the bearer token', () async {
      String? auth;
      final api = ApiClient(client: MockClient((request) async {
        auth = request.headers['authorization'];
        return jsonResponse(const [], 200);
      }))
        ..demoMode = false
        ..token = 'jwt-abc';
      final app = AppState(api: api)..demoMode = false;

      await app.loadRealTrips();
      expect(auth, 'Bearer jwt-abc');
    });
  });

  // ── Demo Mode isolation ─────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('real trip loads make zero HTTP calls', () async {
      var calls = 0;
      final app = demoApp(MockClient((request) async {
        calls++;
        return jsonResponse(const [], 200);
      }));

      expect(await app.loadRealTrips(), TripActionResult.unavailable);
      expect(await app.loadRealTripDetail(1), TripActionResult.unavailable);
      expect(await app.addRealTripPlace(dayId: 9, placeId: 7),
          TripActionResult.unavailable);
      expect(
        (await app.createRealTripDay(tripId: 1, dayNumber: 1)).result,
        TripActionResult.unavailable,
      );
      expect(
        await app.createRealTrip(
          title: 'x',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 2),
        ),
        TripActionResult.unavailable,
      );
      expect(calls, 0);
    });

    test('demo trips list is preserved and non-empty', () async {
      final app = demoApp(MockClient((request) async {
        return jsonResponse(const [], 200);
      }));
      expect(app.demoMode, isTrue);
      expect(app.trips, isNotEmpty);
      await app.loadRealTrips();
      expect(app.trips, isNotEmpty);
      expect(app.realTrips, isEmpty);
    });
  });

  // ── Real trip list states ───────────────────────────────────────────────────

  group('Real trip list', () {
    test('exposes a loading flag while the request is in flight', () async {
      final completer = Completer<http.Response>();
      final app = realApp(MockClient((request) => completer.future));

      final future = app.loadRealTrips();
      expect(app.realTripsLoading, isTrue);
      completer.complete(jsonResponse([tripSummaryJson()], 200));
      await future;
      expect(app.realTripsLoading, isFalse);
      expect(app.realTripsLoaded, isTrue);
    });

    test('empty list loads to an empty, loaded state', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(const [], 200);
      }));
      await app.loadRealTrips();
      expect(app.realTrips, isEmpty);
      expect(app.realTripsLoaded, isTrue);
      expect(app.realTripsError, isNull);
    });

    test('refresh re-fetches and replaces the list', () async {
      var count = 1;
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          [for (var i = 0; i < count; i++) tripSummaryJson(id: i + 1)],
          200,
        );
      }));
      await app.loadRealTrips();
      expect(app.realTrips.length, 1);
      count = 3;
      await app.loadRealTrips(refresh: true);
      expect(app.realTrips.length, 3);
    });

    test('network failure preserves the prior list and allows retry', () async {
      var fail = false;
      final app = realApp(MockClient((request) async {
        if (fail) throw http.ClientException('offline');
        return jsonResponse([tripSummaryJson()], 200);
      }));
      await app.loadRealTrips();
      expect(app.realTrips.length, 1);
      fail = true;
      final r = await app.loadRealTrips(refresh: true);
      expect(r, TripActionResult.network);
      expect(app.realTrips.length, 1); // preserved
      fail = false;
      expect(await app.loadRealTrips(refresh: true), TripActionResult.success);
    });

    test('5xx maps to a server error', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(errorBody(500, 'boom', '/api/me/trips'), 500);
      }));
      expect(await app.loadRealTrips(), TripActionResult.serverError);
    });

    test('401 maps to sessionExpired without logging out', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(errorBody(401, 'unauth', '/api/me/trips'), 401);
      }));
      final r = await app.loadRealTrips();
      expect(r, TripActionResult.sessionExpired);
      expect(app.demoMode, isFalse); // never switched to demo
      expect(app.realTripsError, TripActionResult.sessionExpired);
    });

    test('403 maps to a distinct forbidden result', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(errorBody(403, 'nope', '/api/me/trips'), 403);
      }));
      expect(await app.loadRealTrips(), TripActionResult.forbidden);
    });
  });

  // ── Real trip detail ────────────────────────────────────────────────────────

  group('Real trip detail', () {
    test('missing trip (404) maps to notFound', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(errorBody(404, 'gone', '/api/me/trips/9'), 404);
      }));
      final r = await app.loadRealTripDetail(9);
      expect(r, TripActionResult.notFound);
      expect(app.realSelectedTripDetail, isNull);
      expect(app.realTripDetailError, TripActionResult.notFound);
    });

    test('a newer selection supersedes an in-flight load', () async {
      final gate = Completer<http.Response>();
      var seen = <int>[];
      final app = realApp(MockClient((request) async {
        final id = int.parse(request.url.pathSegments.last);
        seen.add(id);
        if (id == 1) return gate.future;
        return jsonResponse(tripDetailJson(id: id), 200);
      }));

      final f1 = app.loadRealTripDetail(1); // stalls on gate
      await app.loadRealTripDetail(2); // supersedes
      expect(app.realSelectedTripId, 2);
      gate.complete(jsonResponse(tripDetailJson(id: 1), 200));
      await f1;
      // The stale trip-1 result must not overwrite the trip-2 selection.
      expect(app.realSelectedTripDetail!.id, 2);
    });
  });

  // ── Add to trip ─────────────────────────────────────────────────────────────

  group('Add to trip', () {
    test('add reflects the new item into the loaded detail', () async {
      final app = realApp(MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse(
            tripDetailJson(days: [tripDayJson(id: 9, items: const [])]),
            200,
          );
        }
        return jsonResponse(tripItemJson(id: 500), 201);
      }));

      await app.loadRealTripDetail(1);
      expect(app.realSelectedTripDetail!.days.single.items, isEmpty);
      final r = await app.addRealTripPlace(dayId: 9, placeId: 7);
      expect(r, TripActionResult.success);
      expect(app.realSelectedTripDetail!.days.single.items.single.id, 500);
    });

    test('new-day path creates a day then adds the item to it', () async {
      final requests = <String>[];
      final app = realApp(MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/days')) {
          return jsonResponse(tripDayJson(id: 77, dayNumber: 1), 201);
        }
        return jsonResponse(tripItemJson(), 201);
      }));

      final day = await app.createRealTripDay(tripId: 1, dayNumber: 1);
      expect(day.result, TripActionResult.success);
      expect(day.dayId, 77);
      final add = await app.addRealTripPlace(dayId: day.dayId!, placeId: 7);
      expect(add, TripActionResult.success);
      expect(requests, [
        'POST /api/me/trips/1/days',
        'POST /api/me/trips/days/77/items',
      ]);
    });

    test('422 unpublished place maps to unprocessable', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(
          errorBody(422, 'Only published places can be added to a trip',
              '/api/me/trips/days/9/items'),
          422,
        );
      }));
      expect(await app.addRealTripPlace(dayId: 9, placeId: 7),
          TripActionResult.unprocessable);
    });

    test('403 forbidden and 404 notFound are distinct', () async {
      final forbidden = realApp(MockClient((request) async {
        return jsonResponse(errorBody(403, 'no', '/x'), 403);
      }));
      final missing = realApp(MockClient((request) async {
        return jsonResponse(errorBody(404, 'no', '/x'), 404);
      }));
      expect(await forbidden.addRealTripPlace(dayId: 9, placeId: 7),
          TripActionResult.forbidden);
      expect(await missing.addRealTripPlace(dayId: 9, placeId: 7),
          TripActionResult.notFound);
    });

    test('401 during add maps to sessionExpired (no logout)', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(errorBody(401, 'no', '/x'), 401);
      }));
      expect(await app.addRealTripPlace(dayId: 9, placeId: 7),
          TripActionResult.sessionExpired);
      expect(app.demoMode, isFalse);
    });

    test('concurrent add is de-duped to a single request', () async {
      final completer = Completer<http.Response>();
      var calls = 0;
      final app = realApp(MockClient((request) {
        calls++;
        return completer.future;
      }));

      final f1 = app.addRealTripPlace(dayId: 9, placeId: 7);
      final f2 = app.addRealTripPlace(dayId: 9, placeId: 7); // guarded
      completer.complete(jsonResponse(tripItemJson(), 201));
      await Future.wait([f1, f2]);
      expect(calls, 1);
    });
  });

  // ── Create trip ─────────────────────────────────────────────────────────────

  group('Create trip', () {
    test('success prepends the new trip summary', () async {
      final app = realApp(MockClient((request) async {
        if (request.method == 'GET') {
          return jsonResponse([tripSummaryJson(id: 1)], 200);
        }
        return jsonResponse(tripDetailJson(id: 99, title: 'Fresh'), 201);
      }));
      await app.loadRealTrips();
      expect(app.realTrips.length, 1);
      final r = await app.createRealTrip(
        title: 'Fresh',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 2),
      );
      expect(r, TripActionResult.success);
      expect(app.realTrips.first.id, 99);
      expect(app.realTrips.length, 2);
    });

    test('validation (400) preserves the list and returns validation',
        () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse(errorBody(400, 'bad', '/api/me/trips'), 400);
      }));
      final r = await app.createRealTrip(
        title: 'x',
        startDate: DateTime(2026, 9, 2),
        endDate: DateTime(2026, 9, 1),
      );
      expect(r, TripActionResult.validation);
      expect(app.realTrips, isEmpty);
    });

    test('concurrent create is guarded against double submit', () async {
      final completer = Completer<http.Response>();
      var calls = 0;
      final app = realApp(MockClient((request) {
        calls++;
        return completer.future;
      }));
      final f1 = app.createRealTrip(
        title: 'x',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 2),
      );
      final f2 = app.createRealTrip(
        title: 'x',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 2),
      );
      completer.complete(jsonResponse(tripDetailJson(id: 5), 201));
      await Future.wait([f1, f2]);
      expect(calls, 1);
    });
  });

  // ── Session isolation ───────────────────────────────────────────────────────

  group('Session', () {
    test('logout clears all real-trip state', () async {
      final app = realApp(MockClient((request) async {
        return jsonResponse([tripSummaryJson()], 200);
      }));
      await app.loadRealTrips();
      expect(app.realTrips, isNotEmpty);
      await app.logout();
      expect(app.realTrips, isEmpty);
      expect(app.realTripsLoaded, isFalse);
      expect(app.realSelectedTripDetail, isNull);
    });
  });

  // ── Widget: real trips screen ───────────────────────────────────────────────

  group('Widget — real trips', () {
    testWidgets('renders trip cards after a successful load', (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        return jsonResponse(
            [tripSummaryJson(id: 1, title: 'Ha Long Trip')], 200);
      }));
      await pumpSize(
        tester,
        testApp(app: app, child: const Scaffold(body: TripsScreen())),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('real-trip-card-1')), findsOneWidget);
      expect(find.text('Ha Long Trip'), findsOneWidget);
    });

    testWidgets('shows the empty state with a create action', (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        return jsonResponse(const [], 200);
      }));
      await pumpSize(
        tester,
        testApp(app: app, child: const Scaffold(body: TripsScreen())),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('real-trips-empty')), findsOneWidget);
    });

    testWidgets('401 shows the session-expired state (no logout)',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        return jsonResponse(errorBody(401, 'no', '/api/me/trips'), 401);
      }));
      await pumpSize(
        tester,
        testApp(app: app, child: const Scaffold(body: TripsScreen())),
        const Size(1200, 2000),
      );
      expect(
        find.byKey(const Key('real-trips-session-expired')),
        findsOneWidget,
      );
      expect(app.demoMode, isFalse);
    });
  });

  // ── Widget: add-to-trip sheet ───────────────────────────────────────────────

  group('Widget — add to trip sheet', () {
    Widget sheetHost(AppState app) => testApp(
          app: app,
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showAddToTripSheet(context, samplePlace()),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );

    testWidgets('lists real trips and adds a place, closing on success',
        (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/trips' && request.method == 'GET') {
          return jsonResponse([tripSummaryJson(id: 1)], 200);
        }
        if (request.url.path == '/api/me/trips/1') {
          return jsonResponse(
            tripDetailJson(days: [tripDayJson(id: 9, dayNumber: 1)]),
            200,
          );
        }
        if (request.url.path == '/api/me/trips/days/9/items') {
          return jsonResponse(tripItemJson(), 201);
        }
        return jsonResponse(errorBody(404, 'no', request.url.path), 404);
      }));

      await pumpSize(tester, sheetHost(app), const Size(1200, 2000));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('real-quick-add-trip-1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('real-quick-add-trip-1')));
      await tester.pumpAndSettle();

      // Existing day chip is offered alongside the "new day" option.
      expect(find.byKey(const Key('real-quick-add-day-9')), findsOneWidget);
      await tester.tap(find.byKey(const Key('real-quick-add-day-9')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('real-quick-add-submit')));
      await tester.pumpAndSettle();

      // Sheet closed on confirmed success.
      expect(find.byKey(const Key('real-quick-add-submit')), findsNothing);
    });

    testWidgets('failed add keeps the sheet open', (tester) async {
      ignoreNetworkImageErrors();
      final app = realApp(MockClient((request) async {
        if (request.url.path == '/api/me/trips' && request.method == 'GET') {
          return jsonResponse([tripSummaryJson(id: 1)], 200);
        }
        if (request.url.path == '/api/me/trips/1') {
          return jsonResponse(
            tripDetailJson(days: [tripDayJson(id: 9, dayNumber: 1)]),
            200,
          );
        }
        return jsonResponse(
          errorBody(500, 'boom', request.url.path),
          500,
        );
      }));

      await pumpSize(tester, sheetHost(app), const Size(1200, 2000));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('real-quick-add-trip-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('real-quick-add-day-9')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('real-quick-add-submit')));
      await tester.pumpAndSettle();

      // Sheet stays open after a failed add.
      expect(find.byKey(const Key('real-quick-add-submit')), findsOneWidget);
    });
  });

  // ── Localization parity ─────────────────────────────────────────────────────

  group('Localization', () {
    testWidgets('new keys resolve in both English and Vietnamese',
        (tester) async {
      for (final locale in const [Locale('en'), Locale('vi')]) {
        late AppLocalizations l10n;
        await tester.pumpWidget(
          testApp(
            locale: locale,
            child: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context)!;
                return const SizedBox();
              },
            ),
          ),
        );
        expect(l10n.tripsRealLoadingMessage, isNotEmpty);
        expect(l10n.addToTripRealNewDayOption(2), isNotEmpty);
        expect(l10n.tripDetailRealEditDisabledNote, isNotEmpty);
        expect(l10n.createTripRealErrorMessage, isNotEmpty);
      }
    });
  });
}
