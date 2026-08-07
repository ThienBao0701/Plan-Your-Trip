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
import 'trip_companion_screen.dart' show reminderStatusLabel, reminderTypeLabel;

/// UI46 — Real Mode trip reminders (`/api/me/trips/{tripId}/reminders`). Lists a
/// real trip's in-app reminder records (soonest first; cancelled hidden unless
/// the include-cancelled filter is on), and supports add / edit / complete /
/// cancel / delete (owner or EDITOR collaborator). This is the backend's
/// storage + CRUD foundation only — there is no delivery/scheduler, so the UI
/// never claims a reminder will be pushed or emailed.
class RealTripRemindersScreen extends StatefulWidget {
  final int tripId;
  final String? tripTitle;

  const RealTripRemindersScreen({
    super.key,
    required this.tripId,
    this.tripTitle,
  });

  @override
  State<RealTripRemindersScreen> createState() =>
      _RealTripRemindersScreenState();
}

class _RealTripRemindersScreenState extends State<RealTripRemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealReminders(widget.tripId);
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

  String _messageForOutcome(AppLocalizations l10n, ReminderOutcome o) {
    return switch (o) {
      ReminderOutcome.forbidden => l10n.remindersRealForbiddenMessage,
      ReminderOutcome.notFound => l10n.remindersRealGoneMessage,
      ReminderOutcome.validation => l10n.remindersRealTitleRequiredMessage,
      ReminderOutcome.network => l10n.remindersRealNetworkMessage,
      _ => l10n.remindersRealActionErrorMessage,
    };
  }

  Future<void> _openForm(AppState app, RealReminder? existing) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await showModalBottomSheet<ReminderOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReminderFormSheet(
        tripId: widget.tripId,
        existing: existing,
      ),
    );
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case ReminderOutcome.success:
        _snack(existing == null
            ? l10n.remindersRealCreatedMessage
            : l10n.remindersRealUpdatedMessage);
      case ReminderOutcome.sessionExpired:
        _reauth();
      case ReminderOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _complete(AppState app, RealReminder r) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await app.completeRealReminder(widget.tripId, r.id);
    if (!mounted) return;
    switch (outcome) {
      case ReminderOutcome.success:
        _snack(l10n.remindersRealCompletedMessage);
      case ReminderOutcome.busy:
        break;
      case ReminderOutcome.sessionExpired:
        _reauth();
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _cancel(AppState app, RealReminder r) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await app.cancelRealReminder(widget.tripId, r.id);
    if (!mounted) return;
    switch (outcome) {
      case ReminderOutcome.success:
        _snack(l10n.remindersRealCancelledMessage);
      case ReminderOutcome.busy:
        break;
      case ReminderOutcome.sessionExpired:
        _reauth();
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _delete(AppState app, RealReminder r) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reminderDeleteConfirmTitle),
        content: Text(l10n.remindersRealDeleteConfirmMessage(r.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('reminder-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.reminderDeleteAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.deleteRealReminder(widget.tripId, r.id);
    if (!mounted) return;
    switch (outcome) {
      case ReminderOutcome.success:
        _snack(l10n.remindersRealDeletedMessage);
      case ReminderOutcome.sessionExpired:
        _reauth();
      case ReminderOutcome.busy:
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
            : l10n.remindersRealTitle),
        actions: [
          if (app.realRemindersLoaded)
            IconButton(
              key: const Key('reminder-add'),
              tooltip: l10n.remindersRealAddSemantic,
              onPressed: app.realRemindersMutationInFlight
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
    if (app.realRemindersError == ReminderOutcome.sessionExpired &&
        !app.realRemindersLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('reminders-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realRemindersLoading && !app.realRemindersLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.remindersRealLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('reminders-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.remindersRealLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realRemindersError != null && !app.realRemindersLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('reminders-error'),
          message: app.realRemindersError == ReminderOutcome.notFound
              ? l10n.remindersRealGoneMessage
              : app.realRemindersError == ReminderOutcome.forbidden
                  ? l10n.remindersRealForbiddenMessage
                  : l10n.remindersRealErrorMessage,
          onReload: () => app.loadRealReminders(widget.tripId, refresh: true),
        ),
      );
    }
    final reminders = app.realRemindersFor(widget.tripId);
    return RefreshIndicator(
      onRefresh: () => app.loadRealReminders(widget.tripId, refresh: true),
      child: ListView(
        key: const Key('reminders-content'),
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
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilterChip(
                    key: const Key('reminders-include-cancelled'),
                    label: Text(l10n.remindersIncludeCancelled),
                    selected: app.realRemindersIncludeCancelled,
                    onSelected: app.realRemindersMutationInFlight
                        ? null
                        : (value) => app.loadRealReminders(
                              widget.tripId,
                              refresh: true,
                              includeCancelled: value,
                            ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (reminders.isEmpty)
                  OceanEmptyState(
                    key: const Key('reminders-empty'),
                    title: l10n.remindersRealEmptyTitle,
                    message: l10n.remindersRealEmptyMessage,
                    actionLabel: l10n.remindersAddAction,
                    onAction: app.realRemindersMutationInFlight
                        ? null
                        : () => _openForm(app, null),
                  )
                else
                  for (final r in reminders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ReminderCard(
                        reminder: r,
                        now: app.now(),
                        busy: app.realRemindersMutationInFlight,
                        onComplete: () => _complete(app, r),
                        onCancel: () => _cancel(app, r),
                        onEdit: () => _openForm(app, r),
                        onDelete: () => _delete(app, r),
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

/// Localized reminder-type label for a real reminder, falling back to the raw
/// wire code if the backend sent an unrecognised type.
String realReminderTypeLabel(AppLocalizations l10n, RealReminder r) {
  final view = r.typeView;
  if (view != null) return reminderTypeLabel(l10n, view);
  return r.reminderType.trim().isEmpty
      ? l10n.reminderTypeLabel
      : r.reminderType;
}

/// Localized status label for a real reminder, falling back to the raw code.
String realReminderStatusLabel(AppLocalizations l10n, RealReminder r) {
  final view = r.statusView;
  if (view != null) return reminderStatusLabel(l10n, view);
  return r.status.trim().isEmpty ? l10n.reminderStatusPending : r.status;
}

Color _realReminderStatusColor(RealReminder r) {
  switch (r.statusView) {
    case TripReminderStatus.completed:
      return AppColors.success;
    case TripReminderStatus.cancelled:
      return AppColors.textTertiary;
    case TripReminderStatus.pending:
    case null:
      return AppColors.ocean;
  }
}

class _ReminderCard extends StatelessWidget {
  final RealReminder reminder;
  final DateTime now;
  final bool busy;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.now,
    required this.busy,
    required this.onComplete,
    required this.onCancel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date =
        DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_Hm();
    final overdue = reminder.isOverdue(now);
    final pending = reminder.statusView == TripReminderStatus.pending;
    return OceanGlassCard(
      key: Key('reminder-card-${reminder.id}'),
      onTap: onEdit,
      semanticLabel: reminder.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: realReminderTypeLabel(l10n, reminder),
                icon: Icons.alarm_rounded,
              ),
              OceanStatusPill(
                label: realReminderStatusLabel(l10n, reminder),
                icon: Icons.flag_rounded,
                color: _realReminderStatusColor(reminder),
              ),
              if (overdue)
                OceanStatusPill(
                  label: l10n.reminderOverdue,
                  icon: Icons.warning_rounded,
                  color: AppColors.warning,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reminder.title.trim().isEmpty
                ? realReminderTypeLabel(l10n, reminder)
                : reminder.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if ((reminder.message ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(reminder.message!.trim()),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(date.format(reminder.reminderAt.toLocal())),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (pending)
                OceanSecondaryButton(
                  key: Key('reminder-complete-${reminder.id}'),
                  label: l10n.reminderCompleteAction,
                  icon: Icons.check_circle_outline_rounded,
                  fullWidth: false,
                  onPressed: busy ? null : onComplete,
                  semanticLabel:
                      l10n.remindersRealCompleteSemantic(reminder.title),
                ),
              if (pending)
                OceanSecondaryButton(
                  key: Key('reminder-cancel-${reminder.id}'),
                  label: l10n.reminderCancelAction,
                  icon: Icons.block_rounded,
                  fullWidth: false,
                  onPressed: busy ? null : onCancel,
                  semanticLabel:
                      l10n.remindersRealCancelSemantic(reminder.title),
                ),
              OceanSecondaryButton(
                key: Key('reminder-delete-${reminder.id}'),
                label: l10n.reminderDeleteAction,
                icon: Icons.delete_outline_rounded,
                fullWidth: false,
                onPressed: busy ? null : onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderFormSheet extends StatefulWidget {
  final int tripId;
  final RealReminder? existing;

  const _ReminderFormSheet({required this.tripId, this.existing});

  @override
  State<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<_ReminderFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _message;
  late TripReminderType _type;
  late DateTime _when; // local
  bool _titleError = false;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _title = TextEditingController(text: r?.title ?? '');
    _message = TextEditingController(text: r?.message ?? '');
    _type = r?.typeView ?? TripReminderType.custom;
    _when = (r?.reminderAt ?? DateTime.now().add(const Duration(hours: 1)))
        .toLocal();
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (!mounted) return;
    setState(() {
      _when = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _when.hour,
        time?.minute ?? _when.minute,
      );
    });
  }

  Future<void> _submit() async {
    final app = AppScope.of(context);
    final title = _title.text.trim();
    setState(() => _titleError = title.isEmpty);
    if (title.isEmpty) return;
    final payload = RealReminderPayload(
      reminderType: _type,
      title: title,
      message: _message.text.trim().isEmpty ? null : _message.text.trim(),
      reminderAt: _when,
    );
    final existing = widget.existing;
    final outcome = existing == null
        ? await app.createRealReminder(widget.tripId, payload)
        : await app.updateRealReminder(widget.tripId, existing.id, payload);
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final saving = app.realRemindersMutationInFlight;
    final isEdit = widget.existing != null;
    final whenLabel =
        DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .add_Hm()
            .format(_when);
    return SafeArea(
      child: Padding(
        key: const Key('reminder-form-content'),
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
                    ? l10n.remindersRealEditTitle
                    : l10n.remindersRealCreateTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('reminder-field-title'),
                controller: _title,
                decoration: InputDecoration(
                  labelText: l10n.reminderTitleField,
                  errorText: _titleError
                      ? l10n.remindersRealTitleRequiredMessage
                      : null,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<TripReminderType>(
                key: const Key('reminder-field-type'),
                initialValue: _type,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.reminderTypeLabel),
                items: [
                  for (final t in TripReminderType.values)
                    DropdownMenuItem(
                      value: t,
                      child: Text(reminderTypeLabel(l10n, t)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                key: const Key('reminder-field-when'),
                onTap: saving ? null : _pickWhen,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.reminderAtField,
                    suffixIcon: const Icon(Icons.event_rounded),
                  ),
                  child: Text(whenLabel),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('reminder-field-message'),
                controller: _message,
                decoration:
                    InputDecoration(labelText: l10n.reminderMessageField),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.lg),
              OceanPrimaryButton(
                key: const Key('reminder-form-save'),
                label:
                    isEdit ? l10n.remindersEditAction : l10n.remindersAddAction,
                icon: Icons.check_rounded,
                onPressed: saving ? null : _submit,
                semanticLabel:
                    isEdit ? l10n.remindersEditAction : l10n.remindersAddAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
