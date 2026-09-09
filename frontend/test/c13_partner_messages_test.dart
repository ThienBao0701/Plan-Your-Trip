import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/messages/partner_messages_screen.dart';
import 'package:planyourtrip_frontend/features/partner/messages/partner_messages_state.dart';
import 'package:planyourtrip_frontend/features/partner/partner_module_screen.dart';
import 'package:planyourtrip_frontend/features/partner/partner_navigation.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:planyourtrip_frontend/shared/widgets/glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// D5 — Partner Messaging (guest↔host conversations).
///
/// Encodes what the pre-implementation verification established:
///
///  * `PartnerConversationController` gives a partner exactly five endpoints;
///    D5 uses four of them. **Close is deliberately excluded** — a CLOSED
///    conversation silently reopens on the guest's next message.
///  * `POST /{id}/messages` answers **201**, and only 201 is success.
///  * There is no idempotency key and no duplicate protection, so a send that
///    times out is `uncertain` and is **never retried automatically**.
///  * Cross-partner access is a uniform **404**, never 403 — the UI must not
///    reveal that a conversation belongs to somebody else.
///  * `GET /partner/conversations` is **unpaginated** and returns the complete
///    inbox; nothing is re-sorted client-side.
///  * `ConversationSummaryResponse` has **no `userName`** — the inbox row cannot
///    name the guest, and must not invent one. The thread response does.
///  * Only `PATCH /read` clears `unreadCount`; sending does not.
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

  Map<String, dynamic> extranetHomeJson({int unreadMessages = 0}) => {
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
        'unreadMessages': unreadMessages,
        'unreadNotifications': 0,
        'pendingReviews': 0,
        'activePromotions': 0,
        'quickActions': <Object>[],
      };

  Map<String, dynamic> hotelJson() => {
        'id': 11,
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

  /// `ConversationDto.ConversationSummaryResponse` — note there is **no
  /// `userName`**: the inbox row genuinely cannot name the guest.
  Map<String, dynamic> summaryJson({
    int id = 1,
    String? bookingCode = 'BK-1001',
    String? subject = 'Late check-in',
    String status = 'OPEN',
    String? lastMessageAt = '2026-09-01T10:00:00Z',
    String? lastMessagePreview = 'Could we arrive at 11pm?',
    int unreadCount = 0,
  }) =>
      {
        'id': id,
        'bookingId': 500 + id,
        'bookingCode': bookingCode,
        'subject': subject,
        'status': status,
        'lastMessageAt': lastMessageAt,
        'lastMessagePreview': lastMessagePreview,
        'unreadCount': unreadCount,
        'createdAt': '2026-08-30T01:12:27Z',
      };

  Map<String, dynamic> messageJson({
    int id = 1,
    int conversationId = 1,
    String senderRole = 'USER',
    String? senderName = 'Mai Tran',
    String body = 'Could we arrive at 11pm?',
    bool readByPartner = false,
    String createdAt = '2026-09-01T10:00:00Z',
  }) =>
      {
        'id': id,
        'conversationId': conversationId,
        'senderUserId': senderRole == 'PARTNER' ? 42 : 9,
        'senderName': senderName,
        'senderRole': senderRole,
        'body': body,
        'readByUser': senderRole == 'USER',
        'readByPartner': readByPartner,
        'createdAt': createdAt,
      };

  /// `ConversationDto.ConversationResponse` — this one *does* carry `userName`.
  Map<String, dynamic> threadJson({
    int id = 1,
    String status = 'OPEN',
    String? userName = 'Mai Tran',
    String? bookingCode = 'BK-1001',
    List<Map<String, dynamic>>? messages,
  }) =>
      {
        'id': id,
        'bookingId': 500 + id,
        'bookingCode': bookingCode,
        'userId': 9,
        'userName': userName,
        'partnerProfileId': 7,
        'partnerBusinessName': 'Bay View Resorts',
        'status': status,
        'subject': 'Late check-in',
        'lastMessageAt': '2026-09-01T10:00:00Z',
        'createdAt': '2026-08-30T01:12:27Z',
        'updatedAt': '2026-09-01T10:00:00Z',
        'messages': messages ?? [messageJson()],
      };

  late List<String> requestLog;
  late List<Map<String, dynamic>> writeBodies;
  setUp(() {
    requestLog = <String>[];
    writeBodies = <Map<String, dynamic>>[];
  });

  int countOf(String needle) =>
      requestLog.where((e) => e.contains(needle)).length;

  MockClient d5Client({
    List<Map<String, dynamic>>? conversations,
    Map<String, dynamic>? thread,
    int? listStatus,
    int? threadStatus,
    int? sendStatus,
    int? readStatus,
    bool sendTimesOut = false,
    bool throwNetwork = false,
    bool conversationsThrow = false,
    Map<String, dynamic>? threadAfterSend,
  }) {
    // The thread is held as mutable server state so a successful POST changes
    // what the next GET returns — exactly how the real backend behaves, and the
    // only honest way to assert "the message appears only after a re-read".
    var threadState = thread ?? threadJson();
    return MockClient((request) async {
      final path = request.url.path;
      requestLog.add('${request.method} $path');
      if (throwNetwork) throw http.ClientException('offline');
      if (conversationsThrow && path.contains('/partner/conversations')) {
        throw http.ClientException('offline');
      }
      if (request.body.isNotEmpty) {
        final decoded = jsonDecode(request.body);
        if (decoded is Map<String, dynamic>) writeBodies.add(decoded);
      }

      if (path.endsWith('/partner/profile')) {
        return jsonResponse(profileJson(), 200);
      }
      if (path.endsWith('/partner/extranet/home')) {
        return jsonResponse(extranetHomeJson(), 200);
      }
      if (path.endsWith('/partner/hotels')) {
        return jsonResponse([hotelJson()], 200);
      }

      // POST /partner/conversations/{id}/messages
      if (path.endsWith('/messages') &&
          path.contains('/partner/conversations/')) {
        if (sendTimesOut) {
          // Outlast the client's 8s timeout without a real wall-clock wait:
          // `fakeAsync` inside `pumpAndSettle` advances the timer for us.
          await Future<void>.delayed(const Duration(seconds: 30));
          return jsonResponse(messageJson(id: 99), 201);
        }
        final code = sendStatus ?? 201;
        if (code != 201) {
          return jsonResponse(errorBody(code, 'refused', path), code);
        }
        // The server now holds the new message; the next GET will show it.
        if (threadAfterSend != null) threadState = threadAfterSend;
        return jsonResponse(
          messageJson(
              id: 99,
              senderRole: 'PARTNER',
              senderName: 'Le Minh',
              body: 'Yes, that is fine.'),
          201,
        );
      }

      // PATCH /partner/conversations/{id}/read
      if (path.endsWith('/read') && path.contains('/partner/conversations/')) {
        final code = readStatus ?? 200;
        if (code != 200) {
          return jsonResponse(errorBody(code, 'refused', path), code);
        }
        return jsonResponse(threadState, 200);
      }

      // GET /partner/conversations/{id}
      final detail = RegExp(r'/partner/conversations/(\d+)$').firstMatch(path);
      if (detail != null) {
        final code = threadStatus ?? 200;
        if (code != 200) {
          return jsonResponse(errorBody(code, 'Not found', path), code);
        }
        return jsonResponse(threadState, 200);
      }

      // GET /partner/conversations
      if (path.endsWith('/partner/conversations')) {
        final code = listStatus ?? 200;
        if (code != 200) {
          return jsonResponse(errorBody(code, 'refused', path), code);
        }
        return jsonResponse(conversations ?? [summaryJson()], 200);
      }

      return jsonResponse(errorBody(404, 'Not found', path), 404);
    });
  }

  AppState partnerApp(http.Client client, {AppRole role = AppRole.partner}) =>
      AppState(api: ApiClient(client: client)..demoMode = false)
        ..demoMode = false
        ..email = 'partner@planyourtrip.com'
        ..role = role;

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
    WidgetTester tester, {
    http.Client? client,
    Size size = const Size(1600, 3600),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? d5Client());
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp(
      app: app,
      partner: partner,
      child: const PartnerMessagesScreen(),
      locale: locale,
    ));
    await tester.pumpAndSettle();
    return (app: app, partner: partner);
  }

  // ── 1. Navigation registration ─────────────────────────────────────────────

  group('navigation registration', () {
    test('the messages destination is marked implemented', () {
      final messages =
          PartnerNavigation.destinations.firstWhere((d) => d.key == 'messages');
      expect(messages.implemented, isTrue);
      expect(messages.route, '/partner/messages');
      expect(messages.badge, PartnerNavBadge.unreadMessages);
    });

    testWidgets('the module renders the real screen, not the placeholder',
        (tester) async {
      await pumpScreen(tester);
      expect(find.byType(PartnerMessagesScreen), findsOneWidget);
      // The "planned" placeholder must be gone for this destination.
      expect(find.byType(PartnerModuleScreen), findsNothing);
      expect(find.text(en.partnerModulePlannedBadge), findsNothing);
      expect(find.byKey(const Key('partner-messages-title')), findsOneWidget);
    });
  });

  // ── 2. Inbox ──────────────────────────────────────────────────────────────

  group('inbox', () {
    testWidgets('empty inbox shows the empty state, never a fabricated row',
        (tester) async {
      await pumpScreen(tester, client: d5Client(conversations: const []));
      expect(find.byKey(const Key('partner-messages-empty')), findsOneWidget);
      expect(find.text(en.partnerMessagesEmptyTitle), findsOneWidget);
      expect(find.byKey(const Key('partner-messages-row-1')), findsNothing);
    });

    testWidgets('renders the conversations the server returned',
        (tester) async {
      await pumpScreen(
        tester,
        client: d5Client(conversations: [
          summaryJson(
              id: 1,
              subject: 'Late check-in',
              lastMessagePreview: 'Arriving at 11pm'),
          summaryJson(
              id: 2,
              subject: 'Parking',
              bookingCode: 'BK-1002',
              lastMessagePreview: 'Is parking free?'),
        ]),
      );
      expect(find.byKey(const Key('partner-messages-row-1')), findsOneWidget);
      expect(find.byKey(const Key('partner-messages-row-2')), findsOneWidget);
      expect(find.text('Late check-in'), findsOneWidget);
      expect(find.text('Parking'), findsOneWidget);
      expect(
          find.text(en.partnerMessagesBookingLabel('BK-1001')), findsOneWidget);
      expect(
          find.text(en.partnerMessagesBookingLabel('BK-1002')), findsOneWidget);
      expect(find.text('Arriving at 11pm'), findsOneWidget);
      expect(find.text('Is parking free?'), findsOneWidget);
    });

    testWidgets('unreadCount renders only when above zero', (tester) async {
      await pumpScreen(
        tester,
        client: d5Client(conversations: [
          summaryJson(id: 1, unreadCount: 3),
          summaryJson(id: 2, unreadCount: 0),
        ]),
      );
      expect(
          find.byKey(const Key('partner-messages-unread-1')), findsOneWidget);
      expect(find.text(en.partnerMessagesUnreadBadge(3)), findsOneWidget);
      expect(find.byKey(const Key('partner-messages-unread-2')), findsNothing);
    });

    testWidgets('null lastMessageAt, preview and subject render safely',
        (tester) async {
      await pumpScreen(
        tester,
        client: d5Client(conversations: [
          summaryJson(
            id: 1,
            subject: null,
            lastMessageAt: null,
            lastMessagePreview: null,
          ),
        ]),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(en.partnerMessagesNoSubject), findsOneWidget);
      expect(find.text(en.partnerMessagesNoPreview), findsOneWidget);
    });

    testWidgets('the inbox says plainly that it is not paginated',
        (tester) async {
      await pumpScreen(tester);
      expect(find.text(en.partnerMessagesUnpaginatedNotice), findsOneWidget);
    });

    testWidgets('order is preserved exactly as served — never re-sorted',
        (tester) async {
      // Deliberately out of "newest first" order: the client must not fix it.
      await pumpScreen(
        tester,
        client: d5Client(conversations: [
          summaryJson(
              id: 1, subject: 'Older', lastMessageAt: '2026-08-01T10:00:00Z'),
          summaryJson(
              id: 2, subject: 'Newer', lastMessageAt: '2026-09-01T10:00:00Z'),
        ]),
      );
      final older = tester.getTopLeft(find.text('Older')).dy;
      final newer = tester.getTopLeft(find.text('Newer')).dy;
      expect(older, lessThan(newer));
    });
  });

  // ── 3. Thread ─────────────────────────────────────────────────────────────

  group('thread', () {
    testWidgets('opening a row loads the thread and identifies the guest',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('partner-messages-row-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('partner-messages-thread-guest')),
          findsOneWidget);
      expect(
          find.text(en.partnerMessagesGuestLabel('Mai Tran')), findsOneWidget);
      expect(find.byKey(const Key('partner-messages-thread-booking')),
          findsOneWidget);
      expect(countOf('GET /api/partner/conversations/1'), 1);
    });

    testWidgets('messages render in served order with sender attribution',
        (tester) async {
      await pumpScreen(
        tester,
        client: d5Client(
          thread: threadJson(messages: [
            messageJson(id: 1, senderRole: 'USER', body: 'Guest first'),
            messageJson(
              id: 2,
              senderRole: 'PARTNER',
              senderName: 'Le Minh',
              body: 'Host second',
              createdAt: '2026-09-01T11:00:00Z',
            ),
          ]),
        ),
      );
      await tester.tap(find.byKey(const Key('partner-messages-row-1')));
      await tester.pumpAndSettle();

      final first = tester.getTopLeft(find.text('Guest first')).dy;
      final second = tester.getTopLeft(find.text('Host second')).dy;
      expect(first, lessThan(second), reason: 'backend order is oldest-first');

      // The host is "You"; the guest is named by the server.
      expect(find.text(en.partnerMessagesSenderHost), findsOneWidget);
      expect(find.text('Mai Tran'), findsOneWidget);
    });

    testWidgets('a thread with no messages says so', (tester) async {
      await pumpScreen(tester,
          client: d5Client(thread: threadJson(messages: const [])));
      await tester.tap(find.byKey(const Key('partner-messages-row-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('partner-messages-thread-empty')),
          findsOneWidget);
    });

    testWidgets(
        'mark-read fires after a successful load and refreshes the list',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('partner-messages-row-1')));
      await tester.pumpAndSettle();

      expect(countOf('PATCH /api/partner/conversations/1/read'), 1);
      // The list is re-read so the row's unreadCount matches the server.
      expect(
          countOf('GET /api/partner/conversations'), greaterThanOrEqualTo(2));
    });

    testWidgets('a failed mark-read is best effort — the thread stays',
        (tester) async {
      await pumpScreen(tester, client: d5Client(readStatus: 500));
      await tester.tap(find.byKey(const Key('partner-messages-row-1')));
      await tester.pumpAndSettle();

      expect(countOf('PATCH /api/partner/conversations/1/read'), 1);
      // Still on screen, fully rendered. The bubble is thread-only, so this
      // cannot be satisfied by the inbox row's preview text.
      expect(find.byKey(const Key('partner-messages-thread-guest')),
          findsOneWidget);
      expect(
          find.byKey(const Key('partner-messages-bubble-1')), findsOneWidget);
    });

    testWidgets('back returns to the inbox', (tester) async {
      await pumpScreen(tester, size: const Size(900, 2400));
      await tester.tap(find.byKey(const Key('partner-messages-row-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('partner-messages-back')), findsOneWidget);

      await tester.tap(find.byKey(const Key('partner-messages-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('partner-messages-row-1')), findsOneWidget);
      expect(find.byKey(const Key('partner-messages-composer')), findsNothing);
    });
  });

  // ── 4. Sending ────────────────────────────────────────────────────────────

  group('sending', () {
    Future<void> openThread(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('partner-messages-row-1')));
      await tester.pumpAndSettle();
    }

    testWidgets('the send request uses the partner URI and a {"body"} payload',
        (tester) async {
      await pumpScreen(tester);
      await openThread(tester);

      await tester.enterText(find.byKey(const Key('partner-messages-composer')),
          'Yes, that is fine.');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-messages-send')));
      await tester.pumpAndSettle();

      expect(
        requestLog,
        contains('POST /api/partner/conversations/1/messages'),
      );
      // Never the customer endpoint.
      expect(countOf('/api/me/conversations'), 0);
      expect(writeBodies.last, {'body': 'Yes, that is fine.'});
    });

    testWidgets('201 is success, and the message appears only after a re-read',
        (tester) async {
      await pumpScreen(
        tester,
        client: d5Client(
          thread:
              threadJson(messages: [messageJson(id: 1, body: 'Guest asks')]),
          threadAfterSend: threadJson(messages: [
            messageJson(id: 1, body: 'Guest asks'),
            messageJson(
                id: 99,
                senderRole: 'PARTNER',
                senderName: 'Le Minh',
                body: 'Host answers',
                createdAt: '2026-09-01T12:00:00Z'),
          ]),
        ),
      );
      await openThread(tester);
      expect(find.text('Host answers'), findsNothing);

      await tester.enterText(
          find.byKey(const Key('partner-messages-composer')), 'Host answers');
      await tester.pumpAndSettle();
      // Nothing optimistic: the bubble is not on screen before the round trip.
      expect(find.byKey(const Key('partner-messages-bubble-99')), findsNothing);

      await tester.tap(find.byKey(const Key('partner-messages-send')));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerMessagesSent), findsOneWidget);
      expect(find.text('Host answers'), findsOneWidget);
      expect(
          find.byKey(const Key('partner-messages-bubble-99')), findsOneWidget);
    });

    testWidgets('a blank composer disables send and issues no request',
        (tester) async {
      await pumpScreen(tester);
      await openThread(tester);

      final before = countOf('POST');
      await tester.enterText(
          find.byKey(const Key('partner-messages-composer')), '   ');
      await tester.pumpAndSettle();

      final button = tester.widget<OceanPrimaryButton>(
          find.byKey(const Key('partner-messages-send')));
      expect(button.onPressed, isNull,
          reason: 'a blank body would be a guaranteed 400');

      // Tapping a disabled control must still issue nothing.
      await tester.tap(find.byKey(const Key('partner-messages-send')),
          warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(countOf('POST'), before);
    });

    testWidgets('a 200 on send is NOT treated as success', (tester) async {
      await pumpScreen(tester, client: d5Client(sendStatus: 200));
      await openThread(tester);
      await tester.enterText(
          find.byKey(const Key('partner-messages-composer')), 'Hello');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-messages-send')));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerMessagesSent), findsNothing);
    });

    testWidgets('422 tells the operator the thread is archived',
        (tester) async {
      await pumpScreen(tester, client: d5Client(sendStatus: 422));
      await openThread(tester);
      await tester.enterText(
          find.byKey(const Key('partner-messages-composer')), 'Hello');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-messages-send')));
      await tester.pumpAndSettle();

      expect(find.text(en.partnerMessagesArchivedNotice), findsWidgets);
    });

    testWidgets('an archived thread offers no composer at all', (tester) async {
      await pumpScreen(
        tester,
        client: d5Client(thread: threadJson(status: 'ARCHIVED')),
      );
      await openThread(tester);

      expect(find.byKey(const Key('partner-messages-archived-notice')),
          findsOneWidget);
      expect(find.byKey(const Key('partner-messages-composer')), findsNothing);
      expect(find.byKey(const Key('partner-messages-send')), findsNothing);
    });

    testWidgets('a closed thread warns that sending reopens it',
        (tester) async {
      await pumpScreen(
        tester,
        client: d5Client(thread: threadJson(status: 'CLOSED')),
      );
      await openThread(tester);

      expect(find.byKey(const Key('partner-messages-closed-notice')),
          findsOneWidget);
      // Still sendable — the backend allows it and reopens the thread.
      expect(
          find.byKey(const Key('partner-messages-composer')), findsOneWidget);
    });

    testWidgets('a send timeout is uncertain and is never retried',
        (tester) async {
      await pumpScreen(tester, client: d5Client(sendTimesOut: true));
      await openThread(tester);

      await tester.enterText(
          find.byKey(const Key('partner-messages-composer')), 'Hello');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('partner-messages-send')));
      await tester.pumpAndSettle(const Duration(seconds: 40));

      expect(find.text(en.partnerMessagesSendUncertain), findsOneWidget);
      // Exactly one POST — the client must never send it again by itself.
      expect(countOf('POST /api/partner/conversations/1/messages'), 1);
    });
  });

  // ── 5. Errors and authorization ───────────────────────────────────────────

  group('errors and authorization', () {
    testWidgets('401 gets the session-expired treatment, never a logout',
        (tester) async {
      final result =
          await pumpScreen(tester, client: d5Client(listStatus: 401));
      expect(find.byKey(const Key('partner-messages-unauthorized')),
          findsOneWidget);
      // The session is not torn down by a module-level 401.
      expect(result.app.email, 'partner@planyourtrip.com');
    });

    testWidgets('403 is surfaced as a refusal, with a retry', (tester) async {
      await pumpScreen(tester, client: d5Client(listStatus: 403));
      expect(
          find.byKey(const Key('partner-messages-forbidden')), findsOneWidget);
    });

    testWidgets('404 uses the team-member treatment, not "create a profile"',
        (tester) async {
      await pumpScreen(tester, client: d5Client(listStatus: 404));
      expect(
          find.byKey(const Key('partner-messages-notfound')), findsOneWidget);
    });

    testWidgets('a 5xx is retryable and the retry re-issues the request',
        (tester) async {
      await pumpScreen(tester, client: d5Client(listStatus: 500));
      expect(find.byKey(const Key('partner-messages-error')), findsOneWidget);
      final before = countOf('GET /api/partner/conversations');

      final retry = find.text(en.partnerActionRetry);
      expect(retry, findsWidgets, reason: 'a 5xx must offer a retry');
      await tester.tap(retry.first);
      await tester.pumpAndSettle();
      expect(countOf('GET /api/partner/conversations'), greaterThan(before));
    });

    testWidgets('a cross-partner 404 never reveals another partner',
        (tester) async {
      await pumpScreen(tester, client: d5Client(threadStatus: 404));
      await tester.tap(find.byKey(const Key('partner-messages-row-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('partner-messages-thread-unavailable')),
          findsOneWidget);
      expect(find.text(en.partnerMessagesUnavailableTitle), findsOneWidget);

      // Nothing anywhere on screen may hint at another partner.
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => (t.data ?? '').toLowerCase())
          .join(' | ');
      expect(texts.contains('another partner'), isFalse);
      expect(texts.contains('belongs to'), isFalse);
      expect(texts.contains('forbidden'), isFalse);
    });

    testWidgets('a transport failure is a retryable error, not empty data',
        (tester) async {
      // Only the conversations call fails — the workspace itself loads, so this
      // exercises the module's own error path rather than the shell's.
      await pumpScreen(tester, client: d5Client(conversationsThrow: true));
      expect(find.byKey(const Key('partner-messages-error')), findsOneWidget);
      expect(find.byKey(const Key('partner-messages-empty')), findsNothing);
    });

    testWidgets('a USER account never reaches the module', (tester) async {
      final app = partnerApp(d5Client(), role: AppRole.user);
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(
          app: app, partner: partner, child: const PartnerMessagesScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('partner-messages-title')), findsNothing);
      expect(countOf('/partner/conversations'), 0);
    });
  });

  // ── 6. Demo Mode ──────────────────────────────────────────────────────────

  group('demo mode', () {
    testWidgets('makes zero HTTP calls and fabricates nothing', (tester) async {
      final app = AppState(api: ApiClient(client: d5Client())..demoMode = true)
        ..demoMode = true
        ..email = 'demo@planyourtrip.com'
        ..role = AppRole.user;
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);

      await tester.pumpWidget(testApp(
          app: app, partner: partner, child: const PartnerMessagesScreen()));
      await tester.pumpAndSettle();

      expect(requestLog, isEmpty);
      expect(find.byKey(const Key('partner-messages-row-1')), findsNothing);
    });
  });

  // ── 7. Localization ───────────────────────────────────────────────────────

  group('localization', () {
    test('every D5 string resolves in both locales', () {
      final pairs = <String, String>{
        en.partnerMessagesTitle: vi.partnerMessagesTitle,
        en.partnerMessagesSubtitle: vi.partnerMessagesSubtitle,
        en.partnerMessagesLoading: vi.partnerMessagesLoading,
        en.partnerMessagesEmptyTitle: vi.partnerMessagesEmptyTitle,
        en.partnerMessagesEmptyMessage: vi.partnerMessagesEmptyMessage,
        en.partnerMessagesUnpaginatedNotice:
            vi.partnerMessagesUnpaginatedNotice,
        en.partnerMessagesNoPreview: vi.partnerMessagesNoPreview,
        en.partnerMessagesNoSubject: vi.partnerMessagesNoSubject,
        en.partnerMessagesBackToInbox: vi.partnerMessagesBackToInbox,
        en.partnerMessagesThreadLoading: vi.partnerMessagesThreadLoading,
        en.partnerMessagesThreadEmpty: vi.partnerMessagesThreadEmpty,
        en.partnerMessagesUnavailableTitle: vi.partnerMessagesUnavailableTitle,
        en.partnerMessagesUnavailableMessage:
            vi.partnerMessagesUnavailableMessage,
        en.partnerMessagesSenderHost: vi.partnerMessagesSenderHost,
        en.partnerMessagesSenderGuest: vi.partnerMessagesSenderGuest,
        en.partnerMessagesSenderSupport: vi.partnerMessagesSenderSupport,
        en.partnerMessagesStatusOpen: vi.partnerMessagesStatusOpen,
        en.partnerMessagesStatusClosed: vi.partnerMessagesStatusClosed,
        en.partnerMessagesStatusArchived: vi.partnerMessagesStatusArchived,
        en.partnerMessagesComposerLabel: vi.partnerMessagesComposerLabel,
        en.partnerMessagesComposerHint: vi.partnerMessagesComposerHint,
        en.partnerMessagesSend: vi.partnerMessagesSend,
        en.partnerMessagesSending: vi.partnerMessagesSending,
        en.partnerMessagesSendEmpty: vi.partnerMessagesSendEmpty,
        en.partnerMessagesSent: vi.partnerMessagesSent,
        en.partnerMessagesSendFailed: vi.partnerMessagesSendFailed,
        en.partnerMessagesSendUncertain: vi.partnerMessagesSendUncertain,
        en.partnerMessagesArchivedNotice: vi.partnerMessagesArchivedNotice,
        en.partnerMessagesClosedNotice: vi.partnerMessagesClosedNotice,
      };
      pairs.forEach((english, vietnamese) {
        expect(english, isNotEmpty);
        expect(vietnamese, isNotEmpty);
        expect(vietnamese, isNot(equals(english)));
      });

      expect(en.partnerMessagesUnreadBadge(3), contains('3'));
      expect(vi.partnerMessagesUnreadBadge(3), contains('3'));
      expect(en.partnerMessagesBookingLabel('BK-1'), contains('BK-1'));
      expect(vi.partnerMessagesBookingLabel('BK-1'), contains('BK-1'));
      expect(en.partnerMessagesGuestLabel('Mai'), contains('Mai'));
      expect(vi.partnerMessagesGuestLabel('Mai'), contains('Mai'));
      expect(en.partnerMessagesOpenSemantic('BK-1'), contains('BK-1'));
      expect(vi.partnerMessagesOpenSemantic('BK-1'), contains('BK-1'));
      expect(en.partnerMessagesUnreadTotal(3, 2), contains('3'));
      expect(vi.partnerMessagesUnreadTotal(3, 2), contains('2'));
    });

    testWidgets('the screen renders in Vietnamese', (tester) async {
      await pumpScreen(tester, locale: const Locale('vi'));
      expect(find.text(vi.partnerMessagesTitle), findsOneWidget);
      expect(find.text(vi.partnerMessagesUnpaginatedNotice), findsOneWidget);
    });
  });

  // ── 8. State-level guarantees ─────────────────────────────────────────────

  group('state guarantees', () {
    test('a second send while one is in flight is refused, not queued',
        () async {
      final completer = Completer<http.Response>();
      var posts = 0;
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          posts++;
          return completer.future;
        }
        if (request.url.path.endsWith('/partner/conversations')) {
          return jsonResponse([summaryJson()], 200);
        }
        return jsonResponse(threadJson(), 200);
      });

      final state = PartnerMessagesState(api: ApiClient(client: client));
      await state.load();
      await state.openThread(1);

      // `_sending` is set before the first await, so the second call sees it.
      final first = state.sendMessage('one');
      final second = await state.sendMessage('two');
      expect(second, PartnerSendResult.busy);

      // Let the in-flight request actually reach the client before counting.
      await Future<void>.delayed(Duration.zero);
      expect(posts, 1, reason: 'a duplicate POST would duplicate the message');

      completer.complete(jsonResponse(messageJson(id: 99), 201));
      await first;
      state.dispose();
    });

    test('unread totals come from the server, never from local arithmetic',
        () async {
      final state = PartnerMessagesState(
        api: ApiClient(
          client: MockClient((request) async => jsonResponse(
                [
                  summaryJson(id: 1, unreadCount: 2),
                  summaryJson(id: 2, unreadCount: 5)
                ],
                200,
              )),
        ),
      );
      await state.load();
      expect(state.totalUnread, 7);
      expect(state.conversations.map((c) => c.unreadCount), [2, 5]);
      state.dispose();
    });

    test('an archived thread refuses a send without any HTTP call', () async {
      var posts = 0;
      final client = MockClient((request) async {
        if (request.method == 'POST') posts++;
        if (request.url.path.endsWith('/partner/conversations')) {
          return jsonResponse([summaryJson()], 200);
        }
        return jsonResponse(threadJson(status: 'ARCHIVED'), 200);
      });
      final state = PartnerMessagesState(api: ApiClient(client: client));
      await state.load();
      await state.openThread(1);

      expect(await state.sendMessage('hello'), PartnerSendResult.archived);
      expect(posts, 0);
      state.dispose();
    });

    test('a blank body never reaches the network', () async {
      var posts = 0;
      final client = MockClient((request) async {
        if (request.method == 'POST') posts++;
        if (request.url.path.endsWith('/partner/conversations')) {
          return jsonResponse([summaryJson()], 200);
        }
        return jsonResponse(threadJson(), 200);
      });
      final state = PartnerMessagesState(api: ApiClient(client: client));
      await state.load();
      await state.openThread(1);

      expect(await state.sendMessage('   '), PartnerSendResult.validation);
      expect(posts, 0);
      state.dispose();
    });

    test('D5 never calls the close endpoint', () async {
      final calls = <String>[];
      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/partner/conversations')) {
          return jsonResponse([summaryJson()], 200);
        }
        if (request.url.path.endsWith('/read')) {
          return jsonResponse(threadJson(), 200);
        }
        return jsonResponse(threadJson(), 200);
      });
      final state = PartnerMessagesState(api: ApiClient(client: client));
      await state.load();
      await state.openThread(1);
      state.closeThread();

      expect(calls.where((c) => c.endsWith('/close')), isEmpty);
      state.dispose();
    });
  });
}
