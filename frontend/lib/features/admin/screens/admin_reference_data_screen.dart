import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_reference_states.dart';
import '../widgets/admin_widgets.dart';

/// D10 — Admin Reference Data: amenities and categories, in one destination.
///
/// <h4>What the backend offers, and therefore what this screen offers</h4>
///
/// `AdminAmenityController` and `AdminCategoryController` expose exactly four
/// operations each: list, create, update, and set a boolean `active`. **There
/// is no delete endpoint** — not for admins, not for anyone — so this screen
/// renders no delete control, no archive action and no wording that implies
/// a row can be removed.
///
/// <h4>What `active` actually does</h4>
///
/// Nothing, downstream. `Amenity.active`, `Category.active` and
/// `AdministrativeUnit.active` are read in exactly one place in the backend —
/// the response mappers — and no query, specification or service filters on
/// them. `GET /api/amenities` and `GET /api/categories` return inactive rows to
/// the public just the same. The flag is therefore presented as **CMS status**
/// and every surface that mentions it says so; nothing here claims a customer-
/// facing effect the server does not deliver.
class AdminReferenceDataScreen extends StatefulWidget {
  final AdminAmenitiesState amenities;
  final AdminCategoriesState categories;
  final AdminLocationsState locations;

  /// Which tab opens first. Exists so a test can target any tab directly
  /// without driving a gesture.
  final int initialTab;

  const AdminReferenceDataScreen({
    super.key,
    required this.amenities,
    required this.categories,
    required this.locations,
    this.initialTab = 0,
  });

  @override
  State<AdminReferenceDataScreen> createState() =>
      _AdminReferenceDataScreenState();
}

class _AdminReferenceDataScreenState extends State<AdminReferenceDataScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 2),
  )..addListener(_onTabChanged);

  @override
  void initState() {
    super.initState();
    // Each tab loads the first time it is shown, never both at once. Deferred
    // past the frame because load() notifies, and notifying while the tree is
    // still building is the defect this convention exists to avoid.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCurrentTab();
    });
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    setState(_loadCurrentTab);
  }

  /// Idle-guarded, so returning to a tab keeps its rows instead of refetching.
  ///
  /// Written as a branch rather than a shared variable: the three notifiers
  /// have different type arguments, so their least upper bound is
  /// `ChangeNotifier` and a common variable would need a cast that buys
  /// nothing.
  void _loadCurrentTab() {
    switch (_tabs.index) {
      case 0:
        if (widget.amenities.status == AdminLoadStatus.idle) {
          widget.amenities.load();
        }
      case 1:
        if (widget.categories.status == AdminLoadStatus.idle) {
          widget.categories.load();
        }
      default:
        if (widget.locations.status == AdminLoadStatus.idle) {
          widget.locations.load();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: _CmsScopeNotice(),
        ),
        TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.adminReferenceTabAmenities),
            Tab(text: l10n.adminReferenceTabCategories),
            Tab(text: l10n.adminReferenceTabLocations),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _AmenitiesTab(state: widget.amenities),
              _CategoriesTab(state: widget.categories),
              _LocationsTab(state: widget.locations),
            ],
          ),
        ),
      ],
    );
  }
}

/// The two statements an operator has to be able to read before touching
/// anything here: the status flag is CMS-only, and nothing can be deleted.
class _CmsScopeNotice extends StatelessWidget {
  const _CmsScopeNotice();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      key: const Key('admin-reference-cms-notice'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminReferenceCmsStatusNotice,
                    style: theme.textTheme.labelSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(l10n.adminReferenceNoDeleteNotice,
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared chrome
// ═══════════════════════════════════════════════════════════════════════════

/// Banner for the outcome of the last mutation.
///
/// `uncertain` is kept visually distinct from a plain failure: the write may
/// have committed, so the remedy is "look at the list", never "press it again".
class _MutationBanner extends StatelessWidget {
  final AdminReferenceListState<Object?> state;

  /// Shown for a 409 whose server message did not survive sanitisation.
  /// Amenities and categories have one conflict axis, so the default names the
  /// slug; locations have two, so that tab supplies its own wording rather than
  /// blaming a field the operator may not have touched.
  final String? conflictLabel;

  const _MutationBanner({required this.state, this.conflictLabel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final uncertain = state.mutationUncertain;
    final conflict = state.mutationConflict;
    final error = state.mutationError;
    if (!uncertain && !conflict && error == null) {
      return const SizedBox.shrink();
    }

    final scheme = theme.colorScheme;
    final background =
        uncertain ? scheme.tertiaryContainer : scheme.errorContainer;
    final foreground =
        uncertain ? scheme.onTertiaryContainer : scheme.onErrorContainer;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Container(
        key: const Key('admin-reference-mutation-banner'),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(uncertain ? Icons.help_outline : Icons.error_outline_rounded,
                size: 18, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                uncertain
                    ? l10n.adminReferenceMutationUncertain
                    // The backend's own message is the useful one here — a
                    // 409 names the slug that is already taken. The
                    // duplicate-slug string is the fallback for when that
                    // message did not survive sanitisation.
                    : (error ??
                        (conflict
                            ? (conflictLabel ??
                                l10n.adminReferenceDuplicateSlug)
                            : l10n.adminReferenceMutationFailed)),
                style: theme.textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ),
            TextButton(
              onPressed: state.dismissMutationNotice,
              child: Text(l10n.adminReferenceDismiss),
            ),
          ],
        ),
      ),
    );
  }
}

/// Refresh + create, plus the note that the list order is the server's.
class _ReferenceToolbar extends StatelessWidget {
  final AdminReferenceListState<Object?> state;
  final String createLabel;
  final Key createKey;
  final VoidCallback onCreate;

  /// Rendered under the buttons. Only Locations uses it, for its client-side
  /// filter — the other two surfaces hold far fewer rows than the backend's own
  /// search would need to be worth wiring.
  final Widget? extra;

  const _ReferenceToolbar({
    required this.state,
    required this.createLabel,
    required this.createKey,
    required this.onCreate,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = state.isLoading || state.isMutating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              key: createKey,
              onPressed: busy ? null : onCreate,
              icon: const Icon(Icons.add),
              label: Text(createLabel),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : state.refresh,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.adminReferenceRefresh),
            ),
          ],
        ),
        if (extra != null) ...[
          const SizedBox(height: AppSpacing.xs),
          extra!,
        ],
        const SizedBox(height: AppSpacing.xxs),
        // The backend applies no ordering and never uses `sortOrder` to sort,
        // so the rows arrive in whatever order the database returned. Said
        // plainly rather than hidden behind a client-side re-sort that would
        // only look authoritative.
        Text(l10n.adminReferenceOrderingNotice,
            style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// The CMS-status pill. Colour is always paired with text, never the only cue.
class _CmsStatusChip extends StatelessWidget {
  final bool active;

  const _CmsStatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              active ? Icons.check_circle_outline : Icons.remove_circle_outline,
              size: 14,
              color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            active
                ? l10n.adminReferenceStatusActive
                : l10n.adminReferenceStatusInactive,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Confirmation for a CMS-status change.
///
/// Both directions are confirmed, and both repeat the CMS-only scope: an
/// operator deactivating a row must not walk away believing customers stopped
/// seeing it.
Future<bool> _confirmStatus(
  BuildContext context, {
  required String name,
  required bool activating,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(activating
          ? l10n.adminReferenceActivateTitle
          : l10n.adminReferenceDeactivateTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activating
                ? l10n.adminReferenceActivateBody(name)
                : l10n.adminReferenceDeactivateBody(name)),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.adminReferenceStatusPublicNotice,
                style: Theme.of(ctx).textTheme.labelSmall),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.adminPartnerCancel),
        ),
        FilledButton(
          key: const Key('admin-reference-status-confirm'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.adminReferenceStatusConfirm),
        ),
      ],
    ),
  );
  return ok == true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Amenities
// ═══════════════════════════════════════════════════════════════════════════

class _AmenitiesTab extends StatelessWidget {
  final AdminAmenitiesState state;

  const _AmenitiesTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final rows = state.items;
        final body = state.isReady && rows.isNotEmpty
            ? AdminResponsiveGrid(
                wide: (context) => _AmenityTable(state: state, rows: rows),
                narrow: (context) => _AmenityCards(state: state, rows: rows),
              )
            : AdminStateView(
                status: state.status,
                message: state.errorMessage,
                emptyMessage: l10n.adminReferenceEmptyAmenities,
                onRetry: state.refresh,
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MutationBanner(state: state),
            Expanded(
              child: AdminGridScaffold(
                isLoading: state.isLoading,
                toolbar: _ReferenceToolbar(
                  state: state,
                  createLabel: l10n.adminReferenceNewAmenity,
                  createKey: const Key('admin-reference-new-amenity'),
                  onCreate: () => _openAmenityForm(context, state, null),
                ),
                body: body,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AmenityTable extends StatelessWidget {
  final AdminAmenitiesState state;
  final List<AdminAmenity> rows;

  const _AmenityTable({required this.state, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.adminReferenceColName)),
            DataColumn(label: Text(l10n.adminReferenceColSlug)),
            DataColumn(label: Text(l10n.adminReferenceColGroup)),
            DataColumn(label: Text(l10n.adminReferenceColSortOrder)),
            DataColumn(label: Text(l10n.adminReferenceColCmsStatus)),
            DataColumn(label: Text(l10n.adminReferenceColAction)),
          ],
          rows: [
            for (final r in rows)
              DataRow(cells: [
                DataCell(Text(AdminFormats.text(context, r.name))),
                DataCell(Text(AdminFormats.text(context, r.slug))),
                DataCell(Text(AdminFormats.text(context, r.groupName))),
                DataCell(
                    Text(r.sortOrder?.toString() ?? l10n.adminValueUnknown)),
                DataCell(_CmsStatusChip(active: r.active)),
                DataCell(_AmenityActions(state: state, row: r, inline: true)),
              ]),
          ],
        ),
      ),
    );
  }
}

class _AmenityCards extends StatelessWidget {
  final AdminAmenitiesState state;
  final List<AdminAmenity> rows;

  const _AmenityCards({required this.state, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final r = rows[i];
        return OceanGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(AdminFormats.text(context, r.name),
                        style: theme.textTheme.titleSmall),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _CmsStatusChip(active: r.active),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AdminCardRow(
                  label: l10n.adminReferenceColSlug,
                  value: AdminFormats.text(context, r.slug)),
              AdminCardRow(
                  label: l10n.adminReferenceColGroup,
                  value: AdminFormats.text(context, r.groupName)),
              AdminCardRow(
                  label: l10n.adminReferenceColSortOrder,
                  value: r.sortOrder?.toString() ?? l10n.adminValueUnknown),
              const SizedBox(height: AppSpacing.xs),
              _AmenityActions(state: state, row: r),
            ],
          ),
        );
      },
    );
  }
}

/// Lays the row actions out for the surface they are on.
///
/// A `DataTable` row has a fixed height: a [Wrap] that flows onto a second line
/// paints outside the row's bounds, which leaves the wrapped control visible but
/// unable to receive a tap. So tables get a single-line [Row] and let the column
/// widen, while the narrow-viewport cards keep the [Wrap] they need for large
/// text scales.
class _ActionBar extends StatelessWidget {
  final bool inline;
  final List<Widget> children;

  const _ActionBar({required this.inline, required this.children});

  @override
  Widget build(BuildContext context) => inline
      ? Row(mainAxisSize: MainAxisSize.min, children: children)
      : Wrap(spacing: AppSpacing.xxs, children: children);
}

class _AmenityActions extends StatelessWidget {
  final AdminAmenitiesState state;
  final AdminAmenity row;
  final bool inline;

  const _AmenityActions({
    required this.state,
    required this.row,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = state.isMutating || state.isLoading;
    final name = row.name ?? l10n.adminValueUnknown;
    return _ActionBar(
      inline: inline,
      children: [
        Semantics(
          button: true,
          label: l10n.adminReferenceEditSemantic(name),
          child: TextButton(
            key: Key('admin-reference-amenity-edit-${row.id}'),
            onPressed:
                busy ? null : () => _openAmenityForm(context, state, row),
            child: Text(l10n.adminReferenceEdit),
          ),
        ),
        TextButton(
          key: Key('admin-reference-amenity-status-${row.id}'),
          onPressed: busy
              ? null
              : () async {
                  final target = !row.active;
                  final ok = await _confirmStatus(context,
                      name: name, activating: target);
                  if (!ok) return;
                  await state.setActive(row, active: target);
                },
          child: Text(row.active
              ? l10n.adminReferenceDeactivate
              : l10n.adminReferenceActivate),
        ),
      ],
    );
  }
}

Future<void> _openAmenityForm(
  BuildContext context,
  AdminAmenitiesState state,
  AdminAmenity? existing,
) async {
  final result = await showDialog<_AmenityFormResult>(
    context: context,
    builder: (ctx) => _AmenityFormDialog(
      existing: existing,
      groupOptions: state.groupOptions(current: existing?.groupName),
    ),
  );
  if (result == null) return;
  if (existing == null) {
    await state.create(
      name: result.name,
      slug: result.slug,
      icon: result.icon,
      groupName: result.groupName,
      description: result.description,
      sortOrder: result.sortOrder,
    );
  } else {
    await state.update(
      existing,
      name: result.name,
      icon: result.icon,
      groupName: result.groupName,
      description: result.description,
      sortOrder: result.sortOrder,
    );
  }
}

class _AmenityFormResult {
  final String name;
  final String? slug;
  final String? icon;
  final String? groupName;
  final String? description;
  final int? sortOrder;

  const _AmenityFormResult({
    required this.name,
    required this.slug,
    required this.icon,
    required this.groupName,
    required this.description,
    required this.sortOrder,
  });
}

/// One form for create and update.
///
/// It offers exactly the six fields `AmenityRequest` carries. Slug is the one
/// asymmetry: editable on create (or left blank for the server to derive), and
/// **read-only** afterwards, because `HotelRoomService` resolves room amenities
/// by slug and silently skips a value it cannot match.
class _AmenityFormDialog extends StatefulWidget {
  final AdminAmenity? existing;
  final List<String> groupOptions;

  const _AmenityFormDialog({
    required this.existing,
    required this.groupOptions,
  });

  @override
  State<_AmenityFormDialog> createState() => _AmenityFormDialogState();
}

class _AmenityFormDialogState extends State<_AmenityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _slug =
      TextEditingController(text: widget.existing?.slug ?? '');
  late final TextEditingController _icon =
      TextEditingController(text: widget.existing?.icon ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final TextEditingController _sortOrder =
      TextEditingController(text: widget.existing?.sortOrder?.toString() ?? '');

  late String? _group = widget.existing?.groupName;

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _icon.dispose();
    _description.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final slug = _slug.text.trim();
    Navigator.of(context).pop(_AmenityFormResult(
      name: _name.text.trim(),
      slug: slug.isEmpty ? null : slug,
      icon: _icon.text.trim().isEmpty ? null : _icon.text.trim(),
      groupName: _group,
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      sortOrder: int.tryParse(_sortOrder.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing
          ? l10n.adminReferenceAmenityEditTitle
          : l10n.adminReferenceAmenityCreateTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NameField(controller: _name),
              const SizedBox(height: AppSpacing.xs),
              _SlugField(controller: _slug, editing: editing),
              const SizedBox(height: AppSpacing.xs),
              _VocabularyPicker(
                label: l10n.adminReferenceFieldGroup,
                value: _group,
                options: widget.groupOptions,
                pickerKey: const Key('admin-reference-group-picker'),
                onChanged: (v) => setState(() => _group = v),
              ),
              const SizedBox(height: AppSpacing.xs),
              _PlainField(
                  controller: _icon, label: l10n.adminReferenceFieldIcon),
              const SizedBox(height: AppSpacing.xs),
              _PlainField(
                  controller: _description,
                  label: l10n.adminReferenceFieldDescription),
              const SizedBox(height: AppSpacing.xs),
              _SortOrderField(controller: _sortOrder),
              if (editing) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.adminReferenceUpdateReplacesNotice,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.adminPartnerCancel),
        ),
        FilledButton(
          key: const Key('admin-reference-form-submit'),
          onPressed: _submit,
          child: Text(
              editing ? l10n.adminReferenceSave : l10n.adminReferenceCreate),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Categories
// ═══════════════════════════════════════════════════════════════════════════

class _CategoriesTab extends StatelessWidget {
  final AdminCategoriesState state;

  const _CategoriesTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final rows = state.items;
        final body = state.isReady && rows.isNotEmpty
            ? AdminResponsiveGrid(
                wide: (context) => _CategoryTable(state: state, rows: rows),
                narrow: (context) => _CategoryCards(state: state, rows: rows),
              )
            : AdminStateView(
                status: state.status,
                message: state.errorMessage,
                emptyMessage: l10n.adminReferenceEmptyCategories,
                onRetry: state.refresh,
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MutationBanner(state: state),
            Expanded(
              child: AdminGridScaffold(
                isLoading: state.isLoading,
                toolbar: _ReferenceToolbar(
                  state: state,
                  createLabel: l10n.adminReferenceNewCategory,
                  createKey: const Key('admin-reference-new-category'),
                  onCreate: () => _openCategoryForm(context, state, null),
                ),
                body: body,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryTable extends StatelessWidget {
  final AdminCategoriesState state;
  final List<AdminCategory> rows;

  const _CategoryTable({required this.state, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.adminReferenceColName)),
            DataColumn(label: Text(l10n.adminReferenceColSlug)),
            DataColumn(label: Text(l10n.adminReferenceColType)),
            DataColumn(label: Text(l10n.adminReferenceColParent)),
            DataColumn(label: Text(l10n.adminReferenceColSortOrder)),
            DataColumn(label: Text(l10n.adminReferenceColCmsStatus)),
            DataColumn(label: Text(l10n.adminReferenceColAction)),
          ],
          rows: [
            for (final r in rows)
              DataRow(cells: [
                DataCell(Text(AdminFormats.text(context, r.name))),
                DataCell(Text(AdminFormats.text(context, r.slug))),
                DataCell(Text(AdminFormats.text(context, r.type))),
                DataCell(Text(r.isRoot
                    ? l10n.adminReferenceParentNone
                    : AdminFormats.text(context, state.parentNameOf(r)))),
                DataCell(
                    Text(r.sortOrder?.toString() ?? l10n.adminValueUnknown)),
                DataCell(_CmsStatusChip(active: r.active)),
                DataCell(_CategoryActions(state: state, row: r, inline: true)),
              ]),
          ],
        ),
      ),
    );
  }
}

class _CategoryCards extends StatelessWidget {
  final AdminCategoriesState state;
  final List<AdminCategory> rows;

  const _CategoryCards({required this.state, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final r = rows[i];
        return OceanGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(AdminFormats.text(context, r.name),
                        style: theme.textTheme.titleSmall),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _CmsStatusChip(active: r.active),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AdminCardRow(
                  label: l10n.adminReferenceColSlug,
                  value: AdminFormats.text(context, r.slug)),
              AdminCardRow(
                  label: l10n.adminReferenceColType,
                  value: AdminFormats.text(context, r.type)),
              AdminCardRow(
                label: l10n.adminReferenceColParent,
                value: r.isRoot
                    ? l10n.adminReferenceParentNone
                    : AdminFormats.text(context, state.parentNameOf(r)),
              ),
              AdminCardRow(
                  label: l10n.adminReferenceColSortOrder,
                  value: r.sortOrder?.toString() ?? l10n.adminValueUnknown),
              const SizedBox(height: AppSpacing.xs),
              _CategoryActions(state: state, row: r),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryActions extends StatelessWidget {
  final AdminCategoriesState state;
  final AdminCategory row;
  final bool inline;

  const _CategoryActions({
    required this.state,
    required this.row,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = state.isMutating || state.isLoading;
    final name = row.name ?? l10n.adminValueUnknown;
    return _ActionBar(
      inline: inline,
      children: [
        Semantics(
          button: true,
          label: l10n.adminReferenceEditSemantic(name),
          child: TextButton(
            key: Key('admin-reference-category-edit-${row.id}'),
            onPressed:
                busy ? null : () => _openCategoryForm(context, state, row),
            child: Text(l10n.adminReferenceEdit),
          ),
        ),
        TextButton(
          key: Key('admin-reference-category-status-${row.id}'),
          onPressed: busy
              ? null
              : () async {
                  final target = !row.active;
                  final ok = await _confirmStatus(context,
                      name: name, activating: target);
                  if (!ok) return;
                  await state.setActive(row, active: target);
                },
          child: Text(row.active
              ? l10n.adminReferenceDeactivate
              : l10n.adminReferenceActivate),
        ),
      ],
    );
  }
}

Future<void> _openCategoryForm(
  BuildContext context,
  AdminCategoriesState state,
  AdminCategory? existing,
) async {
  final result = await showDialog<_CategoryFormResult>(
    context: context,
    builder: (ctx) => _CategoryFormDialog(
      existing: existing,
      typeOptions: state.typeOptions(current: existing?.type),
      parentOptions: state.parentOptions(editing: existing),
    ),
  );
  if (result == null) return;
  if (existing == null) {
    await state.create(
      name: result.name,
      slug: result.slug,
      parentId: result.parentId,
      type: result.type,
      icon: result.icon,
      color: result.color,
      coverImageUrl: result.coverImageUrl,
      sortOrder: result.sortOrder,
    );
  } else {
    await state.update(
      existing,
      name: result.name,
      parentId: result.parentId,
      type: result.type,
      icon: result.icon,
      color: result.color,
      coverImageUrl: result.coverImageUrl,
      sortOrder: result.sortOrder,
    );
  }
}

class _CategoryFormResult {
  final String name;
  final String? slug;
  final int? parentId;
  final String? type;
  final String? icon;
  final String? color;
  final String? coverImageUrl;
  final int? sortOrder;

  const _CategoryFormResult({
    required this.name,
    required this.slug,
    required this.parentId,
    required this.type,
    required this.icon,
    required this.color,
    required this.coverImageUrl,
    required this.sortOrder,
  });
}

/// One form for create and update.
///
/// It offers exactly the eight fields `CategoryRequest` carries — `color`
/// included. `CategoryService.fill` assigns every column from the request, so a
/// field this form omitted would be written as null on every save.
class _CategoryFormDialog extends StatefulWidget {
  final AdminCategory? existing;
  final List<String> typeOptions;
  final List<AdminCategory> parentOptions;

  const _CategoryFormDialog({
    required this.existing,
    required this.typeOptions,
    required this.parentOptions,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _slug =
      TextEditingController(text: widget.existing?.slug ?? '');
  late final TextEditingController _icon =
      TextEditingController(text: widget.existing?.icon ?? '');
  late final TextEditingController _color =
      TextEditingController(text: widget.existing?.color ?? '');
  late final TextEditingController _coverImageUrl =
      TextEditingController(text: widget.existing?.coverImageUrl ?? '');
  late final TextEditingController _sortOrder =
      TextEditingController(text: widget.existing?.sortOrder?.toString() ?? '');

  late String? _type = widget.existing?.type;

  /// The stored parent is preserved only when it is still an offerable option.
  /// A parent that has become a descendant (data already containing a cycle)
  /// would otherwise be a dropdown value with no matching item, which throws.
  late int? _parentId =
      widget.parentOptions.any((c) => c.id == widget.existing?.parentId)
          ? widget.existing?.parentId
          : null;

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _icon.dispose();
    _color.dispose();
    _coverImageUrl.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    String? trimmed(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? null : t;
    }

    Navigator.of(context).pop(_CategoryFormResult(
      name: _name.text.trim(),
      slug: trimmed(_slug),
      parentId: _parentId,
      type: _type,
      icon: trimmed(_icon),
      color: trimmed(_color),
      coverImageUrl: trimmed(_coverImageUrl),
      sortOrder: int.tryParse(_sortOrder.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing
          ? l10n.adminReferenceCategoryEditTitle
          : l10n.adminReferenceCategoryCreateTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NameField(controller: _name),
              const SizedBox(height: AppSpacing.xs),
              _SlugField(controller: _slug, editing: editing),
              const SizedBox(height: AppSpacing.xs),
              _VocabularyPicker(
                label: l10n.adminReferenceFieldType,
                value: _type,
                options: widget.typeOptions,
                pickerKey: const Key('admin-reference-type-picker'),
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.adminReferenceTypeNotice,
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                container: true,
                explicitChildNodes: true,
                label: l10n.adminReferenceFieldParent,
                child: DropdownButtonFormField<int?>(
                  key: const Key('admin-reference-parent-picker'),
                  initialValue: _parentId,
                  isExpanded: true,
                  decoration: InputDecoration(
                      labelText: l10n.adminReferenceFieldParent),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.adminReferenceParentNone),
                    ),
                    for (final c in widget.parentOptions)
                      DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name ?? '#${c.id}',
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _parentId = v),
                ),
              ),
              if (editing) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(l10n.adminReferenceParentGuardNotice,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
              const SizedBox(height: AppSpacing.xs),
              _PlainField(
                  controller: _icon, label: l10n.adminReferenceFieldIcon),
              const SizedBox(height: AppSpacing.xs),
              _PlainField(
                  controller: _color, label: l10n.adminReferenceFieldColor),
              const SizedBox(height: AppSpacing.xs),
              _PlainField(
                  controller: _coverImageUrl,
                  label: l10n.adminReferenceFieldCoverImageUrl),
              const SizedBox(height: AppSpacing.xs),
              _SortOrderField(controller: _sortOrder),
              if (editing) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.adminReferenceUpdateReplacesNotice,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.adminPartnerCancel),
        ),
        FilledButton(
          key: const Key('admin-reference-form-submit'),
          onPressed: _submit,
          child: Text(
              editing ? l10n.adminReferenceSave : l10n.adminReferenceCreate),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Locations
// ═══════════════════════════════════════════════════════════════════════════
//
// `AdministrativeUnit` on the backend; **Location** everywhere a person reads
// it. Nothing is renamed on either side.
//
// Six fields are editable — name, code, type, parent, oldName, sortOrder.
// Everything else the row carries is shown read-only and echoed back on save,
// because `PUT` is a full replace:
//
//  * `fullPath` — customer-visible through `PlaceDto.LocationRef`, and derived
//    by the server from the parent and name on every write, so the form
//    previews it and never edits it;
//  * `level` — derived from nothing, validated against nothing;
//  * `latitude`/`longitude` — no range or pairing validation.
//
// The type and parent pickers mirror the backend hierarchy (D13), so a
// combination the backend would refuse is not offered and cannot be submitted.
// The backend stays the authority and re-validates every write.

class _LocationsTab extends StatelessWidget {
  final AdminLocationsState state;

  const _LocationsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final rows = state.visibleItems;
        final body = state.isReady && rows.isNotEmpty
            ? AdminResponsiveGrid(
                wide: (context) => _LocationTable(state: state, rows: rows),
                narrow: (context) => _LocationCards(state: state, rows: rows),
              )
            : AdminStateView(
                status: state.status,
                message: state.errorMessage,
                // "No match for this search" and "no locations exist" are
                // different facts, and neither is ever shown for a failure.
                emptyMessage: state.isFilteredEmpty
                    ? l10n.adminLocationFilterEmpty
                    : l10n.adminLocationEmpty,
                onRetry: state.refresh,
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MutationBanner(
              state: state,
              conflictLabel: l10n.adminLocationDuplicateCodeOrSlug,
            ),
            Expanded(
              child: AdminGridScaffold(
                isLoading: state.isLoading,
                toolbar: _ReferenceToolbar(
                  state: state,
                  createLabel: l10n.adminLocationNew,
                  createKey: const Key('admin-reference-new-location'),
                  onCreate: () => _openLocationForm(context, state, null),
                  extra: _LocationFilterField(state: state),
                ),
                body: body,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Client-side only: the admin list endpoint takes no search parameter, so
/// filtering happens over rows already held rather than pretending to query.
class _LocationFilterField extends StatefulWidget {
  final AdminLocationsState state;

  const _LocationFilterField({required this.state});

  @override
  State<_LocationFilterField> createState() => _LocationFilterFieldState();
}

class _LocationFilterFieldState extends State<_LocationFilterField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.state.filter);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      textField: true,
      label: l10n.adminLocationFilterLabel,
      child: TextField(
        key: const Key('admin-reference-location-filter'),
        controller: _controller,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search),
          labelText: l10n.adminLocationFilterLabel,
          helperText: l10n.adminLocationFilterHelper,
          helperMaxLines: 2,
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: l10n.adminLocationFilterClear,
                  onPressed: () {
                    _controller.clear();
                    widget.state.clearFilter();
                    setState(() {});
                  },
                ),
        ),
        onChanged: (v) {
          widget.state.setFilter(v);
          setState(() {});
        },
      ),
    );
  }
}

String _coordinatesLabel(BuildContext context, AdminLocation row) {
  final l10n = AppLocalizations.of(context)!;
  if (!row.hasCoordinates) return l10n.adminValueUnknown;
  return '${row.latitude!.toStringAsFixed(4)}, '
      '${row.longitude!.toStringAsFixed(4)}';
}

String _parentLabel(
    BuildContext context, AdminLocationsState state, AdminLocation row) {
  final l10n = AppLocalizations.of(context)!;
  if (row.isRoot) return l10n.adminReferenceParentNone;
  return state.parentNameOf(row) ?? '#${row.parentId}';
}

class _LocationTable extends StatelessWidget {
  final AdminLocationsState state;
  final List<AdminLocation> rows;

  const _LocationTable({required this.state, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.adminReferenceColName)),
            DataColumn(label: Text(l10n.adminLocationColCode)),
            DataColumn(label: Text(l10n.adminReferenceColSlug)),
            DataColumn(label: Text(l10n.adminReferenceColType)),
            DataColumn(label: Text(l10n.adminReferenceColParent)),
            DataColumn(label: Text(l10n.adminLocationColLevel)),
            DataColumn(label: Text(l10n.adminLocationColCoordinates)),
            DataColumn(label: Text(l10n.adminReferenceColCmsStatus)),
            DataColumn(label: Text(l10n.adminReferenceColAction)),
          ],
          rows: [
            for (final r in rows)
              DataRow(cells: [
                DataCell(Text(AdminFormats.text(context, r.name))),
                DataCell(Text(AdminFormats.text(context, r.code))),
                DataCell(Text(AdminFormats.text(context, r.slug))),
                DataCell(Text(AdminFormats.text(context, r.type))),
                DataCell(Text(_parentLabel(context, state, r))),
                DataCell(Text(r.level?.toString() ?? l10n.adminValueUnknown)),
                DataCell(Text(_coordinatesLabel(context, r))),
                DataCell(_CmsStatusChip(active: r.active)),
                DataCell(_LocationActions(state: state, row: r, inline: true)),
              ]),
          ],
        ),
      ),
    );
  }
}

class _LocationCards extends StatelessWidget {
  final AdminLocationsState state;
  final List<AdminLocation> rows;

  const _LocationCards({required this.state, required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final r = rows[i];
        return OceanGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(AdminFormats.text(context, r.name),
                        style: theme.textTheme.titleSmall),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _CmsStatusChip(active: r.active),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AdminCardRow(
                  label: l10n.adminLocationColCode,
                  value: AdminFormats.text(context, r.code)),
              AdminCardRow(
                  label: l10n.adminReferenceColSlug,
                  value: AdminFormats.text(context, r.slug)),
              AdminCardRow(
                  label: l10n.adminReferenceColType,
                  value: AdminFormats.text(context, r.type)),
              AdminCardRow(
                  label: l10n.adminReferenceColParent,
                  value: _parentLabel(context, state, r)),
              AdminCardRow(
                  label: l10n.adminLocationColLevel,
                  value: r.level?.toString() ?? l10n.adminValueUnknown),
              AdminCardRow(
                  label: l10n.adminLocationColCoordinates,
                  value: _coordinatesLabel(context, r)),
              const SizedBox(height: AppSpacing.xs),
              _LocationActions(state: state, row: r),
            ],
          ),
        );
      },
    );
  }
}

class _LocationActions extends StatelessWidget {
  final AdminLocationsState state;
  final AdminLocation row;
  final bool inline;

  const _LocationActions({
    required this.state,
    required this.row,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = state.isMutating || state.isLoading;
    final name = row.name ?? l10n.adminValueUnknown;
    return _ActionBar(
      inline: inline,
      children: [
        Semantics(
          button: true,
          label: l10n.adminReferenceEditSemantic(name),
          child: TextButton(
            key: Key('admin-reference-location-edit-${row.id}'),
            onPressed:
                busy ? null : () => _openLocationForm(context, state, row),
            child: Text(l10n.adminReferenceEdit),
          ),
        ),
        TextButton(
          key: Key('admin-reference-location-status-${row.id}'),
          onPressed: busy
              ? null
              : () async {
                  final target = !row.active;
                  final ok = await _confirmStatus(context,
                      name: name, activating: target);
                  if (!ok) return;
                  await state.setActive(row, active: target);
                },
          child: Text(row.active
              ? l10n.adminReferenceDeactivate
              : l10n.adminReferenceActivate),
        ),
      ],
    );
  }
}

Future<void> _openLocationForm(
  BuildContext context,
  AdminLocationsState state,
  AdminLocation? existing,
) async {
  final result = await showDialog<_LocationFormResult>(
    context: context,
    builder: (ctx) => _LocationFormDialog(existing: existing, state: state),
  );
  if (result == null) return;
  if (existing == null) {
    await state.create(
      name: result.name,
      type: result.type,
      parentId: result.parentId,
      slug: result.slug,
      code: result.code,
      oldName: result.oldName,
      fullPath: result.fullPath,
      sortOrder: result.sortOrder,
    );
  } else {
    await state.update(
      existing,
      name: result.name,
      type: result.type,
      parentId: result.parentId,
      code: result.code,
      oldName: result.oldName,
      sortOrder: result.sortOrder,
    );
  }
}

class _LocationFormResult {
  final String name;
  final String type;
  final int? parentId;
  final String? slug;
  final String? code;
  final String? oldName;
  final String? fullPath;
  final int? sortOrder;

  const _LocationFormResult({
    required this.name,
    required this.type,
    required this.parentId,
    required this.slug,
    required this.code,
    required this.oldName,
    required this.fullPath,
    required this.sortOrder,
  });
}

/// One form for create and update.
///
/// The type picker decides which parents are offered, and the parent picker
/// offers exactly those: "top level" for a COUNTRY and nothing else, compatible
/// well-formed locations for every other type. A type change the chosen parent
/// cannot hold clears the parent and says so, rather than leaving a combination
/// the backend would refuse. WARD and COMMUNE are listed, disabled, because the
/// enum declares them; they have no place in the hierarchy.
///
/// Every hierarchy question is answered by [AdminLocationsState] from the rows
/// already loaded — the form issues no request of its own.
class _LocationFormDialog extends StatefulWidget {
  final AdminLocation? existing;
  final AdminLocationsState state;

  const _LocationFormDialog({required this.existing, required this.state});

  @override
  State<_LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<_LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _slug =
      TextEditingController(text: widget.existing?.slug ?? '');
  late final TextEditingController _code =
      TextEditingController(text: widget.existing?.code ?? '');
  late final TextEditingController _oldName =
      TextEditingController(text: widget.existing?.oldName ?? '');
  late final TextEditingController _sortOrder =
      TextEditingController(text: widget.existing?.sortOrder?.toString() ?? '');

  late String _type;
  int? _parentId;

  /// True once the form has had to drop a parent — on open, because the stored
  /// one is not an offerable choice, or after a type change it cannot hold.
  bool _parentCleared = false;

  /// Bumped whenever the form itself replaces the parent, so the picker is
  /// rebuilt from the new value instead of keeping the one it was built with.
  int _parentPickerGeneration = 0;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? AdminLocationType.values.first;
    // The stored parent is kept only while it is still an offerable choice. A
    // legacy placement the hierarchy forbids starts empty — visibly — so the
    // operator chooses rather than the form guessing.
    final stored = existing?.parentId;
    if (stored != null && _offers(_type, stored)) {
      _parentId = stored;
    } else {
      _parentCleared = stored != null;
    }
    // The path preview follows the name as it is typed.
    _name.addListener(_onNameChanged);
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _name.removeListener(_onNameChanged);
    _name.dispose();
    _slug.dispose();
    _code.dispose();
    _oldName.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  List<AdminLocation> _optionsFor(String? type) =>
      widget.state.parentOptions(type: type, editing: widget.existing);

  bool _offers(String? type, int parentId) =>
      _optionsFor(type).any((l) => l.id == parentId);

  /// A new type keeps the chosen parent when that parent can hold it, and
  /// otherwise clears it and says so. Nothing is ever re-pointed silently.
  void _onTypeChanged(String? next) {
    if (next == null || next == _type) return;
    setState(() {
      _type = next;
      final current = _parentId;
      if (current != null && !_offers(next, current)) {
        _parentId = null;
        _parentCleared = true;
        _parentPickerGeneration++;
      }
    });
  }

  /// The path the server will derive: `parent.fullPath + " > " + name`, or the
  /// name alone at top level — the rule `LocationService` applies since D12.
  ///
  /// A guide only. The server computes the stored value itself on every write,
  /// so this string is never relied on; it is empty whenever the form cannot
  /// know the answer yet.
  String get _fullPathPreview {
    final name = _name.text.trim();
    if (name.isEmpty) return '';
    final parentId = _parentId;
    if (parentId == null) {
      return AdminLocationType.allowsRoot(_type) ? name : '';
    }
    final parentPath = widget.state.byId(parentId)?.fullPath?.trim();
    if (parentPath == null || parentPath.isEmpty) return '';
    return '$parentPath > $name';
  }

  String? _validateType(String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (!AdminLocationType.isAssignable(v)) {
      return l10n.adminLocationTypeUnavailable;
    }
    final existing = widget.existing;
    if (existing != null &&
        widget.state.typeChangeStrandsChildren(existing, v)) {
      return l10n.adminLocationTypeBlockedByChildren;
    }
    return null;
  }

  /// Only a COUNTRY may be saved without a parent. A reserved type is refused
  /// by [_validateType], so it is not reported twice here.
  String? _validateParent(int? v) {
    if (v != null) return null;
    if (!AdminLocationType.isAssignable(_type)) return null;
    if (AdminLocationType.allowsRoot(_type)) return null;
    return AppLocalizations.of(context)!.adminLocationParentRequired;
  }

  String? _validateCode(String? v) {
    final existing = widget.existing;
    if (existing == null || existing.code == null) return null;
    final t = v?.trim() ?? '';
    if (t.isEmpty) {
      return AppLocalizations.of(context)!.adminLocationCodeCannotBeCleared;
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    String? trimmed(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? null : t;
    }

    final creating = widget.existing == null;
    Navigator.of(context).pop(_LocationFormResult(
      name: _name.text.trim(),
      type: _type,
      parentId: _parentId,
      slug: creating ? trimmed(_slug) : widget.existing!.slug,
      code: trimmed(_code),
      oldName: trimmed(_oldName),
      fullPath: creating ? _fullPathPreview : widget.existing!.fullPath,
      sortOrder: int.tryParse(_sortOrder.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final existing = widget.existing;
    final editing = existing != null;
    return AlertDialog(
      title: Text(editing
          ? l10n.adminLocationEditTitle
          : l10n.adminLocationCreateTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NameField(controller: _name),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                textField: true,
                label: l10n.adminLocationFieldCode,
                child: TextFormField(
                  key: const Key('admin-reference-location-code-field'),
                  controller: _code,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.adminLocationFieldCode,
                    helperText: editing && existing.code != null
                        ? l10n.adminLocationCodeHelperFixed
                        : l10n.adminLocationCodeHelper,
                    helperMaxLines: 3,
                  ),
                  validator: _validateCode,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _SlugField(controller: _slug, editing: editing),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                container: true,
                explicitChildNodes: true,
                label: l10n.adminReferenceFieldType,
                child: DropdownButtonFormField<String>(
                  key: const Key('admin-reference-location-type-picker'),
                  initialValue: _type,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: l10n.adminReferenceFieldType),
                  items: [
                    for (final t
                        in AdminLocationType.optionsWith(existing?.type))
                      DropdownMenuItem(
                        key: Key('admin-reference-location-type-option-$t'),
                        value: t,
                        // WARD and COMMUNE are declared by the enum, so they
                        // are listed — disabled, and labelled as reserved.
                        enabled: AdminLocationType.isAssignable(t),
                        child: AdminLocationType.isReserved(t)
                            ? Row(
                                children: [
                                  Text(t),
                                  const SizedBox(width: AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      l10n.adminLocationTypeReservedMarker,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ),
                                ],
                              )
                            : Text(t),
                      ),
                  ],
                  onChanged: _onTypeChanged,
                  validator: _validateType,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                container: true,
                explicitChildNodes: true,
                label: l10n.adminLocationFieldParent,
                // Rebuilt from scratch when the form replaces the parent, so
                // the field never holds a value its new items do not contain.
                child: KeyedSubtree(
                  key: ValueKey('location-parent-$_parentPickerGeneration'),
                  child: DropdownButtonFormField<int?>(
                    key: const Key('admin-reference-location-parent-picker'),
                    initialValue: _parentId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.adminLocationFieldParent,
                      helperText: l10n.adminLocationHierarchyRule,
                      helperMaxLines: 3,
                    ),
                    hint: Text(l10n.adminLocationParentHint),
                    disabledHint: Text(l10n.adminLocationParentNoCandidates),
                    items: [
                      // Top level is a position only a COUNTRY may take.
                      if (AdminLocationType.allowsRoot(_type))
                        DropdownMenuItem<int?>(
                          key:
                              const Key('admin-reference-location-parent-root'),
                          value: null,
                          child: Text(l10n.adminReferenceParentNone),
                        ),
                      for (final p in _optionsFor(_type))
                        DropdownMenuItem<int?>(
                          key: Key(
                              'admin-reference-location-parent-option-${p.id}'),
                          value: p.id,
                          child: _ParentOptionLabel(location: p),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _parentId = v;
                      _parentCleared = false;
                    }),
                    validator: _validateParent,
                  ),
                ),
              ),
              if (_parentCleared) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.adminLocationParentCleared,
                  key: const Key('admin-reference-location-parent-cleared'),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (editing) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(l10n.adminLocationParentGuardNotice,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
              const SizedBox(height: AppSpacing.xs),
              _PlainField(
                controller: _oldName,
                label: l10n.adminLocationFieldOldName,
                fieldKey: const Key('admin-reference-location-oldname-field'),
              ),
              const SizedBox(height: AppSpacing.xs),
              _SortOrderField(controller: _sortOrder),
              const SizedBox(height: AppSpacing.sm),

              // ── read-only, preserved on save ──────────────────────────────
              Text(l10n.adminLocationReadOnlyNotice,
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSpacing.xs),
              _ReadOnlyValue(
                label: l10n.adminLocationFieldFullPath,
                value: _fullPathPreview.isEmpty
                    ? l10n.adminValueUnknown
                    : _fullPathPreview,
                note: l10n.adminLocationFullPathGeneratedNotice,
              ),
              _ReadOnlyValue(
                label: l10n.adminLocationFieldLevel,
                value: existing?.level?.toString() ?? l10n.adminValueUnknown,
              ),
              _ReadOnlyValue(
                label: l10n.adminLocationFieldCoordinates,
                value: editing
                    ? _coordinatesLabel(context, existing)
                    : l10n.adminValueUnknown,
              ),
              if (editing) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.adminReferenceUpdateReplacesNotice,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.adminPartnerCancel),
        ),
        FilledButton(
          key: const Key('admin-reference-form-submit'),
          onPressed: _submit,
          child: Text(
              editing ? l10n.adminReferenceSave : l10n.adminReferenceCreate),
        ),
      ],
    );
  }
}

/// One parent choice: the parent's path, so two places with the same name are
/// told apart, its type, and — only when it applies — the CMS-inactive marker.
/// Inactive parents stay offered: CMS status has no bearing on the hierarchy.
class _ParentOptionLabel extends StatelessWidget {
  final AdminLocation location;

  const _ParentOptionLabel({required this.location});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final small = Theme.of(context).textTheme.labelSmall;
    return Row(
      children: [
        Flexible(
          child: Text(
            location.fullPath ?? location.name ?? '#${location.id}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(location.type ?? l10n.adminValueUnknown, style: small),
        if (!location.active) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(l10n.adminReferenceStatusInactive, style: small),
        ],
      ],
    );
  }
}

/// A value the console shows but never lets an operator change.
///
/// Deliberately **not** a disabled `TextFormField`: a text box that cannot be
/// typed into still reads as an input, and these four are not inputs at all.
class _ReadOnlyValue extends StatelessWidget {
  final String label;
  final String value;
  final String? note;

  const _ReadOnlyValue({
    required this.label,
    required this.value,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        container: true,
        readOnly: true,
        label: label,
        value: value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.bodyMedium),
            if (note != null)
              Text(note!,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared form fields
// ═══════════════════════════════════════════════════════════════════════════

/// `@NotBlank name` is the only validation either backend DTO declares, so it
/// is the only validation this form adds. No length cap is invented: neither
/// request record carries a `@Size`.
class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  static const Key fieldKey = Key('admin-reference-name-field');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      textField: true,
      label: l10n.adminReferenceFieldName,
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        decoration: InputDecoration(labelText: l10n.adminReferenceFieldName),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? l10n.adminReferenceNameRequired
            : null,
      ),
    );
  }
}

/// Editable on create, read-only afterwards — see the class doc on
/// `_AmenityFormDialog` for why.
class _SlugField extends StatelessWidget {
  final TextEditingController controller;
  final bool editing;

  const _SlugField({required this.controller, required this.editing});

  static const Key fieldKey = Key('admin-reference-slug-field');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      textField: true,
      readOnly: editing,
      label: l10n.adminReferenceFieldSlug,
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        enabled: !editing,
        readOnly: editing,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: l10n.adminReferenceFieldSlug,
          helperText: editing
              ? l10n.adminReferenceSlugFixedNotice
              : l10n.adminReferenceSlugHelper,
          helperMaxLines: 3,
        ),
      ),
    );
  }
}

class _PlainField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  /// Applied to the `TextFormField` itself rather than to this wrapper, so a
  /// test that enumerates the dialog's inputs sees it.
  final Key? fieldKey;

  const _PlainField({
    required this.controller,
    required this.label,
    this.fieldKey,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        textField: true,
        label: label,
        child: TextFormField(
          key: fieldKey,
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

/// `sortOrder` is an unbounded `Integer` on both DTOs — negatives included — so
/// the only thing rejected here is text that is not an integer at all.
class _SortOrderField extends StatelessWidget {
  final TextEditingController controller;

  const _SortOrderField({required this.controller});

  static const Key fieldKey = Key('admin-reference-sort-order-field');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      textField: true,
      label: l10n.adminReferenceFieldSortOrder,
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        keyboardType: TextInputType.number,
        decoration:
            InputDecoration(labelText: l10n.adminReferenceFieldSortOrder),
        validator: (v) {
          final t = v?.trim() ?? '';
          if (t.isEmpty) return null;
          return int.tryParse(t) == null
              ? l10n.adminReferenceSortOrderInvalid
              : null;
        },
      ),
    );
  }
}

/// A closed picker over values observed in the data.
///
/// Both vocabularies it serves — `Amenity.groupName` and `Category.type` — are
/// unvalidated `String` columns the backend will accept anything into, and
/// `Category.type` is matched against `CouponDefinition.placeType` by live
/// coupon targeting. A free text field here would let a typo break that
/// silently, so no "add a new value" affordance is offered.
class _VocabularyPicker extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final Key pickerKey;

  const _VocabularyPicker({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.pickerKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: DropdownButtonFormField<String?>(
        key: pickerKey,
        initialValue: options.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(l10n.adminReferenceValueNotSet),
          ),
          for (final o in options)
            DropdownMenuItem<String?>(
                value: o, child: Text(o, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
