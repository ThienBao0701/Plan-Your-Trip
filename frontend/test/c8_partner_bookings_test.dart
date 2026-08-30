import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_booking_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/bookings/partner_bookings_screen.dart';
import 'package:planyourtrip_frontend/features/partner/bookings/partner_bookings_state.dart';
import 'package:planyourtrip_frontend/features/partner/bookings/partner_front_desk_state.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:planyourtrip_frontend/shared/widgets/glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C8 — Partner Bookings.
///
/// Encodes what the backend audit established, so a later change that breaks any
/// of it fails here:
///
///  * **A partner cannot cancel or modify a booking.** `BookingService.cancel`
///    and `.modify` compare the caller against `booking.getUser()` and answer
///    403 to anyone else, the property owner included. No such control exists.
///  * **Nights are half-open** (`DAYS.between(checkIn, checkOut)`), unlike the
///    inclusive C4 calendar and C5 rate windows. The client never recomputes.
///  * **Bookings carry a currency**, unlike rate plans and promotions.
///  * **Ownership is uniform-404** for unknown and unowned alike.
///  * **An illegal transition is 422**, never 409, and changes nothing.
///  * **Pagination is real** (`PageResponse`); nothing is paged client-side.
///  * **An unrecognised status filter is silently ignored** by the backend, so
///    only real enum values are ever sent.
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
        'todaysArrivals': 1,
        'todaysDepartures': 0,
        'unreadMessages': 0,
        'unreadNotifications': 0,
        'pendingReviews': 0,
        'activePromotions': 0,
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

  Map<String, dynamic> roomJson({
    int id = 1,
    String roomName = 'Standard Twin',
  }) =>
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

  /// `PartnerBookingDto.PartnerBookingSummaryResponse` — all 15 fields. Note it
  /// carries no `hotelId`, which is why the list cannot be grouped by property.
  Map<String, dynamic> summaryJson({
    int id = 1,
    String bookingCode = 'PYT-20260829-000001',
    int roomId = 1,
    String status = 'CONFIRMED',
    String checkIn = '2026-10-28',
    String checkOut = '2026-10-30',
    int nights = 2,
    num finalPrice = 1800000,
    String? currency = 'VND',
  }) =>
      {
        'id': id,
        'bookingCode': bookingCode,
        'roomId': roomId,
        'roomName': 'Standard Twin',
        'roomCode': 'STD-$roomId',
        'guestName': 'Demo User',
        'guestEmail': 'demo@planyourtrip.com',
        'checkIn': checkIn,
        'checkOut': checkOut,
        'nights': nights,
        'status': status,
        'finalPrice': finalPrice,
        'currency': currency,
        'createdAt': '2026-08-29T08:26:10Z',
      };

  Map<String, dynamic> pageJson({
    List<Map<String, dynamic>>? content,
    int page = 0,
    int size = 20,
    int? totalElements,
    int totalPages = 1,
  }) {
    final items = content ?? [summaryJson()];
    return {
      'content': items,
      'page': page,
      'size': size,
      'totalElements': totalElements ?? items.length,
      'totalPages': totalPages,
    };
  }

  /// `BookingDto.BookingResponse`, shaped like real seed data (most optional
  /// fields genuinely null — the seeded booking has no rate plan).
  Map<String, dynamic> bookingJson({
    int id = 1,
    String status = 'CONFIRMED',
    String? currency = 'VND',
    num? ratePlanPrice,
    String? ratePlanName,
    num discountAmount = 0,
    String? actualCheckInAt,
    String? actualCheckOutAt,
  }) =>
      {
        'id': id,
        'bookingCode': 'PYT-20260829-00000$id',
        'userId': 1,
        'userFullName': 'Demo User',
        'userEmail': 'demo@planyourtrip.com',
        'hotelId': 11,
        'hotelName': 'Bay View Danang',
        'roomId': 1,
        'roomName': 'Standard Twin',
        'roomCode': 'STD-1',
        'checkIn': '2026-10-28',
        'checkOut': '2026-10-30',
        'nights': 2,
        'adults': 2,
        'children': 0,
        'numberOfRooms': 1,
        'status': status,
        'currency': currency,
        'basePrice': 1800000,
        'ratePlanPrice': ratePlanPrice,
        'discountAmount': discountAmount,
        'finalPrice': 1800000,
        'specialRequest': 'Sea view please',
        'partnerNote': null,
        'createdAt': '2026-08-29T08:26:10Z',
        'updatedAt': '2026-08-29T08:26:10Z',
        'confirmedAt': '2026-08-29T08:26:10Z',
        'cancelledAt': null,
        'actualCheckInAt': actualCheckInAt,
        'actualCheckOutAt': actualCheckOutAt,
        'completedAt': null,
        'archivedAt': null,
        'lastStatusChangedAt': null,
        'cancelReason': null,
        'couponCode': null,
        'couponDiscountAmount': null,
        'creditAmountUsed': null,
        'loyaltyDiscountAmount': null,
        'loyaltyPointsRedeemed': null,
        'giftCardAmountUsed': null,
        'giftCardReference': null,
        'selectedRatePlanId': ratePlanName == null ? null : 3,
        'selectedRatePlanCode': ratePlanName == null ? null : 'FLEX',
        'selectedRatePlanName': ratePlanName,
        'mealPlanType': ratePlanName == null ? null : 'BREAKFAST',
        'cancellationPolicyType':
            ratePlanName == null ? null : 'FREE_CANCELLATION',
        'cancellationDeadlineAt': null,
        'refundable': ratePlanName == null ? null : true,
        'nightlyRateSnapshot': ratePlanName == null ? null : 900000,
        'ratePlanAdjustmentSnapshot': null,
      };

  /// `PaymentDto.PaymentResponse` — including the two fields the client must
  /// never surface, so a regression that starts rendering them is caught.
  Map<String, dynamic> paymentJson() => {
        'id': 1,
        'paymentCode': 'PAY-20260829-000001',
        'bookingId': 1,
        'bookingCode': 'PYT-20260829-000001',
        'amount': 1800000,
        'currency': 'VND',
        'paymentMethod': 'MOCK',
        'status': 'PAID',
        'provider': 'MOCK',
        'providerTransactionId': 'MOCK-TXN-SEED-1',
        'checkoutUrl': 'https://pay.example/checkout/secret-token-1',
        'failureReason': null,
        'paidAt': '2026-08-29T08:26:10Z',
        'failedAt': null,
        'refundedAt': null,
        'createdAt': '2026-08-29T08:26:10Z',
        'updatedAt': '2026-08-29T08:26:10Z',
      };

  Map<String, dynamic> detailJson({
    Map<String, dynamic>? booking,
    List<Map<String, dynamic>>? payments,
    bool invoice = true,
  }) =>
      {
        'booking': booking ?? bookingJson(),
        'payments': payments ?? [paymentJson()],
        'invoice': invoice
            ? {
                'id': 1,
                'invoiceNumber': 'INV-20260829-000001',
                'bookingId': 1,
                'bookingCode': 'PYT-20260829-000001',
                'status': 'ISSUED',
                'totalAmount': 1800000,
                'currency': 'VND',
                'issuedAt': '2026-08-29T08:26:10Z',
              }
            : null,
        'timeline': {
          'bookingId': 1,
          'bookingCode': 'PYT-20260829-000001',
          'events': [
            {
              'event': 'CREATED',
              'occurredAt': '2026-08-29T08:26:10Z',
              'description': 'Booking created',
            },
            {
              'event': 'CONFIRMED',
              'occurredAt': '2026-08-29T08:26:10Z',
              'description': 'Booking confirmed',
            },
          ],
        },
      };

  /// `PartnerGuestStayDto.PartnerGuestStayResponse`.
  Map<String, dynamic> stayJson({
    String status = 'CONFIRMED',
    String stayState = 'UPCOMING',
    List<String> warnings = const ['FUTURE_BOOKING'],
    List<Map<String, dynamic>>? modifications,
    Map<String, dynamic>? checkInAudit,
    Map<String, dynamic>? checkOutAudit,
    int currentNight = 0,
    int remaining = 2,
  }) =>
      {
        'bookingId': 1,
        'bookingCode': 'PYT-20260829-000001',
        'bookingStatus': status,
        'createdAt': '2026-08-29T08:26:10Z',
        'updatedAt': '2026-08-29T08:26:10Z',
        'guestName': 'Demo User',
        'occupancy': {'adults': 2, 'children': 0},
        'hotelId': 11,
        'hotelName': 'Bay View Danang',
        'roomId': 1,
        'roomName': 'Standard Twin',
        'roomCode': 'STD-1',
        'schedule': {
          'checkInDate': '2026-10-28',
          'checkOutDate': '2026-10-30',
          'totalNights': 2,
          'actualCheckInAt': null,
          'actualCheckOutAt': null,
          'currentStayState': stayState,
          'currentNightNumber': currentNight,
          'remainingNights': remaining,
        },
        'voucher': {'voucherAvailable': true, 'voucherStatus': 'VALID'},
        'timeline': {
          'bookingId': 1,
          'bookingCode': 'PYT-20260829-000001',
          'events': <Object>[],
        },
        'modifications': modifications ?? <Object>[],
        'checkInAudit': checkInAudit,
        'checkOutAudit': checkOutAudit,
        'operationalWarnings': warnings,
      };

  Map<String, dynamic> frontDeskJson({
    String status = 'CHECKED_IN',
    String message = 'Check-in completed',
    String? at = '2026-10-28T06:00:00Z',
  }) =>
      {
        'success': true,
        'bookingCode': 'PYT-20260829-000001',
        'bookingStatus': status,
        'checkedInAt': at,
        'hotelName': 'Bay View Danang',
        'roomName': 'Standard Twin',
        'guestName': 'Demo User',
        'message': message,
      };

  late List<String> requestLog;
  late List<Uri> requestUris;
  late List<Map<String, dynamic>> postBodies;
  setUp(() {
    requestLog = <String>[];
    requestUris = <Uri>[];
    postBodies = <Map<String, dynamic>>[];
  });

  MockClient bookingsClient({
    Map<String, http.Response>? overrides,
    Map<String, dynamic>? page,
    Map<String, dynamic>? detail,
    Map<String, dynamic>? stay,
    List<Map<String, dynamic>>? rooms,
    Map<String, dynamic>? frontDesk,
    int? frontDeskStatus,
    String? frontDeskMessage,
    int? actionStatus,
    Map<String, dynamic>? actionBooking,
    bool throwNetwork = false,
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path');
        requestUris.add(request.url);
        if (throwNetwork) throw http.ClientException('offline');
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

        // POST front-desk endpoints, before the {id} matcher.
        if (path.endsWith('/partner/bookings/check-in') ||
            path.endsWith('/partner/bookings/check-out')) {
          final status = frontDeskStatus ?? 200;
          if (status != 200) {
            return jsonResponse(
                errorBody(status, frontDeskMessage ?? 'Rejected', path),
                status);
          }
          return jsonResponse(frontDesk ?? frontDeskJson(), 200);
        }

        final action = RegExp(
                r'/partner/bookings/(\d+)/(check-in|check-out|no-show|complete)$')
            .firstMatch(path);
        if (action != null) {
          final status = actionStatus ?? 200;
          if (status != 200) {
            return jsonResponse(
              errorBody(status, 'Illegal status transition', path),
              status,
            );
          }
          return jsonResponse(
              actionBooking ?? bookingJson(status: 'CHECKED_IN'), 200);
        }

        final stayMatch = RegExp(r'/partner/stays/(\d+)$').firstMatch(path);
        if (stayMatch != null) {
          return jsonResponse(stay ?? stayJson(), 200);
        }

        final byId = RegExp(r'/partner/bookings/(\d+)$').firstMatch(path);
        if (byId != null) {
          return jsonResponse(detail ?? detailJson(), 200);
        }

        if (path.endsWith('/partner/bookings')) {
          return jsonResponse(page ?? pageJson(), 200);
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
              body: SingleChildScrollView(child: PartnerBookingsScreen()),
            ),
          ),
        ),
      );

  Future<({AppState app, PartnerState partner})> pumpBookings(
    WidgetTester tester, {
    http.Client? client,
    Size size = const Size(1600, 3000),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? bookingsClient());
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

  Future<({PartnerBookingsState state, PartnerState partner})> loadedState(
    http.Client client,
  ) async {
    final app = partnerApp(client);
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);
    final state = PartnerBookingsState(api: app.api);
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

  Uri lastBookingsListUri() => requestUris.lastWhere((u) =>
      u.path.endsWith('/partner/bookings') && u.path.contains('partner'));

  Future<void> openFrontDeskTab(WidgetTester tester) async {
    final tab = find.text(en.partnerBookingsTabFrontDesk);
    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  // ── Model / contract fidelity ─────────────────────────────────────────

  group('booking model mirrors the backend DTOs', () {
    test('the summary parses every field the list needs', () {
      final s = PartnerBookingSummary.fromJson(summaryJson())!;
      expect(s.id, 1);
      expect(s.bookingCode, 'PYT-20260829-000001');
      expect(s.roomId, 1);
      expect(s.roomName, 'Standard Twin');
      expect(s.guestName, 'Demo User');
      expect(s.guestEmail, 'demo@planyourtrip.com');
      expect(s.checkIn, DateTime(2026, 10, 28));
      expect(s.checkOut, DateTime(2026, 10, 30));
      expect(s.nights, 2);
      expect(s.status, PartnerBookingStatus.confirmed);
      expect(s.finalPrice, 1800000);
      expect(s.currency, 'VND');
    });

    test('all ten backend statuses parse, and nothing else does', () {
      const wire = {
        'PENDING': PartnerBookingStatus.pending,
        'CONFIRMED': PartnerBookingStatus.confirmed,
        'CHECK_IN_READY': PartnerBookingStatus.checkInReady,
        'CHECKED_IN': PartnerBookingStatus.checkedIn,
        'CHECKED_OUT': PartnerBookingStatus.checkedOut,
        'COMPLETED': PartnerBookingStatus.completed,
        'CANCELLED': PartnerBookingStatus.cancelled,
        'REFUNDED': PartnerBookingStatus.refunded,
        'ARCHIVED': PartnerBookingStatus.archived,
        'NO_SHOW': PartnerBookingStatus.noShow,
      };
      wire.forEach((raw, expected) {
        expect(PartnerBookingStatus.parse(raw), expected);
      });
      expect(PartnerBookingStatus.parse('IN_PROGRESS'),
          PartnerBookingStatus.unknown);
      expect(PartnerBookingStatus.parse(null), PartnerBookingStatus.unknown);
      // The unknown value has no wire form, so it can never be sent.
      expect(PartnerBookingStatus.unknown.wireValue, isNull);
    });

    test('only real enum values are offered as filters', () {
      expect(PartnerBookingStatus.filterable, hasLength(10));
      expect(
        PartnerBookingStatus.filterable.contains(PartnerBookingStatus.unknown),
        isFalse,
      );
      for (final status in PartnerBookingStatus.filterable) {
        expect(status.wireValue, isNotNull);
      }
    });

    test('the action matrix mirrors BookingStatusEngineService.ALLOWED', () {
      expect(PartnerBookingStatus.confirmed.canCheckIn, isTrue);
      expect(PartnerBookingStatus.checkInReady.canCheckIn, isTrue);
      expect(PartnerBookingStatus.pending.canCheckIn, isFalse);
      expect(PartnerBookingStatus.checkedIn.canCheckIn, isFalse);

      expect(PartnerBookingStatus.checkedIn.canCheckOut, isTrue);
      expect(PartnerBookingStatus.confirmed.canCheckOut, isFalse);

      expect(PartnerBookingStatus.confirmed.canMarkNoShow, isTrue);
      expect(PartnerBookingStatus.checkedIn.canMarkNoShow, isFalse);

      expect(PartnerBookingStatus.checkedOut.canComplete, isTrue);
      expect(PartnerBookingStatus.completed.canComplete, isFalse);
    });

    test('the booking detail keeps the rate-plan snapshot verbatim', () {
      final b = PartnerBooking.fromJson(
          bookingJson(ratePlanName: 'Flexible', ratePlanPrice: 1900000))!;
      expect(b.hasRatePlanSnapshot, isTrue);
      expect(b.selectedRatePlanName, 'Flexible');
      expect(b.selectedRatePlanCode, 'FLEX');
      expect(b.nightlyRateSnapshot, 900000);
      expect(b.mealPlanType, 'BREAKFAST');
      expect(b.refundable, isTrue);
    });

    test('a booking with no rate plan reports no snapshot', () {
      final b = PartnerBooking.fromJson(bookingJson())!;
      expect(b.hasRatePlanSnapshot, isFalse);
      expect(b.selectedRatePlanId, isNull);
      expect(b.nightlyRateSnapshot, isNull);
    });

    test('the guest financial ledger is not mapped at all', () {
      // Coupon / loyalty / gift-card / travel-credit fields exist on the DTO but
      // are the guest's financial detail, so the partner model never carries
      // them and they cannot leak into the UI.
      final json = PartnerBooking.fromJson(bookingJson())!.toString();
      expect(json.contains('coupon'), isFalse);
      expect(json.contains('giftCard'), isFalse);
    });

    test('a booking with no id is rejected rather than half-built', () {
      final json = bookingJson()..remove('id');
      expect(PartnerBooking.fromJson(json), isNull);
    });

    test('dates parse as plain calendar days, immune to timezone drift', () {
      final b = PartnerBooking.fromJson(bookingJson())!;
      expect(b.checkIn!.isUtc, isFalse);
      expect(b.checkIn!.day, 28);
      expect(b.checkOut!.day, 30);
    });
  });

  group('night semantics are half-open and server-supplied', () {
    test('nights come from the server, not from a local subtraction', () {
      // 28 Oct -> 30 Oct is 2 nights: checkIn <= night < checkOut. This is
      // deliberately NOT the inclusive rule C4/C5 use.
      final s = PartnerBookingSummary.fromJson(summaryJson())!;
      expect(s.nights, 2);
      expect(s.checkOut!.difference(s.checkIn!).inDays, 2);
    });

    test('a server value that disagrees with the dates is still trusted', () {
      // If the backend ever changes its rule, the client must follow it rather
      // than silently "correcting" the number.
      final s = PartnerBookingSummary.fromJson(summaryJson(nights: 3))!;
      expect(s.nights, 3);
    });

    test('a same-day booking is zero nights, not one', () {
      final s = PartnerBookingSummary.fromJson(summaryJson(
          checkIn: '2026-10-28', checkOut: '2026-10-28', nights: 0))!;
      expect(s.nights, 0);
    });

    test('the stay schedule carries the server night counters', () {
      final stay = PartnerGuestStay.fromJson(
          stayJson(stayState: 'IN_HOUSE', currentNight: 1, remaining: 1))!;
      expect(stay.schedule.totalNights, 2);
      expect(stay.schedule.currentNightNumber, 1);
      expect(stay.schedule.remainingNights, 1);
      expect(stay.schedule.state, PartnerStayState.inHouse);
    });
  });

  group('currency', () {
    test('a booking carries one, unlike a rate plan or a promotion', () {
      expect(PartnerBooking.fromJson(bookingJson())!.currency, 'VND');
      expect(PartnerBookingSummary.fromJson(summaryJson())!.currency, 'VND');
    });

    test('a missing currency is tolerated rather than guessed', () {
      final b = PartnerBooking.fromJson(bookingJson(currency: null))!;
      expect(b.currency, isNull);
      expect(b.finalPrice, 1800000);
    });
  });

  // ── Query construction ────────────────────────────────────────────────

  group('the query only ever sends supported parameters', () {
    test('an empty query still carries paging', () {
      const query = PartnerBookingQuery();
      expect(query.toQueryParameters(), {'page': '0', 'size': '20'});
      expect(query.hasActiveFilters, isFalse);
    });

    test('every filter maps to its real request parameter', () {
      final query = PartnerBookingQuery(
        status: PartnerBookingStatus.checkedIn,
        guest: '  demo ',
        bookingCode: ' PYT-1 ',
        roomId: 4,
        checkInFrom: DateTime(2026, 10, 1),
        checkInTo: DateTime(2026, 10, 31),
        quickFilter: PartnerBookingQuickFilter.inHouse,
        page: 2,
        size: 50,
      );
      expect(query.toQueryParameters(), {
        'status': 'CHECKED_IN',
        'guest': 'demo',
        'bookingCode': 'PYT-1',
        'roomId': '4',
        'checkInFrom': '2026-10-01',
        'checkInTo': '2026-10-31',
        'inHouse': 'true',
        'page': '2',
        'size': '50',
      });
    });

    test('a partial date range keeps whichever half was given', () {
      expect(
        PartnerBookingQuery(checkInFrom: DateTime(2026, 10, 1))
            .toQueryParameters()['checkInFrom'],
        '2026-10-01',
      );
      expect(
        PartnerBookingQuery(checkInTo: DateTime(2026, 10, 31))
            .toQueryParameters()
            .containsKey('checkInFrom'),
        isFalse,
      );
    });

    test('there is no hotelId parameter to send', () {
      final params = const PartnerBookingQuery().toQueryParameters();
      expect(params.containsKey('hotelId'), isFalse);
    });

    test('an unknown status can never be encoded', () {
      const query = PartnerBookingQuery(status: PartnerBookingStatus.unknown);
      // The backend would silently ignore an unrecognised status and return the
      // unfiltered list, so the client refuses to send one at all.
      expect(query.toQueryParameters().containsKey('status'), isFalse);
    });
  });

  // ── Loading, filtering, paging ────────────────────────────────────────

  group('loading bookings', () {
    test('the first load requests page 0 with no filters', () async {
      await loadedState(bookingsClient());
      final uri = lastBookingsListUri();
      expect(uri.queryParameters['page'], '0');
      expect(uri.queryParameters['size'], '20');
      expect(uri.queryParameters.containsKey('status'), isFalse);
    });

    test('an empty result is a real answer, not an error', () async {
      final loaded = await loadedState(
          bookingsClient(page: pageJson(content: [], totalPages: 0)));
      expect(loaded.state.status, PartnerBookingsStatus.ready);
      expect(loaded.state.isEmpty, isTrue);
      expect(loaded.state.isUnfilteredEmpty, isTrue);
    });

    test('an empty filtered result is distinguished from having none',
        () async {
      final loaded = await loadedState(
          bookingsClient(page: pageJson(content: [], totalPages: 0)));
      await loaded.state.applyQuery(
        loaded.partner,
        const PartnerBookingQuery(status: PartnerBookingStatus.noShow),
      );
      expect(loaded.state.isEmpty, isTrue);
      expect(loaded.state.isUnfilteredEmpty, isFalse);
    });

    test('applying a filter resets to page 0', () async {
      final loaded = await loadedState(bookingsClient(
          page: pageJson(page: 2, totalElements: 60, totalPages: 3)));
      await loaded.state.goToPage(loaded.partner, 2);
      await loaded.state.applyQuery(
        loaded.partner,
        loaded.state.query.copyWith(status: PartnerBookingStatus.cancelled),
      );
      expect(lastBookingsListUri().queryParameters['page'], '0');
    });

    test('paging forwards and back uses the server page numbers', () async {
      final loaded = await loadedState(bookingsClient(
          page: pageJson(page: 0, size: 20, totalElements: 45, totalPages: 3)));
      expect(loaded.state.page.hasNext, isTrue);
      expect(loaded.state.page.hasPrevious, isFalse);

      await loaded.state.nextPage(loaded.partner);
      expect(lastBookingsListUri().queryParameters['page'], '1');
    });

    test('paging past the end is refused before any request', () async {
      final loaded = await loadedState(
          bookingsClient(page: pageJson(totalElements: 1, totalPages: 1)));
      final before = requestLog.length;
      await loaded.state.goToPage(loaded.partner, 5);
      await loaded.state.goToPage(loaded.partner, -1);
      expect(requestLog.length, before);
    });

    test('the showing-x-of-y range comes from PageResponse', () async {
      final loaded = await loadedState(bookingsClient(
          page: pageJson(page: 1, size: 20, totalElements: 45, totalPages: 3)));
      expect(loaded.state.page.firstIndex, 21);
      expect(loaded.state.page.lastIndex, 21);
      expect(loaded.state.page.totalElements, 45);
    });

    test('a rooms failure does not blank the booking list', () async {
      final loaded = await loadedState(bookingsClient(overrides: {
        '/partner/rooms': jsonResponse(errorBody(500, 'boom', '/x'), 500),
      }));
      expect(loaded.state.status, PartnerBookingsStatus.ready);
      expect(loaded.state.bookings, hasLength(1));
      expect(loaded.state.rooms, isEmpty);
    });
  });

  // ── Ownership / IDOR ──────────────────────────────────────────────────

  group('ownership and scope', () {
    test('detail refuses an id that is not on the loaded page', () async {
      final loaded = await loadedState(bookingsClient());
      final before = requestLog.length;
      await loaded.state.openBooking(999);
      expect(requestLog.length, before);
      expect(loaded.state.openBookingId, isNull);
    });

    test('a 404 on detail is the uniform unknown-or-unowned answer', () async {
      final loaded = await loadedState(bookingsClient(overrides: {
        '/partner/bookings/1':
            jsonResponse(errorBody(404, 'Booking not found: 1', '/x'), 404),
      }));
      await loaded.state.openBooking(1);
      expect(loaded.state.detailErrorKind, ApiErrorKind.notFound);
      expect(loaded.state.detail, isNull);
    });

    test('an open detail is dropped when the booking leaves the page',
        () async {
      final loaded = await loadedState(bookingsClient());
      await loaded.state.openBooking(1);
      expect(loaded.state.detail, isNotNull);

      final gone = partnerApp(
          bookingsClient(page: pageJson(content: [], totalPages: 0)));
      final goneState = PartnerBookingsState(api: gone.api);
      await goneState.load(loaded.partner, loaded.partner.selectedPropertyId);
      expect(goneState.openBookingId, isNull);
    });

    test('switching property clears a stale room filter and any open detail',
        () async {
      final loaded = await loadedState(bookingsClient());
      await loaded.state
          .applyQuery(loaded.partner, loaded.state.query.copyWith(roomId: 1));
      await loaded.state.openBooking(1);
      expect(loaded.state.query.roomId, 1);

      // A different property: the previous property's room id must not survive
      // and silently scope the new list.
      await loaded.state.load(loaded.partner, 999);
      expect(loaded.state.query.roomId, isNull);
      expect(loaded.state.openBookingId, isNull);
      expect(
          lastBookingsListUri().queryParameters.containsKey('roomId'), isFalse);
    });

    test('an action on a booking outside the page is refused locally',
        () async {
      final loaded = await loadedState(bookingsClient());
      final before = requestLog.length;
      final result = await loaded.state.runAction(
        partner: loaded.partner,
        bookingId: 4242,
        action: PartnerBookingAction.checkIn,
      );
      expect(result, PartnerBookingActionResult.notFound);
      expect(requestLog.length, before);
    });
  });

  // ── Error mapping ─────────────────────────────────────────────────────

  group('error mapping', () {
    test('401 is a session problem', () async {
      final loaded = await loadedState(bookingsClient(overrides: {
        '/partner/bookings': jsonResponse(errorBody(401, 'no', '/x'), 401),
      }));
      expect(loaded.state.status, PartnerBookingsStatus.unauthorized);
    });

    test('403 is an approval problem', () async {
      final loaded = await loadedState(bookingsClient(overrides: {
        '/partner/bookings': jsonResponse(errorBody(403, 'no', '/x'), 403),
      }));
      expect(loaded.state.status, PartnerBookingsStatus.forbidden);
    });

    test('404 means no partner profile', () async {
      final loaded = await loadedState(bookingsClient(overrides: {
        '/partner/bookings': jsonResponse(errorBody(404, 'no', '/x'), 404),
      }));
      expect(loaded.state.status, PartnerBookingsStatus.notFound);
    });

    test('a network failure is retryable', () async {
      final app = partnerApp(bookingsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final offline = partnerApp(bookingsClient(throwNetwork: true));
      final state = PartnerBookingsState(api: offline.api);
      await state.load(partner, partner.selectedPropertyId);
      expect(state.status, PartnerBookingsStatus.error);
      expect(state.isRetryable, isTrue);
    });

    test('a 500 is an error, not an empty list', () async {
      final loaded = await loadedState(bookingsClient(overrides: {
        '/partner/bookings': jsonResponse(errorBody(500, 'boom', '/x'), 500),
      }));
      expect(loaded.state.status, PartnerBookingsStatus.error);
      expect(loaded.state.isEmpty, isFalse);
    });

    test('422 on an action is a rejection, never a conflict', () async {
      final loaded = await loadedState(bookingsClient(actionStatus: 422));
      final result = await loaded.state.runAction(
        partner: loaded.partner,
        bookingId: 1,
        action: PartnerBookingAction.checkOut,
      );
      expect(result, PartnerBookingActionResult.rejected);
    });

    test('400 on an action is a validation failure', () async {
      final loaded = await loadedState(bookingsClient(actionStatus: 400));
      expect(
        await loaded.state.runAction(
          partner: loaded.partner,
          bookingId: 1,
          action: PartnerBookingAction.checkIn,
        ),
        PartnerBookingActionResult.validation,
      );
    });

    test('404 on an action is the uniform unknown-or-unowned answer', () async {
      final loaded = await loadedState(bookingsClient(actionStatus: 404));
      expect(
        await loaded.state.runAction(
          partner: loaded.partner,
          bookingId: 1,
          action: PartnerBookingAction.checkIn,
        ),
        PartnerBookingActionResult.notFound,
      );
    });

    test('403 on an action is an approval problem', () async {
      final loaded = await loadedState(bookingsClient(actionStatus: 403));
      expect(
        await loaded.state.runAction(
          partner: loaded.partner,
          bookingId: 1,
          action: PartnerBookingAction.checkIn,
        ),
        PartnerBookingActionResult.forbidden,
      );
    });

    test('a timeout on an action is uncertain, never a clean failure',
        () async {
      final client = MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'PATCH') {
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
          return jsonResponse([hotelListJson()], 200);
        }
        if (path.endsWith('/partner/rooms')) {
          return jsonResponse([roomJson()], 200);
        }
        if (path.endsWith('/partner/bookings')) {
          return jsonResponse(pageJson(), 200);
        }
        return jsonResponse(errorBody(404, 'x', path), 404);
      });
      final loaded = await loadedState(client);
      expect(
        await loaded.state.runAction(
          partner: loaded.partner,
          bookingId: 1,
          action: PartnerBookingAction.checkIn,
        ),
        PartnerBookingActionResult.uncertain,
      );
      // The local row must not claim the transition happened.
      expect(
          loaded.state.bookings.single.status, PartnerBookingStatus.confirmed);
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  // ── Lifecycle actions ─────────────────────────────────────────────────

  group('lifecycle actions', () {
    test('a successful action takes its new status from the server', () async {
      final loaded = await loadedState(bookingsClient());
      final result = await loaded.state.runAction(
        partner: loaded.partner,
        bookingId: 1,
        action: PartnerBookingAction.checkIn,
      );
      expect(result, PartnerBookingActionResult.success);
      expect(
          loaded.state.bookings.single.status, PartnerBookingStatus.checkedIn);
    });

    test('the request is a PATCH to the action path', () async {
      final loaded = await loadedState(bookingsClient());
      await loaded.state.runAction(
        partner: loaded.partner,
        bookingId: 1,
        action: PartnerBookingAction.noShow,
      );
      expect(requestLog, contains('PATCH /api/partner/bookings/1/no-show'));
    });

    test('every action path matches the controller mapping', () {
      expect(PartnerBookingAction.checkIn.path, 'check-in');
      expect(PartnerBookingAction.checkOut.path, 'check-out');
      expect(PartnerBookingAction.noShow.path, 'no-show');
      expect(PartnerBookingAction.complete.path, 'complete');
    });

    test('only permitted actions are offered for a status', () async {
      final loaded = await loadedState(bookingsClient());
      expect(
        loaded.state.availableActionsFor(PartnerBookingStatus.confirmed),
        [PartnerBookingAction.checkIn, PartnerBookingAction.noShow],
      );
      expect(
        loaded.state.availableActionsFor(PartnerBookingStatus.checkedIn),
        [PartnerBookingAction.checkOut],
      );
      expect(
        loaded.state.availableActionsFor(PartnerBookingStatus.checkedOut),
        [PartnerBookingAction.complete],
      );
      expect(
        loaded.state.availableActionsFor(PartnerBookingStatus.cancelled),
        isEmpty,
      );
      expect(
        loaded.state.availableActionsFor(PartnerBookingStatus.completed),
        isEmpty,
      );
    });

    test('the open booking is re-read after a successful action', () async {
      final loaded = await loadedState(bookingsClient());
      await loaded.state.openBooking(1);
      final before =
          requestLog.where((r) => r.contains('/partner/stays/1')).length;
      await loaded.state.runAction(
        partner: loaded.partner,
        bookingId: 1,
        action: PartnerBookingAction.checkIn,
      );
      final after =
          requestLog.where((r) => r.contains('/partner/stays/1')).length;
      // The timeline, audit rows and derived state all changed server-side.
      expect(after, greaterThan(before));
    });
  });

  // ── Detail ────────────────────────────────────────────────────────────

  group('booking detail', () {
    test('both endpoints are read, and each supplies what it owns', () async {
      final loaded = await loadedState(bookingsClient());
      await loaded.state.openBooking(1);
      expect(requestLog, contains('GET /api/partner/bookings/1'));
      expect(requestLog, contains('GET /api/partner/stays/1'));
      expect(loaded.state.detail!.booking.bookingCode, 'PYT-20260829-000001');
      expect(loaded.state.detail!.payments, hasLength(1));
      expect(
          loaded.state.detail!.invoice!.invoiceNumber, 'INV-20260829-000001');
      expect(loaded.state.detail!.timeline, hasLength(2));
      expect(loaded.state.stay!.schedule.state, PartnerStayState.upcoming);
    });

    test('losing the stay projection degrades rather than fails', () async {
      final loaded = await loadedState(bookingsClient(overrides: {
        '/partner/stays/1': jsonResponse(errorBody(500, 'boom', '/x'), 500),
      }));
      await loaded.state.openBooking(1);
      expect(loaded.state.detail, isNotNull);
      expect(loaded.state.stay, isNull);
      expect(loaded.state.detailErrorKind, isNull);
    });

    test('warnings parse into typed tokens, and unknown ones survive', () {
      final stay = PartnerGuestStay.fromJson(stayJson(
          warnings: ['CURRENTLY_STAYING', 'CHECK_OUT_OVERDUE', 'NEW_TOKEN']))!;
      expect(stay.warnings, hasLength(3));
      expect(stay.warnings, contains(PartnerStayWarning.checkOutOverdue));
      expect(stay.warnings, contains(PartnerStayWarning.unknown));
      expect(stay.actionableWarnings, [PartnerStayWarning.checkOutOverdue]);
    });

    test('modification history parses as history', () {
      final stay = PartnerGuestStay.fromJson(stayJson(modifications: [
        {
          'previousCheckIn': '2026-10-28',
          'newCheckIn': '2026-10-29',
          'previousCheckOut': '2026-10-30',
          'newCheckOut': '2026-10-31',
          'previousAdults': 2,
          'newAdults': 3,
          'previousChildren': 0,
          'newChildren': 0,
          'previousRatePlanId': null,
          'newRatePlanId': null,
          'previousRatePlan': null,
          'newRatePlan': 'Flexible',
          'previousPrice': 1800000,
          'newPrice': 2100000,
          'modifiedAt': '2026-09-01T02:00:00Z',
        }
      ]))!;
      expect(stay.hasModifications, isTrue);
      final m = stay.modifications.single;
      expect(m.changedDates, isTrue);
      expect(m.changedOccupancy, isTrue);
      expect(m.changedPrice, isTrue);
      expect(m.newRatePlan, 'Flexible');
    });

    test('audit rows parse, including the check-out method', () {
      final stay = PartnerGuestStay.fromJson(stayJson(
        checkInAudit: {
          'partnerProfileId': 7,
          'partnerUserId': 42,
          'operation': 'CHECK_IN',
          'method': null,
          'timestamp': '2026-10-28T06:00:00Z',
        },
        checkOutAudit: {
          'partnerProfileId': 7,
          'partnerUserId': 42,
          'operation': 'CHECK_OUT',
          'method': 'QR_SCAN',
          'timestamp': '2026-10-30T04:00:00Z',
        },
      ))!;
      expect(stay.hasAudit, isTrue);
      // A check-in records no method; only a check-out does.
      expect(stay.checkInAudit!.method, isNull);
      expect(stay.checkOutAudit!.method, 'QR_SCAN');
    });
  });

  // ── Payment safety ────────────────────────────────────────────────────

  group('payment data is safe', () {
    test('the gateway identifier and checkout URL are not even parsed', () {
      final payment = PartnerBookingPayment.fromJson(paymentJson())!;
      expect(payment.paymentCode, 'PAY-20260829-000001');
      expect(payment.status, 'PAID');
      expect(payment.amount, 1800000);
      // Not fields on the model at all, so nothing downstream can render them.
      expect(payment.toString().contains('MOCK-TXN'), isFalse);
      expect(payment.toString().contains('secret-token'), isFalse);
    });

    testWidgets('no gateway identifier or payment link reaches the screen',
        (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('MOCK-TXN'), findsNothing);
      expect(find.textContaining('pay.example'), findsNothing);
      expect(find.textContaining('secret-token'), findsNothing);
    });

    testWidgets('the payment limitation is stated', (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerBookingPaymentReadOnlyNote), findsOneWidget);
    });
  });

  // ── No invented capability ────────────────────────────────────────────

  group('nothing beyond the audited contract is offered', () {
    testWidgets('no cancel or modify control exists', (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      // Cancel and modify are the customer's endpoints; a partner gets 403.
      expect(find.text('Cancel booking'), findsNothing);
      expect(find.text('Modify booking'), findsNothing);
      expect(find.byIcon(Icons.edit_rounded), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('no refund or payment control exists', (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(find.text('Refund'), findsNothing);
      expect(find.text('Charge'), findsNothing);
    });

    testWidgets('the module issues no DELETE or PUT', (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(requestLog.where((r) => r.startsWith('DELETE')), isEmpty);
      expect(requestLog.where((r) => r.startsWith('PUT')), isEmpty);
    });
  });

  // ── Front desk ────────────────────────────────────────────────────────

  group('front-desk check-in and check-out', () {
    PartnerFrontDeskState frontDeskState(http.Client client) =>
        PartnerFrontDeskState(api: ApiClient(client: client)..demoMode = false);

    test('a scanned payload is sent as voucherPayload', () async {
      final state = frontDeskState(bookingsClient());
      state.setInput('PYT-V1.PYT-20260829-000001.sig');
      expect(state.looksLikeVoucherPayload, isTrue);
      await state.submit();
      expect(postBodies.single.keys, ['voucherPayload']);
    });

    test('a typed code is sent as bookingCode', () async {
      final state = frontDeskState(bookingsClient());
      state.setInput('PYT-20260829-000001');
      expect(state.looksLikeVoucherPayload, isFalse);
      await state.submit();
      // The backend derives the audit method from exactly this distinction:
      // a payload records QR_SCAN, a bare code records MANUAL.
      expect(postBodies.single.keys, ['bookingCode']);
    });

    test('exactly one field is ever sent', () async {
      final state = frontDeskState(bookingsClient());
      state.setInput('  PYT-20260829-000001  ');
      await state.submit();
      expect(postBodies.single, {'bookingCode': 'PYT-20260829-000001'});
    });

    test('check-out posts to the check-out endpoint', () async {
      final state = frontDeskState(bookingsClient());
      state.setCheckIn(false);
      state.setInput('PYT-20260829-000001');
      await state.submit();
      expect(requestLog, contains('POST /api/partner/bookings/check-out'));
    });

    test('an empty input never reaches the network', () async {
      final state = frontDeskState(bookingsClient());
      state.setInput('   ');
      await state.submit();
      expect(state.status, PartnerFrontDeskStatus.invalidInput);
      expect(requestLog.where((r) => r.startsWith('POST')), isEmpty);
    });

    test('a successful check-in keeps the server message verbatim', () async {
      final state = frontDeskState(bookingsClient());
      state.setInput('PYT-20260829-000001');
      await state.submit();
      expect(state.status, PartnerFrontDeskStatus.done);
      expect(state.result!.message, 'Check-in completed');
      expect(state.result!.status, PartnerBookingStatus.checkedIn);
    });

    test('an idempotent repeat is a success with its own message', () async {
      final state = frontDeskState(bookingsClient(
          frontDesk: frontDeskJson(message: 'Guest is already checked in')));
      state.setInput('PYT-20260829-000001');
      await state.submit();
      // The backend returns 200 with the unchanged time and says so; the client
      // must not present that as a fresh transition of its own invention.
      expect(state.status, PartnerFrontDeskStatus.done);
      expect(state.result!.message, 'Guest is already checked in');
    });

    test('a 404 becomes one honest not-recognised state', () async {
      final state = frontDeskState(bookingsClient(frontDeskStatus: 404));
      state.setInput('tampered');
      await state.submit();
      expect(state.status, PartnerFrontDeskStatus.notRecognised);
      expect(state.result, isNull);
    });

    test('a 422 keeps the server explanation', () async {
      final state = frontDeskState(bookingsClient(
          frontDeskStatus: 422,
          frontDeskMessage: 'Check-in not available until 2026-10-27'));
      state.setInput('PYT-20260829-000001');
      await state.submit();
      expect(state.status, PartnerFrontDeskStatus.rejected);
      expect(state.errorMessage, 'Check-in not available until 2026-10-27');
    });

    test('a 400 is an input problem', () async {
      final state = frontDeskState(bookingsClient(frontDeskStatus: 400));
      state.setInput('PYT-20260829-000001');
      await state.submit();
      expect(state.status, PartnerFrontDeskStatus.invalidInput);
    });

    test('401 and 403 are distinguished', () async {
      final unauthorized = frontDeskState(bookingsClient(frontDeskStatus: 401));
      unauthorized.setInput('X');
      await unauthorized.submit();
      expect(unauthorized.status, PartnerFrontDeskStatus.unauthorized);

      final forbidden = frontDeskState(bookingsClient(frontDeskStatus: 403));
      forbidden.setInput('X');
      await forbidden.submit();
      expect(forbidden.status, PartnerFrontDeskStatus.forbidden);
    });

    test('editing the input invalidates the previous verdict', () async {
      final state = frontDeskState(bookingsClient());
      state.setInput('PYT-20260829-000001');
      await state.submit();
      expect(state.result, isNotNull);
      state.setInput('PYT-20260829-000002');
      expect(state.result, isNull);
      expect(state.status, PartnerFrontDeskStatus.idle);
    });

    test('switching between check-in and check-out clears the verdict',
        () async {
      final state = frontDeskState(bookingsClient());
      state.setInput('PYT-20260829-000001');
      await state.submit();
      state.setCheckIn(false);
      expect(state.result, isNull);
      expect(state.status, PartnerFrontDeskStatus.idle);
    });

    test('the client refuses a request with both or neither field', () async {
      final api = ApiClient(client: bookingsClient())..demoMode = false;
      final both = await api.runPartnerFrontDeskAction(
          checkIn: true, voucherPayload: 'a', bookingCode: 'b');
      final neither = await api.runPartnerFrontDeskAction(checkIn: true);
      expect(both.errorKind, ApiErrorKind.validation);
      expect(neither.errorKind, ApiErrorKind.validation);
      // Mirrors the backend rule rather than spending a round trip on it.
      expect(requestLog.where((r) => r.startsWith('POST')), isEmpty);
    });
  });

  // ── UI ────────────────────────────────────────────────────────────────

  group('bookings UI', () {
    testWidgets('renders real booking data from the backend', (tester) async {
      await pumpBookings(tester);
      expect(find.text('PYT-20260829-000001'), findsWidgets);
      expect(find.text('Demo User'), findsWidgets);
      expect(find.text(en.partnerBookingStatusConfirmed), findsWidgets);
    });

    testWidgets('states that the list is not scoped to one property',
        (tester) async {
      await pumpBookings(tester);
      expect(find.text(en.partnerBookingsScopeNote), findsOneWidget);
    });

    testWidgets('amounts carry the server currency code', (tester) async {
      await pumpBookings(tester);
      expect(find.textContaining('VND'), findsWidgets);
    });

    testWidgets('an empty list explains itself', (tester) async {
      await pumpBookings(tester,
          client: bookingsClient(page: pageJson(content: [], totalPages: 0)));
      expect(find.text(en.partnerBookingsEmptyTitle), findsOneWidget);
      expect(find.text(en.partnerBookingsEmptyMessage), findsOneWidget);
    });

    testWidgets('opening a booking shows its grouped detail', (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerBookingDetailHeading), findsOneWidget);
      expect(find.text(en.partnerBookingSectionGuest), findsOneWidget);
      expect(find.text(en.partnerBookingSectionStay), findsOneWidget);
      expect(find.text(en.partnerBookingSectionPrice), findsOneWidget);
      expect(find.text(en.partnerBookingSectionPayment), findsOneWidget);
      expect(find.text(en.partnerBookingSectionTimeline), findsOneWidget);
    });

    testWidgets('the rate-plan group is absent when nothing was snapshotted',
        (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerBookingSectionRatePlan), findsNothing);
    });

    testWidgets('the rate-plan group appears when one was snapshotted',
        (tester) async {
      await pumpBookings(tester,
          client: bookingsClient(
              detail: detailJson(
                  booking: bookingJson(
                      ratePlanName: 'Flexible', ratePlanPrice: 1900000))));
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerBookingSectionRatePlan), findsOneWidget);
      expect(find.text(en.partnerBookingSnapshotNote), findsOneWidget);
      expect(find.text('Flexible'), findsWidgets);
    });

    testWidgets('the price note says the backend calculated it',
        (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerBookingPriceNote), findsOneWidget);
    });

    testWidgets('an action asks for confirmation before running',
        (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text(en.partnerBookingActionCheckIn).first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // Declining must send nothing.
      await tester.tap(find.text(en.partnerBookingActionCancel));
      await tester.pumpAndSettle();
      expect(requestLog.where((r) => r.startsWith('PATCH')), isEmpty);
    });

    testWidgets('confirming runs the action and reports the outcome',
        (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerBookingActionCheckIn).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerBookingActionConfirmCta));
      await tester.pumpAndSettle();

      expect(requestLog, contains('PATCH /api/partner/bookings/1/check-in'));
      expect(
        find.text(en.partnerBookingActionSucceeded(
            en.partnerBookingActionCheckIn, 'PYT-20260829-000001')),
        findsOneWidget,
      );
    });

    testWidgets('a rejected action says nothing changed', (tester) async {
      await pumpBookings(tester, client: bookingsClient(actionStatus: 422));
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerBookingActionCheckIn).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerBookingActionConfirmCta));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerBookingActionRejected), findsOneWidget);
    });

    testWidgets('a closed booking offers no action', (tester) async {
      await pumpBookings(tester,
          client: bookingsClient(
              page: pageJson(content: [summaryJson(status: 'CANCELLED')]),
              detail: detailJson(booking: bookingJson(status: 'CANCELLED')),
              stay: stayJson(
                  status: 'CANCELLED',
                  stayState: 'CANCELLED',
                  warnings: ['CANCELLED_STAY'])));
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerBookingNoActionsClosed), findsOneWidget);
      expect(find.text(en.partnerBookingActionCheckIn), findsNothing);
    });

    testWidgets('an overdue check-out is surfaced as a warning',
        (tester) async {
      await pumpBookings(tester,
          client: bookingsClient(
              stay: stayJson(
                  status: 'CHECKED_IN',
                  stayState: 'IN_HOUSE',
                  warnings: ['CURRENTLY_STAYING', 'CHECK_OUT_OVERDUE'])));
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerStayWarningCheckOutOverdue), findsOneWidget);
    });

    testWidgets('modification history is shown as history, not as a control',
        (tester) async {
      await pumpBookings(tester,
          client: bookingsClient(
              stay: stayJson(modifications: [
            {
              'previousCheckIn': '2026-10-28',
              'newCheckIn': '2026-10-29',
              'previousCheckOut': '2026-10-30',
              'newCheckOut': '2026-10-31',
              'previousAdults': 2,
              'newAdults': 2,
              'previousChildren': 0,
              'newChildren': 0,
              'previousRatePlanId': null,
              'newRatePlanId': null,
              'previousRatePlan': null,
              'newRatePlan': null,
              'previousPrice': 1800000,
              'newPrice': 2100000,
              'modifiedAt': '2026-09-01T02:00:00Z',
            }
          ])));
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerBookingSectionModifications), findsOneWidget);
      expect(find.text(en.partnerBookingModificationNote), findsOneWidget);
    });

    testWidgets('pagination controls reflect the server page', (tester) async {
      await pumpBookings(tester,
          client: bookingsClient(
              page: pageJson(
                  page: 0, size: 20, totalElements: 45, totalPages: 3)));
      expect(
          find.text(en.partnerBookingPagePosition('1', '3')), findsOneWidget);
      expect(
        find.text(en.partnerBookingPageRange('1', '1', '45')),
        findsOneWidget,
      );
    });

    testWidgets('a quick filter sends its own request parameter',
        (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text(en.partnerBookingFilterInHouse));
      await tester.pumpAndSettle();
      expect(lastBookingsListUri().queryParameters['inHouse'], 'true');
    });

    testWidgets('the status filter only offers real backend values',
        (tester) async {
      await pumpBookings(tester);
      await tester.tap(find.text(en.partnerBookingFilterAnyStatus).last);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerBookingStatusUnknown), findsNothing);
      expect(find.text(en.partnerBookingStatusNoShow), findsWidgets);
    });
  });

  group('front-desk UI', () {
    testWidgets('a successful check-in is stated plainly', (tester) async {
      await pumpBookings(tester);
      await openFrontDeskTab(tester);
      await tester.enterText(find.byType(TextField), 'PYT-20260829-000001');
      await tester.pump();
      await tester.tap(find.byType(OceanPrimaryButton));
      await tester.pumpAndSettle();
      // It mutates a booking, so it is confirmed first.
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text(en.partnerBookingActionConfirmCta));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerFrontDeskCheckedInTitle), findsOneWidget);
      expect(find.text('Check-in completed'), findsOneWidget);
      expect(find.text(en.partnerFrontDeskIdempotentNote), findsOneWidget);
    });

    testWidgets('declining the confirmation sends nothing', (tester) async {
      await pumpBookings(tester);
      await openFrontDeskTab(tester);
      await tester.enterText(find.byType(TextField), 'PYT-20260829-000001');
      await tester.pump();
      await tester.tap(find.byType(OceanPrimaryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerBookingActionCancel));
      await tester.pumpAndSettle();
      expect(requestLog.where((r) => r.startsWith('POST')), isEmpty);
    });

    testWidgets('a 404 never claims to know which cause applied',
        (tester) async {
      await pumpBookings(tester, client: bookingsClient(frontDeskStatus: 404));
      await openFrontDeskTab(tester);
      await tester.enterText(find.byType(TextField), 'tampered');
      await tester.pump();
      await tester.tap(find.byType(OceanPrimaryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerBookingActionConfirmCta));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerFrontDeskNotRecognisedTitle), findsOneWidget);
      expect(
          find.text(en.partnerFrontDeskNotRecognisedMessage), findsOneWidget);
      expect(find.textContaining('forged'), findsNothing);
    });

    testWidgets('a 422 shows the server explanation verbatim', (tester) async {
      await pumpBookings(tester,
          client: bookingsClient(
              frontDeskStatus: 422,
              frontDeskMessage: 'Check-in not available until 2026-10-27'));
      await openFrontDeskTab(tester);
      await tester.enterText(find.byType(TextField), 'PYT-20260829-000001');
      await tester.pump();
      await tester.tap(find.byType(OceanPrimaryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerBookingActionConfirmCta));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerFrontDeskRejectedTitle), findsOneWidget);
      expect(
          find.text('Check-in not available until 2026-10-27'), findsOneWidget);
    });
  });

  // ── Workspace gating ──────────────────────────────────────────────────

  group('workspace gating', () {
    testWidgets('a non-approved partner never reaches bookings',
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
      expect(find.text(en.partnerBookingsTabReservations), findsNothing);
    });

    testWidgets('demo mode shows no fabricated bookings', (tester) async {
      final app = AppState(api: ApiClient(client: bookingsClient()))
        ..demoMode = true
        ..email = 'demo@planyourtrip.com'
        ..role = AppRole.partner;
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(app: app, partner: partner));
      await tester.pumpAndSettle();
      expect(find.text('PYT-20260829-000001'), findsNothing);
    });
  });

  // ── Layout and localization ───────────────────────────────────────────

  group('layout', () {
    testWidgets('desktop shows the table', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpBookings(tester, size: const Size(1600, 3000));
      expect(find.byType(Table), findsOneWidget);
      expect(errors, isEmpty);
    });

    testWidgets('desktop shows the list beside the open detail',
        (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpBookings(tester, size: const Size(1600, 3000));
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerBookingDetailHeading), findsOneWidget);
      expect(errors, isEmpty);
    });

    testWidgets('tablet falls back to cards without overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpBookings(tester, size: const Size(820, 3000));
      expect(errors, isEmpty);
    });

    testWidgets('mobile stacks with no horizontal overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpBookings(tester, size: const Size(390, 3400));
      expect(errors, isEmpty);
    });

    testWidgets('a very narrow phone does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpBookings(tester, size: const Size(320, 3400));
      expect(errors, isEmpty);
    });

    testWidgets('the detail panel fits a narrow phone', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpBookings(tester, size: const Size(320, 4200));
      await tester.tap(find.text('PYT-20260829-000001').first);
      await tester.pumpAndSettle();
      expect(errors, isEmpty);
    });

    testWidgets('the front desk fits a narrow phone', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpBookings(tester, size: const Size(320, 3400));
      await openFrontDeskTab(tester);
      expect(errors, isEmpty);
    });
  });

  group('localization', () {
    testWidgets('English renders English strings', (tester) async {
      await pumpBookings(tester, locale: const Locale('en'));
      expect(find.text(en.partnerBookingsTitle), findsOneWidget);
      expect(find.text(en.partnerBookingsTabFrontDesk), findsOneWidget);
    });

    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpBookings(tester, locale: const Locale('vi'));
      expect(find.text(vi.partnerBookingsTitle), findsOneWidget);
      expect(find.text(vi.partnerBookingsTabFrontDesk), findsOneWidget);
    });

    testWidgets('Vietnamese mobile does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpBookings(tester,
          size: const Size(390, 3400), locale: const Locale('vi'));
      expect(errors, isEmpty);
    });

    test('labels do not collide with the sidebar destinations', () {
      // "Bookings", "Rooms" and "Pricing" are navigation destinations; a field
      // or tab with the same text would be ambiguous inside the shell.
      expect(en.partnerBookingsTabReservations, isNot(en.partnerNavBookings));
      expect(vi.partnerBookingsTabReservations, isNot(vi.partnerNavBookings));
      expect(en.partnerBookingFieldRoom, isNot(en.partnerNavRooms));
      expect(vi.partnerBookingFieldRoom, isNot(vi.partnerNavRooms));
      expect(en.partnerBookingSectionPrice, isNot(en.partnerNavPricing));
      expect(vi.partnerBookingSectionPrice, isNot(vi.partnerNavPricing));
      expect(en.partnerBookingFieldProperty, isNot(en.partnerNavGroupProperty));
      expect(vi.partnerBookingFieldProperty, isNot(vi.partnerNavGroupProperty));
    });
  });
}
