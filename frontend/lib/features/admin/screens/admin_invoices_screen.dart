import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_feature_states.dart';
import '../widgets/admin_widgets.dart';

/// Admin invoices grid — `GET /api/admin/invoices`, paginated in D1a.
///
/// Read-only, and deliberately offers **no PDF download, no export and no
/// payment control**: the backend exposes none of those. D0 recorded "no
/// official exports" as an open finding, and inventing a download button that
/// cannot work would be exactly the fake-capability failure the project rules
/// forbid.
class AdminInvoicesScreen extends StatelessWidget {
  final AdminInvoicesState state;

  const AdminInvoicesScreen({super.key, required this.state});

  static const List<AdminSortOption> _sorts = [
    AdminSortOption(field: 'createdAt', label: _createdAt),
    AdminSortOption(field: 'status', label: _status),
    AdminSortOption(field: 'issuedAt', label: _issuedAt),
    AdminSortOption(field: 'totalAmount', label: _total),
  ];

  static String _createdAt(AppLocalizations l) => l.adminSortCreatedAt;
  static String _status(AppLocalizations l) => l.adminSortStatus;
  static String _issuedAt(AppLocalizations l) => l.adminSortIssuedAt;
  static String _total(AppLocalizations l) => l.adminSortTotalAmount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final body = state.isReady && !state.isEmpty
            ? AdminResponsiveGrid(
                wide: (c) => _InvoicesTable(rows: state.rows),
                narrow: (c) => _InvoicesCards(rows: state.rows),
              )
            : AdminStateView(
                status: state.status,
                message: state.errorMessage,
                emptyMessage: l10n.adminInvoicesEmpty,
                onRetry: state.refresh,
              );

        return AdminGridScaffold(
          isLoading: state.isLoading,
          page: state.isReady ? state.page : null,
          onPageChanged: state.goToPage,
          toolbar: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminFilterChips(
                values: AdminInvoicesState.statusValues,
                selected: state.statusFilter,
                enabled: !state.isLoading,
                onChanged: state.setStatusFilter,
                labelOf: (_, v) => v,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AdminSortControl(
                  options: _sorts,
                  selectedField: state.sortField,
                  descending: state.sortDescending,
                  enabled: !state.isLoading,
                  onChanged: state.setSort,
                ),
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }
}

class _InvoicesTable extends StatelessWidget {
  final List<AdminInvoiceRow> rows;

  const _InvoicesTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.adminInvoiceNumber)),
            DataColumn(label: Text(l10n.adminInvoiceBooking)),
            DataColumn(label: Text(l10n.adminInvoiceHotel)),
            DataColumn(label: Text(l10n.adminInvoiceTotal)),
            DataColumn(label: Text(l10n.adminFilterStatus)),
            DataColumn(label: Text(l10n.adminInvoiceIssuedAt)),
          ],
          rows: [
            for (final r in rows)
              DataRow(cells: [
                DataCell(Text(AdminFormats.text(context, r.invoiceNumber))),
                DataCell(Text(AdminFormats.text(context, r.bookingCode))),
                DataCell(Text(AdminFormats.text(context, r.hotelName))),
                DataCell(Text(
                    AdminFormats.money(context, r.totalAmount, r.currency))),
                DataCell(AdminStatusChip(status: r.status)),
                DataCell(Text(AdminFormats.date(context, r.issuedAt))),
              ]),
          ],
        ),
      ),
    );
  }
}

class _InvoicesCards extends StatelessWidget {
  final List<AdminInvoiceRow> rows;

  const _InvoicesCards({required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final r = rows[i];
        return OceanGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(AdminFormats.text(context, r.invoiceNumber),
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    AdminStatusChip(status: r.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AdminCardRow(
                    label: l10n.adminInvoiceBooking,
                    value: AdminFormats.text(context, r.bookingCode)),
                AdminCardRow(
                    label: l10n.adminInvoiceHotel,
                    value: AdminFormats.text(context, r.hotelName)),
                AdminCardRow(
                    label: l10n.adminInvoiceSubtotal,
                    value: AdminFormats.money(context, r.subtotal, r.currency)),
                if (r.discountAmount != null)
                  AdminCardRow(
                      label: l10n.adminInvoiceDiscount,
                      value: AdminFormats.money(
                          context, r.discountAmount, r.currency)),
                if (r.taxAmount != null)
                  AdminCardRow(
                      label: l10n.adminInvoiceTax,
                      value:
                          AdminFormats.money(context, r.taxAmount, r.currency)),
                AdminCardRow(
                  label: l10n.adminInvoiceTotal,
                  value: AdminFormats.money(context, r.totalAmount, r.currency),
                  emphasise: true,
                ),
                AdminCardRow(
                    label: l10n.adminInvoiceIssuedAt,
                    value: AdminFormats.date(context, r.issuedAt)),
                if (r.paidAt != null)
                  AdminCardRow(
                      label: l10n.adminInvoicePaidAt,
                      value: AdminFormats.date(context, r.paidAt)),
              ],
            ),
          ),
        );
      },
    );
  }
}
