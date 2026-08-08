import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/trips/real_trip_collaboration_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget testApp({required Widget child, AppState? app, Locale? locale}) {
    return AppScope(
      notifier: app ?? AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  Future<void> pumpSize(WidgetTester tester, Widget widget, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

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

  AppState realApp(http.Client client) => AppState(
        api: ApiClient(client: client)..demoMode = false,
      )..demoMode = false;

  AppState demoApp(http.Client client) =>
      AppState(api: ApiClient(client: client));

  Map<String, dynamic> collaboratorJson({
    int id = 11,
    String role = 'VIEWER',
    bool active = true,
    String email = 'friend@example.com',
    String fullName = 'Friend Nguyen',
  }) =>
      {
        'id': id,
        'tripPlanId': 7,
        'userId': 42,
        'userEmail': email,
        'userFullName': fullName,
        'role': role,
        'active': active,
        'invitedAt': '2030-04-01T08:00:00Z',
        'acceptedAt': '2030-04-01T08:00:00Z',
        'createdAt': '2030-04-01T08:00:00Z',
        'updatedAt': '2030-04-01T08:00:00Z',
      };

  Map<String, dynamic> shareJson(bool isPublic) =>
      {'tripId': 7, 'isPublic': isPublic};

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/trips/7/collaborators');
  bool invitePath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/trips/7/collaborators');
  bool updatePath(http.Request r) =>
      r.method == 'PATCH' &&
      RegExp(r'/me/trips/7/collaborators/\d+$').hasMatch(r.url.path);
  bool removePath(http.Request r) =>
      r.method == 'DELETE' &&
      RegExp(r'/me/trips/7/collaborators/\d+$').hasMatch(r.url.path);
  bool publicPath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/me/trips/7/public');
  bool privatePath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/me/trips/7/private');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onInvite,
    Future<http.Response> Function(http.Request)? onUpdate,
    Future<http.Response> Function(http.Request)? onRemove,
    Future<http.Response> Function(http.Request)? onPublic,
    Future<http.Response> Function(http.Request)? onPrivate,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (invitePath(request)) {
          return (onInvite ??
              (_) async =>
                  jsonResponse(collaboratorJson(id: 99), 201))(request);
        }
        if (updatePath(request)) {
          return (onUpdate ??
              (_) async =>
                  jsonResponse(collaboratorJson(role: 'EDITOR'), 200))(request);
        }
        if (removePath(request)) {
          return (onRemove ?? (_) async => http.Response('', 204))(request);
        }
        if (publicPath(request)) {
          return (onPublic ??
              (_) async => jsonResponse(shareJson(true), 200))(request);
        }
        if (privatePath(request)) {
          return (onPrivate ??
              (_) async => jsonResponse(shareJson(false), 200))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([collaboratorJson()], 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  RealCollaboratorPayload payload() => const RealCollaboratorPayload(
        email: 'new@example.com',
        role: TripCollaboratorRole.editor,
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('list parses; role/active; correct path', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) seen = r;
      });
      expect(await app.loadRealCollaborators(7), CollaborationOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/7/collaborators'), isTrue);
      final c = app.realCollaboratorsFor(7).single;
      expect(c.id, 11);
      expect(c.userEmail, 'friend@example.com');
      expect(c.userFullName, 'Friend Nguyen');
      expect(c.roleView, TripCollaboratorRole.viewer);
      expect(c.active, isTrue);
    });

    test('role mapper + wire code; unknown → null', () {
      expect(collaboratorRoleFromCode('EDITOR'), TripCollaboratorRole.editor);
      expect(collaboratorRoleFromCode('NOPE'), isNull);
      expect(TripCollaboratorRole.viewer.code, 'VIEWER');
    });

    test('payload toJson emits email + role wire', () {
      final json = payload().toJson();
      expect(json['email'], 'new@example.com');
      expect(json['role'], 'EDITOR');
    });

    test('share fromJson', () {
      final s = RealTripShare.fromJson(shareJson(true));
      expect(s.tripId, 7);
      expect(s.isPublic, isTrue);
    });

    test('non-list body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('{}', 200)));
      expect(
          await app.loadRealCollaborators(7), CollaborationOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse([collaboratorJson()], 200);
      }));
      expect(await app.loadRealCollaborators(7),
          CollaborationOutcome.demoUnavailable);
      expect(await app.inviteRealCollaborator(7, payload()),
          CollaborationOutcome.demoUnavailable);
      expect(await app.updateRealCollaboratorRole(7, 11, payload()),
          CollaborationOutcome.demoUnavailable);
      expect(await app.removeRealCollaborator(7, 11),
          CollaborationOutcome.demoUnavailable);
      expect(await app.setRealTripPublic(7, true),
          CollaborationOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realCollaboratorsFor(7), isEmpty);
    });
  });

  // ── CRUD ────────────────────────────────────────────────────────────────────

  group('CRUD', () {
    test('cached list not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) gets++;
      });
      await app.loadRealCollaborators(7);
      await app.loadRealCollaborators(7);
      expect(gets, 1);
      await app.loadRealCollaborators(7, refresh: true);
      expect(gets, 2);
    });

    test('seedIsPublic seeds the toggle on first load', () async {
      final app = routedApp();
      await app.loadRealCollaborators(7, seedIsPublic: true);
      expect(app.realCollabIsPublicFor(7), isTrue);
    });

    test('invite POSTs the payload and reloads', () async {
      Map<String, dynamic>? body;
      var listGets = 0;
      final app = routedApp(
        onRequest: (r) {
          if (listPath(r)) listGets++;
        },
        onInvite: (r) async {
          body = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(collaboratorJson(id: 99), 201);
        },
      );
      await app.loadRealCollaborators(7);
      expect(listGets, 1);
      expect(await app.inviteRealCollaborator(7, payload()),
          CollaborationOutcome.success);
      expect(body!['email'], 'new@example.com');
      expect(body!['role'], 'EDITOR');
      expect(listGets, 2);
    });

    test('blank email → validation, no HTTP', () async {
      var calls = 0;
      final app = routedApp(onRequest: (_) => calls++);
      const blank = RealCollaboratorPayload(
          email: '   ', role: TripCollaboratorRole.viewer);
      expect(await app.inviteRealCollaborator(7, blank),
          CollaborationOutcome.validation);
      expect(await app.updateRealCollaboratorRole(7, 11, blank),
          CollaborationOutcome.validation);
      expect(calls, 0);
    });

    test('update role PATCHes the collaborator id and reloads', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (updatePath(r)) seen = r;
      });
      await app.loadRealCollaborators(7);
      expect(await app.updateRealCollaboratorRole(7, 11, payload()),
          CollaborationOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/7/collaborators/11'), isTrue);
    });

    test('remove DELETEs and reloads', () async {
      http.Request? seen;
      var listGets = 0;
      final app = routedApp(onRequest: (r) {
        if (removePath(r)) seen = r;
        if (listPath(r)) listGets++;
      });
      await app.loadRealCollaborators(7);
      expect(await app.removeRealCollaborator(7, 11),
          CollaborationOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/7/collaborators/11'), isTrue);
      expect(listGets, 2);
    });

    test('setPublic PATCHes /public and stores response state', () async {
      final seen = <String>[];
      final app = routedApp(onRequest: (r) {
        if (publicPath(r) || privatePath(r)) seen.add(r.url.path);
      });
      await app.loadRealCollaborators(7);
      expect(
          await app.setRealTripPublic(7, true), CollaborationOutcome.success);
      expect(app.realCollabIsPublicFor(7), isTrue);
      expect(
          await app.setRealTripPublic(7, false), CollaborationOutcome.success);
      expect(app.realCollabIsPublicFor(7), isFalse);
      expect(seen[0].endsWith('/me/trips/7/public'), isTrue);
      expect(seen[1].endsWith('/me/trips/7/private'), isTrue);
    });
  });

  // ── Errors / permissions ─────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/collaborators'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealCollaborators(7),
          CollaborationOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('load 403 → forbidden (owner-only)', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/trips/7/collaborators'), 403),
      );
      expect(
          await app.loadRealCollaborators(7), CollaborationOutcome.forbidden);
    });

    test('invite 404 → notFound; 409 → conflict; 400 → validation', () async {
      final nf = routedApp(
        onInvite: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/trips/7/collaborators'), 404),
      );
      expect(await nf.inviteRealCollaborator(7, payload()),
          CollaborationOutcome.notFound);

      final conflict = routedApp(
        onInvite: (_) async =>
            jsonResponse(errorBody(409, 'x', '/me/trips/7/collaborators'), 409),
      );
      expect(await conflict.inviteRealCollaborator(7, payload()),
          CollaborationOutcome.conflict);

      final inv = routedApp(
        onInvite: (_) async =>
            jsonResponse(errorBody(400, 'x', '/me/trips/7/collaborators'), 400),
      );
      expect(await inv.inviteRealCollaborator(7, payload()),
          CollaborationOutcome.validation);
    });

    test('list 500 → serverError; network', () async {
      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/trips/7/collaborators'), 500),
      );
      expect(
          await se.loadRealCollaborators(7), CollaborationOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealCollaborators(7), CollaborationOutcome.network);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onList: (_) async => fail
            ? jsonResponse(
                errorBody(500, 'x', '/me/trips/7/collaborators'), 500)
            : jsonResponse([collaboratorJson()], 200),
      );
      await app.loadRealCollaborators(7);
      expect(app.realCollaboratorsFor(7), isNotEmpty);
      fail = true;
      expect(await app.loadRealCollaborators(7, refresh: true),
          CollaborationOutcome.serverError);
      expect(app.realCollaboratorsFor(7), isNotEmpty);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all collaboration state', () async {
      final app = routedApp();
      await app.loadRealCollaborators(7, seedIsPublic: true);
      expect(app.realCollaboratorsFor(7), isNotEmpty);
      await app.logout();
      expect(app.realCollaboratorsFor(7), isEmpty);
      expect(app.realCollabIsPublicFor(7), isNull);
      expect(app.realCollabTripId, isNull);
      expect(app.realCollabLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders content, share card + collaborator card', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealTripCollaborationScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('collab-content')), findsOneWidget);
      expect(find.byKey(const Key('collab-share-card')), findsOneWidget);
      expect(find.byKey(const Key('collab-card-11')), findsOneWidget);
    });

    testWidgets('invite opens the form; saving POSTs and closes', (t) async {
      var invited = 0;
      final app = routedApp(onRequest: (r) {
        if (invitePath(r)) invited++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripCollaborationScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('collab-invite')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('collab-form-content')), findsOneWidget);
      await t.enterText(
          find.byKey(const Key('collab-field-email')), 'x@example.com');
      await t.tap(find.byKey(const Key('collab-form-save')));
      await t.pumpAndSettle();
      expect(invited, 1);
      expect(find.byKey(const Key('collab-form-content')), findsNothing);
    });

    testWidgets('invite form blocks submit without an email (no HTTP)',
        (t) async {
      var invited = 0;
      final app = routedApp(onRequest: (r) {
        if (invitePath(r)) invited++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripCollaborationScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('collab-invite')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('collab-form-save')));
      await t.pumpAndSettle();
      expect(invited, 0);
      expect(find.byKey(const Key('collab-form-content')), findsOneWidget);
    });

    testWidgets('role edit PATCHes the collaborator', (t) async {
      var updated = 0;
      final app = routedApp(onRequest: (r) {
        if (updatePath(r)) updated++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripCollaborationScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('collab-role-11')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('collab-form-content')), findsOneWidget);
      await t.tap(find.byKey(const Key('collab-form-save')));
      await t.pumpAndSettle();
      expect(updated, 1);
    });

    testWidgets('remove confirms then DELETEs', (t) async {
      var removed = 0;
      final app = routedApp(onRequest: (r) {
        if (removePath(r)) removed++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripCollaborationScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('collab-remove-11')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('collab-remove-confirm')));
      await t.pumpAndSettle();
      expect(removed, 1);
    });

    testWidgets('public toggle PATCHes /public', (t) async {
      var toggled = 0;
      final app = routedApp(onRequest: (r) {
        if (publicPath(r)) toggled++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripCollaborationScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('collab-public-toggle')));
      await t.pumpAndSettle();
      expect(toggled, 1);
    });

    testWidgets('empty collaborators shows the empty state', (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const RealTripCollaborationScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('collab-empty')), findsOneWidget);
    });

    testWidgets('a 403 shows the owner-only error state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/trips/7/collaborators'), 403),
      );
      await pumpSize(
        t,
        testApp(child: const RealTripCollaborationScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('collab-error')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/collaborators'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealTripCollaborationScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('collab-session-expired')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI48 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.collaborationRealTitle,
        en.collaborationRealLoadingMessage,
        en.collaborationRealErrorMessage,
        en.collaborationRealForbiddenMessage,
        en.collaborationRealGoneMessage,
        en.collaborationRealNetworkMessage,
        en.collaborationRealActionErrorMessage,
        en.collaborationRealInvitedMessage,
        en.collaborationRealRoleUpdatedMessage,
        en.collaborationRealRemovedMessage,
        en.collaborationRealPublicOnMessage,
        en.collaborationRealPublicOffMessage,
        en.collaborationRealInvalidMessage,
        en.collaborationRealUserNotFoundMessage,
        en.collaborationRealAlreadyMemberMessage,
        en.collaborationRealEmptyTitle,
        en.collaborationRealEmptyMessage,
        en.collaborationRealEmailLabel,
        en.collaborationRealRoleLabel,
        en.collaborationRealEditRoleTitle,
        en.collaborationRealOwnerBadge,
        en.collaborationRealPublicLabel,
        en.collaborationRealAddSemantic,
      ];
      final viValues = <String>[
        vi.collaborationRealTitle,
        vi.collaborationRealLoadingMessage,
        vi.collaborationRealErrorMessage,
        vi.collaborationRealForbiddenMessage,
        vi.collaborationRealGoneMessage,
        vi.collaborationRealNetworkMessage,
        vi.collaborationRealActionErrorMessage,
        vi.collaborationRealInvitedMessage,
        vi.collaborationRealRoleUpdatedMessage,
        vi.collaborationRealRemovedMessage,
        vi.collaborationRealPublicOnMessage,
        vi.collaborationRealPublicOffMessage,
        vi.collaborationRealInvalidMessage,
        vi.collaborationRealUserNotFoundMessage,
        vi.collaborationRealAlreadyMemberMessage,
        vi.collaborationRealEmptyTitle,
        vi.collaborationRealEmptyMessage,
        vi.collaborationRealEmailLabel,
        vi.collaborationRealRoleLabel,
        vi.collaborationRealEditRoleTitle,
        vi.collaborationRealOwnerBadge,
        vi.collaborationRealPublicLabel,
        vi.collaborationRealAddSemantic,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.collaborationRealTitle, isNot(vi.collaborationRealTitle));
    });

    test('parameterized + reused demo keys resolve', () {
      final en = AppLocalizationsEn();
      expect(en.collaborationRealRemoveConfirmMessage('Friend'),
          contains('Friend'));
      expect(en.collaborationRoleViewer.trim(), isNotEmpty);
      expect(en.collaborationRoleEditor.trim(), isNotEmpty);
      expect(en.collaborationActiveLabel.trim(), isNotEmpty);
      expect(en.collaborationInviteAction.trim(), isNotEmpty);
      expect(en.collaborationRemoveConfirmTitle.trim(), isNotEmpty);
    });
  });
}
