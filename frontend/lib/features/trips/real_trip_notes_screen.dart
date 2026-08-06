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
import 'trip_companion_screen.dart' show moodLabel, noteTypeLabel;

/// UI44 — Real Mode trip notes (`/api/me/trips/{tripId}/notes`). Lists a real
/// trip's freeform notes and journal entries (pinned first), and supports add /
/// edit / delete / pin (owner or EDITOR collaborator). All fields come from the
/// backend; nothing is fabricated.
class RealTripNotesScreen extends StatefulWidget {
  final int tripId;
  final String? tripTitle;

  const RealTripNotesScreen({
    super.key,
    required this.tripId,
    this.tripTitle,
  });

  @override
  State<RealTripNotesScreen> createState() => _RealTripNotesScreenState();
}

class _RealTripNotesScreenState extends State<RealTripNotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealNotes(widget.tripId);
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

  String _messageForOutcome(AppLocalizations l10n, NoteOutcome o) {
    return switch (o) {
      NoteOutcome.forbidden => l10n.notesRealForbiddenMessage,
      NoteOutcome.notFound => l10n.notesRealGoneMessage,
      NoteOutcome.validation => l10n.notesRealContentRequiredMessage,
      NoteOutcome.network => l10n.notesRealNetworkMessage,
      _ => l10n.notesRealActionErrorMessage,
    };
  }

  Future<void> _openForm(AppState app, RealTripNote? existing) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await showModalBottomSheet<NoteOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NoteFormSheet(
        tripId: widget.tripId,
        existing: existing,
      ),
    );
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case NoteOutcome.success:
        _snack(existing == null
            ? l10n.notesRealCreatedMessage
            : l10n.notesRealUpdatedMessage);
      case NoteOutcome.sessionExpired:
        _reauth();
      case NoteOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _togglePin(AppState app, RealTripNote note) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome =
        await app.setRealNotePinned(widget.tripId, note.id, !note.pinned);
    if (!mounted) return;
    switch (outcome) {
      case NoteOutcome.success:
        _snack(note.pinned
            ? l10n.notesRealUnpinnedMessage
            : l10n.notesRealPinnedMessage);
      case NoteOutcome.sessionExpired:
        _reauth();
      case NoteOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _delete(AppState app, RealTripNote note) async {
    final l10n = AppLocalizations.of(context)!;
    final title = (note.title ?? '').trim().isNotEmpty
        ? note.title!.trim()
        : l10n.notesRealTitle;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notesDeleteConfirmTitle),
        content: Text(l10n.notesDeleteConfirmMessage(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('note-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.notesDeleteAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.deleteRealNote(widget.tripId, note.id);
    if (!mounted) return;
    switch (outcome) {
      case NoteOutcome.success:
        _snack(l10n.notesRealDeletedMessage);
      case NoteOutcome.sessionExpired:
        _reauth();
      case NoteOutcome.busy:
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
            : l10n.notesRealTitle),
        actions: [
          if (app.realNotesLoaded)
            IconButton(
              key: const Key('notes-add'),
              tooltip: l10n.notesRealAddSemantic,
              onPressed: app.realNoteMutationInFlight
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
    if (app.realNotesError == NoteOutcome.sessionExpired &&
        !app.realNotesLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('notes-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realNotesLoading && !app.realNotesLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.notesRealLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('notes-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.notesRealLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realNotesError != null && !app.realNotesLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('notes-error'),
          message: app.realNotesError == NoteOutcome.notFound
              ? l10n.notesRealGoneMessage
              : app.realNotesError == NoteOutcome.forbidden
                  ? l10n.notesRealForbiddenMessage
                  : l10n.notesRealErrorMessage,
          onReload: () => app.loadRealNotes(widget.tripId, refresh: true),
        ),
      );
    }
    final notes = app.realNotesFor(widget.tripId);
    final locale = Localizations.localeOf(context).toString();
    return RefreshIndicator(
      onRefresh: () => app.loadRealNotes(widget.tripId, refresh: true),
      child: ListView(
        key: const Key('notes-content'),
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
                if (notes.isEmpty)
                  OceanEmptyState(
                    key: const Key('notes-empty'),
                    title: l10n.notesEmptyTitle,
                    message: l10n.notesEmptyMessage,
                    actionLabel: l10n.notesAddAction,
                    onAction: app.realNoteMutationInFlight
                        ? null
                        : () => _openForm(app, null),
                  )
                else
                  for (final n in notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _NoteCard(
                        note: n,
                        locale: locale,
                        onEdit: () => _openForm(app, n),
                        onTogglePin: () => _togglePin(app, n),
                        onDelete: () => _delete(app, n),
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

String realNoteTypeLabel(AppLocalizations l10n, RealTripNote note) {
  final view = note.typeView;
  if (view != null) return noteTypeLabel(l10n, view);
  return note.noteType.trim().isEmpty ? l10n.notesRealTitle : note.noteType;
}

IconData realNoteTypeIcon(TripNoteType? type) {
  return switch (type) {
    TripNoteType.note => Icons.sticky_note_2_rounded,
    TripNoteType.journal => Icons.menu_book_rounded,
    TripNoteType.reminder => Icons.alarm_rounded,
    TripNoteType.idea => Icons.lightbulb_rounded,
    TripNoteType.memory => Icons.photo_album_rounded,
    null => Icons.sticky_note_2_rounded,
  };
}

class _NoteCard extends StatelessWidget {
  final RealTripNote note;
  final String locale;
  final VoidCallback onEdit;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.locale,
    required this.onEdit,
    required this.onTogglePin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = (note.title ?? '').trim().isNotEmpty
        ? note.title!.trim()
        : realNoteTypeLabel(l10n, note);
    final date = note.updatedAt != null
        ? DateFormat.yMMMd(locale).format(note.updatedAt!.toLocal())
        : null;
    final mood = note.moodView;
    return OceanGlassCard(
      key: Key('note-card-${note.id}'),
      onTap: onEdit,
      semanticLabel: title,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.ocean.withValues(alpha: .12),
            child: Icon(
              realNoteTypeIcon(note.typeView),
              color: AppColors.ocean,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (note.content.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    note.content.trim(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OceanStatusPill(
                      label: realNoteTypeLabel(l10n, note),
                      icon: realNoteTypeIcon(note.typeView),
                    ),
                    if (mood != null)
                      OceanStatusPill(
                        label: moodLabel(l10n, mood),
                        icon: Icons.mood_rounded,
                        color: AppColors.turquoise600,
                      ),
                    if (note.pinned)
                      OceanStatusPill(
                        label: l10n.notesPinAction,
                        icon: Icons.push_pin_rounded,
                        color: AppColors.warning,
                      ),
                    if (date != null)
                      OceanStatusPill(
                        label: date,
                        icon: Icons.update_rounded,
                        color: AppColors.slate,
                      ),
                    if ((note.authorUserName ?? '').trim().isNotEmpty)
                      OceanStatusPill(
                        label: note.authorUserName!.trim(),
                        icon: Icons.person_rounded,
                        color: AppColors.slate,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                key: Key('note-pin-${note.id}'),
                tooltip:
                    note.pinned ? l10n.notesUnpinAction : l10n.notesPinAction,
                onPressed: onTogglePin,
                icon: Icon(note.pinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined),
              ),
              IconButton(
                key: Key('note-delete-${note.id}'),
                tooltip: l10n.notesDeleteAction,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteFormSheet extends StatefulWidget {
  final int tripId;
  final RealTripNote? existing;

  const _NoteFormSheet({required this.tripId, this.existing});

  @override
  State<_NoteFormSheet> createState() => _NoteFormSheetState();
}

class _NoteFormSheetState extends State<_NoteFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _photoUrl;
  late TripNoteType _type;
  TripMood? _mood;
  bool _contentError = false;

  @override
  void initState() {
    super.initState();
    final n = widget.existing;
    _title = TextEditingController(text: n?.title ?? '');
    _content = TextEditingController(text: n?.content ?? '');
    _photoUrl = TextEditingController(text: n?.photoUrl ?? '');
    _type = n?.typeView ?? TripNoteType.note;
    _mood = n?.moodView;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = AppScope.of(context);
    final content = _content.text.trim();
    setState(() => _contentError = content.isEmpty);
    if (content.isEmpty) return;
    final payload = RealTripNotePayload(
      noteType: _type,
      content: content,
      title: _title.text.trim().isEmpty ? null : _title.text.trim(),
      mood: _mood,
      photoUrl: _photoUrl.text.trim().isEmpty ? null : _photoUrl.text.trim(),
    );
    final existing = widget.existing;
    final outcome = existing == null
        ? await app.createRealNote(widget.tripId, payload)
        : await app.updateRealNote(widget.tripId, existing.id, payload);
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final saving = app.realNoteMutationInFlight;
    final isEdit = widget.existing != null;
    return SafeArea(
      child: Padding(
        key: const Key('note-form-content'),
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
                isEdit ? l10n.notesRealEditTitle : l10n.notesRealCreateTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('note-field-title'),
                controller: _title,
                decoration: InputDecoration(labelText: l10n.notesTitleLabel),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<TripNoteType>(
                key: const Key('note-field-type'),
                initialValue: _type,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.notesTypeLabel),
                items: [
                  for (final type in TripNoteType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(noteTypeLabel(l10n, type)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<TripMood?>(
                key: const Key('note-field-mood'),
                initialValue: _mood,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.notesMoodLabel),
                items: [
                  DropdownMenuItem<TripMood?>(
                    value: null,
                    child: Text(l10n.notesRealMoodNone),
                  ),
                  for (final mood in TripMood.values)
                    DropdownMenuItem<TripMood?>(
                      value: mood,
                      child: Text(moodLabel(l10n, mood)),
                    ),
                ],
                onChanged: (v) => setState(() => _mood = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('note-field-content'),
                controller: _content,
                decoration: InputDecoration(
                  labelText: l10n.notesContentLabel,
                  errorText: _contentError
                      ? l10n.notesRealContentRequiredMessage
                      : null,
                ),
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('note-field-photo'),
                controller: _photoUrl,
                decoration: InputDecoration(labelText: l10n.notesPhotoUrlLabel),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.lg),
              OceanPrimaryButton(
                key: const Key('note-form-save'),
                label: isEdit ? l10n.notesEditAction : l10n.notesAddAction,
                icon: Icons.check_rounded,
                onPressed: saving ? null : _submit,
                semanticLabel:
                    isEdit ? l10n.notesEditAction : l10n.notesAddAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
