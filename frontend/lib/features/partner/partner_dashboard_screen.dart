import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/partner/partner_models.dart';
import '../../core/partner/partner_state.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'dashboard/partner_dashboard_state.dart';
import 'dashboard/widgets/partner_dashboard_sections.dart';
import 'dashboard/widgets/partner_trend_chart.dart';
import 'widgets/partner_state_views.dart';

/// The Partner Dashboard — a desktop-first operations console rendered entirely
/// from live `/api/partner/**` responses.
///
/// ## Where every number comes from
///
/// | Panel | Endpoint | Scope |
/// |---|---|---|
/// | Workspace header | `extranet/home` (via `PartnerState`) | all properties |
/// | Needs attention | `extranet/menu` | all properties |
/// | Quick actions | `extranet/home` `quickActions` | all properties |
/// | Today's operations | `dashboard` | today, all properties (endpoint takes no params) |
/// | Performance | `analytics/overview` | selected property + window |
/// | Occupancy | `analytics/occupancy` | selected property + window |
/// | Revenue | `analytics/revenue` | selected property + window |
/// | Finance | `extranet/home` `financeSummary`, or `finance/overview` when scoped | see below |
/// | Recent activity | `extranet/activity-logs` | all properties |
///
/// Nothing is computed here. Occupancy, ADR, revenue, commission and settlement
/// are backend responsibilities; a plausible client-side figure would be worse
/// than none. The only client arithmetic is chart axis scaling.
///
/// Because the panels genuinely have **different scopes**, each states its own.
/// `/api/partner/dashboard` is fixed to today across every owned hotel while the
/// analytics panels follow the filter, so both can legitimately show a different
/// "occupancy" at the same moment. Labelling the scope is what makes that
/// honest rather than contradictory.
///
/// Authorization is never assumed from the UI. Reaching this screen grants
/// nothing: `SecurityConfig` gates `/api/partner/**` and every partner service
/// re-resolves the caller through `partnerProfileRepo.findByUserId(uid)`.
class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  PartnerDashboardState? _dashboard;
  PartnerState? _partner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    if (identical(partner, _partner)) return;
    _partner = partner;
    _dashboard?.dispose();
    final dashboard = PartnerDashboardState(api: partner.api);
    _dashboard = dashboard;
    // The workspace must be ready before any /api/partner/** call is worth
    // making: PartnerState has already resolved profile + approval, and a call
    // made before that would only reproduce the 404/403 it already handled.
    if (partner.isReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) dashboard.load(workspace: partner.overview);
      });
    }
  }

  @override
  void dispose() {
    _dashboard?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final partner = _partner;
    final dashboard = _dashboard;
    if (partner == null || dashboard == null) return;
    await dashboard.load(workspace: partner.overview);
  }

  @override
  Widget build(BuildContext context) {
    final partner = PartnerScope.of(context);
    final dashboard = _dashboard;

    // Workspace-level lifecycle (not approved, no profile, demo mode, ...) is
    // PartnerState's job and is rendered by the shell; this is the safety net
    // for a direct render outside it.
    if (!partner.isReady || dashboard == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return AnimatedBuilder(
      animation: dashboard,
      builder: (context, _) => _DashboardBody(
        partner: partner,
        dashboard: dashboard,
        onReload: _reload,
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final PartnerState partner;
  final PartnerDashboardState dashboard;
  final Future<void> Function() onReload;

  const _DashboardBody({
    required this.partner,
    required this.dashboard,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Every panel failing with 401/403/404 is a workspace-level condition, not
    // seven independent outages — say it once.
    if (dashboard.isWholeWorkspaceFailure) {
      final status = switch (dashboard.sessionFailureKind) {
        ApiErrorKind.unauthorized => PartnerWorkspaceStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerWorkspaceStatus.forbidden,
        ApiErrorKind.notFound => PartnerWorkspaceStatus.onboardingRequired,
        _ => PartnerWorkspaceStatus.error,
      };
      return PartnerWorkspaceStatusView(
        status: status,
        onPrimaryAction: onReload,
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.desktop;

    final performanceColumn = <Widget>[
      _PerformanceSection(dashboard: dashboard, onRetry: onReload),
      const SizedBox(height: AppSpacing.md),
      _OccupancySection(dashboard: dashboard, onRetry: onReload),
      const SizedBox(height: AppSpacing.md),
      _RevenueSection(dashboard: dashboard, onRetry: onReload),
    ];

    final sideColumn = <Widget>[
      _FinanceSection(dashboard: dashboard, onRetry: onReload),
      const SizedBox(height: AppSpacing.md),
      _ActivitySection(dashboard: dashboard, onRetry: onReload),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WorkspaceHeader(partner: partner, dashboard: dashboard),
        const SizedBox(height: AppSpacing.md),
        _AttentionSection(dashboard: dashboard, onRetry: onReload),
        const SizedBox(height: AppSpacing.md),
        _ScopeSection(
          partner: partner,
          dashboard: dashboard,
          semanticsLabel: l10n.partnerDashboardScopeHeading,
        ),
        const SizedBox(height: AppSpacing.md),
        _OperationsSection(dashboard: dashboard, onRetry: onReload),
        const SizedBox(height: AppSpacing.md),
        if (isWide)
          // Deliberately no IntrinsicHeight: the panels contain LayoutBuilders
          // (the KPI grids), which cannot report intrinsic dimensions. Letting
          // each column size to its own content is also the better dashboard
          // behaviour — a short Finance panel should not stretch to match a
          // tall chart column.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: performanceColumn,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: sideColumn,
                ),
              ),
            ],
          )
        else ...[
          ...performanceColumn,
          const SizedBox(height: AppSpacing.md),
          ...sideColumn,
        ],
      ],
    );
  }
}

/// Who am I, and what am I operating.
class _WorkspaceHeader extends StatelessWidget {
  final PartnerState partner;
  final PartnerDashboardState dashboard;

  const _WorkspaceHeader({required this.partner, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final formats = PartnerNumberFormats.of(context);
    final overview = partner.overview!;
    final selected = partner.selectedProperty;
    final lastLoaded = dashboard.lastLoadedAt;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                overview.businessName.isEmpty
                    ? l10n.partnerWorkspaceUnnamed
                    : overview.businessName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              PartnerVerificationPill(status: overview.verificationStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.partnerDashboardRepresentative(overview.representativeName),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xxs,
            children: [
              _HeaderFact(
                icon: Icons.apartment_rounded,
                text: l10n
                    .partnerDashboardPropertyCount(overview.ownedHotelCount),
              ),
              _HeaderFact(
                icon: Icons.meeting_room_rounded,
                text: l10n.partnerDashboardRoomCount(overview.activeRoomCount),
              ),
              _HeaderFact(
                icon: Icons.badge_outlined,
                text: l10n.partnerDashboardTeamRole(
                    _teamRoleLabel(l10n, partner.teamRole)),
              ),
              if (selected != null)
                _HeaderFact(
                  icon: Icons.place_outlined,
                  text: l10n.partnerDashboardActiveProperty(selected.name),
                ),
              if (lastLoaded != null)
                _HeaderFact(
                  icon: Icons.schedule_rounded,
                  text: l10n.partnerDashboardUpdatedAt(
                      formats.dateTime.format(lastLoaded)),
                ),
            ],
          ),
          if (dashboard.performance.isReady &&
              dashboard.performance.data!.hasNoBookings) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.partnerDashboardNoActivityHint,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  static String _teamRoleLabel(AppLocalizations l10n, PartnerTeamRole role) =>
      switch (role) {
        PartnerTeamRole.owner => l10n.partnerTeamRoleOwner,
        PartnerTeamRole.manager => l10n.partnerTeamRoleManager,
        PartnerTeamRole.frontDesk => l10n.partnerTeamRoleFrontDesk,
        PartnerTeamRole.finance => l10n.partnerTeamRoleFinance,
        PartnerTeamRole.viewer => l10n.partnerTeamRoleViewer,
        PartnerTeamRole.unknown => l10n.partnerTeamRoleUnknown,
      };
}

class _HeaderFact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderFact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xxs),
          // Flexible, not a bare Text: these sit in a Wrap, so a long fact
          // (a localised timestamp, a long property name) would otherwise
          // overflow the row on a phone-width card instead of ellipsizing.
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
}

/// What needs attention, plus the backend's quick actions.
class _AttentionSection extends StatelessWidget {
  final PartnerDashboardState dashboard;
  final Future<void> Function() onRetry;

  const _AttentionSection({required this.dashboard, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final menu = dashboard.menu;
    final quickActions = partner.overview?.quickActions ?? const [];

    return PartnerDashboardSection(
      title: l10n.partnerDashboardAttentionHeading,
      scopeCaption: l10n.partnerDashboardScopeAllProperties,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (menu.isLoading)
            const PartnerSectionLoading(lines: 1)
          else if (menu.isFailed)
            PartnerSectionFailure(
              kind: menu.errorKind,
              message: menu.message,
              onRetry: onRetry,
            )
          else if (dashboard.attentionItems.isEmpty)
            PartnerSectionEmpty(message: l10n.partnerDashboardAttentionClear)
          else
            PartnerAttentionRail(items: dashboard.attentionItems),
          if (quickActions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.partnerDashboardQuickActionsHeading,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            PartnerQuickActionsRow(actions: quickActions),
          ],
        ],
      ),
    );
  }
}

/// The analytics scope controls.
class _ScopeSection extends StatelessWidget {
  final PartnerState partner;
  final PartnerDashboardState dashboard;
  final String semanticsLabel;

  const _ScopeSection({
    required this.partner,
    required this.dashboard,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PartnerDashboardSection(
      title: semanticsLabel,
      scopeCaption: l10n.partnerDashboardScopeHint,
      child: PartnerScopeBar(
        range: dashboard.range,
        selectedPropertyId: dashboard.hotelId,
        enabled: !dashboard.isLoading,
        properties: [
          for (final property in partner.properties)
            (id: property.id, name: property.name),
        ],
        onRangeChanged: (value) =>
            dashboard.selectRange(value, workspace: partner.overview),
        onPropertyChanged: (value) {
          // The workspace owns the property context so later partner modules
          // inherit one selection rather than each keeping their own.
          // `PartnerState.selectProperty` ignores any id the backend did not
          // authorise, and cannot represent "all properties" — which is a
          // dashboard-only filter, so null simply leaves the workspace
          // selection untouched.
          if (value != null) partner.selectProperty(value);
          dashboard.selectProperty(
            value,
            authorizedIds: partner.properties.map((p) => p.id),
            workspace: partner.overview,
          );
        },
      ),
    );
  }
}

/// `GET /api/partner/dashboard` — today's operations.
class _OperationsSection extends StatelessWidget {
  final PartnerDashboardState dashboard;
  final Future<void> Function() onRetry;

  const _OperationsSection({required this.dashboard, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formats = PartnerNumberFormats.of(context);
    final section = dashboard.operations;

    return PartnerDashboardSection(
      title: l10n.partnerDashboardTodayHeading,
      scopeCaption: l10n.partnerDashboardScopeToday,
      child: section.isLoading
          ? const PartnerSectionLoading()
          : section.isFailed
              ? PartnerSectionFailure(
                  kind: section.errorKind,
                  message: section.message,
                  onRetry: onRetry,
                )
              : PartnerKpiGrid(
                  tiles: [
                    PartnerKpiTile(
                      label: l10n.partnerMetricArrivals,
                      value:
                          formats.integer.format(section.data!.todaysArrivals),
                      icon: Icons.login_rounded,
                      accent: AppColors.success,
                    ),
                    PartnerKpiTile(
                      label: l10n.partnerMetricDepartures,
                      value: formats.integer
                          .format(section.data!.todaysDepartures),
                      icon: Icons.logout_rounded,
                      accent: AppColors.info,
                    ),
                    PartnerKpiTile(
                      label: l10n.partnerKpiCurrentGuests,
                      value:
                          formats.integer.format(section.data!.currentGuests),
                      icon: Icons.people_alt_rounded,
                      accent: AppColors.ocean600,
                    ),
                    PartnerKpiTile(
                      label: l10n.partnerKpiUpcoming,
                      value: formats.integer.format(section.data!.upcoming),
                      icon: Icons.event_available_rounded,
                      accent: AppColors.violet,
                    ),
                    PartnerKpiTile(
                      label: l10n.partnerKpiOccupancy,
                      value: formats.percent(section.data!.occupancyRate),
                      icon: Icons.donut_large_rounded,
                      accent: AppColors.turquoise600,
                    ),
                    PartnerKpiTile(
                      label: l10n.partnerKpiRevenueToday,
                      value: formats.money.format(section.data!.revenueToday),
                      icon: Icons.today_rounded,
                      accent: AppColors.mint,
                    ),
                    PartnerKpiTile(
                      label: l10n.partnerKpiRevenueMonth,
                      value: formats.money.format(section.data!.revenueMonth),
                      icon: Icons.calendar_month_rounded,
                      accent: AppColors.mint,
                    ),
                    PartnerKpiTile(
                      label: l10n.partnerKpiAverageStay,
                      value: formats.decimal
                          .format(section.data!.averageStayNights),
                      icon: Icons.hotel_rounded,
                      accent: AppColors.coral,
                    ),
                  ],
                ),
    );
  }
}

/// `GET /api/partner/analytics/overview` — the selected window.
class _PerformanceSection extends StatelessWidget {
  final PartnerDashboardState dashboard;
  final Future<void> Function() onRetry;

  const _PerformanceSection({required this.dashboard, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formats = PartnerNumberFormats.of(context);
    final section = dashboard.performance;

    return PartnerDashboardSection(
      title: l10n.partnerDashboardPerformanceHeading,
      scopeCaption: _scopeCaption(l10n, dashboard),
      child: section.isLoading
          ? const PartnerSectionLoading()
          : section.isFailed
              ? PartnerSectionFailure(
                  kind: section.errorKind,
                  message: section.message,
                  onRetry: onRetry,
                )
              : section.data!.hasNoBookings
                  ? PartnerSectionEmpty(
                      message: l10n.partnerDashboardPerformanceEmpty)
                  : PartnerKpiGrid(
                      tiles: [
                        PartnerKpiTile(
                          label: l10n.partnerKpiTotalRevenue,
                          value:
                              formats.money.format(section.data!.totalRevenue),
                          icon: Icons.payments_rounded,
                          accent: AppColors.mint,
                        ),
                        PartnerKpiTile(
                          label: l10n.partnerKpiTotalBookings,
                          value: formats.integer
                              .format(section.data!.totalBookings),
                          icon: Icons.receipt_long_rounded,
                          accent: AppColors.ocean600,
                        ),
                        PartnerKpiTile(
                          label: l10n.partnerKpiAdr,
                          value: formats.money
                              .format(section.data!.averageDailyRate),
                          icon: Icons.price_change_rounded,
                          accent: AppColors.turquoise600,
                          caption: l10n.partnerKpiAdrCaption,
                        ),
                        PartnerKpiTile(
                          label: l10n.partnerKpiOccupancy,
                          value: formats.percent(section.data!.occupancyRate),
                          icon: Icons.donut_large_rounded,
                          accent: AppColors.turquoise600,
                        ),
                        PartnerKpiTile(
                          label: l10n.partnerKpiConfirmed,
                          value: formats.integer
                              .format(section.data!.confirmedBookings),
                          icon: Icons.check_circle_outline_rounded,
                          accent: AppColors.success,
                        ),
                        PartnerKpiTile(
                          label: l10n.partnerKpiCancelled,
                          value: formats.integer
                              .format(section.data!.cancelledBookings),
                          icon: Icons.cancel_outlined,
                          accent: AppColors.danger,
                        ),
                        PartnerKpiTile(
                          label: l10n.partnerKpiReviewAverage,
                          value: section.data!.reviewCount == 0
                              ? l10n.partnerValueUnavailable
                              : formats.decimal
                                  .format(section.data!.reviewAverage),
                          caption: l10n
                              .partnerKpiReviewCount(section.data!.reviewCount),
                          icon: Icons.star_rounded,
                          accent: AppColors.warning,
                        ),
                        // `responseRate` is a nullable Double in the DTO — a
                        // null means "not measurable", never zero.
                        PartnerKpiTile(
                          label: l10n.partnerKpiResponseRate,
                          value: section.data!.responseRate == null
                              ? l10n.partnerValueUnavailable
                              : formats.percent(section.data!.responseRate!),
                          icon: Icons.forum_rounded,
                          accent: AppColors.violet,
                        ),
                      ],
                    ),
    );
  }
}

/// `GET /api/partner/analytics/occupancy`.
class _OccupancySection extends StatelessWidget {
  final PartnerDashboardState dashboard;
  final Future<void> Function() onRetry;

  const _OccupancySection({required this.dashboard, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formats = PartnerNumberFormats.of(context);
    final section = dashboard.occupancy;

    return PartnerDashboardSection(
      title: l10n.partnerDashboardOccupancyHeading,
      scopeCaption: _scopeCaption(l10n, dashboard),
      child: section.isLoading
          ? const PartnerSectionLoading(lines: 4)
          : section.isFailed
              ? PartnerSectionFailure(
                  kind: section.errorKind,
                  message: section.message,
                  onRetry: onRetry,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PartnerKpiGrid(
                      minTileWidth: 140,
                      tiles: [
                        PartnerKpiTile(
                          label: l10n.partnerOccupancyInventory,
                          value: formats.integer
                              .format(section.data!.totalRoomInventory),
                          icon: Icons.inventory_2_outlined,
                        ),
                        PartnerKpiTile(
                          label: l10n.partnerOccupancySold,
                          value:
                              formats.integer.format(section.data!.soldRooms),
                          icon: Icons.sell_outlined,
                          accent: AppColors.success,
                        ),
                        PartnerKpiTile(
                          label: l10n.partnerOccupancyAvailable,
                          value: formats.integer
                              .format(section.data!.availableRooms),
                          icon: Icons.event_available_outlined,
                          accent: AppColors.info,
                        ),
                        PartnerKpiTile(
                          label: l10n.partnerOccupancyStopSell,
                          value: formats.integer
                              .format(section.data!.stopSellDaysCount),
                          icon: Icons.block_outlined,
                          accent: AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (section.data!.hasNoInventory)
                      PartnerSectionEmpty(
                          message: l10n.partnerDashboardOccupancyNoInventory)
                    else if (section.data!.occupancyByDay.isEmpty)
                      PartnerSectionEmpty(
                          message: l10n.partnerDashboardChartEmpty)
                    else
                      PartnerTrendChart(
                        points: section.data!.occupancyByDay,
                        color: AppColors.turquoise600,
                        semanticLabel: l10n.partnerDashboardOccupancyChartLabel,
                        formatValue: (value) => formats.percent(value),
                        formatDate: (date) => formats.shortDate.format(date),
                      ),
                  ],
                ),
    );
  }
}

/// `GET /api/partner/analytics/revenue`.
class _RevenueSection extends StatelessWidget {
  final PartnerDashboardState dashboard;
  final Future<void> Function() onRetry;

  const _RevenueSection({required this.dashboard, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formats = PartnerNumberFormats.of(context);
    final section = dashboard.revenue;

    return PartnerDashboardSection(
      title: l10n.partnerDashboardRevenueHeading,
      scopeCaption: _scopeCaption(l10n, dashboard),
      child: section.isLoading
          ? const PartnerSectionLoading(lines: 4)
          : section.isFailed
              ? PartnerSectionFailure(
                  kind: section.errorKind,
                  message: section.message,
                  onRetry: onRetry,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PartnerKpiGrid(
                      minTileWidth: 180,
                      tiles: [
                        PartnerKpiTile(
                          label: l10n.partnerRevenueMonthToDate,
                          value: formats.money
                              .format(section.data!.revenueMonthToDate),
                          icon: Icons.calendar_month_rounded,
                          accent: AppColors.mint,
                        ),
                        PartnerKpiTile(
                          label: l10n.partnerRevenueLast30,
                          value: formats.money
                              .format(section.data!.revenueLast30Days),
                          icon: Icons.trending_up_rounded,
                          accent: AppColors.mint,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (section.data!.revenueByDay.isEmpty)
                      PartnerSectionEmpty(
                          message: l10n.partnerDashboardChartEmpty)
                    else
                      PartnerTrendChart(
                        points: section.data!.revenueByDay,
                        color: AppColors.ocean600,
                        semanticLabel: l10n.partnerDashboardRevenueChartLabel,
                        formatValue: (value) => formats.money.format(value),
                        formatDate: (date) => formats.shortDate.format(date),
                      ),
                    if (section.data!.revenueByHotel.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.partnerRevenueByProperty,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      for (final item in section.data!.revenueByHotel)
                        PartnerFinanceRow(
                          label: item.label,
                          value: formats.money.format(item.value),
                        ),
                    ],
                  ],
                ),
    );
  }
}

/// Finance. Seeded from the `financeSummary` already embedded in
/// `extranet/home` at the default scope, or fetched from
/// `GET /api/partner/finance/overview` once the scope narrows.
class _FinanceSection extends StatelessWidget {
  final PartnerDashboardState dashboard;
  final Future<void> Function() onRetry;

  const _FinanceSection({required this.dashboard, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formats = PartnerNumberFormats.of(context);
    final section = dashboard.finance;

    return PartnerDashboardSection(
      title: l10n.partnerDashboardFinanceHeading,
      scopeCaption: dashboard.isDefaultScope
          ? l10n.partnerDashboardScopeLast30AllProperties
          : _scopeCaption(l10n, dashboard),
      child: section.isLoading
          ? const PartnerSectionLoading(lines: 5)
          : section.isFailed
              ? PartnerSectionFailure(
                  kind: section.errorKind,
                  message: section.message,
                  onRetry: onRetry,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PartnerFinanceRow(
                      label: l10n.partnerFinanceGross,
                      value: formats.money.format(section.data!.grossRevenue),
                      emphasised: true,
                    ),
                    PartnerFinanceRow(
                      label: l10n.partnerFinanceCommission,
                      value:
                          formats.money.format(section.data!.commissionAmount),
                    ),
                    PartnerFinanceRow(
                      label: l10n.partnerFinanceTax,
                      value: formats.money.format(section.data!.estimatedTax),
                    ),
                    PartnerFinanceRow(
                      label: l10n.partnerFinanceRefunded,
                      value: formats.money.format(section.data!.refundedAmount),
                    ),
                    const Divider(height: AppSpacing.lg),
                    PartnerFinanceRow(
                      label: l10n.partnerFinanceNet,
                      value: formats.money.format(section.data!.netRevenue),
                      emphasised: true,
                    ),
                    PartnerFinanceRow(
                      label: l10n.partnerFinancePendingSettlement,
                      value:
                          formats.money.format(section.data!.pendingSettlement),
                    ),
                    PartnerFinanceRow(
                      label: l10n.partnerFinanceNextPayout,
                      // Nullable LocalDate in the DTO — no date means none is
                      // scheduled, not "today".
                      value: section.data!.nextEstimatedPayoutDate == null
                          ? l10n.partnerValueUnavailable
                          : formats.shortDate
                              .format(section.data!.nextEstimatedPayoutDate!),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        _HeaderFact(
                          icon: Icons.done_all_rounded,
                          text: l10n.partnerFinanceCompletedBookings(
                              section.data!.completedBookings),
                        ),
                        _HeaderFact(
                          icon: Icons.credit_score_rounded,
                          text: l10n.partnerFinancePaidBookings(
                              section.data!.paidBookings),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}

/// `GET /api/partner/extranet/activity-logs`.
class _ActivitySection extends StatelessWidget {
  final PartnerDashboardState dashboard;
  final Future<void> Function() onRetry;

  const _ActivitySection({required this.dashboard, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final section = dashboard.activity;

    return PartnerDashboardSection(
      title: l10n.partnerDashboardActivityHeading,
      scopeCaption: l10n.partnerDashboardScopeAllProperties,
      child: section.isLoading
          ? const PartnerSectionLoading(lines: 4)
          : section.isFailed
              ? PartnerSectionFailure(
                  kind: section.errorKind,
                  message: section.message,
                  onRetry: onRetry,
                )
              : section.data!.isEmpty
                  ? PartnerSectionEmpty(
                      message: l10n.partnerDashboardActivityEmpty)
                  : PartnerActivityList(entries: section.data!),
    );
  }
}

/// The caption every scoped panel shows, so a reader always knows which window
/// and which property produced the number above it.
String _scopeCaption(AppLocalizations l10n, PartnerDashboardState dashboard) {
  final window = switch (dashboard.range) {
    PartnerDashboardRange.last7 => l10n.partnerDashboardRangeLast7,
    PartnerDashboardRange.last30 => l10n.partnerDashboardRangeLast30,
    PartnerDashboardRange.last90 => l10n.partnerDashboardRangeLast90,
  };
  return dashboard.hotelId == null
      ? l10n.partnerDashboardScopeWindowAll(window)
      : l10n.partnerDashboardScopeWindowOne(window);
}
