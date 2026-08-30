import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_rate_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_radii.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../properties/widgets/partner_property_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_rates_state.dart';
import 'widgets/partner_rate_widgets.dart';

/// The Partner Rates module — rate plans for one room type.
///
/// ## Backend contract (verified in `backend-v1`/`develop` and live on :8081)
///
/// | Action | Endpoint | C5 |
/// |---|---|---|
/// | List plans | `GET /api/partner/rooms/{roomId}/rate-plans` | ✅ |
/// | Occupancy prices | `GET /api/partner/rate-plans/{id}/occupancy-prices` | ✅ |
/// | Pricing preview | `GET /api/partner/rate-plans/{id}/preview` | ✅ |
/// | Activate / deactivate | `POST /api/partner/rate-plans/{id}/(de)activate` | ✅ |
/// | Create / update / delete / duplicate | `POST`/`PUT`/`DELETE` | ⛔ |
/// | Occupancy price writes | `POST`/`PUT`/`DELETE` | ⛔ |
///
/// The writes are omitted for a specific reason, not for scope: `PUT
/// /rate-plans/{id}` runs `applyAndValidate`, which **nulls** `code`,
/// `description`, both cancellation fields, the stay limits and the advance-
/// booking limits whenever they are absent from the body. A partial edit form
/// would therefore silently erase a plan's configuration. `DELETE` is
/// irreversible and 409s when the plan parents derived plans.
///
/// ## Currency
///
/// `RatePlan` has **no currency** — not on the DTO, the entity or the table,
/// while `Booking`/`Invoice`/`Payment` do. Amounts are shown as grouped numbers
/// with no symbol, and the screen says so once.
///
/// ## Pricing safety
///
/// Changing a plan does not re-price stays already sold: `BookingService`
/// snapshots the plan's name, nightly rate and adjustment onto the booking at
/// creation. `RatePlan` also carries `@Version`, so concurrent edits conflict
/// rather than silently overwriting — unlike `RoomInventory` (see the C4 report).
class PartnerRatesScreen extends StatefulWidget {
  const PartnerRatesScreen({super.key});

  @override
  State<PartnerRatesScreen> createState() => _PartnerRatesScreenState();
}

class _PartnerRatesScreenState extends State<PartnerRatesScreen> {
  PartnerRatesState? _rates;
  PartnerState? _partner;
  int? _syncedPropertyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    final rebind = !identical(partner, _partner);
    if (rebind) {
      _partner = partner;
      _rates?.dispose();
      _rates = PartnerRatesState(api: partner.api);
      _syncedPropertyId = null;
    }

    final selected = partner.selectedPropertyId;
    if (partner.isReady && (rebind || selected != _syncedPropertyId)) {
      _syncedPropertyId = selected;
      final rates = _rates!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) rates.load(partner, selected);
      });
    }
  }

  @override
  void dispose() {
    _rates?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final partner = _partner;
    final rates = _rates;
    if (partner == null || rates == null) return;
    await rates.load(partner, partner.selectedPropertyId);
  }

  @override
  Widget build(BuildContext context) {
    final partner = PartnerScope.of(context);
    final rates = _rates;

    if (!partner.isReady || rates == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return AnimatedBuilder(
      animation: rates,
      builder: (context, _) =>
          _RatesBody(partner: partner, rates: rates, onReload: _reload),
    );
  }
}

class _RatesBody extends StatelessWidget {
  final PartnerState partner;
  final PartnerRatesState rates;
  final Future<void> Function() onReload;

  const _RatesBody({
    required this.partner,
    required this.rates,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (rates.status) {
      case PartnerRatesStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
            status: PartnerWorkspaceStatus.unauthorized);
      case PartnerRatesStatus.forbidden:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.forbidden,
          detail: rates.errorMessage,
          onPrimaryAction: onReload,
        );
      case PartnerRatesStatus.error:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.error,
          detail: rates.errorMessage,
          onPrimaryAction: onReload,
        );
      default:
        break;
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.desktop;
    final detailOpen = rates.openPlanId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RatesHeader(partner: partner, rates: rates, onReload: onReload),
        const SizedBox(height: AppSpacing.md),
        if (rates.rooms.isNotEmpty) ...[
          _RatesScopeBar(partner: partner, rates: rates),
          const SizedBox(height: AppSpacing.md),
        ],
        _body(context, l10n, isWide, detailOpen),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    bool isWide,
    bool detailOpen,
  ) {
    switch (rates.status) {
      case PartnerRatesStatus.noProperties:
        return OceanStateView(
          icon: Icons.apartment_outlined,
          title: l10n.partnerRatesNoPropertiesTitle,
          message: l10n.partnerRatesNoPropertiesMessage,
          semanticLabel: l10n.partnerRatesNoPropertiesTitle,
        );
      case PartnerRatesStatus.noPropertySelected:
        return OceanStateView(
          icon: Icons.touch_app_outlined,
          title: l10n.partnerRatesSelectPropertyTitle,
          message: l10n.partnerRatesSelectPropertyMessage,
          semanticLabel: l10n.partnerRatesSelectPropertyTitle,
        );
      case PartnerRatesStatus.noRooms:
        return OceanStateView(
          icon: Icons.meeting_room_outlined,
          title: l10n.partnerRatesNoRoomsTitle,
          message: l10n.partnerRatesNoRoomsMessage,
          semanticLabel: l10n.partnerRatesNoRoomsTitle,
        );
      case PartnerRatesStatus.noRoomSelected:
        return OceanStateView(
          icon: Icons.touch_app_outlined,
          title: l10n.partnerRatesSelectRoomTitle,
          message: l10n.partnerRatesSelectRoomMessage,
          semanticLabel: l10n.partnerRatesSelectRoomTitle,
        );
      case PartnerRatesStatus.notFound:
        return OceanStateView(
          icon: Icons.error_outline_rounded,
          title: l10n.partnerRatesUnavailableTitle,
          message: l10n.partnerRatesUnavailableMessage,
          semanticLabel: l10n.partnerRatesUnavailableTitle,
          actionLabel: l10n.partnerActionRetry,
          onAction: onReload,
        );
      case PartnerRatesStatus.idle:
      case PartnerRatesStatus.loading:
      case PartnerRatesStatus.loadingRooms:
        return const _RatesLoading();
      case PartnerRatesStatus.ready:
        if (rates.isEmpty) {
          return OceanStateView(
            icon: Icons.sell_outlined,
            title: l10n.partnerRatesEmptyTitle,
            message: l10n.partnerRatesEmptyMessage,
            semanticLabel: l10n.partnerRatesEmptyTitle,
          );
        }
        final list = _RatePlanList(
          partner: partner,
          rates: rates,
          compact: isWide && detailOpen,
        );
        if (isWide && detailOpen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: list),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 3, child: _RatePlanDetailPanel(rates: rates)),
            ],
          );
        }
        if (detailOpen) return _RatePlanDetailPanel(rates: rates);
        return list;
      default:
        return const SizedBox.shrink();
    }
  }
}

class _RatesHeader extends StatelessWidget {
  final PartnerState partner;
  final PartnerRatesState rates;
  final Future<void> Function() onReload;

  const _RatesHeader({
    required this.partner,
    required this.rates,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final property = partner.selectedProperty;
    final room = rates.selectedRoom;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.partnerNavPricing,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      property == null
                          ? l10n.partnerRatesNoPropertyContext
                          : room == null
                              ? l10n.partnerRatesForProperty(property.name)
                              : l10n.partnerRatesForRoom(
                                  room.roomName, property.name),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: rates.isLoading ? null : onReload,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.partnerActionRefresh,
              ),
            ],
          ),
          if (rates.isReady && rates.plans.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xxs,
              children: [
                _Fact(
                  icon: Icons.sell_outlined,
                  text: l10n.partnerRatesCount(rates.plans.length),
                ),
                _Fact(
                  icon: Icons.toggle_on_rounded,
                  text: l10n.partnerRatesActiveCount(rates.activePlanCount),
                ),
                if (rates.expiredPlanCount > 0)
                  _Fact(
                    icon: Icons.event_busy_outlined,
                    text: l10n.partnerRatesExpiredCount(rates.expiredPlanCount),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Stated once, here, rather than repeated beside every figure.
            Text(
              l10n.partnerRateCurrencyNote,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
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

class _RatesScopeBar extends StatelessWidget {
  final PartnerState partner;
  final PartnerRatesState rates;

  const _RatesScopeBar({required this.partner, required this.rates});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Widget group(String title, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            child,
          ],
        );

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (partner.properties.length > 1) ...[
            group(
              l10n.partnerRatesPropertyScope,
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final property in partner.properties)
                    _Chip(
                      label: property.name,
                      selected: partner.selectedPropertyId == property.id,
                      enabled: !rates.isLoading,
                      onTap: () => partner.selectProperty(property.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          group(
            l10n.partnerRatesRoomScope,
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final room in rates.rooms)
                  _Chip(
                    label: room.roomName,
                    selected: rates.selectedRoomId == room.id,
                    enabled: !rates.isLoading,
                    onTap: () => rates.selectRoom(room.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      onSelected: enabled ? (_) => onTap() : null,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.textInverse : AppColors.textPrimary,
      ),
      selectedColor: AppColors.ocean700,
      backgroundColor: AppColors.surfaceMuted,
      showCheckmark: false,
    );
  }
}

class _RatesLoading extends StatelessWidget {
  const _RatesLoading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.partnerStatusLoadingTitle,
      liveRegion: true,
      child: OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RatePlanList extends StatelessWidget {
  final PartnerState partner;
  final PartnerRatesState rates;
  final bool compact;

  const _RatePlanList({
    required this.partner,
    required this.rates,
    required this.compact,
  });

  /// `PartnerPricingService` applies no `PartnerTeamRole` check — it resolves
  /// the caller with `partnerProfileRepo.findByUserId`, so only the profile
  /// owner reaches these endpoints. Gating on OWNER mirrors that exactly;
  /// unknown fails closed. UX only — the backend re-checks every request.
  bool get _canEdit => partner.teamRole == PartnerTeamRole.owner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_canEdit) ...[
          _Notice(message: l10n.partnerRateActionsOwnerOnly),
          const SizedBox(height: AppSpacing.sm),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppSpacing.sm;
            final columns =
                compact ? 1 : (constraints.maxWidth / 340).floor().clamp(1, 3);
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final plan in rates.plans)
                  SizedBox(
                    width: width,
                    child: PartnerRatePlanCard(
                      plan: plan,
                      open: rates.openPlanId == plan.id,
                      actionPending: rates.pendingActionPlanId == plan.id,
                      canEdit: _canEdit,
                      onOpen: () => rates.openPlan(plan.id),
                      onToggleActive:
                          _canEdit ? () => _toggle(context, plan) : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, PartnerRatePlan plan) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await rates.setActive(plan.id, activate: !plan.active);
    if (!context.mounted) return;

    final message = switch (result) {
      PartnerRateActionResult.success => plan.active
          ? l10n.partnerRateDeactivatedMessage(plan.rateName)
          : l10n.partnerRateActivatedMessage(plan.rateName),
      PartnerRateActionResult.unauthorized =>
        l10n.partnerDashboardErrorUnauthorized,
      PartnerRateActionResult.forbidden => l10n.partnerDashboardErrorForbidden,
      PartnerRateActionResult.notFound => l10n.partnerRateActionNotFound,
      PartnerRateActionResult.conflict => l10n.partnerRateActionConflict,
      PartnerRateActionResult.uncertain => l10n.partnerPropertyActionUncertain,
      PartnerRateActionResult.failed => l10n.partnerPropertyActionFailed,
    };
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Notice extends StatelessWidget {
  final String message;

  const _Notice({required this.message});

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
}

class _RatePlanDetailPanel extends StatelessWidget {
  final PartnerRatesState rates;

  const _RatePlanDetailPanel({required this.rates});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final plan = rates.openedPlan;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.partnerRateDetailHeading,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: rates.closePlan,
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.partnerRateCloseDetail,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (plan == null)
            const SizedBox.shrink()
          else
            _RatePlanDetail(plan: plan, rates: rates),
        ],
      ),
    );
  }
}

class _RatePlanDetail extends StatelessWidget {
  final PartnerRatePlan plan;
  final PartnerRatesState rates;

  const _RatePlanDetail({required this.plan, required this.rates});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerRateFormats.of(context);

    String? nights(int? value) => value == null
        ? null
        : l10n.partnerRateNightsValue(f.integer.format(value));
    String? days(int? value) => value == null
        ? null
        : l10n.partnerRateDaysValue(f.integer.format(value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          plan.rateName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            OceanStatusPill(
              label: partnerRateTypeLabel(l10n, plan.rateType),
              color: AppColors.ocean600,
              icon: Icons.local_offer_outlined,
            ),
            OceanStatusPill(
              label: partnerRateSourceLabel(l10n, plan.sourceType),
              color: plan.isDerived ? AppColors.violet : AppColors.ocean700,
              icon: plan.isDerived
                  ? Icons.call_split_rounded
                  : Icons.anchor_rounded,
            ),
            OceanStatusPill(
              label: plan.active
                  ? l10n.partnerRateActive
                  : l10n.partnerRateInactive,
              color: plan.active ? AppColors.success : AppColors.textTertiary,
              icon: plan.active
                  ? Icons.toggle_on_rounded
                  : Icons.toggle_off_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PartnerPropertySection(
          title: l10n.partnerRateSectionIdentity,
          children: [
            PartnerPropertyField(
                label: l10n.partnerRateFieldCode, value: plan.code),
            PartnerPropertyField(
                label: l10n.partnerRateFieldDescription,
                value: plan.description),
            PartnerPropertyField(
              label: l10n.partnerRateFieldPriority,
              value: f.integer.format(plan.priority),
            ),
          ],
        ),
        PartnerPropertySection(
          title: l10n.partnerRateSectionPricing,
          children: [
            PartnerRateAmountRow(
              label: l10n.partnerRateFieldPricePerNight,
              value: plan.pricePerNight == null
                  ? null
                  : f.amount.format(plan.pricePerNight),
              emphasis: true,
            ),
            PartnerRateAmountRow(
              label: l10n.partnerRateFieldExtraBedPrice,
              value: plan.extraBedPrice == null
                  ? null
                  : f.amount.format(plan.extraBedPrice),
            ),
            // Adjustment only means anything on a DERIVED plan.
            if (plan.isDerived) ...[
              PartnerPropertyField(
                label: l10n.partnerRateFieldAdjustmentType,
                value: plan.adjustmentType == null
                    ? null
                    : partnerRateAdjustmentLabel(l10n, plan.adjustmentType!),
              ),
              PartnerRateAmountRow(
                label: l10n.partnerRateFieldAdjustmentValue,
                value: plan.adjustmentValue == null
                    ? null
                    : plan.adjustmentType ==
                            PartnerRateAdjustmentType.percentage
                        ? '${f.percent.format(plan.adjustmentValue)}%'
                        : f.amount.format(plan.adjustmentValue),
              ),
              PartnerPropertyField(
                label: l10n.partnerRateFieldParentPlan,
                value: plan.parentRatePlanId == null
                    ? null
                    : f.integer.format(plan.parentRatePlanId),
              ),
            ],
          ],
        ),
        PartnerPropertySection(
          title: l10n.partnerRateSectionValidity,
          children: [
            PartnerPropertyField(
              label: l10n.partnerRateFieldValidFrom,
              value: plan.startDate == null
                  ? null
                  : f.date.format(plan.startDate!),
            ),
            PartnerPropertyField(
              label: l10n.partnerRateFieldValidTo,
              value: plan.endDate == null ? null : f.date.format(plan.endDate!),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                l10n.partnerRateValidityNote,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
        PartnerPropertySection(
          title: l10n.partnerRateSectionRestrictions,
          children: [
            PartnerPropertyField(
                label: l10n.partnerRateFieldMinStay,
                value: nights(plan.minStayNights)),
            PartnerPropertyField(
                label: l10n.partnerRateFieldMaxStay,
                value: nights(plan.maxStayNights)),
            PartnerPropertyField(
                label: l10n.partnerRateFieldMinAdvance,
                value: days(plan.minAdvanceBookingDays)),
            PartnerPropertyField(
                label: l10n.partnerRateFieldMaxAdvance,
                value: days(plan.maxAdvanceBookingDays)),
            PartnerPropertyField(
              label: l10n.partnerRateFieldClosedToArrival,
              value: plan.closedToArrival
                  ? l10n.partnerRoomYes
                  : l10n.partnerRoomNo,
            ),
            PartnerPropertyField(
              label: l10n.partnerRateFieldClosedToDeparture,
              value: plan.closedToDeparture
                  ? l10n.partnerRoomYes
                  : l10n.partnerRoomNo,
            ),
          ],
        ),
        PartnerPropertySection(
          title: l10n.partnerRateSectionCancellation,
          children: [
            PartnerPropertyField(
              label: l10n.partnerRateFieldPolicy,
              value: plan.cancellationPolicyType == null
                  ? null
                  : partnerCancellationLabel(
                      l10n, plan.cancellationPolicyType!),
            ),
            PartnerPropertyField(
              label: l10n.partnerRateFieldRefundable,
              value: plan.refundable ? l10n.partnerRoomYes : l10n.partnerRoomNo,
            ),
            PartnerPropertyField(
              label: l10n.partnerRateFieldDeadlineHours,
              value: plan.cancellationDeadlineHours == null
                  ? null
                  : f.integer.format(plan.cancellationDeadlineHours),
            ),
            PartnerPropertyField(
              label: l10n.partnerRateFieldPenaltyPercent,
              value: plan.cancellationPenaltyPercent == null
                  ? null
                  : '${f.percent.format(plan.cancellationPenaltyPercent)}%',
            ),
          ],
        ),
        PartnerPropertySection(
          title: l10n.partnerRateSectionInclusions,
          children: [
            PartnerPropertyField(
              label: l10n.partnerRateFieldMealPlan,
              value: plan.mealPlanType == null
                  ? null
                  : partnerMealPlanLabel(l10n, plan.mealPlanType!),
            ),
            PartnerPropertyField(
              label: l10n.partnerRateFieldOccupancyPricing,
              value: plan.occupancyPricingEnabled
                  ? l10n.partnerRoomYes
                  : l10n.partnerRoomNo,
            ),
            PartnerPropertyField(
              label: l10n.partnerRateFieldChildPricing,
              value: plan.childPricingEnabled
                  ? l10n.partnerRoomYes
                  : l10n.partnerRoomNo,
            ),
          ],
        ),
        _OccupancyPrices(rates: rates),
      ],
    );
  }
}

/// Occupancy prices for the open plan (`GET /rate-plans/{id}/occupancy-prices`).
class _OccupancyPrices extends StatelessWidget {
  final PartnerRatesState rates;

  const _OccupancyPrices({required this.rates});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = PartnerRateFormats.of(context);

    if (rates.isDetailLoading) {
      return PartnerPropertySection(
        title: l10n.partnerRateSectionOccupancy,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (rates.detailErrorKind != null) {
      final text = switch (rates.detailErrorKind) {
        ApiErrorKind.unauthorized => l10n.partnerDashboardErrorUnauthorized,
        ApiErrorKind.forbidden => l10n.partnerDashboardErrorForbidden,
        ApiErrorKind.notFound => l10n.partnerRateActionNotFound,
        ApiErrorKind.timeout => l10n.partnerDashboardErrorTimeout,
        ApiErrorKind.network => l10n.partnerDashboardErrorNetwork,
        _ => l10n.partnerDashboardErrorGeneric,
      };
      return PartnerPropertySection(
        title: l10n.partnerRateSectionOccupancy,
        children: [
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    final prices = rates.occupancyPrices;
    return PartnerPropertySection(
      title: l10n.partnerRateSectionOccupancy,
      children: [
        if (prices.isEmpty)
          Text(
            l10n.partnerRateOccupancyEmpty,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          )
        else
          for (final price in prices)
            PartnerRateAmountRow(
              label: l10n.partnerRateOccupancyLabel(
                f.integer.format(price.adults),
                f.integer.format(price.children),
              ),
              value: price.pricePerNight == null
                  ? null
                  : f.amount.format(price.pricePerNight),
            ),
      ],
    );
  }
}
