import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/trips/real_trip_packing_screen.dart';
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

  Map<String, dynamic> itemJson({
    int id = 1,
    String label = 'Passport',
    String category = 'DOCUMENTS',
    int quantity = 1,
    bool checked = false,
    int sortOrder = 0,
  }) =>
      {
        'id': id,
        'tripPlanId': 7,
        'label': label,
        'category': category,
        'quantity': quantity,
        'checked': checked,
        'assignedToUserId': null,
        'assignedToUserName': null,
        'notes': 'Keep it safe',
        'sortOrder': sortOrder,
        'createdAt': '2030-05-01T10:00:00Z',
        'updatedAt': '2030-05-01T10:00:00Z',
        'checkedAt': checked ? '2030-05-01T11:00:00Z' : null,
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/trips/7/packing');
  bool createPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/trips/7/packing');
  bool updatePath(http.Request r) =>
      r.method == 'PUT' &&
      RegExp(r'/me/trips/packing/\d+$').hasMatch(r.url.path);
  bool deletePath(http.Request r) =>
      r.method == 'DELETE' &&
      RegExp(r'/me/trips/packing/\d+$').hasMatch(r.url.path);
  bool checkPath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/check');
  bool uncheckPath(http.Request r) =>
      r.method == 'PATCH' && r.url.path.endsWith('/uncheck');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onCreate,
    Future<http.Response> Function(http.Request)? onUpdate,
    Future<http.Response> Function(http.Request)? onDelete,
    Future<http.Response> Function(http.Request)? onCheck,
    Future<http.Response> Function(http.Request)? onUncheck,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (createPath(request)) {
          return (onCreate ??
              (_) async => jsonResponse(itemJson(id: 99), 201))(request);
        }
        if (updatePath(request)) {
          return (onUpdate ??
              (_) async => jsonResponse(itemJson(), 200))(request);
        }
        if (deletePath(request)) {
          return (onDelete ?? (_) async => http.Response('', 204))(request);
        }
        if (checkPath(request)) {
          return (onCheck ??
              (_) async => jsonResponse(itemJson(checked: true), 200))(request);
        }
        if (uncheckPath(request)) {
          return (onUncheck ??
              (_) async =>
                  jsonResponse(itemJson(checked: false), 200))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([itemJson()], 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  RealPackingItemPayload payload() => const RealPackingItemPayload(
        label: 'Sunscreen',
        category: PackingCategory.toiletries,
        quantity: 2,
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('list parses; correct path', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) seen = r;
      });
      expect(await app.loadRealPacking(7), PackingOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/7/packing'), isTrue);
      final i = app.realPackingItemsFor(7).single;
      expect(i.id, 1);
      expect(i.label, 'Passport');
      expect(i.categoryView, PackingCategory.documents);
      expect(i.quantity, 1);
      expect(i.checked, isFalse);
      expect(i.notes, 'Keep it safe');
    });

    test('category mapper + wire code; unknown → null', () {
      expect(
          packingCategoryFromCode('ELECTRONICS'), PackingCategory.electronics);
      expect(packingCategoryFromCode('NOPE'), isNull);
      expect(PackingCategory.documents.code, 'DOCUMENTS');
    });

    test('payload toJson emits label, category wire, quantity', () {
      final json = payload().toJson();
      expect(json['label'], 'Sunscreen');
      expect(json['category'], 'TOILETRIES');
      expect(json['quantity'], 2);
      expect(json.containsKey('notes'), isTrue);
      expect(json.containsKey('assignedToUserId'), isTrue);
    });

    test('non-list body → serverError (malformed)', () async {
      final app = realApp(MockClient((_) async => http.Response('{}', 200)));
      expect(await app.loadRealPacking(7), PackingOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse([itemJson()], 200);
      }));
      expect(await app.loadRealPacking(7), PackingOutcome.demoUnavailable);
      expect(await app.createRealPackingItem(7, payload()),
          PackingOutcome.demoUnavailable);
      expect(await app.updateRealPackingItem(7, 1, payload()),
          PackingOutcome.demoUnavailable);
      expect(await app.deleteRealPackingItem(7, 1),
          PackingOutcome.demoUnavailable);
      expect(await app.setRealPackingItemChecked(7, 1, true),
          PackingOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realPackingItemsFor(7), isEmpty);
    });
  });

  // ── CRUD + check ────────────────────────────────────────────────────────────────

  group('CRUD', () {
    test('cached list not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) gets++;
      });
      await app.loadRealPacking(7);
      await app.loadRealPacking(7);
      expect(gets, 1);
      await app.loadRealPacking(7, refresh: true);
      expect(gets, 2);
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
          return jsonResponse(itemJson(id: 99), 201);
        },
      );
      await app.loadRealPacking(7);
      expect(listGets, 1);
      expect(await app.createRealPackingItem(7, payload()),
          PackingOutcome.success);
      expect(body!['label'], 'Sunscreen');
      expect(body!['category'], 'TOILETRIES');
      expect(body!['quantity'], 2);
      expect(listGets, 2);
    });

    test('blank label / quantity < 1 → validation, no HTTP', () async {
      var calls = 0;
      final app = routedApp(onRequest: (_) => calls++);
      const blankLabel = RealPackingItemPayload(
        label: '   ',
        category: PackingCategory.other,
        quantity: 1,
      );
      const badQty = RealPackingItemPayload(
        label: 'x',
        category: PackingCategory.other,
        quantity: 0,
      );
      expect(await app.createRealPackingItem(7, blankLabel),
          PackingOutcome.validation);
      expect(await app.createRealPackingItem(7, badQty),
          PackingOutcome.validation);
      expect(await app.updateRealPackingItem(7, 1, badQty),
          PackingOutcome.validation);
      expect(calls, 0);
    });

    test('update PUTs to the item id and reloads', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (updatePath(r)) seen = r;
      });
      await app.loadRealPacking(7);
      expect(await app.updateRealPackingItem(7, 1, payload()),
          PackingOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/packing/1'), isTrue);
    });

    test('delete DELETEs and reloads', () async {
      http.Request? seen;
      var listGets = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) seen = r;
        if (listPath(r)) listGets++;
      });
      await app.loadRealPacking(7);
      expect(await app.deleteRealPackingItem(7, 1), PackingOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/packing/1'), isTrue);
      expect(listGets, 2);
    });

    test('check/uncheck PATCH the right paths', () async {
      final seen = <String>[];
      final app = routedApp(onRequest: (r) {
        if (checkPath(r) || uncheckPath(r)) seen.add(r.url.path);
      });
      await app.loadRealPacking(7);
      expect(await app.setRealPackingItemChecked(7, 1, true),
          PackingOutcome.success);
      expect(await app.setRealPackingItemChecked(7, 1, false),
          PackingOutcome.success);
      expect(seen[0].endsWith('/me/trips/packing/1/check'), isTrue);
      expect(seen[1].endsWith('/me/trips/packing/1/uncheck'), isTrue);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/packing'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealPacking(7), PackingOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('403 forbidden on create; 404 on update; 400 validation', () async {
      final f = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/trips/7/packing'), 403),
      );
      expect(await f.createRealPackingItem(7, payload()),
          PackingOutcome.forbidden);

      final nf = routedApp(
        onUpdate: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/trips/packing/1'), 404),
      );
      expect(await nf.updateRealPackingItem(7, 1, payload()),
          PackingOutcome.notFound);

      final inv = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(400, 'x', '/me/trips/7/packing'), 400),
      );
      expect(await inv.createRealPackingItem(7, payload()),
          PackingOutcome.validation);
    });

    test('list 500 → serverError; network', () async {
      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/trips/7/packing'), 500),
      );
      expect(await se.loadRealPacking(7), PackingOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealPacking(7), PackingOutcome.network);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onList: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/me/trips/7/packing'), 500)
            : jsonResponse([itemJson()], 200),
      );
      await app.loadRealPacking(7);
      expect(app.realPackingItemsFor(7), isNotEmpty);
      fail = true;
      expect(await app.loadRealPacking(7, refresh: true),
          PackingOutcome.serverError);
      expect(app.realPackingItemsFor(7), isNotEmpty);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all packing state', () async {
      final app = routedApp();
      await app.loadRealPacking(7);
      expect(app.realPackingItemsFor(7), isNotEmpty);
      await app.logout();
      expect(app.realPackingItemsFor(7), isEmpty);
      expect(app.realPackingTripId, isNull);
      expect(app.realPackingLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders content, progress + item cards', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealTripPackingScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('packing-content')), findsOneWidget);
      expect(find.byKey(const Key('packing-progress')), findsOneWidget);
      expect(find.byKey(const Key('packing-card-1')), findsOneWidget);
    });

    testWidgets('toggling the checkbox PATCHes check', (t) async {
      var checked = 0;
      final app = routedApp(onRequest: (r) {
        if (checkPath(r)) checked++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripPackingScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('packing-check-1')));
      await t.pumpAndSettle();
      expect(checked, 1);
    });

    testWidgets('add opens the form; saving POSTs and closes', (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripPackingScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('packing-add')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('packing-form-content')), findsOneWidget);
      await t.enterText(find.byKey(const Key('packing-field-label')), 'Towel');
      await t.tap(find.byKey(const Key('packing-form-save')));
      await t.pumpAndSettle();
      expect(created, 1);
      expect(find.byKey(const Key('packing-form-content')), findsNothing);
    });

    testWidgets('create form blocks submit without a label (no HTTP)',
        (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripPackingScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('packing-add')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('packing-form-save')));
      await t.pumpAndSettle();
      expect(created, 0);
      expect(find.byKey(const Key('packing-form-content')), findsOneWidget);
    });

    testWidgets('delete confirms then DELETEs', (t) async {
      var deleted = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) deleted++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripPackingScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('packing-delete-1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('packing-delete-confirm')));
      await t.pumpAndSettle();
      expect(deleted, 1);
    });

    testWidgets('empty feed shows the empty state', (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const RealTripPackingScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('packing-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/packing'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealTripPackingScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('packing-session-expired')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI45 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.packingRealTitle,
        en.packingRealLoadingMessage,
        en.packingRealErrorMessage,
        en.packingRealForbiddenMessage,
        en.packingRealGoneMessage,
        en.packingRealNetworkMessage,
        en.packingRealActionErrorMessage,
        en.packingRealCreatedMessage,
        en.packingRealUpdatedMessage,
        en.packingRealDeletedMessage,
        en.packingRealLabelRequiredMessage,
        en.packingRealQuantityInvalidMessage,
        en.packingRealAddSemantic,
        en.packingRealCreateTitle,
        en.packingRealEditTitle,
        en.packingRealEmptyTitle,
        en.packingRealEmptyMessage,
      ];
      final viValues = <String>[
        vi.packingRealTitle,
        vi.packingRealLoadingMessage,
        vi.packingRealErrorMessage,
        vi.packingRealForbiddenMessage,
        vi.packingRealGoneMessage,
        vi.packingRealNetworkMessage,
        vi.packingRealActionErrorMessage,
        vi.packingRealCreatedMessage,
        vi.packingRealUpdatedMessage,
        vi.packingRealDeletedMessage,
        vi.packingRealLabelRequiredMessage,
        vi.packingRealQuantityInvalidMessage,
        vi.packingRealAddSemantic,
        vi.packingRealCreateTitle,
        vi.packingRealEditTitle,
        vi.packingRealEmptyTitle,
        vi.packingRealEmptyMessage,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.packingRealTitle, isNot(vi.packingRealTitle));
    });

    test('parameterized + reused demo keys resolve', () {
      final en = AppLocalizationsEn();
      expect(
          en.packingRealDeleteConfirmMessage('Passport'), contains('Passport'));
      expect(en.packingRealCheckSemantic('Passport'), contains('Passport'));
      expect(en.packingProgressValue(1, 4, 25), contains('25'));
      expect(en.packingLabelField.trim(), isNotEmpty);
      expect(en.packingCategoryDocuments.trim(), isNotEmpty);
    });
  });
}
