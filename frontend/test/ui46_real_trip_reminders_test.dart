import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/trips/real_trip_reminders_screen.dart';
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

  Map<String, dynamic> reminderJson({
    int id = 1,
    String reminderType = 'CHECK_IN',
    String title = 'Hotel check-in',
    String status = 'PENDING',
    String reminderAt = '2030-05-01T10:00:00Z',
  }) =>
      {
        'id': id,
        'tripPlanId': 7,
        'tripDayId': null,
        'tripItemId': null,
        'documentId': null,
        'userId': 3,
        'userName': 'Bao',
        'reminderType': reminderType,
        'title': title,
        'message': 'Bring the passport',
        'reminderAt': reminderAt,
        'status': status,
        'createdAt': '2030-04-01T08:00:00Z',
        'updatedAt': '2030-04-01T08:00:00Z',
        'completedAt': status == 'COMPLETED' ? '2030-04-02T08:00:00Z' : null,
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' &&
      RegExp(r'/me/trips/7/reminders$').hasMatch(r.url.path);
  bool createPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/trips/7/reminders');
  bool updatePath(http.Request r) =>
      r.method == 'PUT' &&
      RegExp(r'/me/trips/reminders/\d+$').hasMatch(r.url.path);
  bool deletePath(http.Request r) =>
      r.method == 'DELETE' &&
      RegExp(r'/me/trips/reminders/\d+$').hasMatch(r.url.path);
  bool completePath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/complete');
  bool cancelPath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/cancel');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onCreate,
    Future<http.Response> Function(http.Request)? onUpdate,
    Future<http.Response> Function(http.Request)? onDelete,
    Future<http.Response> Function(http.Request)? onComplete,
    Future<http.Response> Function(http.Request)? onCancel,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (createPath(request)) {
          return (onCreate ??
              (_) async => jsonResponse(reminderJson(id: 99), 201))(request);
        }
        if (updatePath(request)) {
          return (onUpdate ??
              (_) async => jsonResponse(reminderJson(), 200))(request);
        }
        if (deletePath(request)) {
          return (onDelete ?? (_) async => http.Response('', 204))(request);
        }
        if (completePath(request)) {
          return (onComplete ??
              (_) async => jsonResponse(
                  reminderJson(status: 'COMPLETED'), 200))(request);
        }
        if (cancelPath(request)) {
          return (onCancel ??
              (_) async => jsonResponse(
                  reminderJson(status: 'CANCELLED'), 200))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([reminderJson()], 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  RealReminderPayload payload() => RealReminderPayload(
        reminderType: TripReminderType.flight,
        title: 'Flight to Da Nang',
        message: 'Gate 12',
        reminderAt: DateTime.utc(2030, 6, 1, 9, 30),
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('list parses; correct path + default filter param', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) seen = r;
      });
      expect(await app.loadRealReminders(7), ReminderOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/7/reminders'), isTrue);
      expect(seen!.url.queryParameters['includeCancelled'], 'false');
      final r = app.realRemindersFor(7).single;
      expect(r.id, 1);
      expect(r.title, 'Hotel check-in');
      expect(r.typeView, TripReminderType.checkIn);
      expect(r.statusView, TripReminderStatus.pending);
      expect(r.message, 'Bring the passport');
      expect(r.userName, 'Bao');
    });

    test('type/status mappers + wire codes; unknown → null', () {
      expect(reminderTypeFromCode('FLIGHT'), TripReminderType.flight);
      expect(reminderTypeFromCode('NOPE'), isNull);
      expect(reminderStatusFromCode('CANCELLED'), TripReminderStatus.cancelled);
      expect(reminderStatusFromCode('NOPE'), isNull);
      expect(TripReminderType.checkIn.code, 'CHECK_IN');
      expect(TripReminderStatus.completed.code, 'COMPLETED');
    });

    test('payload toJson emits type wire, title, message, UTC ISO reminderAt',
        () {
      final json = payload().toJson();
      expect(json['reminderType'], 'FLIGHT');
      expect(json['title'], 'Flight to Da Nang');
      expect(json['message'], 'Gate 12');
      expect(json['reminderAt'], '2030-06-01T09:30:00.000Z');
      expect(json.containsKey('tripDayId'), isTrue);
      expect(json.containsKey('tripItemId'), isTrue);
      expect(json.containsKey('documentId'), isTrue);
    });

    test('isOverdue: PENDING past → true; future / non-pending → false', () {
      final past = RealReminder.fromJson(
          reminderJson(reminderAt: '2020-01-01T00:00:00Z'));
      final future = RealReminder.fromJson(
          reminderJson(reminderAt: '2999-01-01T00:00:00Z'));
      final done = RealReminder.fromJson(reminderJson(
          status: 'COMPLETED', reminderAt: '2020-01-01T00:00:00Z'));
      final now = DateTime.utc(2025, 1, 1);
      expect(past.isOverdue(now), isTrue);
      expect(future.isOverdue(now), isFalse);
      expect(done.isOverdue(now), isFalse);
    });

    test('non-list body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('{}', 200)));
      expect(await app.loadRealReminders(7), ReminderOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse([reminderJson()], 200);
      }));
      expect(await app.loadRealReminders(7), ReminderOutcome.demoUnavailable);
      expect(await app.createRealReminder(7, payload()),
          ReminderOutcome.demoUnavailable);
      expect(await app.updateRealReminder(7, 1, payload()),
          ReminderOutcome.demoUnavailable);
      expect(await app.completeRealReminder(7, 1),
          ReminderOutcome.demoUnavailable);
      expect(
          await app.cancelRealReminder(7, 1), ReminderOutcome.demoUnavailable);
      expect(
          await app.deleteRealReminder(7, 1), ReminderOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realRemindersFor(7), isEmpty);
    });
  });

  // ── CRUD + actions ────────────────────────────────────────────────────────────

  group('CRUD', () {
    test('cached list not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) gets++;
      });
      await app.loadRealReminders(7);
      await app.loadRealReminders(7);
      expect(gets, 1);
      await app.loadRealReminders(7, refresh: true);
      expect(gets, 2);
    });

    test('changing includeCancelled reloads with the query param', () async {
      final seen = <String?>[];
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) seen.add(r.url.queryParameters['includeCancelled']);
      });
      await app.loadRealReminders(7);
      await app.loadRealReminders(7, includeCancelled: true);
      expect(seen, ['false', 'true']);
      expect(app.realRemindersIncludeCancelled, isTrue);
    });

    test('create POSTs the payload and reloads', () async {
      Map<String, dynamic>? body;
      var listGets = 0;
      final app = routedApp(
        onRequest: (r) {
          if (listPath(r)) listGets++;
        },
        onCreate: (r) async {
          body = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(reminderJson(id: 99), 201);
        },
      );
      await app.loadRealReminders(7);
      expect(listGets, 1);
      expect(
          await app.createRealReminder(7, payload()), ReminderOutcome.success);
      expect(body!['title'], 'Flight to Da Nang');
      expect(body!['reminderType'], 'FLIGHT');
      expect(listGets, 2);
    });

    test('blank title → validation, no HTTP', () async {
      var calls = 0;
      final app = routedApp(onRequest: (_) => calls++);
      final blank = RealReminderPayload(
        reminderType: TripReminderType.custom,
        title: '   ',
        reminderAt: DateTime.utc(2030, 1, 1),
      );
      expect(
          await app.createRealReminder(7, blank), ReminderOutcome.validation);
      expect(await app.updateRealReminder(7, 1, blank),
          ReminderOutcome.validation);
      expect(calls, 0);
    });

    test('update PUTs to the reminder id and reloads', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (updatePath(r)) seen = r;
      });
      await app.loadRealReminders(7);
      expect(await app.updateRealReminder(7, 1, payload()),
          ReminderOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/reminders/1'), isTrue);
    });

    test('complete/cancel PATCH the right paths and reload', () async {
      final seen = <String>[];
      var listGets = 0;
      final app = routedApp(onRequest: (r) {
        if (completePath(r) || cancelPath(r)) seen.add(r.url.path);
        if (listPath(r)) listGets++;
      });
      await app.loadRealReminders(7);
      expect(await app.completeRealReminder(7, 1), ReminderOutcome.success);
      expect(await app.cancelRealReminder(7, 1), ReminderOutcome.success);
      expect(seen[0].endsWith('/me/trips/reminders/1/complete'), isTrue);
      expect(seen[1].endsWith('/me/trips/reminders/1/cancel'), isTrue);
      expect(listGets, 3);
    });

    test('delete DELETEs and reloads', () async {
      http.Request? seen;
      var listGets = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) seen = r;
        if (listPath(r)) listGets++;
      });
      await app.loadRealReminders(7);
      expect(await app.deleteRealReminder(7, 1), ReminderOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/reminders/1'), isTrue);
      expect(listGets, 2);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/reminders'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealReminders(7), ReminderOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('403 forbidden on create; 404 on update; 400 validation', () async {
      final f = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/trips/7/reminders'), 403),
      );
      expect(
          await f.createRealReminder(7, payload()), ReminderOutcome.forbidden);

      final nf = routedApp(
        onUpdate: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/trips/reminders/1'), 404),
      );
      expect(await nf.updateRealReminder(7, 1, payload()),
          ReminderOutcome.notFound);

      final inv = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(400, 'x', '/me/trips/7/reminders'), 400),
      );
      expect(await inv.createRealReminder(7, payload()),
          ReminderOutcome.validation);
    });

    test('list 500 → serverError; network', () async {
      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/trips/7/reminders'), 500),
      );
      expect(await se.loadRealReminders(7), ReminderOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealReminders(7), ReminderOutcome.network);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onList: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/me/trips/7/reminders'), 500)
            : jsonResponse([reminderJson()], 200),
      );
      await app.loadRealReminders(7);
      expect(app.realRemindersFor(7), isNotEmpty);
      fail = true;
      expect(await app.loadRealReminders(7, refresh: true),
          ReminderOutcome.serverError);
      expect(app.realRemindersFor(7), isNotEmpty);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all reminder state', () async {
      final app = routedApp();
      await app.loadRealReminders(7, includeCancelled: true);
      expect(app.realRemindersFor(7), isNotEmpty);
      await app.logout();
      expect(app.realRemindersFor(7), isEmpty);
      expect(app.realRemindersTripId, isNull);
      expect(app.realRemindersLoaded, isFalse);
      expect(app.realRemindersIncludeCancelled, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders content + reminder card', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealTripRemindersScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('reminders-content')), findsOneWidget);
      expect(find.byKey(const Key('reminder-card-1')), findsOneWidget);
      expect(
          find.byKey(const Key('reminders-include-cancelled')), findsOneWidget);
    });

    testWidgets('complete button PATCHes complete', (t) async {
      var completed = 0;
      final app = routedApp(onRequest: (r) {
        if (completePath(r)) completed++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripRemindersScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('reminder-complete-1')));
      await t.pumpAndSettle();
      expect(completed, 1);
    });

    testWidgets('cancel button PATCHes cancel', (t) async {
      var cancelled = 0;
      final app = routedApp(onRequest: (r) {
        if (cancelPath(r)) cancelled++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripRemindersScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('reminder-cancel-1')));
      await t.pumpAndSettle();
      expect(cancelled, 1);
    });

    testWidgets('add opens the form; saving POSTs and closes', (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripRemindersScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('reminder-add')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('reminder-form-content')), findsOneWidget);
      await t.enterText(
          find.byKey(const Key('reminder-field-title')), 'Book taxi');
      await t.tap(find.byKey(const Key('reminder-form-save')));
      await t.pumpAndSettle();
      expect(created, 1);
      expect(find.byKey(const Key('reminder-form-content')), findsNothing);
    });

    testWidgets('create form blocks submit without a title (no HTTP)',
        (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripRemindersScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('reminder-add')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('reminder-form-save')));
      await t.pumpAndSettle();
      expect(created, 0);
      expect(find.byKey(const Key('reminder-form-content')), findsOneWidget);
    });

    testWidgets('delete confirms then DELETEs', (t) async {
      var deleted = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) deleted++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripRemindersScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('reminder-delete-1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('reminder-delete-confirm')));
      await t.pumpAndSettle();
      expect(deleted, 1);
    });

    testWidgets('toggling include-cancelled reloads with the param', (t) async {
      final seen = <String?>[];
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) seen.add(r.url.queryParameters['includeCancelled']);
      });
      await pumpSize(
        t,
        testApp(child: const RealTripRemindersScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('reminders-include-cancelled')));
      await t.pumpAndSettle();
      expect(seen, ['false', 'true']);
    });

    testWidgets('empty feed shows the empty state', (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const RealTripRemindersScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('reminders-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/reminders'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealTripRemindersScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(
          find.byKey(const Key('reminders-session-expired')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI46 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.remindersRealTitle,
        en.remindersRealLoadingMessage,
        en.remindersRealErrorMessage,
        en.remindersRealForbiddenMessage,
        en.remindersRealGoneMessage,
        en.remindersRealNetworkMessage,
        en.remindersRealActionErrorMessage,
        en.remindersRealCreatedMessage,
        en.remindersRealUpdatedMessage,
        en.remindersRealCompletedMessage,
        en.remindersRealCancelledMessage,
        en.remindersRealDeletedMessage,
        en.remindersRealTitleRequiredMessage,
        en.remindersRealAddSemantic,
        en.remindersRealCreateTitle,
        en.remindersRealEditTitle,
        en.remindersRealEmptyTitle,
        en.remindersRealEmptyMessage,
      ];
      final viValues = <String>[
        vi.remindersRealTitle,
        vi.remindersRealLoadingMessage,
        vi.remindersRealErrorMessage,
        vi.remindersRealForbiddenMessage,
        vi.remindersRealGoneMessage,
        vi.remindersRealNetworkMessage,
        vi.remindersRealActionErrorMessage,
        vi.remindersRealCreatedMessage,
        vi.remindersRealUpdatedMessage,
        vi.remindersRealCompletedMessage,
        vi.remindersRealCancelledMessage,
        vi.remindersRealDeletedMessage,
        vi.remindersRealTitleRequiredMessage,
        vi.remindersRealAddSemantic,
        vi.remindersRealCreateTitle,
        vi.remindersRealEditTitle,
        vi.remindersRealEmptyTitle,
        vi.remindersRealEmptyMessage,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.remindersRealTitle, isNot(vi.remindersRealTitle));
    });

    test('parameterized + reused demo keys resolve', () {
      final en = AppLocalizationsEn();
      expect(
          en.remindersRealDeleteConfirmMessage('Flight'), contains('Flight'));
      expect(en.remindersRealCompleteSemantic('Flight'), contains('Flight'));
      expect(en.remindersRealCancelSemantic('Flight'), contains('Flight'));
      expect(en.reminderTitleField.trim(), isNotEmpty);
      expect(en.reminderStatusPending.trim(), isNotEmpty);
      expect(en.reminderTypeCheckIn.trim(), isNotEmpty);
      expect(en.remindersIncludeCancelled.trim(), isNotEmpty);
    });
  });
}
