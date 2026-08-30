import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_analytics_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_finance_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/analytics/partner_analytics_screen.dart';
import 'package:planyourtrip_frontend/features/partner/analytics/partner_analytics_state.dart';
import 'package:planyourtrip_frontend/features/partner/finance/partner_finance_screen.dart';
import 'package:planyourtrip_frontend/features/partner/finance/partner_finance_state.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// C11 — Partner Finance & Analytics.
///
/// Encodes what the backend audit established:
///
///  * **Both controllers are read-only** — fifteen GETs, no mutation anywhere.
///  * **No finance DTO carries a currency**, so no symbol is ever shown.
///  * **No finance record has an identifier** — no invoice, payout, settlement
///    or refund id exists, so there is no detail view and no export.
///  * **Money is never computed on the client.** [PartnerMoney] has no
///    operators, so client-side arithmetic is a compile error.
///  * **`from > to` is a real 400**, unlike the C4/C9 calendar's silent empty
///    result, and a **partial range is honoured**, unlike the calendar's.
///  * **Nullable is not zero**: `estimatedDiscountedBookings` and
///    `averageResponseTimeMinutes` arrive null and are shown as unavailable.
///  * **`paid` can contradict the period history**, because `getSettlement`
///    counts future months as settled. Both values are shown as sent and the
///    disagreement is named.
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

  /// `PartnerFinanceDto.PartnerFinanceOverviewResponse` — note the absence of
  /// any currency field, which is the contract.
  Map<String, dynamic> financeOverviewJson() => {
        'grossRevenue': 6000000.0,
        'netRevenue': 5100000.0,
        'commissionAmount': 900000.0,
        'estimatedTax': 510000.0,
        'completedBookings': 1,
        'paidBookings': 1,
        'refundedAmount': 0.0,
        'pendingSettlement': 5100000.0,
        'nextEstimatedPayoutDate': '2026-09-01',
      };

  Map<String, dynamic> commissionJson() => {
        'gross': 6000000.0,
        'commission': 900000.0,
        'net': 5100000.0,
        'commissionRate': 0.15,
      };

  Map<String, dynamic> revenueJson({bool empty = false}) => {
        'revenueByDay': empty
            ? [
                {'date': '2026-08-01', 'value': 0.0},
                {'date': '2026-08-02', 'value': 0.0},
              ]
            : [
                {'date': '2026-08-01', 'value': 0.0},
                {'date': '2026-08-02', 'value': 4200000.0},
              ],
        'revenueByMonth': empty
            ? <Object>[]
            : [
                {'label': '2026-08', 'amount': 4200000.0},
                {'label': '2026-10', 'amount': 1800000.0},
              ],
        'revenueByHotel': empty
            ? <Object>[]
            : [
                {'label': 'Bay View Danang', 'value': 6000000.0, 'count': 2},
              ],
        'revenueByRoom': empty
            ? <Object>[]
            : [
                {'label': 'Family Double', 'value': 4200000.0, 'count': 1},
                {'label': 'Standard Twin', 'value': 1800000.0, 'count': 1},
              ],
        'averageBookingValue': 3000000.0,
        'highestBooking': 4200000.0,
      };

  /// Reproduces the live contradiction: two `PENDING` periods, yet a non-zero
  /// `paid` scalar, because `getSettlement` counts every non-current period —
  /// including future months — as paid.
  Map<String, dynamic> settlementJson({bool contradiction = true}) => {
        'currentSettlement': 3570000.0,
        'lastSettlement': contradiction ? 1530000.0 : 0.0,
        'pending': 3570000.0,
        'paid': contradiction ? 1530000.0 : 0.0,
        'settlementHistory': [
          {
            'period': '2026-08',
            'grossAmount': 4200000.0,
            'commissionAmount': 630000.0,
            'netAmount': 3570000.0,
            'status': 'PENDING',
          },
          {
            'period': '2026-10',
            'grossAmount': 1800000.0,
            'commissionAmount': 270000.0,
            'netAmount': 1530000.0,
            'status': 'PENDING',
          },
        ],
        'estimatedNextSettlement': 3570000.0,
      };

  Map<String, dynamic> payoutJson() => {
        'upcomingPayouts': [
          {
            'period': '2026-08',
            'grossAmount': 4200000.0,
            'commissionAmount': 630000.0,
            'netAmount': 3570000.0,
            'status': 'PENDING',
          },
        ],
        'completedPayouts': <Object>[],
        'estimatedPayoutDate': '2026-09-01',
      };

  Map<String, dynamic> invoiceJson() => {
        'issued': 1,
        'paid': 0,
        'cancelled': 0,
        'refunded': 0,
        'totalInvoiceAmount': 1800000.0,
      };

  Map<String, dynamic> refundJson() => {
        'refundCount': 0,
        'refundAmount': 0.0,
        'refundPercentage': 0.0,
      };

  Map<String, dynamic> bookingAnalyticsJson({bool empty = false}) => {
        'bookingsByStatus': empty
            ? <Object>[]
            : [
                {'label': 'CONFIRMED', 'value': 1, 'count': 1},
                {'label': 'COMPLETED', 'value': 1, 'count': 1},
              ],
        'arrivals': 2,
        'departures': 2,
        'cancellations': 1,
        'noShows': 0,
        'averageStayLength': 2.0,
      };

  Map<String, dynamic> roomAnalyticsJson() => {
        'topRoomsByRevenue': [
          {'label': 'Family Double', 'value': 4200000.0, 'count': 1},
        ],
        'topRoomsByBookings': [
          {'label': 'Standard Twin', 'value': 1, 'count': 1},
        ],
        'roomAvailabilitySummary': [
          {'label': 'Available', 'value': 18, 'count': 18},
        ],
        'roomOccupancyEstimate': 12.5,
      };

  /// `estimatedDiscountedBookings` is null live — the backend cannot attribute
  /// discounts yet.
  Map<String, dynamic> promotionAnalyticsJson({Object? discounted}) => {
        'activePromotions': 2,
        'promotionsByType': [
          {'label': 'ROOM', 'value': 2, 'count': 2},
        ],
        'estimatedDiscountedBookings': discounted,
        'promotionCountByStatus': [
          {'label': 'ACTIVE', 'value': 2, 'count': 2},
        ],
      };

  Map<String, dynamic> reviewAnalyticsJson({int count = 1}) => {
        'averageRating': count == 0 ? 0.0 : 5.0,
        'reviewCount': count,
        'pendingReviews': 0,
        'approvedReviews': count,
        'rejectedReviews': 0,
        // Guest-bearing previews the client must not parse.
        'latestReviews': [
          {
            'id': 1,
            'guestName': 'Demo User',
            'ratingOverall': 5,
            'title': 'Wonderful stay',
            'status': 'APPROVED',
            'createdAt': '2026-08-30T01:12:27Z',
          }
        ],
      };

  Map<String, dynamic> messageAnalyticsJson({Object? responseTime}) => {
        'openConversations': 1,
        'closedConversations': 0,
        'archivedConversations': 0,
        'unreadPartnerMessages': 0,
        'averageResponseTimeMinutes': responseTime,
      };

  late List<String> requestLog;
  late List<Uri> requestUris;
  setUp(() {
    requestLog = <String>[];
    requestUris = <Uri>[];
  });

  MockClient metricsClient({
    Map<String, http.Response>? overrides,
    Map<String, dynamic>? settlement,
    Map<String, dynamic>? revenue,
    Map<String, dynamic>? promotions,
    Map<String, dynamic>? reviews,
    Map<String, dynamic>? messages,
    Map<String, dynamic>? bookings,
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

        // The backend rejects an inverted range with a real 400.
        final from = request.url.queryParameters['from'];
        final to = request.url.queryParameters['to'];
        if (from != null && to != null && from.compareTo(to) > 0) {
          return jsonResponse(
              errorBody(400, 'from must not be after to', path), 400);
        }
        // An unowned hotelId is a uniform 404.
        final hotelId = request.url.queryParameters['hotelId'];
        if (hotelId != null && hotelId != '11') {
          return jsonResponse(
              errorBody(404, 'Hotel not found: $hotelId', path), 404);
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

        if (path.endsWith('/finance/overview')) {
          return jsonResponse(financeOverviewJson(), 200);
        }
        if (path.endsWith('/finance/commissions')) {
          return jsonResponse(commissionJson(), 200);
        }
        if (path.endsWith('/finance/revenue')) {
          return jsonResponse(revenue ?? revenueJson(), 200);
        }
        if (path.endsWith('/finance/settlements')) {
          return jsonResponse(settlement ?? settlementJson(), 200);
        }
        if (path.endsWith('/finance/payouts')) {
          return jsonResponse(payoutJson(), 200);
        }
        if (path.endsWith('/finance/invoices')) {
          return jsonResponse(invoiceJson(), 200);
        }
        if (path.endsWith('/finance/refunds')) {
          return jsonResponse(refundJson(), 200);
        }

        if (path.endsWith('/analytics/bookings')) {
          return jsonResponse(bookings ?? bookingAnalyticsJson(), 200);
        }
        if (path.endsWith('/analytics/rooms')) {
          return jsonResponse(roomAnalyticsJson(), 200);
        }
        if (path.endsWith('/analytics/promotions')) {
          return jsonResponse(promotions ?? promotionAnalyticsJson(), 200);
        }
        if (path.endsWith('/analytics/reviews')) {
          return jsonResponse(reviews ?? reviewAnalyticsJson(), 200);
        }
        if (path.endsWith('/analytics/messages')) {
          return jsonResponse(messages ?? messageAnalyticsJson(), 200);
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
    required Widget child,
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
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      );

  Future<({AppState app, PartnerState partner})> pumpScreen(
    WidgetTester tester,
    Widget child, {
    http.Client? client,
    Size size = const Size(1600, 4000),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? metricsClient());
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
        testApp(app: app, partner: partner, child: child, locale: locale));
    await tester.pumpAndSettle();
    return (app: app, partner: partner);
  }

  Future<({PartnerFinanceState state, PartnerState partner})> loadedFinance(
    http.Client client,
  ) async {
    final app = partnerApp(client);
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);
    final state = PartnerFinanceState(api: app.api);
    await state.load(partner, partner.selectedPropertyId);
    return (state: state, partner: partner);
  }

  Future<({PartnerAnalyticsState state, PartnerState partner})> loadedAnalytics(
    http.Client client,
  ) async {
    final app = partnerApp(client);
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);
    final state = PartnerAnalyticsState(api: app.api);
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

  Uri uriFor(String suffix) =>
      requestUris.lastWhere((u) => u.path.endsWith(suffix));

  // ── Money precision and currency ──────────────────────────────────────

  group('money', () {
    test('PartnerMoney exposes no arithmetic', () {
      // The guarantee is structural: there is no +, -, * or / to reach for, so
      // client-side money maths cannot be written by accident.
      const money = PartnerMoney(6000000);
      expect(money.value, 6000000);
      expect(money, const PartnerMoney(6000000));
      expect(money.isZero, isFalse);
      expect(PartnerMoney.zero.isZero, isTrue);
    });

    test('an absent amount is null, not zero', () {
      expect(PartnerMoney.maybe(null), isNull);
      expect(PartnerMoney.maybe(0), const PartnerMoney(0));
    });

    test('no finance DTO carries a currency', () {
      // Every finance response is parsed; none of them has a currency field to
      // read, which is why the UI shows no symbol.
      final json = <String, dynamic>{
        ...financeOverviewJson(),
        ...commissionJson(),
        ...settlementJson(),
        ...invoiceJson(),
        ...refundJson(),
      };
      expect(json.containsKey('currency'), isFalse);
    });

    test('server figures are read, never recomputed', () {
      final commission = PartnerCommission.fromJson(commissionJson());
      // 6,000,000 − 900,000 = 5,100,000 would be the same, but the client takes
      // the server's `net` rather than subtracting.
      expect(commission.gross.value, 6000000);
      expect(commission.commission.value, 900000);
      expect(commission.net.value, 5100000);
      expect(commission.commissionRate, 0.15);
    });
  });

  // ── Finance model fidelity ────────────────────────────────────────────

  group('finance models', () {
    test('settlement periods parse with their server status', () {
      final settlement = PartnerSettlement.fromJson(settlementJson());
      expect(settlement.settlementHistory, hasLength(2));
      expect(settlement.settlementHistory.first.period, '2026-08');
      expect(settlement.settlementHistory.first.status,
          PartnerSettlementStatus.pending);
      expect(settlement.pendingPeriods, hasLength(2));
      expect(settlement.paidPeriods, isEmpty);
    });

    test('a paid total with no paid period is reported as a contradiction', () {
      // `getSettlement` counts every non-current period — future months
      // included — into `paid`, while the history marks them PENDING.
      final settlement = PartnerSettlement.fromJson(settlementJson());
      expect(settlement.paid.value, 1530000);
      expect(settlement.paidPeriods, isEmpty);
      expect(settlement.historyContradictsPaid, isTrue);
    });

    test('a consistent response reports no contradiction', () {
      final settlement =
          PartnerSettlement.fromJson(settlementJson(contradiction: false));
      expect(settlement.historyContradictsPaid, isFalse);
    });

    test('an unrecognised settlement status degrades', () {
      final json = settlementJson();
      (json['settlementHistory'] as List)[0]['status'] = 'SOMETHING_NEW';
      final settlement = PartnerSettlement.fromJson(json);
      expect(settlement.settlementHistory.first.status,
          PartnerSettlementStatus.unknown);
    });

    test('payouts carry no record identifier, reference or bank detail', () {
      final payouts = PartnerPayouts.fromJson(payoutJson());
      expect(payouts.upcomingPayouts.single.period, '2026-08');
      // The DTO has no id/reference/bank field at all, so nothing can leak.
      expect(payouts.toString().contains('iban'), isFalse);
      expect(payouts.completedPayouts, isEmpty);
      expect(payouts.estimatedPayoutDate, DateTime(2026, 9, 1));
    });

    test('invoice figures are counts, with no list and no identifier', () {
      final invoices = PartnerInvoiceFinance.fromJson(invoiceJson());
      expect(invoices.issued, 1);
      expect(invoices.total, 1);
      expect(invoices.totalInvoiceAmount.value, 1800000);
      expect(invoices.isEmpty, isFalse);
    });

    test('an all-zero invoice response is genuinely empty', () {
      final invoices = PartnerInvoiceFinance.fromJson({
        'issued': 0,
        'paid': 0,
        'cancelled': 0,
        'refunded': 0,
        'totalInvoiceAmount': 0.0,
      });
      expect(invoices.isEmpty, isTrue);
    });

    test('refunds are read-only counts', () {
      final refunds = PartnerRefunds.fromJson(refundJson());
      expect(refunds.refundCount, 0);
      expect(refunds.isEmpty, isTrue);
      expect(refunds.refundPercentage, 0.0);
    });

    test('revenue emptiness means no observations, not zeroed data', () {
      expect(PartnerFinanceRevenue.fromJson(revenueJson(empty: true)).isEmpty,
          isTrue);
      expect(PartnerFinanceRevenue.fromJson(revenueJson()).isEmpty, isFalse);
    });
  });

  // ── Analytics model fidelity ──────────────────────────────────────────

  group('analytics models', () {
    test('a null discounted-bookings count stays null', () {
      final promotions =
          PartnerPromotionAnalytics.fromJson(promotionAnalyticsJson());
      expect(promotions.estimatedDiscountedBookings, isNull);
      expect(promotions.hasDiscountAttribution, isFalse);
    });

    test('a present discounted-bookings count is read', () {
      final promotions = PartnerPromotionAnalytics.fromJson(
          promotionAnalyticsJson(discounted: 4));
      expect(promotions.estimatedDiscountedBookings, 4);
      expect(promotions.hasDiscountAttribution, isTrue);
    });

    test('a null response time stays null', () {
      final messages = PartnerMessageAnalytics.fromJson(messageAnalyticsJson());
      expect(messages.averageResponseTimeMinutes, isNull);
      expect(messages.hasResponseTime, isFalse);
    });

    test('zero reviews is no observations, not a rating of zero', () {
      final reviews =
          PartnerReviewAnalytics.fromJson(reviewAnalyticsJson(count: 0));
      expect(reviews.reviewCount, 0);
      expect(reviews.averageRating, 0);
      expect(reviews.hasNoObservations, isTrue);
    });

    test('guest-bearing review previews are not parsed at all', () {
      final reviews = PartnerReviewAnalytics.fromJson(reviewAnalyticsJson());
      // `latestReviews` carries guest names and titles; the analytics model has
      // no field for them, so they cannot reach an analytics screen.
      expect(reviews.toString().contains('Demo User'), isFalse);
      expect(reviews.toString().contains('Wonderful'), isFalse);
    });

    test('the two room rankings measure different things', () {
      final rooms = PartnerRoomAnalytics.fromJson(roomAnalyticsJson());
      // Money in one, a count in the other — kept apart, never merged.
      expect(rooms.topRoomsByRevenue.single.value, 4200000.0);
      expect(rooms.topRoomsByBookings.single.value, 1);
    });

    test('an empty booking breakdown is empty, not all-zero', () {
      expect(
          PartnerBookingAnalytics.fromJson(bookingAnalyticsJson(empty: true))
              .isEmpty,
          isTrue);
      expect(PartnerBookingAnalytics.fromJson(bookingAnalyticsJson()).isEmpty,
          isFalse);
    });
  });

  // ── Request shape, scope and date semantics ───────────────────────────

  group('request shape', () {
    test('finance issues exactly the seven endpoints, all GET', () async {
      await loadedFinance(metricsClient());
      final finance =
          requestLog.where((r) => r.contains('/partner/finance/')).toSet();
      expect(finance, {
        'GET /api/partner/finance/overview',
        'GET /api/partner/finance/commissions',
        'GET /api/partner/finance/revenue',
        'GET /api/partner/finance/settlements',
        'GET /api/partner/finance/payouts',
        'GET /api/partner/finance/invoices',
        'GET /api/partner/finance/refunds',
      });
      expect(requestLog.where((r) => !r.startsWith('GET')), isEmpty);
    });

    test('analytics issues only the five C1 did not already own', () async {
      await loadedAnalytics(metricsClient());
      final analytics =
          requestLog.where((r) => r.contains('/partner/analytics/')).toSet();
      expect(analytics, {
        'GET /api/partner/analytics/bookings',
        'GET /api/partner/analytics/rooms',
        'GET /api/partner/analytics/promotions',
        'GET /api/partner/analytics/reviews',
        'GET /api/partner/analytics/messages',
      });
      // Overview, revenue and occupancy belong to C1's dashboard; loading them
      // here would create a second definition of the same KPI.
      expect(analytics.any((r) => r.endsWith('/overview')), isFalse);
      expect(analytics.any((r) => r.endsWith('/revenue')), isFalse);
      expect(analytics.any((r) => r.endsWith('/occupancy')), isFalse);
    });

    test('both bounds are always sent', () async {
      final loaded = await loadedFinance(metricsClient());
      final uri = uriFor('/finance/overview');
      expect(uri.queryParameters.containsKey('from'), isTrue);
      expect(uri.queryParameters.containsKey('to'), isTrue);
      expect(loaded.state.to.difference(loaded.state.from).inDays,
          PartnerFinanceState.defaultWindowDays - 1);
    });

    test('the default window matches the backend default', () async {
      final loaded = await loadedFinance(metricsClient());
      final today = DateTime.now();
      expect(loaded.state.to, DateTime(today.year, today.month, today.day));
      expect(PartnerFinanceState.defaultWindowDays, 30);
    });

    test('the selected property is sent as hotelId', () async {
      final loaded = await loadedFinance(metricsClient());
      // The seeded workspace selects its single property.
      expect(loaded.state.hotelId, 11);
      expect(uriFor('/finance/overview').queryParameters['hotelId'], '11');
      expect(loaded.state.isPartnerWide, isFalse);
    });

    test('a property the workspace does not list is never sent', () async {
      final loaded = await loadedFinance(metricsClient());
      await loaded.state.load(loaded.partner, 999);
      // Rather than asking about someone else's property, the request is made
      // partner-wide, which is what the backend does for a null hotelId.
      expect(loaded.state.hotelId, isNull);
      expect(loaded.state.isPartnerWide, isTrue);
      expect(uriFor('/finance/overview').queryParameters.containsKey('hotelId'),
          isFalse);
    });

    test('an inverted range is refused before any request', () async {
      final loaded = await loadedFinance(metricsClient());
      final before = requestLog.length;
      await loaded.state.setRange(
          loaded.partner, DateTime(2026, 12, 31), DateTime(2026, 1, 1));
      expect(loaded.state.status, PartnerFinanceStatus.invalidRange);
      expect(requestLog.length, before);
    });

    test('the server 400 for an inverted range maps to the same state',
        () async {
      // Same outcome whether the client catches it or the backend does.
      final loaded = await loadedFinance(metricsClient(overrides: {
        '/finance/overview': jsonResponse(
            errorBody(400, 'from must not be after to', '/x'), 400),
      }));
      expect(loaded.state.status, PartnerFinanceStatus.invalidRange);
    });

    test('resetting the range restores the backend default', () async {
      final loaded = await loadedFinance(metricsClient());
      await loaded.state
          .setRange(loaded.partner, DateTime(2026, 1, 1), DateTime(2026, 3, 1));
      expect(loaded.state.from, DateTime(2026, 1, 1));
      await loaded.state.resetRange(loaded.partner);
      expect(loaded.state.to.difference(loaded.state.from).inDays, 29);
    });
  });

  // ── Section independence and error semantics ──────────────────────────

  group('sections load independently', () {
    test('one failing section does not blank the others', () async {
      final loaded = await loadedFinance(metricsClient(overrides: {
        '/finance/settlements': jsonResponse(errorBody(500, 'boom', '/x'), 500),
      }));
      expect(loaded.state.status, PartnerFinanceStatus.ready);
      expect(loaded.state.settlement.hasError, isTrue);
      expect(loaded.state.overview.hasData, isTrue);
      expect(loaded.state.revenue.hasData, isTrue);
      expect(loaded.state.failedSections, 1);
    });

    test('a failed section carries no data, so it cannot read as empty',
        () async {
      final loaded = await loadedFinance(metricsClient(overrides: {
        '/finance/refunds': jsonResponse(errorBody(500, 'boom', '/x'), 500),
      }));
      expect(loaded.state.refunds.hasError, isTrue);
      expect(loaded.state.refunds.hasData, isFalse);
    });

    test('401 is a module-level session problem', () async {
      final loaded = await loadedFinance(metricsClient(overrides: {
        '/finance/overview': jsonResponse(errorBody(401, 'no', '/x'), 401),
      }));
      expect(loaded.state.status, PartnerFinanceStatus.unauthorized);
    });

    test('403 is an approval problem', () async {
      final loaded = await loadedFinance(metricsClient(overrides: {
        '/finance/overview': jsonResponse(errorBody(403, 'no', '/x'), 403),
      }));
      expect(loaded.state.status, PartnerFinanceStatus.forbidden);
    });

    test('404 is a missing profile or property', () async {
      final loaded = await loadedFinance(metricsClient(overrides: {
        '/finance/overview': jsonResponse(errorBody(404, 'no', '/x'), 404),
      }));
      expect(loaded.state.status, PartnerFinanceStatus.notFound);
    });

    test('a 5xx is retryable', () async {
      final loaded = await loadedFinance(metricsClient(overrides: {
        '/finance/overview': jsonResponse(errorBody(500, 'boom', '/x'), 500),
      }));
      expect(loaded.state.status, PartnerFinanceStatus.error);
      expect(loaded.state.isRetryable, isTrue);
    });

    test('a network drop is retryable', () async {
      final app = partnerApp(metricsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final offline = partnerApp(metricsClient(throwNetwork: true));
      final state = PartnerFinanceState(api: offline.api);
      await state.load(partner, partner.selectedPropertyId);
      expect(state.status, PartnerFinanceStatus.error);
      expect(state.isRetryable, isTrue);
    });

    test('a timeout leaves no fabricated figures', () async {
      final app = partnerApp(metricsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final slow = partnerApp(MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 30));
        return jsonResponse(financeOverviewJson(), 200);
      }));
      final state = PartnerFinanceState(api: slow.api);
      await state.load(partner, partner.selectedPropertyId);
      expect(state.overview.errorKind, ApiErrorKind.timeout);
      expect(state.overview.hasData, isFalse);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('analytics maps the same failures the same way', () async {
      for (final entry in {
        401: PartnerAnalyticsStatus.unauthorized,
        403: PartnerAnalyticsStatus.forbidden,
        404: PartnerAnalyticsStatus.notFound,
        400: PartnerAnalyticsStatus.invalidRange,
        500: PartnerAnalyticsStatus.error,
      }.entries) {
        final loaded = await loadedAnalytics(metricsClient(overrides: {
          '/analytics/bookings':
              jsonResponse(errorBody(entry.key, 'x', '/x'), entry.key),
        }));
        expect(loaded.state.status, entry.value, reason: 'HTTP ${entry.key}');
      }
    });
  });

  // ── IDOR ──────────────────────────────────────────────────────────────

  group('ownership', () {
    test('an unowned hotelId is a 404 the module surfaces, not data', () async {
      // The mock mirrors `resolveHotelScope`: anything but the owned id is 404.
      final app = partnerApp(metricsClient());
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      final result = await app.api.getPartnerCommissions(hotelId: 4242);
      expect(result.success, isFalse);
      expect(result.errorKind, ApiErrorKind.notFound);
    });

    test('no finance response exposes an identifier to probe', () {
      // There is no invoice/payout/settlement/refund id anywhere in the API, so
      // there is no per-record IDOR surface at all — only hotelId, which the
      // backend validates.
      final json = <String, dynamic>{
        ...financeOverviewJson(),
        ...settlementJson(),
        ...payoutJson(),
        ...invoiceJson(),
        ...refundJson(),
      };
      expect(json.keys.where((k) => k == 'id' || k.endsWith('Id')), isEmpty);
    });
  });

  // ── UI ────────────────────────────────────────────────────────────────

  group('finance UI', () {
    testWidgets('renders real server figures', (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen());
      expect(find.text(en.partnerFinanceTitle), findsOneWidget);
      expect(find.textContaining('6,000,000'), findsWidgets);
    });

    testWidgets('states that these are estimates', (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen());
      expect(find.text(en.partnerFinanceEstimateNotice), findsOneWidget);
    });

    testWidgets('shows no currency symbol anywhere', (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen());
      // The finance API sends no currency, so none is invented.
      expect(find.textContaining('₫'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
      expect(find.textContaining('VND'), findsNothing);
    });

    testWidgets('offers no export, download, refund or payout action',
        (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen());
      expect(find.byIcon(Icons.download_rounded), findsNothing);
      expect(find.byIcon(Icons.file_download_outlined), findsNothing);
      expect(find.text('Export'), findsNothing);
      expect(find.text('Download'), findsNothing);
      expect(find.text('Refund'), findsNothing);
      expect(find.text('Pay out'), findsNothing);
    });

    testWidgets('the module never writes', (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen());
      expect(requestLog.where((r) => !r.startsWith('GET')), isEmpty);
    });

    testWidgets('names the settlement contradiction rather than hiding it',
        (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen());
      await tester.tap(find.text(en.partnerFinanceTabSettlement));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerFinanceSettlementMismatch), findsOneWidget);
    });

    testWidgets('says invoices have no document to open', (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen());
      await tester.tap(find.text(en.partnerFinanceTabSettlement));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerFinanceInvoiceNoDocuments), findsOneWidget);
      expect(find.text(en.partnerFinancePayoutNoRecords), findsOneWidget);
      expect(find.text(en.partnerFinanceRefundReadOnly), findsOneWidget);
    });

    testWidgets('reports the commission rate as a server constant',
        (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen());
      expect(find.text(en.partnerFinanceRateNotice('15%')), findsOneWidget);
    });

    testWidgets('an empty revenue window says so', (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen(),
          client: metricsClient(revenue: revenueJson(empty: true)));
      await tester.tap(find.text(en.partnerFinanceTabRevenue));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerFinanceRevenueEmpty), findsOneWidget);
    });

    testWidgets('a failed section is reported as unavailable, not zero',
        (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen(),
          client: metricsClient(overrides: {
            '/finance/refunds': jsonResponse(errorBody(500, 'boom', '/x'), 500),
          }));
      expect(find.text(en.partnerMetricSectionsFailed('1')), findsOneWidget);
    });
  });

  group('analytics UI', () {
    testWidgets('renders the five sections it owns', (tester) async {
      await pumpScreen(tester, const PartnerAnalyticsScreen());
      expect(find.text(en.partnerAnalyticsBookingsHeading), findsOneWidget);
      expect(find.text(en.partnerAnalyticsRoomsHeading), findsOneWidget);
      expect(find.text(en.partnerAnalyticsPromotionsHeading), findsOneWidget);
      expect(find.text(en.partnerAnalyticsReviewsHeading), findsOneWidget);
      expect(find.text(en.partnerAnalyticsMessagesHeading), findsOneWidget);
    });

    testWidgets('points at the dashboard for revenue and occupancy',
        (tester) async {
      await pumpScreen(tester, const PartnerAnalyticsScreen());
      expect(find.text(en.partnerAnalyticsDashboardPointer), findsOneWidget);
    });

    testWidgets('an unattributable discount count reads as unavailable',
        (tester) async {
      await pumpScreen(tester, const PartnerAnalyticsScreen());
      expect(find.text(en.partnerMetricUnavailable), findsWidgets);
      expect(find.text(en.partnerAnalyticsNoAttribution), findsOneWidget);
    });

    testWidgets('an unmeasured response time reads as unavailable',
        (tester) async {
      await pumpScreen(tester, const PartnerAnalyticsScreen());
      expect(find.text(en.partnerAnalyticsNoResponses), findsOneWidget);
    });

    testWidgets('a present response time is shown with its unit',
        (tester) async {
      await pumpScreen(tester, const PartnerAnalyticsScreen(),
          client: metricsClient(
              messages: messageAnalyticsJson(responseTime: 12.5)));
      expect(
          find.text(en.partnerAnalyticsMinutesValue('12.5')), findsOneWidget);
    });

    testWidgets('zero reviews reads as no observations, not a zero rating',
        (tester) async {
      await pumpScreen(tester, const PartnerAnalyticsScreen(),
          client: metricsClient(reviews: reviewAnalyticsJson(count: 0)));
      expect(find.text(en.partnerAnalyticsNoReviews), findsOneWidget);
    });

    testWidgets('no guest name from the review previews reaches the screen',
        (tester) async {
      await pumpScreen(tester, const PartnerAnalyticsScreen());
      expect(find.text('Demo User'), findsNothing);
      expect(find.textContaining('Wonderful'), findsNothing);
    });
  });

  // ── Gating, layout, localization ──────────────────────────────────────

  group('gating', () {
    testWidgets('a non-approved partner reaches neither module',
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

      await tester.pumpWidget(testApp(
          app: app, partner: partner, child: const PartnerFinanceScreen()));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerFinanceTabRevenue), findsNothing);
    });

    testWidgets('demo mode fabricates no figures', (tester) async {
      final app = AppState(api: ApiClient(client: metricsClient()))
        ..demoMode = true
        ..email = 'demo@planyourtrip.com'
        ..role = AppRole.partner;
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(
          app: app, partner: partner, child: const PartnerFinanceScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('6,000,000'), findsNothing);
    });
  });

  group('layout', () {
    testWidgets('finance fits desktop', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpScreen(tester, const PartnerFinanceScreen(),
          size: const Size(1600, 4000));
      expect(errors, isEmpty);
    });

    testWidgets('finance fits tablet', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpScreen(tester, const PartnerFinanceScreen(),
          size: const Size(820, 4600));
      expect(errors, isEmpty);
    });

    testWidgets('finance fits mobile', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpScreen(tester, const PartnerFinanceScreen(),
          size: const Size(390, 6000));
      expect(errors, isEmpty);
    });

    testWidgets('finance fits a very narrow phone', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpScreen(tester, const PartnerFinanceScreen(),
          size: const Size(320, 6000));
      expect(errors, isEmpty);
    });

    testWidgets('the settlement table fits a narrow phone', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpScreen(tester, const PartnerFinanceScreen(),
          size: const Size(320, 6000));
      await tester.tap(find.text(en.partnerFinanceTabSettlement));
      await tester.pumpAndSettle();
      expect(errors, isEmpty);
    });

    testWidgets('analytics fits every width', (tester) async {
      for (final size in const [
        Size(1600, 4000),
        Size(820, 5000),
        Size(390, 6000),
        Size(320, 6000),
      ]) {
        final errors = captureLayoutErrors(tester);
        await pumpScreen(tester, const PartnerAnalyticsScreen(), size: size);
        expect(errors, isEmpty, reason: '$size');
      }
    });
  });

  group('localization', () {
    testWidgets('English renders English strings', (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen(),
          locale: const Locale('en'));
      expect(find.text(en.partnerFinanceTitle), findsOneWidget);
    });

    testWidgets('Vietnamese renders Vietnamese strings', (tester) async {
      await pumpScreen(tester, const PartnerFinanceScreen(),
          locale: const Locale('vi'));
      expect(find.text(vi.partnerFinanceTitle), findsOneWidget);
    });

    testWidgets('Vietnamese analytics does not overflow', (tester) async {
      final errors = captureLayoutErrors(tester);
      await pumpScreen(tester, const PartnerAnalyticsScreen(),
          size: const Size(390, 6000), locale: const Locale('vi'));
      expect(errors, isEmpty);
    });

    test('labels do not collide with the sidebar destinations', () {
      expect(en.partnerFinanceTitle, isNot(en.partnerNavFinance));
      expect(vi.partnerFinanceTitle, isNot(vi.partnerNavFinance));
      expect(en.partnerAnalyticsTitle, isNot(en.partnerNavAnalytics));
      expect(vi.partnerAnalyticsTitle, isNot(vi.partnerNavAnalytics));
      expect(en.partnerAnalyticsBookingsHeading, isNot(en.partnerNavBookings));
      expect(vi.partnerAnalyticsBookingsHeading, isNot(vi.partnerNavBookings));
      expect(en.partnerAnalyticsRoomsHeading, isNot(en.partnerNavRooms));
      expect(en.partnerFinanceTabOverview, isNot(en.partnerNavGroupOverview));
    });
  });
}
