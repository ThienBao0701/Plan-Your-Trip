import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_feature_states.dart';
import '../widgets/admin_widgets.dart';

/// Admin bookings grid — `GET /api/admin/bookings`, paginated in D1a.
///
/// Read-only. The backend exposes booking status overrides and refunds, but
/// those are destructive one-way transitions and D1b's scope is explicitly the
/// foundation, not mutation. Nothing here implies an action that is not wired.
class AdminBookingsScreen extends StatelessWidget {
  final AdminBookingsState state;

  const AdminBookingsScreen({super.key, required this.state});

  static const List<AdminSortOption> _sorts = [
    AdminSortOption(field: 'createdAt', label: _createdAt),
    AdminSortOption(field: 'checkInDate', label: _checkIn),
    AdminSortOption(field: 'checkOutDate', label: _checkOut),
    AdminSortOption(field: 'finalPrice', label: _total),
    AdminSortOption(field: 'status', label: _status),
    AdminSortOption(field: 'bookingCode', label: _code),
  ];

  static String _createdAt(AppLocalizations l) => l.adminSortCreatedAt;
  static String _checkIn(AppLocalizations l) => l.adminSortCheckIn;
  static String _checkOut(AppLocalizations l) => l.adminSortCheckOut;
  static String _total(AppLocalizations l) => l.adminSortFinalPrice;
  static String _status(AppLocalizations l) => l.adminSortStatus;
  static String _code(AppLocalizations l) => l.adminSortBookingCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final body = state.isReady && !state.isEmpty
            ? AdminResponsiveGrid(
                wide: (c) => _BookingsTable(rows: state.rows),
                narrow: (c) => _BookingsCards(rows: state.rows),
              )
            : AdminStateView(
                status: state.status,
                message: state.errorMessage,
                emptyMessage: l10n.adminBookingsEmpty,
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

class _Toolbar extends StatelessWidget {
  final AdminBookingsState state;
  final List<AdminSortOption> sorts;

  const _Toolbar({required this.state, required this.sorts});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFilterChips(
            values: AdminBookingsState.statusValues,
            selected: state.statusFilter,
            enabled: !state.isLoading,
            onChanged: state.setStatusFilter,
            labelOf: (_, v) => v,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AdminSortControl(
              options: sorts,
              selectedField: state.sortField,
              descending: state.sortDescending,
              enabled: !state.isLoading,
              onChanged: state.setSort,
            ),
          ),
        ],
      );
}

class _BookingsTable extends StatelessWidget {
  final List<AdminBookingRow> rows;

  const _BookingsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Horizontally scrollable inside its own viewport so a wide table never
    // makes the page itself scroll sideways.
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: DataTable(
          columns: [
            DataColumn(label: Text(l10n.adminBookingCode)),
            DataColumn(label: Text(l10n.adminBookingHotel)),
            DataColumn(label: Text(l10n.adminBookingRoom)),
            DataColumn(label: Text(l10n.adminBookingStay)),
            DataColumn(label: Text(l10n.adminBookingTotal)),
            DataColumn(label: Text(l10n.adminFilterStatus)),
            DataColumn(label: Text(l10n.adminBookingCreated)),
          ],
          rows: [
            for (final r in rows)
              DataRow(cells: [
                DataCell(Text(AdminFormats.text(context, r.bookingCode))),
                DataCell(Text(AdminFormats.text(context, r.hotelName))),
                DataCell(Text(AdminFormats.text(context, r.roomName))),
                DataCell(Text('${AdminFormats.date(context, r.checkIn)} → '
                    '${AdminFormats.date(context, r.checkOut)}')),
                DataCell(Text(
                    AdminFormats.money(context, r.finalPrice, r.currency))),
                DataCell(AdminStatusChip(status: r.status)),
                DataCell(Text(AdminFormats.date(context, r.createdAt))),
              ]),
          ],
        ),
      ),
    );
  }
}

class _BookingsCards extends StatelessWidget {
  final List<AdminBookingRow> rows;

  const _BookingsCards({required this.rows});

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
                      child: Text(
                        AdminFormats.text(context, r.bookingCode),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    AdminStatusChip(status: r.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AdminCardRow(
                    label: l10n.adminBookingHotel,
                    value: AdminFormats.text(context, r.hotelName)),
                AdminCardRow(
                    label: l10n.adminBookingRoom,
                    value: AdminFormats.text(context, r.roomName)),
                AdminCardRow(
                  label: l10n.adminBookingStay,
                  value: '${AdminFormats.date(context, r.checkIn)} → '
                      '${AdminFormats.date(context, r.checkOut)} '
                      '(${l10n.adminBookingNights(r.nights)})',
                ),
                AdminCardRow(
                  label: l10n.adminBookingTotal,
                  value: AdminFormats.money(context, r.finalPrice, r.currency),
                  emphasise: true,
                ),
                AdminCardRow(
                    label: l10n.adminBookingCreated,
                    value: AdminFormats.date(context, r.createdAt)),
              ],
            ),
          ),
        );
      },
    );
  }
}
