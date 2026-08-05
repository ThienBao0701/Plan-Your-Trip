import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/conversations/real_conversation_thread_screen.dart';
import 'package:planyourtrip_frontend/features/conversations/real_conversations_screen.dart';
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

  Map<String, dynamic> summaryJson({
    int id = 1,
    String status = 'OPEN',
    int unread = 2,
  }) =>
      {
        'id': id,
        'bookingId': 5,
        'bookingCode': 'BK-100',
        'subject': 'Late check-in',
        'status': status,
        'lastMessageAt': '2030-05-01T10:00:00Z',
        'lastMessagePreview': 'See you soon',
        'unreadCount': unread,
        'createdAt': '2030-05-01T09:00:00Z',
      };

  Map<String, dynamic> messageJson({
    int id = 11,
    String role = 'USER',
    String body = 'Hello host',
    bool readByPartner = false,
  }) =>
      {
        'id': id,
        'conversationId': 1,
        'senderUserId': 9,
        'senderName': 'Bao',
        'senderRole': role,
        'body': body,
        'readByUser': true,
        'readByPartner': readByPartner,
        'createdAt': '2030-05-01T10:00:00Z',
      };

  Map<String, dynamic> conversationJson({
    int id = 1,
    String status = 'OPEN',
    List<Map<String, dynamic>>? messages,
  }) =>
      {
        'id': id,
        'bookingId': 5,
        'bookingCode': 'BK-100',
        'userId': 9,
        'userName': 'Bao',
        'partnerProfileId': 3,
        'partnerBusinessName': 'Seaside Hotel',
        'status': status,
        'subject': 'Late check-in',
        'lastMessageAt': '2030-05-01T10:00:00Z',
        'createdAt': '2030-05-01T09:00:00Z',
        'updatedAt': '2030-05-01T10:00:00Z',
        'messages': messages ??
            [
              messageJson(id: 11, role: 'USER', body: 'Hello host'),
              messageJson(id: 12, role: 'PARTNER', body: 'Hi, welcome!'),
            ],
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/conversations');
  bool detailPath(http.Request r) =>
      r.method == 'GET' &&
      RegExp(r'/me/conversations/\d+$').hasMatch(r.url.path);
  bool createPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/conversations');
  bool sendPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/messages');
  bool readPath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/read');
  bool closePath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/close');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onDetail,
    Future<http.Response> Function(http.Request)? onCreate,
    Future<http.Response> Function(http.Request)? onSend,
    Future<http.Response> Function(http.Request)? onRead,
    Future<http.Response> Function(http.Request)? onClose,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (sendPath(request)) {
          return (onSend ??
              (_) async => jsonResponse(messageJson(id: 99), 201))(request);
        }
        if (readPath(request)) {
          return (onRead ??
              (_) async => jsonResponse(conversationJson(), 200))(request);
        }
        if (closePath(request)) {
          return (onClose ??
              (_) async => jsonResponse(
                  conversationJson(status: 'CLOSED'), 200))(request);
        }
        if (createPath(request)) {
          return (onCreate ??
              (_) async => jsonResponse(conversationJson(id: 7), 201))(request);
        }
        if (detailPath(request)) {
          return (onDetail ??
              (_) async => jsonResponse(conversationJson(), 200))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([summaryJson()], 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('list + thread parse; correct paths', () async {
      final seen = <String>[];
      final app = routedApp(onRequest: (r) => seen.add(r.url.path));
      expect(await app.loadRealConversations(), ConversationOutcome.success);
      final s = app.realConversations.single;
      expect(s.id, 1);
      expect(s.statusView, ConversationStatusView.open);
      expect(s.unreadCount, 2);
      expect(s.lastMessagePreview, 'See you soon');
      expect(seen.any((p) => p.endsWith('/me/conversations')), isTrue);

      expect(
          await app.loadRealConversationDetail(1), ConversationOutcome.success);
      final c = app.realConversationDetailFor(1)!;
      expect(c.messages.length, 2);
      expect(c.messages.first.isFromUser, isTrue);
      expect(c.messages[1].senderRoleView, MessageSenderRoleView.partner);
    });

    test('status + role mappers, unknown → unknown', () {
      expect(conversationStatusViewFromCode('CLOSED'),
          ConversationStatusView.closed);
      expect(conversationStatusViewFromCode('???'),
          ConversationStatusView.unknown);
      expect(messageSenderRoleViewFromCode('SYSTEM'),
          MessageSenderRoleView.system);
      expect(
          messageSenderRoleViewFromCode('???'), MessageSenderRoleView.unknown);
    });

    test('non-list body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('{}', 200)));
      expect(
          await app.loadRealConversations(), ConversationOutcome.serverError);
    });

    test('unread total sums per-thread counts', () async {
      final app = routedApp(
        onList: (_) async => jsonResponse(
          [summaryJson(id: 1, unread: 2), summaryJson(id: 2, unread: 3)],
          200,
        ),
      );
      await app.loadRealConversations();
      expect(app.realConversationsUnreadTotal, 5);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse([summaryJson()], 200);
      }));
      expect(await app.loadRealConversations(),
          ConversationOutcome.demoUnavailable);
      expect(await app.loadRealConversationDetail(1),
          ConversationOutcome.demoUnavailable);
      expect(await app.sendRealMessage(1, 'hi'),
          ConversationOutcome.demoUnavailable);
      expect(await app.markRealConversationRead(1),
          ConversationOutcome.demoUnavailable);
      expect(await app.closeRealConversation(1),
          ConversationOutcome.demoUnavailable);
      expect(await app.createRealConversation(5),
          ConversationOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realConversations, isEmpty);
    });
  });

  // ── Load / send / read / close / create ────────────────────────────────────────

  group('Actions', () {
    test('cached list not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) gets++;
      });
      await app.loadRealConversations();
      await app.loadRealConversations();
      expect(gets, 1);
      await app.loadRealConversations(refresh: true);
      expect(gets, 2);
    });

    test('send POSTs the body and reloads the thread', () async {
      Map<String, dynamic>? body;
      var detailGets = 0;
      final app = routedApp(
        onRequest: (r) {
          if (detailPath(r)) detailGets++;
        },
        onSend: (r) async {
          body = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(messageJson(id: 99), 201);
        },
      );
      await app.loadRealConversationDetail(1);
      expect(detailGets, 1);
      expect(await app.sendRealMessage(1, '  Hi there '),
          ConversationOutcome.success);
      expect(body!['body'], 'Hi there');
      expect(detailGets, 2); // reloaded after send
    });

    test('empty message → validation, no HTTP', () async {
      var calls = 0;
      final app = routedApp(onRequest: (_) => calls++);
      expect(
          await app.sendRealMessage(1, '   '), ConversationOutcome.validation);
      expect(calls, 0);
    });

    test('mark read PATCHes and updates the thread', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (readPath(r)) seen = r;
      });
      await app.loadRealConversationDetail(1);
      expect(
          await app.markRealConversationRead(1), ConversationOutcome.success);
      expect(seen!.url.path.endsWith('/me/conversations/1/read'), isTrue);
    });

    test('close PATCHes and updates status', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (closePath(r)) seen = r;
      });
      await app.loadRealConversationDetail(1);
      expect(await app.closeRealConversation(1), ConversationOutcome.success);
      expect(seen!.url.path.endsWith('/me/conversations/1/close'), isTrue);
      expect(app.realConversationDetailFor(1)!.statusView,
          ConversationStatusView.closed);
    });

    test('create POSTs bookingId and stores the thread id', () async {
      Map<String, dynamic>? body;
      final app = routedApp(
        onCreate: (r) async {
          body = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(conversationJson(id: 7), 201);
        },
      );
      expect(await app.createRealConversation(5), ConversationOutcome.success);
      expect(body!['bookingId'], 5);
      expect(app.realConversationDetailId, 7);
    });

    test('create 422 (no partner) → unprocessable', () async {
      final app = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(422, 'x', '/me/conversations'), 422),
      );
      expect(await app.createRealConversation(5),
          ConversationOutcome.unprocessable);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/conversations'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealConversations(),
          ConversationOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('detail 403 forbidden; send 422 archived', () async {
      final f = routedApp(
        onDetail: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/conversations/1'), 403),
      );
      expect(
          await f.loadRealConversationDetail(1), ConversationOutcome.forbidden);

      final a = routedApp(
        onSend: (_) async => jsonResponse(
            errorBody(422, 'x', '/me/conversations/1/messages'), 422),
      );
      expect(
          await a.sendRealMessage(1, 'hi'), ConversationOutcome.unprocessable);
    });

    test('list 500 → serverError; network', () async {
      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/conversations'), 500),
      );
      expect(await se.loadRealConversations(), ConversationOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealConversations(), ConversationOutcome.network);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onList: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/me/conversations'), 500)
            : jsonResponse([summaryJson()], 200),
      );
      await app.loadRealConversations();
      expect(app.realConversations, isNotEmpty);
      fail = true;
      expect(await app.loadRealConversations(refresh: true),
          ConversationOutcome.serverError);
      expect(app.realConversations, isNotEmpty);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears inbox + thread state', () async {
      final app = routedApp();
      await app.loadRealConversations();
      await app.loadRealConversationDetail(1);
      expect(app.realConversations, isNotEmpty);
      expect(app.realConversationDetailFor(1), isNotNull);
      await app.logout();
      expect(app.realConversations, isEmpty);
      expect(app.realConversationDetailFor(1), isNull);
      expect(app.realConversationDetailId, isNull);
      expect(app.realConversationsLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('inbox renders content + tiles', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealConversationsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('conversations-content')), findsOneWidget);
      expect(find.byKey(const Key('conversation-tile-1')), findsOneWidget);
    });

    testWidgets('empty inbox shows the empty state', (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const RealConversationsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('conversations-empty')), findsOneWidget);
    });

    testWidgets('inbox 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/conversations'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealConversationsScreen(), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('conversations-session-expired')),
          findsOneWidget);
    });

    testWidgets('thread renders messages and sends', (t) async {
      var sent = 0;
      final app = routedApp(onRequest: (r) {
        if (sendPath(r)) sent++;
      });
      await pumpSize(
        t,
        testApp(
          child: const RealConversationThreadScreen(conversationId: 1),
          app: app,
        ),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('conversation-content')), findsOneWidget);
      expect(find.text('Hello host'), findsOneWidget);
      await t.enterText(
          find.byKey(const Key('conversation-composer')), 'A reply');
      await t.tap(find.byKey(const Key('conversation-send')));
      await t.pumpAndSettle();
      expect(sent, 1);
    });

    testWidgets('thread 403 shows the recoverable error', (t) async {
      final app = routedApp(
        onDetail: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/conversations/1'), 403),
      );
      await pumpSize(
        t,
        testApp(
          child: const RealConversationThreadScreen(conversationId: 1),
          app: app,
        ),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('conversation-error')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI41 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.conversationsTitle,
        en.conversationsLoadingMessage,
        en.conversationsErrorMessage,
        en.conversationsEmptyTitle,
        en.conversationsEmptyMessage,
        en.conversationStatusOpen,
        en.conversationStatusClosed,
        en.conversationStatusArchived,
        en.conversationUntitled,
        en.conversationLoadingMessage,
        en.conversationErrorMessage,
        en.conversationForbiddenMessage,
        en.conversationGoneMessage,
        en.conversationArchivedMessage,
        en.conversationEmptyBodyMessage,
        en.conversationNetworkMessage,
        en.conversationActionErrorMessage,
        en.conversationNoPartnerMessage,
        en.conversationCloseConfirmTitle,
        en.conversationCloseAction,
        en.conversationClosedMessage,
        en.conversationNoMessagesTitle,
        en.conversationSenderYou,
        en.conversationSenderHost,
        en.conversationSeen,
        en.conversationComposerHint,
        en.conversationSendSemantic,
        en.conversationMessageHostAction,
      ];
      final viValues = <String>[
        vi.conversationsTitle,
        vi.conversationsLoadingMessage,
        vi.conversationsErrorMessage,
        vi.conversationsEmptyTitle,
        vi.conversationsEmptyMessage,
        vi.conversationStatusOpen,
        vi.conversationStatusClosed,
        vi.conversationStatusArchived,
        vi.conversationUntitled,
        vi.conversationLoadingMessage,
        vi.conversationErrorMessage,
        vi.conversationForbiddenMessage,
        vi.conversationGoneMessage,
        vi.conversationArchivedMessage,
        vi.conversationEmptyBodyMessage,
        vi.conversationNetworkMessage,
        vi.conversationActionErrorMessage,
        vi.conversationNoPartnerMessage,
        vi.conversationCloseConfirmTitle,
        vi.conversationCloseAction,
        vi.conversationClosedMessage,
        vi.conversationNoMessagesTitle,
        vi.conversationSenderYou,
        vi.conversationSenderHost,
        vi.conversationSeen,
        vi.conversationComposerHint,
        vi.conversationSendSemantic,
        vi.conversationMessageHostAction,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.conversationsTitle, isNot(vi.conversationsTitle));
    });

    test('parameterized keys resolve in both locales', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      expect(en.conversationBookingLabel('BK-100'), contains('BK-100'));
      expect(vi.conversationBookingLabel('BK-100'), contains('BK-100'));
      expect(en.conversationUnreadBadge(3), contains('3'));
      expect(en.conversationTileSemantic('Late check-in', 2), contains('2'));
      expect(en.conversationMessageSemantic('You', 'Hi'), contains('Hi'));
    });
  });
}
