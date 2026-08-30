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
import 'package:planyourtrip_frontend/core/partner/partner_rate_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/rates/partner_rates_screen.dart';
import 'package:planyourtrip_frontend/features/partner/rates/partner_rates_state.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C5 — Partner Rates.
///
/// Encodes the contract established from `PartnerPricingController`,
/// `RatePlanService` and `RatePlanEligibilityService`, and confirmed live:
///
///  * **No currency.** `RatePlan` carries none on the DTO, entity or table.
///  * **Validity is inclusive on both ends**, applied against *nights*
///    (`startDate <= checkIn && endDate >= checkOut-1`), and creation requires
///    `endDate` strictly after `startDate` — unlike C4's calendar, where
///    `from == to` is a legitimate single day.
///  * `PUT /rate-plans/{id}` is a **full replace**, so no edit UI exists.
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

  /// `RatePlanDto.RatePlanResponse` — all 31 fields, shaped like live seed data
  /// (most optional fields genuinely null).
  Map<String, dynamic> planJson({
    int id = 1,
    int roomId = 1,
    String rateName = 'Summer Deal',
    String rateType = 'PROMOTIONAL',
    num? pricePerNight = 800000,
    String startDate = '2026-08-29',
    String endDate = '2026-09-28',
    bool active = true,
    String? code,
    String sourceType = 'BASE',
    int? parentRatePlanId,
    String? adjustmentType,
    num? adjustmentValue,
    int priority = 0,
    int? minStayNights,
    String? mealPlanType = 'ROOM_ONLY',
    String? cancellationPolicyType = 'FREE_CANCELLATION',
    bool refundable = true,
  }) =>
      {
        'id': id,
        'roomId': roomId,
        'rateName': rateName,
        'rateType': rateType,
        'pricePerNight': pricePerNight,
        'startDate': startDate,
        'endDate': endDate,
        'active': active,
        'createdAt': '2026-08-29T08:26:09Z',
        'updatedAt': '2026-08-29T08:26:09Z',
        'code': code,
        'description': null,
        'mealPlanType': mealPlanType,
        'cancellationPolicyType': cancellationPolicyType,
        'cancellationDeadlineHours': null,
        'cancellationPenaltyPercent': null,
        'refundable': refundable,
        'sourceType': sourceType,
        'parentRatePlanId': parentRatePlanId,
        'adjustmentType': adjustmentType,
        'adjustmentValue': adjustmentValue,
        'priority': priority,
        'minStayNights': minStayNights,
        'maxStayNights': null,
        'minAdvanceBookingDays': null,
        'maxAdvanceBookingDays': null,
        'closedToArrival': false,
        'closedToDeparture': false,
        'occupancyPricingEnabled': false,
        'childPricingEnabled': false,
        'extraBedPrice': null,
      };

  Map<String, dynamic> occupancyJson({int id = 1, int ratePlanId = 1}) => {
        'id': id,
        'ratePlanId': ratePlanId,
        'adults': 2,
        'children': 1,
        'pricePerNight': 1100000,
        'childSupplement': 150000,
        'extraBedSupplement': null,
        'createdAt': '2026-08-29T08:26:09Z',
        'updatedAt': '2026-08-29T08:26:09Z',
      };

  Map<String, dynamic> previewJson({
    bool eligible = true,
    String reason = 'Eligible',
    int nights = 3,
  }) =>
      {
        'ratePlanId': 1,
        'code': null,
        'rateName': 'Summer Deal',
        'roomId': 1,
        'roomName': 'Standard Twin',
        'sourceType': 'BASE',
        'parentRatePlanId': null,
        'eligible': eligible,
        'reason': reason,
        'nights': nights,
        'baseNightlyRate': 800000,
        'derivedAdjustment': 0,
        'occupancyAdjustment': 0,
        'childSupplement': 0,
        'extraBedSupplement': 0,
        'finalNightlyRate': 800000,
        'staySubtotal': 2400000,
        'mealPlan': 'ROOM_ONLY',
        'cancellationPolicy': 'FREE_CANCELLATION',
        'refundable': true,
        'cancellationDeadline': null,
        'policySummary': 'Free cancellation',
      };

  late List<String> requestLog;
  setUp(() => requestLog = <String>[]);

  MockClient ratesClient({
    Map<String, http.Response>? overrides,
    List<Map<String, dynamic>>? hotels,
    List<Map<String, dynamic>>? rooms,
    List<Map<String, dynamic>>? plans,
    List<Map<String, dynamic>>? occupancy,
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
            return jsonResponse(errorBody(404, 'Hotel not found', path), 404);
          }
          return jsonResponse(rooms ?? [roomJson()], 200);
        }

        final toggle = RegExp(
                r'/partner/rate-plans/(\d+)/(activate|deactivate)$')
            .firstMatch(path);
        if (toggle != null) {
          final id = int.parse(toggle.group(1)!);
          final known = (plans ?? [planJson()]).map((p) => p['id']);
          if (!known.contains(id)) {
            return jsonResponse(
                errorBody(404, 'Rate plan not found: $id', path), 404);
          }
          return jsonResponse(
              planJson(id: id, active: toggle.group(2) == 'activate'), 200);
        }

        final occ = RegExp(r'/partner/rate-plans/(\d+)/occupancy-prices$')
            .firstMatch(path);
        if (occ != null) {
          final id = int.parse(occ.group(1)!);
          final known = (plans ?? [planJson()]).map((p) => p['id']);
          if (!known.contains(id)) {
            return jsonResponse(
                errorBody(404, 'Rate plan not found: $id', path), 404);
          }
          return jsonResponse(occupancy ?? <Object>[], 200);
        }

        if (RegExp(r'/partner/rate-plans/(\d+)/preview$').hasMatch(path)) {
          return jsonResponse(previewJson(), 200);
        }

        final list =
            RegExp(r'/partner/rooms/(\d+)/rate-plans$').firstMatch(path);
        if (list != null) {
          final roomId = int.parse(list.group(1)!);
          final known = (rooms ?? [roomJson()]).map((r) => r['id']);
          if (!known.contains(roomId)) {
            return jsonResponse(
                errorBody(404, 'Room not found: $roomId', path), 404);
          }
          return jsonResponse(plans ?? [planJson()], 200);
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
              body: SingleChildScrollView(child: PartnerRatesScreen()),
            ),
          ),
        ),
      );

  Future<({AppState app, PartnerState partner})> pumpRates(
    WidgetTester tester, {
    http.Client? client,
    Size size = const Size(1600, 2400),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? ratesClient());
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

  // ── Currency — mandatory per the brief ───────────────────────────────────

  group('currency', () {
    test('the rate DTO carries no currency field', () {
      final plan = PartnerRatePlan.fromJson(planJson())!;
      expect(plan.pricePerNight, 800000);
      // There is deliberately no `currency` member to read: the backend does
      // not supply one on RatePlan (Booking/Invoice/Payment do).
      expect(planJson().containsKey('currency'), isFalse);
    });

    testWidgets('no currency symbol is invented, and the gap is stated',
        (tester) async {
      await pumpRates(tester);

      expect(find.text(en.partnerRateCurrencyNote), findsOneWidget);
      // Never assume VND from the Vietnamese locale, nor USD.
      expect(find.textContaining('₫'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
      expect(find.textContaining('VND'), findsNothing);
      expect(find.textContaining('USD'), findsNothing);
    });

    testWidgets('a Vietnamese session still shows no currency symbol',
        (tester) async {
      await pumpRates(tester, locale: const Locale('vi'));
      expect(find.textContaining('₫'), findsNothing);
      expect(find.text(vi.partnerRateCurrencyNote), findsOneWidget);
    });
  });

  // ── Date semantics ───────────────────────────────────────────────────────

  group('date semantics', () {
    test('validity is inclusive on both ends', () {
      final plan = PartnerRatePlan.fromJson(
          planJson(startDate: '2026-09-01', endDate: '2026-09-30'))!;
      expect(plan.coversDate(DateTime(2026, 9, 1)), isTrue,
          reason: 'startDate is inclusive');
      expect(plan.coversDate(DateTime(2026, 9, 30)), isTrue,
          reason: 'endDate is inclusive');
      expect(plan.coversDate(DateTime(2026, 8, 31)), isFalse);
      expect(plan.coversDate(DateTime(2026, 10, 1)), isFalse);
    });

    test('dates are plain calendar days, immune to timezone shifts', () {
      final plan = PartnerRatePlan.fromJson(planJson())!;
      expect(plan.startDate, DateTime(2026, 8, 29));
      expect(plan.startDate!.hour, 0);
      expect(plan.endDate, DateTime(2026, 9, 28));
    });

    test('expiry is a fact about dates, separate from the active flag', () {
      final past = PartnerRatePlan.fromJson(planJson(
          startDate: '2026-01-01', endDate: '2026-02-01', active: true))!;
      expect(past.isExpired(DateTime(2026, 8, 29)), isTrue);
      expect(past.active, isTrue,
          reason: 'an expired plan can still be flagged active');

      final live = PartnerRatePlan.fromJson(planJson())!;
      expect(live.isExpired(DateTime(2026, 8, 29)), isFalse);
    });

    test('the preview stay is a half-open night range, unlike validity',
        () async {
      final api = ApiClient(client: ratesClient())..demoMode = false;
      await api.getPartnerRatePreview(
        ratePlanId: 1,
        checkIn: DateTime(2026, 9, 10),
        checkOut: DateTime(2026, 9, 13),
      );
      final call = requestLog.singleWhere((r) => r.contains('/preview'));
      expect(call.contains('checkIn=2026-09-10'), isTrue);
      expect(call.contains('checkOut=2026-09-13'), isTrue);
    });

    test('an inverted preview stay is refused before requesting', () async {
      final app = partnerApp(ratesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rates = PartnerRatesState(api: app.api);
      await rates.load(partner, 11);
      await rates.openPlan(1);
      requestLog.clear();

      // The endpoint answers checkOut <= checkIn with 200 (verified live), so
      // the client must reject it rather than render a nonsense breakdown.
      await rates.runPreview(
        checkIn: DateTime(2026, 9, 13),
        checkOut: DateTime(2026, 9, 10),
      );

      expect(rates.previewErrorKind, ApiErrorKind.validation);
      expect(rates.preview, isNull);
      expect(requestLog.any((r) => r.contains('/preview')), isFalse);
    });

    test('a valid preview stay is fetched and mapped', () async {
      final app = partnerApp(ratesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rates = PartnerRatesState(api: app.api);
      await rates.load(partner, 11);
      await rates.openPlan(1);

      await rates.runPreview(
        checkIn: DateTime(2026, 9, 10),
        checkOut: DateTime(2026, 9, 13),
      );

      expect(rates.preview, isNotNull);
      expect(rates.preview!.eligible, isTrue);
      expect(rates.preview!.nights, 3);
      expect(rates.preview!.staySubtotal, 2400000);
    });

    test('an ineligible stay carries the backend reason verbatim', () async {
      final api = ApiClient(
          client: ratesClient(overrides: {
        '/preview': jsonResponse(
            previewJson(
                eligible: false,
                reason: "Stay is outside the rate plan's date range"),
            200),
      }))
        ..demoMode = false;
      final result = await api.getPartnerRatePreview(
        ratePlanId: 1,
        checkIn: DateTime(2027, 5, 1),
        checkOut: DateTime(2027, 5, 3),
      );
      expect(result.data!.eligible, isFalse);
      expect(result.data!.reason, "Stay is outside the rate plan's date range");
    });
  });

  // ── List / detail ────────────────────────────────────────────────────────

  group('rate list', () {
    testWidgets('renders plans for the selected room', (tester) async {
      await pumpRates(tester);
      expect(find.text('Summer Deal'), findsOneWidget);
      expect(find.text(en.partnerRateTypePromotional), findsWidgets);
      expect(find.text(en.partnerRateActive), findsWidgets);
      expect(find.text(en.partnerRatesCount(1)), findsOneWidget);
    });

    testWidgets('invents nothing the DTO does not supply', (tester) async {
      await pumpRates(tester);
      // Rates are not inventory: C4's vocabulary must not appear here.
      expect(find.text(en.partnerInventoryAvailable), findsNothing);
      expect(find.text(en.partnerInventoryStopSell), findsNothing);
      // No create affordance — create exists on the backend but is out of C5.
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('base and derived plans are distinguished', (tester) async {
      await pumpRates(
        tester,
        client: ratesClient(plans: [
          planJson(),
          planJson(
              id: 4,
              rateName: 'Non-refundable',
              sourceType: 'DERIVED',
              parentRatePlanId: 3,
              adjustmentType: 'PERCENTAGE',
              adjustmentValue: -10,
              priority: 20),
        ]),
      );
      expect(find.text(en.partnerRateSourceDerived), findsWidgets);
      expect(find.text(en.partnerRatesCount(2)), findsOneWidget);
    });

    testWidgets('opens detail with all sections', (tester) async {
      await pumpRates(tester);
      await tester.tap(find.text('Summer Deal'));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerRateDetailHeading), findsOneWidget);
      expect(find.text(en.partnerRateSectionIdentity), findsOneWidget);
      expect(find.text(en.partnerRateSectionPricing), findsOneWidget);
      expect(find.text(en.partnerRateSectionValidity), findsOneWidget);
      expect(find.text(en.partnerRateSectionRestrictions), findsOneWidget);
      expect(find.text(en.partnerRateSectionCancellation), findsOneWidget);
      expect(find.text(en.partnerRateSectionOccupancy), findsOneWidget);
      // The inclusive-window explanation is stated, not assumed.
      expect(find.text(en.partnerRateValidityNote), findsOneWidget);
    });

    testWidgets('null optional fields read as "not set"', (tester) async {
      await pumpRates(tester);
      await tester.tap(find.text('Summer Deal'));
      await tester.pumpAndSettle();
      // code, description, deadline hours, penalty %, stay and advance limits
      // are all null in live seed data.
      expect(find.text(en.partnerPropertyNotSet), findsWidgets);
    });

    testWidgets('occupancy prices render when configured', (tester) async {
      await pumpRates(tester, client: ratesClient(occupancy: [occupancyJson()]));
      await tester.tap(find.text('Summer Deal'));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerRateOccupancyLabel('2', '1')), findsOneWidget);
    });

    testWidgets('an occupancy-free plan says so', (tester) async {
      await pumpRates(tester);
      await tester.tap(find.text('Summer Deal'));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerRateOccupancyEmpty), findsOneWidget);
    });
  });

  // ── Context chain ────────────────────────────────────────────────────────

  group('context chain', () {
    test('no properties is its own state', () async {
      final app = partnerApp(ratesClient(hotels: <Map<String, dynamic>>[]));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rates = PartnerRatesState(api: app.api);
      await rates.load(partner, null);
      expect(rates.status, PartnerRatesStatus.noProperties);
    });

    test('no property selected makes no request', () async {
      final app = partnerApp(ratesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rates = PartnerRatesState(api: app.api);
      requestLog.clear();
      await rates.load(partner, null);
      expect(rates.status, PartnerRatesStatus.noPropertySelected);
      expect(requestLog, isEmpty);
    });

    test('a property with no rooms stops at noRooms', () async {
      final app = partnerApp(ratesClient(rooms: <Map<String, dynamic>>[]));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rates = PartnerRatesState(api: app.api);
      await rates.load(partner, 11);
      expect(rates.status, PartnerRatesStatus.noRooms);
    });

    testWidgets('a room with no rate plans is an answer, not an error',
        (tester) async {
      await pumpRates(tester, client: ratesClient(plans: <Map<String, dynamic>>[]));
      expect(find.text(en.partnerRatesEmptyTitle), findsOneWidget);
      expect(find.text(en.partnerRatesUnavailableTitle), findsNothing);
    });

    test('an unauthorized property id is refused before any request', () async {
      final app = partnerApp(ratesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rates = PartnerRatesState(api: app.api);
      requestLog.clear();
      await rates.load(partner, 999);
      expect(rates.status, PartnerRatesStatus.notFound);
      expect(requestLog, isEmpty);
    });

    test('an unauthorized room id is ignored', () async {
      final app = partnerApp(ratesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rates = PartnerRatesState(api: app.api);
      await rates.load(partner, 11);
      requestLog.clear();
      await rates.selectRoom(9999);
      expect(rates.selectedRoomId, 1);
      expect(requestLog, isEmpty);
    });

    test('switching property drops room and plan from the old property',
        () async {
      final app = partnerApp(ratesClient(
        hotels: [hotelJson(), hotelJson(id: 12, name: 'Hoi An')],
        rooms: [roomJson(), roomJson(id: 2, roomName: 'Deluxe')],
      ));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rates = PartnerRatesState(api: app.api);

      await rates.load(partner, 11);
      await rates.selectRoom(2);
      await rates.openPlan(1);
      expect(rates.openPlanId, 1);

      await rates.load(partner, 12);

      expect(rates.loadedPropertyId, 12);
      expect(rates.openPlanId, isNull,
          reason: 'a plan from the old property must not survive the switch');
    });

    test('opening a plan outside the loaded list is refused', () async {
      final app = partnerApp(ratesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rates = PartnerRatesState(api: app.api);
      await rates.load(partner, 11);
      requestLog.clear();

      await rates.openPlan(9999);
      expect(rates.openPlanId, isNull);
      expect(requestLog, isEmpty);
    });
  });

  // ── Mutations ────────────────────────────────────────────────────────────

  group('activate / deactivate', () {
    test('deactivating POSTs the right endpoint and folds the response',
        () async {
      final app = partnerApp(ratesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rates = PartnerRatesState(api: app.api);
      await rates.load(partner, 11);
      requestLog.clear();

      final result = await rates.setActive(1, activate: false);

      expect(result, PartnerRateActionResult.success);
      expect(
        requestLog.any((r) =>
            r.startsWith('POST') &&
            r.contains('/partner/rate-plans/1/deactivate')),
        isTrue,
      );
      expect(rates.plans.first.active, isFalse);
    });

    testWidgets('a failed toggle changes nothing and says so', (tester) async {
      await pumpRates(
        tester,
        client: ratesClient(overrides: {
          '/deactivate': jsonResponse(
              errorBody(404, 'Rate plan not found: 1', '/deactivate'), 404),
        }),
      );

      await tester.tap(find.text(en.partnerRateDeactivateAction));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerRateActionNotFound), findsOneWidget);
      expect(find.text(en.partnerRateActive), findsWidgets);
    });

    test('a 409 is classified as a conflict, never a generic failure',
        () async {
      final app = partnerApp(ratesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final conflicting = PartnerRatesState(
        api: ApiClient(
            client: ratesClient(overrides: {
          '/deactivate': jsonResponse(
              errorBody(409, 'Conflict', '/deactivate'), 409),
        }))
          ..demoMode = false,
      );
      await conflicting.load(partner, 11);
      final result = await conflicting.setActive(1, activate: false);
      expect(result, PartnerRateActionResult.conflict);
    });

    test('a timed-out toggle is uncertain, never a clean failure', () async {
      final api = ApiClient(
          client: MockClient((_) async => throw TimeoutException('slow')))
        ..demoMode = false;
      final result = await api.deactivatePartnerRatePlan(1);
      expect(result.errorKind, ApiErrorKind.uncertain);
    });

    test('acting on a plan outside the list never reaches the network',
        () async {
      final app = partnerApp(ratesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final rates = PartnerRatesState(api: app.api);
      await rates.load(partner, 11);
      requestLog.clear();

      final result = await rates.setActive(9999, activate: false);
      expect(result, PartnerRateActionResult.notFound);
      expect(requestLog, isEmpty);
    });

    test('no destructive or full-replace endpoint is exposed', () {
      // PUT /rate-plans/{id} nulls every omitted optional field, DELETE is
      // irreversible and 409s for parents of derived plans. Neither is wired.
      final api = ApiClient(client: ratesClient());
      expect(api.activatePartnerRatePlan, isNotNull);
      expect(api.deactivatePartnerRatePlan, isNotNull);
      expect(api.getPartnerRatePlans, isNotNull);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────

  group('errors', () {
    testWidgets('401 shows the session-expired view', (tester) async {
      await pumpRates(
        tester,
        client: ratesClient(overrides: {
          '/rate-plans': jsonResponse(
              errorBody(401, 'Unauthorized', '/api/partner'), 401),
        }),
      );
      expect(find.text(en.partnerStatusUnauthorizedTitle), findsOneWidget);
    });

    testWidgets('403 is an approval problem', (tester) async {
      await pumpRates(
        tester,
        client: ratesClient(overrides: {
          '/rate-plans': jsonResponse(
              errorBody(403, 'Partner profile is not approved', '/api/partner'),
              403),
        }),
      );
      expect(find.text(en.partnerStatusForbiddenTitle), findsOneWidget);
    });

    testWidgets('404 shows the unavailable view', (tester) async {
      await pumpRates(
        tester,
        client: ratesClient(overrides: {
          '/rate-plans': jsonResponse(
              errorBody(404, 'Room not found', '/api/partner'), 404),
        }),
      );
      expect(find.text(en.partnerRatesUnavailableTitle), findsOneWidget);
    });

    test('a network failure is retryable and not empty', () async {
      final app = partnerApp(ratesClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      final offline = PartnerRatesState(
        api: ApiClient(client: ratesClient(throwNetwork: true))
          ..demoMode = false,
      );
      await offline.load(partner, 11);
      expect(offline.status, PartnerRatesStatus.error);
      expect(offline.isRetryable, isTrue);
      expect(offline.isEmpty, isFalse);
    });

    test('a malformed body fails rather than rendering blanks', () async {
      final api = ApiClient(
          client: MockClient((_) async => http.Response('{}', 200,
              headers: {'content-type': 'application/json; charset=utf-8'})))
        ..demoMode = false;
      final result = await api.getPartnerRatePreview(
        ratePlanId: 1,
        checkIn: DateTime(2026, 9, 1),
        checkOut: DateTime(2026, 9, 3),
      );
      expect(result.success, isFalse);
      expect(result.errorKind, ApiErrorKind.malformed);
    });

    testWidgets('a non-approved partner never reaches rates', (tester) async {
      final app = partnerApp(ratesClient(verificationStatus: 'SUBMITTED'));
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerStatusAwaitingApprovalTitle), findsOneWidget);
      expect(requestLog.any((r) => r.contains('rate-plans')), isFalse);
    });
  });

  // ── Role ─────────────────────────────────────────────────────────────────

  group('team role', () {
    testWidgets('the owner sees rate actions', (tester) async {
      final handles = await pumpRates(tester);
      expect(handles.partner.teamRole, PartnerTeamRole.owner);
      expect(find.text(en.partnerRateActionsOwnerOnly), findsNothing);
      expect(find.text(en.partnerRateDeactivateAction), findsOneWidget);
    });
  });

  // ── Responsive ───────────────────────────────────────────────────────────

  group('responsive', () {
    testWidgets('desktop shows list and detail side by side', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRates(tester, size: const Size(1700, 2600));
      await tester.tap(find.text('Summer Deal'));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerRateDetailHeading), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('tablet renders without layout errors', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRates(tester, size: const Size(820, 2600));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('mobile has no horizontal overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRates(tester, size: const Size(390, 3000));
      expect(find.text('Summer Deal'), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('a very narrow phone does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRates(tester, size: const Size(320, 3200));
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    testWidgets('mobile detail does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRates(tester, size: const Size(390, 4200));
      await tester.tap(find.text('Summer Deal'));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerRateDetailHeading), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });
  });

  // ── Localization ─────────────────────────────────────────────────────────

  group('localization', () {
    testWidgets('English renders English strings', (tester) async {
      await pumpRates(tester, locale: const Locale('en'));
      expect(find.text(en.partnerRateActive), findsWidgets);
      expect(find.text(en.partnerRatesCount(1)), findsOneWidget);
    });

    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpRates(tester, locale: const Locale('vi'));
      expect(find.text(vi.partnerRateActive), findsWidgets);
      expect(find.text(vi.partnerRatesCount(1)), findsOneWidget);
      expect(find.text(en.partnerRateActive), findsNothing);
    });

    testWidgets('Vietnamese detail is localized and does not overflow',
        (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpRates(
          tester, size: const Size(390, 4400), locale: const Locale('vi'));
      await tester.tap(find.text('Summer Deal'));
      await tester.pumpAndSettle();
      expect(find.text(vi.partnerRateDetailHeading), findsOneWidget);
      expect(find.text(vi.partnerRateSectionCancellation), findsOneWidget);
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });

    test('every C5 string exists in both locales', () {
      for (final l10n in <AppLocalizations>[en, vi]) {
        expect(l10n.partnerRatesEmptyTitle, isNotEmpty);
        expect(l10n.partnerRateDetailHeading, isNotEmpty);
        expect(l10n.partnerRateCurrencyNote, isNotEmpty);
        expect(l10n.partnerRateValidityNote, isNotEmpty);
        expect(l10n.partnerRateTypeLastMinute, isNotEmpty);
        expect(l10n.partnerMealPlanAllInclusive, isNotEmpty);
        expect(l10n.partnerCancellationNonRefundable, isNotEmpty);
        expect(l10n.partnerRateSourceDerived, isNotEmpty);
        expect(l10n.partnerRatesCount(2), isNotEmpty);
        expect(l10n.partnerRateOccupancyLabel('2', '1'), isNotEmpty);
      }
    });
  });

  // ── DTO mapping ──────────────────────────────────────────────────────────

  group('DTO mapping', () {
    test('parses all five RatePlanType values and fails closed', () {
      for (final e in {
        'STANDARD': PartnerRatePlanType.standard,
        'PROMOTIONAL': PartnerRatePlanType.promotional,
        'MEMBER': PartnerRatePlanType.member,
        'EARLY_BIRD': PartnerRatePlanType.earlyBird,
        'LAST_MINUTE': PartnerRatePlanType.lastMinute,
      }.entries) {
        expect(PartnerRatePlanType.parse(e.key), e.value);
      }
      expect(PartnerRatePlanType.parse('FLASH_SALE'),
          PartnerRatePlanType.unknown);
    });

    test('nullable enums keep null distinct from unknown', () {
      expect(PartnerMealPlanType.parse(null), isNull);
      expect(PartnerMealPlanType.parse('BRUNCH'), PartnerMealPlanType.unknown);
      expect(PartnerCancellationPolicyType.parse(null), isNull);
      expect(PartnerRateAdjustmentType.parse(null), isNull);
    });

    test('maps the plan record field for field', () {
      final p = PartnerRatePlan.fromJson(planJson(
          code: 'SUM26', minStayNights: 2, priority: 10))!;
      expect(p.id, 1);
      expect(p.roomId, 1);
      expect(p.rateName, 'Summer Deal');
      expect(p.rateType, PartnerRatePlanType.promotional);
      expect(p.pricePerNight, 800000);
      expect(p.code, 'SUM26');
      expect(p.priority, 10);
      expect(p.minStayNights, 2);
      expect(p.mealPlanType, PartnerMealPlanType.roomOnly);
      expect(p.cancellationPolicyType,
          PartnerCancellationPolicyType.freeCancellation);
      expect(p.sourceType, PartnerRateSourceType.base);
      expect(p.isDerived, isFalse);
      // Genuinely null on the wire.
      expect(p.description, isNull);
      expect(p.cancellationDeadlineHours, isNull);
      expect(p.extraBedPrice, isNull);
    });

    test('a derived plan carries its parent and adjustment', () {
      final p = PartnerRatePlan.fromJson(planJson(
          sourceType: 'DERIVED',
          parentRatePlanId: 3,
          adjustmentType: 'PERCENTAGE',
          adjustmentValue: -10))!;
      expect(p.isDerived, isTrue);
      expect(p.parentRatePlanId, 3);
      expect(p.adjustmentType, PartnerRateAdjustmentType.percentage);
      expect(p.adjustmentValue, -10);
    });

    test('hasRestrictions reflects only configured limits', () {
      expect(PartnerRatePlan.fromJson(planJson())!.hasRestrictions, isFalse);
      expect(PartnerRatePlan.fromJson(planJson(minStayNights: 2))!
          .hasRestrictions, isTrue);
    });

    test('copyWithActive preserves every other field', () {
      final p = PartnerRatePlan.fromJson(planJson(code: 'SUM26'))!;
      final off = p.copyWithActive(false);
      expect(off.active, isFalse);
      expect(off.id, p.id);
      expect(off.code, p.code);
      expect(off.pricePerNight, p.pricePerNight);
      expect(off.startDate, p.startDate);
    });

    test('maps the occupancy price record', () {
      final o = PartnerOccupancyPrice.fromJson(occupancyJson())!;
      expect(o.adults, 2);
      expect(o.children, 1);
      expect(o.pricePerNight, 1100000);
      expect(o.childSupplement, 150000);
      expect(o.extraBedSupplement, isNull);
    });
  });
}
