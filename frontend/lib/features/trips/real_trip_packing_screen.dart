import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'trip_companion_screen.dart' show packingCategoryLabel;

/// UI45 — Real Mode packing checklist (`/api/me/trips/{tripId}/packing`). Lists a
/// real trip's packing items (unchecked first), and supports add / edit / delete
/// and check / uncheck (owner or EDITOR collaborator). Progress is a simple count
/// of the backend-provided `checked` flags; all data comes from the backend.
class RealTripPackingScreen extends StatefulWidget {
  final int tripId;
  final String? tripTitle;

  const RealTripPackingScreen({
    super.key,
    required this.tripId,
    this.tripTitle,
  });

  @override
  State<RealTripPackingScreen> createState() => _RealTripPackingScreenState();
}

class _RealTripPackingScreenState extends State<RealTripPackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealPacking(widget.tripId);
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

  String _messageForOutcome(AppLocalizations l10n, PackingOutcome o) {
    return switch (o) {
      PackingOutcome.forbidden => l10n.packingRealForbiddenMessage,
      PackingOutcome.notFound => l10n.packingRealGoneMessage,
      PackingOutcome.validation => l10n.packingRealLabelRequiredMessage,
      PackingOutcome.network => l10n.packingRealNetworkMessage,
      _ => l10n.packingRealActionErrorMessage,
    };
  }

  Future<void> _openForm(AppState app, RealPackingItem? existing) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await showModalBottomSheet<PackingOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PackingFormSheet(
        tripId: widget.tripId,
        existing: existing,
      ),
    );
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case PackingOutcome.success:
        _snack(existing == null
            ? l10n.packingRealCreatedMessage
            : l10n.packingRealUpdatedMessage);
      case PackingOutcome.sessionExpired:
        _reauth();
      case PackingOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _toggleChecked(AppState app, RealPackingItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await app.setRealPackingItemChecked(
      widget.tripId,
      item.id,
      !item.checked,
    );
    if (!mounted) return;
    switch (outcome) {
      case PackingOutcome.success:
      case PackingOutcome.busy:
        break;
      case PackingOutcome.sessionExpired:
        _reauth();
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _delete(AppState app, RealPackingItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.packingDeleteConfirmTitle),
        content: Text(l10n.packingRealDeleteConfirmMessage(item.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('packing-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.packingDeleteAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.deleteRealPackingItem(widget.tripId, item.id);
    if (!mounted) return;
    switch (outcome) {
      case PackingOutcome.success:
        _snack(l10n.packingRealDeletedMessage);
      case PackingOutcome.sessionExpired:
        _reauth();
      case PackingOutcome.busy:
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
            : l10n.packingRealTitle),
        actions: [
          if (app.realPackingLoaded)
            IconButton(
              key: const Key('packing-add'),
              tooltip: l10n.packingRealAddSemantic,
              onPressed: app.realPackingMutationInFlight
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
    if (app.realPackingError == PackingOutcome.sessionExpired &&
        !app.realPackingLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('packing-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realPackingLoading && !app.realPackingLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.packingRealLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('packing-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.packingRealLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realPackingError != null && !app.realPackingLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('packing-error'),
          message: app.realPackingError == PackingOutcome.notFound
              ? l10n.packingRealGoneMessage
              : app.realPackingError == PackingOutcome.forbidden
                  ? l10n.packingRealForbiddenMessage
                  : l10n.packingRealErrorMessage,
          onReload: () => app.loadRealPacking(widget.tripId, refresh: true),
        ),
      );
    }
    final items = app.realPackingItemsFor(widget.tripId);
    final checked = items.where((i) => i.checked).length;
    return RefreshIndicator(
      onRefresh: () => app.loadRealPacking(widget.tripId, refresh: true),
      child: ListView(
        key: const Key('packing-content'),
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
                if (items.isNotEmpty) ...[
                  OceanGlassCard(
                    key: const Key('packing-progress'),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.packingProgressValue(
                          checked,
                          items.length,
                          items.isEmpty
                              ? 0
                              : ((checked * 100) / items.length).round(),
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (items.isEmpty)
                  OceanEmptyState(
                    key: const Key('packing-empty'),
                    title: l10n.packingRealEmptyTitle,
                    message: l10n.packingRealEmptyMessage,
                    actionLabel: l10n.packingAddAction,
                    onAction: app.realPackingMutationInFlight
                        ? null
                        : () => _openForm(app, null),
                  )
                else
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _PackingCard(
                        item: item,
                        onToggle: () => _toggleChecked(app, item),
                        onEdit: () => _openForm(app, item),
                        onDelete: () => _delete(app, item),
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

String realPackingCategoryLabel(AppLocalizations l10n, RealPackingItem item) {
  final view = item.categoryView;
  if (view != null) return packingCategoryLabel(l10n, view);
  return item.category.trim().isEmpty
      ? l10n.packingCategoryLabel
      : item.category;
}

class _PackingCard extends StatelessWidget {
  final RealPackingItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PackingCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          decoration: item.checked ? TextDecoration.lineThrough : null,
          color: item.checked ? AppColors.textSecondary : null,
        );
    return OceanGlassCard(
      key: Key('packing-card-${item.id}'),
      onTap: onEdit,
      semanticLabel: item.label,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            checked: item.checked,
            label: item.checked
                ? l10n.packingRealUncheckSemantic(item.label)
                : l10n.packingRealCheckSemantic(item.label),
            child: Checkbox(
              key: Key('packing-check-${item.id}'),
              value: item.checked,
              onChanged: (_) => onToggle(),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label.trim().isEmpty
                            ? realPackingCategoryLabel(l10n, item)
                            : item.label,
                        style: labelStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.quantity > 1) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '×${item.quantity}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                if ((item.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.notes!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OceanStatusPill(
                      label: realPackingCategoryLabel(l10n, item),
                      icon: Icons.category_rounded,
                    ),
                    if ((item.assignedToUserName ?? '').trim().isNotEmpty)
                      OceanStatusPill(
                        label: item.assignedToUserName!.trim(),
                        icon: Icons.person_rounded,
                        color: AppColors.turquoise600,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('packing-delete-${item.id}'),
            tooltip: l10n.packingDeleteAction,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _PackingFormSheet extends StatefulWidget {
  final int tripId;
  final RealPackingItem? existing;

  const _PackingFormSheet({required this.tripId, this.existing});

  @override
  State<_PackingFormSheet> createState() => _PackingFormSheetState();
}

class _PackingFormSheetState extends State<_PackingFormSheet> {
  late final TextEditingController _label;
  late final TextEditingController _quantity;
  late final TextEditingController _notes;
  late PackingCategory _category;
  bool _labelError = false;
  bool _quantityError = false;

  @override
  void initState() {
    super.initState();
    final i = widget.existing;
    _label = TextEditingController(text: i?.label ?? '');
    _quantity = TextEditingController(text: '${i?.quantity ?? 1}');
    _notes = TextEditingController(text: i?.notes ?? '');
    _category = i?.categoryView ?? PackingCategory.other;
  }

  @override
  void dispose() {
    _label.dispose();
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = AppScope.of(context);
    final label = _label.text.trim();
    final quantity = int.tryParse(_quantity.text.trim());
    setState(() {
      _labelError = label.isEmpty;
      _quantityError = quantity == null || quantity < 1;
    });
    if (label.isEmpty || quantity == null || quantity < 1) return;
    final payload = RealPackingItemPayload(
      label: label,
      category: _category,
      quantity: quantity,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    final existing = widget.existing;
    final outcome = existing == null
        ? await app.createRealPackingItem(widget.tripId, payload)
        : await app.updateRealPackingItem(widget.tripId, existing.id, payload);
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final saving = app.realPackingMutationInFlight;
    final isEdit = widget.existing != null;
    return SafeArea(
      child: Padding(
        key: const Key('packing-form-content'),
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
                isEdit
                    ? l10n.packingRealEditTitle
                    : l10n.packingRealCreateTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('packing-field-label'),
                controller: _label,
                decoration: InputDecoration(
                  labelText: l10n.packingLabelField,
                  errorText:
                      _labelError ? l10n.packingRealLabelRequiredMessage : null,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<PackingCategory>(
                      key: const Key('packing-field-category'),
                      initialValue: _category,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.packingCategoryLabel,
                      ),
                      items: [
                        for (final c in PackingCategory.values)
                          DropdownMenuItem(
                            value: c,
                            child: Text(packingCategoryLabel(l10n, c)),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      key: const Key('packing-field-quantity'),
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.packingQuantityField,
                        errorText: _quantityError
                            ? l10n.packingRealQuantityInvalidMessage
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('packing-field-notes'),
                controller: _notes,
                decoration: InputDecoration(labelText: l10n.packingNotesField),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              OceanPrimaryButton(
                key: const Key('packing-form-save'),
                label: isEdit ? l10n.packingEditAction : l10n.packingAddAction,
                icon: Icons.check_rounded,
                onPressed: saving ? null : _submit,
                semanticLabel:
                    isEdit ? l10n.packingEditAction : l10n.packingAddAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
