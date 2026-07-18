import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'trip_documents_screen.dart';

class TripCompanionScreen extends StatelessWidget {
  final Trip trip;

  const TripCompanionScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentTrip = app.tripById(trip.id);
    final counts =
        currentTrip == null ? null : app.companionCountsForTrip(currentTrip.id);
    final permission = currentTrip == null
        ? TripPermission.noAccess
        : app.tripAccessLevel(currentTrip.id);

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.tripCompanionTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('trip-companion-screen'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: currentTrip == null
                    ? OceanEmptyState(
                        title: l10n.tripDocumentsEmptyTitle,
                        message: l10n.tripDocumentsTripDeletedMessage,
                      )
                    : !app.demoMode
                        ? OceanEmptyState(
                            title: l10n.tripCompanionRealEmptyTitle,
                            message: l10n.tripCompanionRealEmptyMessage,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CompanionHeader(
                                trip: currentTrip,
                                permission: permission,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _CompanionCounts(counts: counts!),
                              const SizedBox(height: AppSpacing.lg),
                              _CompanionModuleGrid(trip: currentTrip),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SharedWithMeScreen extends StatelessWidget {
  const SharedWithMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.MMMd(Localizations.localeOf(context).toString());
    final trips = app.visibleSharedTrips();

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.sharedWithMeTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('shared-with-me-screen'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: !app.demoMode
                    ? OceanEmptyState(
                        title: l10n.sharedWithMeRealEmptyTitle,
                        message: l10n.sharedWithMeRealEmptyMessage,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.sharedWithMeTitle,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.sharedWithMeSubtitle,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (trips.isEmpty)
                            OceanEmptyState(
                              title: l10n.sharedWithMeEmptyTitle,
                              message: l10n.sharedWithMeEmptyMessage,
                            )
                          else
                            for (final trip in trips)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: OceanGlassCard(
                                  key: Key('shared-trip-${trip.tripId}'),
                                  onTap: () {
                                    final fullTrip = app.tripById(trip.tripId);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => fullTrip == null
                                            ? SharedTripSummaryScreen(
                                                summary: trip,
                                              )
                                            : TripCompanionScreen(
                                                trip: fullTrip,
                                              ),
                                      ),
                                    );
                                  },
                                  semanticLabel: trip.title,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              trip.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.xxs),
                                            Text(
                                              '${trip.destination} - ${date.format(trip.startDate)} - ${date.format(trip.endDate)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.sm),
                                            Wrap(
                                              spacing: AppSpacing.xs,
                                              runSpacing: AppSpacing.xs,
                                              children: [
                                                OceanStatusPill(
                                                  label: l10n
                                                      .sharedWithMeOwnerLabel(
                                                    trip.ownerName,
                                                  ),
                                                  icon: Icons.person_rounded,
                                                ),
                                                OceanStatusPill(
                                                  label: l10n
                                                      .sharedWithMeRoleLabel(
                                                    collaboratorRoleLabel(
                                                      l10n,
                                                      trip.role,
                                                    ),
                                                  ),
                                                  icon: trip.role ==
                                                          TripCollaboratorRole
                                                              .editor
                                                      ? Icons.edit_rounded
                                                      : Icons
                                                          .visibility_rounded,
                                                  color: AppColors.turquoise600,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SharedTripSummaryScreen extends StatelessWidget {
  final SharedTripSummary summary;

  const SharedTripSummaryScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(summary.title),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('shared-trip-summary-screen'),
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
                    OceanGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.title,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${summary.destination} - ${date.format(summary.startDate)} - ${date.format(summary.endDate)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              OceanStatusPill(
                                label: l10n.sharedWithMeOwnerLabel(
                                  summary.ownerName,
                                ),
                                icon: Icons.person_rounded,
                              ),
                              OceanStatusPill(
                                label: l10n.sharedWithMeRoleLabel(
                                  collaboratorRoleLabel(l10n, summary.role),
                                ),
                                icon:
                                    summary.role == TripCollaboratorRole.editor
                                        ? Icons.edit_rounded
                                        : Icons.visibility_rounded,
                                color: AppColors.turquoise600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OceanGlassSurface(
                      blur: 0,
                      color: AppColors.paleCyan,
                      child: Text(
                        l10n.sharedWithMeSummaryReadOnlyNotice,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TripCollaborationScreen extends StatefulWidget {
  final Trip trip;

  const TripCollaborationScreen({super.key, required this.trip});

  @override
  State<TripCollaborationScreen> createState() =>
      _TripCollaborationScreenState();
}

class _TripCollaborationScreenState extends State<TripCollaborationScreen> {
  final _email = TextEditingController();
  TripCollaboratorRole _role = TripCollaboratorRole.viewer;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final trip = app.tripById(widget.trip.id);
    final permission =
        trip == null ? TripPermission.noAccess : app.tripAccessLevel(trip.id);
    final collaborators =
        trip == null ? <TripCollaborator>[] : app.collaboratorsForTrip(trip.id);

    return _TripToolScaffold(
      keyName: 'trip-collaboration-screen',
      title: l10n.tripCompanionCollaborationTitle,
      child: trip == null
          ? OceanEmptyState(
              title: l10n.tripDocumentsEmptyTitle,
              message: l10n.tripDocumentsTripDeletedMessage,
            )
          : !app.demoMode
              ? OceanEmptyState(
                  title: l10n.tripCompanionRealEmptyTitle,
                  message: l10n.tripCompanionRealEmptyMessage,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ReadOnlyNotice(permission: permission),
                    OceanGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.collaborationPrivacyNotice,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Material(
                            color: Colors.transparent,
                            child: SwitchListTile(
                              key: const Key('trip-public-toggle'),
                              contentPadding: EdgeInsets.zero,
                              value: app.isTripPublic(trip.id),
                              title: Text(l10n.collaborationPublicToggleLabel),
                              subtitle: Text(app.isTripPublic(trip.id)
                                  ? l10n.collaborationPrivacyPublic
                                  : l10n.collaborationPrivacyPrivate),
                              onChanged: permission.canManage
                                  ? (value) => _showResult(
                                      app.setTripPublic(trip.id, value))
                                  : null,
                            ),
                          ),
                          Text(
                            l10n.collaborationNoShareUrlNotice,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OceanGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.collaborationInviteTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            key: const Key('collaboration-email-field'),
                            controller: _email,
                            decoration: InputDecoration(
                              labelText: l10n.collaborationInviteEmailLabel,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _RoleDropdown(
                            value: _role,
                            onChanged: permission.canManage
                                ? (value) {
                                    if (value != null) {
                                      setState(() => _role = value);
                                    }
                                  }
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OceanPrimaryButton(
                            key: const Key('collaboration-invite-action'),
                            label: l10n.collaborationInviteAction,
                            icon: Icons.person_add_rounded,
                            onPressed: permission.canManage && !_submitting
                                ? () {
                                    setState(() => _submitting = true);
                                    final result = app.inviteTripCollaborator(
                                      trip.id,
                                      _email.text,
                                      role: _role,
                                    );
                                    if (result ==
                                        TripToolActionResult.success) {
                                      _email.clear();
                                    }
                                    setState(() => _submitting = false);
                                    _showResult(result);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final collaborator in collaborators)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _CollaboratorCard(
                          collaborator: collaborator,
                          canManage: permission.canManage,
                          onRoleChanged: (role) => _showResult(
                            app.updateCollaboratorRole(
                              trip.id,
                              collaborator.id,
                              role,
                            ),
                          ),
                          onRemove: () => _confirmRemove(collaborator),
                        ),
                      ),
                  ],
                ),
    );
  }

  Future<void> _confirmRemove(TripCollaborator collaborator) async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.collaborationRemoveConfirmTitle),
        content: Text(
            l10n.collaborationRemoveConfirmMessage(collaborator.userFullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.collaborationRemoveAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _showResult(app.removeCollaborator(widget.trip.id, collaborator.id));
  }

  void _showResult(TripToolActionResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tripToolResultMessage(context, result))));
  }
}

class TripNotesScreen extends StatefulWidget {
  final Trip trip;

  const TripNotesScreen({super.key, required this.trip});

  @override
  State<TripNotesScreen> createState() => _TripNotesScreenState();
}

class _TripNotesScreenState extends State<TripNotesScreen> {
  final _search = TextEditingController();
  TripNoteType? _type;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final trip = app.tripById(widget.trip.id);
    final permission =
        trip == null ? TripPermission.noAccess : app.tripAccessLevel(trip.id);
    final notes =
        trip == null ? <TripNote>[] : _filteredNotes(app.notesForTrip(trip.id));

    return _TripToolScaffold(
      keyName: 'trip-notes-screen',
      title: l10n.tripCompanionNotesTitle,
      child: trip == null
          ? OceanEmptyState(
              title: l10n.tripDocumentsEmptyTitle,
              message: l10n.tripDocumentsTripDeletedMessage,
            )
          : !app.demoMode
              ? OceanEmptyState(
                  title: l10n.tripCompanionRealEmptyTitle,
                  message: l10n.tripCompanionRealEmptyMessage,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ReadOnlyNotice(permission: permission),
                    OceanGlassCard(
                      child: Column(
                        children: [
                          OceanSearchField(
                            key: const Key('trip-notes-search'),
                            controller: _search,
                            hintText: l10n.notesSearchHint,
                            onChanged: (_) => setState(() {}),
                            onClear: () => setState(_search.clear),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _EnumDropdown<TripNoteType>(
                            key: const Key('trip-notes-type-filter'),
                            label: l10n.notesTypeLabel,
                            value: _type,
                            values: TripNoteType.values,
                            labelFor: (value) => noteTypeLabel(l10n, value),
                            onChanged: (value) => setState(() => _type = value),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OceanPrimaryButton(
                            key: const Key('trip-note-add'),
                            label: l10n.notesAddAction,
                            icon: Icons.note_add_rounded,
                            onPressed: permission.canEdit
                                ? () => _showEditor(trip)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (notes.isEmpty)
                      OceanEmptyState(
                        title: l10n.notesEmptyTitle,
                        message: l10n.notesEmptyMessage,
                      )
                    else
                      for (final note in notes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _NoteCard(
                            note: note,
                            canEdit: permission.canEdit,
                            onEdit: () => _showEditor(trip, note),
                            onPin: () => _showResult(
                              app.setTripNotePinned(note.id, !note.pinned),
                            ),
                            onDelete: () => _confirmDelete(note),
                          ),
                        ),
                  ],
                ),
    );
  }

  List<TripNote> _filteredNotes(List<TripNote> notes) {
    final query = _search.text.trim().toLowerCase();
    return notes.where((note) {
      if (_type != null && note.noteType != _type) return false;
      if (query.isEmpty) return true;
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.authorUserName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _showEditor(Trip trip, [TripNote? note]) async {
    final result = await showModalBottomSheet<TripToolActionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteEditor(trip: trip, note: note),
    );
    if (!mounted || result == null) return;
    _showResult(result);
  }

  Future<void> _confirmDelete(TripNote note) async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.notesDeleteConfirmTitle),
        content: Text(l10n.notesDeleteConfirmMessage(note.titleOrContent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.notesDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _showResult(app.deleteTripNote(note.id));
  }

  void _showResult(TripToolActionResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tripToolResultMessage(context, result))));
  }
}

class TripPackingScreen extends StatefulWidget {
  final Trip trip;

  const TripPackingScreen({super.key, required this.trip});

  @override
  State<TripPackingScreen> createState() => _TripPackingScreenState();
}

class _TripPackingScreenState extends State<TripPackingScreen> {
  final _search = TextEditingController();
  PackingCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final trip = app.tripById(widget.trip.id);
    final permission =
        trip == null ? TripPermission.noAccess : app.tripAccessLevel(trip.id);
    final items = trip == null
        ? <PackingItem>[]
        : _filteredItems(app.packingForTrip(trip.id));
    final progress = trip == null
        ? const PackingProgress(total: 0, checked: 0)
        : app.packingProgressForTrip(trip.id);

    return _TripToolScaffold(
      keyName: 'trip-packing-screen',
      title: l10n.tripCompanionPackingTitle,
      child: trip == null
          ? OceanEmptyState(
              title: l10n.tripDocumentsEmptyTitle,
              message: l10n.tripDocumentsTripDeletedMessage,
            )
          : !app.demoMode
              ? OceanEmptyState(
                  title: l10n.tripCompanionRealEmptyTitle,
                  message: l10n.tripCompanionRealEmptyMessage,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ReadOnlyNotice(permission: permission),
                    _PackingProgressCard(progress: progress),
                    const SizedBox(height: AppSpacing.md),
                    OceanGlassCard(
                      child: Column(
                        children: [
                          OceanSearchField(
                            key: const Key('trip-packing-search'),
                            controller: _search,
                            hintText: l10n.packingSearchHint,
                            onChanged: (_) => setState(() {}),
                            onClear: () => setState(_search.clear),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _EnumDropdown<PackingCategory>(
                            key: const Key('trip-packing-category-filter'),
                            label: l10n.packingCategoryLabel,
                            value: _category,
                            values: PackingCategory.values,
                            labelFor: (value) =>
                                packingCategoryLabel(l10n, value),
                            onChanged: (value) =>
                                setState(() => _category = value),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OceanPrimaryButton(
                            key: const Key('trip-packing-add'),
                            label: l10n.packingAddAction,
                            icon: Icons.add_task_rounded,
                            onPressed: permission.canEdit
                                ? () => _showEditor(trip)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (items.isEmpty)
                      OceanEmptyState(
                        title: l10n.packingEmptyTitle,
                        message: l10n.packingEmptyMessage,
                      )
                    else
                      for (var i = 0; i < items.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _PackingCard(
                            item: items[i],
                            canEdit: permission.canEdit,
                            onChecked: (value) => _showResult(
                              app.setPackingChecked(items[i].id, value),
                            ),
                            onMoveUp: i == 0
                                ? null
                                : () => _moveItem(app, trip.id, items, i, -1),
                            onMoveDown: i == items.length - 1
                                ? null
                                : () => _moveItem(app, trip.id, items, i, 1),
                            onEdit: () => _showEditor(trip, items[i]),
                            onDelete: () => _confirmDelete(items[i]),
                          ),
                        ),
                  ],
                ),
    );
  }

  List<PackingItem> _filteredItems(List<PackingItem> items) {
    final query = _search.text.trim().toLowerCase();
    return items.where((item) {
      if (_category != null && item.category != _category) return false;
      if (query.isEmpty) return true;
      return item.label.toLowerCase().contains(query) ||
          item.notes.toLowerCase().contains(query) ||
          (item.assignedToUserName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _showEditor(Trip trip, [PackingItem? item]) async {
    final result = await showModalBottomSheet<TripToolActionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackingEditor(trip: trip, item: item),
    );
    if (!mounted || result == null) return;
    _showResult(result);
  }

  Future<void> _confirmDelete(PackingItem item) async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.packingDeleteConfirmTitle),
        content: Text(l10n.packingDeleteConfirmMessage(item.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.packingDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _showResult(app.deletePackingItem(item.id));
  }

  void _moveItem(
    AppState app,
    int tripId,
    List<PackingItem> visibleItems,
    int index,
    int delta,
  ) {
    final full = app.packingForTrip(tripId).map((item) => item.id).toList();
    final fromId = visibleItems[index].id;
    final toId = visibleItems[index + delta].id;
    final from = full.indexOf(fromId);
    final to = full.indexOf(toId);
    if (from < 0 || to < 0) {
      _showResult(TripToolActionResult.invalidReorder);
      return;
    }
    final moved = full.removeAt(from);
    full.insert(to, moved);
    _showResult(app.reorderPackingItems(tripId, full));
  }

  void _showResult(TripToolActionResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tripToolResultMessage(context, result))));
  }
}

class TripRemindersScreen extends StatefulWidget {
  final Trip trip;

  const TripRemindersScreen({super.key, required this.trip});

  @override
  State<TripRemindersScreen> createState() => _TripRemindersScreenState();
}

class _TripRemindersScreenState extends State<TripRemindersScreen> {
  bool _includeCancelled = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final trip = app.tripById(widget.trip.id);
    final permission =
        trip == null ? TripPermission.noAccess : app.tripAccessLevel(trip.id);
    final reminders = trip == null
        ? <TripReminder>[]
        : app.remindersForTrip(
            trip.id,
            includeCancelled: _includeCancelled,
          );

    return _TripToolScaffold(
      keyName: 'trip-reminders-screen',
      title: l10n.tripCompanionRemindersTitle,
      child: trip == null
          ? OceanEmptyState(
              title: l10n.tripDocumentsEmptyTitle,
              message: l10n.tripDocumentsTripDeletedMessage,
            )
          : !app.demoMode
              ? OceanEmptyState(
                  title: l10n.tripCompanionRealEmptyTitle,
                  message: l10n.tripCompanionRealEmptyMessage,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ReadOnlyNotice(permission: permission),
                    OceanGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.reminderNoDeliveryNotice,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Material(
                            color: Colors.transparent,
                            child: SwitchListTile(
                              key: const Key('reminders-include-cancelled'),
                              contentPadding: EdgeInsets.zero,
                              value: _includeCancelled,
                              title: Text(l10n.remindersIncludeCancelled),
                              onChanged: (value) =>
                                  setState(() => _includeCancelled = value),
                            ),
                          ),
                          OceanPrimaryButton(
                            key: const Key('trip-reminder-add'),
                            label: l10n.remindersAddAction,
                            icon: Icons.alarm_add_rounded,
                            onPressed: permission.canEdit
                                ? () => _showEditor(trip)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (reminders.isEmpty)
                      OceanEmptyState(
                        title: l10n.reminderEmptyTitle,
                        message: l10n.reminderEmptyMessage,
                      )
                    else
                      for (final reminder in reminders)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ReminderCard(
                            reminder: reminder,
                            canEdit: permission.canEdit,
                            onEdit: () => _showEditor(trip, reminder),
                            onComplete: () => _showResult(
                              app.completeTripReminder(reminder.id),
                            ),
                            onCancel: () => _showResult(
                              app.cancelTripReminder(reminder.id),
                            ),
                            onDelete: () => _confirmDelete(reminder),
                          ),
                        ),
                  ],
                ),
    );
  }

  Future<void> _showEditor(Trip trip, [TripReminder? reminder]) async {
    final result = await showModalBottomSheet<TripToolActionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderEditor(trip: trip, reminder: reminder),
    );
    if (!mounted || result == null) return;
    _showResult(result);
  }

  Future<void> _confirmDelete(TripReminder reminder) async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reminderDeleteConfirmTitle),
        content: Text(l10n.reminderDeleteConfirmMessage(reminder.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.reminderDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _showResult(app.deleteTripReminder(reminder.id));
  }

  void _showResult(TripToolActionResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tripToolResultMessage(context, result))));
  }
}

class _CompanionHeader extends StatelessWidget {
  final Trip trip;
  final TripPermission permission;

  const _CompanionHeader({required this.trip, required this.permission});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tripCompanionTitle,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.tripCompanionSubtitle(trip.title),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: l10n.tripCompanionPermissionLabel(
                  permissionLabel(l10n, permission),
                ),
                icon: Icons.admin_panel_settings_rounded,
              ),
              OceanStatusPill(
                label: l10n.demoModeLabel,
                icon: Icons.science_rounded,
                color: AppColors.turquoise600,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompanionCounts extends StatelessWidget {
  final TripCompanionCounts counts;

  const _CompanionCounts({required this.counts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      (
        l10n.tripCompanionCountCollaborators,
        counts.activeCollaborators,
        Icons.group_rounded
      ),
      (l10n.tripCompanionCountNotes, counts.notes, Icons.notes_rounded),
      (
        l10n.tripCompanionCountPacking,
        counts.uncheckedPacking,
        Icons.checklist_rounded
      ),
      (
        l10n.tripCompanionCountReminders,
        counts.pendingReminders,
        Icons.alarm_rounded
      ),
      (
        l10n.tripCompanionCountDocuments,
        counts.documents,
        Icons.folder_copy_rounded
      ),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final card in cards)
          SizedBox(
            width: 166,
            child: OceanGlassCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              semanticLabel: l10n.walletSummarySemantic(card.$1, card.$2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(card.$3, color: AppColors.ocean),
                  const SizedBox(height: AppSpacing.xs),
                  Text(card.$1, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${card.$2}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CompanionModuleGrid extends StatelessWidget {
  final Trip trip;

  const _CompanionModuleGrid({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final modules = [
      _ModuleSpec(
        key: const Key('companion-collaboration'),
        title: l10n.tripCompanionCollaborationTitle,
        subtitle: l10n.tripCompanionCollaborationSubtitle,
        icon: Icons.group_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TripCollaborationScreen(trip: trip)),
        ),
      ),
      _ModuleSpec(
        key: const Key('companion-notes'),
        title: l10n.tripCompanionNotesTitle,
        subtitle: l10n.tripCompanionNotesSubtitle,
        icon: Icons.edit_note_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripNotesScreen(trip: trip)),
        ),
      ),
      _ModuleSpec(
        key: const Key('companion-packing'),
        title: l10n.tripCompanionPackingTitle,
        subtitle: l10n.tripCompanionPackingSubtitle,
        icon: Icons.checklist_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripPackingScreen(trip: trip)),
        ),
      ),
      _ModuleSpec(
        key: const Key('companion-reminders'),
        title: l10n.tripCompanionRemindersTitle,
        subtitle: l10n.tripCompanionRemindersSubtitle,
        icon: Icons.alarm_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripRemindersScreen(trip: trip)),
        ),
      ),
      _ModuleSpec(
        key: const Key('companion-documents'),
        title: l10n.tripDocumentsTitle,
        subtitle: l10n.tripCompanionDocumentsSubtitle,
        icon: Icons.folder_copy_rounded,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripDocumentsScreen(trip: trip)),
        ),
      ),
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final module in modules)
          SizedBox(
            key: module.key,
            width: 280,
            child: OceanGlassCard(
              semanticLabel: l10n.tripCompanionOpenSemantic(module.title),
              onTap: module.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(module.icon, color: AppColors.ocean),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    module.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    module.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TripToolScaffold extends StatelessWidget {
  final String keyName;
  final String title;
  final Widget child;

  const _TripToolScaffold({
    required this.keyName,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: OceanGlassAppBar(
          leading: IconButton(
            tooltip: AppLocalizations.of(context)!.commonBackSemantic,
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(title),
        ),
        body: BubbleBackground(
          child: SafeArea(
            top: false,
            child: ListView(
              key: Key(keyName),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                OceanContentConstraint(
                  maxWidth: AppBreakpoints.maxContentWidth,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      );
}

class _ReadOnlyNotice extends StatelessWidget {
  final TripPermission permission;

  const _ReadOnlyNotice({required this.permission});

  @override
  Widget build(BuildContext context) {
    if (permission.canEdit) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: OceanGlassSurface(
        blur: 0,
        color: AppColors.paleCyan,
        child: Text(
          AppLocalizations.of(context)!.tripCompanionReadOnlyNotice,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _ModuleSpec {
  final Key key;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleSpec({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _CollaboratorCard extends StatelessWidget {
  final TripCollaborator collaborator;
  final bool canManage;
  final ValueChanged<TripCollaboratorRole> onRoleChanged;
  final VoidCallback onRemove;

  const _CollaboratorCard({
    required this.collaborator,
    required this.canManage,
    required this.onRoleChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person_rounded)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collaborator.userFullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      collaborator.userEmail,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              OceanStatusPill(
                label: collaborator.active
                    ? l10n.collaborationActiveLabel
                    : l10n.collaborationInactiveLabel,
                color:
                    collaborator.active ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 210,
                child: _RoleDropdown(
                  value: collaborator.role,
                  onChanged: canManage && collaborator.active
                      ? (value) {
                          if (value != null) onRoleChanged(value);
                        }
                      : null,
                ),
              ),
              OceanSecondaryButton(
                label: l10n.collaborationRemoveAction,
                icon: Icons.person_remove_rounded,
                fullWidth: false,
                onPressed: canManage ? onRemove : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final TripNote note;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.canEdit,
    required this.onEdit,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      semanticLabel: note.titleOrContent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: noteTypeLabel(l10n, note.noteType),
                icon: Icons.label_rounded,
              ),
              if (note.mood != null)
                OceanStatusPill(
                  label: moodLabel(l10n, note.mood!),
                  icon: Icons.mood_rounded,
                  color: AppColors.turquoise600,
                ),
              if (note.pinned)
                OceanStatusPill(
                  label: l10n.tripDocumentPinned,
                  icon: Icons.push_pin_rounded,
                  color: AppColors.coral,
                ),
              if (note.photoUrl.isNotEmpty)
                OceanStatusPill(
                  label: l10n.notesPhotoMetadataLabel,
                  icon: Icons.image_rounded,
                  color: AppColors.turquoise600,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (note.title.isNotEmpty)
            Text(note.title, style: Theme.of(context).textTheme.titleLarge),
          Text(note.content, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            note.authorUserName,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OceanSecondaryButton(
                label: l10n.notesEditAction,
                icon: Icons.edit_rounded,
                fullWidth: false,
                onPressed: canEdit ? onEdit : null,
              ),
              OceanSecondaryButton(
                label:
                    note.pinned ? l10n.notesUnpinAction : l10n.notesPinAction,
                icon: Icons.push_pin_rounded,
                fullWidth: false,
                onPressed: canEdit ? onPin : null,
              ),
              OceanSecondaryButton(
                label: l10n.notesDeleteAction,
                icon: Icons.delete_rounded,
                fullWidth: false,
                onPressed: canEdit ? onDelete : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackingProgressCard extends StatelessWidget {
  final PackingProgress progress;

  const _PackingProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.packingProgressValue(
        progress.checked,
        progress.total,
        progress.percent,
      ),
      child: OceanGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tripCompanionPackingTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.packingProgressValue(
                progress.checked,
                progress.total,
                progress.percent,
              ),
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: AppColors.ocean),
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: progress.ratio, minHeight: 8),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.packingUncheckedCount(progress.unchecked)),
          ],
        ),
      ),
    );
  }
}

class _PackingCard extends StatelessWidget {
  final PackingItem item;
  final bool canEdit;
  final ValueChanged<bool> onChecked;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PackingCard({
    required this.item,
    required this.canEdit,
    required this.onChecked,
    this.onMoveUp,
    this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              key: Key('packing-check-${item.id}'),
              contentPadding: EdgeInsets.zero,
              value: item.checked,
              onChanged: canEdit ? (value) => onChecked(value ?? false) : null,
              title: Text(item.label),
              subtitle: Text(
                '${packingCategoryLabel(l10n, item.category)} - ${item.quantity} - ${item.assignedToUserName ?? l10n.packingUnassignedLabel}',
              ),
            ),
          ),
          if (item.notes.isNotEmpty) Text(item.notes),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              IconButton.filledTonal(
                tooltip: l10n.packingMoveUpAction,
                onPressed: canEdit ? onMoveUp : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              IconButton.filledTonal(
                tooltip: l10n.packingMoveDownAction,
                onPressed: canEdit ? onMoveDown : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              OceanSecondaryButton(
                label: l10n.packingEditAction,
                icon: Icons.edit_rounded,
                fullWidth: false,
                onPressed: canEdit ? onEdit : null,
              ),
              OceanSecondaryButton(
                label: l10n.packingDeleteAction,
                icon: Icons.delete_rounded,
                fullWidth: false,
                onPressed: canEdit ? onDelete : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final TripReminder reminder;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.canEdit,
    required this.onEdit,
    required this.onComplete,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final date =
        DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_Hm();
    final overdue = reminder.isOverdue(app.now());
    return OceanGlassCard(
      semanticLabel: reminder.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: reminderTypeLabel(l10n, reminder.reminderType),
                icon: Icons.alarm_rounded,
              ),
              OceanStatusPill(
                label: reminderStatusLabel(l10n, reminder.status),
                icon: Icons.flag_rounded,
                color: _reminderStatusColor(reminder.status),
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
          Text(reminder.title, style: Theme.of(context).textTheme.titleLarge),
          if (reminder.message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(reminder.message),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(date.format(reminder.reminderAt.toLocal())),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OceanSecondaryButton(
                label: l10n.remindersEditAction,
                icon: Icons.edit_rounded,
                fullWidth: false,
                onPressed: canEdit ? onEdit : null,
              ),
              OceanSecondaryButton(
                label: l10n.reminderCompleteAction,
                icon: Icons.done_rounded,
                fullWidth: false,
                onPressed:
                    canEdit && reminder.status == TripReminderStatus.pending
                        ? onComplete
                        : null,
              ),
              OceanSecondaryButton(
                label: l10n.reminderCancelAction,
                icon: Icons.cancel_rounded,
                fullWidth: false,
                onPressed:
                    canEdit && reminder.status == TripReminderStatus.pending
                        ? onCancel
                        : null,
              ),
              OceanSecondaryButton(
                label: l10n.reminderDeleteAction,
                icon: Icons.delete_rounded,
                fullWidth: false,
                onPressed: canEdit ? onDelete : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteEditor extends StatefulWidget {
  final Trip trip;
  final TripNote? note;

  const _NoteEditor({required this.trip, this.note});

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _photoUrl;
  late TripNoteType _type;
  TripMood? _mood;
  int? _day;
  int? _itemId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _title = TextEditingController(text: note?.title ?? '');
    _content = TextEditingController(text: note?.content ?? '');
    _photoUrl = TextEditingController(text: note?.photoUrl ?? '');
    _type = note?.noteType ?? TripNoteType.note;
    _mood = note?.mood;
    _day = note?.tripDayId;
    _itemId = note?.tripItemId;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final note = widget.note;
    final items = app.timeline
        .where((item) => item.tripId == widget.trip.id)
        .toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              note == null ? l10n.notesAddAction : l10n.notesEditAction,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('note-title-field'),
              controller: _title,
              decoration: InputDecoration(labelText: l10n.notesTitleLabel),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('note-content-field'),
              controller: _content,
              decoration: InputDecoration(labelText: l10n.notesContentLabel),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('note-photo-url-field'),
              controller: _photoUrl,
              decoration: InputDecoration(labelText: l10n.notesPhotoUrlLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
            _EnumDropdown<TripNoteType>(
              label: l10n.notesTypeLabel,
              value: _type,
              values: TripNoteType.values,
              labelFor: (value) => noteTypeLabel(l10n, value),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _EnumDropdown<TripMood>(
              label: l10n.notesMoodLabel,
              value: _mood,
              values: TripMood.values,
              labelFor: (value) => moodLabel(l10n, value),
              onChanged: (value) => setState(() => _mood = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<int?>(
              initialValue: _day,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.notesLinkedDayLabel),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.walletFilterAll),
                ),
                for (var day = 1; day <= widget.trip.days; day++)
                  DropdownMenuItem<int?>(
                    value: day,
                    child: Text(l10n.tripDayCount(day)),
                  ),
              ],
              onChanged: (value) => setState(() => _day = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<int?>(
              initialValue: _itemId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.notesLinkedItemLabel),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.walletFilterAll),
                ),
                for (final item in items)
                  DropdownMenuItem<int?>(
                    value: item.id,
                    child: Text(item.title, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _itemId = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            OceanPrimaryButton(
              key: const Key('note-save'),
              label: l10n.walletSaveAction,
              icon: Icons.save_rounded,
              onPressed: _saving
                  ? null
                  : () {
                      setState(() => _saving = true);
                      final timestamp = app.now();
                      final draft = TripNote(
                        id: note?.id ??
                            'note-local-${timestamp.microsecondsSinceEpoch}',
                        tripPlanId: widget.trip.id,
                        tripDayId: _day,
                        tripItemId: _itemId,
                        authorUserId:
                            note?.authorUserId ?? app.currentDemoUser.id,
                        authorUserName: note?.authorUserName ??
                            app.currentDemoUser.fullName,
                        noteType: _type,
                        title: _title.text,
                        content: _content.text,
                        mood: _mood,
                        photoUrl: _photoUrl.text,
                        pinned: note?.pinned ?? false,
                        createdAt: note?.createdAt ?? timestamp,
                        updatedAt: timestamp,
                      );
                      final result = note == null
                          ? app.addTripNote(draft)
                          : app.updateTripNote(draft);
                      Navigator.pop(context, result);
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            OceanSecondaryButton(
              label: l10n.profileCancel,
              icon: Icons.close_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackingEditor extends StatefulWidget {
  final Trip trip;
  final PackingItem? item;

  const _PackingEditor({required this.trip, this.item});

  @override
  State<_PackingEditor> createState() => _PackingEditorState();
}

class _PackingEditorState extends State<_PackingEditor> {
  late final TextEditingController _label;
  late final TextEditingController _quantity;
  late final TextEditingController _notes;
  late PackingCategory _category;
  String? _assigneeId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _label = TextEditingController(text: item?.label ?? '');
    _quantity = TextEditingController(text: '${item?.quantity ?? 1}');
    _notes = TextEditingController(text: item?.notes ?? '');
    _category = item?.category ?? PackingCategory.documents;
    _assigneeId = item?.assignedToUserId;
  }

  @override
  void dispose() {
    _label.dispose();
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    final assignees = [
      (widget.trip.ownerUserId, widget.trip.ownerName),
      for (final collaborator in app.activeCollaboratorsForTrip(widget.trip.id))
        (collaborator.userId, collaborator.userFullName),
    ];
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item == null ? l10n.packingAddAction : l10n.packingEditAction,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('packing-label-field'),
              controller: _label,
              decoration: InputDecoration(labelText: l10n.packingLabelField),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('packing-quantity-field'),
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.packingQuantityField),
            ),
            const SizedBox(height: AppSpacing.sm),
            _EnumDropdown<PackingCategory>(
              label: l10n.packingCategoryLabel,
              value: _category,
              values: PackingCategory.values,
              labelFor: (value) => packingCategoryLabel(l10n, value),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String?>(
              initialValue: _assigneeId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.packingAssigneeLabel),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.packingUnassignedLabel),
                ),
                for (final assignee in assignees)
                  DropdownMenuItem<String?>(
                    value: assignee.$1,
                    child: Text(assignee.$2),
                  ),
              ],
              onChanged: (value) => setState(() => _assigneeId = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notes,
              decoration: InputDecoration(labelText: l10n.packingNotesField),
            ),
            const SizedBox(height: AppSpacing.lg),
            OceanPrimaryButton(
              key: const Key('packing-save'),
              label: l10n.walletSaveAction,
              icon: Icons.save_rounded,
              onPressed: _saving
                  ? null
                  : () {
                      setState(() => _saving = true);
                      final timestamp = app.now();
                      final draft = PackingItem(
                        id: item?.id ??
                            'packing-local-${timestamp.microsecondsSinceEpoch}',
                        tripPlanId: widget.trip.id,
                        label: _label.text,
                        category: _category,
                        quantity: int.tryParse(_quantity.text.trim()) ?? 0,
                        checked: item?.checked ?? false,
                        assignedToUserId: _assigneeId,
                        notes: _notes.text,
                        sortOrder: item?.sortOrder ??
                            app.packingForTrip(widget.trip.id).length,
                        createdAt: item?.createdAt ?? timestamp,
                        updatedAt: timestamp,
                        checkedAt: item?.checkedAt,
                      );
                      final result = item == null
                          ? app.addPackingItem(draft)
                          : app.updatePackingItem(draft);
                      Navigator.pop(context, result);
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            OceanSecondaryButton(
              label: l10n.profileCancel,
              icon: Icons.close_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderEditor extends StatefulWidget {
  final Trip trip;
  final TripReminder? reminder;

  const _ReminderEditor({required this.trip, this.reminder});

  @override
  State<_ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<_ReminderEditor> {
  late final TextEditingController _title;
  late final TextEditingController _message;
  late final TextEditingController _reminderAt;
  late TripReminderType _type;
  int? _day;
  int? _itemId;
  String? _documentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    final defaultAt = DateTime(
      widget.trip.startDate.year,
      widget.trip.startDate.month,
      widget.trip.startDate.day,
      9,
    );
    _title = TextEditingController(text: reminder?.title ?? '');
    _message = TextEditingController(text: reminder?.message ?? '');
    _reminderAt = TextEditingController(
      text: DateFormat('yyyy-MM-dd HH:mm')
          .format((reminder?.reminderAt ?? defaultAt).toLocal()),
    );
    _type = reminder?.reminderType ?? TripReminderType.custom;
    _day = reminder?.tripDayId;
    _itemId = reminder?.tripItemId;
    _documentId = reminder?.documentId;
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _reminderAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final reminder = widget.reminder;
    final items = app.timeline
        .where((item) => item.tripId == widget.trip.id)
        .toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    final documents = app.documentsForTrip(widget.trip.id);
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              reminder == null
                  ? l10n.remindersAddAction
                  : l10n.remindersEditAction,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('reminder-title-field'),
              controller: _title,
              decoration: InputDecoration(labelText: l10n.reminderTitleField),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _message,
              decoration: InputDecoration(labelText: l10n.reminderMessageField),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('reminder-at-field'),
              controller: _reminderAt,
              decoration: InputDecoration(
                labelText: l10n.reminderAtField,
                helperText: l10n.reminderLocalTimeHelper,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _EnumDropdown<TripReminderType>(
              label: l10n.reminderTypeLabel,
              value: _type,
              values: TripReminderType.values,
              labelFor: (value) => reminderTypeLabel(l10n, value),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<int?>(
              initialValue: _day,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.notesLinkedDayLabel),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.walletFilterAll),
                ),
                for (var day = 1; day <= widget.trip.days; day++)
                  DropdownMenuItem<int?>(
                    value: day,
                    child: Text(l10n.tripDayCount(day)),
                  ),
              ],
              onChanged: (value) => setState(() => _day = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<int?>(
              initialValue: _itemId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.notesLinkedItemLabel),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.walletFilterAll),
                ),
                for (final item in items)
                  DropdownMenuItem<int?>(
                    value: item.id,
                    child: Text(item.title, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _itemId = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String?>(
              initialValue: _documentId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.tripDocumentsTitle),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.walletFilterAll),
                ),
                for (final document in documents)
                  DropdownMenuItem<String?>(
                    value: document.id,
                    child:
                        Text(document.title, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _documentId = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            OceanPrimaryButton(
              key: const Key('reminder-save'),
              label: l10n.walletSaveAction,
              icon: Icons.save_rounded,
              onPressed: _saving
                  ? null
                  : () {
                      setState(() => _saving = true);
                      final timestamp = app.now();
                      final parsed =
                          DateFormat('yyyy-MM-dd HH:mm').tryParseStrict(
                        _reminderAt.text.trim(),
                      );
                      if (parsed == null) {
                        Navigator.pop(
                          context,
                          TripToolActionResult.invalidDate,
                        );
                        return;
                      }
                      final draft = TripReminder(
                        id: reminder?.id ??
                            'reminder-local-${timestamp.microsecondsSinceEpoch}',
                        tripPlanId: widget.trip.id,
                        tripDayId: _day,
                        tripItemId: _itemId,
                        documentId: _documentId,
                        userId: reminder?.userId ?? app.currentDemoUser.id,
                        userName:
                            reminder?.userName ?? app.currentDemoUser.fullName,
                        reminderType: _type,
                        title: _title.text,
                        message: _message.text,
                        reminderAt: parsed.toUtc(),
                        status: reminder?.status ?? TripReminderStatus.pending,
                        createdAt: reminder?.createdAt ?? timestamp,
                        updatedAt: timestamp,
                        completedAt: reminder?.completedAt,
                      );
                      final result = reminder == null
                          ? app.addTripReminder(draft)
                          : app.updateTripReminder(draft);
                      Navigator.pop(context, result);
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            OceanSecondaryButton(
              label: l10n.profileCancel,
              icon: Icons.close_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final TripCollaboratorRole value;
  final ValueChanged<TripCollaboratorRole?>? onChanged;

  const _RoleDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<TripCollaboratorRole>(
      key: const Key('collaboration-role-field'),
      initialValue: value,
      isExpanded: true,
      decoration:
          InputDecoration(labelText: l10n.collaborationChangeRoleAction),
      items: [
        for (final role in TripCollaboratorRole.values)
          DropdownMenuItem(
            value: role,
            child: Text(collaboratorRoleLabel(l10n, role)),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T?> onChanged;

  const _EnumDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem<T?>(
            value: null,
            child: Text(AppLocalizations.of(context)!.walletFilterAll),
          ),
          for (final value in values)
            DropdownMenuItem<T?>(
              value: value,
              child: Text(labelFor(value), overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      );
}

extension _TripNoteTitle on TripNote {
  String get titleOrContent => title.isEmpty ? content : title;
}

String permissionLabel(AppLocalizations l10n, TripPermission permission) {
  switch (permission) {
    case TripPermission.owner:
      return l10n.collaborationOwnerRole;
    case TripPermission.editor:
      return l10n.collaborationRoleEditor;
    case TripPermission.viewer:
      return l10n.collaborationRoleViewer;
    case TripPermission.noAccess:
      return l10n.tripCompanionNoAccessRole;
  }
}

String collaboratorRoleLabel(AppLocalizations l10n, TripCollaboratorRole role) {
  switch (role) {
    case TripCollaboratorRole.viewer:
      return l10n.collaborationRoleViewer;
    case TripCollaboratorRole.editor:
      return l10n.collaborationRoleEditor;
  }
}

String noteTypeLabel(AppLocalizations l10n, TripNoteType type) {
  switch (type) {
    case TripNoteType.note:
      return l10n.noteTypeNote;
    case TripNoteType.journal:
      return l10n.noteTypeJournal;
    case TripNoteType.reminder:
      return l10n.noteTypeReminder;
    case TripNoteType.idea:
      return l10n.noteTypeIdea;
    case TripNoteType.memory:
      return l10n.noteTypeMemory;
  }
}

String moodLabel(AppLocalizations l10n, TripMood mood) {
  switch (mood) {
    case TripMood.happy:
      return l10n.moodHappy;
    case TripMood.excited:
      return l10n.moodExcited;
    case TripMood.calm:
      return l10n.moodCalm;
    case TripMood.tired:
      return l10n.moodTired;
    case TripMood.stressed:
      return l10n.moodStressed;
    case TripMood.neutral:
      return l10n.moodNeutral;
  }
}

String packingCategoryLabel(AppLocalizations l10n, PackingCategory category) {
  switch (category) {
    case PackingCategory.documents:
      return l10n.packingCategoryDocuments;
    case PackingCategory.clothes:
      return l10n.packingCategoryClothes;
    case PackingCategory.toiletries:
      return l10n.packingCategoryToiletries;
    case PackingCategory.electronics:
      return l10n.packingCategoryElectronics;
    case PackingCategory.medicine:
      return l10n.packingCategoryMedicine;
    case PackingCategory.money:
      return l10n.packingCategoryMoney;
    case PackingCategory.food:
      return l10n.packingCategoryFood;
    case PackingCategory.baby:
      return l10n.packingCategoryBaby;
    case PackingCategory.pet:
      return l10n.packingCategoryPet;
    case PackingCategory.other:
      return l10n.packingCategoryOther;
  }
}

String reminderTypeLabel(AppLocalizations l10n, TripReminderType type) {
  switch (type) {
    case TripReminderType.custom:
      return l10n.reminderTypeCustom;
    case TripReminderType.document:
      return l10n.reminderTypeDocument;
    case TripReminderType.checkIn:
      return l10n.reminderTypeCheckIn;
    case TripReminderType.flight:
      return l10n.reminderTypeFlight;
    case TripReminderType.activity:
      return l10n.reminderTypeActivity;
    case TripReminderType.payment:
      return l10n.reminderTypePayment;
    case TripReminderType.packing:
      return l10n.reminderTypePacking;
    case TripReminderType.other:
      return l10n.reminderTypeOther;
  }
}

String reminderStatusLabel(AppLocalizations l10n, TripReminderStatus status) {
  switch (status) {
    case TripReminderStatus.pending:
      return l10n.reminderStatusPending;
    case TripReminderStatus.completed:
      return l10n.reminderStatusCompleted;
    case TripReminderStatus.cancelled:
      return l10n.reminderStatusCancelled;
  }
}

String tripToolResultMessage(
  BuildContext context,
  TripToolActionResult result,
) {
  final l10n = AppLocalizations.of(context)!;
  switch (result) {
    case TripToolActionResult.success:
      return l10n.tripToolSavedMessage;
    case TripToolActionResult.unavailable:
      return l10n.tripToolUnavailableMessage;
    case TripToolActionResult.forbidden:
      return l10n.tripToolForbiddenMessage;
    case TripToolActionResult.blank:
      return l10n.tripToolBlankMessage;
    case TripToolActionResult.invalidEmail:
      return l10n.tripToolInvalidEmailMessage;
    case TripToolActionResult.duplicate:
      return l10n.tripToolDuplicateMessage;
    case TripToolActionResult.rejected:
      return l10n.tripToolRejectedMessage;
    case TripToolActionResult.unsafeUrl:
      return l10n.tripToolUnsafeUrlMessage;
    case TripToolActionResult.notFound:
      return l10n.tripToolNotFoundMessage;
    case TripToolActionResult.invalidQuantity:
      return l10n.tripToolInvalidQuantityMessage;
    case TripToolActionResult.invalidReorder:
      return l10n.tripToolInvalidReorderMessage;
    case TripToolActionResult.invalidDate:
      return l10n.tripToolInvalidDateMessage;
  }
}

Color _reminderStatusColor(TripReminderStatus status) {
  switch (status) {
    case TripReminderStatus.pending:
      return AppColors.ocean;
    case TripReminderStatus.completed:
      return AppColors.success;
    case TripReminderStatus.cancelled:
      return AppColors.textTertiary;
  }
}
