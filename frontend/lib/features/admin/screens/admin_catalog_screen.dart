import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_catalog_states.dart';
import '../widgets/admin_widgets.dart';

/// Admin place roster — `GET /api/admin/places`.
///
/// The sort control here is deliberately **not** [AdminSortControl]: that widget
/// speaks `field,dir`, and this endpoint takes a closed token vocabulary where
/// the direction is baked into the token (`rating_desc`, `price_asc`). Reusing
/// the shared control would have meant sending a string the backend silently
/// ignores, which looks like a working control that does nothing.
class AdminCatalogScreen extends StatelessWidget {
  final AdminCatalogPlacesState state;
  final ValueChanged<AdminPlaceRow> onOpenPlace;

  const AdminCatalogScreen({
    super.key,
    required this.state,
    required this.onOpenPlace,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final body = state.isReady && !state.isEmpty
            ? AdminResponsiveGrid(
                wide: (context) =>
                    _PlaceTable(rows: state.rows, onOpen: onOpenPlace),
                narrow: (context) =>
                    _PlaceCards(rows: state.rows, onOpen: onOpenPlace),
              )
            : AdminStateView(
                status: state.status,
                message: state.errorMessage,
                emptyMessage: state.hasFilters
                    ? l10n.adminCatalogEmptyFiltered
                    : l10n.adminCatalogEmpty,
                onRetry: state.refresh,
              );

        return AdminGridScaffold(
          isLoading: state.isLoading,
          page: state.isReady ? state.page : null,
          onPageChanged: state.goToPage,
          toolbar: _Toolbar(state: state),
          body: body,
        );
      },
    );
  }
}

class _Toolbar extends StatefulWidget {
  final AdminCatalogPlacesState state;

  const _Toolbar({required this.state});

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  late final TextEditingController _search =
      TextEditingController(text: widget.state.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _sortLabel(AppLocalizations l, String token) => switch (token) {
        'newest' => l.adminCatalogSortNewest,
        'rating_desc' => l.adminCatalogSortRatingDesc,
        'price_asc' => l.adminCatalogSortPriceAsc,
        'price_desc' => l.adminCatalogSortPriceDesc,
        'name_asc' => l.adminCatalogSortNameAsc,
        _ => token,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          textField: true,
          label: l10n.adminCatalogSearchLabel,
          child: TextField(
            controller: _search,
            enabled: !state.isLoading,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              labelText: l10n.adminCatalogSearchLabel,
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l10n.adminCatalogSearchClear,
                      onPressed: () {
                        _search.clear();
                        state.setQuery('');
                        setState(() {});
                      },
                    ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: state.setQuery,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.adminFilterStatus,
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xxs),
        AdminFilterChips(
          values: AdminCatalogPlacesState.statusValues,
          selected: state.statusFilter,
          enabled: !state.isLoading,
          onChanged: state.setStatusFilter,
          labelOf: (_, v) => v,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: Text(l10n.adminCatalogFilterFeatured),
              selected: state.featuredFilter == true,
              onSelected: state.isLoading
                  ? null
                  : (on) => state.setFeaturedFilter(on ? true : null),
            ),
            FilterChip(
              label: Text(l10n.adminCatalogFilterVerified),
              selected: state.verifiedFilter == true,
              onSelected: state.isLoading
                  ? null
                  : (on) => state.setVerifiedFilter(on ? true : null),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        // A visible label, not a bare dropdown: the token names are product
        // vocabulary ("Highest rated"), so without one the control reads as an
        // unexplained value. Wrapping in a labelled container as well keeps the
        // name attached to the control itself for a screen reader.
        Text(l10n.adminCatalogSortLabel,
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xxs),
        // isExpanded, because a DropdownButton sizes itself to its widest
        // *item*: "Price: low to high" is wider than a 320px toolbar, and the
        // button overflowed rather than ellipsised.
        Semantics(
          container: true,
          label: l10n.adminCatalogSortLabel,
          child: DropdownButton<String>(
            value: state.sortField,
            isExpanded: true,
            onChanged: state.isLoading
                ? null
                : (v) => v == null ? null : state.setSortToken(v),
            items: [
              for (final token in AdminCatalogPlacesState.sortTokens)
                DropdownMenuItem(
                  value: token,
                  child: Text(_sortLabel(l10n, token),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
        // The backend applies no id tiebreaker, so rows sharing the sort key can
        // swap between requests. Said plainly rather than hidden behind a
        // client-side re-sort that would only look stable.
        Text(l10n.adminCatalogOrderingNotice,
            style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _PlaceTable extends StatelessWidget {
  final List<AdminPlaceRow> rows;
  final ValueChanged<AdminPlaceRow> onOpen;

  const _PlaceTable({required this.rows, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.adminCatalogColName)),
            DataColumn(label: Text(l10n.adminCatalogColCategory)),
            DataColumn(label: Text(l10n.adminFilterStatus)),
            DataColumn(label: Text(l10n.adminCatalogColRating)),
            DataColumn(label: Text(l10n.adminCatalogColFlags)),
            DataColumn(label: Text(l10n.adminPartnerColAction)),
          ],
          rows: [
            for (final r in rows)
              DataRow(cells: [
                DataCell(Text(AdminFormats.text(context, r.name))),
                DataCell(Text(AdminFormats.text(context, r.category?.name))),
                DataCell(AdminStatusChip(status: r.status.wire)),
                DataCell(Text('${r.ratingAvg} (${r.reviewCount})')),
                DataCell(
                    _FlagIcons(featured: r.featured, verified: r.verified)),
                DataCell(TextButton(
                  onPressed: () => onOpen(r),
                  child: Text(l10n.adminPartnerOpen),
                )),
              ]),
          ],
        ),
      ),
    );
  }
}

class _PlaceCards extends StatelessWidget {
  final List<AdminPlaceRow> rows;
  final ValueChanged<AdminPlaceRow> onOpen;

  const _PlaceCards({required this.rows, required this.onOpen});

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
        return Semantics(
          button: true,
          label:
              l10n.adminCatalogOpenSemantic(r.name ?? l10n.adminValueUnknown),
          child: OceanGlassCard(
            child: InkWell(
              onTap: () => onOpen(r),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                        AdminStatusChip(status: r.status.wire),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AdminCardRow(
                        label: l10n.adminCatalogColCategory,
                        value: AdminFormats.text(context, r.category?.name)),
                    AdminCardRow(
                        label: l10n.adminCatalogColLocation,
                        value: AdminFormats.text(context, r.location?.name)),
                    AdminCardRow(
                        label: l10n.adminCatalogColRating,
                        value: '${r.ratingAvg} (${r.reviewCount})'),
                    const SizedBox(height: AppSpacing.xxs),
                    _FlagIcons(featured: r.featured, verified: r.verified),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Flags are shown with an icon *and* a word, never colour alone.
class _FlagIcons extends StatelessWidget {
  final bool featured;
  final bool verified;

  const _FlagIcons({required this.featured, required this.verified});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (!featured && !verified) {
      return Text('—', style: theme.textTheme.bodySmall);
    }
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        if (verified)
          Chip(
            avatar: const Icon(Icons.verified_outlined, size: 15),
            label: Text(l10n.adminCatalogFilterVerified),
            visualDensity: VisualDensity.compact,
          ),
        if (featured)
          Chip(
            avatar: const Icon(Icons.star_outline, size: 15),
            label: Text(l10n.adminCatalogFilterFeatured),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
