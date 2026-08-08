import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/bookings/real_booking_detail_screen.dart';
import 'package:planyourtrip_frontend/features/profile/notifications_screen.dart';
import 'package:planyourtrip_frontend/features/trips/real_trip_detail_screen.dart';
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

  AppState realApp(http.Client client) => AppState(
        api: ApiClient(client: client)..demoMode = false,
      )..demoMode = false;

  AppState demoApp(http.Client client) =>
      AppState(api: ApiClient(client: client));

  Map<String, dynamic> notificationJson({
    int id = 5,
    String title = 'Trip updated',
    String message = 'Your trip has an update.',
    String type = 'TRIP',
    String priority = 'NORMAL',
    bool read = false,
    String? relatedEntityType,
    int? relatedEntityId,
  }) =>
      {
        'id': id,
        'title': title,
        'message': message,
        'notificationType': type,
        'priority': priority,
        'read': read,
        'relatedEntityType': relatedEntityType,
        'relatedEntityId': relatedEntityId,
        'createdAt': '2030-05-01T10:00:00Z',
      };

  Map<String, dynamic> tripDetailJson(int id) => {
        'id': id,
        'userId': 1,
        'title': 'Linked trip',
        'status': 'ACTIVE',
        'isPublic': false,
        'days': const [],
      };

  Map<String, dynamic> bookingDetailJson(int id) => {
        'id': id,
        'bookingCode': 'PYT-$id',
        'status': 'PENDING',
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/notifications');
  bool readPath(http.Request r) =>
      r.method == 'PATCH' &&
      RegExp(r'/notifications/\d+/read$').hasMatch(r.url.path);
  bool tripDetailPath(http.Request r) =>
      r.method == 'GET' && RegExp(r'/me/trips/\d+$').hasMatch(r.url.path);
  bool bookingDetailPath(http.Request r) =>
      r.method == 'GET' && RegExp(r'/bookings/\d+$').hasMatch(r.url.path);

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onRead,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (request.url.path.endsWith('/unread-count')) {
          return jsonResponse(1, 200);
        }
        if (readPath(request)) {
          return (onRead ??
              (_) async =>
                  jsonResponse(notificationJson(read: true), 200))(request);
        }
        if (tripDetailPath(request)) {
          return jsonResponse(tripDetailJson(7), 200);
        }
        if (bookingDetailPath(request)) {
          return jsonResponse(bookingDetailJson(42), 200);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([notificationJson()], 200))(request);
        }
        return jsonResponse(const <Map<String, dynamic>>[], 200);
      }));

  // ── Contract parsing / DTO mapping ───────────────────────────────────────────

  group('Contract parsing', () {
    test('relatedEntity wire mapping; unknown → null', () {
      expect(notificationRelatedEntityFromWire('TRIP'),
          NotificationRelatedEntity.trip);
      expect(notificationRelatedEntityFromWire('BOOKING'),
          NotificationRelatedEntity.booking);
      expect(notificationRelatedEntityFromWire('MESSAGE'),
          NotificationRelatedEntity.message);
      expect(notificationRelatedEntityFromWire('WAT'), isNull);
      expect(notificationRelatedEntityFromWire(null), isNull);
    });

    test('fromJson parses related fields; getters resolve', () {
      final r = RealNotificationRecord.fromJson(
          notificationJson(relatedEntityType: 'TRIP', relatedEntityId: 7));
      expect(r.relatedEntityType, 'TRIP');
      expect(r.relatedEntityId, 7);
      expect(r.relatedEntityView, NotificationRelatedEntity.trip);
      expect(r.hasNavigableTarget, isTrue);
    });

    test('summary record (no related fields) is not navigable', () {
      final r = RealNotificationRecord.fromJson(notificationJson());
      expect(r.relatedEntityType, isNull);
      expect(r.relatedEntityId, isNull);
      expect(r.relatedEntityView, isNull);
      expect(r.hasNavigableTarget, isFalse);
    });

    test('hasNavigableTarget: trip/booking with id true; others false', () {
      RealNotificationRecord rec(String? type, int? id) =>
          RealNotificationRecord.fromJson(
              notificationJson(relatedEntityType: type, relatedEntityId: id));
      expect(rec('TRIP', 7).hasNavigableTarget, isTrue);
      expect(rec('BOOKING', 42).hasNavigableTarget, isTrue);
      expect(rec('TRIP', null).hasNavigableTarget, isFalse);
      expect(rec('PAYMENT', 9).hasNavigableTarget, isFalse);
      expect(rec('HOTEL', 9).hasNavigableTarget, isFalse);
      expect(rec('MESSAGE', 9).hasNavigableTarget, isFalse);
      expect(rec('MYSTERY', 9).hasNavigableTarget, isFalse);
    });
  });

  // ── Mark-read surfaces the navigation target ────────────────────────────────

  group('Mark-read surfaces the target', () {
    test('markRead response replaces the record with related fields', () async {
      // The list is summary-only (no related fields); the PATCH read response
      // carries them. After marking read, the stored record becomes navigable.
      final app = routedApp(
        onList: (_) async => jsonResponse([notificationJson(id: 5)], 200),
        onRead: (_) async => jsonResponse(
            notificationJson(
                id: 5,
                read: true,
                relatedEntityType: 'TRIP',
                relatedEntityId: 7),
            200),
      );
      expect(
          await app.loadRealNotifications(), RealNotificationOutcome.success);
      expect(app.realNotifications.single.hasNavigableTarget, isFalse);
      expect(await app.markRealNotificationRead(5),
          RealNotificationOutcome.success);
      final updated = app.realNotifications.single;
      expect(updated.read, isTrue);
      expect(updated.relatedEntityView, NotificationRelatedEntity.trip);
      expect(updated.relatedEntityId, 7);
      expect(updated.hasNavigableTarget, isTrue);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('markRealNotificationRead → demoUnavailable, zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(notificationJson(), 200);
      }));
      expect(await app.markRealNotificationRead(5),
          RealNotificationOutcome.demoUnavailable);
      expect(calls, 0);
    });
  });

  // ── Widget / user journey ────────────────────────────────────────────────────

  group('Journey', () {
    testWidgets('trip notification → opens RealTripDetailScreen', (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse([
          notificationJson(
              id: 5, read: true, relatedEntityType: 'TRIP', relatedEntityId: 7)
        ], 200),
      );
      await pumpSize(
        t,
        testApp(child: const NotificationsScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('real-notification-card-5')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('real-notification-open-target')),
          findsOneWidget);
      await t.tap(find.byKey(const Key('real-notification-open-target')));
      await t.pumpAndSettle();
      expect(find.byType(RealTripDetailScreen), findsOneWidget);
    });

    testWidgets('booking notification → opens RealBookingDetailScreen',
        (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse([
          notificationJson(
              id: 6,
              type: 'BOOKING',
              read: true,
              relatedEntityType: 'BOOKING',
              relatedEntityId: 42)
        ], 200),
      );
      await pumpSize(
        t,
        testApp(child: const NotificationsScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('real-notification-card-6')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('real-notification-open-target')));
      await t.pumpAndSettle();
      expect(find.byType(RealBookingDetailScreen), findsOneWidget);
    });

    testWidgets('notification without a target shows no open action',
        (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse(
            [notificationJson(id: 9, type: 'SYSTEM', read: true)], 200),
      );
      await pumpSize(
        t,
        testApp(child: const NotificationsScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('real-notification-card-9')));
      await t.pumpAndSettle();
      expect(
          find.byKey(const Key('real-notification-open-target')), findsNothing);
      expect(find.byKey(const Key('real-notification-delete')), findsOneWidget);
    });

    testWidgets('unread tap marks read then surfaces the open action',
        (t) async {
      final app = routedApp(
        onList: (_) async => jsonResponse([notificationJson(id: 5)], 200),
        onRead: (_) async => jsonResponse(
            notificationJson(
                id: 5,
                read: true,
                relatedEntityType: 'TRIP',
                relatedEntityId: 7),
            200),
      );
      await pumpSize(
        t,
        testApp(child: const NotificationsScreen(), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('real-notification-card-5')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('real-notification-open-target')),
          findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('reused open-target keys resolve in EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      expect(en.notificationOpenTrip.trim(), isNotEmpty);
      expect(en.notificationOpenBooking.trim(), isNotEmpty);
      expect(en.notificationOpenTargetSemantic.trim(), isNotEmpty);
      expect(vi.notificationOpenTrip.trim(), isNotEmpty);
      expect(vi.notificationOpenBooking.trim(), isNotEmpty);
      expect(vi.notificationOpenTargetSemantic.trim(), isNotEmpty);
      expect(en.notificationOpenTrip, isNot(vi.notificationOpenTrip));
    });
  });
}
