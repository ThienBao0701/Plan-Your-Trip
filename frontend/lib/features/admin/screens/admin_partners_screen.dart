import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_partner_states.dart';
import '../widgets/admin_widgets.dart';

/// Admin partner roster — `GET /api/admin/partners`, paginated in D1c.
///
/// The grid shows business identity and verification state only. The contact
/// block the DTO also returns — email, phone, address, tax code — is genuine
/// PII and stays on the detail view, where an administrator has opened one
/// partner deliberately, rather than appearing in a list that is scanned in
/// bulk (D2B, sensitive data).
class AdminPartnersScreen extends StatelessWidget {
  final AdminPartnersState state;
  final ValueChanged<AdminPartnerRow> onOpenPartner;

  const AdminPartnersScreen({
    super.key,
    required this.state,
    required this.onOpenPartner,
  });

  static const List<AdminSortOption> _sorts = [
    AdminSortOption(field: 'createdAt', label: _createdAt),
    AdminSortOption(field: 'businessName', label: _businessName),
    AdminSortOption(field: 'verificationStatus', label: _status),
    AdminSortOption(field: 'submittedAt', label: _submittedAt),
    AdminSortOption(field: 'approvedAt', label: _approvedAt),
  ];

  static String _createdAt(AppLocalizations l) => l.adminSortCreatedAt;
  static String _businessName(AppLocalizations l) => l.adminPartnerSortBusinessName;
  static String _status(AppLocalizations l) => l.adminFilterStatus;
  static String _submittedAt(AppLocalizations l) => l.adminPartnerSortSubmittedAt;
  static String _approvedAt(AppLocalizations l) => l.adminSortApprovedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final body = state.isReady && !state.isEmpty
            ? AdminResponsiveGrid(
                wide: (context) =>
                    _PartnerTable(rows: state.rows, onOpen: onOpenPartner),
                narrow: (context) =>
                    _PartnerCards(rows: state.rows, onOpen: onOpenPartner),
              )
            : AdminStateView(
                status: state.status,
                message: state.errorMessage,
                emptyMessage: state.hasFilters
                    ? l10n.adminPartnersEmptyFiltered
                    : l10n.adminPartnersEmpty,
                onRetry: state.refresh,
              );

        return AdminGridScaffold(
          isLoading: state.isLoading,
          page: state.isReady ? state.page : null,
          onPageChanged: state.goToPage,
          toolbar: _Toolbar(state: state, sorts: _sorts),
          body: body,
        );
      },
    );
  }
}

class _Toolbar extends StatefulWidget {
  final AdminPartnersState state;
  final List<AdminSortOption> sorts;

  const _Toolbar({required this.state, required this.sorts});

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          textField: true,
          label: l10n.adminPartnerSearchLabel,
          child: TextField(
            controller: _search,
            enabled: !state.isLoading,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              labelText: l10n.adminPartnerSearchLabel,
              helperText: l10n.adminPartnerSearchHint,
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l10n.adminPartnerSearchClear,
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
          values: AdminPartnersState.statusValues,
          selected: state.statusFilter,
          enabled: !state.isLoading,
          onChanged: state.setStatusFilter,
          labelOf: (_, v) => v,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.adminPartnerFilterBusinessType,
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xxs),
        AdminFilterChips(
          values: AdminPartnersState.businessTypeValues,
          selected: state.businessTypeFilter,
          enabled: !state.isLoading,
          onChanged: state.setBusinessTypeFilter,
          labelOf: (_, v) => v,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: AdminSortControl(
            options: widget.sorts,
            selectedField: state.sortField,
            descending: state.sortDescending,
            enabled: !state.isLoading,
            onChanged: state.setSort,
          ),
        ),
      ],
    );
  }
}

/// Desktop/tablet: a dense table. Business identity and lifecycle state only.
class _PartnerTable extends StatelessWidget {
  final List<AdminPartnerRow> rows;
  final ValueChanged<AdminPartnerRow> onOpen;

  const _PartnerTable({required this.rows, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.adminPartnerColBusiness)),
            DataColumn(label: Text(l10n.adminPartnerColType)),
            DataColumn(label: Text(l10n.adminFilterStatus)),
            DataColumn(label: Text(l10n.adminPartnerColSubmitted)),
            DataColumn(label: Text(l10n.adminSortCreatedAt)),
            DataColumn(label: Text(l10n.adminPartnerColAction)),
          ],
          rows: [
            for (final r in rows)
              DataRow(cells: [
                DataCell(Text(AdminFormats.text(context, r.businessName))),
                DataCell(Text(AdminFormats.text(context, r.businessType))),
                DataCell(AdminStatusChip(status: r.status.wire)),
                DataCell(Text(AdminFormats.date(context, r.submittedAt))),
                DataCell(Text(AdminFormats.date(context, r.createdAt))),
                DataCell(
                  TextButton(
                    onPressed: () => onOpen(r),
                    child: Text(l10n.adminPartnerOpen),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

/// Mobile: one card per partner, the whole card being the tap target.
class _PartnerCards extends StatelessWidget {
  final List<AdminPartnerRow> rows;
  final ValueChanged<AdminPartnerRow> onOpen;

  const _PartnerCards({required this.rows, required this.onOpen});

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
          label: l10n.adminPartnerOpenSemantic(
              r.businessName ?? l10n.adminValueUnknown),
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
                          child: Text(
                            AdminFormats.text(context, r.businessName),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AdminStatusChip(status: r.status.wire),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AdminCardRow(
                        label: l10n.adminPartnerColType,
                        value: AdminFormats.text(context, r.businessType)),
                    AdminCardRow(
                        label: l10n.adminPartnerColSubmitted,
                        value: AdminFormats.date(context, r.submittedAt)),
                    AdminCardRow(
                        label: l10n.adminSortCreatedAt,
                        value: AdminFormats.date(context, r.createdAt)),
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
