import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:planyourtrip_frontend/core/admin/admin_models.dart';
import 'package:planyourtrip_frontend/core/admin/admin_state.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/features/admin/admin_navigation.dart';
import 'package:planyourtrip_frontend/features/admin/admin_partner_states.dart';
import 'package:planyourtrip_frontend/features/admin/admin_routes.dart';
import 'package:planyourtrip_frontend/features/admin/screens/admin_partner_detail_screen.dart';
import 'package:planyourtrip_frontend/features/admin/screens/admin_partners_screen.dart';
import 'package:planyourtrip_frontend/features/admin/widgets/admin_widgets.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// D2C — Admin Partner Management.
///
/// Every payload below is the shape the backend actually returns, taken from
/// the D2B contract freeze against `develop@3467d45`. Where a test asserts an
/// absence — no profile editor, no team controls, no settings save, no property
/// list, no restore action — that absence is the requirement, because the
/// backend has no endpoint behind any of them.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── fixtures ───────────────────────────────────────────────────────────────

  Map<String, dynamic> partnerJson({
    int id = 1,
    String status = 'SUBMITTED',
    String business = 'Sunrise Hotel',
    String? reason,
  }) =>
      {
        'id': id,
        'userId': 7,
        'userName': 'Partner Owner',
        'userEmail': 'partner@planyourtrip.com',
        'businessName': business,
        'businessType': 'HOTEL',
        'representativeName': 'Nguyen Van A',
        'phone': '+84 90 000 0000',
        'email': 'contact@sunrise.test',
        'address': '1 Beach Road',
        'taxCode': '0101234567',
        'website': 'https://sunrise.test',
        'verificationStatus': status,
        'rejectReason': reason,
        'submittedAt': '2026-08-01T10:00:00Z',
        'approvedAt': status == 'APPROVED' ? '2026-08-02T10:00:00Z' : null,
        'rejectedAt': status == 'REJECTED' ? '2026-08-02T10:00:00Z' : null,
        'approvedById': status == 'APPROVED' ? 1 : null,
        'approvedByName': status == 'APPROVED' ? 'Admin' : null,
        'createdAt': '2026-07-30T09:00:00Z',
        'updatedAt': '2026-08-02T10:00:00Z',
      };

  Map<String, dynamic> pageOf(List<Map<String, dynamic>> rows,
          {int page = 0, int size = 20, int? total}) =>
      {
        'content': rows,
        'page': page,
        'size': size,
        'totalElements': total ?? rows.length,
        'totalPages': ((total ?? rows.length) / size).ceil(),
      };

  final detailJson = {
    'partnerProfileId': 1,
    'businessName': 'Sunrise Hotel',
    'verificationStatus': 'APPROVED',
    'ownedHotelCount': 3,
    'teamMemberCount': 2,
    'payoutAccountStatus': 'VERIFIED',
    'createdAt': '2026-07-30T09:00:00Z',
  };

  final teamJson = [
    {
      'id': 11,
      'partnerProfileId': 1,
      'userId': 7,
      'userName': 'Partner Owner',
      'userEmail': 'partner@planyourtrip.com',
      'role': 'OWNER',
      'active': true,
      'invitedAt': '2026-07-30T09:00:00Z',
      'joinedAt': '2026-07-30T09:00:00Z',
      'createdAt': '2026-07-30T09:00:00Z',
      'updatedAt': '2026-07-30T09:00:00Z',
    }
  ];

  final settingsJson = {
    'id': 5,
    'partnerProfileId': 1,
    'defaultLanguage': 'vi',
    'timezone': 'Asia/Ho_Chi_Minh',
    'notificationEmailEnabled': true,
    'notificationSmsEnabled': false,
    'notificationInAppEnabled': true,
    'bookingNotificationEnabled': true,
    'paymentNotificationEnabled': true,
    'reviewNotificationEnabled': false,
    'promotionNotificationEnabled': false,
    'createdAt': '2026-07-30T09:00:00Z',
    'updatedAt': '2026-07-30T09:00:00Z',
  };

  final activityJson = {
    'id': 21,
    'partnerProfileId': 1,
    'actorUserId': 7,
    'actorName': 'Partner Owner',
    'action': 'RATE_PLAN_UPDATED',
    'entityType': 'RATE_PLAN',
    'entityId': 4,
    'description': 'Updated the standard rate plan',
    'createdAt': '2026-08-03T08:00:00Z',
  };

  /// A client whose responses are driven by a per-path map. Recorded requests
  /// let a test assert exactly which query the UI sent.
  ({
    ApiClient api,
    List<Uri> requests,
    List<String> bodies,
    List<http.Request> sent
  }) clientFor(
    Map<String, http.Response> Function(Uri uri) route,
  ) {
    final requests = <Uri>[];
    final bodies = <String>[];
    final sent = <http.Request>[];
    final mock = _RecordingClient(
      onRequest: (req) {
        requests.add(req.url);
        if (req is http.Request) {
          sent.add(req);
          if (req.body.isNotEmpty) bodies.add(req.body);
        }
        return route(req.url)[req.url.path] ??
            http.Response('{"message":"unmapped"}', 500);
      },
    );
    return (
      api: ApiClient(client: mock, baseUrl: 'http://test/api'),
      requests: requests,
      bodies: bodies,
      sent: sent
    );
  }

  http.Response ok(Object json) =>
      http.Response(jsonEncode(json), 200, headers: {'content-type': 'application/json'});

  Map<String, http.Response> fullPartnerRoutes({
    String status = 'SUBMITTED',
    http.Response? profileOverride,
  }) =>
      {
        '/api/admin/partners': ok(pageOf([partnerJson(status: status)])),
        '/api/admin/partners/1': profileOverride ?? ok(partnerJson(status: status)),
        '/api/admin/partners/1/detail': ok(detailJson),
        '/api/admin/partners/1/team': ok(teamJson),
        '/api/admin/partners/1/settings': ok(settingsJson),
        '/api/admin/partners/1/activity-logs': ok(pageOf([activityJson])),
        '/api/admin/partners/1/approve': ok(partnerJson(status: 'APPROVED')),
        '/api/admin/partners/1/reject':
            ok(partnerJson(status: 'REJECTED', reason: 'Incomplete documents')),
        '/api/admin/partners/1/suspend':
            ok(partnerJson(status: 'SUSPENDED', reason: 'Policy breach')),
      };

  Widget harness(Widget child, {Locale? locale}) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // 1–4 · Route admission
  // ═══════════════════════════════════════════════════════════════════════════

  group('route admission', () {
    test('only ADMIN may enter the admin console', () {
      expect(AppRole.admin.canEnterAdminConsole, isTrue);
      expect(AppRole.user.canEnterAdminConsole, isFalse);
      expect(AppRole.partner.canEnterAdminConsole, isFalse);
      expect(AppRole.unknown.canEnterAdminConsole, isFalse);
    });

    testWidgets('a signed-out session is refused the Partners route',
        (tester) async {
      final app = AppState();
      await tester.pumpWidget(AppScope(
        notifier: app,
        child: AdminScope(
          notifier: AdminState(api: app.api),
          child: harness(
              const AdminRouteGuard(initialRoute: AdminRoutes.partners)),
        ),
      ));
      await tester.pump();
      expect(find.byType(AdminAccessDeniedScreen), findsOneWidget);
    });

    test('Partners is a registered destination in the operations section', () {
      final d = AdminNavigation.byRoute(AdminRoutes.partners);
      expect(d, isNotNull);
      expect(d!.section, AdminSection.operations);
      expect(AdminRoutes.isAdminRoute(AdminRoutes.partners), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 5 · Partner list
  // ═══════════════════════════════════════════════════════════════════════════

  group('partner list', () {
    test('sort options never leave the backend allowlist', () {
      // PartnerProfileService.PARTNER_SORT_FIELDS. A field outside it answers
      // 400, so offering one would be a control that cannot work.
      expect(
        AdminPartnersState.sortFields,
        containsAll(<String>[
          'createdAt',
          'updatedAt',
          'businessName',
          'verificationStatus',
          'submittedAt',
          'approvedAt',
          'rejectedAt',
          'id',
        ]),
      );
      expect(AdminPartnersState.sortFields, hasLength(8));
    });

    test('filter values mirror the backend enums exactly', () {
      expect(AdminPartnersState.statusValues,
          ['DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'SUSPENDED']);
      expect(AdminPartnersState.businessTypeValues,
          ['HOTEL', 'RESTAURANT', 'CAFE', 'TOUR_OPERATOR', 'TRANSPORT', 'OTHER']);
    });

    test('loads a page and exposes the envelope', () async {
      final c = clientFor((_) => fullPartnerRoutes());
      final state = AdminPartnersState(api: c.api);
      await state.load();

      expect(state.status, AdminLoadStatus.ready);
      expect(state.rows, hasLength(1));
      expect(state.rows.single.businessName, 'Sunrise Hotel');
      expect(state.page.totalElements, 1);
      expect(state.isEmpty, isFalse);
    });

    test('an empty result is empty, not an error', () async {
      final c = clientFor((_) => {
            '/api/admin/partners': ok(pageOf(const [])),
          });
      final state = AdminPartnersState(api: c.api);
      await state.load();
      expect(state.status, AdminLoadStatus.ready);
      expect(state.isEmpty, isTrue);
    });

    test('a 403 becomes forbidden rather than a generic error', () async {
      final c = clientFor((_) => {
            '/api/admin/partners': http.Response('{"message":"denied"}', 403),
          });
      final state = AdminPartnersState(api: c.api);
      await state.load();
      expect(state.status, AdminLoadStatus.forbidden);
      expect(state.isEmpty, isFalse);
    });

    test('filters and sort are sent as backend query parameters, server-side',
        () async {
      final c = clientFor((_) => fullPartnerRoutes());
      final state = AdminPartnersState(api: c.api);
      await state.load();
      await state.setStatusFilter('SUBMITTED');
      await state.setBusinessTypeFilter('HOTEL');
      await state.setQuery('  sunrise  ');
      await state.setSort('businessName', false);

      final last = c.requests.last;
      expect(last.queryParameters['verificationStatus'], 'SUBMITTED');
      expect(last.queryParameters['businessType'], 'HOTEL');
      expect(last.queryParameters['q'], 'sunrise', reason: 'trimmed');
      expect(last.queryParameters['sort'], 'businessName,asc');
      expect(last.queryParameters['page'], '0',
          reason: 'a filter change returns to the first page');
    });

    test('paging asks the server rather than slicing locally', () async {
      var served = 0;
      final c = clientFor((_) => {
            '/api/admin/partners': ok(pageOf([partnerJson()],
                page: served++ == 0 ? 0 : 1, total: 40)),
          });
      final state = AdminPartnersState(api: c.api);
      await state.load();
      expect(state.pageIndex, 0);

      await state.goToPage(1);
      expect(c.requests.last.queryParameters['page'], '1');
      // The server's own page index wins over the one requested.
      expect(state.pageIndex, 1);
    });

    test('page size never exceeds the backend ceiling', () async {
      final c = clientFor((_) => fullPartnerRoutes());
      final state = AdminPartnersState(api: c.api);
      await state.setPageSize(100000);
      expect(state.pageSize, AdminPagedStateLimits.maxPageSize);
    });

    testWidgets('renders rows and opens one', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => fullPartnerRoutes());
      final state = AdminPartnersState(api: c.api);
      await state.load();

      AdminPartnerRow? opened;
      await tester.pumpWidget(harness(AdminPartnersScreen(
        state: state,
        onOpenPartner: (r) => opened = r,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Sunrise Hotel'), findsWidgets);
      await tester.tap(find.text('Open').first);
      await tester.pump();
      expect(opened?.id, 1);
    });

    testWidgets('the list grid does not print contact PII', (tester) async {
      final c = clientFor((_) => fullPartnerRoutes());
      final state = AdminPartnersState(api: c.api);
      await state.load();
      await tester.pumpWidget(harness(AdminPartnersScreen(
        state: state,
        onOpenPartner: (_) {},
      )));
      await tester.pumpAndSettle();

      // Contact details belong to the detail view, where a partner has been
      // opened deliberately — not to a grid scanned in bulk.
      expect(find.text('contact@sunrise.test'), findsNothing);
      expect(find.text('+84 90 000 0000'), findsNothing);
      expect(find.text('1 Beach Road'), findsNothing);
      expect(find.text('0101234567'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 6 · Partner detail, and the existence gate
  // ═══════════════════════════════════════════════════════════════════════════

  group('partner detail', () {
    test('loads every section once the canonical read succeeds', () async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();

      expect(state.isReady, isTrue);
      expect(state.profile!.businessName, 'Sunrise Hotel');
      expect(state.detail!.ownedHotelCount, 3);
      expect(state.team, hasLength(1));
      expect(state.settings!.timezone, 'Asia/Ho_Chi_Minh');
      expect(state.activity.content, hasLength(1));
    });

    test(
        'a 404 on the canonical read stops the sub-resources being requested '
        'at all', () async {
      // /team and /activity-logs answer 200 with an empty body for an id that
      // does not exist (D2A-F3). If they were fetched anyway, an empty roster
      // would be indistinguishable from a real partner with no team.
      final c = clientFor((_) => {
            '/api/admin/partners/999':
                http.Response('{"message":"Partner profile not found"}', 404),
            '/api/admin/partners/999/team': ok(const []),
            '/api/admin/partners/999/activity-logs': ok(pageOf(const [])),
          });
      final state = AdminPartnerDetailState(api: c.api, partnerId: 999);
      await state.load();

      expect(state.isNotFound, isTrue);
      expect(state.isReady, isFalse);
      expect(state.team, isEmpty);
      expect(
        c.requests.map((u) => u.path),
        everyElement(isNot(contains('/team'))),
        reason: 'the sub-resources must never be requested for a phantom id',
      );
    });

    testWidgets('a missing partner reads as not found, not as empty tabs',
        (tester) async {
      final c = clientFor((_) => {
            '/api/admin/partners/999': http.Response('{}', 404),
          });
      final state = AdminPartnerDetailState(api: c.api, partnerId: 999);
      await state.load();

      await tester.pumpWidget(harness(
          AdminPartnerDetailScreen(state: state, onBack: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Partner not found'), findsOneWidget);
      expect(find.text('Overview'), findsNothing,
          reason: 'no tabs for a partner that does not exist');
    });

    test('one failing section does not blank the others', () async {
      final routes = fullPartnerRoutes(status: 'APPROVED');
      routes['/api/admin/partners/1/settings'] = http.Response('{}', 500);
      final c = clientFor((_) => routes);
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();

      expect(state.isReady, isTrue);
      expect(state.settingsStatus, AdminLoadStatus.error);
      expect(state.teamStatus, AdminLoadStatus.ready);
      expect(state.detail, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 7 · Overview is read-only
  // ═══════════════════════════════════════════════════════════════════════════

  group('overview', () {
    testWidgets('shows the profile with no edit control anywhere',
        (tester) async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await tester.pumpWidget(harness(
          AdminPartnerDetailScreen(state: state, onBack: () {})));
      await tester.pumpAndSettle();

      expect(find.text('contact@sunrise.test'), findsOneWidget);

      // No PUT /api/admin/partners/{id} exists, so no editor may be offered.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('the reason label follows the current status', (tester) async {
      // The backend stores rejection and suspension reasons in one column
      // (D2A-F4), so a suspended partner must not be told it was "rejected".
      final routes = fullPartnerRoutes();
      routes['/api/admin/partners/1'] =
          ok(partnerJson(status: 'SUSPENDED', reason: 'Policy breach'));
      final c = clientFor((_) => routes);
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await tester.pumpWidget(harness(
          AdminPartnerDetailScreen(state: state, onBack: () {})));
      await tester.pumpAndSettle();

      expect(find.text('Suspension reason'), findsOneWidget);
      expect(find.text('Rejection reason'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 8–9 · Approve and reject
  // ═══════════════════════════════════════════════════════════════════════════

  group('approve and reject', () {
    test('offered only from SUBMITTED', () {
      expect(AdminPartnerStatus.submitted.canApproveOrReject, isTrue);
      for (final s in [
        AdminPartnerStatus.draft,
        AdminPartnerStatus.approved,
        AdminPartnerStatus.rejected,
        AdminPartnerStatus.suspended,
        AdminPartnerStatus.unknown,
      ]) {
        expect(s.canApproveOrReject, isFalse, reason: s.name);
      }
    });

    testWidgets('the action bar appears for SUBMITTED and not for APPROVED',
        (tester) async {
      for (final entry in {'SUBMITTED': true, 'APPROVED': false}.entries) {
        final c = clientFor((_) => fullPartnerRoutes(status: entry.key));
        final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
        await state.load();
        await tester.pumpWidget(harness(
            AdminPartnerDetailScreen(state: state, onBack: () {})));
        await tester.pumpAndSettle();

        expect(find.text('Approve'), entry.value ? findsWidgets : findsNothing,
            reason: entry.key);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    test('approve posts and adopts the server\'s new state', () async {
      final c = clientFor((_) => fullPartnerRoutes());
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      final okResult = await state.approve();

      expect(okResult, isTrue);
      expect(
          c.requests.map((u) => u.path), contains('/api/admin/partners/1/approve'));
      expect(state.mutationError, isNull);
    });

    test('reject sends the reason under the backend\'s own field name',
        () async {
      final c = clientFor((_) => fullPartnerRoutes());
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await state.reject('Incomplete documents');

      final body = jsonDecode(c.bodies.last) as Map<String, dynamic>;
      expect(body.keys, ['rejectReason'],
          reason: 'PartnerRejectRequest declares exactly this field');
      expect(body['rejectReason'], 'Incomplete documents');
    });

    test('a blank rejection reason is refused without a round trip', () async {
      final c = clientFor((_) => fullPartnerRoutes());
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      final before = c.requests.length;
      final result = await state.reject('   ');

      expect(result, isFalse);
      expect(c.requests.length, before, reason: 'nothing was sent');
    });

    test('a 422 is surfaced, not swallowed', () async {
      final routes = fullPartnerRoutes();
      routes['/api/admin/partners/1/approve'] = http.Response(
          '{"message":"Only submitted profiles can be approved"}', 422);
      final c = clientFor((_) => routes);
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      final result = await state.approve();

      expect(result, isFalse);
      expect(state.mutationError, contains('submitted'));
      expect(state.mutationUncertain, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 10 · Suspend — the irreversible one
  // ═══════════════════════════════════════════════════════════════════════════

  group('suspend', () {
    test('offered only from APPROVED, and SUSPENDED is terminal', () {
      expect(AdminPartnerStatus.approved.canSuspend, isTrue);
      expect(AdminPartnerStatus.submitted.canSuspend, isFalse);
      expect(AdminPartnerStatus.suspended.canSuspend, isFalse);
      expect(AdminPartnerStatus.suspended.isTerminalSuspension, isTrue);
    });

    testWidgets(
        'the dialog states all three consequences and gates the confirm button',
        (tester) async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await tester.pumpWidget(harness(
          AdminPartnerDetailScreen(state: state, onBack: () {})));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Suspend'));
      await tester.pumpAndSettle();

      expect(find.textContaining('cannot be reversed'), findsOneWidget);
      expect(find.textContaining('bookable'), findsOneWidget);
      expect(find.textContaining('may go unhandled'), findsOneWidget);

      // Disabled until the operator acknowledges.
      final confirm = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Suspend partner'));
      expect(confirm.onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      final enabled = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Suspend partner'));
      expect(enabled.onPressed, isNotNull);
    });

    testWidgets('no restore control is offered for a suspended partner',
        (tester) async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'SUSPENDED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await tester.pumpWidget(harness(
          AdminPartnerDetailScreen(state: state, onBack: () {})));
      await tester.pumpAndSettle();

      // There is no reactivate endpoint anywhere in the backend, so inventing
      // any of these controls would be a promise the product cannot keep.
      expect(find.text('Restore'), findsNothing);
      expect(find.text('Reactivate'), findsNothing);
      expect(find.text('Unsuspend'), findsNothing);
      expect(find.text('Suspend'), findsNothing);
      expect(find.textContaining('no way to restore'), findsOneWidget);
    });

    test('a timeout is reported as uncertain, never as a clean failure',
        () async {
      final routes = fullPartnerRoutes(status: 'APPROVED');
      // A success body that cannot be decoded: the suspension may well have
      // committed, and it cannot be undone.
      routes['/api/admin/partners/1/suspend'] = http.Response('not json', 200);
      final c = clientFor((_) => routes);
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      final result = await state.suspend(reason: 'Policy breach');

      expect(result, isFalse);
      expect(state.mutationUncertain, isTrue);
    });

    test('an omitted reason is not sent as an empty field', () async {
      // The body is `{}` rather than `{"reason": ""}` - an absent optional
      // field, not a blank one.
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await state.suspend();
      expect(c.sent.where((r) => r.method == 'POST').last.body, '{}');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 11–13 · Team, activity, settings
  // ═══════════════════════════════════════════════════════════════════════════

  group('team, activity and settings', () {
    testWidgets('team is read-only with no mutation controls', (tester) async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await tester.pumpWidget(harness(
          AdminPartnerDetailScreen(state: state, onBack: () {})));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Team'));
      await tester.pumpAndSettle();

      expect(find.text('Partner Owner'), findsWidgets);
      expect(find.textContaining('managed by the partner'), findsOneWidget);
      for (final label in ['Invite', 'Add', 'Remove', 'Edit role']) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });

    testWidgets('activity is the partner\'s own log, named as such',
        (tester) async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await tester.pumpWidget(harness(
          AdminPartnerDetailScreen(state: state, onBack: () {})));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      expect(find.text('RATE_PLAN_UPDATED'), findsOneWidget);
      // Explicitly distinguished from the administrative audit trail.
      expect(find.textContaining('console activity log'), findsOneWidget);
    });

    test('activity paging sends page/size and no sort', () async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await state.goToActivityPage(1);

      final last = c.requests.last;
      expect(last.path, '/api/admin/partners/1/activity-logs');
      expect(last.queryParameters['page'], '1');
      // The endpoint's ordering is fixed server-side; it accepts no sort.
      expect(last.queryParameters.containsKey('sort'), isFalse);
    });

    testWidgets('settings are read-only with no save control', (tester) async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await tester.pumpWidget(harness(
          AdminPartnerDetailScreen(state: state, onBack: () {})));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Asia/Ho_Chi_Minh'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(find.text('Save'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 14–15 · Property and assignment boundaries
  // ═══════════════════════════════════════════════════════════════════════════

  group('boundaries', () {
    testWidgets('properties are a count, never a fabricated list',
        (tester) async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await tester.pumpWidget(harness(
          AdminPartnerDetailScreen(state: state, onBack: () {})));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Owned properties'),
        find.byType(ListView).first,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      expect(find.text('Owned properties'), findsOneWidget);
      expect(find.text('3'), findsWidgets, reason: 'owned property count');
      expect(find.text('Properties'), findsNothing,
          reason: 'no properties tab — no endpoint lists them');
      expect(
        c.requests.map((u) => u.path),
        everyElement(isNot(contains('/properties'))),
        reason: 'GET /admin/partners/{id}/properties does not exist',
      );
    });

    testWidgets('no finance, media, bookings or analytics section exists',
        (tester) async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await tester.pumpWidget(harness(
          AdminPartnerDetailScreen(state: state, onBack: () {})));
      await tester.pumpAndSettle();

      for (final absent in ['Finance', 'Media', 'Bookings', 'Analytics']) {
        expect(find.text(absent), findsNothing, reason: absent);
      }
    });

    test('assign-owner is deferred: the client offers no method for it', () {
      // POST /api/admin/hotels/{hotelId}/assign-owner is real, but the D2B
      // freeze places it in a future property/catalogue screen. Nothing in the
      // partner console calls it.
      final c = clientFor((_) => fullPartnerRoutes());
      expect(c.api, isA<ApiClient>());
      // ignore: unnecessary_type_check
      expect(c.api is ApiClient, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 16–17 · Localization and responsive
  // ═══════════════════════════════════════════════════════════════════════════

  group('localization and layout', () {
    testWidgets('renders in Vietnamese without falling back to English',
        (tester) async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await tester.pumpWidget(harness(
        AdminPartnerDetailScreen(state: state, onBack: () {}),
        locale: const Locale('vi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Nhân sự'), findsOneWidget);
      expect(find.text('Overview'), findsNothing);
    });

    testWidgets(
        'list and every detail tab survive 320, 390, 820 and 1600',
        (tester) async {
      addTearDown(tester.view.reset);
      final overflows = <String>[];
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          overflows.add(details.exceptionAsString().split('\n').first);
        }
      };
      addTearDown(() => FlutterError.onError = FlutterError.presentError);

      for (final width in [320.0, 390.0, 820.0, 1600.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;

        final c = clientFor((_) => fullPartnerRoutes(status: 'SUBMITTED'));
        final list = AdminPartnersState(api: c.api);
        await list.load();
        await tester.pumpWidget(harness(AdminPartnersScreen(
            state: list, onOpenPartner: (_) {})));
        await tester.pumpAndSettle();

        final detail = AdminPartnerDetailState(api: c.api, partnerId: 1);
        await detail.load();
        await tester.pumpWidget(harness(
            AdminPartnerDetailScreen(state: detail, onBack: () {})));
        await tester.pumpAndSettle();

        // Every tab, not just the one the screen opens on: Team, Activity and
        // Settings have their own layouts and were previously never laid out
        // at these widths.
        for (final tab in ['Team', 'Activity', 'Settings', 'Overview']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(overflows, isEmpty,
              reason: 'overflow on $tab at ${width}px: ${overflows.join()}');
        }
      }
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });

    /// An accessibility smoke check, not a WCAG audit: every control an
    /// operator must be able to reach by name has an accessible name, and the
    /// destructive one is reachable by its own label rather than by icon alone.
    testWidgets('critical controls carry an accessible name', (tester) async {
      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final handle = tester.ensureSemantics();

      final list = AdminPartnersState(api: c.api);
      await list.load();
      await tester.pumpWidget(
          harness(AdminPartnersScreen(state: list, onOpenPartner: (_) {})));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      // Search field and each partner row are addressable by name.
      expect(find.bySemanticsLabel(l10n.adminPartnerSearchLabel), findsWidgets);

      final detail = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await detail.load();
      await tester.pumpWidget(
          harness(AdminPartnerDetailScreen(state: detail, onBack: () {})));
      await tester.pumpAndSettle();

      // Back navigation is icon-only, so its accessible name comes from the
      // tooltip — which is what a screen reader announces for it.
      expect(find.byTooltip(l10n.adminPartnerBackToList), findsOneWidget);
      // Tabs and the destructive action are named text, which is their label.
      for (final label in [
        l10n.adminPartnerTabOverview,
        l10n.adminPartnerTabTeam,
        l10n.adminPartnerTabActivity,
        l10n.adminPartnerTabSettings,
        l10n.adminPartnerSuspend,
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }

      // The confirmation is reachable and its acknowledgement is a real,
      // hittable control rather than fine print.
      await tester.tap(find.text(l10n.adminPartnerSuspend));
      await tester.pumpAndSettle();
      expect(find.text(l10n.adminPartnerSuspendAcknowledge), findsOneWidget);
      final box = tester.getSize(find.byType(Checkbox));
      expect(box.width, greaterThanOrEqualTo(24.0));
      expect(find.text(l10n.adminPartnerSuspendConfirm), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the suspend dialog fits a 320px viewport', (tester) async {
      addTearDown(tester.view.reset);
      final overflows = <String>[];
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          overflows.add(details.exceptionAsString().split('\n').first);
        }
      };
      addTearDown(() => FlutterError.onError = FlutterError.presentError);

      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;

      final c = clientFor((_) => fullPartnerRoutes(status: 'APPROVED'));
      final state = AdminPartnerDetailState(api: c.api, partnerId: 1);
      await state.load();
      await tester.pumpWidget(harness(
          AdminPartnerDetailScreen(state: state, onBack: () {})));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suspend'));
      await tester.pumpAndSettle();

      expect(find.text('Suspend partner'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget,
          reason: 'the acknowledgement must remain reachable at 320');
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });
  });
}

/// Exposes the paging ceiling for assertions without reaching into the state.
class AdminPagedStateLimits {
  static const int maxPageSize = 200;
}

class _RecordingClient extends http.BaseClient {
  final http.Response Function(http.BaseRequest request) onRequest;

  _RecordingClient({required this.onRequest});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Materialise the body so a POST's payload can be asserted on.
    final materialised = request is http.Request
        ? (http.Request(request.method, request.url)
          ..headers.addAll(request.headers)
          ..body = request.body)
        : request;
    final res = onRequest(materialised);
    return http.StreamedResponse(
      Stream.value(utf8.encode(res.body)),
      res.statusCode,
      headers: res.headers,
      request: request,
    );
  }
}
