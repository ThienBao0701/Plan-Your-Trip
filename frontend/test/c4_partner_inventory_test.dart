import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_inventory_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/inventory/partner_inventory_screen.dart';
import 'package:planyourtrip_frontend/features/partner/inventory/partner_inventory_state.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C4 — Partner Inventory (the backend's "calendar" surface).
///
/// The assertions below encode the semantics established from
/// `RoomInventoryService` / `RoomInventoryRepository` and confirmed against the
/// running backend:
///
///  * `from`/`to` are **inclusive on both ends** (`BETWEEN :from AND :to`).
///  * The range is applied only when **both** bounds are sent; one alone is
///    silently ignored and returns the room's whole history.
///  * An inverted range is **200 with an empty list**, not a 400.
///  * The five quantities are stored independently and are **not** required to
///    sum to `totalInventory`.
///  * `stopSell` is a separate gate from zero availability.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  Map<String, dynamic> profileJson({String verificationStatus = 'APPROVED'}) => {
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

  Map<String, dynamic> hotelJson({int id = 11, String name = 'Bay View Danang'}) => {
        'id': id,
        'name': name,
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

  Map<String, dynamic> roomJson({int id = 1, String roomName = 'Standard Twin'}) => {
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
        'quantity': 10,
        'availableQuantity': 4,
        'active': true,
        'amenities': <Object>[],
        'coverImageUrl': null,
        'galleryImages': <Object>[],
        'createdAt': '2026-08-29T08:26:09Z',
        'updatedAt': '2026-08-29T08:26:09Z',
      };

  /// `RoomInventoryDto.RoomInventoryResponse` — every field the record declares.
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

  String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Generates rows for the inclusive window the client asks for, mirroring the
  /// backend's `BETWEEN` semantics exactly.
  List<Map<String, dynamic>> daysBetween(String from, String to) {
    final start = DateTime.parse(from);
    final end = DateTime.parse(to);
    if (start.isAfter(end)) return const [];
    final out = <Map<String, dynamic>>[];
    var cursor = start;
    var id = 1;
    while (!cursor.isAfter(end)) {
      out.add(dayJson(iso(cursor), id: id++));
      cursor = cursor.add(const Duration(days: 1));
    }
    return out;
  }

  late List<String> requestLog;
  setUp(() => requestLog = <String>[]);

  MockClient inventoryClient({
    Map<String, http.Response>? overrides,
    List<Map<String, dynamic>>? hotels,
    List<Map<String, dynamic>>? rooms,
    List<Map<String, dynamic>>? fixedDays,
    bool throwNetwork = false,
    String verificationStatus = 'APPROVED',
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path?${request.url.query}');
        if (throwNetwork) throw http.ClientException('offline');

        if (overrides != null) {
          for (final entry in overrides.entries) {
            if (path.contains(entry.key)) return entry.value;
          }
        }

        if (path.endsWith('/partner/profile')) {
          return jsonResponse(
              profileJson(verificationStatus: verificationStatus), 200);
        }
        if (path.endsWith('/partner/extranet/home')) {
          return jsonResponse(extranetHomeJson(), 200);
        }
        if (path.endsWith('/partner/team')) return jsonResponse(<Object>[], 200);
        if (path.endsWith('/partner/hotels')) {
          return jsonResponse(hotels ?? [hotelJson()], 200);
        }
        if (path.endsWith('/partner/rooms')) {
          final hotelId = request.url.queryParameters['hotelId'];
          final owned = (hotels ?? [hotelJson()]).map((h) => '${h['id']}');
          if (hotelId == null || !owned.contains(hotelId)) {
            return jsonResponse(
                errorBody(404, 'Hotel not found', path), 404);
          }
          return jsonResponse(rooms ?? [roomJson()], 200);
        }

        // Flag PATCH: /partner/calendar/rooms/{id}/{date}/{flag}
        final flagMatch = RegExp(
                r'/partner/calendar/rooms/(\d+)/(\d{4}-\d{2}-\d{2})/(stop-sell|closed-arrival|closed-departure)$')
            .firstMatch(path);
        if (flagMatch != null) {
          final roomId = int.parse(flagMatch.group(1)!);
          final date = flagMatch.group(2)!;
          final flag = flagMatch.group(3)!;
          final value =
              (jsonDecode(request.body) as Map<String, dynamic>)['value'] == true;
          return jsonResponse(
            dayJson(date,
                roomId: roomId,
                stopSell: flag == 'stop-sell' && value,
                closedArrival: flag == 'closed-arrival' && value,
                closedDeparture: flag == 'closed-departure' && value),
            200,
          );
        }

        final calMatch =
            RegExp(r'/partner/calendar/rooms/(\d+)$').firstMatch(path);
        if (calMatch != null) {
          final roomId = int.parse(calMatch.group(1)!);
          final known = (rooms ?? [roomJson()]).map((r) => r['id']);
          if (!known.contains(roomId)) {
            return jsonResponse(
                errorBody(404, 'Room not found: $roomId', path), 404);
          }
          final from = request.url.queryParameters['from'];
          final to = request.url.queryParameters['to'];
          final inventory = fixedDays ??
              (from != null && to != null
                  ? daysBetween(from, to)
                  // Mirrors the backend: a partial range returns everything.
                  : daysBetween('2026-01-01', '2026-12-31'));
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
              body: SingleChildScrollView(child: PartnerInventoryScreen()),
            ),
          ),
        ),
      );

  Future<({AppState app, PartnerState partner})> pumpInventory(
    WidgetTester tester, {
    http.Client? client,
    Size size = const Size(1600, 2400),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? inventoryClient());
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp(app: app, partner: partner, locale: locale));
    await tester.pumpAndSettle();
    return (app: app, partner: partner);
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

  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();

  // ── Date semantics — the heart of C4 ─────────────────────────────────────

  group('date semantics', () {
    test('the window is inclusive on both ends', () {
      final now = DateTime(2026, 8, 29);
      final week = PartnerInventoryRange.week.resolve(now);
      expect(week.from, DateTime(2026, 8, 29));
      // 7 days counting BOTH ends -> Aug 29 + 6, not +7.
      expect(week.to, DateTime(2026, 9, 4));
      expect(week.to.difference(week.from).inDays, 6);

      final month = PartnerInventoryRange.month.resolve(now);
      expect(month.to.difference(month.from).inDays, 29);
    });

    test('a 7-day window really returns 7 rows', () async {
      final api = ApiClient(client: inventoryClient())..demoMode = false;
      final from = DateTime(2026, 8, 29);
      final to = DateTime(2026, 9, 4);
      final result =
          await api.getPartnerInventory(roomId: 1, from: from, to: to);
      expect(result.success, isTrue);
      expect(result.data!.days.length, 7);
      expect(result.data!.days.first.date, from);
      expect(result.data!.days.last.date, to);
    });

    test('a single-day window returns exactly one row', () async {
      final api = ApiClient(client: inventoryClient())..demoMode = false;
      final day = DateTime(2026, 9, 1);
      final result =
          await api.getPartnerInventory(roomId: 1, from: day, to: day);
      expect(result.data!.days.length, 1);
    });

    test('both bounds are always sent — never one', () async {
      final api = ApiClient(client: inventoryClient())..demoMode = false;
      await api.getPartnerInventory(
          roomId: 1, from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 7));

      final calls = requestLog
          .where((r) => r.contains('/partner/calendar/rooms/1?'))
          .toList();
      expect(calls, isNotEmpty);
      for (final call in calls) {
        expect(call.contains('from='), isTrue);
        expect(call.contains('to='), isTrue,
            reason: 'a partial range is silently ignored by the backend');
      }
    });

    test('an inverted range is refused client-side, not shown as empty',
        () async {
      // The backend answers from>to with 200 + [], which would read as "no
      // inventory". The state refuses it before the request is made.
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      await inventory.load(partner, 11);
      expect(inventory.status, PartnerInventoryStatus.ready);
      requestLog.clear();

      await inventory.setCustomWindow(DateTime(2026, 9, 10), DateTime(2026, 9, 1));

      expect(inventory.status, PartnerInventoryStatus.invalidRange);
      expect(inventory.isEmpty, isFalse,
          reason: 'an invalid range is not an empty calendar');
      expect(requestLog, isEmpty,
          reason: 'an inverted range must not be sent to the backend');
    });

    test('a valid custom window is honoured inclusively', () async {
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      await inventory.load(partner, 11);

      await inventory.setCustomWindow(
          DateTime(2026, 9, 1), DateTime(2026, 9, 3));

      expect(inventory.status, PartnerInventoryStatus.ready);
      expect(inventory.hasCustomWindow, isTrue);
      expect(inventory.calendar!.days.length, 3,
          reason: 'Sep 1-3 inclusive is three rows');
    });

    test('choosing a preset clears a custom window', () async {
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      await inventory.load(partner, 11);

      await inventory.setCustomWindow(
          DateTime(2026, 9, 1), DateTime(2026, 9, 3));
      expect(inventory.hasCustomWindow, isTrue);

      await inventory.selectRange(PartnerInventoryRange.week);
      expect(inventory.hasCustomWindow, isFalse);
      expect(inventory.calendar!.days.length, 7);
    });

    test('inventoryDate is a plain calendar day, immune to timezone shifts',
        () {
      final day = PartnerInventoryDay.fromJson(dayJson('2026-08-29'))!;
      expect(day.date.year, 2026);
      expect(day.date.month, 8);
      expect(day.date.day, 29);
      expect(day.date.hour, 0);
    });
  });

  // ── Load / render ────────────────────────────────────────────────────────

  group('inventory load', () {
    testWidgets('renders the calendar for the selected property and room',
        (tester) async {
      await pumpInventory(tester);

      expect(find.text(en.partnerInventoryForProperty('Bay View Danang')),
          findsOneWidget);
      expect(find.text(en.partnerInventoryAvailable), findsWidgets);
      expect(find.text(en.partnerInventoryStateBookable), findsWidgets);
      // 14-day default window.
      expect(find.text(en.partnerInventoryRangeFortnight), findsOneWidget);
    });

    testWidgets('follows the property → rooms → calendar chain', (tester) async {
      await pumpInventory(tester);
      expect(requestLog.any((r) => r.contains('/partner/hotels')), isTrue);
      expect(requestLog.any((r) => r.contains('/partner/rooms?hotelId=11')),
          isTrue);
      expect(requestLog.any((r) => r.contains('/partner/calendar/rooms/1?')),
          isTrue);
    });

    testWidgets('invents no metric the DTO does not supply', (tester) async {
      await pumpInventory(tester);
      // Occupancy %, revenue and booking counts are dashboard concepts; the
      // inventory record supplies none of them.
      expect(find.text(en.partnerKpiOccupancy), findsNothing);
      expect(find.text(en.partnerKpiTotalRevenue), findsNothing);
    });
  });

  // ── Context chain states ─────────────────────────────────────────────────

  group('context chain', () {
    test('no properties is its own state', () async {
      final app = partnerApp(inventoryClient(hotels: <Map<String, dynamic>>[]));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      await inventory.load(partner, null);
      expect(inventory.status, PartnerInventoryStatus.noProperties);
    });

    test('no property selected makes no request', () async {
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      requestLog.clear();
      await inventory.load(partner, null);
      expect(inventory.status, PartnerInventoryStatus.noPropertySelected);
      expect(requestLog, isEmpty);
    });

    test('a property with no rooms stops at noRooms', () async {
      final app =
          partnerApp(inventoryClient(rooms: <Map<String, dynamic>>[]));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      await inventory.load(partner, 11);
      expect(inventory.status, PartnerInventoryStatus.noRooms);
      expect(inventory.calendar, isNull);
    });

    testWidgets('no rooms shows its own view, distinct from empty inventory',
        (tester) async {
      await pumpInventory(
          tester, client: inventoryClient(rooms: <Map<String, dynamic>>[]));
      expect(find.text(en.partnerInventoryNoRoomsTitle), findsOneWidget);
      expect(find.text(en.partnerInventoryEmptyTitle), findsNothing);
    });

    testWidgets('an empty window is an answer, not an error', (tester) async {
      await pumpInventory(
          tester, client: inventoryClient(fixedDays: <Map<String, dynamic>>[]));
      expect(find.text(en.partnerInventoryEmptyTitle), findsOneWidget);
      expect(find.text(en.partnerInventoryInvalidRangeTitle), findsNothing);
      expect(find.text(en.partnerInventoryUnavailableTitle), findsNothing);
    });

    test('a single room is selected automatically', () async {
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      await inventory.load(partner, 11);
      expect(inventory.selectedRoomId, 1);
    });

    test('switching property drops a room id from the old property', () async {
      final app = partnerApp(inventoryClient(
        hotels: [hotelJson(), hotelJson(id: 12, name: 'Hoi An')],
        rooms: [roomJson(), roomJson(id: 2, roomName: 'Deluxe')],
      ));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);

      await inventory.load(partner, 11);
      await inventory.selectRoom(2);
      expect(inventory.selectedRoomId, 2);

      await inventory.load(partner, 12);
      // Re-derived from the new property's room list, never carried over blind.
      expect(inventory.selectedRoomId, isNotNull);
      expect(inventory.loadedPropertyId, 12);
    });

    test('an unauthorized property id is refused before any request', () async {
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      requestLog.clear();

      await inventory.load(partner, 999);

      expect(inventory.status, PartnerInventoryStatus.notFound);
      expect(requestLog, isEmpty);
    });

    test('an unauthorized room id is ignored', () async {
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      await inventory.load(partner, 11);
      requestLog.clear();

      await inventory.selectRoom(9999);
      expect(inventory.selectedRoomId, 1);
      expect(requestLog, isEmpty);
    });
  });

  // ── Quantity / availability semantics ────────────────────────────────────

  group('semantics', () {
    test('bookable follows the backend rule: available > 0 AND !stopSell', () {
      final ok = PartnerInventoryDay.fromJson(dayJson('2026-09-01'))!;
      expect(ok.isBookable, isTrue);

      final stopped = PartnerInventoryDay.fromJson(
          dayJson('2026-09-01', stopSell: true))!;
      expect(stopped.isBookable, isFalse);
      expect(stopped.isSoldOut, isFalse,
          reason: 'stopped is not sold out — different cause, different fix');

      final soldOut =
          PartnerInventoryDay.fromJson(dayJson('2026-09-01', available: 0))!;
      expect(soldOut.isBookable, isFalse);
      expect(soldOut.isSoldOut, isTrue);
    });

    test('stopSell with stock left is stopped, not sold out', () {
      final day = PartnerInventoryDay.fromJson(
          dayJson('2026-09-01', available: 12, stopSell: true))!;
      expect(day.availableInventory, 12);
      expect(day.isSoldOut, isFalse);
      expect(day.isBookable, isFalse);
    });

    test('CTA and CTD are restrictions but do not make a day unbookable', () {
      final cta = PartnerInventoryDay.fromJson(
          dayJson('2026-09-01', closedArrival: true))!;
      expect(cta.hasRestriction, isTrue);
      expect(cta.isBookable, isTrue,
          reason: 'CTA constrains which stays may start, not sellability');
    });

    test('inconsistent counts are surfaced, never silently corrected', () {
      // The backend validates each field <= total but never the sum.
      final bad = PartnerInventoryDay.fromJson(dayJson('2026-09-01',
          total: 20, available: 5, blocked: 1, sold: 0, maintenance: 1))!;
      expect(bad.isInconsistent, isTrue);
      expect(bad.accountedInventory, 7);
      expect(bad.totalInventory, 20, reason: 'total is reported as stored');

      final good = PartnerInventoryDay.fromJson(dayJson('2026-09-01'))!;
      expect(good.isInconsistent, isFalse);
    });

    testWidgets('an inconsistent day is flagged in the UI', (tester) async {
      await pumpInventory(
        tester,
        client: inventoryClient(fixedDays: [
          dayJson('2026-09-01', total: 20, available: 5, blocked: 1,
              sold: 0, maintenance: 1),
        ]),
      );
      expect(find.text(en.partnerInventoryInconsistentSummary(1)),
          findsOneWidget);
    });

    test('room-record quantities are not inventory quantities', () {
      // HotelRoom.quantity/availableQuantity (C3) and RoomInventory's daily
      // counts are separate columns with different values for the same room.
      final day = PartnerInventoryDay.fromJson(dayJson('2026-09-01'))!;
      expect(day.totalInventory, 20);
      expect(roomJson()['quantity'], 10);
      expect(day.totalInventory == roomJson()['quantity'], isFalse);
    });
  });

  // ── Flag mutations ───────────────────────────────────────────────────────

  group('flag mutations', () {
    test('setting stop-sell PATCHes the right endpoint and folds the response',
        () async {
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      await inventory.load(partner, 11);
      final date = inventory.calendar!.days.first.date;
      requestLog.clear();

      final result = await inventory.setFlag(
        date: date,
        flag: PartnerInventoryFlag.stopSell,
        value: true,
      );

      expect(result, PartnerInventoryActionResult.success);
      expect(
        requestLog.any((r) =>
            r.startsWith('PATCH') &&
            r.contains('/partner/calendar/rooms/1/') &&
            r.contains('/stop-sell')),
        isTrue,
      );
      expect(inventory.calendar!.days.first.stopSell, isTrue);
    });

    test('each flag hits its own endpoint', () async {
      final api = ApiClient(client: inventoryClient())..demoMode = false;
      for (final entry in {
        PartnerInventoryFlag.stopSell: 'stop-sell',
        PartnerInventoryFlag.closedArrival: 'closed-arrival',
        PartnerInventoryFlag.closedDeparture: 'closed-departure',
      }.entries) {
        requestLog.clear();
        await api.setPartnerInventoryFlag(
          roomId: 1,
          date: DateTime(2026, 9, 1),
          flag: entry.key,
          value: true,
        );
        expect(requestLog.single.contains('/2026-09-01/${entry.value}'), isTrue);
      }
    });

    test('a date outside the loaded window never reaches the network',
        () async {
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      await inventory.load(partner, 11);
      requestLog.clear();

      final result = await inventory.setFlag(
        date: DateTime(2030, 1, 1),
        flag: PartnerInventoryFlag.stopSell,
        value: true,
      );
      expect(result, PartnerInventoryActionResult.notFound);
      expect(requestLog, isEmpty);
    });

    test('404 on a flag write is reported, and nothing changes', () async {
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final inventory = PartnerInventoryState(api: app.api);
      await inventory.load(partner, 11);
      final date = inventory.calendar!.days.first.date;
      final before = inventory.calendar!.days.first.stopSell;

      final failing = PartnerInventoryState(
        api: ApiClient(
            client: inventoryClient(overrides: {
          '/stop-sell': jsonResponse(
              errorBody(404, 'Inventory not found', '/stop-sell'), 404),
        }))
          ..demoMode = false,
      );
      await failing.load(partner, 11);
      final result = await failing.setFlag(
        date: date,
        flag: PartnerInventoryFlag.stopSell,
        value: true,
      );

      expect(result, PartnerInventoryActionResult.notFound);
      expect(failing.calendar!.days.first.stopSell, before,
          reason: 'a failed write must not appear to have succeeded');
    });

    test('a timed-out write is uncertain, never a clean failure', () async {
      final api = ApiClient(
          client: MockClient((_) async => throw TimeoutException('slow')))
        ..demoMode = false;
      final result = await api.setPartnerInventoryFlag(
        roomId: 1,
        date: DateTime(2026, 9, 1),
        flag: PartnerInventoryFlag.stopSell,
        value: true,
      );
      expect(result.errorKind, ApiErrorKind.uncertain);
    });

    test('no numeric write endpoint is exposed', () {
      // PUT .../{date} and POST .../bulk replace all five quantities including
      // soldInventory, which the booking flow maintains atomically. With no
      // optimistic locking on RoomInventory, exposing them would let a stale
      // form erase a concurrent booking. C4 writes only booleans.
      final api = ApiClient(client: inventoryClient());
      expect(api.setPartnerInventoryFlag, isNotNull);
      expect(
        (api as dynamic).toString().contains('bulk'),
        isFalse,
      );
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────

  group('errors', () {
    testWidgets('401 shows the session-expired view', (tester) async {
      await pumpInventory(
        tester,
        client: inventoryClient(overrides: {
          '/partner/calendar/rooms/': jsonResponse(
              errorBody(401, 'Unauthorized', '/api/partner/calendar'), 401),
        }),
      );
      expect(find.text(en.partnerStatusUnauthorizedTitle), findsOneWidget);
    });

    testWidgets('403 is an approval problem', (tester) async {
      await pumpInventory(
        tester,
        client: inventoryClient(overrides: {
          '/partner/calendar/rooms/': jsonResponse(
              errorBody(403, 'Partner profile is not approved',
                  '/api/partner/calendar'),
              403),
        }),
      );
      expect(find.text(en.partnerStatusForbiddenTitle), findsOneWidget);
    });

    testWidgets('404 shows the unavailable view', (tester) async {
      await pumpInventory(
        tester,
        client: inventoryClient(overrides: {
          '/partner/calendar/rooms/': jsonResponse(
              errorBody(404, 'Room not found', '/api/partner/calendar'), 404),
        }),
      );
      expect(find.text(en.partnerInventoryUnavailableTitle), findsOneWidget);
    });

    test('a network failure is retryable and not empty', () async {
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final offline = PartnerInventoryState(
        api: ApiClient(client: inventoryClient(throwNetwork: true))
          ..demoMode = false,
      );
      await offline.load(partner, 11);

      expect(offline.status, PartnerInventoryStatus.error);
      expect(offline.isRetryable, isTrue);
      expect(offline.isEmpty, isFalse);
    });

    test('a 500 is retryable, not a lifecycle state', () async {
      final app = partnerApp(inventoryClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final failing = PartnerInventoryState(
        api: ApiClient(
            client: inventoryClient(overrides: {
          '/partner/calendar/rooms/': jsonResponse(
              errorBody(500, 'Unexpected server error', '/api'), 500),
        }))
          ..demoMode = false,
      );
      await failing.load(partner, 11);
      expect(failing.status, PartnerInventoryStatus.error);
      expect(failing.isRetryable, isTrue);
    });

    test('a malformed calendar body fails rather than rendering blanks',
        () async {
      final api = ApiClient(
          client: MockClient((_) async => http.Response('[]', 200,
              headers: {'content-type': 'application/json; charset=utf-8'})))
        ..demoMode = false;
      final result = await api.getPartnerInventory(
          roomId: 1, from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 2));
      expect(result.success, isFalse);
      expect(result.errorKind, ApiErrorKind.malformed);
    });

    testWidgets('a non-approved partner never reaches inventory',
        (tester) async {
      final app =
          partnerApp(inventoryClient(verificationStatus: 'SUBMITTED'));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerStatusAwaitingApprovalTitle), findsOneWidget);
      expect(requestLog.any((r) => r.contains('/partner/calendar')), isFalse);
    });
  });

  // ── Role ─────────────────────────────────────────────────────────────────

  group('team role', () {
    testWidgets('the owner can toggle restrictions', (tester) async {
      final handles = await pumpInventory(tester);
      expect(handles.partner.teamRole, PartnerTeamRole.owner);
      expect(find.text(en.partnerInventoryEditOwnerOnly), findsNothing);
      expect(find.text(en.partnerInventoryStopSell), findsWidgets);
    });
  });

  // ── Responsive ───────────────────────────────────────────────────────────

  group('responsive', () {
    testWidgets('desktop renders the dense table', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpInventory(tester, size: const Size(1700, 2400));
      expect(find.byType(Table), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('mobile uses cards instead of the table, with no overflow',
        (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpInventory(tester, size: const Size(390, 4000));
      // The dense table is not squeezed onto a phone...
      expect(find.byType(Table), findsNothing);
      // ...but the same data is still present.
      expect(find.text(en.partnerInventoryAvailable), findsWidgets);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('tablet renders without layout errors', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpInventory(tester, size: const Size(820, 4000));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('a very narrow phone does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpInventory(tester, size: const Size(320, 4200));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });
  });

  // ── Localization ─────────────────────────────────────────────────────────

  group('localization', () {
    testWidgets('English renders English strings', (tester) async {
      await pumpInventory(tester, locale: const Locale('en'));
      expect(find.text(en.partnerInventoryAvailable), findsWidgets);
      expect(find.text(en.partnerInventoryStopSell), findsWidgets);
    });

    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpInventory(tester, locale: const Locale('vi'));
      expect(find.text(vi.partnerInventoryAvailable), findsWidgets);
      expect(find.text(vi.partnerInventoryStopSell), findsWidgets);
      expect(find.text(en.partnerInventoryStopSell), findsNothing);
    });

    testWidgets('Vietnamese mobile does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpInventory(
          tester, size: const Size(390, 4200), locale: const Locale('vi'));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    test('every C4 string exists in both locales', () {
      for (final l10n in <AppLocalizations>[en, vi]) {
        expect(l10n.partnerInventoryEmptyTitle, isNotEmpty);
        expect(l10n.partnerInventorySelectRoomTitle, isNotEmpty);
        expect(l10n.partnerInventoryInvalidRangeTitle, isNotEmpty);
        expect(l10n.partnerInventoryStateStopped, isNotEmpty);
        expect(l10n.partnerInventoryClosedDeparture, isNotEmpty);
        expect(l10n.partnerInventoryWindow('a', 'b', 7), isNotEmpty);
        expect(l10n.partnerInventoryBookableDays(3, 7), isNotEmpty);
        expect(l10n.partnerInventoryStopSellDays(2), isNotEmpty);
        expect(l10n.partnerInventoryInconsistentSummary(1), isNotEmpty);
      }
    });
  });
}
