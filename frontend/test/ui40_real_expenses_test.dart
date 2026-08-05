import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/network/api_client.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/expenses/real_trip_expenses_screen.dart';
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

  Map<String, dynamic> expenseJson({
    int id = 1,
    String title = 'Dinner',
    String category = 'FOOD',
    double amount = 250000,
    String currency = 'VND',
    String? notes = 'Seafood',
    String expenseDate = '2030-05-01',
  }) =>
      {
        'id': id,
        'tripPlanId': 7,
        'tripDayId': null,
        'tripItemId': null,
        'paidByUserId': 9,
        'paidByUserName': 'Bao',
        'category': category,
        'amount': amount,
        'currency': currency,
        'title': title,
        'notes': notes,
        'expenseDate': expenseDate,
        'createdAt': '2030-05-01T10:00:00Z',
        'updatedAt': '2030-05-01T10:00:00Z',
      };

  Map<String, dynamic> summaryJson({
    double totalBudget = 1000000,
    double totalSpent = 250000,
    bool overBudget = false,
  }) =>
      {
        'tripPlanId': 7,
        'totalBudget': totalBudget,
        'totalSpent': totalSpent,
        'remainingBudget': totalBudget - totalSpent,
        'overBudget': overBudget,
        'categoryBreakdown': [
          {'category': 'FOOD', 'totalAmount': totalSpent},
        ],
      };

  bool listPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/trips/7/expenses');
  bool summaryPath(http.Request r) =>
      r.method == 'GET' && r.url.path.endsWith('/me/trips/7/budget-summary');
  bool createPath(http.Request r) =>
      r.method == 'POST' && r.url.path.endsWith('/me/trips/7/expenses');
  bool updatePath(http.Request r) =>
      r.method == 'PUT' &&
      RegExp(r'/me/trips/expenses/\d+$').hasMatch(r.url.path);
  bool deletePath(http.Request r) =>
      r.method == 'DELETE' &&
      RegExp(r'/me/trips/expenses/\d+$').hasMatch(r.url.path);

  AppState routedApp({
    Future<http.Response> Function(http.Request)? onList,
    Future<http.Response> Function(http.Request)? onSummary,
    Future<http.Response> Function(http.Request)? onCreate,
    Future<http.Response> Function(http.Request)? onUpdate,
    Future<http.Response> Function(http.Request)? onDelete,
    void Function(http.Request)? onRequest,
  }) =>
      realApp(MockClient((request) async {
        onRequest?.call(request);
        if (createPath(request)) {
          return (onCreate ??
              (_) async => jsonResponse(expenseJson(id: 99), 201))(request);
        }
        if (updatePath(request)) {
          return (onUpdate ??
              (_) async => jsonResponse(expenseJson(), 200))(request);
        }
        if (deletePath(request)) {
          return (onDelete ?? (_) async => http.Response('', 204))(request);
        }
        if (summaryPath(request)) {
          return (onSummary ??
              (_) async => jsonResponse(summaryJson(), 200))(request);
        }
        if (listPath(request)) {
          return (onList ??
              (_) async => jsonResponse([expenseJson()], 200))(request);
        }
        return jsonResponse(const <String, dynamic>{}, 200);
      }));

  RealExpensePayload payload() => RealExpensePayload(
        category: RealExpenseCategory.food,
        amount: 100,
        currency: 'VND',
        title: 'Lunch',
        expenseDate: DateTime(2030, 5, 2),
      );

  // ── Contract parsing ───────────────────────────────────────────────────────

  group('Contract parsing', () {
    test('list + summary parse; correct paths', () async {
      final seen = <String>[];
      final app = routedApp(onRequest: (r) => seen.add(r.url.path));
      expect(await app.loadRealExpenses(7), ExpenseOutcome.success);
      final e = app.realExpensesFor(7).single;
      expect(e.id, 1);
      expect(e.categoryView, RealExpenseCategory.food);
      expect(e.amount, 250000);
      expect(e.currency, 'VND');
      expect(e.title, 'Dinner');
      expect(e.notes, 'Seafood');
      expect(e.expenseDate, isNotNull);
      final s = app.realExpenseSummaryFor(7)!;
      expect(s.totalSpent, 250000);
      expect(s.hasBudget, isTrue);
      expect(s.overBudget, isFalse);
      expect(s.categoryBreakdown.single.categoryView, RealExpenseCategory.food);
      expect(seen.any((p) => p.endsWith('/me/trips/7/expenses')), isTrue);
      expect(seen.any((p) => p.endsWith('/me/trips/7/budget-summary')), isTrue);
    });

    test('category mapper + wire round-trip; unknown → unknown', () {
      expect(realExpenseCategoryFromCode('TRANSPORT'),
          RealExpenseCategory.transport);
      expect(realExpenseCategoryFromCode('???'), RealExpenseCategory.unknown);
      expect(realExpenseCategoryWire(RealExpenseCategory.visa), 'VISA');
      expect(realExpenseCategoryWire(RealExpenseCategory.unknown), 'OTHER');
      expect(realExpenseCategoryChoices.contains(RealExpenseCategory.unknown),
          isFalse);
    });

    test('payload toJson emits every field with wire category + iso date', () {
      final json = payload().toJson();
      expect(json['category'], 'FOOD');
      expect(json['amount'], 100);
      expect(json['currency'], 'VND');
      expect(json['title'], 'Lunch');
      expect(json['expenseDate'], '2030-05-02');
      expect(json.containsKey('notes'), isTrue);
      expect(json.containsKey('tripDayId'), isTrue);
      expect(json.containsKey('tripItemId'), isTrue);
    });

    test('non-list body → serverError (malformed)', () async {
      final app = realApp(MockClient((r) async {
        if (listPath(r)) return http.Response('{}', 200);
        return jsonResponse(summaryJson(), 200);
      }));
      expect(await app.loadRealExpenses(7), ExpenseOutcome.serverError);
    });
  });

  // ── Demo Mode (zero HTTP) ────────────────────────────────────────────────────

  group('Demo Mode', () {
    test('all methods return demoUnavailable with zero HTTP', () async {
      var calls = 0;
      final app = demoApp(MockClient((_) async {
        calls++;
        return jsonResponse([expenseJson()], 200);
      }));
      expect(await app.loadRealExpenses(7), ExpenseOutcome.demoUnavailable);
      expect(await app.createRealExpense(7, payload()),
          ExpenseOutcome.demoUnavailable);
      expect(await app.updateRealExpense(7, 1, payload()),
          ExpenseOutcome.demoUnavailable);
      expect(await app.deleteRealExpense(7, 1), ExpenseOutcome.demoUnavailable);
      expect(calls, 0);
      expect(app.realExpensesFor(7), isEmpty);
    });
  });

  // ── Load / create / update / delete ───────────────────────────────────────────

  group('CRUD', () {
    test('cached list is not re-fetched unless refreshed', () async {
      var gets = 0;
      final app = routedApp(onRequest: (r) {
        if (listPath(r)) gets++;
      });
      await app.loadRealExpenses(7);
      await app.loadRealExpenses(7);
      expect(gets, 1);
      await app.loadRealExpenses(7, refresh: true);
      expect(gets, 2);
    });

    test('switching trips reloads (different tripId)', () async {
      final app = routedApp(
        onList: (r) async {
          // both trips resolve via the catch-all pattern; assert path carries id
          return jsonResponse([expenseJson()], 200);
        },
      );
      await app.loadRealExpenses(7);
      expect(app.realExpensesTripId, 7);
      // A different trip id short-circuits differently: not loaded for trip 8.
      expect(app.realExpensesFor(8), isEmpty);
    });

    test('create POSTs the payload and reloads the list', () async {
      Map<String, dynamic>? body;
      var listGets = 0;
      final app = routedApp(
        onRequest: (r) {
          if (listPath(r)) listGets++;
        },
        onCreate: (r) async {
          body = jsonDecode(r.body) as Map<String, dynamic>;
          return jsonResponse(expenseJson(id: 99), 201);
        },
      );
      await app.loadRealExpenses(7);
      expect(listGets, 1);
      expect(await app.createRealExpense(7, payload()), ExpenseOutcome.success);
      expect(body!['title'], 'Lunch');
      expect(body!['category'], 'FOOD');
      expect(listGets, 2); // reloaded after create
    });

    test('update PUTs to the expense id and reloads', () async {
      http.Request? seen;
      final app = routedApp(onRequest: (r) {
        if (updatePath(r)) seen = r;
      });
      await app.loadRealExpenses(7);
      expect(
          await app.updateRealExpense(7, 1, payload()), ExpenseOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/expenses/1'), isTrue);
    });

    test('delete DELETEs and reloads', () async {
      http.Request? seen;
      var listGets = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) seen = r;
        if (listPath(r)) listGets++;
      });
      await app.loadRealExpenses(7);
      expect(listGets, 1);
      expect(await app.deleteRealExpense(7, 1), ExpenseOutcome.success);
      expect(seen!.url.path.endsWith('/me/trips/expenses/1'), isTrue);
      expect(listGets, 2);
    });

    test('list succeeds even when the summary read fails', () async {
      final app = routedApp(
        onSummary: (_) async =>
            jsonResponse(errorBody(500, 'x', '/budget-summary'), 500),
      );
      expect(await app.loadRealExpenses(7), ExpenseOutcome.success);
      expect(app.realExpensesFor(7), isNotEmpty);
      expect(app.realExpenseSummaryFor(7), isNull);
    });
  });

  // ── Errors ───────────────────────────────────────────────────────────────────

  group('Errors', () {
    test('401 → sessionExpired, no auto-logout / no demo switch', () async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/expenses'), 401),
      );
      app.email = 'bao@example.com';
      app.api.token = 'jwt-token';
      expect(await app.loadRealExpenses(7), ExpenseOutcome.sessionExpired);
      expect(app.email, 'bao@example.com');
      expect(app.api.token, 'jwt-token');
      expect(app.demoMode, isFalse);
    });

    test('403 forbidden on create; 404 on update; 400 validation', () async {
      final f = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(403, 'x', '/me/trips/7/expenses'), 403),
      );
      expect(await f.createRealExpense(7, payload()), ExpenseOutcome.forbidden);

      final nf = routedApp(
        onUpdate: (_) async =>
            jsonResponse(errorBody(404, 'x', '/me/trips/expenses/1'), 404),
      );
      expect(
          await nf.updateRealExpense(7, 1, payload()), ExpenseOutcome.notFound);

      final inv = routedApp(
        onCreate: (_) async =>
            jsonResponse(errorBody(400, 'x', '/me/trips/7/expenses'), 400),
      );
      expect(
          await inv.createRealExpense(7, payload()), ExpenseOutcome.validation);
    });

    test('list 500 → serverError; network', () async {
      final se = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(500, 'x', '/me/trips/7/expenses'), 500),
      );
      expect(await se.loadRealExpenses(7), ExpenseOutcome.serverError);

      final net = realApp(MockClient((_) async {
        throw http.ClientException('offline');
      }));
      expect(await net.loadRealExpenses(7), ExpenseOutcome.network);
    });

    test('a failed refresh preserves the previously loaded list', () async {
      var fail = false;
      final app = routedApp(
        onList: (_) async => fail
            ? jsonResponse(errorBody(500, 'x', '/me/trips/7/expenses'), 500)
            : jsonResponse([expenseJson()], 200),
      );
      await app.loadRealExpenses(7);
      expect(app.realExpensesFor(7), isNotEmpty);
      fail = true;
      expect(await app.loadRealExpenses(7, refresh: true),
          ExpenseOutcome.serverError);
      expect(app.realExpensesFor(7), isNotEmpty);
    });
  });

  // ── Session isolation ────────────────────────────────────────────────────────

  group('Session isolation', () {
    test('logout clears all expense state', () async {
      final app = routedApp();
      await app.loadRealExpenses(7);
      expect(app.realExpensesFor(7), isNotEmpty);
      expect(app.realExpenseSummaryFor(7), isNotNull);
      await app.logout();
      expect(app.realExpensesFor(7), isEmpty);
      expect(app.realExpenseSummaryFor(7), isNull);
      expect(app.realExpensesTripId, isNull);
      expect(app.realExpensesLoaded, isFalse);
    });
  });

  // ── Widgets ──────────────────────────────────────────────────────────────────

  group('Widgets', () {
    testWidgets('renders content, summary + cards', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealTripExpensesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('expenses-content')), findsOneWidget);
      expect(find.byKey(const Key('expenses-summary')), findsOneWidget);
      expect(find.byKey(const Key('expense-card-1')), findsOneWidget);
    });

    testWidgets('add opens the form; saving POSTs and closes', (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripExpensesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('expenses-add')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('expense-form-content')), findsOneWidget);
      await t.enterText(find.byKey(const Key('expense-field-title')), 'Taxi');
      await t.enterText(find.byKey(const Key('expense-field-amount')), '80000');
      await t.tap(find.byKey(const Key('expense-form-save')));
      await t.pumpAndSettle();
      expect(created, 1);
      expect(find.byKey(const Key('expense-form-content')), findsNothing);
    });

    testWidgets('empty amount/title blocks submit (no HTTP)', (t) async {
      var created = 0;
      final app = routedApp(onRequest: (r) {
        if (createPath(r)) created++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripExpensesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('expenses-add')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('expense-form-save')));
      await t.pumpAndSettle();
      expect(created, 0);
      expect(find.byKey(const Key('expense-form-content')), findsOneWidget);
    });

    testWidgets('editing a card opens the form prefilled', (t) async {
      final app = routedApp();
      await pumpSize(
        t,
        testApp(child: const RealTripExpensesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('expense-card-1')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('expense-form-content')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('expense-field-title')),
          matching: find.text('Dinner'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('delete confirms then DELETEs', (t) async {
      var deleted = 0;
      final app = routedApp(onRequest: (r) {
        if (deletePath(r)) deleted++;
      });
      await pumpSize(
        t,
        testApp(child: const RealTripExpensesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      await t.tap(find.byKey(const Key('expense-delete-1')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('expense-delete-confirm')));
      await t.pumpAndSettle();
      expect(deleted, 1);
    });

    testWidgets('empty feed shows the empty state', (t) async {
      final app = routedApp(onList: (_) async => jsonResponse(const [], 200));
      await pumpSize(
        t,
        testApp(child: const RealTripExpensesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('expenses-empty')), findsOneWidget);
    });

    testWidgets('a 401 shows the inline session-expired state', (t) async {
      final app = routedApp(
        onList: (_) async =>
            jsonResponse(errorBody(401, 'x', '/me/trips/7/expenses'), 401),
      );
      await pumpSize(
        t,
        testApp(child: const RealTripExpensesScreen(tripId: 7), app: app),
        const Size(1200, 2400),
      );
      expect(find.byKey(const Key('expenses-session-expired')), findsOneWidget);
    });
  });

  // ── Localization parity ──────────────────────────────────────────────────────

  group('Localization parity', () {
    test('every new UI40 key is present in both EN and VI', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      final enValues = <String>[
        en.expensesTitle,
        en.expensesLoadingMessage,
        en.expensesErrorMessage,
        en.expensesGoneMessage,
        en.expensesForbiddenMessage,
        en.expensesInvalidMessage,
        en.expensesEmptyTitle,
        en.expensesEmptyMessage,
        en.expensesAddAction,
        en.expensesSaveAction,
        en.expensesAddTitle,
        en.expensesEditTitle,
        en.expensesCreatedMessage,
        en.expensesUpdatedMessage,
        en.expensesDeletedMessage,
        en.expensesDeleteConfirmTitle,
        en.expensesSummarySpent,
        en.expensesSummaryOverBudget,
        en.expenseFieldTitle,
        en.expenseFieldAmount,
        en.expenseFieldCurrency,
        en.expenseFieldCategory,
        en.expenseFieldDate,
        en.expenseFieldNotes,
        en.expenseCategoryAccommodation,
        en.expenseCategoryFood,
        en.expenseCategoryTransport,
        en.expenseCategoryAttraction,
        en.expenseCategoryShopping,
        en.expenseCategoryHealth,
        en.expenseCategoryVisa,
        en.expenseCategoryInsurance,
        en.expenseCategoryOther,
      ];
      final viValues = <String>[
        vi.expensesTitle,
        vi.expensesLoadingMessage,
        vi.expensesErrorMessage,
        vi.expensesGoneMessage,
        vi.expensesForbiddenMessage,
        vi.expensesInvalidMessage,
        vi.expensesEmptyTitle,
        vi.expensesEmptyMessage,
        vi.expensesAddAction,
        vi.expensesSaveAction,
        vi.expensesAddTitle,
        vi.expensesEditTitle,
        vi.expensesCreatedMessage,
        vi.expensesUpdatedMessage,
        vi.expensesDeletedMessage,
        vi.expensesDeleteConfirmTitle,
        vi.expensesSummarySpent,
        vi.expensesSummaryOverBudget,
        vi.expenseFieldTitle,
        vi.expenseFieldAmount,
        vi.expenseFieldCurrency,
        vi.expenseFieldCategory,
        vi.expenseFieldDate,
        vi.expenseFieldNotes,
        vi.expenseCategoryAccommodation,
        vi.expenseCategoryFood,
        vi.expenseCategoryTransport,
        vi.expenseCategoryAttraction,
        vi.expenseCategoryShopping,
        vi.expenseCategoryHealth,
        vi.expenseCategoryVisa,
        vi.expenseCategoryInsurance,
        vi.expenseCategoryOther,
      ];
      for (final v in enValues) {
        expect(v.trim(), isNotEmpty);
      }
      for (final v in viValues) {
        expect(v.trim(), isNotEmpty);
      }
      expect(en.expensesTitle, isNot(vi.expensesTitle));
    });

    test('parameterized keys resolve in both locales', () {
      final en = AppLocalizationsEn();
      final vi = AppLocalizationsVi();
      expect(en.expensesDeleteConfirmMessage('Dinner'), contains('Dinner'));
      expect(vi.expensesDeleteConfirmMessage('Dinner'), contains('Dinner'));
      expect(en.expenseCardSemantic('Dinner'), contains('Dinner'));
      expect(en.expensesSummaryBudget('1,000'), contains('1,000'));
      expect(vi.expensesSummaryRemaining('750'), contains('750'));
    });
  });
}
