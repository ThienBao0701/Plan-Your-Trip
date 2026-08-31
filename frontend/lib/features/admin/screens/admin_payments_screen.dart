import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_feature_states.dart';
import '../widgets/admin_widgets.dart';

/// Admin payments grid — `GET /api/admin/payments`, paginated in D1a.
///
/// Read-only. `POST /api/admin/payments/{id}/refund` exists and is audited as
/// of D1a, but a refund moves real money and is irreversible, so it is
/// deliberately not exposed here: D1b builds the foundation, and a destructive
/// financial control needs its own phase with a confirmation flow.
///
/// Amounts render exactly as the backend supplies them — the amount alongside
/// its own `currency` string, never a locale-derived symbol and never converted.
class AdminPaymentsScreen extends StatelessWidget {
  final AdminPaymentsState state;

  const AdminPaymentsScreen({super.key, required this.state});

  static const List<AdminSortOption> _sorts = [
    AdminSortOption(field: 'createdAt', label: _createdAt),
    AdminSortOption(field: 'amount', label: _amount),
    AdminSortOption(field: 'status', label: _status),
    AdminSortOption(field: 'paidAt', label: _paidAt),
    AdminSortOption(field: 'refundedAt', label: _refundedAt),
  ];

  static String _createdAt(AppLocalizations l) => l.adminSortCreatedAt;
  static String _amount(AppLocalizations l) => l.adminSortAmount;
  static String _status(AppLocalizations l) => l.adminSortStatus;
  static String _paidAt(AppLocalizations l) => l.adminSortPaidAt;
  static String _refundedAt(AppLocalizations l) => l.adminSortRefundedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final body = state.isReady && !state.isEmpty
            ? AdminResponsiveGrid(
                wide: (c) => _PaymentsTable(rows: state.rows),
                narrow: (c) => _PaymentsCards(rows: state.rows),
              )
            : AdminStateView(
                status: state.status,
                message: state.errorMessage,
                emptyMessage: l10n.adminPaymentsEmpty,
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
                values: AdminPaymentsState.statusValues,
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

class _PaymentsTable extends StatelessWidget {
  final List<AdminPaymentRow> rows;

  const _PaymentsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.adminPaymentCode)),
            DataColumn(label: Text(l10n.adminPaymentBooking)),
            DataColumn(label: Text(l10n.adminPaymentAmount)),
            DataColumn(label: Text(l10n.adminPaymentMethod)),
            DataColumn(label: Text(l10n.adminPaymentProvider)),
            DataColumn(label: Text(l10n.adminFilterStatus)),
            DataColumn(label: Text(l10n.adminPaymentPaidAt)),
          ],
          rows: [
            for (final r in rows)
              DataRow(cells: [
                DataCell(Text(AdminFormats.text(context, r.paymentCode))),
                DataCell(Text(AdminFormats.text(context, r.bookingCode))),
                DataCell(
                    Text(AdminFormats.money(context, r.amount, r.currency))),
                DataCell(Text(AdminFormats.text(context, r.paymentMethod))),
                DataCell(Text(AdminFormats.text(context, r.provider))),
                DataCell(AdminStatusChip(status: r.status)),
                DataCell(Text(AdminFormats.dateTime(context, r.paidAt))),
              ]),
          ],
        ),
      ),
    );
  }
}

class _PaymentsCards extends StatelessWidget {
  final List<AdminPaymentRow> rows;

  const _PaymentsCards({required this.rows});

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
                      child: Text(AdminFormats.text(context, r.paymentCode),
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    AdminStatusChip(status: r.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AdminCardRow(
                  label: l10n.adminPaymentAmount,
                  value: AdminFormats.money(context, r.amount, r.currency),
                  emphasise: true,
                ),
                AdminCardRow(
                    label: l10n.adminPaymentBooking,
                    value: AdminFormats.text(context, r.bookingCode)),
                AdminCardRow(
                    label: l10n.adminPaymentMethod,
                    value: AdminFormats.text(context, r.paymentMethod)),
                AdminCardRow(
                    label: l10n.adminPaymentProvider,
                    value: AdminFormats.text(context, r.provider)),
                AdminCardRow(
                    label: l10n.adminPaymentPaidAt,
                    value: AdminFormats.dateTime(context, r.paidAt)),
                if (r.refundedAt != null)
                  AdminCardRow(
                      label: l10n.adminPaymentRefundedAt,
                      value: AdminFormats.dateTime(context, r.refundedAt)),
                if (r.failureReason != null)
                  AdminCardRow(
                      label: l10n.adminPaymentFailureReason,
                      value: r.failureReason!),
              ],
            ),
          ),
        );
      },
    );
  }
}
