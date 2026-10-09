import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planyourtrip_frontend/core/admin/admin_access_models.dart';
import 'package:planyourtrip_frontend/core/admin/admin_state.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/features/admin/admin_navigation.dart';
import 'package:planyourtrip_frontend/features/admin/admin_routes.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';

import 'support/admin_access_stub.dart';

/// RBAC R6 — admin profiles in the console (RBAC V1.1 §7, §9.2, §25.4).
///
/// The console renders from `GET /api/admin/me/access` and never decides
/// access: the backend authorizes every request (covered by the backend's
/// `RbacAdminProfilesTest`). These tests pin that the console fails closed —
/// no document, no destination — and that the Administrators screen only
/// reports what the server answered.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late List<String> requests;
  late List<Map<String, dynamic>> putBodies;

  Map<String, dynamic> page(List<Map<String, dynamic>> content) => {
        'content': content,
        'page': 0,
        'size': 20,
        'totalElements': content.length,
        'totalPages': content.isEmpty ? 0 : 1,
      };

  Map<String, dynamic> account(int id,
          {String name = 'Admin',
          bool self = false,
          bool enabled = true,
          List<String> profiles = const ['PLATFORM_OWNER']}) =>
      {
        'userId': id,
        'fullName': '$name $id',
        'email': 'admin$id@planyourtrip.com',
        'enabled': enabled,
        'self': self,
        'profiles': profiles,
      };

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json; charset=utf-8'});

  http.Response refusal(int status, String code) => json({
        'timestamp': '2026-10-09T00:00:00Z',
        'status': status,
        'error': 'Error',
        'code': code,
        'message': 'refused',
        'path': '/api/admin/access/admins/2/profiles',
      }, status);

  /// A backend for the console. [access] answers `/admin/me/access` (null
  /// = 403); [accessStatus] overrides its status; [puts] answers successive
  /// profile writes.
  http.Client backend({
    Map<String, dynamic>? access,
    int? accessStatus,
    List<Map<String, dynamic>>? admins,
    List<http.Response Function()>? puts,
  }) {
    var accessCalls = 0;
    final queue = [...?puts];
    var list = admins ??
        [
          account(1, self: true),
          account(2, profiles: const ['TECH_SUPPORT']),
        ];
    return MockClient((request) async {
      final path = request.url.path;
      requests.add('${request.method} $path');
      if (path.endsWith('/admin/me/access')) {
        accessCalls++;
        if (accessStatus != null && accessCalls == 1) {
          return json({'status': accessStatus, 'message': 'no'}, accessStatus);
        }
        return access == null
            ? refusal(403, 'PERMISSION_DENIED')
            : json(access);
      }
      if (path.endsWith('/me/step-up')) {
        return json({
          'token': 'fresh-session',
          'user': {'role': 'ADMIN', 'email': 'admin1@planyourtrip.com'},
        });
      }
      if (path.endsWith('/admin/access/admins')) return json(list);
      if (request.method == 'PUT' && path.contains('/admin/access/admins/')) {
        putBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        final answer = queue.isEmpty ? null : queue.removeAt(0)();
        if (answer != null && answer.statusCode == 200) {
          final changed = jsonDecode(answer.body) as Map<String, dynamic>;
          list = [
            for (final a in list) a['userId'] == changed['userId'] ? changed : a
          ];
        }
        return answer ?? refusal(500, 'INTERNAL');
      }
      if (path.endsWith('/analytics/overview')) {
        return json({'totalBookings': 0, 'grossRevenue': 0});
      }
      if (path.contains('/admin/')) return json(page(const []));
      return json({'status': 404, 'message': 'Not found'}, 404);
    });
  }

  setUp(() {
    requests = [];
    putBodies = [];
  });

  Future<({AppState app, AdminState admin})> pumpConsole(
    WidgetTester tester,
    http.Client client, {
    String route = AdminRoutes.dashboard,
    Size size = const Size(1600, 2400),
    Locale? locale,
  }) async {
    final app = AppState(api: ApiClient(client: client)..demoMode = false)
      ..demoMode = false
      ..email = 'admin1@planyourtrip.com'
      ..role = AppRole.admin;
    final admin = AdminState(api: app.api)..bindSession(app);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      notifier: app,
      child: AdminScope(
        notifier: admin,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminRouteGuard(key: ValueKey(route), initialRoute: route),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return (app: app, admin: admin);
  }

  Future<AppLocalizations> en() =>
      AppLocalizations.delegate.load(const Locale('en'));

  Map<String, dynamic> doc(List<String> permissions,
          {List<String> profiles = const ['TECH_SUPPORT']}) =>
      adminAccessDocument(profiles: profiles, permissions: permissions);

  // ── 1. The access document ────────────────────────────────────────────────

  group('access document', () {
    test('a document without a user id is malformed, not empty access', () {
      expect(
          AdminAccess.fromJson({
            'permissions': ['admin.console.access']
          }),
          isNull);
    });

    test('unknown profiles and permission keys are kept, never widened', () {
      final access = AdminAccess.fromJson({
        'userId': 7,
        'profiles': ['PLATFORM_OWNER', 'SUPER_ADMIN', 42],
        'permissions': ['admin.booking.view', 'admin.*', 3],
      })!;
      expect(access.profiles, [
        AdminProfile.platformOwner,
        AdminProfile.unknown,
        AdminProfile.unknown,
      ]);
      expect(access.permissions, {'admin.booking.view', 'admin.*'});
      expect(access.holds(AdminPermissionKeys.paymentView), isFalse,
          reason: 'a wildcard-looking key grants nothing');
    });

    test('AdminState.holds fails closed before and after a session reset',
        () async {
      requests = [];
      final admin = AdminState(
          api: ApiClient(client: backend(access: adminAccessDocument())));
      expect(admin.holds(AdminPermissionKeys.consoleAccess), isFalse);
      await admin.loadAccess();
      expect(admin.accessStatus, AdminAccessStatus.ready);
      expect(admin.holds(AdminPermissionKeys.accessManage), isTrue);
      admin.reset();
      expect(admin.access, isNull);
      expect(admin.holds(AdminPermissionKeys.consoleAccess), isFalse);
    });

    test('the profile wire names are exactly the 11 documented profiles', () {
      expect(AdminProfile.assignable.map((p) => p.wire), [
        'PLATFORM_OWNER',
        'PARTNER_OPERATIONS',
        'CONTENT_CATALOGUE',
        'BOOKING_SUPPORT',
        'FINANCE_OPERATIONS',
        'GROWTH_MARKETING',
        'TRUST_SAFETY',
        'REVIEW_MODERATION',
        'ANALYTICS',
        'LOCATION_CATALOGUE',
        'TECH_SUPPORT',
      ]);
    });

    test('every destination names a permission the platform owner holds', () {
      for (final d in AdminNavigation.destinations) {
        expect(platformOwnerPermissions, contains(d.requiresPermission),
            reason: d.route);
      }
      expect(AdminNavigation.byRoute(AdminRoutes.access)!.requiresPermission,
          AdminPermissionKeys.accessManage);
    });
  });

  // ── 2. Menu and landing ───────────────────────────────────────────────────

  group('menu and landing', () {
    testWidgets('the menu lists only the destinations the document grants',
        (tester) async {
      await pumpConsole(
          tester,
          backend(
              access: doc(const [
            'admin.console.access',
            'admin.audit_log.view',
            'admin.booking.view',
            'admin.payment.view',
          ])),
          route: AdminRoutes.bookings);
      for (final d in AdminNavigation.destinations) {
        final shown = const {
          AdminRoutes.bookings,
          AdminRoutes.payments,
          AdminRoutes.activityLog,
          AdminRoutes.referenceData,
        }.contains(d.route);
        expect(find.byKey(Key('admin-nav-${d.route}')),
            shown ? findsOneWidget : findsNothing,
            reason: d.route);
      }
    });

    testWidgets('a landing route that is not granted moves to a granted one',
        (tester) async {
      await pumpConsole(
          tester,
          backend(
              access: doc(const [
            'admin.console.access',
            'admin.booking.view',
          ])));
      expect(requests.where((r) => r.endsWith('/analytics/overview')), isEmpty,
          reason: 'the dashboard is never read without admin.analytics.view');
      expect(requests, contains('GET /api/admin/bookings'));
      expect(requests.first, 'GET /api/admin/me/access',
          reason: 'nothing loads before the access document');
    });

    testWidgets('only a platform owner sees the Administrators destination',
        (tester) async {
      await pumpConsole(tester, backend(access: adminAccessDocument()));
      expect(find.byKey(const Key('admin-nav-${AdminRoutes.access}')),
          findsOneWidget);
    });

    testWidgets('a direct route to Administrators without A02 never reads it',
        (tester) async {
      await pumpConsole(
          tester,
          backend(
              access: doc(const [
            'admin.console.access',
            'admin.booking.view',
          ])),
          route: AdminRoutes.access);
      expect(find.byKey(const Key('admin-nav-${AdminRoutes.access}')),
          findsNothing);
      expect(
          requests.where((r) => r.contains('/admin/access/admins')), isEmpty);
      expect(find.byKey(const Key('admin-access-list')), findsNothing);
    });
  });

  // ── 3. No access and errors ───────────────────────────────────────────────

  group('no access and errors', () {
    testWidgets('a 403 access document shows no console at all',
        (tester) async {
      await pumpConsole(tester, backend());
      final l10n = await en();
      expect(find.byKey(const Key('admin-no-access')), findsOneWidget);
      expect(find.text(l10n.adminNoProfileTitle), findsOneWidget);
      expect(requests, ['GET /api/admin/me/access'],
          reason: 'an admin without a profile makes no other admin request');
      for (final d in AdminNavigation.destinations) {
        expect(find.byKey(Key('admin-nav-${d.route}')), findsNothing);
      }
    });

    testWidgets('an access load failure is retryable, not empty access',
        (tester) async {
      await pumpConsole(
          tester, backend(access: adminAccessDocument(), accessStatus: 500));
      expect(find.byKey(const Key('admin-access-error')), findsOneWidget);
      expect(find.byKey(const Key('admin-no-access')), findsNothing);
      await tester.tap(find.text((await en()).errorAction).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin-access-error')), findsNothing);
      expect(find.byKey(const Key('admin-nav-${AdminRoutes.dashboard}')),
          findsOneWidget);
    });
  });

  // ── 4. The Administrators screen ──────────────────────────────────────────

  group('administrators screen', () {
    Future<void> openAccess(WidgetTester tester, http.Client client) async {
      await pumpConsole(tester, client, route: AdminRoutes.access);
      expect(find.byKey(const Key('admin-access-list')), findsOneWidget);
    }

    testWidgets('lists administrators; the own row cannot be edited',
        (tester) async {
      await openAccess(tester, backend(access: adminAccessDocument()));
      expect(find.byKey(const Key('admin-access-account-1')), findsOneWidget);
      expect(find.byKey(const Key('admin-access-self-1')), findsOneWidget);
      final own = tester
          .widget<TextButton>(find.byKey(const Key('admin-access-edit-1')));
      expect(own.onPressed, isNull, reason: 'AP-1: nobody edits themselves');
      final other = tester
          .widget<TextButton>(find.byKey(const Key('admin-access-edit-2')));
      expect(other.onPressed, isNotNull);
    });

    testWidgets('a row with a profile this build does not know is read-only',
        (tester) async {
      await openAccess(
          tester,
          backend(access: adminAccessDocument(), admins: [
            account(1, self: true),
            account(3, profiles: const ['TECH_SUPPORT', 'FUTURE_PROFILE']),
          ]));
      final row = tester
          .widget<TextButton>(find.byKey(const Key('admin-access-edit-3')));
      expect(row.onPressed, isNull,
          reason: 'saving would silently revoke the unknown profile');
    });

    testWidgets('an admin with no profile is labelled, not hidden',
        (tester) async {
      await openAccess(
          tester,
          backend(access: adminAccessDocument(), admins: [
            account(1, self: true),
            account(4, profiles: const []),
          ]));
      expect(find.byKey(const Key('admin-access-none-4')), findsOneWidget);
    });

    testWidgets('saving sends exactly the selected profiles and the reason',
        (tester) async {
      await openAccess(
          tester,
          backend(access: adminAccessDocument(), puts: [
            () => json(account(2, profiles: const [
                  'BOOKING_SUPPORT',
                  'TECH_SUPPORT',
                ])),
          ]));
      await tester.tap(find.byKey(const Key('admin-access-edit-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin-access-dialog')), findsOneWidget);
      await tester
          .tap(find.byKey(const Key('admin-access-profile-BOOKING_SUPPORT')));
      await tester.enterText(
          find.byKey(const Key('admin-access-reason')), '  Ticket 42  ');
      await tester.tap(find.byKey(const Key('admin-access-save')));
      await tester.pumpAndSettle();

      expect(putBodies, [
        {
          'profiles': ['BOOKING_SUPPORT', 'TECH_SUPPORT'],
          'reason': 'Ticket 42',
        }
      ]);
      final l10n = await en();
      expect(find.text(l10n.adminAccessSaved), findsOneWidget);
      expect(
          requests.where((r) => r == 'GET /api/admin/access/admins').length, 2,
          reason: 'the list is re-read from the server after a change');
    });

    testWidgets('STEP_UP_REQUIRED asks for the password, then retries once',
        (tester) async {
      await openAccess(
          tester,
          backend(access: adminAccessDocument(), puts: [
            () => refusal(403, 'STEP_UP_REQUIRED'),
            () => json(account(2, profiles: const [])),
          ]));
      await tester.tap(find.byKey(const Key('admin-access-edit-2')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('admin-access-profile-TECH_SUPPORT')));
      await tester.tap(find.byKey(const Key('admin-access-save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('partner-step-up-dialog')), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('partner-step-up-password')), 'not-logged');
      await tester.tap(find.byKey(const Key('partner-step-up-confirm')));
      await tester.pumpAndSettle();

      expect(requests.where((r) => r == 'POST /api/me/step-up'), hasLength(1));
      expect(putBodies, hasLength(2));
      expect(putBodies.last, {'profiles': <String>[]},
          reason: 'clearing every profile is an explicit, empty set');
      expect(find.text((await en()).adminAccessSaved), findsOneWidget);
    });

    testWidgets('a cancelled step-up sends nothing further', (tester) async {
      await openAccess(
          tester,
          backend(access: adminAccessDocument(), puts: [
            () => refusal(403, 'STEP_UP_REQUIRED'),
          ]));
      await tester.tap(find.byKey(const Key('admin-access-edit-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-access-save')));
      await tester.pumpAndSettle();
      final l10n = await en();
      await tester.tap(find.text(l10n.partnerTeamCancel));
      await tester.pumpAndSettle();
      expect(putBodies, hasLength(1));
      expect(requests.where((r) => r == 'POST /api/me/step-up'), isEmpty);
    });

    for (final (code, status, message) in [
      (
        'LAST_PLATFORM_OWNER_REQUIRED',
        409,
        (AppLocalizations l) => l.adminAccessErrorLastOwner
      ),
      (
        'SELF_MODIFICATION_FORBIDDEN',
        403,
        (AppLocalizations l) => l.adminAccessErrorSelf
      ),
      (
        'PERMISSION_DENIED',
        403,
        (AppLocalizations l) => l.adminAccessErrorPermission
      ),
      (
        'VALIDATION_FAILED',
        400,
        (AppLocalizations l) => l.adminAccessErrorValidation
      ),
    ]) {
      testWidgets('$code is worded, never reported as saved', (tester) async {
        await openAccess(
            tester,
            backend(
                access: adminAccessDocument(),
                puts: [() => refusal(status, code)]));
        await tester.tap(find.byKey(const Key('admin-access-edit-2')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('admin-access-save')));
        await tester.pumpAndSettle();
        final l10n = await en();
        expect(find.text(message(l10n)), findsOneWidget);
        expect(find.text(l10n.adminAccessSaved), findsNothing);
        expect(find.byKey(const Key('partner-step-up-dialog')), findsNothing);
      });
    }

    testWidgets('the screen renders in Vietnamese at phone width',
        (tester) async {
      await pumpConsole(tester, backend(access: adminAccessDocument()),
          route: AdminRoutes.access,
          size: const Size(360, 900),
          locale: const Locale('vi'));
      final vi = await AppLocalizations.delegate.load(const Locale('vi'));
      expect(find.text(vi.adminAccessYou), findsOneWidget);
      expect(find.text(vi.adminProfileTechSupport), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
