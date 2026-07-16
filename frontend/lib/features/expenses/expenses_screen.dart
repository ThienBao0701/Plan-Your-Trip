import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../trips/create_trip_screen.dart';
import 'expense_categories.dart';

const String defaultBudgetCurrency = 'VND';
const List<String> supportedBudgetCurrencies = ['VND', 'USD'];

class BudgetSnapshot {
  final Trip trip;
  final String currency;
  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final bool mixedCurrencies;
  final Map<String, double> categoryTotals;

  const BudgetSnapshot({
    required this.trip,
    required this.currency,
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.mixedCurrencies,
    required this.categoryTotals,
  });

  factory BudgetSnapshot.from(Trip trip, List<Expense> expenses) {
    final currency = trip.budgetCurrency.trim().isEmpty
        ? defaultBudgetCurrency
        : trip.budgetCurrency.trim();
    final tripExpenses =
        expenses.where((expense) => expense.tripId == trip.id).toList();
    final currencies = tripExpenses.map((e) => e.currency).toSet();
    final sameCurrency =
        tripExpenses.where((expense) => expense.currency == currency);
    final totals = {
      for (final category in TripExpenseCategory.values) category.code: 0.0,
    };
    var spent = 0.0;
    for (final expense in sameCurrency) {
      spent += expense.amount;
      final category = TripExpenseCategoryData.fromCode(expense.category);
      totals[category.code] = (totals[category.code] ?? 0) + expense.amount;
    }
    return BudgetSnapshot(
      trip: trip,
      currency: currency,
      totalBudget: trip.budget,
      totalSpent: spent,
      remaining: trip.budget - spent,
      mixedCurrencies: currencies.any((value) => value != currency),
      categoryTotals: totals,
    );
  }

  bool get hasBudget => totalBudget > 0;
  bool get isOverBudget => hasBudget && remaining < 0;
  double get overBudgetAmount => math.max(0, -remaining);
  double get progressValue =>
      hasBudget ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0;
  int get progressPercent =>
      hasBudget ? (progressValue * 100).round().clamp(0, 100) : 0;
}

class ExpensesScreen extends StatefulWidget {
  final int? filterTripId;

  const ExpensesScreen({super.key, this.filterTripId});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int? _tripId;
  TripExpenseCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _tripId = widget.filterTripId;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final selectedTrip = _resolveTrip(app);

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.budgetTitle),
        actions: [
          if (selectedTrip != null)
            Semantics(
              button: true,
              label: l10n.expenseAddSemantic,
              child: IconButton(
                tooltip: l10n.expenseAddSemantic,
                onPressed: () => _showExpenseSheet(app, selectedTrip),
                icon: const Icon(Icons.add_rounded),
              ),
            ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: selectedTrip == null
                    ? OceanEmptyState(
                        title: l10n.budgetNoTripTitle,
                        message: l10n.budgetNoTripMessage,
                        actionLabel: l10n.tripsCreateAction,
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateTripScreen(),
                          ),
                        ),
                      )
                    : _BudgetContent(
                        app: app,
                        trip: selectedTrip,
                        categoryFilter: _categoryFilter,
                        onTripChanged: widget.filterTripId == null
                            ? (tripId) => setState(() {
                                  _tripId = tripId;
                                  _categoryFilter = null;
                                })
                            : null,
                        onSetBudget: () => _showBudgetSheet(app, selectedTrip),
                        onAddExpense: () =>
                            _showExpenseSheet(app, selectedTrip),
                        onEditExpense: (expense) =>
                            _showExpenseSheet(app, selectedTrip, expense),
                        onDeleteExpense: (expense) =>
                            _confirmDelete(app, expense),
                        onCategoryFilter: (category) =>
                            setState(() => _categoryFilter = category),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Trip? _resolveTrip(AppState app) {
    if (app.trips.isEmpty) return null;
    final requested = _tripId ?? widget.filterTripId;
    if (requested != null) {
      for (final trip in app.trips) {
        if (trip.id == requested) {
          _tripId = trip.id;
          return trip;
        }
      }
    }
    _tripId = app.trips.first.id;
    return app.trips.first;
  }

  Future<void> _showBudgetSheet(AppState app, Trip trip) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetSheet(
        trip: trip,
        onSave: (updated) {
          app.updateTrip(updated);
          return true;
        },
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.budgetSavedMessage)),
    );
  }

  Future<void> _showExpenseSheet(
    AppState app,
    Trip selectedTrip, [
    Expense? expense,
  ]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseSheet(
        app: app,
        initialTripId: expense?.tripId ?? selectedTrip.id,
        existing: expense,
        onSave: (candidate) => expense == null
            ? app.addExpense(candidate)
            : app.updateExpense(candidate),
      ),
    );
    if (!mounted || saved != true) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          expense == null ? l10n.expenseAddedMessage : l10n.expenseSavedMessage,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(AppState app, Expense expense) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.expenseDeleteConfirmTitle),
        content: Text(l10n.expenseDeleteConfirmMessage(expense.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.expenseDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    app.deleteExpense(expense.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.expenseDeletedMessage)),
    );
  }
}

class _BudgetContent extends StatelessWidget {
  final AppState app;
  final Trip trip;
  final TripExpenseCategory? categoryFilter;
  final ValueChanged<int>? onTripChanged;
  final VoidCallback onSetBudget;
  final VoidCallback onAddExpense;
  final ValueChanged<Expense> onEditExpense;
  final ValueChanged<Expense> onDeleteExpense;
  final ValueChanged<TripExpenseCategory?> onCategoryFilter;

  const _BudgetContent({
    required this.app,
    required this.trip,
    required this.categoryFilter,
    required this.onTripChanged,
    required this.onSetBudget,
    required this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onCategoryFilter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = BudgetSnapshot.from(trip, app.expenses);
    final history = app.expensesForTrip(trip.id).where((expense) {
      if (categoryFilter == null) return true;
      return TripExpenseCategoryData.fromCode(expense.category) ==
          categoryFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.budgetHeading,
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(trip.title,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: l10n.expenseAddSemantic,
              child: IconButton.filled(
                tooltip: l10n.expenseAddSemantic,
                onPressed: onAddExpense,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
        if (onTripChanged != null && app.trips.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<int>(
            initialValue: trip.id,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.budgetTripSelectorLabel,
              prefixIcon: const Icon(Icons.map_rounded),
            ),
            items: app.trips
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.title, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onTripChanged?.call(value);
            },
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _BudgetOverviewCard(snapshot: snapshot, onSetBudget: onSetBudget),
        if (snapshot.mixedCurrencies) ...[
          const SizedBox(height: AppSpacing.md),
          OceanRecoverableErrorState(
            message: l10n.budgetMixedCurrencyWarning(snapshot.currency),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _CategoryTotals(snapshot: snapshot),
        const SizedBox(height: AppSpacing.lg),
        _ExpenseHistoryHeader(
          selected: categoryFilter,
          onSelected: onCategoryFilter,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (history.isEmpty)
          OceanEmptyState(
            title: snapshot.hasBudget
                ? l10n.budgetNoExpensesTitle
                : l10n.budgetMissingBudgetTitle,
            message: snapshot.hasBudget
                ? l10n.budgetNoExpensesMessage
                : l10n.budgetMissingBudgetMessage,
            actionLabel: l10n.expenseAddAction,
            onAction: onAddExpense,
          )
        else
          for (final expense in history)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ExpenseTile(
                expense: expense,
                onEdit: () => onEditExpense(expense),
                onDelete: () => onDeleteExpense(expense),
              ),
            ),
      ],
    );
  }
}

class _BudgetOverviewCard extends StatelessWidget {
  final BudgetSnapshot snapshot;
  final VoidCallback onSetBudget;

  const _BudgetOverviewCard({
    required this.snapshot,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progressLabel = snapshot.hasBudget
        ? l10n.budgetProgressSemantic(snapshot.progressPercent)
        : l10n.budgetProgressMissingSemantic;
    return OceanGlassCard(
      semanticLabel: l10n.budgetOverviewSemantic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.budgetTotalBudget,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: onSetBudget,
                icon: const Icon(Icons.edit_rounded),
                label: Text(l10n.budgetSetAction),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            snapshot.hasBudget
                ? formatMoney(context, snapshot.totalBudget, snapshot.currency)
                : l10n.budgetNotSet,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _BudgetMetric(
                label: l10n.budgetSpent,
                value: formatMoney(
                  context,
                  snapshot.totalSpent,
                  snapshot.currency,
                ),
                color: AppColors.ocean,
              ),
              _BudgetMetric(
                label:
                    snapshot.isOverBudget ? l10n.budgetOverBy : l10n.budgetLeft,
                value: formatMoney(
                  context,
                  snapshot.isOverBudget
                      ? snapshot.overBudgetAmount
                      : snapshot.remaining,
                  snapshot.currency,
                ),
                color: snapshot.isOverBudget
                    ? AppColors.danger
                    : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: progressLabel,
            child: LinearProgressIndicator(
              key: const Key('budget-progress'),
              value: snapshot.progressValue,
              minHeight: 10,
              backgroundColor: AppColors.mist,
              color: snapshot.isOverBudget ? AppColors.danger : AppColors.ocean,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            snapshot.hasBudget
                ? l10n.budgetProgressLabel(snapshot.progressPercent)
                : l10n.budgetMissingBudgetMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (snapshot.isOverBudget) ...[
            const SizedBox(height: AppSpacing.sm),
            OceanStatusPill(
              label: l10n.budgetOverMessage(
                formatMoney(
                  context,
                  snapshot.overBudgetAmount,
                  snapshot.currency,
                ),
              ),
              icon: Icons.warning_rounded,
              color: AppColors.danger,
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BudgetMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: OceanGlassSurface(
          blur: 0,
          color: color.withValues(alpha: .08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      );
}

class _CategoryTotals extends StatelessWidget {
  final BudgetSnapshot snapshot;

  const _CategoryTotals({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.budgetByCategoryTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final category in TripExpenseCategory.values)
                SizedBox(
                  width: 190,
                  child: _CategoryTotalTile(
                    category: category,
                    amount: snapshot.categoryTotals[category.code] ?? 0,
                    currency: snapshot.currency,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryTotalTile extends StatelessWidget {
  final TripExpenseCategory category;
  final double amount;
  final String currency;

  const _CategoryTotalTile({
    required this.category,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassSurface(
      blur: 0,
      color: category.color.withValues(alpha: .08),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: category.color.withValues(alpha: .12),
            child: Icon(category.icon, color: category.color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  formatMoney(context, amount, currency),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseHistoryHeader extends StatelessWidget {
  final TripExpenseCategory? selected;
  final ValueChanged<TripExpenseCategory?> onSelected;

  const _ExpenseHistoryHeader({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.budgetHistoryTitle,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(l10n.savedPlacesAllFilter),
                  selected: selected == null,
                  onSelected: (_) => onSelected(null),
                ),
              ),
              for (final category in TripExpenseCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    avatar: Icon(category.icon, size: AppIconSizes.xs),
                    label: Text(category.label(l10n)),
                    selected: selected == category,
                    onSelected: (_) => onSelected(category),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = TripExpenseCategoryData.fromCode(expense.category);
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return OceanGlassCard(
      semanticLabel: l10n.expenseTileSemantic(expense.title),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: category.color.withValues(alpha: .12),
            child: Icon(category.icon, color: category.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${date.format(expense.date)} · ${category.label(l10n)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatMoney(context, expense.amount, expense.currency),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          PopupMenuButton<String>(
            tooltip: l10n.expenseActionsSemantic(expense.title),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.expenseEditAction)),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  l10n.expenseDeleteAction,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetSheet extends StatefulWidget {
  final Trip trip;
  final bool Function(Trip trip) onSave;

  const _BudgetSheet({required this.trip, required this.onSave});

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late String _currency;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.trip.budget > 0 ? widget.trip.budget.toStringAsFixed(0) : '',
    );
    _notes = TextEditingController(text: widget.trip.budgetNotes);
    _currency = widget.trip.budgetCurrency.trim().isEmpty
        ? defaultBudgetCurrency
        : widget.trip.budgetCurrency;
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final amount = parseMoneyInput(_amount.text);
    if (amount == null || amount <= 0) {
      _show(l10n.expenseAmountInvalid);
      return;
    }
    setState(() => _submitting = true);
    final saved = widget.onSave(widget.trip.copyWith(
      budget: amount,
      budgetCurrency: _currency,
      budgetNotes: _notes.text.trim(),
    ));
    if (!mounted) return;
    if (!saved) {
      setState(() => _submitting = false);
      _show(l10n.budgetSaveFailed);
      return;
    }
    Navigator.pop(context, true);
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.budgetSetTitle,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('budget-amount-field'),
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.budgetAmountLabel,
                prefixIcon: const Icon(Icons.savings_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.expenseCurrencyLabel,
                prefixIcon: const Icon(Icons.payments_rounded),
              ),
              items: supportedBudgetCurrencies
                  .map(
                    (currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _currency = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notes,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.expenseNotesLabel,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OceanPrimaryButton(
              label: l10n.budgetSetAction,
              icon: Icons.check_rounded,
              onPressed: _submitting ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseSheet extends StatefulWidget {
  final AppState app;
  final int initialTripId;
  final Expense? existing;
  final bool Function(Expense expense) onSave;

  const _ExpenseSheet({
    required this.app,
    required this.initialTripId,
    required this.onSave,
    this.existing,
  });

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late int _tripId;
  late TripExpenseCategory _category;
  late String _currency;
  late DateTime _date;
  int? _tripDayId;
  int? _tripItemId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final initialTrip = _tripFor(existing?.tripId ?? widget.initialTripId) ??
        widget.app.trips.first;
    _tripId = initialTrip.id;
    _title = TextEditingController(text: existing?.title ?? '');
    _amount = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(0),
    );
    _notes = TextEditingController(text: existing?.notes ?? '');
    _category = existing == null
        ? TripExpenseCategory.food
        : TripExpenseCategoryData.fromCode(existing.category);
    _currency = existing?.currency ?? initialTrip.budgetCurrency;
    if (_currency.trim().isEmpty) _currency = defaultBudgetCurrency;
    _date = _clampDate(existing?.date ?? initialTrip.startDate, initialTrip);
    _tripDayId = existing?.tripDayId;
    _tripItemId = existing?.tripItemId;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trip = _tripFor(_tripId)!;
    final dayItems = _itemsForSelectedTrip();
    if (_tripItemId != null &&
        !dayItems.any((item) => item.id == _tripItemId)) {
      _tripItemId = null;
    }
    if (_tripDayId != null && (_tripDayId! < 1 || _tripDayId! > trip.days)) {
      _tripDayId = null;
    }

    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? l10n.expenseAddTitle
                  : l10n.expenseEditTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.plannerLocalOnlyMessage,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('expense-title-field'),
              controller: _title,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.expenseTitleLabel,
                prefixIcon: const Icon(Icons.receipt_long_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('expense-amount-field'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.expenseAmountLabel,
                prefixIcon: const Icon(Icons.payments_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              key: const Key('expense-currency-field'),
              initialValue: _currency,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.expenseCurrencyLabel,
                prefixIcon: const Icon(Icons.currency_exchange_rounded),
              ),
              items: supportedBudgetCurrencies
                  .map(
                    (currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _currency = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _CategoryPicker(
              selected: _category,
              onSelected: (category) => setState(() => _category = category),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              key: const Key('expense-trip-field'),
              initialValue: _tripId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.budgetTripSelectorLabel,
                prefixIcon: const Icon(Icons.map_rounded),
              ),
              items: widget.app.trips
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.title, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _tripId = value;
                  final newTrip = _tripFor(value)!;
                  _date = _clampDate(_date, newTrip);
                  _tripDayId = null;
                  _tripItemId = null;
                  if (_currency.trim().isEmpty) {
                    _currency = newTrip.budgetCurrency;
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _DateButton(
              label: l10n.expenseDateLabel,
              value:
                  DateFormat.yMMMd(Localizations.localeOf(context).toString())
                      .format(_date),
              onTap: () => _pickDate(trip),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int?>(
              key: const Key('expense-day-field'),
              initialValue: _tripDayId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.expenseLinkedDayLabel,
                prefixIcon: const Icon(Icons.calendar_month_rounded),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.expenseNoLinkedDay),
                ),
                for (var day = 1; day <= trip.days; day++)
                  DropdownMenuItem<int?>(
                    value: day,
                    child: Text(l10n.tripOverviewDayLabel(day)),
                  ),
              ],
              onChanged: (value) => setState(() {
                _tripDayId = value;
                _tripItemId = null;
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int?>(
              key: const Key('expense-item-field'),
              initialValue: _tripItemId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.expenseLinkedItemLabel,
                prefixIcon: const Icon(Icons.link_rounded),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.expenseNoLinkedItem),
                ),
                for (final item in dayItems)
                  DropdownMenuItem<int?>(
                    value: item.id,
                    child: Text(item.title, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _tripItemId = value),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notes,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.expenseNotesLabel,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OceanPrimaryButton(
              key: const Key('expense-submit'),
              label: widget.existing == null
                  ? l10n.expenseAddAction
                  : l10n.expenseSaveAction,
              icon: Icons.check_rounded,
              semanticLabel: widget.existing == null
                  ? l10n.expenseAddSemantic
                  : l10n.expenseSaveSemantic,
              onPressed: _submitting ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Trip? _tripFor(int id) {
    try {
      return widget.app.trips.firstWhere((trip) => trip.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TimelineItem> _itemsForSelectedTrip() {
    final items = widget.app.timeline
        .where((item) =>
            item.tripId == _tripId &&
            (_tripDayId == null || item.dayNumber == _tripDayId))
        .toList();
    items.sort((a, b) {
      final day = a.dayNumber.compareTo(b.dayNumber);
      if (day != 0) return day;
      return a.id.compareTo(b.id);
    });
    return items;
  }

  Future<void> _pickDate(Trip trip) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _clampDate(_date, trip),
      firstDate: _dateOnly(trip.startDate),
      lastDate: _dateOnly(trip.endDate),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _save() {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final trip = _tripFor(_tripId);
    if (trip == null) {
      _show(l10n.expenseTripRequired);
      return;
    }
    final title = _title.text.trim();
    if (title.isEmpty) {
      _show(l10n.expenseTitleRequired);
      return;
    }
    final amount = parseMoneyInput(_amount.text);
    if (amount == null || amount <= 0) {
      _show(l10n.expenseAmountInvalid);
      return;
    }
    if (!_dateIsInsideTrip(_date, trip)) {
      _show(l10n.expenseDateOutOfRange);
      return;
    }
    if (_tripDayId != null && (_tripDayId! < 1 || _tripDayId! > trip.days)) {
      _show(l10n.expenseLinkedDayInvalid);
      return;
    }
    if (_tripItemId != null &&
        !widget.app.timeline
            .any((item) => item.id == _tripItemId && item.tripId == trip.id)) {
      _show(l10n.expenseLinkedItemInvalid);
      return;
    }

    setState(() => _submitting = true);
    final existing = widget.existing;
    final expense = existing == null
        ? Expense(
            id: widget.app.newId,
            tripId: trip.id,
            title: title,
            category: _category.code,
            amount: amount,
            currency: _currency,
            date: _dateOnly(_date),
            tripDayId: _tripDayId,
            tripItemId: _tripItemId,
            notes: _notes.text.trim(),
          )
        : existing.copyWith(
            tripId: trip.id,
            title: title,
            category: _category.code,
            amount: amount,
            currency: _currency,
            date: _dateOnly(_date),
            tripDayId: _tripDayId,
            tripItemId: _tripItemId,
            notes: _notes.text.trim(),
          );
    final saved = widget.onSave(expense);
    if (!mounted) return;
    if (!saved) {
      setState(() => _submitting = false);
      _show(l10n.expenseSaveFailed);
      return;
    }
    Navigator.pop(context, true);
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  DateTime _clampDate(DateTime value, Trip trip) {
    final date = _dateOnly(value);
    final start = _dateOnly(trip.startDate);
    final end = _dateOnly(trip.endDate);
    if (date.isBefore(start)) return start;
    if (date.isAfter(end)) return end;
    return date;
  }

  bool _dateIsInsideTrip(DateTime value, Trip trip) {
    final date = _dateOnly(value);
    final start = _dateOnly(trip.startDate);
    final end = _dateOnly(trip.endDate);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _CategoryPicker extends StatelessWidget {
  final TripExpenseCategory selected;
  final ValueChanged<TripExpenseCategory> onSelected;

  const _CategoryPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.expenseCategoryLabel,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in TripExpenseCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    key: Key('expense-category-${category.code}'),
                    avatar: Icon(category.icon, size: AppIconSizes.xs),
                    label: Text(category.label(l10n)),
                    selected: selected == category,
                    onSelected: (_) => onSelected(category),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.calendar_month_rounded),
            ),
            child: Text(value),
          ),
        ),
      );
}

double? parseMoneyInput(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  final lower = value.toLowerCase();
  if (lower == 'nan' || lower == 'infinity' || lower == '-infinity') {
    return null;
  }
  var normalized = value.replaceAll(RegExp(r'\s'), '');
  normalized =
      normalized.replaceAllMapped(RegExp(r'[,.](?=\d{3}([,.]|$))'), (_) => '');
  normalized = normalized.replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(normalized)) return null;
  final parsed = double.tryParse(normalized);
  if (parsed == null || !parsed.isFinite || parsed <= 0) return null;
  return parsed;
}

String formatMoney(BuildContext context, double amount, String currency) {
  final locale = Localizations.localeOf(context).toString();
  final format = NumberFormat.currency(
    locale: locale == 'vi' ? 'vi_VN' : locale,
    name: currency,
    symbol: currency == 'VND' ? '₫' : currency,
    decimalDigits: currency == 'VND' ? 0 : 2,
  );
  return format.format(amount);
}
