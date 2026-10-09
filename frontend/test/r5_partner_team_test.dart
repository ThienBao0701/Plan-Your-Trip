import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/app/routing/auth_link_token.dart';
import 'package:planyourtrip_frontend/app/routing/invitation_link.dart';
import 'package:planyourtrip_frontend/app/routing/partner_router.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_access_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_models.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/core/partner/partner_team_models.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/partner_navigation.dart';
import 'package:planyourtrip_frontend/features/partner/team/accept_invitation_screen.dart';
import 'package:planyourtrip_frontend/features/partner/team/partner_team_screen.dart';
import 'package:planyourtrip_frontend/features/partner/team/partner_team_state.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// R5 — Partner team and invitation management against the R4 API.
///
/// A stateful fake backend serves the exact R4 routes and DTO shapes
/// (`/api/partner/me/access`, `/api/partner/team…`, `/api/partner/team/invitations…`,
/// `/api/me/partner-invitations…`, `/api/me/step-up`). Every request and body is
/// logged so tests can prove what was — and was not — sent.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PartnerInvitationLink.clear();
    AuthLinkToken.clear('/');
  });

  final en = AppLocalizationsEn();

  http.Response json(Object? body, int status) => http.Response(
        body == null ? '' : jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, dynamic> error(int status, String code,
          {String? reason, List<Map<String, String>>? fields}) =>
      {
        'timestamp': '2026-10-09T00:00:00Z',
        'status': status,
        'error': 'Error',
        'message': 'refused',
        'path': '/x',
        'code': code,
        if (reason != null) 'reason': reason,
        if (fields != null) 'fieldErrors': fields,
      };

  Map<String, dynamic> member(
          int id, String email, List<Map<String, String>> grants,
          {String status = 'ACTIVE',
          bool primary = false,
          bool self = false,
          bool pending = false,
          int version = 3}) =>
      {
        'id': id,
        'partnerProfileId': 7,
        'userId': 100 + id,
        'userName': 'Member $id',
        'userEmail': email,
        'role': grants.first['role'],
        'active': status == 'ACTIVE',
        'status': status,
        'grants': grants,
        'primaryOwner': primary,
        'pendingOwnerConfirmation': pending,
        'isSelf': self,
        'version': version,
      };

  Map<String, String> g(String role, String scope) =>
      {'role': role, 'scope': scope};

  Map<String, dynamic> invitation(int id, String email,
          {String status = 'PENDING',
          String delivery = 'SENT',
          int resends = 0,
          DateTime? lastSent,
          List<Map<String, String>>? grants}) =>
      {
        'id': id,
        'email': email,
        'grants': grants ?? [g('VIEWER', 'COMPANY:7')],
        'status': status,
        'statusReason': null,
        'deliveryStatus': delivery,
        'expiresAt': DateTime.now()
            .toUtc()
            .add(const Duration(days: 6))
            .toIso8601String(),
        'resendCount': resends,
        'lastSentAt': (lastSent ??
                DateTime.now().toUtc().subtract(const Duration(minutes: 5)))
            .toIso8601String(),
        'invitedByUserId': 101,
        'invitedByName': 'Owner One',
        'createdAt': '2026-10-08T00:00:00Z',
      };

  const ownerKeys = [
    'partner.workspace.access',
    'partner.team.view',
    'partner.team.invite',
    'partner.team.role.assign',
    'partner.team.suspend',
    'partner.team.remove',
    'partner.team.owner.manage',
  ];

  Map<String, dynamic> access({
    bool primary = true,
    List<String> company = ownerKeys,
    Map<String, List<String>> properties = const {},
    List<Map<String, Object>> grants = const [
      {'role': 'OWNER', 'scopeType': 'COMPANY', 'scopeId': 7},
    ],
    String membership = 'ACTIVE',
  }) =>
      {
        'workspace': {
          'companyId': 7,
          'businessName': 'Bay View Resorts',
          'verificationStatus': 'APPROVED'
        },
        'membership': {
          'id': 1,
          'status': membership,
          'primaryOwner': primary,
          'pendingOwnerConfirmation': false
        },
        'grants': grants,
        'permissions': {
          'company': company,
          'properties': properties,
          'units': <String, Object>{}
        },
        'context': {
          'properties': [
            {
              'id': 12,
              'name': 'Bay View Hotel',
              'locationLabel': 'Vung Tau',
              'active': true,
              'placeStatus': 'PUBLISHED'
            },
            {
              'id': 13,
              'name': 'Hill Lodge',
              'locationLabel': 'Da Lat',
              'active': true,
              'placeStatus': 'PUBLISHED'
            },
          ],
          'units': <Object>[],
        },
        'stepUp': {'freshUntil': null},
      };

  final managerAccess = access(
    primary: false,
    company: const [
      'partner.workspace.access',
      'partner.team.view',
      'partner.team.invite',
      'partner.team.role.assign',
      'partner.team.suspend',
      'partner.team.remove',
    ],
    grants: const [
      {'role': 'MANAGER', 'scopeType': 'COMPANY', 'scopeId': 7},
    ],
  );

  final propertyManagerAccess = access(
    primary: false,
    company: const ['partner.workspace.access'],
    properties: const {
      '12': [
        'partner.workspace.access',
        'partner.team.view',
        'partner.team.invite',
        'partner.team.role.assign',
        'partner.team.suspend',
        'partner.team.remove',
      ],
    },
    grants: const [
      {'role': 'MANAGER', 'scopeType': 'PROPERTY', 'scopeId': 12},
    ],
  );

  final viewerAccess = access(
    primary: false,
    company: const ['partner.workspace.access', 'partner.team.view'],
    grants: const [
      {'role': 'VIEWER', 'scopeType': 'COMPANY', 'scopeId': 7},
    ],
  );

  final noTeamAccess = access(
    primary: false,
    company: const ['partner.workspace.access'],
    grants: const [
      {'role': 'FRONT_DESK', 'scopeType': 'COMPANY', 'scopeId': 7},
    ],
  );

  late List<String> log;
  late List<String> bodies;

  /// The fake R4 backend. [overrides] map `METHOD /path-suffix` to a response.
  MockClient backend({
    Map<String, dynamic>? accessDoc,
    List<Map<String, dynamic>>? members,
    List<Map<String, dynamic>>? invitations,
    Map<String, http.Response Function()> overrides = const {},
    List<Map<String, dynamic>> mine = const [],
  }) {
    log = [];
    bodies = [];
    final team = members ??
        [
          member(1, 'owner@bayview.example', [g('OWNER', 'COMPANY:7')],
              primary: true, self: true),
          member(2, 'manager@bayview.example', [g('MANAGER', 'COMPANY:7')]),
          member(3, 'finance@bayview.example', [g('FINANCE', 'COMPANY:7')]),
          member(4, 'desk@bayview.example', [g('FRONT_DESK', 'PROPERTY:12')]),
          member(5, 'paused@bayview.example', [g('VIEWER', 'COMPANY:7')],
              status: 'SUSPENDED'),
        ];
    final invites = invitations ?? [invitation(9, 'new@bayview.example')];
    return MockClient((request) async {
      final path = request.url.path;
      final key = '${request.method} $path';
      log.add(key);
      if (request.body.isNotEmpty) bodies.add(request.body);
      for (final entry in overrides.entries) {
        final parts = entry.key.split(' ');
        if (parts[0] == request.method && path.endsWith(parts[1])) {
          return entry.value();
        }
      }
      if (path.endsWith('/partner/profile')) {
        return json({
          'id': 7,
          'userId': 101,
          'businessName': 'Bay View Resorts',
          'representativeName': 'Owner',
          'verificationStatus': 'APPROVED'
        }, 200);
      }
      if (path.endsWith('/partner/me/access')) {
        return json(accessDoc ?? access(), 200);
      }
      if (path.endsWith('/partner/extranet/home')) {
        return json({
          'profile': {'id': 7, 'businessName': 'Bay View Resorts'},
          'verificationStatus': 'APPROVED',
          'ownedHotelCount': 2,
          'activeRoomCount': 3,
        }, 200);
      }
      if (path.endsWith('/partner/hotels')) return json(<Object>[], 200);
      if (path.endsWith('/partner/rooms')) {
        return json([
          {
            'id': 31,
            'roomName': 'Deluxe Sea View',
            'roomCode': 'DLX',
            'roomType': 'DELUXE'
          },
        ], 200);
      }
      if (path.endsWith('/partner/team/invitations') &&
          request.method == 'GET') {
        return json(invites, 200);
      }
      if (path.endsWith('/partner/team/invitations') &&
          request.method == 'POST') {
        return json({'status': 'REQUESTED', 'message': 'recorded'}, 202);
      }
      if (RegExp(r'/partner/team/invitations/\d+/resend$').hasMatch(path)) {
        return json({'status': 'REQUESTED', 'message': 'recorded'}, 202);
      }
      if (RegExp(r'/partner/team/invitations/\d+$').hasMatch(path)) {
        return json(null, 204);
      }
      if (path.endsWith('/partner/team') && request.method == 'GET') {
        return json(team, 200);
      }
      if (path.endsWith('/partner/team/leave')) return json(null, 204);
      final grants = RegExp(r'/partner/team/(\d+)/grants$').firstMatch(path);
      if (grants != null) {
        final id = int.parse(grants.group(1)!);
        final sent = jsonDecode(request.body) as Map<String, dynamic>;
        return json(
            member(
                id,
                'x@bayview.example',
                List<Map<String, String>>.from((sent['grants'] as List)
                    .map((e) => Map<String, String>.from(e as Map)))),
            200);
      }
      final status =
          RegExp(r'/partner/team/(\d+)/(suspend|reactivate)$').firstMatch(path);
      if (status != null) {
        final id = int.parse(status.group(1)!);
        return json(
            member(id, 'x@bayview.example', [g('VIEWER', 'COMPANY:7')],
                status: status.group(2) == 'suspend' ? 'SUSPENDED' : 'ACTIVE'),
            200);
      }
      if (RegExp(r'/partner/team/\d+$').hasMatch(path) &&
          request.method == 'DELETE') {
        return json(null, 204);
      }
      if (path.endsWith('/me/partner-invitations') && request.method == 'GET') {
        return json(mine, 200);
      }
      if (path.endsWith('/me/partner-invitations/accept')) {
        return json(managerAccess, 200);
      }
      if (path.endsWith('/me/partner-invitations/decline')) {
        return json(null, 204);
      }
      if (path.endsWith('/me/step-up')) {
        return json({
          'token': 'fresh-session-token',
          'user': {
            'id': 101,
            'email': 'partner@planyourtrip.com',
            'role': 'PARTNER'
          }
        }, 200);
      }
      return json(error(404, 'NOT_FOUND'), 404);
    });
  }

  AppState partnerApp(http.Client client) =>
      AppState(api: ApiClient(client: client)..demoMode = false)
        ..demoMode = false
        ..email = 'partner@planyourtrip.com'
        ..role = AppRole.partner;

  Future<({AppState app, PartnerState partner})> pump(
    WidgetTester tester,
    Widget child, {
    required http.Client client,
    Size size = const Size(1600, 3200),
    bool loadWorkspace = true,
    bool scroll = true,
  }) async {
    final app = partnerApp(client);
    final partner = PartnerState(api: app.api)..bindSession(app);
    if (loadWorkspace) await partner.loadWorkspace(app);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(AppScope(
      notifier: app,
      child: PartnerScope(
        notifier: partner,
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Full pages (sign-in, acceptance) bring their own Scaffold.
          home: scroll
              ? Scaffold(body: SingleChildScrollView(child: child))
              : child,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return (app: app, partner: partner);
  }

  Future<PartnerState> loadedPartner(http.Client client) async {
    final app = partnerApp(client);
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);
    return partner;
  }

  List<String> layoutErrors(WidgetTester tester) {
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.toString());
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
    return errors;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Contract: models parse exactly what R4 returns
  // ═══════════════════════════════════════════════════════════════════════

  group('contract', () {
    test('a member carries status, grants, owner flags, self and version', () {
      final parsed = PartnerTeamMember.fromJson(member(4, 'desk@x.example',
          [g('FRONT_DESK', 'PROPERTY:12'), g('HOUSEKEEPING', 'UNIT:31')],
          status: 'SUSPENDED', version: 9))!;
      expect(parsed.status, PartnerMembershipStatus.suspended);
      expect(parsed.version, 9);
      expect(
          parsed.grants.map((e) => e.scope.wire), ['PROPERTY:12', 'UNIT:31']);
      expect(parsed.roles,
          {PartnerTeamRole.frontDesk, PartnerTeamRole.housekeeping});
      expect(parsed.involvesOwner, isFalse);
    });

    test('scopes parse as strictly as the server: anything else is no scope',
        () {
      expect(PartnerScopeRef.parse('PROPERTY:12'),
          const PartnerScopeRef(PartnerScopeType.property, 12));
      for (final bad in [
        'property:12',
        'ROOM:1',
        'PROPERTY:0',
        'PROPERTY:abc',
        'PROPERTY:12 ',
        ''
      ]) {
        expect(PartnerScopeRef.parse(bad), isNull, reason: bad);
      }
    });

    test(
        'the role/scope vocabulary is the server\'s (§11.3), unknown never sent',
        () {
      expect(PartnerTeamRoles.scopesFor(PartnerTeamRole.owner),
          {PartnerScopeType.company});
      expect(PartnerTeamRoles.scopesFor(PartnerTeamRole.finance),
          {PartnerScopeType.company});
      expect(PartnerTeamRoles.scopesFor(PartnerTeamRole.housekeeping),
          {PartnerScopeType.property, PartnerScopeType.unit});
      expect(PartnerTeamRoles.scopesFor(PartnerTeamRole.viewer),
          {PartnerScopeType.company, PartnerScopeType.property});
      expect(
          const PartnerTeamGrant(
                  role: PartnerTeamRole.unknown,
                  scope: PartnerScopeRef(PartnerScopeType.company, 7))
              .toJson(),
          isNull);
    });

    test(
        'the access document is read by permission and scope, unknown keys ignored',
        () {
      final doc = PartnerAccess.fromJson({
        ...propertyManagerAccess,
        'permissions': {
          'company': ['partner.workspace.access', 'partner.unknown.future'],
          'properties':
              (propertyManagerAccess['permissions'] as Map)['properties'],
          'units': <String, Object>{},
        },
      })!;
      expect(doc.holdsAnywhere(PartnerPermissionKeys.teamInvite), isTrue);
      expect(doc.holdsAtCompany(PartnerPermissionKeys.teamInvite), isFalse,
          reason: 'a property scope never widens');
      expect(
          doc.holdsForProperty(PartnerPermissionKeys.teamInvite, 12), isTrue);
      expect(
          doc.holdsForProperty(PartnerPermissionKeys.teamInvite, 13), isFalse);
      expect(
          doc
              .propertiesCovering(PartnerPermissionKeys.teamInvite)
              .map((p) => p.id),
          [12]);
      expect(doc.highestRole, PartnerTeamRole.manager);
      expect(doc.isOwnerActor, isFalse);
    });

    test('invitations and access documents have no token field', () {
      final inv = PartnerTeamInvitation.fromJson({
        ...invitation(9, 'a@b.example'),
        'token': 'leak',
        'tokenHash': 'leak'
      })!;
      expect(inv.email, 'a@b.example');
      expect('$inv'.contains('leak'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Capabilities: UX shaping from the access document (§10.3, §23 F3–F5)
  // ═══════════════════════════════════════════════════════════════════════

  group('capabilities', () {
    PartnerTeamMember m(int id, List<Map<String, String>> grants,
            {bool primary = false, bool self = false, bool pending = false}) =>
        PartnerTeamMember.fromJson(member(id, 'x$id@b.example', grants,
            primary: primary, self: self, pending: pending))!;

    test('an owner may hand out every role at every scope it holds', () {
      final caps = PartnerTeamCapabilities(PartnerAccess.fromJson(access()));
      expect(caps.isOwnerActor, isTrue);
      expect(caps.grantableRoles, PartnerTeamRoles.all);
      expect(caps.offersCompanyScope(PartnerPermissionKeys.teamInvite), isTrue);
      expect(
          caps.canManage(m(2, [g('MANAGER', 'COMPANY:7')]),
              PartnerPermissionKeys.teamSuspend),
          isTrue);
      expect(
          caps.canManage(m(1, [g('OWNER', 'COMPANY:7')], primary: true),
              PartnerPermissionKeys.teamSuspend),
          isFalse,
          reason: 'the primary owner is immutable (O-1)');
      expect(
          caps.canManage(m(8, [g('OWNER', 'COMPANY:7')], self: true),
              PartnerPermissionKeys.teamSuspend),
          isFalse,
          reason: 'nobody modifies themselves (I7)');
    });

    test(
        'a manager manages only below-manager roles, never owners, managers or finance',
        () {
      final caps =
          PartnerTeamCapabilities(PartnerAccess.fromJson(managerAccess));
      expect(caps.isOwnerActor, isFalse);
      expect(caps.grantableRoles, isNot(contains(PartnerTeamRole.owner)));
      expect(caps.grantableRoles, isNot(contains(PartnerTeamRole.manager)));
      expect(caps.grantableRoles, isNot(contains(PartnerTeamRole.finance)));
      expect(caps.grantableRoles, hasLength(6));
      expect(
          caps.canManage(m(4, [g('FRONT_DESK', 'PROPERTY:12')]),
              PartnerPermissionKeys.teamRoleAssign),
          isTrue);
      expect(
          caps.canManage(m(3, [g('FINANCE', 'COMPANY:7')]),
              PartnerPermissionKeys.teamRoleAssign),
          isFalse);
      expect(
          caps.canManage(m(2, [g('MANAGER', 'COMPANY:7')]),
              PartnerPermissionKeys.teamRoleAssign),
          isFalse);
      expect(
          caps.canManage(m(6, [g('VIEWER', 'COMPANY:7')], pending: true),
              PartnerPermissionKeys.teamRoleAssign),
          isFalse,
          reason: 'a pending co-owner counts as an owner (O-9)');
      expect(caps.canLeave, isTrue);
    });

    test('a property manager is offered its property only, never company scope',
        () {
      final caps = PartnerTeamCapabilities(
          PartnerAccess.fromJson(propertyManagerAccess));
      expect(
          caps.offersCompanyScope(PartnerPermissionKeys.teamInvite), isFalse);
      expect(
          caps.propertiesFor(PartnerPermissionKeys.teamInvite).map((p) => p.id),
          [12]);
    });

    test(
        'a viewer sees the team but changes nothing; finance-like roles see nothing',
        () {
      final viewer =
          PartnerTeamCapabilities(PartnerAccess.fromJson(viewerAccess));
      expect(viewer.canView, isTrue);
      expect(
          viewer.canInvite ||
              viewer.canAssign ||
              viewer.canSuspend ||
              viewer.canRemove,
          isFalse);
      final none =
          PartnerTeamCapabilities(PartnerAccess.fromJson(noTeamAccess));
      expect(none.canView, isFalse);
      const missing = PartnerTeamCapabilities(null);
      expect(
          missing.canView || missing.canInvite || missing.isOwnerActor, isFalse,
          reason: 'fail closed (F7)');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // State and API: server-owned lists, versions, conflicts, no double submits
  // ═══════════════════════════════════════════════════════════════════════

  group('team state', () {
    test('loads members and invitations from the R4 endpoints', () async {
      final client = backend();
      final state =
          PartnerTeamState(api: ApiClient(client: client)..demoMode = false);
      await state.load();
      expect(state.status, PartnerTeamStatus.ready);
      expect(state.members, hasLength(5));
      expect(state.activeMembers, hasLength(4));
      expect(state.suspendedMembers, hasLength(1));
      expect(state.pendingInvitations, hasLength(1));
      expect(
          log,
          containsAll(
              ['GET /api/partner/team', 'GET /api/partner/team/invitations']));
    });

    test('a refused or failed load is a state, not data', () async {
      for (final (code, expected) in [
        (403, PartnerTeamStatus.forbidden),
        (401, PartnerTeamStatus.unauthorized),
        (500, PartnerTeamStatus.error)
      ]) {
        final client = backend(overrides: {
          'GET /partner/team': () => json(error(code, 'X'), code)
        });
        final state =
            PartnerTeamState(api: ApiClient(client: client)..demoMode = false);
        await state.load();
        expect(state.status, expected);
        expect(state.members, isEmpty);
      }
    });

    test(
        'an invitation posts the normalised address and grants, and the 202 is not a membership',
        () async {
      final client = backend();
      final state =
          PartnerTeamState(api: ApiClient(client: client)..demoMode = false);
      await state.load();
      final result = await state.invite(
        email: '  New.Person@Bayview.Example ',
        grants: const [
          PartnerTeamGrant(
              role: PartnerTeamRole.reservations,
              scope: PartnerScopeRef(PartnerScopeType.property, 12))
        ],
      );
      expect(result.success, isTrue);
      expect(jsonDecode(bodies.last), {
        'email': 'new.person@bayview.example',
        'grants': [
          {'role': 'RESERVATIONS', 'scope': 'PROPERTY:12'},
        ],
      });
      expect(state.members, hasLength(5),
          reason: 'nobody joined: the list is re-read, never extended locally');
    });

    test('an unavailable email service is reported and nothing appears',
        () async {
      final client = backend(overrides: {
        'POST /partner/team/invitations': () =>
            json(error(503, 'EMAIL_DELIVERY_UNAVAILABLE'), 503),
      });
      final state =
          PartnerTeamState(api: ApiClient(client: client)..demoMode = false);
      await state.load();
      final result = await state.invite(
        email: 'a@b.example',
        grants: const [
          PartnerTeamGrant(
              role: PartnerTeamRole.viewer,
              scope: PartnerScopeRef(PartnerScopeType.company, 7))
        ],
      );
      expect(result.success, isFalse);
      expect(result.code, 'EMAIL_DELIVERY_UNAVAILABLE');
      expect(state.invitations, hasLength(1));
    });

    test(
        'a grant change sends the version read; a stale one reloads and is never resent',
        () async {
      final client = backend(overrides: {
        'PUT /grants': () => json(error(409, 'CONCURRENT_MODIFICATION'), 409),
      });
      final state =
          PartnerTeamState(api: ApiClient(client: client)..demoMode = false);
      await state.load();
      final target = state.members.firstWhere((m) => m.id == 4);
      final result = await state.replaceGrants(
        target,
        const [
          PartnerTeamGrant(
              role: PartnerTeamRole.content,
              scope: PartnerScopeRef(PartnerScopeType.property, 12))
        ],
        reason: 'new duties',
      );
      expect(result.code, 'CONCURRENT_MODIFICATION');
      expect(result.reloaded, isTrue);
      expect(log.where((r) => r == 'PUT /api/partner/team/4/grants'),
          hasLength(1));
      expect(jsonDecode(bodies.last), {
        'grants': [
          {'role': 'CONTENT', 'scope': 'PROPERTY:12'},
        ],
        'version': 3,
        'reason': 'new duties',
      });
      expect(log.where((r) => r == 'GET /api/partner/team'), hasLength(2),
          reason: 'reloaded after the conflict');
    });

    test('status changes, removal, resend, revoke and leave use the R4 routes',
        () async {
      final client = backend();
      final state =
          PartnerTeamState(api: ApiClient(client: client)..demoMode = false);
      await state.load();
      final desk = state.members.firstWhere((m) => m.id == 4);
      final paused = state.members.firstWhere((m) => m.id == 5);
      expect((await state.suspend(desk, reason: 'on leave')).success, isTrue);
      expect((await state.reactivate(paused)).success, isTrue);
      expect((await state.remove(desk)).success, isTrue);
      final inv = state.invitations.first;
      expect((await state.resend(inv)).success, isTrue);
      expect(
          (await state.revoke(inv, reason: 'wrong address')).success, isTrue);
      expect((await state.leave()).success, isTrue);
      expect(
          log,
          containsAll([
            'POST /api/partner/team/4/suspend',
            'POST /api/partner/team/5/reactivate',
            'DELETE /api/partner/team/4',
            'POST /api/partner/team/invitations/9/resend',
            'DELETE /api/partner/team/invitations/9',
            'POST /api/partner/team/leave',
          ]));
      expect(bodies, contains(jsonEncode({'reason': 'on leave'})));
      expect(bodies, contains(jsonEncode({'reason': 'wrong address'})));
    });

    test('resend limits and refusals come from the server and are surfaced',
        () async {
      final client = backend(overrides: {
        'POST /resend': () => json(error(429, 'INVITATION_RATE_LIMITED'), 429),
        'DELETE /invitations/9': () =>
            json(error(409, 'INVITATION_NOT_PENDING'), 409),
      });
      final state =
          PartnerTeamState(api: ApiClient(client: client)..demoMode = false);
      await state.load();
      final inv = state.invitations.first;
      expect((await state.resend(inv)).code, 'INVITATION_RATE_LIMITED');
      final revoked = await state.revoke(inv);
      expect(revoked.code, 'INVITATION_NOT_PENDING');
      expect(revoked.reloaded, isTrue,
          reason:
              'accepted, expired or revoked elsewhere: the view is refreshed');
    });

    test('the same action twice in flight sends one request', () async {
      final client = backend();
      final state =
          PartnerTeamState(api: ApiClient(client: client)..demoMode = false);
      await state.load();
      final desk = state.members.firstWhere((m) => m.id == 4);
      final results =
          await Future.wait([state.suspend(desk), state.suspend(desk)]);
      expect(results.where((r) => r.ignored), hasLength(1));
      expect(log.where((r) => r == 'POST /api/partner/team/4/suspend'),
          hasLength(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Workspace and navigation: permission-aware, member-capable
  // ═══════════════════════════════════════════════════════════════════════

  group('workspace and navigation', () {
    test('the team destination is listed only with team view', () async {
      final team =
          PartnerNavigation.destinations.firstWhere((d) => d.key == 'team');
      expect(team.route, '/partner/team');
      expect(team.requiresPermission, PartnerPermissionKeys.teamView);
      expect(
          (await loadedPartner(backend()))
              .holdsAnywhere(team.requiresPermission!),
          isTrue);
      expect(
          (await loadedPartner(backend(accessDoc: noTeamAccess)))
              .holdsAnywhere(team.requiresPermission!),
          isFalse);
      expect(PartnerSurfaceRouter.routeOf('/team'), '/partner/team');
    });

    test(
        'an owner whose access document cannot be read gets no team affordance',
        () async {
      final partner = await loadedPartner(backend(overrides: {
        'GET /partner/me/access': () => json(error(500, 'X'), 500),
      }));
      expect(partner.status, PartnerWorkspaceStatus.ready);
      expect(partner.access, isNull);
      expect(partner.holdsAnywhere(PartnerPermissionKeys.teamView), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Team screen
  // ═══════════════════════════════════════════════════════════════════════

  group('team screen', () {
    testWidgets(
        'lists members and invitations with roles, scopes, status and counts',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(), client: backend());
      expect(find.text(en.partnerTeamScreenTitle), findsOneWidget);
      expect(find.text(en.partnerTeamCountMembers(5)), findsOneWidget);
      expect(find.text(en.partnerTeamCountPending(1)), findsOneWidget);
      expect(find.text('manager@bayview.example'), findsOneWidget);
      expect(
          find.text(en.partnerTeamGrantLabel(
              en.partnerTeamRoleFrontDesk, 'Bay View Hotel')),
          findsOneWidget);
      expect(find.byKey(const Key('partner-team-primary-1')), findsOneWidget);
      expect(find.byKey(const Key('partner-team-self-1')), findsOneWidget);
      expect(find.text(en.partnerTeamStatusSuspended), findsOneWidget);
      expect(find.text('new@bayview.example'), findsOneWidget);
      expect(find.text(en.partnerInvitationDeliverySent), findsOneWidget);
    });

    testWidgets('empty lists say so', (tester) async {
      await pump(tester, const PartnerTeamScreen(),
          client: backend(members: const [], invitations: const []));
      expect(
          find.byKey(const Key('partner-team-members-empty')), findsOneWidget);
      expect(find.byKey(const Key('partner-team-invitations-empty')),
          findsOneWidget);
    });

    testWidgets('a failed load offers a retry, then recovers', (tester) async {
      var fail = true;
      final client = backend(overrides: {
        'GET /partner/team': () => fail
            ? json(error(500, 'X'), 500)
            : json([
                member(2, 'm@b.example', [g('VIEWER', 'COMPANY:7')])
              ], 200),
      });
      await pump(tester, const PartnerTeamScreen(), client: client);
      expect(find.byKey(const Key('partner-team-error')), findsOneWidget);
      fail = false;
      await tester.tap(find.descendant(
          of: find.byKey(const Key('partner-team-error')),
          matching: find.text(en.partnerActionRefresh)));
      await tester.pumpAndSettle();
      expect(find.text('m@b.example'), findsOneWidget);
    });

    testWidgets('the primary owner and the caller have no actions; others do',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(), client: backend());
      expect(find.byKey(const Key('partner-team-member-menu-1')), findsNothing);
      for (final id in [2, 3, 4, 5]) {
        expect(find.byKey(Key('partner-team-member-menu-$id')), findsOneWidget,
            reason: 'member $id');
      }
      expect(find.byKey(const Key('partner-team-invite')), findsOneWidget);
      expect(find.byKey(const Key('partner-team-leave')), findsNothing,
          reason: 'the primary owner cannot leave');
    });

    testWidgets('a manager gets actions on below-manager members only',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(),
          client: backend(accessDoc: managerAccess));
      expect(find.byKey(const Key('partner-team-member-menu-2')), findsNothing,
          reason: 'MANAGER');
      expect(find.byKey(const Key('partner-team-member-menu-3')), findsNothing,
          reason: 'FINANCE');
      expect(
          find.byKey(const Key('partner-team-member-menu-4')), findsOneWidget);
      expect(find.byKey(const Key('partner-team-leave')), findsOneWidget);
    });

    testWidgets('a viewer reads the team and is told why nothing is editable',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(),
          client: backend(accessDoc: viewerAccess));
      expect(find.byKey(const Key('partner-team-readonly')), findsOneWidget);
      expect(find.byKey(const Key('partner-team-invite')), findsNothing);
      expect(find.byKey(const Key('partner-team-member-menu-4')), findsNothing);
      expect(find.byKey(const Key('partner-team-resend-9')), findsNothing);
    });

    testWidgets('without team view nothing about the team is requested',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(),
          client: backend(accessDoc: noTeamAccess));
      expect(find.byKey(const Key('partner-team-no-access')), findsOneWidget);
      expect(log.where((r) => r.startsWith('GET /api/partner/team')), isEmpty);
    });

    testWidgets(
        'inviting: address, role, scope, review, 202 — and the generic answer',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(), client: backend());
      await tester.tap(find.byKey(const Key('partner-team-invite')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('partner-invite-email')),
          'desk2@bayview.example');
      await tester.tap(find.byKey(const Key('partner-grant-role-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerTeamRoleFrontDesk).last);
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('partner-grant-scope-0-frontDesk')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerTeamScopeProperty).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-grant-property-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bay View Hotel').last);
      await tester.pumpAndSettle();
      expect(
          find.text(en.partnerTeamGrantLabel(
              en.partnerTeamRoleFrontDesk, 'Bay View Hotel')),
          findsWidgets,
          reason: 'the review shows what will be granted');
      await tester.tap(find.byKey(const Key('partner-invite-submit')));
      await tester.pumpAndSettle();
      expect(jsonDecode(bodies.last), {
        'email': 'desk2@bayview.example',
        'grants': [
          {'role': 'FRONT_DESK', 'scope': 'PROPERTY:12'},
        ],
      });
      expect(find.text(en.partnerInviteRecorded), findsOneWidget);
      expect(find.byKey(const Key('partner-invite-dialog')), findsNothing);
    });

    testWidgets('a property manager is never offered company scope',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(),
          client: backend(accessDoc: propertyManagerAccess));
      await tester.tap(find.byKey(const Key('partner-team-invite')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-grant-role-0')));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerTeamRoleOwner), findsNothing);
      expect(find.text(en.partnerTeamRoleManager), findsNothing);
      await tester.tap(find.text(en.partnerTeamRoleViewer).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-grant-scope-0-viewer')));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerTeamScopeCompany), findsNothing);
      expect(find.text(en.partnerTeamScopeProperty), findsWidgets);
    });

    testWidgets(
        'an unavailable email service is a clear error and nothing is added',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(),
          client: backend(overrides: {
            'POST /partner/team/invitations': () =>
                json(error(503, 'EMAIL_DELIVERY_UNAVAILABLE'), 503),
          }));
      await tester.tap(find.byKey(const Key('partner-team-invite')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('partner-invite-email')), 'a@b.example');
      await tester.tap(find.byKey(const Key('partner-grant-role-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerTeamRoleViewer).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-grant-scope-0-viewer')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.partnerTeamScopeCompany).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-invite-submit')));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerTeamErrorEmailUnavailable), findsOneWidget);
      expect(find.byKey(const Key('partner-invite-dialog')), findsOneWidget,
          reason: 'the form stays for a retry');
      expect(find.text(en.partnerInviteRecorded), findsNothing);
    });

    testWidgets('resend waits out the cooldown and stops at the limit',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(),
          client: backend(invitations: [
            invitation(9, 'fresh@b.example', lastSent: DateTime.now().toUtc()),
            invitation(10, 'tired@b.example', resends: 5),
            invitation(11, 'ok@b.example'),
          ]));
      TextButton resend(int id) =>
          tester.widget<TextButton>(find.byKey(Key('partner-team-resend-$id')));
      expect(resend(9).onPressed, isNull);
      expect(find.byKey(const Key('partner-team-invitation-cooldown-9')),
          findsOneWidget);
      expect(resend(10).onPressed, isNull);
      expect(find.text(en.partnerInviteResendLimit), findsOneWidget);
      expect(resend(11).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('partner-team-resend-11')));
      await tester.pumpAndSettle();
      expect(log, contains('POST /api/partner/team/invitations/11/resend'));
      expect(find.text(en.partnerInviteResent), findsOneWidget);
    });

    // Browser smoke test: Resend stayed disabled after the cooldown until a
    // manual refresh.
    testWidgets('resend becomes available when the cooldown ends',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(),
          client: backend(invitations: [
            invitation(9, 'fresh@b.example',
                lastSent: DateTime.now()
                    .toUtc()
                    .subtract(const Duration(seconds: 58))),
          ]));
      TextButton resend() => tester
          .widget<TextButton>(find.byKey(const Key('partner-team-resend-9')));
      expect(resend().onPressed, isNull);
      final requests = log.length;
      await tester.pump(const Duration(seconds: 3));
      expect(resend().onPressed, isNotNull);
      expect(find.byKey(const Key('partner-team-invitation-cooldown-9')),
          findsNothing);
      expect(log.length, requests, reason: 'no reload is needed');
    });

    testWidgets('revoking confirms, sends the reason and refreshes',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(), client: backend());
      await tester.tap(find.byKey(const Key('partner-team-revoke-9')));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerInviteRevokeBody('new@bayview.example')),
          findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('partner-team-confirm-reason')),
          'sent by mistake');
      await tester.tap(find.byKey(const Key('partner-team-confirm-action')));
      await tester.pumpAndSettle();
      expect(log, contains('DELETE /api/partner/team/invitations/9'));
      expect(bodies.last, jsonEncode({'reason': 'sent by mistake'}));
      expect(find.text(en.partnerInviteRevoked), findsOneWidget);
    });

    testWidgets(
        'editing access sends the version; a conflict reloads and says so',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(),
          client: backend(overrides: {
            'PUT /grants': () =>
                json(error(409, 'CONCURRENT_MODIFICATION'), 409),
          }));
      await tester.tap(find.byKey(const Key('partner-team-member-menu-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-team-edit-4')));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const Key('partner-edit-grants-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('partner-edit-grants-submit')));
      await tester.pumpAndSettle();
      expect(jsonDecode(bodies.last)['version'], 3);
      expect(find.byKey(const Key('partner-edit-grants-dialog')), findsNothing);
      expect(find.text(en.partnerTeamConcurrentReloaded), findsOneWidget);
      expect(
          log.where((r) => r == 'PUT /api/partner/team/4/grants'), hasLength(1),
          reason: 'never retried silently');
    });

    testWidgets(
        'suspend and remove ask first; a refusal keeps the list as it was',
        (tester) async {
      await pump(tester, const PartnerTeamScreen(),
          client: backend(overrides: {
            'DELETE /partner/team/4': () =>
                json(error(409, 'LAST_OWNER_REQUIRED'), 409),
          }));
      await tester.tap(find.byKey(const Key('partner-team-member-menu-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-team-suspend-4')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('partner-team-confirm')), findsOneWidget);
      await tester.tap(find.byKey(const Key('partner-team-confirm-action')));
      await tester.pumpAndSettle();
      expect(log, contains('POST /api/partner/team/4/suspend'));
      expect(find.text(en.partnerTeamSuspended), findsOneWidget);

      await tester.tap(find.byKey(const Key('partner-team-member-menu-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-team-remove-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-team-confirm-action')));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerTeamErrorLastOwner), findsOneWidget);
      expect(find.text('desk@bayview.example'), findsOneWidget);
    });

    testWidgets(
        'an owner-level change confirms the password once and retries once',
        (tester) async {
      var calls = 0;
      final r = await pump(tester, const PartnerTeamScreen(),
          client: backend(overrides: {
            'POST /partner/team/2/suspend': () {
              calls++;
              return calls == 1
                  ? json(error(403, 'STEP_UP_REQUIRED'), 403)
                  : json(
                      member(2, 'manager@bayview.example',
                          [g('MANAGER', 'COMPANY:7')],
                          status: 'SUSPENDED'),
                      200);
            },
          }));
      await tester.tap(find.byKey(const Key('partner-team-member-menu-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-team-suspend-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-team-confirm-action')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('partner-step-up-dialog')), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('partner-step-up-password')), 'correct-horse');
      await tester.tap(find.byKey(const Key('partner-step-up-confirm')));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(log, contains('POST /api/me/step-up'));
      expect(r.app.api.token, 'fresh-session-token');
      final prefs = await SharedPreferences.getInstance();
      expect(
          prefs
              .getKeys()
              .any((k) => '${prefs.get(k)}'.contains('correct-horse')),
          isFalse,
          reason: 'the password is never stored');
      expect(find.text(en.partnerTeamSuspended), findsOneWidget);
    });

    testWidgets('a member can leave after confirming', (tester) async {
      await pump(tester, const PartnerTeamScreen(),
          client: backend(accessDoc: managerAccess));
      await tester.tap(find.byKey(const Key('partner-team-leave')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-team-confirm-action')));
      await tester.pumpAndSettle();
      expect(log, contains('POST /api/partner/team/leave'));
    });

    for (final (size, table) in const [
      (Size(1600, 3200), true),
      (Size(390, 4200), false),
      (Size(320, 5200), false)
    ]) {
      testWidgets('lays out without overflow at $size', (tester) async {
        final errors = layoutErrors(tester);
        await pump(tester, const PartnerTeamScreen(),
            client: backend(), size: size);
        expect(errors, isEmpty);
        expect(find.text(en.partnerTeamColumnMember.toUpperCase()),
            table ? findsOneWidget : findsNothing);
      });
    }

    testWidgets('member actions are labelled for assistive technology',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const PartnerTeamScreen(), client: backend());
      final menu = tester.widget<PopupMenuButton<String>>(
          find.byKey(const Key('partner-team-member-menu-4')));
      expect(menu.tooltip, en.partnerTeamMemberActions('Member 4'));
      expect(
          find.bySemanticsLabel(
              RegExp(RegExp.escape(en.partnerTeamPrimaryOwnerProtected))),
          findsOneWidget);
      semantics.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // Invitation link and acceptance (§14)
  // ═══════════════════════════════════════════════════════════════════════

  group('invitation link', () {
    test('the token comes from the fragment only, never from a query', () {
      PartnerInvitationLink.capture(
          from: Uri.parse(
              'https://partner.example/accept-invitation#token=abc_DEF-123'));
      expect(PartnerInvitationLink.pending, 'abc_DEF-123');
      PartnerInvitationLink.clear();
      PartnerInvitationLink.capture(
          from:
              Uri.parse('https://partner.example/accept-invitation?token=abc'));
      expect(PartnerInvitationLink.pending, isNull);
      PartnerInvitationLink.capture(
          from: Uri.parse('https://partner.example/accept-invitation#other=1'));
      expect(PartnerInvitationLink.pending, isNull,
          reason: 'a fragment without a token is no token');
    });

    // Browser smoke test: on the web, Flutter's history setup rewrites the
    // address bar to the bare path before the first screen builds, so a link
    // read only from the live address lost its token. The bootstrap now keeps
    // the address the app was opened at.
    test('the link is still read after the address bar dropped its fragment',
        () {
      AuthLinkToken.captureLaunch(
          from: Uri.base.replace(fragment: 'token=launch-tok'));
      PartnerInvitationLink.capture();
      expect(PartnerInvitationLink.pending, 'launch-tok');
      expect(AuthLinkToken.read(), isNull,
          reason: 'capturing it drops the launch address');
    });

    test('a launch fragment is never read at another location', () {
      AuthLinkToken.captureLaunch(
          from: Uri.base.replace(path: '/somewhere-else', fragment: 'token=x'));
      PartnerInvitationLink.capture();
      expect(PartnerInvitationLink.pending, isNull);
    });

    testWidgets('opened from the launch address, the screen offers to accept',
        (tester) async {
      AuthLinkToken.captureLaunch(
          from: Uri.base.replace(fragment: 'token=launch-tok'));
      await pump(tester, const AcceptInvitationScreen(),
          client: backend(), scroll: false);
      expect(find.byKey(const Key('partner-accept-submit')), findsOneWidget);
      expect(find.byKey(const Key('partner-accept-no-link')), findsNothing);
      expect(PartnerInvitationLink.pending, 'launch-tok');
    });

    test('the router serves the link signed out and signed in', () {
      const router = PartnerSurfaceRouter();
      expect(router.resolve('/accept-invitation'), '/accept-invitation');
      expect(router.publicLocations, contains('/accept-invitation'));
      expect(router.publicScreenAt('/accept-invitation'),
          isA<PartnerInvitationSignInScreen>());
      expect(
          router.shellAt('/accept-invitation'), isA<AcceptInvitationScreen>());
      expect(router.shellAt('/'), isNot(isA<AcceptInvitationScreen>()));
      PartnerInvitationLink.debugSet('pending-token');
      expect(router.shellAt('/'), isA<AcceptInvitationScreen>(),
          reason: 'a sign-in that started on the link returns to it');
    });

    testWidgets(
        'accepting sends the token once in the body, clears it and reports success',
        (tester) async {
      final printed = <String>[];
      final previous = debugPrint;
      debugPrint =
          (String? message, {int? wrapWidth}) => printed.add(message ?? '');
      try {
        await pump(tester,
            const AcceptInvitationScreen(initialToken: 'one-time-token-xyz'),
            client: backend(), scroll: false);
        expect(find.byKey(const Key('partner-invitation-guidance')),
            findsOneWidget);
        await tester.tap(find.byKey(const Key('partner-accept-submit')));
        await tester.tap(find.byKey(const Key('partner-accept-submit')),
            warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(log.where((r) => r == 'POST /api/me/partner-invitations/accept'),
            hasLength(1));
        expect(bodies.last, jsonEncode({'token': 'one-time-token-xyz'}));
        expect(log.any((r) => r.contains('one-time-token-xyz')), isFalse,
            reason: 'never in a URL');
        expect(find.byKey(const Key('partner-accept-success')), findsOneWidget);
        expect(PartnerInvitationLink.pending, isNull);
        final prefs = await SharedPreferences.getInstance();
        expect(
            prefs
                .getKeys()
                .any((k) => '${prefs.get(k)}'.contains('one-time-token-xyz')),
            isFalse,
            reason: 'never in durable storage');
      } finally {
        debugPrint = previous;
      }
      expect(
          printed.any((line) => line.contains('one-time-token-xyz')), isFalse,
          reason: 'never logged');
    });

    for (final (code, reason, message, finalFailure) in [
      ('INVITATION_EXPIRED', null, en.partnerAcceptErrorExpired, true),
      ('INVITATION_INVALID', null, en.partnerAcceptErrorInvalid, true),
      ('INVITATION_STALE', null, en.partnerAcceptErrorStale, true),
      (
        'INVITATION_ACCOUNT_MISMATCH',
        null,
        en.partnerAcceptErrorMismatch,
        false
      ),
      (
        'PARTNER_ACCOUNT_REQUIRED',
        null,
        en.partnerAcceptErrorPartnerAccount,
        false
      ),
      (
        'WORKSPACE_CONFLICT',
        'OWN_PROFILE_EXISTS',
        en.partnerAcceptErrorOwnCompany,
        false
      ),
      (
        'WORKSPACE_CONFLICT',
        'MEMBERSHIP_EXISTS',
        en.partnerAcceptErrorOtherWorkspace,
        false
      ),
      ('WORKSPACE_UNAVAILABLE', null, en.partnerAcceptErrorUnavailable, false),
    ]) {
      testWidgets(
          'a refused acceptance ($code${reason == null ? '' : '/$reason'}) is explained safely',
          (tester) async {
        final status = switch (code) {
          'INVITATION_EXPIRED' || 'INVITATION_INVALID' => 400,
          'INVITATION_ACCOUNT_MISMATCH' || 'PARTNER_ACCOUNT_REQUIRED' => 403,
          _ => 409,
        };
        await pump(
            tester, const AcceptInvitationScreen(initialToken: 'tok-123'),
            scroll: false,
            client: backend(overrides: {
              'POST /me/partner-invitations/accept': () =>
                  json(error(status, code, reason: reason), status),
            }));
        await tester.tap(find.byKey(const Key('partner-accept-submit')));
        await tester.pumpAndSettle();
        expect(find.text(message), findsOneWidget);
        expect(find.textContaining('tok-123'), findsNothing);
        expect(
            PartnerInvitationLink.pending, finalFailure ? isNull : 'tok-123');
        expect(find.byKey(const Key('partner-accept-submit')),
            finalFailure ? findsNothing : findsOneWidget);
      });
    }

    testWidgets('a network failure keeps the link for a retry', (tester) async {
      await pump(tester, const AcceptInvitationScreen(initialToken: 'tok-net'),
          scroll: false,
          client: backend(overrides: {
            'POST /me/partner-invitations/accept': () =>
                throw http.ClientException('offline'),
          }));
      await tester.tap(find.byKey(const Key('partner-accept-submit')));
      await tester.pumpAndSettle();
      expect(find.text(en.partnerTeamErrorNetwork), findsOneWidget);
      expect(PartnerInvitationLink.pending, 'tok-net');
    });

    testWidgets('declining confirms first and drops the link', (tester) async {
      await pump(
          tester, const AcceptInvitationScreen(initialToken: 'tok-decline'),
          client: backend(), scroll: false);
      await tester.tap(find.byKey(const Key('partner-accept-decline')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-accept-decline-confirm')));
      await tester.pumpAndSettle();
      expect(log, contains('POST /api/me/partner-invitations/decline'));
      expect(bodies.last, jsonEncode({'token': 'tok-decline'}));
      expect(find.byKey(const Key('partner-accept-declined')), findsOneWidget);
      expect(PartnerInvitationLink.pending, isNull);
    });

    testWidgets(
        'without a link the page says so and lists the caller\'s own invitations',
        (tester) async {
      await pump(tester, const AcceptInvitationScreen(),
          client: backend(mine: [
            {
              'id': 9,
              'companyId': 7,
              'companyName': 'Bay View Resorts',
              'grants': [
                {
                  'role': 'FRONT_DESK',
                  'scopeType': 'PROPERTY',
                  'scopeName': 'Bay View Hotel'
                },
              ],
              'expiresAt': '2026-10-15T00:00:00Z',
            },
          ]),
          loadWorkspace: false,
          scroll: false);
      expect(find.byKey(const Key('partner-accept-no-link')), findsOneWidget);
      expect(find.byKey(const Key('partner-accept-submit')), findsNothing);
      expect(find.text('Bay View Resorts'), findsOneWidget);
    });

    testWidgets(
        'signed out, the link shows the Partner sign-in with the same guidance for everyone',
        (tester) async {
      PartnerInvitationLink.debugSet('tok-signed-out');
      await pump(tester, const PartnerInvitationSignInScreen(),
          client: backend(), loadWorkspace: false, scroll: false);
      expect(
          find.byKey(const Key('partner-invitation-guidance')), findsOneWidget);
      expect(find.text(en.partnerAcceptGuidance), findsOneWidget);
      expect(PartnerInvitationLink.pending, 'tok-signed-out',
          reason: 'kept in memory across the sign-in');
    });
  });
}
