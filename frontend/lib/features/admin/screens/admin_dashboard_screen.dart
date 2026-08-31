import 'package:flutter/material.dart';

import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_feature_states.dart';
import '../widgets/admin_widgets.dart';

/// Platform overview — `GET /api/admin/analytics/overview`.
///
/// Renders **only** the metrics the backend supplies. Nothing is derived: no
/// occupancy rate, no average booking value, no period-over-period delta. Those
/// would be plausible-looking numbers this endpoint never sent, and the money
/// rule proven across C11 and I is that the client does not compute
/// authoritative figures.
///
/// Revenue is shown without a currency because this endpoint returns none — an
/// explicit note says so rather than letting a bare number imply one.
class AdminDashboardScreen extends StatelessWidget {
  final AdminDashboardState state;

  const AdminDashboardScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        if (!state.isReady) {
          return AdminStateView(
            status: state.status,
            message: state.errorMessage,
            onRetry: state.refresh,
          );
        }
        final o = state.overview;
        if (o == null) {
          return AdminStateView(
            status: AdminLoadStatus.error,
            onRetry: state.refresh,
          );
        }

        return RefreshIndicator(
          onRefresh: state.refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _RangeHeader(state: state),
              const SizedBox(height: AppSpacing.sm),
              if (o.hasNoBookings)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: OceanGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(l10n.adminDashboardNoBookings),
                    ),
                  ),
                ),
              _MetricWrap(
                tiles: [
                  _Metric(l10n.adminDashboardTotalBookings,
                      AdminFormats.count(o.totalBookings)),
                  _Metric(l10n.adminDashboardGrossRevenue,
                      AdminFormats.money(context, o.grossRevenue, null)),
                  _Metric(l10n.adminDashboardBookingsInRange,
                      AdminFormats.count(o.bookingsInRange)),
                  _Metric(l10n.adminDashboardRevenueInRange,
                      AdminFormats.money(context, o.revenueInRange, null)),
                  _Metric(l10n.adminDashboardActiveHotels,
                      AdminFormats.count(o.activeHotels)),
                  _Metric(l10n.adminDashboardActiveRooms,
                      AdminFormats.count(o.activeRooms)),
                  _Metric(l10n.adminDashboardTotalUsers,
                      AdminFormats.count(o.totalUsers)),
                  _Metric(l10n.adminDashboardTotalPartners,
                      AdminFormats.count(o.totalPartners)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.adminDashboardNoCurrency,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              if (o.bookingsByStatus.isNotEmpty) ...[
                Text(l10n.adminDashboardBookingsByStatus,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                OceanGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        for (final b in o.bookingsByStatus)
                          AdminCardRow(
                            label: b.label,
                            value: AdminFormats.count(b.count),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RangeHeader extends StatelessWidget {
  final AdminDashboardState state;

  const _RangeHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final o = state.overview;
    final range = (o?.from != null && o?.to != null)
        ? l10n.adminDashboardRange(AdminFormats.date(context, o!.from),
            AdminFormats.date(context, o.to))
        : l10n.adminDashboardRangeDefault;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adminDashboardTitle, style: theme.textTheme.titleLarge),
              Text(range,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (state.loadedAt != null)
                Text(
                  l10n.adminDashboardLoadedAt(
                      AdminFormats.dateTime(context, state.loadedAt)),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: state.isLoading ? null : state.refresh,
          icon: const Icon(Icons.refresh),
          tooltip: l10n.adminRefresh,
        ),
      ],
    );
  }
}

class _Metric {
  final String label;
  final String value;
  const _Metric(this.label, this.value);
}

/// Metric tiles that reflow rather than overflow — at 320 wide they become a
/// single column instead of clipping.
class _MetricWrap extends StatelessWidget {
  final List<_Metric> tiles;

  const _MetricWrap({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
                ? 2
                : 1;
        const gap = AppSpacing.sm;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tiles)
              SizedBox(
                width: width,
                child: OceanGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.label,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(t.value,
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
