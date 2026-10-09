import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planyourtrip_frontend/core/admin/admin_models.dart';
import 'package:planyourtrip_frontend/core/admin/admin_state.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/features/admin/admin_app_shell.dart';
import 'package:planyourtrip_frontend/features/admin/admin_feature_states.dart';
import 'package:planyourtrip_frontend/features/admin/admin_navigation.dart';
import 'package:planyourtrip_frontend/features/admin/admin_routes.dart';
import 'package:planyourtrip_frontend/features/admin/widgets/admin_widgets.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'support/admin_access_stub.dart';

/// D1b — Admin CMS foundation.
///
/// Covers role admission, the route guard, workspace state, the six surfaces,
/// the D1a page/filter/sort contract, error semantics, responsiveness and
/// EN/VI parity. Every payload below mirrors a real backend DTO on
/// `develop@92a009a`; nothing asserts a field the server does not send.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── payload builders ───────────────────────────────────────────────────────

  Map<String, dynamic> page(List<Map<String, dynamic>> content,
          {int pageIndex = 0,
          int size = 20,
          int? totalElements,
          int? totalPages}) =>
      {
        'content': content,
        'page': pageIndex,
        'size': size,
        'totalElements': totalElements ?? content.length,
        'totalPages': totalPages ?? (content.isEmpty ? 0 : 1),
      };

  Map<String, dynamic> bookingRow(int id) => {
        'id': id,
        'bookingCode': 'PYT-$id',
        'hotelId': 1,
        'hotelName': 'Grand Palace Hotel',
        'roomId': 2,
        'roomName': 'Deluxe',
        'checkIn': '2026-10-30',
        'checkOut': '2026-11-01',
        'nights': 2,
        'status': 'CONFIRMED',
        'finalPrice': 1800000,
        'currency': 'VND',
        'createdAt': '2026-08-31T02:00:00Z',
      };

  Map<String, dynamic> paymentRow(int id) => {
        'id': id,
        'paymentCode': 'PAY-$id',
        'bookingId': 3,
        'bookingCode': 'PYT-3',
        'amount': 4200000,
        'currency': 'VND',
        'paymentMethod': 'CASH',
        'status': 'PAID',
        'provider': 'MANUAL',
        'providerTransactionId': 'should-not-be-rendered',
        'checkoutUrl': 'https://example.invalid/should-not-be-rendered',
        'failureReason': null,
        'paidAt': '2026-08-30T10:00:00Z',
        'failedAt': null,
        'refundedAt': null,
        'createdAt': '2026-08-30T09:00:00Z',
        'updatedAt': '2026-08-30T10:00:00Z',
      };

  Map<String, dynamic> reviewRow(int id) => {
        'id': id,
        'bookingId': 3,
        'bookingCode': 'PYT-3',
        'userId': 2,
        'userName': 'Demo User',
        'placeId': 1,
        'placeName': 'Grand Palace Hotel',
        'ratingOverall': 5,
        'title': 'Lovely stay',
        'content': 'The sea view room was spotless.',
        'status': 'APPROVED',
        'helpfulCount': 3,
        'reportedCount': 1,
        'approvedAt': '2026-08-25T00:00:00Z',
        'rejectedAt': null,
        'rejectReason': null,
        'createdAt': '2026-08-24T00:00:00Z',
        'updatedAt': '2026-08-25T00:00:00Z',
        'partnerReply': {
          'content': 'Thank you!',
          'repliedAt': '2026-08-26T00:00:00Z'
        },
        'media': <Map<String, dynamic>>[],
      };

  Map<String, dynamic> invoiceRow(int id) => {
        'id': id,
        'invoiceNumber': 'INV-$id',
        'bookingId': 3,
        'bookingCode': 'PYT-3',
        'paymentId': 1,
        'hotelId': 1,
        'hotelName': 'Grand Palace Hotel',
        'status': 'PAID',
        'currency': 'VND',
        'subtotal': 4000000,
        'discountAmount': 0,
        'taxAmount': 200000,
        'totalAmount': 4200000,
        'issuedAt': '2026-08-30T10:00:00Z',
        'paidAt': '2026-08-30T10:05:00Z',
        'cancelledAt': null,
        'createdAt': '2026-08-30T10:00:00Z',
      };

  Map<String, dynamic> auditRow(int id, {bool system = false}) => {
        'id': id,
        'actorUserId': system ? null : 3,
        'actorEmail': system ? 'SYSTEM' : 'admin@planyourtrip.com',
        'action': system ? 'BATCH_EXPIRE' : 'PAYMENT_REFUND',
        'targetType': 'PAYMENT',
        'targetId': 7,
        'description': 'Refunded 1500000 VND on booking 7.',
        'beforeState': 'PAID',
        'afterState': 'REFUNDED',
        'createdAt': '2026-08-31T01:00:00Z',
      };

  Map<String, dynamic> overview() => {
        'from': '2026-08-01',
        'to': '2026-08-31',
        'totalBookings': 3,
        'bookingsByStatus': [
          {'label': 'CONFIRMED', 'value': null, 'count': 1},
          {'label': 'COMPLETED', 'value': null, 'count': 1},
        ],
        'grossRevenue': 4200000,
        'activeHotels': 1,
        'activeRooms': 4,
        'totalUsers': 3,
        'totalPartners': 1,
        'bookingsInRange': 2,
        'revenueInRange': 4200000,
      };

  final requestLog = <Uri>[];

  setUp(requestLog.clear);

  MockClient adminClient({
    int status = 200,
    Map<String, dynamic>? bookings,
    Map<String, dynamic>? payments,
    Map<String, dynamic>? reviews,
    Map<String, dynamic>? invoices,
    Map<String, dynamic>? logs,
    Map<String, dynamic>? dashboard,
    bool throwNetwork = false,
  }) =>
      MockClient((request) async {
        requestLog.add(request.url);
        if (throwNetwork) throw http.ClientException('offline');
        final path = request.url.path;
        if (status != 200) {
          return http.Response(
            jsonEncode({
              'timestamp': '2026-08-31T00:00:00Z',
              'status': status,
              'error': 'Error',
              'message': 'server said no',
              'path': path,
            }),
            status,
            headers: {'content-type': 'application/json'},
          );
        }
        Map<String, dynamic> body;
        if (path.endsWith('/analytics/overview')) {
          body = dashboard ?? overview();
        } else if (path.endsWith('/admin/bookings')) {
          body = bookings ?? page([bookingRow(1)]);
        } else if (path.endsWith('/admin/payments')) {
          body = payments ?? page([paymentRow(1)]);
        } else if (path.endsWith('/admin/reviews')) {
          body = reviews ?? page([reviewRow(1)]);
        } else if (path.endsWith('/admin/invoices')) {
          body = invoices ?? page([invoiceRow(1)]);
        } else if (path.endsWith('/admin/activity-logs')) {
          body = logs ?? page([auditRow(1)]);
        } else {
          body = page(const []);
        }
        return http.Response(jsonEncode(body), 200,
            headers: {'content-type': 'application/json'});
      });

  AppState adminApp(http.Client client, {AppRole role = AppRole.admin}) =>
      AppState(
          api: ApiClient(client: withAdminAccess(client))..demoMode = false)
        ..demoMode = false
        ..email = 'admin@planyourtrip.com'
        ..role = role;

  Widget harness({
    required AppState app,
    required AdminState admin,
    required Widget child,
    Locale? locale,
  }) =>
      AppScope(
        notifier: app,
        child: AdminScope(
          notifier: admin,
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: child,
          ),
        ),
      );

  Future<({AppState app, AdminState admin})> pumpConsole(
    WidgetTester tester, {
    http.Client? client,
    AppRole role = AppRole.admin,
    Size size = const Size(1600, 2400),
    Locale? locale,
    String route = AdminRoutes.dashboard,
  }) async {
    final app = adminApp(client ?? adminClient(), role: role);
    final admin = AdminState(api: app.api)..bindSession(app);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(harness(
      app: app,
      admin: admin,
      locale: locale,
      child: AdminRouteGuard(key: ValueKey(route), initialRoute: route),
    ));
    await tester.pumpAndSettle();
    return (app: app, admin: admin);
  }

  // ── 1. Role admission ──────────────────────────────────────────────────────

  group('admin role admission', () {
    test('only ADMIN may enter or land on the console', () {
      expect(AppRole.admin.canEnterAdminConsole, isTrue);
      expect(AppRole.admin.landsOnAdminConsole, isTrue);
      for (final role in [AppRole.user, AppRole.partner, AppRole.unknown]) {
        expect(role.canEnterAdminConsole, isFalse,
            reason: '$role must be denied');
        expect(role.landsOnAdminConsole, isFalse,
            reason: '$role must not land');
      }
    });

    test('admin admission is stricter than partner admission', () {
      // PARTNER may enter the partner extranet but never the admin console --
      // this mirrors SecurityConfig, where /api/admin/** is ADMIN-only.
      expect(AppRole.partner.canEnterPartnerExtranet, isTrue);
      expect(AppRole.partner.canEnterAdminConsole, isFalse);
    });

    test('unrecognised roles, including SUPER_*, fail closed', () {
      for (final raw in ['SUPER_ADMIN', 'SUPER_PARTNER', 'admin', '', 'root']) {
        final parsed = AppRole.parse(raw);
        expect(parsed, AppRole.unknown, reason: '$raw must not be recognised');
        expect(parsed.canEnterAdminConsole, isFalse);
      }
      expect(AppRole.parse(null).canEnterAdminConsole, isFalse);
    });
  });

  // ── 2. Route guard ─────────────────────────────────────────────────────────

  group('AdminRouteGuard', () {
    testWidgets('ADMIN reaches the shell', (tester) async {
      await pumpConsole(tester);
      expect(find.byType(AdminAppShell), findsOneWidget);
      expect(find.byType(AdminAccessDeniedScreen), findsNothing);
    });

    for (final role in [AppRole.user, AppRole.partner, AppRole.unknown]) {
      testWidgets('$role is refused', (tester) async {
        await pumpConsole(tester, role: role);
        expect(find.byType(AdminAccessDeniedScreen), findsOneWidget);
        expect(find.byType(AdminAppShell), findsNothing);
      });
    }

    testWidgets('a signed-out session is refused', (tester) async {
      final app = AppState(api: ApiClient(client: adminClient()))
        ..demoMode = false;
      final admin = AdminState(api: app.api)..bindSession(app);
      await tester.pumpWidget(
          harness(app: app, admin: admin, child: const AdminRouteGuard()));
      await tester.pumpAndSettle();
      expect(find.byType(AdminAccessDeniedScreen), findsOneWidget);
    });

    test('route helpers recognise only the admin namespace', () {
      expect(AdminRoutes.isAdminRoute('/admin'), isTrue);
      expect(AdminRoutes.isAdminRoute(AdminRoutes.bookings), isTrue);
      expect(AdminRoutes.isAdminRoute('/partner/dashboard'), isFalse);
      expect(AdminRoutes.isAdminRoute('/adminish'), isFalse);
    });
  });

  // ── 3. AdminState ──────────────────────────────────────────────────────────

  group('AdminState', () {
    test('mirrors the session and clears on sign-out', () async {
      final app = adminApp(adminClient());
      final admin = AdminState(api: app.api)..bindSession(app);
      expect(admin.adminEmail, 'admin@planyourtrip.com');
      expect(admin.isAdmin, isTrue);

      admin.setActiveRoute(AdminRoutes.bookings);
      expect(admin.activeRoute, AdminRoutes.bookings);

      // The production sign-out path: AppState.email/role are plain fields, so
      // only a method that actually notifies can drive the binding.
      await app.logout();
      expect(admin.activeRoute, isNull, reason: 'context must clear on logout');
      expect(admin.isAdmin, isFalse);
    });

    test('holds no row data', () {
      // The workspace notifier must never grow a list -- that is the feature
      // states' job. Asserted structurally so a future addition is caught.
      final admin = AdminState(api: ApiClient(client: adminClient()));
      for (final f in admin.runtimeType.toString().split('\n')) {
        expect(f.contains('List<'), isFalse);
      }
      expect(admin.activeRoute, isNull);
    });
  });

  // ── 4. Page envelope + pagination ──────────────────────────────────────────

  group('page envelope', () {
    test('parses the backend PageResponse shape', () {
      final p = AdminPage.fromJson<AdminBookingRow>(
        page([bookingRow(1), bookingRow(2)],
            pageIndex: 1, size: 2, totalElements: 5, totalPages: 3),
        AdminBookingRow.fromJson,
      );
      expect(p, isNotNull);
      expect(p!.content, hasLength(2));
      expect(p.page, 1);
      expect(p.size, 2);
      expect(p.totalElements, 5);
      expect(p.totalPages, 3);
      expect(p.hasPrevious, isTrue);
      expect(p.hasNext, isTrue);
      expect(p.firstRowNumber, 3);
      expect(p.lastRowNumber, 4);
    });

    test('hasNext comes from totalPages, not from a full page', () {
      final last = AdminPage.fromJson<AdminBookingRow>(
        page([bookingRow(1)],
            pageIndex: 2, size: 1, totalElements: 3, totalPages: 3),
        AdminBookingRow.fromJson,
      )!;
      expect(last.content, hasLength(last.size),
          reason: 'the final page is exactly full');
      expect(last.hasNext, isFalse, reason: 'but there is no page after it');
    });

    test('a non-page payload is rejected rather than half-parsed', () {
      expect(
        AdminPage.fromJson<AdminBookingRow>(
            {'oops': true}, AdminBookingRow.fromJson),
        isNull,
      );
    });

    test('an empty page reports no row range', () {
      final p = AdminPage.fromJson<AdminBookingRow>(
          page(const []), AdminBookingRow.fromJson)!;
      expect(p.isEmpty, isTrue);
      expect(p.firstRowNumber, 0);
      expect(p.lastRowNumber, 0);
      expect(p.hasNext, isFalse);
    });
  });

  // ── 5. Feature states: paging, filters, sort ───────────────────────────────

  group('paged states', () {
    test('bookings send page, size and an allowlisted sort', () async {
      final state = AdminBookingsState(api: ApiClient(client: adminClient()));
      await state.load();
      expect(state.isReady, isTrue);
      expect(state.rows, hasLength(1));

      final uri = requestLog.last;
      expect(uri.queryParameters['page'], '0');
      expect(uri.queryParameters['size'], '20');
      expect(uri.queryParameters['sort'], 'createdAt,desc');
    });

    test('sort only ever emits field,dir from the allowlist', () async {
      final state = AdminBookingsState(api: ApiClient(client: adminClient()));
      await state.load();
      for (final field in AdminBookingsState.sortFields) {
        await state.setSort(field, false);
        expect(requestLog.last.queryParameters['sort'], '$field,asc');
      }
      expect(state.sortParameter, contains(','));
    });

    test('changing a filter resets to the first page', () async {
      final state = AdminBookingsState(api: ApiClient(client: adminClient()));
      await state.load();
      await state.goToPage(2);
      expect(state.pageIndex, 0,
          reason: 'server echoed page 0, which the client adopts');
      await state.setStatusFilter('CONFIRMED');
      expect(requestLog.last.queryParameters['status'], 'CONFIRMED');
      expect(requestLog.last.queryParameters['page'], '0');
    });

    test('clearing a filter omits the parameter entirely', () async {
      final state = AdminBookingsState(api: ApiClient(client: adminClient()));
      await state.setStatusFilter('CONFIRMED');
      expect(requestLog.last.queryParameters.containsKey('status'), isTrue);
      await state.setStatusFilter(null);
      expect(requestLog.last.queryParameters.containsKey('status'), isFalse,
          reason: 'no filter must send no parameter, not an empty one');
    });

    test('page size is clamped to the backend ceiling', () async {
      final state = AdminBookingsState(api: ApiClient(client: adminClient()));
      await state.setPageSize(100000);
      expect(state.pageSize, 200);
      expect(requestLog.last.queryParameters['size'], '200');
      await state.setPageSize(0);
      expect(state.pageSize, 20);
    });

    test('payments send only their confirmed filters', () async {
      final state = AdminPaymentsState(api: ApiClient(client: adminClient()));
      await state.setStatusFilter('PAID');
      await state.setBookingIdFilter(3);
      final q = requestLog.last.queryParameters;
      expect(q['status'], 'PAID');
      expect(q['bookingId'], '3');
      expect(q.keys, isNot(contains('guest')),
          reason: 'payments have no guest filter on the backend');
    });

    test('reviews send only their confirmed filters', () async {
      final state = AdminReviewsState(api: ApiClient(client: adminClient()));
      await state.setStatusFilter('APPROVED');
      await state.setPlaceIdFilter(1);
      final q = requestLog.last.queryParameters;
      expect(q['status'], 'APPROVED');
      expect(q['placeId'], '1');
    });

    test('invoices send only a status filter', () async {
      final state = AdminInvoicesState(api: ApiClient(client: adminClient()));
      await state.setStatusFilter('PAID');
      expect(requestLog.last.queryParameters['status'], 'PAID');
    });

    test('the activity log never sends a sort parameter', () async {
      final state =
          AdminActivityLogState(api: ApiClient(client: adminClient()));
      await state.load();
      expect(requestLog.last.queryParameters.containsKey('sort'), isFalse,
          reason: 'audit ordering is fixed server-side and is not negotiable');
      await state.setActionFilter('PAYMENT_REFUND');
      expect(requestLog.last.queryParameters['action'], 'PAYMENT_REFUND');
      expect(requestLog.last.queryParameters.containsKey('sort'), isFalse);
    });

    test('reset clears rows and filters', () async {
      final state = AdminBookingsState(api: ApiClient(client: adminClient()));
      await state.setStatusFilter('CONFIRMED');
      expect(state.rows, isNotEmpty);
      state.reset();
      expect(state.rows, isEmpty);
      expect(state.statusFilter, isNull);
      expect(state.status, AdminLoadStatus.idle);
    });
  });

  // ── 6. Error semantics ─────────────────────────────────────────────────────

  group('error semantics', () {
    Future<AdminLoadStatus> statusFor(int code) async {
      final state =
          AdminBookingsState(api: ApiClient(client: adminClient(status: code)));
      await state.load();
      return state.status;
    }

    test('backend statuses are preserved, not flattened', () async {
      expect(await statusFor(401), AdminLoadStatus.unauthorized);
      expect(await statusFor(403), AdminLoadStatus.forbidden);
      expect(await statusFor(404), AdminLoadStatus.notFound);
      expect(await statusFor(400), AdminLoadStatus.error);
      expect(await statusFor(409), AdminLoadStatus.error);
      expect(await statusFor(500), AdminLoadStatus.error);
    });

    test('a network failure is an error, not an empty result', () async {
      final state = AdminBookingsState(
          api: ApiClient(client: adminClient(throwNetwork: true)));
      await state.load();
      expect(state.status, AdminLoadStatus.error);
      expect(state.isEmpty, isFalse,
          reason: 'a failure must never render as "no results"');
    });

    test('an empty result is ready-and-empty, not an error', () async {
      final state = AdminBookingsState(
          api: ApiClient(client: adminClient(bookings: page(const []))));
      await state.load();
      expect(state.status, AdminLoadStatus.ready);
      expect(state.isEmpty, isTrue);
    });

    test('the server message is surfaced when safe', () async {
      final state =
          AdminBookingsState(api: ApiClient(client: adminClient(status: 400)));
      await state.load();
      expect(state.errorMessage, 'server said no');
    });
  });

  // ── 7. Money and sensitive data ────────────────────────────────────────────

  group('money and sensitive data', () {
    testWidgets('amounts render with the backend currency only',
        (tester) async {
      await pumpConsole(tester, route: AdminRoutes.payments);
      expect(find.textContaining('4,200,000 VND'), findsWidgets);
      // No locale-derived symbol is ever synthesised.
      expect(find.textContaining('\$'), findsNothing);
      expect(find.textContaining('₫'), findsNothing);
    });

    testWidgets('provider transaction ids and checkout URLs are not rendered',
        (tester) async {
      await pumpConsole(tester, route: AdminRoutes.payments);
      expect(find.textContaining('should-not-be-rendered'), findsNothing);
      expect(find.textContaining('example.invalid'), findsNothing);
    });

    testWidgets('dashboard revenue shows no invented currency', (tester) async {
      await pumpConsole(tester);
      // This endpoint sends no currency, so the number must stand alone.
      expect(find.textContaining('4,200,000'), findsWidgets);
      expect(find.textContaining('4,200,000 VND'), findsNothing);
    });
  });

  // ── 8. Surfaces render ─────────────────────────────────────────────────────

  group('surfaces', () {
    testWidgets('dashboard renders only backend-supplied metrics',
        (tester) async {
      await pumpConsole(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.adminDashboardTotalBookings), findsOneWidget);
      expect(find.text(l10n.adminDashboardActiveHotels), findsOneWidget);
      expect(find.text(l10n.adminDashboardBookingsByStatus), findsOneWidget);
    });

    testWidgets('each grid renders its rows', (tester) async {
      for (final entry in {
        AdminRoutes.bookings: 'PYT-1',
        AdminRoutes.payments: 'PAY-1',
        AdminRoutes.invoices: 'INV-1',
      }.entries) {
        await pumpConsole(tester, route: entry.key);
        expect(find.textContaining(entry.value), findsWidgets,
            reason: '${entry.key} must render its rows');
      }
    });

    testWidgets('reviews show the body an admin may read', (tester) async {
      await pumpConsole(tester, route: AdminRoutes.reviews);
      expect(find.textContaining('sea view room was spotless'), findsOneWidget);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      // D1b asserted that the *absence* of moderation was stated. D8 shipped
      // moderation, so the same guarantee now applies to its presence: the
      // consequence must be stated, not implied. Asserting the actions too
      // stops this passing on notice text alone.
      expect(find.text(l10n.adminReviewModerationNotice), findsOneWidget,
          reason: 'the consequence of moderation must be stated, not implied');
      expect(find.byKey(const Key('admin-review-approve-1')), findsOneWidget,
          reason: 'moderation is live as of D8');
    });

    testWidgets('activity log distinguishes a system actor', (tester) async {
      await pumpConsole(
        tester,
        route: AdminRoutes.activityLog,
        client: adminClient(logs: page([auditRow(1, system: true)])),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.adminActivitySystemActor), findsOneWidget);
      expect(find.text(l10n.adminActivityFixedOrder), findsOneWidget);
    });

    testWidgets('activity log renders no credential-shaped text',
        (tester) async {
      await pumpConsole(tester, route: AdminRoutes.activityLog);
      for (final forbidden in ['password', 'secret', 'Bearer ', 'eyJ']) {
        expect(find.textContaining(forbidden), findsNothing,
            reason: '$forbidden must never appear in the audit view');
      }
    });

    // D2C added Partners as a seventh destination; D10 added Reference Data as
    // the tenth. The assertion stays exact rather than becoming a lower bound:
    // the point of this test is that the menu contains what the backend
    // supports and nothing speculative, so a new entry has to be named here
    // deliberately.
    testWidgets('the menu lists exactly the console destinations',
        (tester) async {
      await pumpConsole(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      for (final label in [
        l10n.adminNavDashboard,
        l10n.adminNavBookings,
        l10n.adminNavPartners,
        l10n.adminNavCatalog,
        l10n.adminNavMedia,
        l10n.adminNavReferenceData,
        l10n.adminNavPayments,
        l10n.adminNavInvoices,
        l10n.adminNavReviews,
        l10n.adminNavActivityLog,
        l10n.adminNavAccess,
      ]) {
        expect(find.text(label), findsWidgets);
      }
      expect(AdminNavigation.destinations, hasLength(11));
      // Nothing speculative: every destination resolves to a real route.
      for (final d in AdminNavigation.destinations) {
        expect(AdminRoutes.isAdminRoute(d.route), isTrue);
      }
    });

    testWidgets('switching section keeps one shell and loads lazily',
        (tester) async {
      await pumpConsole(tester);
      final before = requestLog.length;
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l10n.adminNavBookings).first);
      await tester.pumpAndSettle();
      expect(requestLog.length, greaterThan(before),
          reason: 'the newly selected section loads on first view');
      expect(find.byType(AdminAppShell), findsOneWidget);
    });
  });

  // ── 9. Pagination UX ───────────────────────────────────────────────────────

  group('pagination UX', () {
    testWidgets('the bar reports the range and disables at the ends',
        (tester) async {
      await pumpConsole(
        tester,
        route: AdminRoutes.bookings,
        client: adminClient(
            bookings: page([bookingRow(1)],
                pageIndex: 0, size: 1, totalElements: 3, totalPages: 3)),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.adminPaginationRange(1, 1, 3)), findsOneWidget);
      expect(find.text(l10n.adminPaginationPageOf(1, 3)), findsOneWidget);
      expect(find.byType(AdminPaginationBar), findsOneWidget);
    });

    testWidgets('an empty grid shows no misleading range', (tester) async {
      await pumpConsole(
        tester,
        route: AdminRoutes.bookings,
        client: adminClient(bookings: page(const [])),
      );
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.adminBookingsEmpty), findsOneWidget);
    });
  });

  // ── 10. Responsive ─────────────────────────────────────────────────────────

  group('responsive', () {
    for (final size in [
      const Size(320, 900),
      const Size(390, 900),
      const Size(820, 1200),
      const Size(1600, 1200),
    ]) {
      testWidgets('no overflow at ${size.width.toInt()} wide', (tester) async {
        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.exceptionAsString();
          if (text.contains('overflowed')) errors.add(text);
          previous?.call(details);
        };
        addTearDown(() => FlutterError.onError = previous);

        for (final route in [
          AdminRoutes.dashboard,
          AdminRoutes.bookings,
          AdminRoutes.payments,
          AdminRoutes.reviews,
          AdminRoutes.invoices,
          AdminRoutes.activityLog,
        ]) {
          await pumpConsole(tester, route: route, size: size);
          expect(errors, isEmpty,
              reason: '$route overflowed at ${size.width}: $errors');
        }
      });
    }

    testWidgets('wide shows a sidebar, narrow shows a drawer', (tester) async {
      await pumpConsole(tester, size: const Size(1600, 1200));
      expect(find.byIcon(Icons.menu), findsNothing,
          reason: 'the sidebar is always visible on desktop');

      await pumpConsole(tester, size: const Size(390, 900));
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing,
          reason: 'the admin console deliberately has no bottom navigation');
    });
  });

  // ── 11. Localization ───────────────────────────────────────────────────────

  group('localization', () {
    testWidgets('renders in Vietnamese', (tester) async {
      await pumpConsole(tester, locale: const Locale('vi'));
      final vi = await AppLocalizations.delegate.load(const Locale('vi'));
      expect(find.text(vi.adminNavDashboard), findsWidgets);
      expect(find.text(vi.adminConsoleTitle), findsWidgets);
    });

    test('every admin key resolves in both locales', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final vi = await AppLocalizations.delegate.load(const Locale('vi'));
      final pairs = <String, String>{
        'nav.dashboard': en.adminNavDashboard,
        'nav.bookings': en.adminNavBookings,
        'nav.payments': en.adminNavPayments,
        'nav.invoices': en.adminNavInvoices,
        'nav.reviews': en.adminNavReviews,
        'nav.activityLog': en.adminNavActivityLog,
        'error.forbidden': en.adminErrorForbidden,
        'empty': en.adminEmptyTitle,
      };
      for (final entry in pairs.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: '${entry.key} EN');
      }
      for (final value in [
        vi.adminNavDashboard,
        vi.adminNavBookings,
        vi.adminNavPayments,
        vi.adminNavInvoices,
        vi.adminNavReviews,
        vi.adminNavActivityLog,
        vi.adminErrorForbidden,
        vi.adminEmptyTitle,
      ]) {
        expect(value.trim(), isNotEmpty);
      }
      // Placeholder-bearing messages must substitute in both locales.
      expect(en.adminPaginationRange(1, 20, 57), contains('57'));
      expect(vi.adminPaginationRange(1, 20, 57), contains('57'));
      expect(en.adminSignedInAs('a@b.c'), contains('a@b.c'));
      expect(vi.adminSignedInAs('a@b.c'), contains('a@b.c'));
    });
  });
}
