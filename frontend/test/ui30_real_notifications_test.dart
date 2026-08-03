import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/profile/notifications_screen.dart';
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

  Map<String, dynamic> notificationJson({
    int id = 5,
    String title = 'Booking confirmed',
    String message = 'Your booking PYT-1 has been confirmed.',
    String type = 'BOOKING',
    String priority = 'NORMAL',
    bool read = false,
  }) =>
      {
        'id': id,
        'title': title,
        'message': message,
        'notificationType': type,
        'priority': priority,
        'read': read,
        'createdAt': '2030-05-01T10:00:00Z',
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/notifications');
  bool unreadCountPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/unread-count');
  bool readPath(http.Request r) =>
      r.method == 'PATCH' &&
      RegExp(r'/notifications/\d+/read$').hasMatch(r.url.path);
  bool readAllPath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/read-all');
  bool deletePath(http.Request r) =>
      r.method == 'DELETE' &&
      RegExp(r'/notifications/\d+$').hasMatch(r.url.path);

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onRead,
    Future<http.Response> Function(http.Request)? onReadAll,
    Future<http.Response> Function(http.Request)? onDelete,
    int unreadCount = 1,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (unreadCountPath(request)) {
          return jsonResponse(unreadCount, 200);
        }
        if (readAllPath(request)) {
          return (onReadAll ?? (_) async => jsonResponse(1, 200))(request);
        }
        if (readPath(request)) {
          return (onRead ??
              (_) async =>
                  jsonResponse(notificationJson(read: true), 200))(request);
        }
        if (deletePath(request)) {
          return (onDelete ?? (_) async => http.Response('', 204))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([notificationJson()], 200))(request);
        }
        return jsonResponse(const <Map<String, dynamic>>[], 200);
      }));

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('getNotifications GETs /api/me/notifications as a bare array',
        () async {
      http.Request? captured;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) captured = r;
      });
      final outcome = await app.loadRealNotifications();
      expect(outcome, RealNotificationOutcome.success);
      expect(captured!.url.path.endsWith('/me/notifications'), isTrue);
      expect(app.realNotifications, hasLength(1));
    });

    test('RealNotificationRecord.fromJson maps fields and wire enums',
        () async {
      final app = routedApp(
        onList: (_) async => jsonResponse([
          notificationJson(type: 'PAYMENT', priority: 'HIGH', read: true),
        ], 200),
      );
      await app.loadRealNotifications();
      final n = app.realNotifications.single;
      expect(n.id, 5);
      expect(n.title, 'Booking confirmed');
      expect(n.notificationType, 'PAYMENT');
      expect(n.typeView, UserNotificationType.payment);
      expect(n.priorityView, UserNotificationPriority.high);
      expect(n.read, isTrue);
      expect(n.createdAt, isNotNull);
    });

    test('unread count is derived from the loaded list', () async {
      final app = routedApp(
        onList: (_) async => jsonResponse([
          notificationJson(id: 1, read: false),
          notificationJson(id: 2, read: true),
          notificationJson(id: 3, read: false),
        ], 200),
      );
      await app.loadRealNotifications();
      expect(app.realNotificationsUnreadCount, 2);
    });
  });

  // ── Demo Mode ────────────────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all notification actions make zero HTTP in Demo Mode', () async {
      var calls = 0;
      final app = demoApp(MockClient((r) async {
        calls++;
        return jsonResponse(const [], 200);
      }));
      expect(await app.loadRealNotifications(),
          RealNotificationOutcome.demoUnavailable);
      expect(await app.markRealNotificationRead(5),
          RealNotificationOutcome.demoUnavailable);
      expect(await app.markAllRealNotificationsRead(),
          RealNotificationOutcome.demoUnavailable);
      expect(await app.deleteRealNotification(5),
          RealNotificationOutcome.demoUnavailable);
      expect(calls, 0);
    });
  });

  // ── Mutations ──────────────────────────────────────────────────────────────

  group('Mutations', () {
    test(
        'markRead replaces the item with the server record (no optimistic flip)',
        () async {
      final app = routedApp(
        onList: (_) async => jsonResponse([notificationJson(read: false)], 200),
        onRead: (_) async => jsonResponse(notificationJson(read: true), 200),
      );
      await app.loadRealNotifications();
      expect(app.realNotifications.single.read, isFalse);
      final outcome = await app.markRealNotificationRead(5);
      expect(outcome, RealNotificationOutcome.success);
      expect(app.realNotifications.single.read, isTrue);
    });

    test('markAllRead re-fetches the list so read state reflects the server',
        () async {
      var listCalls = 0;
      final app = routedApp(
        onList: (_) async {
          listCalls++;
          // First load: one unread. After read-all: server returns it read.
          return jsonResponse([notificationJson(read: listCalls > 1)], 200);
        },
      );
      await app.loadRealNotifications();
      expect(app.realNotificationsUnreadCount, 1);
      final outcome = await app.markAllRealNotificationsRead();
      expect(outcome, RealNotificationOutcome.success);
      expect(listCalls, 2);
      expect(app.realNotificationsUnreadCount, 0);
    });

    test('delete removes the item only after the server confirms', () async {
      final app = routedApp(
        onList: (_) async => jsonResponse([
          notificationJson(id: 1),
          notificationJson(id: 2),
        ], 200),
        onDelete: (_) async => http.Response('', 204),
      );
      await app.loadRealNotifications();
      expect(app.realNotifications, hasLength(2));
      final outcome = await app.deleteRealNotification(1);
      expect(outcome, RealNotificationOutcome.success);
      expect(app.realNotifications.map((n) => n.id), [2]);
    });

    test('a concurrent markRead on the same id returns busy', () async {
      final gate = Completer<http.Response>();
      final app = routedApp(
        onList: (_) async => jsonResponse([notificationJson()], 200),
        onRead: (_) => gate.future,
      );
      await app.loadRealNotifications();
      final first = app.markRealNotificationRead(5);
      final second = await app.markRealNotificationRead(5);
      expect(second, RealNotificationOutcome.busy);
      gate.complete(jsonResponse(notificationJson(read: true), 200));
      expect(await first, RealNotificationOutcome.success);
    });
  });

  // ── Errors ────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('list 401 → sessionExpired, no auto-logout / no demo switch',
        () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/notifications'), 401),
      );
      app.email = 'mai@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealNotifications(),
          RealNotificationOutcome.sessionExpired);
      expect(app.email, 'mai@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test(
        'markRead 404 → notFound; delete 403 → forbidden; list 500 → serverError',
        () async {
      final nf = routedApp(
        onList: (_) async => jsonResponse([notificationJson()], 200),
        onRead: (_) async => jsonResponse(
            errorBody(404, 'x', '/api/me/notifications/5/read'), 404),
      );
      await nf.loadRealNotifications();
      expect(await nf.markRealNotificationRead(5),
          RealNotificationOutcome.notFound);

      final fb = routedApp(
        onList: (_) async => jsonResponse([notificationJson()], 200),
        onDelete: (_) async =>
            jsonResponse(errorBody(403, 'x', '/api/me/notifications/5'), 403),
      );
      await fb.loadRealNotifications();
      expect(await fb.deleteRealNotification(5),
          RealNotificationOutcome.forbidden);

      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/api/me/notifications'), 500),
      );
      expect(await se.loadRealNotifications(),
          RealNotificationOutcome.serverError);
    });

    test('a transport failure → network', () async {
      final app = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(
          await app.loadRealNotifications(), RealNotificationOutcome.network);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears notifications and unread state', () async {
      final app = routedApp();
      await app.loadRealNotifications();
      expect(app.realNotifications, isNotEmpty);
      await app.logout();
      expect(app.realNotifications, isEmpty);
      expect(app.realNotificationsLoaded, isFalse);
      expect(app.realNotificationsServerUnread, isNull);
      expect(app.notificationActionInFlight, isEmpty);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('real mode renders the notification list and marks read on tap',
        (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse([notificationJson(read: false)], 200),
        onRead: (_) async => jsonResponse(notificationJson(read: true), 200),
      );
      await pumpSize(
        t,
        testApp(child: const NotificationsScreen(), app: app),
        const Size(1200, 2200),
      );
      expect(
          find.byKey(const Key('real-notifications-content')), findsOneWidget);
      expect(find.byKey(const Key('real-notification-card-5')), findsOneWidget);
      await t.tap(find.byKey(const Key('real-notification-card-5')));
      await t.pumpAndSettle();
      expect(app.realNotifications.single.read, isTrue);
    });

    testWidgets('empty inbox shows the empty state', (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const NotificationsScreen(), app: app),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('real-notifications-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/api/me/notifications'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const NotificationsScreen(), app: app),
        const Size(1200, 2000),
      );
      expect(find.byKey(const Key('real-notifications-session-expired')),
          findsOneWidget);
    });

    testWidgets('mark-all-read marks the list read', (t) async {
      var listCalls = 0;
      final app = routedApp(
        onList: (_) async {
          listCalls++;
          return jsonResponse([notificationJson(read: listCalls > 1)], 200);
        },
      );
      await pumpSize(
        t,
        testApp(child: const NotificationsScreen(), app: app),
        const Size(1200, 2200),
      );
      await t.tap(find.byKey(const Key('real-notifications-mark-all')));
      await t.pumpAndSettle();
      expect(app.realNotificationsUnreadCount, 0);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI30 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final values = <String>[
        en.notificationsRealLoadingMessage,
        vi.notificationsRealLoadingMessage,
        en.notificationsRealErrorMessage,
        vi.notificationsRealErrorMessage,
        en.notificationsRealSubtitle,
        vi.notificationsRealSubtitle,
        en.notificationActionForbiddenMessage,
        vi.notificationActionForbiddenMessage,
        en.notificationActionNetworkMessage,
        vi.notificationActionNetworkMessage,
        en.notificationActionServerErrorMessage,
        vi.notificationActionServerErrorMessage,
      ];
      for (final s in values) {
        expect(s.trim(), isNotEmpty);
      }
      expect(
          en.notificationsRealSubtitle != vi.notificationsRealSubtitle, isTrue);
    });
  });
}
