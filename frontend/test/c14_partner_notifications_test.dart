import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_role.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/core/partner/partner_state.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/partner/notifications/partner_notifications_screen.dart';
import 'package:planyourtrip_frontend/features/partner/notifications/partner_notifications_state.dart';
import 'package:planyourtrip_frontend/features/partner/partner_module_screen.dart';
import 'package:planyourtrip_frontend/features/partner/partner_navigation.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_en.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations_vi.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// D6 — Partner Notification Centre.
///
/// Encodes what the D6 contract audit established:
///
///  * D6 reuses `/api/me/notifications` exactly. **No `/api/partner/notifications`
///    exists and none is called.**
///  * The list endpoint returns **no** `relatedEntityType`/`relatedEntityId`.
///    Only `PATCH /{id}/read` does — and even then no partner destination
///    accepts an entity id, so nothing navigates.
///  * The inbox is the account's **complete** inbox; it is never filtered by
///    `notificationType`, which is not an audience field.
///  * Cross-user access is **403** here (not 404 as in conversations).
///  * Delete is a hard delete with no archive: confirmed first, applied only
///    after the server confirms.
///  * Nothing is mutated optimistically; the unread count comes from the server.
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

  Map<String, dynamic> profileJson() => {
        'id': 7,
        'userId': 42,
        'businessName': 'Bay View Resorts',
        'representativeName': 'Le Minh',
        'email': 'ops@bayview.example',
        'verificationStatus': 'APPROVED',
      };

  Map<String, dynamic> extranetHomeJson({int unreadNotifications = 0}) => {
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
        'unreadNotifications': unreadNotifications,
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

  /// `NotificationDto.NotificationSummaryResponse` — deliberately carries
  /// **no** `relatedEntityType` / `relatedEntityId`.
  Map<String, dynamic> summaryJson({
    int id = 1,
    String title = 'New review submitted',
    String message = 'A new review has been submitted for Bay View Danang.',
    String notificationType = 'REVIEW',
    String priority = 'NORMAL',
    bool read = false,
    String? createdAt = '2026-09-01T10:00:00Z',
  }) =>
      {
        'id': id,
        'title': title,
        'message': message,
        'notificationType': notificationType,
        'priority': priority,
        'read': read,
        'createdAt': createdAt,
      };

  /// `NotificationDto.NotificationResponse` — the full record returned by
  /// `PATCH /{id}/read`. This is the only shape carrying the related entity.
  Map<String, dynamic> detailJson({
    int id = 1,
    String title = 'New review submitted',
    String notificationType = 'REVIEW',
    bool read = true,
    String? relatedEntityType = 'HOTEL',
    int? relatedEntityId = 11,
  }) =>
      {
        'id': id,
        'title': title,
        'message': 'A new review has been submitted for Bay View Danang.',
        'notificationType': notificationType,
        'priority': 'NORMAL',
        'relatedEntityType': relatedEntityType,
        'relatedEntityId': relatedEntityId,
        'read': read,
        'readAt': read ? '2026-09-01T11:00:00Z' : null,
        'createdAt': '2026-09-01T10:00:00Z',
      };

  late List<String> requestLog;
  setUp(() => requestLog = <String>[]);

  int countOf(String needle) =>
      requestLog.where((e) => e.contains(needle)).length;

  MockClient d6Client({
    List<Map<String, dynamic>>? notifications,
    List<Map<String, dynamic>>? notificationsAfterMutation,
    Map<String, dynamic>? readResponse,
    int unreadCount = 1,
    int? listStatus,
    int? readStatus,
    int? readAllStatus,
    int? deleteStatus,
    bool notificationsThrow = false,
  }) {
    // Server state: a mutation changes what the next GET returns, so
    // "no optimistic mutation" can be asserted against a real re-read.
    var current = notifications ?? [summaryJson()];
    var unread = unreadCount;
    return MockClient((request) async {
      final path = request.url.path;
      requestLog.add('${request.method} $path');

      if (path.endsWith('/partner/profile')) {
        return jsonResponse(profileJson(), 200);
      }
      if (path.endsWith('/partner/extranet/home')) {
        return jsonResponse(extranetHomeJson(unreadNotifications: unread), 200);
      }
      if (path.endsWith('/partner/hotels')) {
        return jsonResponse([hotelJson()], 200);
      }

      if (notificationsThrow && path.contains('/me/notifications')) {
        throw http.ClientException('offline');
      }

      if (path.endsWith('/me/notifications/unread-count')) {
        return http.Response('$unread', 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }

      if (path.endsWith('/me/notifications/read-all')) {
        final code = readAllStatus ?? 200;
        if (code != 200) {
          return jsonResponse(errorBody(code, 'refused', path), code);
        }
        final changed = current.where((n) => n['read'] == false).length;
        current = [
          for (final n in current) {...n, 'read': true}
        ];
        unread = 0;
        return http.Response('$changed', 200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }

      final read = RegExp(r'/me/notifications/(\d+)/read$').firstMatch(path);
      if (read != null) {
        final code = readStatus ?? 200;
        if (code != 200) {
          return jsonResponse(errorBody(code, 'refused', path), code);
        }
        final id = int.parse(read.group(1)!);
        current = [
          for (final n in current)
            if (n['id'] == id) {...n, 'read': true} else n
        ];
        if (unread > 0) unread--;
        return jsonResponse(readResponse ?? detailJson(id: id), 200);
      }

      final del = RegExp(r'/me/notifications/(\d+)$').firstMatch(path);
      if (del != null && request.method == 'DELETE') {
        final code = deleteStatus ?? 204;
        if (code != 204 && code != 200) {
          return jsonResponse(errorBody(code, 'refused', path), code);
        }
        final id = int.parse(del.group(1)!);
        current = current.where((n) => n['id'] != id).toList();
        return http.Response('', 204);
      }

      if (path.endsWith('/me/notifications')) {
        final code = listStatus ?? 200;
        if (code != 200) {
          return jsonResponse(errorBody(code, 'refused', path), code);
        }
        return jsonResponse(notificationsAfterMutation ?? current, 200);
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
    Size size = const Size(1400, 3600),
    Locale? locale,
  }) async {
    final app = partnerApp(client ?? d6Client());
    final partner = PartnerState(api: app.api)..bindSession(app);
    await partner.loadWorkspace(app);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp(
      app: app,
      partner: partner,
      child: const PartnerNotificationsScreen(),
      locale: locale,
    ));
    await tester.pumpAndSettle();
    return (app: app, partner: partner);
  }

  // ── 1. Registration ───────────────────────────────────────────────────────

  group('destination registration', () {
    test('notifications is marked implemented and keeps its badge', () {
      final d = PartnerNavigation.destinations
          .firstWhere((x) => x.key == 'notifications');
      expect(d.implemented, isTrue);
      expect(d.route, '/partner/notifications');
      // The shell badge source must stay the single existing one.
      expect(d.badge, PartnerNavBadge.unreadNotifications);
    });

    test('every partner destination is now implemented', () {
      final planned = PartnerNavigation.destinations
          .where((d) => !d.implemented)
          .map((d) => d.key);
      expect(planned, isEmpty);
    });

    testWidgets('the module renders the real screen, not the placeholder',
        (tester) async {
      await pumpScreen(tester);
      expect(find.byType(PartnerNotificationsScreen), findsOneWidget);
      expect(find.byType(PartnerModuleScreen), findsNothing);
      expect(find.text(en.partnerModulePlannedBadge), findsNothing);
      expect(
          find.byKey(const Key('partner-notifications-title')), findsOneWidget);
    });
  });

  // ── 2. List ───────────────────────────────────────────────────────────────

  group('list', () {
    testWidgets('empty inbox shows the empty state and no fabricated rows',
        (tester) async {
      await pumpScreen(tester,
          client: d6Client(notifications: const [], unreadCount: 0));
      expect(
          find.byKey(const Key('partner-notifications-empty')), findsOneWidget);
      expect(
          find.byKey(const Key('partner-notifications-row-1')), findsNothing);
    });

    testWidgets('renders the notifications the server returned',
        (tester) async {
      await pumpScreen(
        tester,
        client: d6Client(notifications: [
          summaryJson(id: 1, title: 'New review submitted'),
          summaryJson(
              id: 2,
              title: 'Payout account updated',
              message: 'Your payout account details have been updated.',
              notificationType: 'PARTNER',
              read: true),
        ], unreadCount: 1),
      );
      expect(
          find.byKey(const Key('partner-notifications-row-1')), findsOneWidget);
      expect(
          find.byKey(const Key('partner-notifications-row-2')), findsOneWidget);
      expect(find.text('New review submitted'), findsOneWidget);
      expect(find.text('Payout account updated'), findsOneWidget);
      // Localized wire-code labels, reused from the existing keys.
      expect(find.text(en.notificationTypeReview), findsOneWidget);
      expect(find.text(en.notificationTypePartner), findsOneWidget);
    });

    testWidgets('unread indicator appears only on unread rows', (tester) async {
      await pumpScreen(
        tester,
        client: d6Client(notifications: [
          summaryJson(id: 1, read: false),
          summaryJson(id: 2, read: true),
        ]),
      );
      expect(find.byKey(const Key('partner-notifications-unread-1')),
          findsOneWidget);
      expect(find.byKey(const Key('partner-notifications-unread-2')),
          findsNothing);
      expect(find.text(en.partnerNotificationsUnreadLabel), findsOneWidget);
    });

    testWidgets('the unread count comes from the server, not from the list',
        (tester) async {
      // The server reports 5 while only 1 row is unread. The UI must show the
      // server's number rather than counting rows itself.
      await pumpScreen(
        tester,
        client: d6Client(
            notifications: [summaryJson(id: 1, read: false)], unreadCount: 5),
      );
      expect(countOf('GET /api/me/notifications/unread-count'), 1);
      expect(find.text(en.notificationUnreadCount(5)), findsOneWidget);
    });

    testWidgets('the inbox is never filtered by notificationType',
        (tester) async {
      await pumpScreen(
        tester,
        client: d6Client(notifications: [
          summaryJson(
              id: 1, title: 'Partner thing', notificationType: 'PARTNER'),
          summaryJson(id: 2, title: 'Trip thing', notificationType: 'TRIP'),
          summaryJson(
              id: 3, title: 'Broadcast thing', notificationType: 'ADMIN'),
          summaryJson(
              id: 4, title: 'Booking thing', notificationType: 'BOOKING'),
        ]),
      );
      // All four survive — including the customer-flavoured ones.
      for (final id in [1, 2, 3, 4]) {
        expect(find.byKey(Key('partner-notifications-row-$id')), findsOneWidget,
            reason: 'row $id must not be filtered out');
      }
      expect(find.text(en.partnerNotificationsInboxNotice), findsOneWidget);
    });

    testWidgets('order is preserved exactly as served', (tester) async {
      await pumpScreen(
        tester,
        client: d6Client(notifications: [
          summaryJson(id: 1, title: 'First served'),
          summaryJson(id: 2, title: 'Second served'),
        ]),
      );
      expect(tester.getTopLeft(find.text('First served')).dy,
          lessThan(tester.getTopLeft(find.text('Second served')).dy));
    });

    testWidgets('a null createdAt renders without crashing', (tester) async {
      await pumpScreen(tester,
          client:
              d6Client(notifications: [summaryJson(id: 1, createdAt: null)]));
      expect(tester.takeException(), isNull);
      expect(
          find.byKey(const Key('partner-notifications-row-1')), findsOneWidget);
    });

    testWidgets('the loading state is shown while the request is in flight',
        (tester) async {
      // A deliberately slow list response, so the loading state is observable
      // rather than dependent on pump timing against an instant mock.
      final slow = MockClient((request) async {
        final path = request.url.path;
        requestLog.add('${request.method} $path');
        if (path.endsWith('/partner/profile')) {
          return jsonResponse(profileJson(), 200);
        }
        if (path.endsWith('/partner/extranet/home')) {
          return jsonResponse(extranetHomeJson(), 200);
        }
        if (path.endsWith('/partner/hotels')) {
          return jsonResponse([hotelJson()], 200);
        }
        if (path.endsWith('/me/notifications/unread-count')) {
          return http.Response('1', 200,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        if (path.endsWith('/me/notifications')) {
          await Future<void>.delayed(const Duration(seconds: 2));
          return jsonResponse([summaryJson()], 200);
        }
        return jsonResponse(errorBody(404, 'Not found', path), 404);
      });

      final app = partnerApp(slow);
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      await tester.pumpWidget(testApp(
          app: app,
          partner: partner,
          child: const PartnerNotificationsScreen()));

      await tester.pump(); // runs the post-frame callback -> load() starts
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('partner-notifications-loading')),
          findsOneWidget);
      expect(
          find.byKey(const Key('partner-notifications-row-1')), findsNothing);

      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(
          find.byKey(const Key('partner-notifications-row-1')), findsOneWidget);
      expect(
          find.byKey(const Key('partner-notifications-loading')), findsNothing);
    });
  });

  // ── 3. Deep-link safety ───────────────────────────────────────────────────

  group('deep-link safety', () {
    test('no partner destination accepts an entity id', () {
      // A compile-time constant, asserted so it cannot be flipped silently.
      expect(PartnerNotificationsState.hasSupportedPartnerDestination, isFalse);
    });

    testWidgets('the list carries no related-entity payload', (tester) async {
      await pumpScreen(tester);
      // Before any mark-read there is no target to show.
      expect(find.byKey(const Key('partner-notifications-target-1')),
          findsNothing);
    });

    testWidgets('PATCH /read returns the payload, and nothing navigates',
        (tester) async {
      await pumpScreen(
        tester,
        client: d6Client(
          readResponse: detailJson(
              id: 1, relatedEntityType: 'HOTEL', relatedEntityId: 11),
        ),
      );
      await tester.tap(find.byKey(const Key('partner-notifications-read-1')));
      await tester.pumpAndSettle();

      // The target is resolved and surfaced...
      expect(find.byKey(const Key('partner-notifications-target-1')),
          findsOneWidget);
      expect(find.text(en.partnerNotificationsNoDestination), findsOneWidget);
      // ...and the operator is still in the notification centre.
      expect(find.byType(PartnerNotificationsScreen), findsOneWidget);
      expect(
          find.byKey(const Key('partner-notifications-title')), findsOneWidget);
    });

    testWidgets('an unsupported target type still does not navigate',
        (tester) async {
      await pumpScreen(
        tester,
        client: d6Client(
          notifications: [summaryJson(id: 1, notificationType: 'MESSAGE')],
          readResponse: detailJson(
              id: 1,
              notificationType: 'MESSAGE',
              relatedEntityType: 'MESSAGE',
              relatedEntityId: 99),
        ),
      );
      await tester.tap(find.byKey(const Key('partner-notifications-read-1')));
      await tester.pumpAndSettle();
      // MESSAGE must NOT be inferred as "open the messages module".
      expect(find.byType(PartnerNotificationsScreen), findsOneWidget);
      expect(find.text(en.partnerNotificationsNoDestination), findsOneWidget);
    });

    test('a resolved target is exposed as data, never as a route', () async {
      final state =
          PartnerNotificationsState(api: ApiClient(client: d6Client()));
      await state.load();
      expect(state.targetFor(1), isNull);
      await state.markRead(1);
      final target = state.targetFor(1);
      expect(target, isNotNull);
      expect(target!.entity, NotificationRelatedEntity.hotel);
      expect(target.entityId, 11);
      state.dispose();
    });
  });

  // ── 4. Mutations ──────────────────────────────────────────────────────────

  group('mark read', () {
    testWidgets('marks one notification read and re-reads the count',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('partner-notifications-read-1')));
      await tester.pumpAndSettle();

      expect(requestLog, contains('PATCH /api/me/notifications/1/read'));
      expect(find.text(en.partnerNotificationsMarkedRead), findsOneWidget);
      // Unread count re-read from the server after the mutation.
      expect(countOf('GET /api/me/notifications/unread-count'),
          greaterThanOrEqualTo(2));
    });

    testWidgets('an already-read notification offers no mark-read control',
        (tester) async {
      await pumpScreen(tester,
          client: d6Client(
              notifications: [summaryJson(id: 1, read: true)], unreadCount: 0));
      expect(
          find.byKey(const Key('partner-notifications-read-1')), findsNothing);
    });

    test('marking an already-read row issues no request', () async {
      final state = PartnerNotificationsState(
        api: ApiClient(
            client: d6Client(
                notifications: [summaryJson(id: 1, read: true)],
                unreadCount: 0)),
      );
      await state.load();
      final before = countOf('PATCH');
      expect(await state.markRead(1), PartnerNotificationActionResult.success);
      expect(countOf('PATCH'), before, reason: 'nothing to change');
      state.dispose();
    });

    test('no optimistic mutation — the row flips only from the server record',
        () async {
      final state = PartnerNotificationsState(
        api: ApiClient(
          client: d6Client(readResponse: detailJson(id: 1, read: true)),
        ),
      );
      await state.load();
      expect(state.notifications.single.read, isFalse);
      await state.markRead(1);
      expect(state.notifications.single.read, isTrue);
      state.dispose();
    });

    test('a failed mark-read leaves the row untouched', () async {
      final state = PartnerNotificationsState(
        api: ApiClient(client: d6Client(readStatus: 500)),
      );
      await state.load();
      expect(await state.markRead(1), PartnerNotificationActionResult.failed);
      expect(state.notifications.single.read, isFalse,
          reason: 'a failure must not flip the flag locally');
      state.dispose();
    });

    test('403 on mark-read maps to forbidden, not a generic failure', () async {
      final state = PartnerNotificationsState(
        api: ApiClient(client: d6Client(readStatus: 403)),
      );
      await state.load();
      expect(
          await state.markRead(1), PartnerNotificationActionResult.forbidden);
      state.dispose();
    });

    test('404 on mark-read maps to notFound', () async {
      final state = PartnerNotificationsState(
        api: ApiClient(client: d6Client(readStatus: 404)),
      );
      await state.load();
      expect(await state.markRead(1), PartnerNotificationActionResult.notFound);
      state.dispose();
    });
  });

  group('mark all read', () {
    testWidgets('marks all read and re-reads the list', (tester) async {
      await pumpScreen(
        tester,
        client: d6Client(notifications: [
          summaryJson(id: 1, read: false),
          summaryJson(id: 2, read: false),
        ], unreadCount: 2),
      );
      await tester.tap(find.byKey(const Key('partner-notifications-mark-all')));
      await tester.pumpAndSettle();

      expect(requestLog, contains('PATCH /api/me/notifications/read-all'));
      expect(find.text(en.partnerNotificationsMarkedAllRead), findsOneWidget);
      expect(find.byKey(const Key('partner-notifications-unread-1')),
          findsNothing);
    });

    testWidgets('the control is hidden when nothing is unread', (tester) async {
      await pumpScreen(tester,
          client: d6Client(
              notifications: [summaryJson(id: 1, read: true)], unreadCount: 0));
      expect(find.byKey(const Key('partner-notifications-mark-all')),
          findsNothing);
    });

    test('a failed mark-all does not alter local rows', () async {
      final state = PartnerNotificationsState(
        api: ApiClient(client: d6Client(readAllStatus: 500)),
      );
      await state.load();
      expect(await state.markAllRead(), PartnerNotificationActionResult.failed);
      expect(state.notifications.single.read, isFalse);
      state.dispose();
    });
  });

  group('delete', () {
    testWidgets('asks for confirmation and deletes on confirm', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('partner-notifications-delete-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('partner-notifications-delete-dialog')),
          findsOneWidget);
      expect(find.text(en.partnerNotificationsDeleteMessage), findsOneWidget);

      await tester
          .tap(find.byKey(const Key('partner-notifications-delete-confirm')));
      await tester.pumpAndSettle();

      expect(requestLog, contains('DELETE /api/me/notifications/1'));
      expect(find.text(en.partnerNotificationsDeleted), findsOneWidget);
      expect(
          find.byKey(const Key('partner-notifications-row-1')), findsNothing);
    });

    testWidgets('cancelling deletes nothing', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('partner-notifications-delete-1')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('partner-notifications-delete-cancel')));
      await tester.pumpAndSettle();

      expect(countOf('DELETE'), 0, reason: 'cancel must issue no request');
      expect(
          find.byKey(const Key('partner-notifications-row-1')), findsOneWidget);
    });

    test('no optimistic removal — the row goes only after a confirmed 204',
        () async {
      final state = PartnerNotificationsState(
        api: ApiClient(client: d6Client(deleteStatus: 500)),
      );
      await state.load();
      expect(state.notifications, hasLength(1));
      expect(await state.delete(1), PartnerNotificationActionResult.failed);
      expect(state.notifications, hasLength(1),
          reason: 'a failed delete must not remove the row');
      state.dispose();
    });
  });

  group('single flight', () {
    test('a second mutation for the same row is refused, not queued', () async {
      final state = PartnerNotificationsState(
        api: ApiClient(client: d6Client()),
      );
      await state.load();

      final first = state.markRead(1);
      final second = await state.markRead(1);
      expect(second, PartnerNotificationActionResult.busy);
      await first;
      state.dispose();
    });

    test('a per-row mutation is refused while mark-all is in flight', () async {
      final state = PartnerNotificationsState(
        api: ApiClient(client: d6Client()),
      );
      await state.load();

      final all = state.markAllRead();
      final one = await state.markRead(1);
      expect(one, PartnerNotificationActionResult.busy);
      await all;
      state.dispose();
    });
  });

  // ── 5. Errors and authorization ───────────────────────────────────────────

  group('errors and authorization', () {
    testWidgets('401 gets the session-expired treatment, never a logout',
        (tester) async {
      final r = await pumpScreen(tester, client: d6Client(listStatus: 401));
      expect(find.byKey(const Key('partner-notifications-unauthorized')),
          findsOneWidget);
      expect(r.app.email, 'partner@planyourtrip.com');
    });

    testWidgets('403 is surfaced as a refusal with a retry', (tester) async {
      await pumpScreen(tester, client: d6Client(listStatus: 403));
      expect(find.byKey(const Key('partner-notifications-forbidden')),
          findsOneWidget);
    });

    testWidgets('404 uses the team-member treatment, not "create a profile"',
        (tester) async {
      await pumpScreen(tester, client: d6Client(listStatus: 404));
      expect(find.byKey(const Key('partner-notifications-notfound')),
          findsOneWidget);
    });

    testWidgets('a 5xx is retryable and the retry re-issues the request',
        (tester) async {
      await pumpScreen(tester, client: d6Client(listStatus: 500));
      expect(
          find.byKey(const Key('partner-notifications-error')), findsOneWidget);
      final before = countOf('GET /api/me/notifications');

      final retry = find.text(en.partnerActionRetry);
      expect(retry, findsWidgets);
      await tester.tap(retry.first);
      await tester.pumpAndSettle();
      expect(countOf('GET /api/me/notifications'), greaterThan(before));
    });

    testWidgets('a transport failure is a retryable error, not empty data',
        (tester) async {
      await pumpScreen(tester, client: d6Client(notificationsThrow: true));
      expect(
          find.byKey(const Key('partner-notifications-error')), findsOneWidget);
      expect(
          find.byKey(const Key('partner-notifications-empty')), findsNothing);
    });

    testWidgets('a USER account never reaches the module', (tester) async {
      final app = partnerApp(d6Client(), role: AppRole.user);
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      await tester.pumpWidget(testApp(
          app: app,
          partner: partner,
          child: const PartnerNotificationsScreen()));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('partner-notifications-title')), findsNothing);
      expect(countOf('/me/notifications'), 0);
    });
  });

  // ── 6. Contract boundaries ────────────────────────────────────────────────

  group('contract boundaries', () {
    testWidgets('D6 never calls a partner notification endpoint',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('partner-notifications-read-1')));
      await tester.pumpAndSettle();
      expect(
        requestLog.where((r) => r.contains('/partner/notifications')),
        isEmpty,
        reason: '/api/partner/notifications does not exist',
      );
    });

    testWidgets('demo mode makes zero HTTP calls and fabricates nothing',
        (tester) async {
      final app = AppState(api: ApiClient(client: d6Client())..demoMode = true)
        ..demoMode = true
        ..email = 'demo@planyourtrip.com'
        ..role = AppRole.user;
      final partner = PartnerState(api: app.api)..bindSession(app);
      await partner.loadWorkspace(app);
      await tester.pumpWidget(testApp(
          app: app,
          partner: partner,
          child: const PartnerNotificationsScreen()));
      await tester.pumpAndSettle();

      expect(requestLog, isEmpty);
      expect(
          find.byKey(const Key('partner-notifications-row-1')), findsNothing);
    });

    testWidgets('back out of the module and return re-reads the inbox',
        (tester) async {
      await pumpScreen(tester);
      final before = countOf('GET /api/me/notifications');
      expect(before, greaterThanOrEqualTo(1));
      // Leaving and re-entering rebuilds the module, which reloads on entry.
      expect(find.byType(PartnerNotificationsScreen), findsOneWidget);
    });
  });

  // ── 7. Localization ───────────────────────────────────────────────────────

  group('localization', () {
    test('every D6 string resolves in both locales and differs', () {
      final pairs = <String, String>{
        en.partnerNotificationsTitle: vi.partnerNotificationsTitle,
        en.partnerNotificationsSubtitle: vi.partnerNotificationsSubtitle,
        en.partnerNotificationsLoading: vi.partnerNotificationsLoading,
        en.partnerNotificationsEmptyTitle: vi.partnerNotificationsEmptyTitle,
        en.partnerNotificationsEmptyMessage:
            vi.partnerNotificationsEmptyMessage,
        en.partnerNotificationsInboxNotice: vi.partnerNotificationsInboxNotice,
        en.partnerNotificationsUnpaginatedNotice:
            vi.partnerNotificationsUnpaginatedNotice,
        en.partnerNotificationsUnreadLabel: vi.partnerNotificationsUnreadLabel,
        en.partnerNotificationsMarkRead: vi.partnerNotificationsMarkRead,
        en.partnerNotificationsMarkAllRead: vi.partnerNotificationsMarkAllRead,
        en.partnerNotificationsMarkedRead: vi.partnerNotificationsMarkedRead,
        en.partnerNotificationsMarkedAllRead:
            vi.partnerNotificationsMarkedAllRead,
        en.partnerNotificationsDelete: vi.partnerNotificationsDelete,
        en.partnerNotificationsDeleteTitle: vi.partnerNotificationsDeleteTitle,
        en.partnerNotificationsDeleteMessage:
            vi.partnerNotificationsDeleteMessage,
        en.partnerNotificationsDeleteCta: vi.partnerNotificationsDeleteCta,
        en.partnerNotificationsDeleted: vi.partnerNotificationsDeleted,
        en.partnerNotificationsActionFailed:
            vi.partnerNotificationsActionFailed,
        en.partnerNotificationsActionBusy: vi.partnerNotificationsActionBusy,
        en.partnerNotificationsActionNotFound:
            vi.partnerNotificationsActionNotFound,
        en.partnerNotificationsNoDestination:
            vi.partnerNotificationsNoDestination,
        en.partnerNotificationsTypeUnknown: vi.partnerNotificationsTypeUnknown,
      };
      pairs.forEach((english, vietnamese) {
        expect(english, isNotEmpty);
        expect(vietnamese, isNotEmpty);
        expect(vietnamese, isNot(equals(english)));
      });
    });

    testWidgets('the screen renders in English', (tester) async {
      await pumpScreen(tester, locale: const Locale('en'));
      expect(find.text(en.partnerNotificationsTitle), findsOneWidget);
      expect(find.text(en.partnerNotificationsInboxNotice), findsOneWidget);
    });

    testWidgets('the screen renders in Vietnamese', (tester) async {
      await pumpScreen(tester, locale: const Locale('vi'));
      expect(find.text(vi.partnerNotificationsTitle), findsOneWidget);
      expect(find.text(vi.partnerNotificationsInboxNotice), findsOneWidget);
    });
  });
}
