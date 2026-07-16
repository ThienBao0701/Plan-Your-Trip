import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planyourtrip_frontend/core/app_state.dart';
import 'package:planyourtrip_frontend/core/mock/app_models.dart';
import 'package:planyourtrip_frontend/core/mock/mock_data.dart';
import 'package:planyourtrip_frontend/design/app_theme.dart';
import 'package:planyourtrip_frontend/features/categories/category_discovery_screen.dart';
import 'package:planyourtrip_frontend/features/expenses/expense_categories.dart';
import 'package:planyourtrip_frontend/features/expenses/expenses_screen.dart';
import 'package:planyourtrip_frontend/features/home/home_screen.dart';
import 'package:planyourtrip_frontend/l10n/app_localizations.dart';
import 'package:planyourtrip_frontend/shared/widgets/glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void ignoreNetworkImageErrors() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is NetworkImageLoadException) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);
  }

  Widget testApp({
    required Widget child,
    AppState? app,
    Locale? locale,
    double textScaleFactor = 1,
  }) {
    return AppScope(
      notifier: app ?? AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data:
                media.copyWith(textScaler: TextScaler.linear(textScaleFactor)),
            child: child!,
          );
        },
        home: child,
      ),
    );
  }

  Future<void> pumpSize(
    WidgetTester tester,
    Widget widget,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  Trip localTrip({
    int id = 501,
    double budget = 1000000,
    String currency = 'VND',
  }) =>
      Trip(
        id: id,
        title: 'UI-5 Da Nang',
        destination: 'Da Nang',
        imageUrl: MockData.places.first.imageUrl,
        startDate: DateTime(2026, 7, 20),
        endDate: DateTime(2026, 7, 22),
        travelers: 2,
        budget: budget,
        budgetCurrency: currency,
      );

  test('category taxonomy uses stable backend root identifiers', () {
    expect(
      CategoryDiscoveryTaxonomy.rootsFor(CategoryDiscoveryMode.foodCafe)
          .map((root) => root.slug),
      ['food', 'cafe'],
    );
    expect(PlaceCategoryRoot.food.backendType, 'FOOD');
    expect(PlaceCategoryRoot.cafe.backendType, 'CAFE');

    final baNa =
        MockData.places.firstWhere((place) => place.name == 'Bà Nà Hills');
    expect(
      CategoryDiscoveryTaxonomy.matchesRoot(
        baNa,
        PlaceCategoryRoot.attraction,
      ),
      isTrue,
    );
    expect(
      CategoryDiscoveryTaxonomy.matchesRoot(
        baNa,
        PlaceCategoryRoot.entertainment,
      ),
      isFalse,
    );
    expect(PlaceCategoryRoot.transportation.backendType, 'TRANSPORTATION');
  });

  testWidgets('Explore category shortcut opens reusable category discovery',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      testApp(
        child: Scaffold(body: HomeScreen(today: DateTime(2026, 7, 16))),
        app: AppState(),
      ),
      const Size(420, 1400),
    );

    final verticalScroll = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Food').first,
      240,
      scrollable: verticalScroll,
    );
    await tester.tap(find.text('Food').first);
    await tester.pumpAndSettle();

    expect(find.text('Food & cafes'), findsWidgets);
    expect(find.text('Bếp Quảng'), findsOneWidget);
  });

  testWidgets('category search derives counts and reaches empty state',
      (tester) async {
    ignoreNetworkImageErrors();
    final app = AppState();
    final expected = app.places
        .where((place) =>
            CategoryDiscoveryTaxonomy.matchesRoot(
                place, PlaceCategoryRoot.food) ||
            CategoryDiscoveryTaxonomy.matchesRoot(
                place, PlaceCategoryRoot.cafe))
        .length;

    await pumpSize(
      tester,
      testApp(
        child: const CategoryDiscoveryScreen(
          mode: CategoryDiscoveryMode.foodCafe,
        ),
        app: app,
      ),
      const Size(420, 960),
    );

    expect(find.text('$expected places'), findsOneWidget);
    expect(find.text('Bếp Quảng'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Cafe'));
    await tester.pumpAndSettle();
    expect(find.text('Túi Mơ To Cafe'), findsOneWidget);
    expect(find.text('Bếp Quảng'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('category-search-field')),
      'zzzzzz',
    );
    await tester.pumpAndSettle();
    expect(find.text('No category results'), findsOneWidget);
  });

  testWidgets('things-to-do and transportation boundaries stay honest',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      testApp(
        child: const CategoryDiscoveryScreen(
          mode: CategoryDiscoveryMode.thingsToDo,
        ),
      ),
      const Size(420, 960),
    );

    expect(find.text('Bà Nà Hills'), findsOneWidget);
    expect(find.text('Helio Center'), findsOneWidget);

    await pumpSize(
      tester,
      testApp(
        child: const CategoryDiscoveryScreen(
          mode: CategoryDiscoveryMode.thingsToDo,
          initialRoot: PlaceCategoryRoot.entertainment,
        ),
      ),
      const Size(420, 960),
    );
    expect(find.text('Helio Center'), findsOneWidget);
    expect(find.text('Bà Nà Hills'), findsNothing);

    await pumpSize(
      tester,
      testApp(
        child: const CategoryDiscoveryScreen(
          mode: CategoryDiscoveryMode.transportation,
        ),
      ),
      const Size(420, 960),
    );

    expect(find.text('Routes not connected'), findsOneWidget);
    expect(find.textContaining('fares, schedules'), findsWidgets);
    expect(find.textContaining('18 minutes'), findsNothing);
    expect(find.textContaining('ticket booking'), findsWidgets);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.text('Map provider not connected'), findsOneWidget);
    expect(find.text('Back to list'), findsOneWidget);
  });

  testWidgets('category detail and quick add reuse supported place behavior',
      (tester) async {
    ignoreNetworkImageErrors();

    await pumpSize(
      tester,
      testApp(
        child: const CategoryDiscoveryScreen(
          mode: CategoryDiscoveryMode.foodCafe,
        ),
      ),
      const Size(420, 1600),
    );

    await tester.enterText(
      find.byKey(const Key('category-search-field')),
      'Bếp',
    );
    await tester.pumpAndSettle();
    final addBepQuang = find.byKey(const Key('category-add-9'));
    await tester.scrollUntilVisible(
      addBepQuang,
      220,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.tap(addBepQuang);
    await tester.pumpAndSettle();
    expect(find.text('Quick Add'), findsOneWidget);
    expect(find.text('Select trip'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpSize(
      tester,
      testApp(
        child: const CategoryDiscoveryScreen(
          mode: CategoryDiscoveryMode.foodCafe,
        ),
      ),
      const Size(420, 1600),
    );
    await tester.tap(find.text('Bếp Quảng').first);
    await tester.pumpAndSettle();
    expect(find.text('Highlights'), findsOneWidget);
    expect(find.textContaining('Menu'), findsNothing);
    expect(find.textContaining('Ticket'), findsNothing);
    expect(find.textContaining('live distance'), findsNothing);
  });

  testWidgets('budget handles no-trip and missing-budget states',
      (tester) async {
    final noTripApp = AppState()
      ..trips = []
      ..timeline = []
      ..expenses = [];

    await pumpSize(
      tester,
      testApp(child: const ExpensesScreen(), app: noTripApp),
      const Size(390, 900),
    );

    expect(find.text('No trip budget yet'), findsOneWidget);
    expect(find.text('Create a trip'), findsOneWidget);

    final trip = localTrip(budget: 0);
    final missingBudgetApp = AppState()
      ..trips = [trip]
      ..timeline = []
      ..expenses = [
        Expense(
          id: 700,
          tripId: trip.id,
          title: 'Lunch',
          category: 'FOOD',
          amount: 120000,
          currency: 'VND',
          date: DateTime(2026, 7, 20),
        ),
      ];

    await pumpSize(
      tester,
      testApp(
        child: ExpensesScreen(filterTripId: trip.id),
        app: missingBudgetApp,
      ),
      const Size(420, 960),
    );

    expect(find.text('Not set'), findsOneWidget);
    expect(
      find.text('Expenses can be tracked before a total budget is set.'),
      findsOneWidget,
    );
    expect(find.text('Lunch'), findsOneWidget);
  });

  testWidgets('set budget sheet updates the selected trip locally',
      (tester) async {
    final trip = localTrip(budget: 0);
    final app = AppState()
      ..trips = [trip]
      ..timeline = []
      ..expenses = [];

    await pumpSize(
      tester,
      testApp(child: ExpensesScreen(filterTripId: trip.id), app: app),
      const Size(420, 960),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Set budget'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('budget-amount-field')),
      '2500000',
    );
    await tester.tap(find.widgetWithText(OceanPrimaryButton, 'Set budget'));
    await tester.pumpAndSettle();

    final updated = app.tripById(trip.id)!;
    expect(updated.budget, 2500000);
    expect(updated.budgetCurrency, 'VND');
  });

  test('budget calculations are deterministic and currency-safe', () {
    final trip = localTrip(budget: 1000000);
    final expenses = [
      Expense(
        id: 1,
        tripId: trip.id,
        title: 'Hotel',
        category: 'ACCOMMODATION',
        amount: 800000,
        currency: 'VND',
        date: DateTime(2026, 7, 20),
      ),
      Expense(
        id: 2,
        tripId: trip.id,
        title: 'Food',
        category: 'FOOD',
        amount: 350000,
        currency: 'VND',
        date: DateTime(2026, 7, 21),
      ),
      Expense(
        id: 3,
        tripId: trip.id,
        title: 'USD item',
        category: 'OTHER',
        amount: 10,
        currency: 'USD',
        date: DateTime(2026, 7, 21),
      ),
    ];

    final snapshot = BudgetSnapshot.from(trip, expenses);
    expect(snapshot.totalSpent, 1150000);
    expect(snapshot.remaining, -150000);
    expect(snapshot.isOverBudget, isTrue);
    expect(snapshot.progressValue, 1);
    expect(snapshot.categoryTotals['FOOD'], 350000);
    expect(snapshot.mixedCurrencies, isTrue);

    final zero = BudgetSnapshot.from(trip.copyWith(budget: 0), expenses);
    expect(zero.progressValue, 0);
    expect(zero.progressValue.isNaN, isFalse);
    expect(zero.progressValue.isInfinite, isFalse);

    expect(
      TripExpenseCategory.values.map((category) => category.code),
      [
        'ACCOMMODATION',
        'FOOD',
        'TRANSPORT',
        'ATTRACTION',
        'SHOPPING',
        'HEALTH',
        'VISA',
        'INSURANCE',
        'OTHER',
      ],
    );
  });

  test('amount parsing rejects zero, negative, malformed and non-finite input',
      () {
    expect(parseMoneyInput('350.000'), 350000);
    expect(parseMoneyInput('0'), isNull);
    expect(parseMoneyInput('-1'), isNull);
    expect(parseMoneyInput('abc'), isNull);
    expect(parseMoneyInput('NaN'), isNull);
    expect(parseMoneyInput('Infinity'), isNull);
  });

  test('expense guards reject orphan, invalid amount and incompatible links',
      () {
    final trip = localTrip();
    final otherTrip = localTrip(id: 999);
    final app = AppState()
      ..trips = [trip, otherTrip]
      ..timeline = [
        TimelineItem(
          id: 10,
          tripId: trip.id,
          dayNumber: 1,
          startTime: '09:00',
          endTime: '10:00',
          title: 'Museum',
        ),
        TimelineItem(
          id: 11,
          tripId: otherTrip.id,
          dayNumber: 1,
          startTime: '09:00',
          endTime: '10:00',
          title: 'Other',
        ),
      ]
      ..expenses = [];

    Expense expense({
      int id = 1,
      double amount = 100000,
      int? day = 1,
      int? item = 10,
    }) =>
        Expense(
          id: id,
          tripId: trip.id,
          title: 'Ticket',
          category: 'ATTRACTION',
          amount: amount,
          currency: 'VND',
          date: DateTime(2026, 7, 20),
          tripDayId: day,
          tripItemId: item,
        );

    expect(app.addExpense(expense(amount: double.infinity)), isFalse);
    expect(app.addExpense(expense(day: 9)), isFalse);
    expect(app.addExpense(expense(item: 11)), isFalse);
    expect(app.addExpense(expense()), isTrue);
    expect(app.expenses, hasLength(1));
  });

  testWidgets('add expense validates amount and prevents duplicate submit',
      (tester) async {
    final trip = localTrip();
    final app = AppState()
      ..trips = [trip]
      ..timeline = []
      ..expenses = [];

    await pumpSize(
      tester,
      testApp(child: ExpensesScreen(filterTripId: trip.id), app: app),
      const Size(420, 960),
    );

    await tester.tap(find.byTooltip('Add expense').first);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('expense-title-field')), 'Taxi');
    await tester.enterText(find.byKey(const Key('expense-amount-field')), '0');
    tester
        .widget<OceanPrimaryButton>(find.byKey(const Key('expense-submit')))
        .onPressed
        ?.call();
    await tester.pump();
    expect(find.text('Use a finite amount above 0.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('expense-amount-field')),
      '180000',
    );
    await tester.tap(find.byKey(const Key('expense-submit')));
    await tester.tap(
      find.byKey(const Key('expense-submit')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(app.expenses, hasLength(1));
    expect(app.expenses.single.title, 'Taxi');
  });

  test('expense edit preserves identity and delete targets one record', () {
    final trip = localTrip();
    final app = AppState()
      ..trips = [trip]
      ..expenses = [
        Expense(
          id: 1,
          tripId: trip.id,
          title: 'Old lunch',
          category: 'FOOD',
          amount: 100000,
          date: DateTime(2026, 7, 20),
        ),
        Expense(
          id: 2,
          tripId: trip.id,
          title: 'Taxi',
          category: 'TRANSPORT',
          amount: 200000,
          date: DateTime(2026, 7, 21),
        ),
      ];

    expect(
      app.updateExpense(app.expenses.first.copyWith(title: 'Updated lunch')),
      isTrue,
    );
    expect(app.expenses.firstWhere((expense) => expense.id == 1).title,
        'Updated lunch');

    app.deleteExpense(2);
    expect(app.expenses.map((expense) => expense.id), [1]);
  });

  testWidgets('real mode does not show demo personal expenses', (tester) async {
    final app = AppState()
      ..demoMode = false
      ..email = 'real@example.com'
      ..trips = []
      ..timeline = []
      ..expenses = [];

    await pumpSize(
      tester,
      testApp(child: const ExpensesScreen(), app: app),
      const Size(390, 900),
    );

    expect(find.text('No trip budget yet'), findsOneWidget);
    expect(find.text('Villa deposit'), findsNothing);
  });

  testWidgets('UI-5 supports Vietnamese, responsive sizes and semantics',
      (tester) async {
    ignoreNetworkImageErrors();
    final semantics = tester.ensureSemantics();
    final app = AppState();
    try {
      await pumpSize(
        tester,
        testApp(
          child: const CategoryDiscoveryScreen(
            mode: CategoryDiscoveryMode.foodCafe,
          ),
          locale: const Locale('vi'),
          textScaleFactor: 1.5,
          app: app,
        ),
        const Size(320, 760),
      );

      expect(find.text('Ẩm thực & cà phê'), findsWidgets);
      expect(tester.takeException(), isNull);

      await pumpSize(
        tester,
        testApp(
          child: ExpensesScreen(filterTripId: MockData.trips.first.id),
          locale: const Locale('vi'),
          app: AppState(),
        ),
        const Size(1280, 860),
      );

      expect(find.text('Ngân sách chuyến đi'), findsOneWidget);
      expect(
          find.bySemanticsLabel(RegExp('Tiến độ ngân sách')), findsOneWidget);
      expect(find.bySemanticsLabel('Thêm chi phí'), findsWidgets);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
