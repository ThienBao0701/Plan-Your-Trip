import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/trips/real_trip_budget_screen.dart';
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

  Map<String, dynamic> budgetJson({
    int id = 1,
    double totalBudget = 1000,
    String currency = 'USD',
    String? notes = 'Main trip fund',
  }) =>
      {
        'id': id,
        'tripPlanId': 7,
        'totalBudget': totalBudget,
        'currency': currency,
        'notes': notes,
        'createdAt': '2030-04-01T08:00:00Z',
        'updatedAt': '2030-04-02T08:00:00Z',
      };

  Map<String, dynamic> summaryJson({
    double totalBudget = 1000,
    double totalSpent = 250,
    double remainingBudget = 750,
    bool overBudget = false,
  }) =>
      {
        'tripPlanId': 7,
        'totalBudget': totalBudget,
        'totalSpent': totalSpent,
        'remainingBudget': remainingBudget,
        'overBudget': overBudget,
        'categoryBreakdown': const [],
      };

  bool summaryPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/trips/7/budget-summary');
  bool budgetGetPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/trips/7/budget');
  bool upsertPath(http.Request r) =>
      r.method == 'PUT' && r.url.path.endsWith('/me/trips/7/budget');
  bool deletePath(http.Request r) =>
      r.method == 'DELETE' && r.url.path.endsWith('/me/trips/7/budget');

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onSummary,
    Future<http.Response> Function(http.Request)? onBudget,
    Future<http.Response> Function(http.Request)? onUpsert,
    Future<http.Response> Function(http.Request)? onDelete,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (upsertPath(request)) {
          return (onUpsert ??
              (_) async => jsonResponse(budgetJson(), 200))(request);
        }
        if (deletePath(request)) {
          return (onDelete ?? (_) async => http.Response('', 204))(request);
        }
        if (summaryPath(request)) {
          return (onSummary ??
              (_) async => jsonResponse(summaryJson(), 200))(request);
        }
        if (budgetGetPath(request)) {
          return (onBudget ??
              (_) async => jsonResponse(budgetJson(), 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  RealBudgetPayload payload() => const RealBudgetPayload(
        totalBudget: 2000,
        currency: 'EUR',
        notes: 'Updated',
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('budget + summary parse; correct paths', () async {
      final seen = <String>[];
      final app = routedApp(onRequest: (r) {
        if (budgetGetPath(r) || summaryPath(r)) seen.add(r.url.path);
      });
      expect(await app.loadRealBudget(7), BudgetOutcome.success);
      final b = app.realBudgetFor(7)!;
      expect(b.id, 1);
      expect(b.totalBudget, 1000);
      expect(b.currency, 'USD');
      expect(b.notes, 'Main trip fund');
      final s = app.realBudgetSummaryFor(7)!;
      expect(s.totalSpent, 250);
      expect(s.remainingBudget, 750);
      expect(s.overBudget, isFalse);
      expect(seen.any((p) => p.endsWith('/me/trips/7/budget-summary')), isTrue);
      expect(seen.any((p) => p.endsWith('/me/trips/7/budget')), isTrue);
    });

    test('RealBudget.fromJson defaults on missing fields', () {
      final b = RealBudget.fromJson(const {'id': 5});
      expect(b.id, 5);
      expect(b.totalBudget, 0);
      expect(b.currency, '');
      expect(b.notes, isNull);
    });

    test('payload toJson emits totalBudget, currency, notes', () {
      final json = payload().toJson();
      expect(json['totalBudget'], 2000);
      expect(json['currency'], 'EUR');
      expect(json['notes'], 'Updated');
    });

    test('malformed budget body → treated as no budget (still loads)',
        () async {
      final app = routedApp(
        onBudget: (_) async => http.Response('not-json', 200),
      );
      expect(await app.loadRealBudget(7), BudgetOutcome.success);
      expect(app.realBudgetFor(7), isNull);
      expect(app.realBudgetSummaryFor(7), isNotNull);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse(budgetJson(), 200);
      }));
      expect(await app.loadRealBudget(7), BudgetOutcome.demoUnavailable);
      expect(await app.saveRealBudget(7, payload()),
          BudgetOutcome.demoUnavailable);
      expect(await app.deleteRealBudget(7), BudgetOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realBudgetFor(7), isNull);
    });
  });

  // ── CRUD ────────────────────────────────────────────────────────────────────

  group('CRUD', () {
    test('cached not re-fetched unless refreshed', () async {
      var summaries = 0;
      final app = routedApp(onRequest: (r) {
        if (summaryPath(r)) summaries++;
      });
      await app.loadRealBudget(7);
      await app.loadRealBudget(7);
      expect(summaries, 1);
      await app.loadRealBudget(7, refresh: true);
      expect(summaries, 2);
    });

    test('budget 404 → no budget set (null), still loads with summary',
        () async {
      final app = routedApp(
        onBudget: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/trips/7/budget'), 404),
      );
      expect(await app.loadRealBudget(7), BudgetOutcome.success);
      expect(app.realBudgetFor(7), isNull);
      expect(app.realBudgetSummaryFor(7), isNotNull);
      expect(app.realBudgetLoaded, isTrue);
    });

    test('save PUTs the payload and reloads', () async {
      Map<String, dynamic>? body;
      var summaries = 0;
      final app = routedApp(
        onRequest: (r) {
          if (summaryPath(r)) summaries++;
        },
        onUpsert: (r) async {
          body = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(
              budgetJson(totalBudget: 2000, currency: 'EUR'), 200);
        },
      );
      await app.loadRealBudget(7);
      expect(summaries, 1);
      expect(await app.saveRealBudget(7, payload()), BudgetOutcome.success);
      expect(body!['totalBudget'], 2000);
      expect(body!['currency'], 'EUR');
      expect(summaries, 2);
    });

    test('negative amount / blank currency → validation, no HTTP', () async {
      var calls = 0;
      final app = routedApp(onRequest: (_) => calls++);
      const negative = RealBudgetPayload(totalBudget: -1, currency: 'USD');
      const blankCurrency =
          RealBudgetPayload(totalBudget: 100, currency: '   ');
      expect(await app.saveRealBudget(7, negative), BudgetOutcome.validation);
      expect(
          await app.saveRealBudget(7, blankCurrency), BudgetOutcome.validation);
      expect(calls, 0);
    });

    test('delete DELETEs and reloads', () async {
      http.Request? seen;
      var summaries = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) seen = r;
        if (summaryPath(r)) summaries++;
      });
      await app.loadRealBudget(7);
      expect(await app.deleteRealBudget(7), BudgetOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/7/budget'), isTrue);
      expect(summaries, 2);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('summary 401 → sessionExpired, no auto-logout / no demo switch',
        () async {
      final app = routedApp(
        onSummary: (_) async => jsonResponse(
            errorBody(401, 'x', '/me/trips/7/budget-summary'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealBudget(7), BudgetOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
      expect(app.realBudgetLoaded, isFalse);
    });

    test('save 403 → forbidden (owner-only)', () async {
      final app = routedApp(
        onUpsert: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/trips/7/budget'), 403),
      );
      expect(await app.saveRealBudget(7, payload()), BudgetOutcome.forbidden);
    });

    test('save 400 → validation; summary 500 → serverError; network', () async {
      final inv = routedApp(
        onUpsert: (_) async =>
            jsonResponse(errorBody(400, 'x', '/me/trips/7/budget'), 400),
      );
      expect(await inv.saveRealBudget(7, payload()), BudgetOutcome.validation);

      final se = routedApp(
        onSummary: (_) async => jsonResponse(
            errorBody(500, 'x', '/me/trips/7/budget-summary'), 500),
      );
      expect(await se.loadRealBudget(7), BudgetOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealBudget(7), BudgetOutcome.network);
    });

    test('a failed refresh preserves the previously loaded budget', () async {
      var fail = false;
      final app = routedApp(
        onSummary: (_) async => fail
            ? jsonResponse(
                errorBody(500, 'x', '/me/trips/7/budget-summary'), 500)
            : jsonResponse(summaryJson(), 200),
      );
      await app.loadRealBudget(7);
      expect(app.realBudgetFor(7), isNotNull);
      fail = true;
      expect(await app.loadRealBudget(7, refresh: true),
          BudgetOutcome.serverError);
      expect(app.realBudgetFor(7), isNotNull);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all budget state', () async {
      final app = routedApp();
      await app.loadRealBudget(7);
      expect(app.realBudgetFor(7), isNotNull);
      await app.logout();
      expect(app.realBudgetFor(7), isNull);
      expect(app.realBudgetSummaryFor(7), isNull);
      expect(app.realBudgetTripId, isNull);
      expect(app.realBudgetLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders content, budget card + progress', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealTripBudgetScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('budget-content')), findsOneWidget);
      expect(find.byKey(const Key('budget-card')), findsOneWidget);
      expect(find.byKey(const Key('budget-progress')), findsOneWidget);
    });

    testWidgets('no budget → empty state with set action', (t) async {
      final app = routedApp(
        onBudget: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/trips/7/budget'), 404),
      );
      await pumpSize(
        t,
        testApp(child: const RealTripBudgetScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('budget-empty')), findsOneWidget);
    });

    testWidgets('set form saves via PUT and closes', (t) async {
      var puts = 0;
      final app = routedApp(
        onBudget: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/trips/7/budget'), 404),
        onUpsert: (r) async {
          puts++;
          return jsonResponse(budgetJson(), 200);
        },
      );
      await pumpSize(
        t,
        testApp(child: const RealTripBudgetScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      // The empty-state action ("Set budget") opens the form.
      await t.tap(find.text(AppLocalizationsEn().budgetSetAction));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('budget-form-content')), findsOneWidget);
      await t.enterText(find.byKey(const Key('budget-field-amount')), '500');
      await t.enterText(find.byKey(const Key('budget-field-currency')), 'USD');
      await t.tap(find.byKey(const Key('budget-form-save')));
      await t.pumpAndSettle();
      expect(puts, 1);
      expect(find.byKey(const Key('budget-form-content')), findsNothing);
    });

    testWidgets('edit form saves via PUT', (t) async {
      var puts = 0;
      final app = routedApp(onUpsert: (r) async {
        puts++;
        return jsonResponse(budgetJson(), 200);
      });
      await pumpSize(
        t,
        testApp(child: const RealTripBudgetScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('budget-edit')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('budget-form-content')), findsOneWidget);
      await t.tap(find.byKey(const Key('budget-form-save')));
      await t.pumpAndSettle();
      expect(puts, 1);
    });

    testWidgets('form blocks submit with a negative amount (no HTTP)',
        (t) async {
      var puts = 0;
      final app = routedApp(onUpsert: (r) async {
        puts++;
        return jsonResponse(budgetJson(), 200);
      });
      await pumpSize(
        t,
        testApp(child: const RealTripBudgetScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('budget-edit')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('budget-field-amount')), '-5');
      await t.tap(find.byKey(const Key('budget-form-save')));
      await t.pumpAndSettle();
      expect(puts, 0);
      expect(find.byKey(const Key('budget-form-content')), findsOneWidget);
    });

    testWidgets('delete confirms then DELETEs', (t) async {
      var deleted = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) deleted++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripBudgetScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('budget-delete')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('budget-delete-confirm')));
      await t.pumpAndSettle();
      expect(deleted, 1);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onSummary: (_) async => jsonResponse(
            errorBody(401, 'x', '/me/trips/7/budget-summary'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealTripBudgetScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('budget-session-expired')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI47 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.budgetRealTitle,
        en.budgetRealLoadingMessage,
        en.budgetRealErrorMessage,
        en.budgetRealForbiddenMessage,
        en.budgetRealGoneMessage,
        en.budgetRealNetworkMessage,
        en.budgetRealActionErrorMessage,
        en.budgetRealSavedMessage,
        en.budgetRealDeletedMessage,
        en.budgetRealAmountInvalidMessage,
        en.budgetRealCurrencyRequiredMessage,
        en.budgetRealEmptyTitle,
        en.budgetRealEmptyMessage,
        en.budgetRealSetTitle,
        en.budgetRealEditTitle,
        en.budgetRealSaveAction,
        en.budgetRealEditAction,
        en.budgetRealDeleteAction,
        en.budgetRealDeleteConfirmTitle,
        en.budgetRealDeleteConfirmMessage,
      ];
      final viValues = <String>[
        vi.budgetRealTitle,
        vi.budgetRealLoadingMessage,
        vi.budgetRealErrorMessage,
        vi.budgetRealForbiddenMessage,
        vi.budgetRealGoneMessage,
        vi.budgetRealNetworkMessage,
        vi.budgetRealActionErrorMessage,
        vi.budgetRealSavedMessage,
        vi.budgetRealDeletedMessage,
        vi.budgetRealAmountInvalidMessage,
        vi.budgetRealCurrencyRequiredMessage,
        vi.budgetRealEmptyTitle,
        vi.budgetRealEmptyMessage,
        vi.budgetRealSetTitle,
        vi.budgetRealEditTitle,
        vi.budgetRealSaveAction,
        vi.budgetRealEditAction,
        vi.budgetRealDeleteAction,
        vi.budgetRealDeleteConfirmTitle,
        vi.budgetRealDeleteConfirmMessage,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.budgetRealTitle, isNot(vi.budgetRealTitle));
    });

    test('reused demo/UI40 budget keys resolve', () {
      final en = AppLocalizationsEn();
      expect(en.budgetTotalBudget.trim(), isNotEmpty);
      expect(en.budgetSpent.trim(), isNotEmpty);
      expect(en.budgetLeft.trim(), isNotEmpty);
      expect(en.budgetSetAction.trim(), isNotEmpty);
      expect(en.budgetAmountLabel.trim(), isNotEmpty);
      expect(en.budgetProgressLabel(25), contains('25'));
      expect(en.budgetProgressSemantic(25), contains('25'));
      expect(en.expensesSummaryOverBudget.trim(), isNotEmpty);
    });
  });
}
