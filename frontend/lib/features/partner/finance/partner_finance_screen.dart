import 'package:flutter/material.dart';

import '../../../core/partner/partner_finance_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../widgets/partner_metric_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_finance_state.dart';

/// The Partner Finance module (C11) — the `finance` destination.
///
/// ## These are estimates, and the screen says so
///
/// `PartnerFinanceService` documents its own limits, and this module repeats
/// them where the numbers appear rather than presenting them as a statement of
/// account:
///
///   * the commission rate is a **hard-coded 0.15**, not a negotiated rate;
///   * the tax figure is an **indicative 10%**, explicitly "not a real tax
///     computation";
///   * settlement and payout "periods" are **synthesized calendar months** —
///     there is no settlement ledger or payout scheduler behind them;
///   * `pendingSettlement` is simply the window's whole net revenue.
///
/// ## What the API does not offer, so neither does this screen
///
/// No invoice, payout, settlement or refund **record** exists — every endpoint
/// returns aggregates with no identifier — so there is no detail view. There is
/// **no export or download endpoint**, so no export button. A partner **cannot
/// initiate a refund**, so no refund action. All seven endpoints are GETs; this
/// module never writes.
///
/// ## Money
///
/// Nothing here is computed on the client. Amounts are [PartnerMoney], which
/// exposes no operators, so client-side money arithmetic is a compile error.
class PartnerFinanceScreen extends StatefulWidget {
  const PartnerFinanceScreen({super.key});

  @override
  State<PartnerFinanceScreen> createState() => _PartnerFinanceScreenState();
}

class _PartnerFinanceScreenState extends State<PartnerFinanceScreen>
    with SingleTickerProviderStateMixin {
  PartnerFinanceState? _finance;
  PartnerState? _partner;
  int? _syncedPropertyId;

  // Built eagerly: on a gated workspace `build` returns before the controller is
  // read, and a lazy `late final` would then be constructed inside `dispose()`.
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    final rebind = !identical(partner, _partner);
    if (rebind) {
      _partner = partner;
      _finance?.dispose();
      _finance = PartnerFinanceState(api: partner.api);
      _syncedPropertyId = null;
    }

    final selected = partner.selectedPropertyId;
    if (partner.isReady && (rebind || selected != _syncedPropertyId)) {
      _syncedPropertyId = selected;
      final finance = _finance!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) finance.load(partner, selected);
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _finance?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final finance = _finance;

    if (!partner.isReady || finance == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.partnerFinanceTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.ocean700,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.ocean700,
                tabs: [
                  Tab(text: l10n.partnerFinanceTabOverview),
                  Tab(text: l10n.partnerFinanceTabRevenue),
                  Tab(text: l10n.partnerFinanceTabSettlement),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedBuilder(
          animation: Listenable.merge([_tabs, finance]),
          builder: (context, _) =>
              _Body(partner: partner, finance: finance, tabIndex: _tabs.index),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final PartnerState partner;
  final PartnerFinanceState finance;
  final int tabIndex;

  const _Body({
    required this.partner,
    required this.finance,
    required this.tabIndex,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (finance.status) {
      case PartnerFinanceStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
            status: PartnerWorkspaceStatus.unauthorized);
      case PartnerFinanceStatus.forbidden:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.forbidden,
          detail: finance.errorMessage,
          onPrimaryAction: () => finance.refresh(partner),
        );
      case PartnerFinanceStatus.notFound:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.onboardingRequired,
          onPrimaryAction: () => finance.refresh(partner),
        );
      case PartnerFinanceStatus.invalidRange:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _rangeBar(context),
            const SizedBox(height: AppSpacing.md),
            PartnerMetricNotice(
              warning: true,
              message: l10n.partnerMetricInvalidRange,
              onRetry: () => finance.resetRange(partner),
            ),
          ],
        );
      case PartnerFinanceStatus.error:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.error,
          detail: finance.errorMessage,
          onPrimaryAction: () => finance.refresh(partner),
        );
      case PartnerFinanceStatus.idle:
      case PartnerFinanceStatus.loading:
      case PartnerFinanceStatus.ready:
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rangeBar(context),
        const SizedBox(height: AppSpacing.md),
        PartnerMetricNotice(message: l10n.partnerFinanceEstimateNotice),
        const SizedBox(height: AppSpacing.md),
        if (finance.failedSections > 0) ...[
          PartnerMetricNotice(
            warning: true,
            message:
                l10n.partnerMetricSectionsFailed('${finance.failedSections}'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        switch (tabIndex) {
          0 => _OverviewTab(partner: partner, finance: finance),
          1 => _RevenueTab(partner: partner, finance: finance),
          _ => _SettlementTab(partner: partner, finance: finance),
        },
      ],
    );
  }

  Widget _rangeBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PartnerRangeBar(
      from: finance.from,
      to: finance.to,
      isPartnerWide: finance.isPartnerWide,
      busy: finance.isLoading,
      scopeNote: finance.isPartnerWide
          ? l10n.partnerFinanceScopeAll
          : l10n.partnerFinanceScopeProperty,
      onRangeChanged: (from, to) => finance.setRange(partner, from, to),
      onReset: () => finance.resetRange(partner),
      onRefresh: () => finance.refresh(partner),
    );
  }
}

/// Gross → commission → net, plus the counters behind them.
class _OverviewTab extends StatelessWidget {
  final PartnerState partner;
  final PartnerFinanceState finance;

  const _OverviewTab({required this.partner, required this.finance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = PartnerMetricFormats.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PartnerSectionCard(
          title: l10n.partnerFinanceOverviewHeading,
          subtitle: l10n.partnerFinanceOverviewSubtitle,
          section: finance.overview,
          onRetry: () => finance.refresh(partner),
          isEmpty: (data) => false,
          emptyMessage: l10n.partnerFinanceNoData,
          builder: (data) => _Grid(children: [
            PartnerAmountTile(
              label: l10n.partnerFinanceGross,
              amount: PartnerMoney(data.grossRevenue),
              emphasis: true,
            ),
            PartnerAmountTile(
              label: l10n.partnerFinanceCommission,
              amount: PartnerMoney(data.commissionAmount),
              caption: l10n.partnerFinanceCommissionCaption,
            ),
            PartnerAmountTile(
              label: l10n.partnerFinanceNet,
              amount: PartnerMoney(data.netRevenue),
              emphasis: true,
            ),
            PartnerAmountTile(
              label: l10n.partnerFinanceTax,
              amount: PartnerMoney(data.estimatedTax),
              caption: l10n.partnerFinanceTaxCaption,
            ),
            PartnerAmountTile(
              label: l10n.partnerFinanceRefunded,
              amount: PartnerMoney(data.refundedAmount),
            ),
            PartnerAmountTile(
              label: l10n.partnerFinancePendingSettlement,
              amount: PartnerMoney(data.pendingSettlement),
              caption: l10n.partnerFinancePendingCaption,
            ),
            PartnerStatTile(
              label: l10n.partnerFinanceCompletedLabel,
              value:
                  l10n.partnerFinanceCompletedBookings(data.completedBookings),
              icon: Icons.task_alt_rounded,
            ),
            PartnerStatTile(
              label: l10n.partnerFinancePaidLabel,
              value: l10n.partnerFinancePaidBookings(data.paidBookings),
              icon: Icons.payments_outlined,
            ),
            PartnerStatTile(
              label: l10n.partnerFinanceNextPayout,
              value: data.nextEstimatedPayoutDate == null
                  ? null
                  : f.date.format(data.nextEstimatedPayoutDate!),
              icon: Icons.event_rounded,
              caption: l10n.partnerFinanceNextPayoutCaption,
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        PartnerSectionCard(
          title: l10n.partnerFinanceCommissionHeading,
          section: finance.commission,
          onRetry: () => finance.refresh(partner),
          isEmpty: (data) => false,
          emptyMessage: l10n.partnerFinanceNoData,
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Grid(children: [
                PartnerAmountTile(
                    label: l10n.partnerFinanceGross, amount: data.gross),
                PartnerAmountTile(
                    label: l10n.partnerFinanceCommission,
                    amount: data.commission),
                PartnerAmountTile(
                    label: l10n.partnerFinanceNet,
                    amount: data.net,
                    emphasis: true),
              ]),
              const SizedBox(height: AppSpacing.sm),
              PartnerMetricNotice(
                // The rate is a constant in the service, not a contract term.
                message:
                    l10n.partnerFinanceRateNotice(f.rate(data.commissionRate)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Revenue by day, month, property and room.
class _RevenueTab extends StatelessWidget {
  final PartnerState partner;
  final PartnerFinanceState finance;

  const _RevenueTab({required this.partner, required this.finance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PartnerSectionCard(
      title: l10n.partnerFinanceRevenueHeading,
      subtitle: l10n.partnerFinanceRevenueSubtitle,
      section: finance.revenue,
      onRetry: () => finance.refresh(partner),
      isEmpty: (data) => data.isEmpty,
      emptyMessage: l10n.partnerFinanceRevenueEmpty,
      builder: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Grid(children: [
            PartnerAmountTile(
              label: l10n.partnerFinanceAverageBooking,
              amount: data.averageBookingValue,
            ),
            PartnerAmountTile(
              label: l10n.partnerFinanceHighestBooking,
              amount: data.highestBooking,
            ),
          ]),
          if (data.revenueByDay.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.partnerFinanceByDay,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            PartnerDailyBars(points: data.revenueByDay),
          ],
          if (data.revenueByMonth.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SubHeading(l10n.partnerFinanceByMonth),
            for (final metric in data.revenueByMonth) _MonthRow(metric: metric),
          ],
          if (data.revenueByHotel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SubHeading(l10n.partnerFinanceByProperty),
            PartnerBreakdownList(
                entries: data.revenueByHotel, valueIsMoney: true),
          ],
          if (data.revenueByRoom.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _SubHeading(l10n.partnerFinanceByRoom),
            PartnerBreakdownList(
                entries: data.revenueByRoom, valueIsMoney: true),
          ],
        ],
      ),
    );
  }
}

/// Settlements, payouts, invoices and refunds — the money-out story.
class _SettlementTab extends StatelessWidget {
  final PartnerState partner;
  final PartnerFinanceState finance;

  const _SettlementTab({required this.partner, required this.finance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = PartnerMetricFormats.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PartnerSectionCard(
          title: l10n.partnerFinanceSettlementHeading,
          subtitle: l10n.partnerFinanceSettlementSubtitle,
          section: finance.settlement,
          onRetry: () => finance.refresh(partner),
          isEmpty: (data) => data.isEmpty,
          emptyMessage: l10n.partnerFinanceSettlementEmpty,
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Grid(children: [
                PartnerAmountTile(
                    label: l10n.partnerFinanceCurrentSettlement,
                    amount: data.currentSettlement,
                    emphasis: true),
                PartnerAmountTile(
                    label: l10n.partnerFinanceLastSettlement,
                    amount: data.lastSettlement),
                PartnerAmountTile(
                    label: l10n.partnerFinancePending, amount: data.pending),
                PartnerAmountTile(
                    label: l10n.partnerFinancePaid, amount: data.paid),
              ]),
              // Two server values that can disagree. Both are shown as sent and
              // the disagreement is named rather than smoothed over.
              if (data.historyContradictsPaid) ...[
                const SizedBox(height: AppSpacing.sm),
                PartnerMetricNotice(
                  warning: true,
                  message: l10n.partnerFinanceSettlementMismatch,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _SubHeading(l10n.partnerFinanceSettlementPeriods),
              _PeriodTable(periods: data.settlementHistory),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PartnerSectionCard(
          title: l10n.partnerFinancePayoutHeading,
          subtitle: l10n.partnerFinancePayoutSubtitle,
          section: finance.payouts,
          onRetry: () => finance.refresh(partner),
          isEmpty: (data) => data.isEmpty,
          emptyMessage: l10n.partnerFinancePayoutEmpty,
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PartnerStatTile(
                label: l10n.partnerFinanceEstimatedPayoutDate,
                value: data.estimatedPayoutDate == null
                    ? null
                    : f.date.format(data.estimatedPayoutDate!),
                icon: Icons.event_rounded,
                caption: l10n.partnerFinanceNextPayoutCaption,
              ),
              if (data.upcomingPayouts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _SubHeading(l10n.partnerFinanceUpcomingPayouts),
                _PeriodTable(periods: data.upcomingPayouts),
              ],
              if (data.completedPayouts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _SubHeading(l10n.partnerFinanceCompletedPayouts),
                _PeriodTable(periods: data.completedPayouts),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // No payout record, reference or bank detail exists in this API.
        PartnerMetricNotice(message: l10n.partnerFinancePayoutNoRecords),
        const SizedBox(height: AppSpacing.md),
        PartnerSectionCard(
          title: l10n.partnerFinanceInvoiceHeading,
          section: finance.invoices,
          onRetry: () => finance.refresh(partner),
          isEmpty: (data) => data.isEmpty,
          emptyMessage: l10n.partnerFinanceInvoiceEmpty,
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Grid(children: [
                PartnerStatTile(
                    label: l10n.partnerFinanceInvoiceIssued,
                    value: f.integer.format(data.issued),
                    icon: Icons.receipt_long_outlined),
                PartnerStatTile(
                    label: l10n.partnerFinanceInvoicePaid,
                    value: f.integer.format(data.paid),
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success),
                PartnerStatTile(
                    label: l10n.partnerFinanceInvoiceCancelled,
                    value: f.integer.format(data.cancelled),
                    icon: Icons.cancel_outlined,
                    color: AppColors.danger),
                PartnerStatTile(
                    label: l10n.partnerFinanceInvoiceRefunded,
                    value: f.integer.format(data.refunded),
                    icon: Icons.currency_exchange_rounded,
                    color: AppColors.warning),
                PartnerAmountTile(
                    label: l10n.partnerFinanceInvoiceTotal,
                    amount: data.totalInvoiceAmount),
              ]),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // No invoice id and no document endpoint exist: nothing to open.
        PartnerMetricNotice(message: l10n.partnerFinanceInvoiceNoDocuments),
        const SizedBox(height: AppSpacing.md),
        PartnerSectionCard(
          title: l10n.partnerFinanceRefundHeading,
          section: finance.refunds,
          onRetry: () => finance.refresh(partner),
          isEmpty: (data) => data.isEmpty,
          emptyMessage: l10n.partnerFinanceRefundEmpty,
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Grid(children: [
                PartnerStatTile(
                    label: l10n.partnerFinanceRefundCount,
                    value: f.integer.format(data.refundCount),
                    icon: Icons.undo_rounded),
                PartnerAmountTile(
                    label: l10n.partnerFinanceRefundAmount,
                    amount: data.refundAmount),
                PartnerStatTile(
                    label: l10n.partnerFinanceRefundRate,
                    value: f.percent(data.refundPercentage, ''),
                    icon: Icons.percent_rounded),
              ]),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // A partner has no refund endpoint; this is read-only.
        PartnerMetricNotice(message: l10n.partnerFinanceRefundReadOnly),
      ],
    );
  }
}

/// A responsive tile grid: three columns on desktop, two on tablet, one on
/// mobile, so a dense money layout never forces horizontal scrolling.
class _Grid extends StatelessWidget {
  final List<Widget> children;

  const _Grid({required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const spacing = AppSpacing.sm;
          final columns = constraints.maxWidth >= AppBreakpoints.desktop
              ? 3
              : constraints.maxWidth >= AppBreakpoints.tablet
                  ? 2
                  : 1;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      );
}

class _SubHeading extends StatelessWidget {
  final String text;

  const _SubHeading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
      );
}

class _MonthRow extends StatelessWidget {
  final PartnerFinanceMetric metric;

  const _MonthRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = PartnerMetricFormats.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              // The server's own `YearMonth` label, unchanged.
              metric.label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Text(
            f.money(metric.amount, ''),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The synthesized period table. Scrolls horizontally only if it must.
class _PeriodTable extends StatelessWidget {
  final List<PartnerSettlementPeriod> periods;

  const _PeriodTable({required this.periods});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = PartnerMetricFormats.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 520),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(96),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
            3: FlexColumnWidth(),
            4: FixedColumnWidth(104),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              children: [
                _Head(l10n.partnerFinancePeriod),
                _Head(l10n.partnerFinanceGross),
                _Head(l10n.partnerFinanceCommission),
                _Head(l10n.partnerFinanceNet),
                _Head(l10n.partnerFinanceStatus),
              ],
            ),
            for (final period in periods)
              TableRow(
                children: [
                  _Cell(period.period, bold: true),
                  _Cell(f.money(period.grossAmount, '')),
                  _Cell(f.money(period.commissionAmount, '')),
                  _Cell(f.money(period.netAmount, '')),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OceanStatusPill(
                        label: switch (period.status) {
                          PartnerSettlementStatus.paid =>
                            l10n.partnerFinanceStatusPaid,
                          PartnerSettlementStatus.pending =>
                            l10n.partnerFinanceStatusPending,
                          PartnerSettlementStatus.unknown =>
                            l10n.partnerFinanceStatusUnknown,
                        },
                        color: switch (period.status) {
                          PartnerSettlementStatus.paid => AppColors.success,
                          PartnerSettlementStatus.pending => AppColors.warning,
                          PartnerSettlementStatus.unknown =>
                            AppColors.textTertiary,
                        },
                        icon: switch (period.status) {
                          PartnerSettlementStatus.paid =>
                            Icons.check_circle_outline_rounded,
                          PartnerSettlementStatus.pending =>
                            Icons.schedule_rounded,
                          PartnerSettlementStatus.unknown =>
                            Icons.help_outline_rounded,
                        },
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );

    // ignore: dead_code
    // ignore_for_file: unused_element
  }
}

class _Head extends StatelessWidget {
  final String label;

  const _Head(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
              ),
        ),
      );
}

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;

  const _Cell(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
}
