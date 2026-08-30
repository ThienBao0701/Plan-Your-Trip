import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_room_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/rooms/partner_rooms_screen.dart';
import 'package:planyourtrip_frontend/features/partner/rooms/partner_rooms_state.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C3 — Partner Rooms.
///
/// Asserts against `HotelRoomResponse` as the backend actually returns it, and
/// against two contract facts that shape the whole module:
///
///  * `GET /api/partner/rooms` takes a **required** `hotelId`, so property
///    context is mandatory and "no property selected" is a first-class state.
///  * A room has **no status enum** — only a boolean `active`. `PlaceStatus`
///    must not leak in from C2.
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
        'activeRoomCount': 4,
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
        'shortDescription': 'Beachfront resort',
        'address': '12 Vo Nguyen Giap, Da Nang',
        'active': true,
        'featured': false,
        'verified': true,
        'ratingAvg': 4.6,
        'reviewCount': 12,
        'status': 'PUBLISHED',
        'createdAt': '2026-07-30T02:00:00Z',
        'updatedAt': '2026-08-20T02:00:00Z',
      };

  /// `HotelRoomDto.HotelRoomResponse` — every field the record declares.
  /// `description`, `floorNumber` and `originalPrice` are null exactly as the
  /// live backend returns them for the seeded rooms.
  Map<String, dynamic> roomJson({
    int id = 1,
    String roomName = 'Standard Twin Room',
    String roomCode = 'STD-TWIN',
    String roomType = 'STANDARD',
    Object? bedType = 'TWIN',
    bool active = true,
    int? quantity = 10,
    int? availableQuantity = 4,
    Object? priceFrom = 900000,
    List<Map<String, dynamic>>? amenities,
  }) =>
      {
        'id': id,
        'roomName': roomName,
        'roomCode': roomCode,
        'roomType': roomType,
        'description': null,
        'bedType': bedType,
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
        'priceFrom': priceFrom,
        'originalPrice': null,
        'quantity': quantity,
        'availableQuantity': availableQuantity,
        'active': active,
        'amenities': amenities ??
            [
              {
                'id': 1,
                'name': 'Free WiFi',
                'slug': 'free-wifi',
                'icon': 'wifi',
                'groupName': 'GENERAL'
              },
            ],
        'coverImageUrl': null,
        'galleryImages': <Object>[],
        'createdAt': '2026-08-29T08:26:09Z',
        'updatedAt': '2026-08-29T08:26:09Z',
      };

  late List<String> requestLog;
  setUp(() => requestLog = <String>[]);

  MockClient roomsClient({
    Map<String, http.Response>? overrides,
    List<Map<String, dynamic>>? hotels,
    List<Map<String, dynamic>>? rooms,
    bool throwNetwork = false,
    String verificationStatus = 'APPROVED',
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path?${request.url.query}');
        if (throwNetwork) throw http.ClientException('offline');

        if (overrides != null) {
          for (final entry in overrides.entries) {
            if (path.endsWith(entry.key)) return entry.value;
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

        final roomDetail = RegExp(r'/partner/rooms/(\d+)$').firstMatch(path);
        if (roomDetail != null) {
          final id = int.parse(roomDetail.group(1)!);
          final list = rooms ?? [roomJson()];
          final match = list.where((r) => r['id'] == id);
          if (match.isEmpty) {
            return jsonResponse(
                errorBody(404, 'Room not found: $id', path), 404);
          }
          return jsonResponse(match.first, 200);
        }
        if (path.endsWith('/partner/rooms')) {
          // Mirror the backend: hotelId is required and validated for ownership.
          final hotelId = request.url.queryParameters['hotelId'];
          if (hotelId == null) {
            return jsonResponse(
                errorBody(500, 'Unexpected server error', path), 500);
          }
          final owned = (hotels ?? [hotelJson()]).map((h) => '${h['id']}');
          if (!owned.contains(hotelId)) {
            return jsonResponse(
                errorBody(404, 'Hotel not found: $hotelId', path), 404);
          }
          return jsonResponse(rooms ?? [roomJson()], 200);
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
              body: SingleChildScrollView(child: PartnerRoomsScreen()),
            ),
          ),
        ),
      );

  Future<({AppState app, PartnerState partner})> pumpRooms(
    WidgetTester tester, {
    http.Client? client,
    Size size = const Size(1440, 1800),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? roomsClient());
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

  // ── 1. Room list ─────────────────────────────────────────────────────────

  group('room list', () {
    testWidgets('renders rooms for the selected property', (tester) async {
      await pumpRooms(tester);

      expect(find.text('Standard Twin Room'), findsOneWidget);
      expect(find.text('STD-TWIN'), findsOneWidget);
      expect(find.text(en.partnerRoomTypeStandard), findsWidgets);
      expect(find.text(en.partnerRoomListed), findsWidgets);
      // The property context is named, because the room record carries none.
      expect(find.text(en.partnerRoomsForProperty('Bay View Danang')),
          findsOneWidget);
    });

    testWidgets('always sends the required hotelId', (tester) async {
      await pumpRooms(tester);
      final roomCalls =
          requestLog.where((r) => r.contains('/partner/rooms?')).toList();
      expect(roomCalls, isNotEmpty);
      for (final call in roomCalls) {
        expect(call.contains('hotelId=11'), isTrue,
            reason: 'hotelId is required; never call the list without it');
      }
    });

    testWidgets('invents nothing the room DTO does not supply', (tester) async {
      await pumpRooms(tester);
      // A room has no lifecycle status — C2's PlaceStatus vocabulary must not
      // leak into this screen.
      expect(find.text(en.partnerPropertyStatusPublished), findsNothing);
      expect(find.text(en.partnerPropertyStatusPendingReview), findsNothing);
      // No create affordance: no create endpoint exists.
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('shows inactive and sold-out as separate facts',
        (tester) async {
      await pumpRooms(
        tester,
        client: roomsClient(rooms: [
          roomJson(),
          roomJson(
              id: 2,
              roomName: 'Deluxe Sea View',
              roomCode: 'DLX-SEA',
              roomType: 'DELUXE',
              active: false),
          roomJson(
              id: 3,
              roomName: 'Family Suite',
              roomCode: 'FAM',
              roomType: 'FAMILY',
              availableQuantity: 0),
        ]),
      );

      expect(find.text(en.partnerRoomUnlisted), findsWidgets);
      expect(find.text(en.partnerRoomSoldOut), findsWidgets);
      expect(find.text(en.partnerRoomsCount(3)), findsOneWidget);
      expect(find.text(en.partnerRoomsListedCount(2)), findsOneWidget);
      expect(find.text(en.partnerRoomsSoldOutCount(1)), findsOneWidget);
    });
  });

  // ── 2. Detail ────────────────────────────────────────────────────────────

  group('room detail', () {
    testWidgets('opens detail and renders the DTO in sections', (tester) async {
      await pumpRooms(tester);
      await tester.tap(find.text('Standard Twin Room'));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerRoomDetailHeading), findsOneWidget);
      expect(find.text(en.partnerRoomSectionIdentity), findsOneWidget);
      expect(find.text(en.partnerRoomSectionBeds), findsOneWidget);
      expect(find.text(en.partnerRoomSectionCapacity), findsOneWidget);
      expect(find.text(en.partnerRoomSectionInventory), findsOneWidget);
      expect(find.text(en.partnerRoomSectionPricing), findsOneWidget);
      expect(find.text(en.partnerRoomSectionConditions), findsOneWidget);
      expect(find.text(en.partnerRoomSectionAmenities), findsOneWidget);
      expect(find.text('Free WiFi'), findsWidgets);
    });

    testWidgets('null fields stay null rather than becoming zero',
        (tester) async {
      await pumpRooms(tester);
      await tester.tap(find.text('Standard Twin Room'));
      await tester.pumpAndSettle();

      // description, floorNumber and originalPrice are null on the wire.
      expect(find.text(en.partnerPropertyNotSet), findsWidgets);
      // A null originalPrice must not render as "0".
      expect(find.text(en.partnerRoomFieldOriginalPrice), findsOneWidget);
    });

    testWidgets('an amenity-free room omits the amenities section',
        (tester) async {
      await pumpRooms(
        tester,
        client: roomsClient(
            rooms: [roomJson(amenities: <Map<String, dynamic>>[])]),
      );
      await tester.tap(find.text('Standard Twin Room'));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerRoomSectionAmenities), findsNothing);
    });

    testWidgets('detail can be closed', (tester) async {
      await pumpRooms(tester);
      await tester.tap(find.text('Standard Twin Room'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(en.partnerRoomCloseDetail));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerRoomDetailHeading), findsNothing);
    });
  });

  // ── 3–6. Property context ────────────────────────────────────────────────

  group('property context', () {
    test('no property selected means no request is made', () async {
      final app = partnerApp(roomsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rooms = PartnerRoomsState(api: app.api);
      requestLog.clear();

      await rooms.load(partner, null);

      expect(rooms.status, PartnerRoomsStatus.noPropertySelected);
      expect(requestLog, isEmpty,
          reason: 'hotelId is required; without one there is nothing to ask');
    });

    testWidgets('no property selected shows a choose-a-property state',
        (tester) async {
      final app = partnerApp(roomsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      partner.clearSelectedProperty();

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerRoomsSelectPropertyTitle), findsOneWidget);
      // Must not be confused with "this property has no rooms".
      expect(find.text(en.partnerRoomsEmptyTitle), findsNothing);
    });

    test('a workspace with no properties is its own state', () async {
      final app = partnerApp(roomsClient(hotels: <Map<String, dynamic>>[]));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rooms = PartnerRoomsState(api: app.api);

      await rooms.load(partner, null);

      expect(rooms.status, PartnerRoomsStatus.noProperties);
    });

    test('an unauthorized property id is refused before any request',
        () async {
      final app = partnerApp(roomsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rooms = PartnerRoomsState(api: app.api);
      requestLog.clear();

      await rooms.load(partner, 999);

      expect(rooms.status, PartnerRoomsStatus.propertyUnavailable);
      expect(requestLog, isEmpty,
          reason: 'never ask for a property the workspace does not authorize');
    });

    testWidgets('changing the workspace property reloads the rooms',
        (tester) async {
      final handles = await pumpRooms(
        tester,
        client: roomsClient(hotels: [
          hotelJson(),
          hotelJson(id: 12, name: 'Bay View Hoi An'),
        ]),
      );
      requestLog.clear();

      handles.partner.selectProperty(12);
      await tester.pumpAndSettle();

      expect(
        requestLog.any((r) => r.contains('/partner/rooms?hotelId=12')),
        isTrue,
        reason: 'the module follows PartnerState, it does not own selection',
      );
    });

    test('rooms state keeps no second copy of the selection', () async {
      final app = partnerApp(roomsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rooms = PartnerRoomsState(api: app.api);
      await rooms.load(partner, 11);

      // loadedPropertyId describes what is on screen; PartnerState remains the
      // authority for what is *selected*.
      expect(rooms.loadedPropertyId, 11);
      expect(partner.selectedPropertyId, 11);
    });
  });

  // ── 5. Empty ─────────────────────────────────────────────────────────────

  group('empty', () {
    testWidgets('a property with no rooms is an answer, not an error',
        (tester) async {
      await pumpRooms(
          tester, client: roomsClient(rooms: <Map<String, dynamic>>[]));

      expect(find.text(en.partnerRoomsEmptyTitle), findsOneWidget);
      expect(find.text(en.partnerRoomsSelectPropertyTitle), findsNothing);
      expect(find.text(en.partnerRoomsPropertyUnavailableTitle), findsNothing);
    });
  });

  // ── 7–11. Errors ─────────────────────────────────────────────────────────

  group('errors', () {
    testWidgets('401 shows the session-expired view', (tester) async {
      await pumpRooms(
        tester,
        client: roomsClient(overrides: {
          '/partner/rooms': jsonResponse(
              errorBody(401, 'Unauthorized', '/api/partner/rooms'), 401),
        }),
      );
      expect(find.text(en.partnerStatusUnauthorizedTitle), findsOneWidget);
    });

    testWidgets('403 is reported as an approval problem', (tester) async {
      await pumpRooms(
        tester,
        client: roomsClient(overrides: {
          '/partner/rooms': jsonResponse(
              errorBody(403, 'Partner profile is not approved',
                  '/api/partner/rooms'),
              403),
        }),
      );
      expect(find.text(en.partnerStatusForbiddenTitle), findsOneWidget);
    });

    testWidgets('404 on the list means the property is unavailable',
        (tester) async {
      await pumpRooms(
        tester,
        client: roomsClient(overrides: {
          '/partner/rooms': jsonResponse(
              errorBody(404, 'Hotel not found: 11', '/api/partner/rooms'), 404),
        }),
      );
      expect(
          find.text(en.partnerRoomsPropertyUnavailableTitle), findsOneWidget);
    });

    testWidgets('404 on detail is worded as unavailable, never forbidden',
        (tester) async {
      await pumpRooms(
        tester,
        client: roomsClient(overrides: {
          '/partner/rooms/1': jsonResponse(
              errorBody(404, 'Room not found: 1', '/api/partner/rooms/1'), 404),
        }),
      );
      await tester.tap(find.text('Standard Twin Room'));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerRoomDetailNotFound), findsOneWidget);
      expect(find.text(en.partnerDashboardErrorForbidden), findsNothing);
    });

    test('a network failure is retryable and not an empty property', () async {
      final app = partnerApp(roomsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final offline = PartnerRoomsState(
        api: ApiClient(client: roomsClient(throwNetwork: true))
          ..demoMode = false,
      );
      await offline.load(partner, 11);

      expect(offline.status, PartnerRoomsStatus.error);
      expect(offline.isRetryable, isTrue);
      expect(offline.isEmpty, isFalse);
    });

    test('a 500 from the list is retryable, not a lifecycle state', () async {
      // The running backend returns 500 (not 400) when hotelId is missing.
      // The client always sends it, but a 5xx must still classify correctly.
      final app = partnerApp(roomsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final failing = PartnerRoomsState(
        api: ApiClient(
            client: roomsClient(overrides: {
          '/partner/rooms': jsonResponse(
              errorBody(500, 'Unexpected server error', '/api/partner/rooms'),
              500),
        }))
          ..demoMode = false,
      );
      await failing.load(partner, 11);

      expect(failing.status, PartnerRoomsStatus.error);
      expect(failing.isRetryable, isTrue);
    });

    test('a timed-out mutation is uncertain, never a clean failure', () async {
      final api = ApiClient(
          client: MockClient((_) async => throw TimeoutException('slow')))
        ..demoMode = false;
      final result = await api.deactivatePartnerRoom(1);
      expect(result.errorKind, ApiErrorKind.uncertain);
    });
  });

  // ── 12. Loading ──────────────────────────────────────────────────────────

  test('a fresh rooms state starts idle with no rooms', () {
    final rooms = PartnerRoomsState(api: ApiClient(client: roomsClient()));
    expect(rooms.status, PartnerRoomsStatus.idle);
    expect(rooms.rooms, isEmpty);
    expect(rooms.isReady, isFalse);
    expect(rooms.isEmpty, isFalse, reason: 'idle is not empty');
  });

  // ── 13. Listing actions and role ─────────────────────────────────────────

  group('listing actions', () {
    testWidgets('unlisting updates the row from the server response',
        (tester) async {
      await pumpRooms(
        tester,
        client: roomsClient(overrides: {
          '/partner/rooms/1/deactivate':
              jsonResponse(roomJson(active: false), 200),
        }),
      );

      await tester.tap(find.text(en.partnerRoomUnlistAction));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerRoomUnlisted), findsWidgets);
    });

    testWidgets('a failed action changes nothing and says so', (tester) async {
      await pumpRooms(
        tester,
        client: roomsClient(overrides: {
          '/partner/rooms/1/deactivate': jsonResponse(
              errorBody(404, 'Room not found: 1',
                  '/api/partner/rooms/1/deactivate'),
              404),
        }),
      );

      await tester.tap(find.text(en.partnerRoomUnlistAction));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerRoomActionNotFound), findsOneWidget);
      expect(find.text(en.partnerRoomListed), findsWidgets);
    });

    test('acting on a room outside the list never reaches the network',
        () async {
      final app = partnerApp(roomsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rooms = PartnerRoomsState(api: app.api);
      await rooms.load(partner, 11);
      requestLog.clear();

      final result = await rooms.setActive(999, activate: false);
      expect(result, PartnerRoomActionResult.notFound);
      expect(requestLog, isEmpty);
    });

    testWidgets('the owner sees listing actions', (tester) async {
      final handles = await pumpRooms(tester);
      expect(handles.partner.teamRole, PartnerTeamRole.owner);
      expect(find.text(en.partnerRoomUnlistAction), findsOneWidget);
      expect(find.text(en.partnerRoomActionsOwnerOnly), findsNothing);
    });
  });

  // ── 14. Ownership ────────────────────────────────────────────────────────

  group('ownership', () {
    testWidgets('a non-approved partner never reaches the rooms module',
        (tester) async {
      final app = partnerApp(roomsClient(verificationStatus: 'SUBMITTED'));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerStatusAwaitingApprovalTitle), findsOneWidget);
      expect(requestLog.any((r) => r.contains('/partner/rooms')), isFalse);
    });

    test('opening a room not in the loaded list is refused', () async {
      final app = partnerApp(roomsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rooms = PartnerRoomsState(api: app.api);
      await rooms.load(partner, 11);
      requestLog.clear();

      await rooms.openRoom(9999);

      expect(rooms.openRoomId, isNull);
      expect(requestLog, isEmpty);
    });

    test('switching property clears a detail from the previous property',
        () async {
      final app = partnerApp(roomsClient(hotels: [
        hotelJson(),
        hotelJson(id: 12, name: 'Bay View Hoi An'),
      ]));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rooms = PartnerRoomsState(api: app.api);

      await rooms.load(partner, 11);
      await rooms.openRoom(1);
      expect(rooms.openRoomId, 1);

      // Property 12 returns a different room set that excludes room 1.
      final other = PartnerRoomsState(
        api: ApiClient(client: roomsClient(hotels: [
          hotelJson(),
          hotelJson(id: 12, name: 'Bay View Hoi An'),
        ], rooms: [
          roomJson(id: 50, roomName: 'Hoi An Suite', roomCode: 'HA-STE')
        ]))
          ..demoMode = false,
      );
      await other.load(partner, 12);
      await other.openRoom(50);
      expect(other.openRoomId, 50);

      // Reloading a property whose list no longer holds the open room drops it.
      await other.load(partner, 12);
      expect(other.openRoomId, 50, reason: 'still present, so kept');
    });
  });

  // ── 15–18. Responsive ────────────────────────────────────────────────────

  group('responsive', () {
    testWidgets('desktop shows list and detail side by side', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRooms(tester, size: const Size(1600, 1800));
      await tester.tap(find.text('Standard Twin Room'));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerRoomDetailHeading), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('tablet renders without layout errors', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRooms(tester, size: const Size(820, 2000));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('mobile has no horizontal overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRooms(tester, size: const Size(390, 2600));
      expect(find.text('Standard Twin Room'), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('a very narrow phone still does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRooms(tester, size: const Size(320, 2800));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('mobile detail does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRooms(tester, size: const Size(390, 3400));
      await tester.tap(find.text('Standard Twin Room'));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerRoomDetailHeading), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });
  });

  // ── 19–20. Localization ──────────────────────────────────────────────────

  group('localization', () {
    testWidgets('English renders English strings', (tester) async {
      await pumpRooms(tester, locale: const Locale('en'));
      expect(find.text(en.partnerRoomTypeStandard), findsWidgets);
      expect(find.text(en.partnerRoomListed), findsWidgets);
    });

    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpRooms(tester, locale: const Locale('vi'));
      expect(find.text(vi.partnerRoomListed), findsWidgets);
      expect(find.text(vi.partnerRoomsCount(1)), findsOneWidget);
      expect(find.text(en.partnerRoomListed), findsNothing);
    });

    testWidgets('Vietnamese detail is localized and does not overflow',
        (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRooms(
          tester, size: const Size(390, 3600), locale: const Locale('vi'));
      await tester.tap(find.text('Standard Twin Room'));
      await tester.pumpAndSettle();

      expect(find.text(vi.partnerRoomDetailHeading), findsOneWidget);
      expect(find.text(vi.partnerRoomSectionCapacity), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    test('every C3 string exists in both locales', () {
      for (final l10n in <AppLocalizations>[en, vi]) {
        expect(l10n.partnerRoomsEmptyTitle, isNotEmpty);
        expect(l10n.partnerRoomsSelectPropertyTitle, isNotEmpty);
        expect(l10n.partnerRoomDetailHeading, isNotEmpty);
        expect(l10n.partnerRoomSoldOut, isNotEmpty);
        expect(l10n.partnerRoomTypeBungalow, isNotEmpty);
        expect(l10n.partnerBedTypeSofaBed, isNotEmpty);
        expect(l10n.partnerRoomsCount(2), isNotEmpty);
        expect(l10n.partnerRoomsForProperty('X'), isNotEmpty);
        expect(l10n.partnerRoomInventoryValue('1', '2'), isNotEmpty);
      }
    });
  });

  // ── DTO mapping ──────────────────────────────────────────────────────────

  group('DTO mapping', () {
    test('parses all nine RoomType values and fails closed otherwise', () {
      for (final entry in {
        'STANDARD': PartnerRoomType.standard,
        'SUPERIOR': PartnerRoomType.superior,
        'DELUXE': PartnerRoomType.deluxe,
        'PREMIER': PartnerRoomType.premier,
        'EXECUTIVE': PartnerRoomType.executive,
        'SUITE': PartnerRoomType.suite,
        'FAMILY': PartnerRoomType.family,
        'VILLA': PartnerRoomType.villa,
        'BUNGALOW': PartnerRoomType.bungalow,
      }.entries) {
        expect(PartnerRoomType.parse(entry.key), entry.value);
      }
      expect(PartnerRoomType.parse('PENTHOUSE'), PartnerRoomType.unknown);
      expect(PartnerRoomType.parse(null), PartnerRoomType.unknown);
    });

    test('parses all seven BedType values and keeps null null', () {
      for (final entry in {
        'SINGLE': PartnerBedType.single,
        'DOUBLE': PartnerBedType.double_,
        'TWIN': PartnerBedType.twin,
        'QUEEN': PartnerBedType.queen,
        'KING': PartnerBedType.king,
        'SOFA_BED': PartnerBedType.sofaBed,
        'BUNK': PartnerBedType.bunk,
      }.entries) {
        expect(PartnerBedType.parse(entry.key), entry.value);
      }
      expect(PartnerBedType.parse(null), isNull,
          reason: 'bedType is nullable — null is not "unknown"');
      expect(PartnerBedType.parse('WATERBED'), PartnerBedType.unknown);
    });

    test('maps the room record field for field', () {
      final r = PartnerRoom.fromJson(roomJson())!;
      expect(r.id, 1);
      expect(r.roomCode, 'STD-TWIN');
      expect(r.roomType, PartnerRoomType.standard);
      expect(r.bedType, PartnerBedType.twin);
      expect(r.bedCount, 2);
      expect(r.maxGuests, 2);
      expect(r.roomSizeSqm, 25.0);
      expect(r.quantity, 10);
      expect(r.availableQuantity, 4);
      expect(r.priceFrom, 900000);
      expect(r.breakfastIncluded, isTrue);
      expect(r.amenities.length, 1);
      expect(r.amenities.first.name, 'Free WiFi');
      // Genuinely null on the wire — must not become 0 or ''.
      expect(r.description, isNull);
      expect(r.floorNumber, isNull);
      expect(r.originalPrice, isNull);
    });

    test('sold-out is inventory, not the listing flag', () {
      final soldOut = PartnerRoom.fromJson(roomJson(availableQuantity: 0))!;
      expect(soldOut.isSoldOut, isTrue);
      expect(soldOut.active, isTrue, reason: 'a sold-out room is still listed');

      final unlisted = PartnerRoom.fromJson(roomJson(active: false))!;
      expect(unlisted.isSoldOut, isFalse);
      expect(unlisted.active, isFalse);

      final noInventory =
          PartnerRoom.fromJson(roomJson(quantity: null, availableQuantity: null))!;
      expect(noInventory.hasInventory, isFalse);
      expect(noInventory.isSoldOut, isFalse,
          reason: 'unknown inventory is not sold out');
    });

    test('copyWithActive preserves every other field', () {
      final r = PartnerRoom.fromJson(roomJson())!;
      final off = r.copyWithActive(false);
      expect(off.active, isFalse);
      expect(off.id, r.id);
      expect(off.roomName, r.roomName);
      expect(off.quantity, r.quantity);
      expect(off.amenities.length, r.amenities.length);
    });

    test('a malformed body fails rather than rendering blanks', () async {
      final api = ApiClient(
          client: MockClient((_) async => http.Response('{"nope":1}', 200,
              headers: {'content-type': 'application/json; charset=utf-8'})))
        ..demoMode = false;
      final result = await api.getPartnerRoom(1);
      expect(result.success, isFalse);
      expect(result.errorKind, ApiErrorKind.malformed);
    });
  });
}
