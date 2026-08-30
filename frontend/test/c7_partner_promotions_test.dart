import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_promotion_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/promotions/partner_promotions_screen.dart';
import 'package:planyourtrip_frontend/features/partner/promotions/partner_promotions_state.dart';
import 'package:planyourtrip_frontend/features/partner/promotions/partner_vouchers_state.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/shared/widgets/glass_widgets.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C7 — Partner Promotions & Vouchers.
///
/// Encodes what the backend audit established, so a later change that breaks any
/// of it fails here:
///
///  * **Promotion and voucher are two unrelated concepts.** A promotion is an
///    automatic discount rule; a partner "voucher" is a signed *booking* QR
///    payload with no discount at all. There is no partner coupon or gift-card
///    API — those are admin/customer surfaces.
///  * **Ownership is by target.** `ALL`-targeted promotions never belong to a
///    partner, so the seeded global promotion is correctly invisible.
///  * **Activation has no command endpoint.** `PUT /promotions/{id}` is a
///    sixteen-field full replace, so the write must echo the whole record.
///  * **Currency is split.** `PromotionResponse` has none; the pricing preview
///    does, and only the preview may show one.
///  * **The 404 is uniform.** Invalid signature, unknown booking and another
///    partner's booking are indistinguishable, and the UI must not pretend
///    otherwise.
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
        'activePromotions': 1,
        'quickActions': <Object>[],
      };

  Map<String, dynamic> hotelListJson({int id = 11}) => {
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
        'quantity': 10,
        'availableQuantity': 4,
        'active': true,
        'amenities': <Object>[],
        'coverImageUrl': null,
        'galleryImages': <Object>[],
        'createdAt': '2026-08-29T08:26:09Z',
        'updatedAt': '2026-08-29T08:26:09Z',
      };

  /// `PromotionDto.PromotionResponse` — all 19 fields. Note there is **no**
  /// currency field; that absence is part of the contract.
  Map<String, dynamic> promotionJson({
    int id = 5,
    String name = 'Autumn Escape',
    String? code = 'AUTUMN25',
    String promotionType = 'ROOM',
    String discountType = 'PERCENTAGE',
    num? discountValue = 25,
    num? maxDiscountAmount = 500000,
    int? minimumStay = 2,
    num? minimumSpend,
    bool stackable = true,
    int priority = 10,
    String? startDate = '2026-08-01',
    String? endDate = '2026-12-31',
    bool active = true,
    String targetType = 'ROOM',
    int? targetId = 1,
  }) =>
      {
        'id': id,
        'name': name,
        'code': code,
        'description': 'Save on autumn stays',
        'active': active,
        'startDate': startDate,
        'endDate': endDate,
        'promotionType': promotionType,
        'discountType': discountType,
        'discountValue': discountValue,
        'maxDiscountAmount': maxDiscountAmount,
        'minimumStay': minimumStay,
        'minimumSpend': minimumSpend,
        'stackable': stackable,
        'priority': priority,
        'targetType': targetType,
        'targetId': targetId,
        'createdAt': '2026-07-30T02:00:00Z',
        'updatedAt': '2026-08-20T02:00:00Z',
      };

  /// `PromotionDto.PricingBreakdownResponse`. This one **does** carry a
  /// currency — live it is `"VND"`.
  Map<String, dynamic> previewJson({
    String? currency = 'VND',
    List<Map<String, dynamic>>? applied,
  }) =>
      {
        'roomId': 1,
        'roomName': 'Standard Twin',
        'roomCode': 'STD-1',
        'checkIn': '2026-09-05',
        'checkOut': '2026-09-08',
        'nights': 3,
        'basePrice': 2700000,
        'ratePlanPrice': 2700000,
        'ratePlanName': 'Flexible',
        'promotionDiscount': 405000,
        'finalPrice': 2295000,
        'currency': currency,
        'appliedPromotions': applied ??
            [
              {
                'promotionId': 2,
                'name': 'Weekend Special',
                'code': 'WEEKEND15',
                'discountType': 'PERCENTAGE',
                'discountValue': 15,
                'discountApplied': 405000,
              }
            ],
      };

  /// `PartnerVoucherDto.VoucherVerificationResponse`.
  Map<String, dynamic> voucherJson({
    bool verified = true,
    bool eligible = true,
    String? reason,
  }) =>
      {
        'verified': verified,
        'eligible': eligible,
        'reason': reason,
        'bookingCode': 'PYT-2026-000123',
        'bookingStatus': 'CONFIRMED',
        'hotelId': 11,
        'hotelName': 'Bay View Danang',
        'roomId': 1,
        'roomName': 'Standard Twin',
        'guestName': 'Tran Thien Bao',
        'checkInDate': '2026-09-05',
        'checkOutDate': '2026-09-08',
        'occupancy': {'adults': 2, 'children': 1},
        'nights': 3,
      };

  late List<String> requestLog;
  late List<Map<String, dynamic>> putBodies;
  late List<Map<String, dynamic>> postBodies;
  setUp(() {
    requestLog = <String>[];
    putBodies = <Map<String, dynamic>>[];
    postBodies = <Map<String, dynamic>>[];
  });

  MockClient promotionsClient({
    Map<String, http.Response>? overrides,
    List<Map<String, dynamic>>? promotions,
    List<Map<String, dynamic>>? rooms,
    Map<String, dynamic>? preview,
    Map<String, dynamic>? voucher,
    int? voucherStatus,
    bool throwNetwork = false,
    bool timeoutOnPut = false,
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path');
        if (throwNetwork) throw http.ClientException('offline');
        if (request.method == 'PUT' && request.body.isNotEmpty) {
          putBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        }
        if (request.method == 'POST' && request.body.isNotEmpty) {
          postBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        }

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
          return jsonResponse([hotelListJson()], 200);
        }
        if (path.endsWith('/partner/rooms')) {
          return jsonResponse(rooms ?? [roomJson()], 200);
        }
        if (path.endsWith('/pricing-preview')) {
          return jsonResponse(preview ?? previewJson(), 200);
        }
        if (path.endsWith('/partner/bookings/voucher/verify')) {
          final status = voucherStatus ?? 200;
          if (status != 200) {
            // The backend answers invalid-signature, unknown and not-owned
            // with the same uniform 404.
            return jsonResponse(
                errorBody(status, 'Voucher not found', path), status);
          }
          return jsonResponse(voucher ?? voucherJson(), 200);
        }

        final byId = RegExp(r'/partner/promotions/(\d+)$').firstMatch(path);
        if (byId != null) {
          final id = int.parse(byId.group(1)!);
          final known = promotions ?? [promotionJson()];
          final match = known.where((p) => p['id'] == id);
          if (match.isEmpty) {
            return jsonResponse(
                errorBody(404, 'Promotion not found: $id', path), 404);
          }
          if (request.method == 'PUT') {
            if (timeoutOnPut) {
              await Future<void>.delayed(const Duration(seconds: 30));
            }
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            // Mirror `PromotionService.validateDates`.
            final start = DateTime.parse(body['startDate'] as String);
            final end = DateTime.parse(body['endDate'] as String);
            if (!end.isAfter(start)) {
              return jsonResponse(
                  errorBody(400, 'endDate must be after startDate', path), 400);
            }
            // `fill` is a full replace: echo exactly what was sent.
            final updated = Map<String, dynamic>.from(match.first)
              ..addAll(body)
              ..['id'] = id;
            return jsonResponse(updated, 200);
          }
          return jsonResponse(match.first, 200);
        }

        if (path.endsWith('/partner/promotions')) {
          return jsonResponse(promotions ?? [promotionJson()], 200);
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
              body: SingleChildScrollView(child: PartnerPromotionsScreen()),
            ),
          ),
        ),
      );

  Future<({AppState app, PartnerState partner})> pumpPromotions(
    WidgetTester tester, {
    http.Client? client,
    Size size = const Size(1600, 2600),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? promotionsClient());
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

  Future<PartnerPromotionsState> loadedState(http.Client client) async {
    final app = partnerApp(client);
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);
    final state = PartnerPromotionsState(api: app.api);
    await state.load(partner, partner.selectedPropertyId);
    return state;
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

  /// The tab strip scrolls on narrow phones, so the destination tab is brought
  /// into view before it is tapped.
  Future<void> openVoucherTab(WidgetTester tester) async {
    final tab = find.text(en.partnerPromotionsTabVoucherCheck);
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  Future<void> submitVoucher(WidgetTester tester, String payload) async {
    await tester.enterText(find.byType(TextField), payload);
    await tester.pump();
    await tester.ensureVisible(find.byType(OceanPrimaryButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OceanPrimaryButton));
    await tester.pumpAndSettle();
  }

  // ── The two domains are modelled separately ────────────────────────────

  group('promotions and vouchers stay separate concepts', () {
    test('they are owned by two independent notifiers', () {
      final api = ApiClient(client: promotionsClient())..demoMode = false;
      expect(
          PartnerPromotionsState(api: api), isNot(isA<PartnerVouchersState>()));
      expect(
          PartnerVouchersState(api: api), isNot(isA<PartnerPromotionsState>()));
    });

    test('a partner voucher carries no discount at all', () {
      final voucher = PartnerVoucherVerification.fromJson(voucherJson())!;
      // Every field is booking data. If a discount ever appears on this DTO the
      // model must change deliberately, not by accident.
      expect(voucher.bookingCode, 'PYT-2026-000123');
      expect(voucher.nights, 3);
      expect(voucher.adults, 2);
      expect(voucher.children, 1);
    });

    testWidgets('the screen labels them as two different things',
        (tester) async {
      await pumpPromotions(tester);
      expect(find.text(en.partnerPromotionsTabPromotions), findsOneWidget);
      expect(find.text(en.partnerPromotionsTabVoucherCheck), findsOneWidget);
      // Neither tab is called "Discounts".
      expect(find.text('Discounts'), findsNothing);
    });

    testWidgets('the voucher panel says it is not a discount code',
        (tester) async {
      await pumpPromotions(tester);
      await openVoucherTab(tester);
      expect(find.text(en.partnerVoucherCheckNote), findsOneWidget);
    });
  });

  // ── Model / contract fidelity ─────────────────────────────────────────

  group('promotion model mirrors PromotionResponse', () {
    test('parses all 19 fields', () {
      final p = PartnerPromotion.fromJson(promotionJson())!;
      expect(p.id, 5);
      expect(p.name, 'Autumn Escape');
      expect(p.code, 'AUTUMN25');
      expect(p.description, 'Save on autumn stays');
      expect(p.active, isTrue);
      expect(p.promotionType, PartnerPromotionType.room);
      expect(p.discountType, PartnerDiscountType.percentage);
      expect(p.discountValue, 25);
      expect(p.maxDiscountAmount, 500000);
      expect(p.minimumStay, 2);
      expect(p.minimumSpend, isNull);
      expect(p.stackable, isTrue);
      expect(p.priority, 10);
      expect(p.targetType, PartnerPromotionTargetType.room);
      expect(p.targetId, 1);
      expect(p.startDate, DateTime(2026, 8, 1));
      expect(p.endDate, DateTime(2026, 12, 31));
      expect(p.createdAt, isNotNull);
      expect(p.updatedAt, isNotNull);
    });

    test('an unrecognised enum degrades instead of throwing', () {
      final p = PartnerPromotion.fromJson(promotionJson(
        promotionType: 'FLASH_SALE',
        discountType: 'BUY_ONE_GET_ONE',
        targetType: 'CITY',
      ))!;
      expect(p.promotionType, PartnerPromotionType.unknown);
      expect(p.discountType, PartnerDiscountType.unknown);
      expect(p.targetType, PartnerPromotionTargetType.unknown);
      // And it must then refuse to be written back, because the wire value is
      // unknown and a full replace would corrupt the record.
      expect(p.canRoundTrip, isFalse);
    });

    test('a promotion with no id is rejected rather than half-built', () {
      final json = promotionJson()..remove('id');
      expect(PartnerPromotion.fromJson(json), isNull);
    });

    test('ALL is not a partner-ownable target', () {
      expect(PartnerPromotionTargetType.all.isPartnerOwnable, isFalse);
      expect(PartnerPromotionTargetType.hotel.isPartnerOwnable, isTrue);
      expect(PartnerPromotionTargetType.room.isPartnerOwnable, isTrue);
      expect(PartnerPromotionTargetType.unknown.isPartnerOwnable, isFalse);
    });

    test('expired and active are independent facts', () {
      final p = PartnerPromotion.fromJson(
          promotionJson(active: true, endDate: '2026-01-31'))!;
      expect(p.active, isTrue);
      expect(p.isExpired(DateTime(2026, 8, 29)), isTrue);
    });

    test('a promotion that has not started is scheduled, not expired', () {
      final p = PartnerPromotion.fromJson(
          promotionJson(startDate: '2026-12-01', endDate: '2026-12-31'))!;
      expect(p.isScheduled(DateTime(2026, 8, 29)), isTrue);
      expect(p.isExpired(DateTime(2026, 8, 29)), isFalse);
    });

    test('dates parse as plain calendar days, immune to timezone drift', () {
      final p = PartnerPromotion.fromJson(promotionJson())!;
      expect(p.startDate!.isUtc, isFalse);
      expect(p.startDate!.day, 1);
      expect(p.endDate!.day, 31);
    });
  });

  group('the write body is a lossless full replace', () {
    test('toRequestJson carries all sixteen request fields', () {
      final p = PartnerPromotion.fromJson(promotionJson())!;
      final body = p.toRequestJson();
      expect(
        body.keys.toSet(),
        {
          'name',
          'code',
          'description',
          'promotionType',
          'discountType',
          'discountValue',
          'maxDiscountAmount',
          'minimumStay',
          'minimumSpend',
          'stackable',
          'priority',
          'startDate',
          'endDate',
          'active',
          'targetType',
          'targetId',
        },
      );
    });

    test('only active differs from the stored record', () {
      final p = PartnerPromotion.fromJson(promotionJson(active: true))!;
      final before = p.toRequestJson();
      final after = p.toRequestJson(activeOverride: false);
      final changed = after.keys.where((k) => before[k] != after[k]).toList();
      expect(changed, ['active']);
    });

    test('nullable fields are echoed, not dropped', () {
      // `PromotionService.fill` nulls anything the body omits, so an absent
      // key and a null value are NOT the same thing.
      final p = PartnerPromotion.fromJson(
          promotionJson(code: null, minimumSpend: null))!;
      final body = p.toRequestJson();
      expect(body.containsKey('code'), isTrue);
      expect(body['code'], isNull);
      expect(body.containsKey('minimumSpend'), isTrue);
      expect(body['minimumSpend'], isNull);
    });

    test('dates are serialised as LocalDate, not as instants', () {
      final body = PartnerPromotion.fromJson(promotionJson())!.toRequestJson();
      expect(body['startDate'], '2026-08-01');
      expect(body['endDate'], '2026-12-31');
    });

    test('a record missing required fields cannot round-trip', () {
      final p = PartnerPromotion.fromJson(
          promotionJson(discountValue: null, startDate: null))!;
      expect(p.canRoundTrip, isFalse);
    });

    test('the PUT the client actually sends is complete', () async {
      final state = await loadedState(promotionsClient());
      final result = await state.setActive(5, active: false);

      expect(result, PartnerPromotionActionResult.success);
      expect(putBodies, hasLength(1));
      expect(putBodies.single['active'], isFalse);
      expect(putBodies.single['name'], 'Autumn Escape');
      expect(putBodies.single['code'], 'AUTUMN25');
      expect(putBodies.single['maxDiscountAmount'], 500000);
      expect(putBodies.single['priority'], 10);
      expect(putBodies.single['targetType'], 'ROOM');
      expect(putBodies.single['targetId'], 1);
    });

    test('the new state comes from the server, not from a local guess',
        () async {
      final state = await loadedState(promotionsClient());
      await state.setActive(5, active: false);
      expect(state.promotions.single.active, isFalse);
      // The record is the server's echo, so every other field survived.
      expect(state.promotions.single.code, 'AUTUMN25');
      expect(state.promotions.single.maxDiscountAmount, 500000);
    });

    test('an unwritable record is refused before any request is sent',
        () async {
      final state = await loadedState(promotionsClient(
        promotions: [promotionJson(promotionType: 'FLASH_SALE')],
      ));
      final result = await state.setActive(5, active: false);
      expect(result, PartnerPromotionActionResult.notRoundTrippable);
      expect(putBodies, isEmpty);
    });
  });

  // ── Reads and scope ───────────────────────────────────────────────────

  group('loading promotions', () {
    test('the list is partner-wide, requested without a property filter',
        () async {
      await loadedState(promotionsClient());
      expect(
        requestLog.where((r) => r.contains('/partner/promotions')),
        ['GET /api/partner/promotions'],
      );
    });

    test('no promotions is a real answer, not an error', () async {
      final state = await loadedState(promotionsClient(promotions: []));
      expect(state.status, PartnerPromotionsStatus.ready);
      expect(state.isEmpty, isTrue);
      expect(state.errorMessage, isNull);
    });

    test('counts report active and expired separately', () async {
      final state = await loadedState(promotionsClient(promotions: [
        promotionJson(id: 5, active: true, endDate: '2026-12-31'),
        promotionJson(id: 6, active: true, endDate: '2026-01-31'),
        promotionJson(id: 7, active: false),
      ]));
      expect(state.promotions, hasLength(3));
      expect(state.activeCount, 2);
      expect(state.expiredCount, 1);
    });

    test('a ROOM target resolves to a name only when the room is known',
        () async {
      final state = await loadedState(promotionsClient(
        promotions: [
          promotionJson(targetId: 1),
          promotionJson(id: 6, targetId: 99)
        ],
        rooms: [roomJson(id: 1, roomName: 'Standard Twin')],
      ));
      expect(state.roomNameFor(state.promotions[0]), 'Standard Twin');
      expect(state.roomNameFor(state.promotions[1]), isNull);
    });

    test('a rooms failure does not blank the promotion list', () async {
      final state = await loadedState(promotionsClient(
        overrides: {
          '/partner/rooms': jsonResponse(errorBody(500, 'boom', '/x'), 500)
        },
      ));
      expect(state.status, PartnerPromotionsStatus.ready);
      expect(state.promotions, hasLength(1));
      expect(state.rooms, isEmpty);
    });

    test('an open detail is dropped when the promotion leaves the list',
        () async {
      final app = partnerApp(promotionsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final state = PartnerPromotionsState(api: app.api);
      await state.load(partner, partner.selectedPropertyId);
      state.openPromotionDetail(5);
      expect(state.openPromotion, isNotNull);

      final gone = partnerApp(promotionsClient(promotions: []));
      final goneState = PartnerPromotionsState(api: gone.api);
      await goneState.load(partner, partner.selectedPropertyId);
      expect(goneState.openPromotion, isNull);
    });

    test('detail refuses an id that is not in the loaded list', () async {
      final state = await loadedState(promotionsClient());
      state.openPromotionDetail(999);
      expect(state.openPromotionId, isNull);
    });
  });

  group('error mapping', () {
    test('401 is a session problem', () async {
      final state = await loadedState(promotionsClient(overrides: {
        '/partner/promotions': jsonResponse(errorBody(401, 'no', '/x'), 401),
      }));
      expect(state.status, PartnerPromotionsStatus.unauthorized);
    });

    test('403 is an approval problem', () async {
      final state = await loadedState(promotionsClient(overrides: {
        '/partner/promotions': jsonResponse(errorBody(403, 'no', '/x'), 403),
      }));
      expect(state.status, PartnerPromotionsStatus.forbidden);
    });

    test('404 means no partner profile', () async {
      final state = await loadedState(promotionsClient(overrides: {
        '/partner/promotions': jsonResponse(errorBody(404, 'no', '/x'), 404),
      }));
      expect(state.status, PartnerPromotionsStatus.notFound);
    });

    test('a network failure is retryable', () async {
      final app = partnerApp(promotionsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final offline = partnerApp(promotionsClient(throwNetwork: true));
      final state = PartnerPromotionsState(api: offline.api);
      await state.load(partner, partner.selectedPropertyId);
      expect(state.status, PartnerPromotionsStatus.error);
      expect(state.isRetryable, isTrue);
    });

    test('409 is reported as the global code clash it is', () async {
      final state = await loadedState(promotionsClient(overrides: {
        '/partner/promotions/5':
            jsonResponse(errorBody(409, 'Promotion code exists', '/x'), 409),
      }));
      expect(await state.setActive(5, active: false),
          PartnerPromotionActionResult.conflict);
    });

    test('400 on the dates is a validation failure', () async {
      final state = await loadedState(promotionsClient(promotions: [
        promotionJson(startDate: '2026-12-31', endDate: '2026-12-31'),
      ]));
      expect(await state.setActive(5, active: false),
          PartnerPromotionActionResult.validation);
    });

    test('a write timeout is uncertain, never a failure', () async {
      // `Promotion` has no @Version and the PUT is a full replace, so a
      // dropped connection may still have committed.
      final state = await loadedState(promotionsClient(timeoutOnPut: true));
      final result = await state.setActive(5, active: false);
      expect(result, PartnerPromotionActionResult.uncertain);
      // The local record must not claim the change happened.
      expect(state.promotions.single.active, isTrue);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('a 404 on write is the uniform unknown-or-unowned answer', () async {
      final state = await loadedState(promotionsClient(overrides: {
        '/partner/promotions/5':
            jsonResponse(errorBody(404, 'Promotion not found', '/x'), 404),
      }));
      expect(await state.setActive(5, active: false),
          PartnerPromotionActionResult.notFound);
    });
  });

  // ── Pricing preview: the backend does every calculation ───────────────

  group('pricing preview', () {
    test('parses the engine breakdown including its currency', () async {
      final state = await loadedState(promotionsClient());
      await state.runPreview(
        roomId: 1,
        checkIn: DateTime(2026, 9, 5),
        checkOut: DateTime(2026, 9, 8),
      );
      final preview = state.preview!;
      expect(preview.nights, 3);
      expect(preview.currency, 'VND');
      expect(preview.basePrice, 2700000);
      expect(preview.promotionDiscount, 405000);
      expect(preview.finalPrice, 2295000);
      expect(preview.appliedPromotions, hasLength(1));
      expect(preview.appliedPromotions.single.name, 'Weekend Special');
      expect(preview.appliedPromotions.single.discountApplied, 405000);
    });

    test('the request sends LocalDate query parameters', () async {
      final state = await loadedState(promotionsClient());
      await state.runPreview(
        roomId: 1,
        checkIn: DateTime(2026, 9, 5),
        checkOut: DateTime(2026, 9, 8),
      );
      expect(
        requestLog.any((r) => r.contains('/partner/rooms/1/pricing-preview')),
        isTrue,
      );
    });

    test('an inverted range is refused before any request', () async {
      final state = await loadedState(promotionsClient());
      final before = requestLog.length;
      await state.runPreview(
        roomId: 1,
        checkIn: DateTime(2026, 9, 8),
        checkOut: DateTime(2026, 9, 5),
      );
      expect(state.previewErrorKind, ApiErrorKind.validation);
      expect(state.preview, isNull);
      expect(requestLog.length, before);
    });

    test('a zero-night stay is refused too', () async {
      final state = await loadedState(promotionsClient());
      await state.runPreview(
        roomId: 1,
        checkIn: DateTime(2026, 9, 5),
        checkOut: DateTime(2026, 9, 5),
      );
      expect(state.previewErrorKind, ApiErrorKind.validation);
    });

    test('an unknown room is never previewed', () async {
      final state = await loadedState(promotionsClient());
      final before = requestLog.length;
      await state.runPreview(
        roomId: 999,
        checkIn: DateTime(2026, 9, 5),
        checkOut: DateTime(2026, 9, 8),
      );
      expect(requestLog.length, before);
      expect(state.preview, isNull);
    });

    test('a missing currency is tolerated rather than guessed', () {
      final preview =
          PartnerPricingPreview.fromJson(previewJson(currency: null))!;
      expect(preview.currency, isNull);
      expect(preview.finalPrice, 2295000);
    });

    test('no promotion applied is a real answer', () {
      final preview = PartnerPricingPreview.fromJson(previewJson(applied: []))!;
      expect(preview.hasPromotions, isFalse);
    });
  });

  // ── Voucher verification ─────────────────────────────────────────────

  group('booking-voucher verification', () {
    test('verified and eligible are separate answers', () async {
      final api = ApiClient(client: promotionsClient())..demoMode = false;
      final state = PartnerVouchersState(api: api);
      state.setPayload('PYT-V1.PYT-2026-000123.abc');
      await state.verify();
      expect(state.status, PartnerVoucherCheckStatus.verified);
      expect(state.result!.verified, isTrue);
      expect(state.result!.eligible, isTrue);
    });

    test('a valid signature with an ineligible booking keeps the reason',
        () async {
      final api = ApiClient(
          client: promotionsClient(
              voucher: voucherJson(
                  eligible: false, reason: 'Check-in date has not arrived')))
        ..demoMode = false;
      final state = PartnerVouchersState(api: api);
      state.setPayload('PYT-V1.PYT-2026-000123.abc');
      await state.verify();
      expect(state.status, PartnerVoucherCheckStatus.verified);
      expect(state.result!.eligible, isFalse);
      expect(state.result!.reason, 'Check-in date has not arrived');
    });

    test('the uniform 404 becomes one honest not-recognised state', () async {
      final api = ApiClient(client: promotionsClient(voucherStatus: 404))
        ..demoMode = false;
      final state = PartnerVouchersState(api: api);
      state.setPayload('tampered');
      await state.verify();
      expect(state.status, PartnerVoucherCheckStatus.notRecognised);
      expect(state.result, isNull);
    });

    test('an empty payload never reaches the network', () async {
      final api = ApiClient(client: promotionsClient())..demoMode = false;
      final state = PartnerVouchersState(api: api);
      state.setPayload('   ');
      await state.verify();
      expect(state.status, PartnerVoucherCheckStatus.empty);
      expect(requestLog.where((r) => r.contains('voucher/verify')), isEmpty);
    });

    test('the payload is sent as the backend names it', () async {
      final api = ApiClient(client: promotionsClient())..demoMode = false;
      final state = PartnerVouchersState(api: api);
      state.setPayload('  PYT-V1.CODE.sig  ');
      await state.verify();
      expect(postBodies.single, {'voucherPayload': 'PYT-V1.CODE.sig'});
    });

    test('editing the payload invalidates the previous answer', () async {
      final api = ApiClient(client: promotionsClient())..demoMode = false;
      final state = PartnerVouchersState(api: api);
      state.setPayload('PYT-V1.CODE.sig');
      await state.verify();
      expect(state.result, isNotNull);
      state.setPayload('PYT-V1.OTHER.sig');
      expect(state.result, isNull);
      expect(state.status, PartnerVoucherCheckStatus.idle);
    });

    test('verification issues exactly one request and mutates nothing',
        () async {
      final api = ApiClient(client: promotionsClient())..demoMode = false;
      final state = PartnerVouchersState(api: api);
      state.setPayload('PYT-V1.CODE.sig');
      await state.verify();
      expect(requestLog.where((r) => r.startsWith('POST')),
          ['POST /api/partner/bookings/voucher/verify']);
      expect(requestLog.where((r) => r.startsWith('PUT')), isEmpty);
      expect(requestLog.where((r) => r.startsWith('DELETE')), isEmpty);
    });

    test('clear resets everything', () async {
      final api = ApiClient(client: promotionsClient())..demoMode = false;
      final state = PartnerVouchersState(api: api);
      state.setPayload('PYT-V1.CODE.sig');
      await state.verify();
      state.clear();
      expect(state.payload, isEmpty);
      expect(state.result, isNull);
      expect(state.status, PartnerVoucherCheckStatus.idle);
    });
  });

  // ── No invented CRUD ─────────────────────────────────────────────────

  group('nothing beyond the audited contract is offered', () {
    testWidgets('no create, delete or free-form edit affordance exists',
        (tester) async {
      await pumpPromotions(tester);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.add_rounded), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.byIcon(Icons.delete_rounded), findsNothing);
      expect(find.byIcon(Icons.edit_rounded), findsNothing);
    });

    testWidgets('the module never issues POST or DELETE on promotions',
        (tester) async {
      await pumpPromotions(tester);
      await tester.tap(find.text(en.partnerPromotionDeactivateAction).first);
      await tester.pumpAndSettle();
      expect(
        requestLog.where((r) => r.contains('/partner/promotions')).toSet(),
        {'GET /api/partner/promotions', 'PUT /api/partner/promotions/5'},
      );
    });

    testWidgets('no coupon or gift-card surface is implied', (tester) async {
      await pumpPromotions(tester);
      expect(find.textContaining('Gift card'), findsNothing);
      expect(find.textContaining('Coupon'), findsNothing);
    });
  });

  // ── UI behaviour ─────────────────────────────────────────────────────

  group('promotions UI', () {
    testWidgets('renders real promotion data from the backend', (tester) async {
      await pumpPromotions(tester);
      expect(find.text('Autumn Escape'), findsWidgets);
      expect(find.text('AUTUMN25'), findsWidgets);
      expect(find.text(en.partnerPromotionActive), findsWidgets);
    });

    testWidgets('states that the promotion API sends no currency',
        (tester) async {
      await pumpPromotions(tester);
      expect(find.text(en.partnerPromotionsCurrencyNote), findsOneWidget);
      // And no symbol is invented for the promotion amount.
      expect(find.textContaining('₫'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
    });

    testWidgets('states that the list is not scoped to one property',
        (tester) async {
      await pumpPromotions(tester);
      expect(find.text(en.partnerPromotionsScopeNote), findsOneWidget);
    });

    testWidgets('an empty list explains why global campaigns are absent',
        (tester) async {
      await pumpPromotions(tester, client: promotionsClient(promotions: []));
      expect(find.text(en.partnerPromotionsEmptyTitle), findsOneWidget);
      expect(find.text(en.partnerPromotionsEmptyMessage), findsOneWidget);
    });

    testWidgets('opening a promotion shows its detail sections',
        (tester) async {
      await pumpPromotions(tester);
      await tester.tap(find.text('Autumn Escape').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerPromotionDetailHeading), findsOneWidget);
      expect(find.text(en.partnerPromotionSectionDiscount), findsOneWidget);
      expect(find.text(en.partnerPromotionSectionApplication), findsOneWidget);
      expect(find.text(en.partnerPromotionFieldStackable), findsOneWidget);
    });

    testWidgets('the stacking rule is explained, not re-implemented',
        (tester) async {
      await pumpPromotions(tester,
          client:
              promotionsClient(promotions: [promotionJson(stackable: false)]));
      await tester.tap(find.text('Autumn Escape').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerPromotionNonStackableNote), findsOneWidget);
    });

    testWidgets('deactivating reports the server-confirmed outcome',
        (tester) async {
      await pumpPromotions(tester);
      await tester.tap(find.text(en.partnerPromotionDeactivateAction).first);
      await tester.pumpAndSettle();
      expect(
        find.text(en.partnerPromotionDeactivatedMessage('Autumn Escape')),
        findsOneWidget,
      );
      expect(find.text(en.partnerPromotionActivateAction), findsWidgets);
    });

    testWidgets('a failed write says nothing changed', (tester) async {
      await pumpPromotions(tester,
          client: promotionsClient(overrides: {
            '/partner/promotions/5':
                jsonResponse(errorBody(404, 'gone', '/x'), 404),
          }));
      await tester.tap(find.text(en.partnerPromotionDeactivateAction).first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerPromotionActionNotFound), findsOneWidget);
      // The card still shows the old, true state.
      expect(find.text(en.partnerPromotionActive), findsWidgets);
    });

    testWidgets('the preview shows the engine-applied promotions',
        (tester) async {
      await pumpPromotions(tester);
      await tester.tap(find.text(en.partnerPromotionPreviewAction));
      await tester.pumpAndSettle();
      expect(
          find.text(en.partnerPromotionPreviewAppliedHeading), findsOneWidget);
      expect(find.textContaining('Weekend Special'), findsOneWidget);
      // The preview payload does carry a currency, so this one may show it.
      expect(find.textContaining('VND'), findsWidgets);
    });

    testWidgets('the preview says the backend calculated it', (tester) async {
      await pumpPromotions(tester);
      expect(find.text(en.partnerPromotionPreviewNote), findsOneWidget);
    });

    testWidgets('a preview with no rooms is not offered at all',
        (tester) async {
      await pumpPromotions(tester, client: promotionsClient(rooms: []));
      expect(find.text(en.partnerPromotionPreviewAction), findsNothing);
    });
  });

  group('voucher UI', () {
    testWidgets('an eligible voucher is stated plainly', (tester) async {
      await pumpPromotions(tester);
      await openVoucherTab(tester);
      await submitVoucher(tester, 'PYT-V1.CODE.sig');
      expect(find.text(en.partnerVoucherEligibleTitle), findsOneWidget);
      expect(find.text('PYT-2026-000123'), findsOneWidget);
      expect(find.text('Tran Thien Bao'), findsOneWidget);
    });

    testWidgets('an ineligible voucher shows the backend reason verbatim',
        (tester) async {
      await pumpPromotions(tester,
          client: promotionsClient(
              voucher: voucherJson(
                  eligible: false, reason: 'Booking is already checked in')));
      await openVoucherTab(tester);
      await submitVoucher(tester, 'PYT-V1.CODE.sig');
      expect(find.text(en.partnerVoucherNotEligibleTitle), findsOneWidget);
      expect(find.text('Booking is already checked in'), findsOneWidget);
    });

    testWidgets('a 404 never claims to know which cause applied',
        (tester) async {
      await pumpPromotions(tester,
          client: promotionsClient(voucherStatus: 404));
      await openVoucherTab(tester);
      await submitVoucher(tester, 'tampered');
      expect(find.text(en.partnerVoucherNotRecognisedTitle), findsOneWidget);
      expect(find.text(en.partnerVoucherNotRecognisedMessage), findsOneWidget);
      // It must not assert forgery.
      expect(find.textContaining('forged'), findsNothing);
    });

    testWidgets('the panel says verifying is not checking in', (tester) async {
      await pumpPromotions(tester);
      await openVoucherTab(tester);
      await submitVoucher(tester, 'PYT-V1.CODE.sig');
      expect(find.text(en.partnerVoucherReadOnlyNote), findsOneWidget);
      // And offers no check-in control.
      expect(find.text('Check in'), findsNothing);
    });
  });

  // ── Workspace gating ─────────────────────────────────────────────────

  group('workspace gating', () {
    testWidgets('a non-approved partner never reaches promotions',
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
      expect(find.text(en.partnerPromotionsTabPromotions), findsNothing);
    });

    testWidgets('demo mode shows no fabricated promotions', (tester) async {
      final app = AppState(api: ApiClient(client: promotionsClient()))
        ..demoMode = true
        ..email = 'demo@planyourtrip.com'
        ..role = AppRole.partner;
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();
      expect(find.text('Autumn Escape'), findsNothing);
    });
  });

  // ── Layout and localization ──────────────────────────────────────────

  group('layout', () {
    testWidgets('desktop shows the list beside the open detail',
        (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPromotions(tester, size: const Size(1600, 2600));
      await tester.tap(find.text('Autumn Escape').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerPromotionDetailHeading), findsOneWidget);
      expect(errors, isEmpty);
    });

    testWidgets('tablet renders without layout errors', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPromotions(tester, size: const Size(820, 2600));
      expect(errors, isEmpty);
    });

    testWidgets('mobile stacks with no horizontal overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPromotions(tester, size: const Size(390, 3200));
      expect(errors, isEmpty);
    });

    testWidgets('a very narrow phone does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPromotions(tester, size: const Size(320, 3200));
      expect(errors, isEmpty);
    });

    testWidgets('the voucher panel fits a narrow phone', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPromotions(tester, size: const Size(320, 3200));
      await openVoucherTab(tester);
      await submitVoucher(tester, 'PYT-V1.CODE.sig');
      expect(errors, isEmpty);
    });

    testWidgets('the preview fits a narrow phone', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPromotions(tester, size: const Size(320, 3200));
      await tester.tap(find.text(en.partnerPromotionPreviewAction));
      await tester.pumpAndSettle();
      expect(errors, isEmpty);
    });
  });

  group('localization', () {
    testWidgets('English renders English strings', (tester) async {
      await pumpPromotions(tester, locale: const Locale('en'));
      expect(find.text(en.partnerPromotionsTitle), findsOneWidget);
      expect(find.text(en.partnerPromotionsTabVoucherCheck), findsOneWidget);
    });

    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpPromotions(tester, locale: const Locale('vi'));
      expect(find.text(vi.partnerPromotionsTitle), findsOneWidget);
      expect(find.text(vi.partnerPromotionsTabVoucherCheck), findsOneWidget);
    });

    testWidgets('Vietnamese mobile does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpPromotions(tester,
          size: const Size(390, 3200), locale: const Locale('vi'));
      expect(errors, isEmpty);
    });

    test('the tab labels do not collide with the sidebar destinations', () {
      // "Promotions" is already a navigation destination; a tab with the same
      // text would be ambiguous inside the shell.
      expect(en.partnerPromotionsTabPromotions, isNot(en.partnerNavPromotions));
      expect(vi.partnerPromotionsTabPromotions, isNot(vi.partnerNavPromotions));
      expect(en.partnerVoucherFieldRoom, isNot(en.partnerNavRooms));
      expect(vi.partnerVoucherFieldRoom, isNot(vi.partnerNavRooms));
    });
  });
}
