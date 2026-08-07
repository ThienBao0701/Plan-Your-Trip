import 'dart:math' as math;

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

/// UI47 — Real Mode trip budget (`/api/me/trips/{tripId}/budget`, Phase 7 Trip
/// Budget & Expenses). Shows the per-trip total budget with the server-computed
/// spent / remaining / over-budget summary (reused from UI-40's budget-summary),
/// and supports set / edit / delete of the budget (owner only). All totals are
/// backend-owned; only the progress ratio is derived for display.
class RealTripBudgetScreen extends StatefulWidget {
  final int tripId;
  final String? tripTitle;

  const RealTripBudgetScreen({
    super.key,
    required this.tripId,
    this.tripTitle,
  });

  @override
  State<RealTripBudgetScreen> createState() => _RealTripBudgetScreenState();
}

class _RealTripBudgetScreenState extends State<RealTripBudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealBudget(widget.tripId);
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

  String _messageForOutcome(AppLocalizations l10n, BudgetOutcome o) {
    return switch (o) {
      BudgetOutcome.forbidden => l10n.budgetRealForbiddenMessage,
      BudgetOutcome.notFound => l10n.budgetRealGoneMessage,
      BudgetOutcome.validation => l10n.budgetRealAmountInvalidMessage,
      BudgetOutcome.network => l10n.budgetRealNetworkMessage,
      _ => l10n.budgetRealActionErrorMessage,
    };
  }

  Future<void> _openForm(AppState app, RealBudget? existing) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await showModalBottomSheet<BudgetOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BudgetFormSheet(
        tripId: widget.tripId,
        existing: existing,
      ),
    );
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case BudgetOutcome.success:
        _snack(l10n.budgetRealSavedMessage);
      case BudgetOutcome.sessionExpired:
        _reauth();
      case BudgetOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _delete(AppState app) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.budgetRealDeleteConfirmTitle),
        content: Text(l10n.budgetRealDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('budget-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.budgetRealDeleteAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.deleteRealBudget(widget.tripId);
    if (!mounted) return;
    switch (outcome) {
      case BudgetOutcome.success:
        _snack(l10n.budgetRealDeletedMessage);
      case BudgetOutcome.sessionExpired:
        _reauth();
      case BudgetOutcome.busy:
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
            : l10n.budgetRealTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    if (app.realBudgetError == BudgetOutcome.sessionExpired &&
        !app.realBudgetLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('budget-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realBudgetLoading && !app.realBudgetLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.budgetRealLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('budget-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.budgetRealLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realBudgetError != null && !app.realBudgetLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('budget-error'),
          message: app.realBudgetError == BudgetOutcome.notFound
              ? l10n.budgetRealGoneMessage
              : app.realBudgetError == BudgetOutcome.forbidden
                  ? l10n.budgetRealForbiddenMessage
                  : l10n.budgetRealErrorMessage,
          onReload: () => app.loadRealBudget(widget.tripId, refresh: true),
        ),
      );
    }
    final budget = app.realBudgetFor(widget.tripId);
    final summary = app.realBudgetSummaryFor(widget.tripId);
    final locale = Localizations.localeOf(context).toString();
    return RefreshIndicator(
      onRefresh: () => app.loadRealBudget(widget.tripId, refresh: true),
      child: ListView(
        key: const Key('budget-content'),
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
                if (budget == null)
                  OceanEmptyState(
                    key: const Key('budget-empty'),
                    title: l10n.budgetRealEmptyTitle,
                    message: l10n.budgetRealEmptyMessage,
                    actionLabel: l10n.budgetSetAction,
                    onAction: app.realBudgetMutationInFlight
                        ? null
                        : () => _openForm(app, null),
                  )
                else
                  _BudgetCard(
                    budget: budget,
                    summary: summary,
                    locale: locale,
                    busy: app.realBudgetMutationInFlight,
                    onEdit: () => _openForm(app, budget),
                    onDelete: () => _delete(app),
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

String budgetMoney(String locale, double amount, String currency) {
  final fmt = NumberFormat('#,##0.##', locale);
  final trimmed = currency.trim();
  return trimmed.isEmpty
      ? fmt.format(amount)
      : '${fmt.format(amount)} $trimmed';
}

class _BudgetCard extends StatelessWidget {
  final RealBudget budget;
  final RealExpenseSummary? summary;
  final String locale;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.budget,
    required this.summary,
    required this.locale,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = budget.currency;
    final total = budget.totalBudget;
    final spent = summary?.totalSpent ?? 0;
    final remaining = summary?.remainingBudget ?? total;
    final overBudget = summary?.overBudget ?? false;
    // Display-only progress ratio (server owns the authoritative totals/flags).
    final ratio = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final percent =
        total > 0 ? math.min(100, (spent / total * 100).round()) : 0;
    return OceanGlassCard(
      key: const Key('budget-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetTotalBudget,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            budgetMoney(locale, total, currency),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            label: l10n.budgetProgressSemantic(percent),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                key: const Key('budget-progress'),
                value: ratio,
                minHeight: 10,
                backgroundColor: AppColors.paleCyan,
                valueColor: AlwaysStoppedAnimation<Color>(
                  overBudget ? AppColors.danger : AppColors.success,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.budgetProgressLabel(percent),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: '${l10n.budgetSpent}: '
                    '${budgetMoney(locale, spent, currency)}',
                icon: Icons.payments_rounded,
                color: AppColors.ocean,
              ),
              if (!overBudget)
                OceanStatusPill(
                  label: '${l10n.budgetLeft}: '
                      '${budgetMoney(locale, remaining, currency)}',
                  icon: Icons.savings_rounded,
                  color: AppColors.success,
                )
              else
                OceanStatusPill(
                  label: l10n.expensesSummaryOverBudget,
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                ),
            ],
          ),
          if ((budget.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              budget.notes!.trim(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OceanSecondaryButton(
                key: const Key('budget-edit'),
                label: l10n.budgetRealEditAction,
                icon: Icons.edit_rounded,
                fullWidth: false,
                onPressed: busy ? null : onEdit,
                semanticLabel: l10n.budgetRealEditAction,
              ),
              OceanSecondaryButton(
                key: const Key('budget-delete'),
                label: l10n.budgetRealDeleteAction,
                icon: Icons.delete_outline_rounded,
                fullWidth: false,
                onPressed: busy ? null : onDelete,
                semanticLabel: l10n.budgetRealDeleteAction,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetFormSheet extends StatefulWidget {
  final int tripId;
  final RealBudget? existing;

  const _BudgetFormSheet({required this.tripId, this.existing});

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _currency;
  late final TextEditingController _notes;
  bool _amountError = false;
  bool _currencyError = false;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _amount = TextEditingController(
      text: b != null ? _trimZeros(b.totalBudget) : '',
    );
    _currency = TextEditingController(
      text: (b?.currency.trim().isNotEmpty ?? false) ? b!.currency : 'VND',
    );
    _notes = TextEditingController(text: b?.notes ?? '');
  }

  static String _trimZeros(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  @override
  void dispose() {
    _amount.dispose();
    _currency.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = AppScope.of(context);
    final amount = double.tryParse(_amount.text.trim());
    final currency = _currency.text.trim();
    setState(() {
      _amountError = amount == null || amount < 0;
      _currencyError = currency.isEmpty;
    });
    if (amount == null || amount < 0 || currency.isEmpty) return;
    final payload = RealBudgetPayload(
      totalBudget: amount,
      currency: currency,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    final outcome = await app.saveRealBudget(widget.tripId, payload);
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final saving = app.realBudgetMutationInFlight;
    final isEdit = widget.existing != null;
    return SafeArea(
      child: Padding(
        key: const Key('budget-form-content'),
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
                isEdit ? l10n.budgetRealEditTitle : l10n.budgetRealSetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GlassTextField(
                      key: const Key('budget-field-amount'),
                      controller: _amount,
                      hint: l10n.budgetAmountLabel,
                      icon: Icons.account_balance_wallet_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GlassTextField(
                      key: const Key('budget-field-currency'),
                      controller: _currency,
                      hint: l10n.expenseFieldCurrency,
                      icon: Icons.attach_money_rounded,
                    ),
                  ),
                ],
              ),
              if (_amountError)
                _fieldError(context, l10n.budgetRealAmountInvalidMessage),
              if (_currencyError)
                _fieldError(context, l10n.budgetRealCurrencyRequiredMessage),
              const SizedBox(height: AppSpacing.sm),
              GlassTextField(
                key: const Key('budget-field-notes'),
                controller: _notes,
                hint: l10n.expenseFieldNotes,
                icon: Icons.notes_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              OceanPrimaryButton(
                key: const Key('budget-form-save'),
                label: l10n.budgetRealSaveAction,
                icon: Icons.check_rounded,
                onPressed: saving ? null : _submit,
                semanticLabel: l10n.budgetRealSaveAction,
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
