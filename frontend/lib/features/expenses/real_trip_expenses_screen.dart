import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';

/// UI40 — Real Mode trip expense management
/// (`/api/me/trips/{tripId}/expenses`, Phase 7 Trip Budget & Expenses). Lists a
/// real trip's expenses with a server-computed spending summary, and supports
/// create / edit / delete (owner or EDITOR collaborator). All amounts/totals are
/// backend-owned; nothing is computed client-side.
class RealTripExpensesScreen extends StatefulWidget {
  final int tripId;
  final String? tripTitle;

  const RealTripExpensesScreen({
    super.key,
    required this.tripId,
    this.tripTitle,
  });

  @override
  State<RealTripExpensesScreen> createState() => _RealTripExpensesScreenState();
}

class _RealTripExpensesScreenState extends State<RealTripExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealExpenses(widget.tripId);
    });
  }

  void _reauth() {
    showOceanSessionExpiredSheet(
      context,
      onLogin: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      onReturnHome: () => Navigator.of(context).pop(),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageForOutcome(AppLocalizations l10n, ExpenseOutcome o) {
    return switch (o) {
      ExpenseOutcome.forbidden => l10n.expensesForbiddenMessage,
      ExpenseOutcome.notFound => l10n.expensesGoneMessage,
      ExpenseOutcome.validation => l10n.expensesInvalidMessage,
      ExpenseOutcome.network => l10n.expensesNetworkMessage,
      _ => l10n.expensesActionErrorMessage,
    };
  }

  Future<void> _openForm(AppState app, RealExpense? existing) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await showModalBottomSheet<ExpenseOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExpenseFormSheet(
        tripId: widget.tripId,
        existing: existing,
      ),
    );
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case ExpenseOutcome.success:
        _snack(existing == null
            ? l10n.expensesCreatedMessage
            : l10n.expensesUpdatedMessage);
      case ExpenseOutcome.sessionExpired:
        _reauth();
      case ExpenseOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _delete(AppState app, RealExpense expense) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.expensesDeleteConfirmTitle),
        content: Text(l10n.expensesDeleteConfirmMessage(expense.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('expense-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.expensesDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.deleteRealExpense(widget.tripId, expense.id);
    if (!mounted) return;
    switch (outcome) {
      case ExpenseOutcome.success:
        _snack(l10n.expensesDeletedMessage);
      case ExpenseOutcome.sessionExpired:
        _reauth();
      case ExpenseOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(widget.tripTitle?.trim().isNotEmpty == true
            ? widget.tripTitle!.trim()
            : l10n.expensesTitle),
        actions: [
          if (app.realExpensesLoaded)
            IconButton(
              key: const Key('expenses-add'),
              tooltip: l10n.expensesAddSemantic,
              onPressed: app.realExpenseMutationInFlight
                  ? null
                  : () => _openForm(app, null),
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    if (app.realExpensesError == ExpenseOutcome.sessionExpired &&
        !app.realExpensesLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('expenses-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realExpensesLoading && !app.realExpensesLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.expensesLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('expenses-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.expensesLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realExpensesError != null && !app.realExpensesLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('expenses-error'),
          message: app.realExpensesError == ExpenseOutcome.notFound
              ? l10n.expensesGoneMessage
              : app.realExpensesError == ExpenseOutcome.forbidden
                  ? l10n.expensesForbiddenMessage
                  : l10n.expensesErrorMessage,
          onReload: () => app.loadRealExpenses(widget.tripId, refresh: true),
        ),
      );
    }
    final expenses = app.realExpensesFor(widget.tripId);
    final summary = app.realExpenseSummaryFor(widget.tripId);
    final locale = Localizations.localeOf(context).toString();
    return RefreshIndicator(
      onRefresh: () => app.loadRealExpenses(widget.tripId, refresh: true),
      child: ListView(
        key: const Key('expenses-content'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (summary != null) ...[
                  _SummaryCard(summary: summary, locale: locale),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (expenses.isEmpty)
                  OceanEmptyState(
                    key: const Key('expenses-empty'),
                    title: l10n.expensesEmptyTitle,
                    message: l10n.expensesEmptyMessage,
                    actionLabel: l10n.expensesAddAction,
                    onAction: app.realExpenseMutationInFlight
                        ? null
                        : () => _openForm(app, null),
                  )
                else
                  for (final e in expenses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ExpenseCard(
                        expense: e,
                        locale: locale,
                        onEdit: () => _openForm(app, e),
                        onDelete: () => _delete(app, e),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _centered(Widget child) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Center(child: child),
          ),
        ],
      );
}

// ── Category presentation (text + icon + colour, never colour-only) ───────────

String expenseCategoryLabel(AppLocalizations l10n, RealExpenseCategory c) {
  return switch (c) {
    RealExpenseCategory.accommodation => l10n.expenseCategoryAccommodation,
    RealExpenseCategory.food => l10n.expenseCategoryFood,
    RealExpenseCategory.transport => l10n.expenseCategoryTransport,
    RealExpenseCategory.attraction => l10n.expenseCategoryAttraction,
    RealExpenseCategory.shopping => l10n.expenseCategoryShopping,
    RealExpenseCategory.health => l10n.expenseCategoryHealth,
    RealExpenseCategory.visa => l10n.expenseCategoryVisa,
    RealExpenseCategory.insurance => l10n.expenseCategoryInsurance,
    RealExpenseCategory.other => l10n.expenseCategoryOther,
    RealExpenseCategory.unknown => l10n.expenseCategoryOther,
  };
}

IconData expenseCategoryIcon(RealExpenseCategory c) {
  return switch (c) {
    RealExpenseCategory.accommodation => Icons.hotel_rounded,
    RealExpenseCategory.food => Icons.restaurant_rounded,
    RealExpenseCategory.transport => Icons.directions_bus_rounded,
    RealExpenseCategory.attraction => Icons.attractions_rounded,
    RealExpenseCategory.shopping => Icons.shopping_bag_rounded,
    RealExpenseCategory.health => Icons.local_hospital_rounded,
    RealExpenseCategory.visa => Icons.badge_rounded,
    RealExpenseCategory.insurance => Icons.shield_rounded,
    RealExpenseCategory.other => Icons.category_rounded,
    RealExpenseCategory.unknown => Icons.help_outline_rounded,
  };
}

Color expenseCategoryColor(RealExpenseCategory c) {
  return switch (c) {
    RealExpenseCategory.accommodation => AppColors.turquoise600,
    RealExpenseCategory.food => AppColors.warning,
    RealExpenseCategory.transport => AppColors.ocean,
    RealExpenseCategory.attraction => AppColors.success,
    RealExpenseCategory.shopping => AppColors.ocean,
    RealExpenseCategory.health => AppColors.danger,
    RealExpenseCategory.visa => AppColors.slate,
    RealExpenseCategory.insurance => AppColors.slate,
    RealExpenseCategory.other => AppColors.slate,
    RealExpenseCategory.unknown => AppColors.slate,
  };
}

String expenseMoney(String locale, double amount, String currency) {
  final fmt = NumberFormat('#,##0.##', locale);
  return '${fmt.format(amount)} $currency';
}

class _SummaryCard extends StatelessWidget {
  final RealExpenseSummary summary;
  final String locale;

  const _SummaryCard({required this.summary, required this.locale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      key: const Key('expenses-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.expensesSummarySpent,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            NumberFormat('#,##0.##', locale).format(summary.totalSpent),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (summary.hasBudget)
                OceanStatusPill(
                  label: l10n.expensesSummaryBudget(
                    NumberFormat('#,##0.##', locale)
                        .format(summary.totalBudget),
                  ),
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.ocean,
                ),
              if (summary.hasBudget && !summary.overBudget)
                OceanStatusPill(
                  label: l10n.expensesSummaryRemaining(
                    NumberFormat('#,##0.##', locale)
                        .format(summary.remainingBudget),
                  ),
                  icon: Icons.savings_rounded,
                  color: AppColors.success,
                ),
              if (summary.hasBudget && summary.overBudget)
                OceanStatusPill(
                  label: l10n.expensesSummaryOverBudget,
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final RealExpense expense;
  final String locale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.locale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cat = expense.categoryView;
    final date = expense.expenseDate != null
        ? DateFormat.yMMMd(locale).format(expense.expenseDate!.toLocal())
        : null;
    return OceanGlassCard(
      key: Key('expense-card-${expense.id}'),
      onTap: onEdit,
      semanticLabel: l10n.expenseCardSemantic(expense.title),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        expense.title.trim().isEmpty
                            ? l10n.expenseUntitled
                            : expense.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      expenseMoney(locale, expense.amount, expense.currency),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if ((expense.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    expense.notes!.trim(),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OceanStatusPill(
                      label: expenseCategoryLabel(l10n, cat),
                      icon: expenseCategoryIcon(cat),
                      color: expenseCategoryColor(cat),
                    ),
                    if (date != null)
                      OceanStatusPill(
                        label: date,
                        icon: Icons.event_rounded,
                        color: AppColors.turquoise600,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('expense-delete-${expense.id}'),
            tooltip: l10n.expensesDeleteSemantic(expense.title),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _ExpenseFormSheet extends StatefulWidget {
  final int tripId;
  final RealExpense? existing;

  const _ExpenseFormSheet({required this.tripId, this.existing});

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _currency;
  late final TextEditingController _notes;
  late RealExpenseCategory _category;
  late DateTime _date;
  bool _amountError = false;
  bool _titleError = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _amount = TextEditingController(
      text: e != null ? _trimZeros(e.amount) : '',
    );
    _currency = TextEditingController(text: e?.currency ?? 'VND');
    _notes = TextEditingController(text: e?.notes ?? '');
    final cat = e?.categoryView;
    _category = (cat == null || cat == RealExpenseCategory.unknown)
        ? RealExpenseCategory.food
        : cat;
    _date = e?.expenseDate ?? DateTime.now();
  }

  static String _trimZeros(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _currency.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final app = AppScope.of(context);
    final title = _title.text.trim();
    final amount = double.tryParse(_amount.text.trim());
    final currency = _currency.text.trim();
    setState(() {
      _titleError = title.isEmpty;
      _amountError = amount == null || amount < 0;
    });
    if (title.isEmpty || amount == null || amount < 0 || currency.isEmpty) {
      return;
    }
    final payload = RealExpensePayload(
      category: _category,
      amount: amount,
      currency: currency,
      title: title,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      expenseDate: _date,
    );
    final existing = widget.existing;
    final outcome = existing == null
        ? await app.createRealExpense(widget.tripId, payload)
        : await app.updateRealExpense(widget.tripId, existing.id, payload);
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final saving = app.realExpenseMutationInFlight;
    final isEdit = widget.existing != null;
    return SafeArea(
      child: Padding(
        key: const Key('expense-form-content'),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? l10n.expensesEditTitle : l10n.expensesAddTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              GlassTextField(
                key: const Key('expense-field-title'),
                controller: _title,
                hint: l10n.expenseFieldTitle,
                icon: Icons.title_rounded,
              ),
              if (_titleError) _fieldError(context, l10n.expenseTitleRequired),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GlassTextField(
                      key: const Key('expense-field-amount'),
                      controller: _amount,
                      hint: l10n.expenseFieldAmount,
                      icon: Icons.payments_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GlassTextField(
                      key: const Key('expense-field-currency'),
                      controller: _currency,
                      hint: l10n.expenseFieldCurrency,
                      icon: Icons.attach_money_rounded,
                    ),
                  ),
                ],
              ),
              if (_amountError) _fieldError(context, l10n.expenseAmountInvalid),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<RealExpenseCategory>(
                key: const Key('expense-field-category'),
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: l10n.expenseFieldCategory,
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
                items: [
                  for (final c in realExpenseCategoryChoices)
                    DropdownMenuItem(
                      value: c,
                      child: Text(expenseCategoryLabel(l10n, c)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                key: const Key('expense-field-date'),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.expenseFieldDate,
                    prefixIcon: const Icon(Icons.event_rounded),
                  ),
                  child: Text(DateFormat.yMMMd(locale).format(_date)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              GlassTextField(
                key: const Key('expense-field-notes'),
                controller: _notes,
                hint: l10n.expenseFieldNotes,
                icon: Icons.notes_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              OceanPrimaryButton(
                key: const Key('expense-form-save'),
                label:
                    isEdit ? l10n.expensesSaveAction : l10n.expensesAddAction,
                icon: Icons.check_rounded,
                onPressed: saving ? null : _submit,
                semanticLabel:
                    isEdit ? l10n.expensesSaveAction : l10n.expensesAddAction,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldError(BuildContext context, String message) => Padding(
        padding:
            const EdgeInsets.only(top: AppSpacing.xxs, left: AppSpacing.sm),
        child: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.danger),
        ),
      );
}
