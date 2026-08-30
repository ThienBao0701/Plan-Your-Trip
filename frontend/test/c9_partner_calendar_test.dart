import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_inventory_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/calendar/partner_calendar_screen.dart';
import 'package:planyourtrip_frontend/features/partner/calendar/partner_calendar_state.dart';
import 'package:planyourtrip_frontend/features/partner/calendar/widgets/partner_calendar_widgets.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C9 — Partner Calendar / Operations.
///
/// Encodes the boundary and the semantics the audit established:
///
///  * **C9 reuses C4 entirely.** It adds no endpoint, no DTO and no parsing —
///    `ApiClient.getPartnerInventory` and `PartnerInventoryDay` are C4's.
///  * **C9 mutates nothing.** The three restriction toggles live in C4; two code
///    paths writing the same rows would be worse than one. Numeric inventory
///    editing stays withheld because `RoomInventory` has no `@Version`.
///  * **A missing inventory row is not "free".** `HotelSearchService` counts
///    rows and rejects a stay when any night is missing.
///  * **Four separate availability questions**, matching the four separate
///    backend conditions; CTA restricts only the arrival night and CTD only the
///    last night.
///  * **Occupancy is the backend's own `soldInventory`** — written by
///    `decrementInventory` over `[checkIn, checkOut)` — never inferred by
///    matching booking rows to dates.
///  * **The calendar range is inclusive** on both ends (`BETWEEN`), which is a
///    different thing from a booking's half-open night span. Both models stand.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();

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

  Map<String, dynamic> profileJson({String verificationStatus = 'APPROVED'}) =>
      {
        'id': 7,
        'userId': 42,
        'businessName': 'Bay View Resorts',
        'representativeName': 'Le Minh',
        'email': 'ops@bayview.example',
        'verificationStatus': verificationStatus,
      };

  Map<String, dynamic> extranetHomeJson() => {
        'profile': {
          'id': 7,
          'businessName': 'Bay View Resorts',
          'representativeName': 'Le Minh',
          'email': 'ops@bayview.example',
        },
        'verificationStatus': 'APPROVED',
        'ownedHotelCount': 1,
        'activeRoomCount': 2,
        'todaysArrivals': 0,
        'todaysDepartures': 0,
        'unreadMessages': 0,
        'unreadNotifications': 0,
        'pendingReviews': 0,
        'activePromotions': 0,
        'quickActions': <Object>[],
      };

  Map<String, dynamic> hotelJson({int id = 11}) => {
        'id': id,
        'name': 'Bay View Danang',
        'slug': 'bay-view-danang',
        'shortDescription': null,
        'address': '12 Vo Nguyen Giap',
        'active': true,
        'featured': false,
        'verified': true,
        'ratingAvg': 4.6,
        'reviewCount': 12,
        'status': 'PUBLISHED',
        'createdAt': '2026-07-30T02:00:00Z',
        'updatedAt': '2026-08-20T02:00:00Z',
      };

  Map<String, dynamic> roomJson(
          {int id = 1, String roomName = 'Standard Twin'}) =>
      {
        'id': id,
        'roomName': roomName,
        'roomCode': 'STD-$id',
        'roomType': 'STANDARD',
        'description': null,
        'bedType': 'TWIN',
        'bedCount': 2,
        'maxAdults': 2,
        'maxChildren': 0,
        'maxGuests': 2,
        'roomSizeSqm': 25.0,
        'floorNumber': null,
        'smokingAllowed': false,
        'breakfastIncluded': true,
        'freeCancellation': false,
        'instantConfirmation': true,
        'priceFrom': 900000,
        'originalPrice': null,
        'quantity': 20,
        'availableQuantity': 18,
        'active': true,
        'amenities': <Object>[],
        'coverImageUrl': null,
        'galleryImages': <Object>[],
        'createdAt': '2026-08-29T08:26:09Z',
        'updatedAt': '2026-08-29T08:26:09Z',
      };

  /// `RoomInventoryDto.RoomInventoryResponse` — the same shape C4 consumes.
  Map<String, dynamic> dayJson(
    String date, {
    int id = 1,
    int roomId = 1,
    int total = 20,
    int available = 18,
    int blocked = 1,
    int sold = 0,
    int maintenance = 1,
    bool stopSell = false,
    bool closedArrival = false,
    bool closedDeparture = false,
  }) =>
      {
        'id': id,
        'roomId': roomId,
        'inventoryDate': date,
        'totalInventory': total,
        'availableInventory': available,
        'blockedInventory': blocked,
        'soldInventory': sold,
        'maintenanceInventory': maintenance,
        'stopSell': stopSell,
        'closedArrival': closedArrival,
        'closedDeparture': closedDeparture,
        'createdAt': '2026-08-29T08:26:09Z',
        'updatedAt': '2026-08-29T08:26:09Z',
      };

  String iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Rows for the **inclusive** window the client asks for, mirroring the
  /// backend's `BETWEEN :from AND :to` exactly.
  List<Map<String, dynamic>> daysBetween(String from, String to, int roomId) {
    final start = DateTime.parse(from);
    final end = DateTime.parse(to);
    final rows = <Map<String, dynamic>>[];
    var cursor = start;
    var id = roomId * 1000;
    while (!cursor.isAfter(end)) {
      rows.add(dayJson(iso(cursor), id: id++, roomId: roomId));
      cursor = cursor.add(const Duration(days: 1));
    }
    return rows;
  }

  late List<String> requestLog;
  late List<Uri> requestUris;
  setUp(() {
    requestLog = <String>[];
    requestUris = <Uri>[];
  });

  MockClient calendarClient({
    Map<String, http.Response>? overrides,
    List<Map<String, dynamic>>? rooms,

    /// Fixed inventory per room id; when absent the mock generates a full
    /// inclusive window, like the backend does.
    Map<int, List<Map<String, dynamic>>>? inventoryByRoom,

    /// Room ids whose calendar request should fail.
    Set<int> failingRooms = const {},
    bool throwNetwork = false,
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path');
        requestUris.add(request.url);
        if (throwNetwork) throw http.ClientException('offline');

        if (overrides != null) {
          for (final entry in overrides.entries) {
            if (path.endsWith(entry.key)) return entry.value;
          }
        }

        if (path.endsWith('/partner/profile')) {
          return jsonResponse(profileJson(), 200);
        }
        if (path.endsWith('/partner/extranet/home')) {
          return jsonResponse(extranetHomeJson(), 200);
        }
        if (path.endsWith('/partner/team')) {
          return jsonResponse(<Object>[], 200);
        }
        if (path.endsWith('/partner/hotels')) {
          return jsonResponse([hotelJson()], 200);
        }
        if (path.endsWith('/partner/rooms')) {
          return jsonResponse(rooms ?? [roomJson()], 200);
        }

        final calendar =
            RegExp(r'/partner/calendar/rooms/(\d+)$').firstMatch(path);
        if (calendar != null) {
          final roomId = int.parse(calendar.group(1)!);
          final owned =
              (rooms ?? [roomJson()]).map((r) => r['id'] as int).toSet();
          if (!owned.contains(roomId)) {
            // The backend answers unknown and unowned alike with 404.
            return jsonResponse(
                errorBody(404, 'Room not found: $roomId', path), 404);
          }
          if (failingRooms.contains(roomId)) {
            return jsonResponse(errorBody(500, 'boom', path), 500);
          }
          final from = request.url.queryParameters['from'];
          final to = request.url.queryParameters['to'];
          final inventory = inventoryByRoom?[roomId] ??
              (from != null && to != null
                  ? daysBetween(from, to, roomId)
                  : daysBetween('2026-01-01', '2026-12-31', roomId));
          return jsonResponse({
            'roomId': roomId,
            'roomCode': 'STD-$roomId',
            'roomName': 'Standard Twin',
            'inventory': inventory,
          }, 200);
        }
        return jsonResponse(errorBody(404, 'Not found', path), 404);
      });

  AppState partnerApp(http.Client client) =>
      AppState(api: ApiClient(client: client)..demoMode = false)
        ..demoMode = false
        ..email = 'partner@planyourtrip.com'
        ..role = AppRole.partner;

  Widget testApp({
    required AppState app,
    required PartnerState partner,
    Locale? locale,
  }) =>
      AppScope(
        notifier: app,
        child: PartnerScope(
          notifier: partner,
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: PartnerCalendarScreen()),
            ),
          ),
        ),
      );

  Future<({AppState app, PartnerState partner})> pumpCalendar(
    WidgetTester tester, {
    http.Client? client,
    Size size = const Size(1600, 3400),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? calendarClient());
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester
        .pumpWidget(testApp(app: app, partner: partner, locale: locale));
    await tester.pumpAndSettle();
    return (app: app, partner: partner);
  }

  Future<({PartnerCalendarState state, PartnerState partner})> loadedState(
    http.Client client,
  ) async {
    final app = partnerApp(client);
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);
    final state = PartnerCalendarState(api: app.api);
    await state.load(partner, partner.selectedPropertyId);
    return (state: state, partner: partner);
  }

  List<String> captureLayoutErrors(WidgetTester tester) {
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.toString());
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
    return errors;
  }

  Uri lastCalendarUri(int roomId) => requestUris
      .lastWhere((u) => u.path.endsWith('/partner/calendar/rooms/$roomId'));

  // ── C4 reuse and the C9 boundary ──────────────────────────────────────

  group('C9 reuses C4 and adds nothing to the API surface', () {
    test('the cells wrap C4 models rather than redeclaring them', () async {
      final loaded = await loadedState(calendarClient());
      final cell = loaded.state.rows.single.cells.first;
      // The type itself is the proof: no second inventory model exists.
      expect(cell.day, isA<PartnerInventoryDay>());
    });

    test('only the C4 calendar GET and the C3 rooms GET are issued', () async {
      await loadedState(calendarClient());
      final partnerCalls =
          requestLog.where((r) => r.contains('/partner/')).toSet();
      expect(
        partnerCalls,
        {
          'GET /api/partner/profile',
          'GET /api/partner/extranet/home',
          'GET /api/partner/hotels',
          'GET /api/partner/rooms',
          'GET /api/partner/calendar/rooms/1',
        },
      );
    });

    test('the module never writes', () async {
      final loaded = await loadedState(calendarClient());
      loaded.state.selectCell(1, loaded.state.days.first);
      await loaded.state.shiftWeeks(loaded.partner, 1);
      await loaded.state.goToToday(loaded.partner);
      await loaded.state.refresh(loaded.partner);
      // No PATCH, PUT, POST or DELETE — C4 owns every inventory write.
      expect(requestLog.where((r) => !r.startsWith('GET')), isEmpty);
    });

    testWidgets('the two views live under one destination', (tester) async {
      await pumpCalendar(tester);
      expect(find.text(en.partnerCalendarTabOverview), findsOneWidget);
      expect(find.text(en.partnerCalendarTabInventory), findsOneWidget);
    });

    testWidgets('no inventory quantity editor is offered', (tester) async {
      await pumpCalendar(tester);
      final state = tester.state<State<PartnerCalendarScreen>>(
          find.byType(PartnerCalendarScreen));
      expect(state.mounted, isTrue);
      // `RoomInventory` has no @Version, so numeric editing is withheld here.
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(Slider), findsNothing);
    });
  });

  // ── Date semantics ────────────────────────────────────────────────────

  group('date semantics', () {
    test('the window is requested with an inclusive from/to pair', () async {
      final loaded = await loadedState(calendarClient());
      final uri = lastCalendarUri(1);
      expect(uri.queryParameters['from'], iso(loaded.state.windowStart));
      expect(uri.queryParameters['to'], iso(loaded.state.windowEnd));
    });

    test('both bounds are always sent — never a partial range', () async {
      // A partial range makes the backend return the room's entire history.
      await loadedState(calendarClient());
      final uri = lastCalendarUri(1);
      expect(uri.queryParameters.containsKey('from'), isTrue);
      expect(uri.queryParameters.containsKey('to'), isTrue);
    });

    test('the inclusive window spans exactly windowDays days', () async {
      final loaded = await loadedState(calendarClient());
      expect(loaded.state.days, hasLength(PartnerCalendarState.windowDays));
      expect(
        loaded.state.windowEnd.difference(loaded.state.windowStart).inDays,
        PartnerCalendarState.windowDays - 1,
      );
    });

    test('the window starts at today by default', () async {
      final loaded = await loadedState(calendarClient());
      expect(loaded.state.windowStart, today());
      expect(loaded.state.showsToday, isTrue);
    });

    test('shifting moves by whole weeks so columns stay aligned', () async {
      final loaded = await loadedState(calendarClient());
      final start = loaded.state.windowStart;
      await loaded.state.shiftWeeks(loaded.partner, 1);
      expect(loaded.state.windowStart, start.add(const Duration(days: 7)));
      expect(loaded.state.windowStart.weekday, start.weekday);

      await loaded.state.shiftWeeks(loaded.partner, -2);
      expect(loaded.state.windowStart, start.subtract(const Duration(days: 7)));
    });

    test('today returns the window and is a no-op when already there',
        () async {
      final loaded = await loadedState(calendarClient());
      await loaded.state.shiftWeeks(loaded.partner, 3);
      expect(loaded.state.showsToday, isFalse);

      await loaded.state.goToToday(loaded.partner);
      expect(loaded.state.windowStart, today());

      final before = requestLog.length;
      await loaded.state.goToToday(loaded.partner);
      expect(requestLog.length, before);
    });

    test('the calendar range and a booking night span stay separate models',
        () async {
      // C4/C9: the range query is inclusive of both ends.
      // C8: a booking covers [checkIn, checkOut), keyed by night-start date.
      // Nothing here converts one into the other.
      final loaded = await loadedState(calendarClient());
      final days = loaded.state.days;
      expect(days.first, loaded.state.windowStart);
      expect(days.last, loaded.state.windowEnd);
    });
  });

  // ── Availability semantics ────────────────────────────────────────────

  group('availability semantics follow HotelSearchService exactly', () {
    PartnerCalendarCell cellFrom({
      int available = 5,
      bool stopSell = false,
      bool closedArrival = false,
      bool closedDeparture = false,
      int sold = 0,
    }) =>
        PartnerCalendarCell(
          roomId: 1,
          date: DateTime(2026, 9, 1),
          day: PartnerInventoryDay.fromJson(dayJson(
            '2026-09-01',
            available: available,
            stopSell: stopSell,
            closedArrival: closedArrival,
            closedDeparture: closedDeparture,
            sold: sold,
          )),
        );

    test('a night with stock and no stop-sell is open', () {
      final cell = cellFrom();
      expect(cell.state, PartnerNightState.open);
      expect(cell.state.isSellable, isTrue);
    });

    test('stop-sell beats stock', () {
      final cell = cellFrom(available: 9, stopSell: true);
      expect(cell.state, PartnerNightState.stopSell);
      expect(cell.state.isSellable, isFalse);
    });

    test('zero available with no stop-sell is sold out', () {
      expect(cellFrom(available: 0).state, PartnerNightState.soldOut);
    });

    test('a missing row is noRecord — and that is not "free"', () {
      final cell = PartnerCalendarCell(roomId: 1, date: DateTime(2026, 9, 1));
      expect(cell.day, isNull);
      expect(cell.state, PartnerNightState.noRecord);
      expect(cell.state.isSellable, isFalse);
      // `HotelSearchService` rejects the stay when a night has no row at all.
      expect(cell.canStartStay, isFalse);
      expect(cell.canEndStay, isFalse);
    });

    test('closed-to-arrival blocks only the start of a stay', () {
      final cell = cellFrom(closedArrival: true);
      // Still sellable inside a longer stay — CTA is checked only against the
      // stay's checkIn date.
      expect(cell.state.isSellable, isTrue);
      expect(cell.canStartStay, isFalse);
      expect(cell.canEndStay, isTrue);
    });

    test('closed-to-departure blocks only the last night of a stay', () {
      final cell = cellFrom(closedDeparture: true);
      expect(cell.state.isSellable, isTrue);
      expect(cell.canStartStay, isTrue);
      expect(cell.canEndStay, isFalse);
    });

    test('both restrictions can hold at once', () {
      final cell = cellFrom(closedArrival: true, closedDeparture: true);
      expect(cell.state.isSellable, isTrue);
      expect(cell.canStartStay, isFalse);
      expect(cell.canEndStay, isFalse);
      expect(cell.hasRestriction, isTrue);
    });

    test('an unsellable night can never start or end a stay', () {
      final stopped = cellFrom(stopSell: true);
      expect(stopped.canStartStay, isFalse);
      expect(stopped.canEndStay, isFalse);
    });

    test('occupancy comes from soldInventory, never from booking rows', () {
      final cell = cellFrom(sold: 3);
      expect(cell.sold, 3);
      expect(cell.isOccupied, isTrue);
      // No booking endpoint is involved in building the calendar.
      expect(requestLog.where((r) => r.contains('/partner/bookings')), isEmpty);
    });

    test('an inconsistent row is surfaced, not corrected', () {
      final cell = PartnerCalendarCell(
        roomId: 1,
        date: DateTime(2026, 9, 1),
        day: PartnerInventoryDay.fromJson(dayJson('2026-09-01',
            total: 20, available: 5, sold: 1, blocked: 1)),
      );
      expect(cell.isInconsistent, isTrue);
    });
  });

  // ── Grid construction ─────────────────────────────────────────────────

  group('room and day mapping', () {
    test('every row spans the whole window, gaps included', () async {
      final start = today();
      final loaded = await loadedState(calendarClient(
        inventoryByRoom: {
          // Only two rows exist; the other twelve days must still appear.
          1: [
            dayJson(iso(start)),
            dayJson(iso(start.add(const Duration(days: 3))), id: 2),
          ],
        },
      ));
      final cells = loaded.state.rows.single.cells;
      expect(cells, hasLength(PartnerCalendarState.windowDays));
      expect(cells[0].day, isNotNull);
      expect(cells[1].day, isNull);
      expect(cells[1].state, PartnerNightState.noRecord);
      expect(cells[3].day, isNotNull);
    });

    test('a day the server did not send becomes noRecord, not omitted',
        () async {
      final loaded = await loadedState(
          calendarClient(inventoryByRoom: {1: <Map<String, dynamic>>[]}));
      final row = loaded.state.rows.single;
      expect(row.cells, hasLength(PartnerCalendarState.windowDays));
      expect(row.missingNights, PartnerCalendarState.windowDays);
      expect(loaded.state.isWindowEmpty, isTrue);
    });

    test('one request per room, not one per room-day', () async {
      await loadedState(calendarClient(
        rooms: [roomJson(id: 1), roomJson(id: 2), roomJson(id: 3)],
      ));
      final calls =
          requestLog.where((r) => r.contains('/partner/calendar/rooms/'));
      // Three rooms, fourteen days: three requests, not forty-two.
      expect(calls, hasLength(3));
    });

    test('rows arrive in the room order the backend gave', () async {
      final loaded = await loadedState(calendarClient(rooms: [
        roomJson(id: 1, roomName: 'Standard Twin'),
        roomJson(id: 2, roomName: 'Deluxe King'),
      ]));
      expect(loaded.state.rows.map((r) => r.room.id), [1, 2]);
    });

    test('one failing room marks its row without blanking the grid', () async {
      final loaded = await loadedState(calendarClient(
        rooms: [roomJson(id: 1), roomJson(id: 2)],
        failingRooms: {2},
      ));
      expect(loaded.state.status, PartnerCalendarStatus.ready);
      expect(loaded.state.rows, hasLength(2));
      expect(loaded.state.rows[0].hasError, isFalse);
      expect(loaded.state.rows[1].hasError, isTrue);
      // A failed row must not read as "no inventory".
      expect(loaded.state.rows[1].cells, isEmpty);
      expect(loaded.state.failedRooms, 1);
    });

    test('window totals count only what was loaded', () async {
      final start = today();
      final loaded = await loadedState(calendarClient(inventoryByRoom: {
        1: [
          dayJson(iso(start), sold: 2),
          dayJson(iso(start.add(const Duration(days: 1))),
              id: 2, stopSell: true),
          dayJson(iso(start.add(const Duration(days: 2))),
              id: 3, closedArrival: true),
        ],
      }));
      expect(loaded.state.totalSellableNights, 2);
      expect(loaded.state.totalOccupiedNights, 1);
      expect(loaded.state.totalRestrictedNights, 2);
      expect(
          loaded.state.totalMissingNights, PartnerCalendarState.windowDays - 3);
    });
  });

  // ── Property and room context ─────────────────────────────────────────

  group('property and room context', () {
    test('no request is made for a property the workspace does not list',
        () async {
      final loaded = await loadedState(calendarClient());
      final before = requestLog.length;
      await loaded.state.load(loaded.partner, 987654);
      expect(requestLog.length, before);
      expect(loaded.state.rooms, isEmpty);
      expect(loaded.state.rows, isEmpty);
      expect(loaded.state.status, PartnerCalendarStatus.ready);
    });

    test('switching property clears rooms, rows and the selection', () async {
      final loaded = await loadedState(calendarClient());
      loaded.state.selectCell(1, loaded.state.days.first);
      expect(loaded.state.selectedCell, isNotNull);

      await loaded.state.load(loaded.partner, 987654);
      expect(loaded.state.selectedCell, isNull);
      expect(loaded.state.rows, isEmpty);
    });

    test('an unowned room id can never be requested', () async {
      // Rooms come from the server for the selected property, so the client
      // only ever asks about ids the server just handed it.
      await loadedState(calendarClient(rooms: [roomJson(id: 1)]));
      final requested = requestUris
          .where((u) => u.path.contains('/partner/calendar/rooms/'))
          .map((u) => u.path.split('/').last)
          .toSet();
      expect(requested, {'1'});
    });

    test('a 404 on a room calendar is the uniform unknown-or-unowned answer',
        () async {
      // The mock answers an id outside the owned set with 404, exactly as
      // `ownedRoomOrThrow` does for both unknown and another partner's room.
      final loaded = await loadedState(calendarClient(
        rooms: [roomJson(id: 1)],
        overrides: {
          '/partner/calendar/rooms/1':
              jsonResponse(errorBody(404, 'Room not found: 1', '/x'), 404),
        },
      ));
      expect(loaded.state.rows.single.hasError, isTrue);
      expect(loaded.state.rows.single.errorKind, ApiErrorKind.notFound);
    });

    test('selecting a cell outside the grid is refused', () async {
      final loaded = await loadedState(calendarClient());
      loaded.state.selectCell(999, loaded.state.days.first);
      expect(loaded.state.selectedCell, isNull);

      loaded.state.selectCell(1, DateTime(2000, 1, 1));
      expect(loaded.state.selectedCell, isNull);
    });

    test('a selection outside the new window is dropped on navigation',
        () async {
      final loaded = await loadedState(calendarClient());
      loaded.state.selectCell(1, loaded.state.days.first);
      expect(loaded.state.selectedCell, isNotNull);
      await loaded.state.shiftWeeks(loaded.partner, 4);
      expect(loaded.state.selectedCell, isNull);
    });

    test('a property with no rooms is a real answer', () async {
      final loaded = await loadedState(calendarClient(rooms: []));
      expect(loaded.state.status, PartnerCalendarStatus.ready);
      expect(loaded.state.hasNoRooms, isTrue);
      expect(requestLog.where((r) => r.contains('/calendar/rooms/')), isEmpty);
    });
  });

  // ── Error semantics ───────────────────────────────────────────────────

  group('error mapping', () {
    test('401 on rooms is a session problem', () async {
      final loaded = await loadedState(calendarClient(overrides: {
        '/partner/rooms': jsonResponse(errorBody(401, 'no', '/x'), 401),
      }));
      expect(loaded.state.status, PartnerCalendarStatus.unauthorized);
    });

    test('403 on rooms is an approval problem', () async {
      final loaded = await loadedState(calendarClient(overrides: {
        '/partner/rooms': jsonResponse(errorBody(403, 'no', '/x'), 403),
      }));
      expect(loaded.state.status, PartnerCalendarStatus.forbidden);
    });

    test('404 on rooms means no partner profile or property', () async {
      final loaded = await loadedState(calendarClient(overrides: {
        '/partner/rooms': jsonResponse(errorBody(404, 'no', '/x'), 404),
      }));
      expect(loaded.state.status, PartnerCalendarStatus.notFound);
    });

    test('400 on rooms is a retryable error rather than a lifecycle state',
        () async {
      final loaded = await loadedState(calendarClient(overrides: {
        '/partner/rooms': jsonResponse(errorBody(400, 'bad', '/x'), 400),
      }));
      expect(loaded.state.status, PartnerCalendarStatus.error);
      expect(loaded.state.isRetryable, isTrue);
    });

    test('a 5xx on rooms is an error, not an empty calendar', () async {
      final loaded = await loadedState(calendarClient(overrides: {
        '/partner/rooms': jsonResponse(errorBody(500, 'boom', '/x'), 500),
      }));
      expect(loaded.state.status, PartnerCalendarStatus.error);
      expect(loaded.state.hasNoRooms, isFalse);
    });

    test('a network failure is retryable', () async {
      final app = partnerApp(calendarClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final offline = partnerApp(calendarClient(throwNetwork: true));
      final state = PartnerCalendarState(api: offline.api);
      await state.load(partner, partner.selectedPropertyId);
      expect(state.status, PartnerCalendarStatus.error);
      expect(state.isRetryable, isTrue);
    });

    test('a timeout on one room calendar marks only that row', () async {
      final client = MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path');
        if (path.contains('/partner/calendar/rooms/2')) {
          await Future<void>.delayed(const Duration(seconds: 30));
        }
        if (path.endsWith('/partner/profile')) {
          return jsonResponse(profileJson(), 200);
        }
        if (path.endsWith('/partner/extranet/home')) {
          return jsonResponse(extranetHomeJson(), 200);
        }
        if (path.endsWith('/partner/team')) {
          return jsonResponse(<Object>[], 200);
        }
        if (path.endsWith('/partner/hotels')) {
          return jsonResponse([hotelJson()], 200);
        }
        if (path.endsWith('/partner/rooms')) {
          return jsonResponse([roomJson(id: 1), roomJson(id: 2)], 200);
        }
        final m = RegExp(r'/partner/calendar/rooms/(\d+)$').firstMatch(path);
        if (m != null) {
          final id = int.parse(m.group(1)!);
          return jsonResponse({
            'roomId': id,
            'roomCode': 'STD-$id',
            'roomName': 'Standard Twin',
            'inventory': daysBetween(
              request.url.queryParameters['from']!,
              request.url.queryParameters['to']!,
              id,
            ),
          }, 200);
        }
        return jsonResponse(errorBody(404, 'x', path), 404);
      });
      final loaded = await loadedState(client);
      expect(loaded.state.status, PartnerCalendarStatus.ready);
      expect(loaded.state.rows[0].hasError, isFalse);
      expect(loaded.state.rows[1].errorKind, ApiErrorKind.timeout);
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  // ── UI ────────────────────────────────────────────────────────────────

  group('calendar UI', () {
    testWidgets('renders a grid of real inventory', (tester) async {
      await pumpCalendar(tester);
      expect(find.byType(Table), findsOneWidget);
      expect(find.text(en.partnerCalendarScopeNote), findsOneWidget);
    });

    testWidgets('the legend names every state it can draw', (tester) async {
      await pumpCalendar(tester);
      expect(find.text(en.partnerCalendarStateOpen), findsWidgets);
      expect(find.text(en.partnerCalendarStateStopSell), findsWidgets);
      expect(find.text(en.partnerCalendarStateSoldOut), findsWidgets);
      expect(find.text(en.partnerCalendarStateNoRecord), findsWidgets);
      expect(find.text(en.partnerCalendarLegendClosedArrival), findsWidgets);
      expect(find.text(en.partnerCalendarLegendClosedDeparture), findsWidgets);
      expect(find.text(en.partnerCalendarLegendNote), findsOneWidget);
    });

    testWidgets('a property with no rooms says so', (tester) async {
      await pumpCalendar(tester, client: calendarClient(rooms: []));
      expect(find.text(en.partnerCalendarNoRoomsTitle), findsOneWidget);
      expect(find.text(en.partnerCalendarNoRoomsMessage), findsOneWidget);
    });

    testWidgets('a window with no records explains why that is not free',
        (tester) async {
      await pumpCalendar(tester,
          client:
              calendarClient(inventoryByRoom: {1: <Map<String, dynamic>>[]}));
      expect(find.text(en.partnerCalendarWindowEmptyMessage), findsOneWidget);
    });

    testWidgets('a failed room is reported as unreadable, not empty',
        (tester) async {
      await pumpCalendar(tester,
          client: calendarClient(
              rooms: [roomJson(id: 1), roomJson(id: 2)], failingRooms: {2}));
      expect(
          find.text(en.partnerCalendarRoomsFailed('1', '2')), findsOneWidget);
    });

    testWidgets('selecting a night answers the four questions separately',
        (tester) async {
      await pumpCalendar(tester);
      await tester.tap(find.byType(PartnerCalendarCellTile).first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerCalendarQuestionsHeading), findsOneWidget);
      expect(find.text(en.partnerCalendarQuestionStock), findsOneWidget);
      expect(find.text(en.partnerCalendarQuestionSellable), findsOneWidget);
      expect(find.text(en.partnerCalendarQuestionArrival), findsOneWidget);
      expect(find.text(en.partnerCalendarQuestionDeparture), findsOneWidget);
      expect(find.text(en.partnerCalendarQuestionsNote), findsOneWidget);
    });

    testWidgets('a night with no record explains the consequence',
        (tester) async {
      final start = today();
      await pumpCalendar(tester,
          client: calendarClient(inventoryByRoom: {
            1: [dayJson(iso(start.add(const Duration(days: 5))))]
          }));
      // The first column has no row behind it.
      await tester.tap(find.byType(PartnerCalendarCellTile).first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerCalendarNoRecordExplanation), findsOneWidget);
    });

    testWidgets('the panel says writes belong to the inventory tab',
        (tester) async {
      await pumpCalendar(tester);
      await tester.tap(find.byType(PartnerCalendarCellTile).first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerCalendarReadOnlyNote), findsOneWidget);
      expect(find.text(en.partnerCalendarManageRestrictions), findsOneWidget);
    });

    testWidgets('the manage link hands over to the C4 inventory tab',
        (tester) async {
      await pumpCalendar(tester);
      await tester.tap(find.byType(PartnerCalendarCellTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerCalendarManageRestrictions));
      await tester.pumpAndSettle();
      // C4's own screen is now on show; C9 did not reimplement its controls.
      expect(find.text(en.partnerCalendarQuestionsHeading), findsNothing);
    });

    testWidgets('week navigation re-requests the new window', (tester) async {
      await pumpCalendar(tester);
      final before = lastCalendarUri(1).queryParameters['from'];
      await tester.tap(find.byTooltip(en.partnerCalendarNextWeek));
      await tester.pumpAndSettle();
      expect(lastCalendarUri(1).queryParameters['from'], isNot(before));
    });
  });

  // ── Workspace gating ──────────────────────────────────────────────────

  group('workspace gating', () {
    testWidgets('a non-approved partner never reaches the calendar',
        (tester) async {
      final app = partnerApp(MockClient((request) async {
        if (request.url.path.endsWith('/partner/profile')) {
          return jsonResponse(
              profileJson(verificationStatus: 'SUBMITTED'), 200);
        }
        return jsonResponse(errorBody(404, 'no', request.url.path), 404);
      }));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerCalendarTabOverview), findsNothing);
    });

    testWidgets('demo mode shows no fabricated calendar', (tester) async {
      final app = AppState(api: ApiClient(client: calendarClient()))
        ..demoMode = true
        ..email = 'demo@planyourtrip.com'
        ..role = AppRole.partner;
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();
      expect(find.byType(Table), findsNothing);
    });
  });

  // ── Layout ────────────────────────────────────────────────────────────

  group('layout', () {
    testWidgets('desktop shows the grid', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpCalendar(tester, size: const Size(1600, 3400));
      expect(find.byType(Table), findsOneWidget);
      expect(errors, isEmpty);
    });

    testWidgets('tablet keeps the grid and scrolls it horizontally',
        (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpCalendar(tester, size: const Size(820, 3400));
      expect(find.byType(Table), findsOneWidget);
      expect(errors, isEmpty);
    });

    testWidgets('mobile swaps the grid for a focused day view', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpCalendar(tester, size: const Size(390, 3600));
      // A fourteen-column grid would be unusable at this width.
      expect(find.byType(Table), findsNothing);
      expect(errors, isEmpty);
    });

    testWidgets('a very narrow phone does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpCalendar(tester, size: const Size(320, 3600));
      expect(errors, isEmpty);
    });

    testWidgets('the night panel fits a narrow phone', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpCalendar(tester, size: const Size(320, 4200));
      // Mobile shows room cards for one day, not grid cells.
      await tester.tap(find.byType(PartnerCalendarDayRoomCard).first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerCalendarQuestionsHeading), findsOneWidget);
      expect(errors, isEmpty);
    });
  });

  group('localization', () {
    testWidgets('English renders English strings', (tester) async {
      await pumpCalendar(tester, locale: const Locale('en'));
      expect(find.text(en.partnerCalendarTitle), findsOneWidget);
      expect(find.text(en.partnerCalendarTabOverview), findsOneWidget);
    });

    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpCalendar(tester, locale: const Locale('vi'));
      expect(find.text(vi.partnerCalendarTitle), findsOneWidget);
      expect(find.text(vi.partnerCalendarTabOverview), findsOneWidget);
    });

    testWidgets('Vietnamese mobile does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpCalendar(tester,
          size: const Size(390, 3600), locale: const Locale('vi'));
      expect(errors, isEmpty);
    });

    test('labels do not collide with the sidebar destinations', () {
      expect(en.partnerCalendarTabOverview, isNot(en.partnerNavCalendar));
      expect(vi.partnerCalendarTabOverview, isNot(vi.partnerNavCalendar));
      expect(en.partnerCalendarTabInventory, isNot(en.partnerNavRooms));
      expect(vi.partnerCalendarTabInventory, isNot(vi.partnerNavRooms));
      expect(en.partnerCalendarTitle, isNot(en.partnerNavCalendar));
      expect(vi.partnerCalendarTitle, isNot(vi.partnerNavCalendar));
    });
  });
}
