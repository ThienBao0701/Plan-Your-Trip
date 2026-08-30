import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/partner/partner_rate_models.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_radii.dart';
import '../../../../design/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_widgets.dart';

/// Formats rate amounts.
///
/// **No currency symbol is applied.** `RatePlan` carries no currency on the DTO,
/// the entity or the table — only `Booking`/`Invoice`/`Payment` do. Rendering
/// `₫` because the app has a Vietnamese locale would assert something the rate
/// API never said, so amounts are grouped numbers and the screen states once
/// that the backend supplies no currency.
class PartnerRateFormats {
  final NumberFormat amount;
  final NumberFormat integer;
  final NumberFormat percent;
  final DateFormat date;
  final DateFormat dateTime;

  PartnerRateFormats(String locale)
      : amount = NumberFormat('#,##0.##', locale),
        integer = NumberFormat('#,##0', locale),
        percent = NumberFormat('#,##0.#', locale),
        date = DateFormat.yMMMd(locale),
        dateTime = DateFormat.yMMMd(locale).add_Hm();

  static PartnerRateFormats of(BuildContext context) =>
      PartnerRateFormats(Localizations.localeOf(context).toString());
}

String partnerRateTypeLabel(AppLocalizations l10n, PartnerRatePlanType type) =>
    switch (type) {
      PartnerRatePlanType.standard => l10n.partnerRateTypeStandard,
      PartnerRatePlanType.promotional => l10n.partnerRateTypePromotional,
      PartnerRatePlanType.member => l10n.partnerRateTypeMember,
      PartnerRatePlanType.earlyBird => l10n.partnerRateTypeEarlyBird,
      PartnerRatePlanType.lastMinute => l10n.partnerRateTypeLastMinute,
      PartnerRatePlanType.unknown => l10n.partnerRateTypeUnknown,
    };

String partnerMealPlanLabel(AppLocalizations l10n, PartnerMealPlanType type) =>
    switch (type) {
      PartnerMealPlanType.roomOnly => l10n.partnerMealPlanRoomOnly,
      PartnerMealPlanType.breakfast => l10n.partnerMealPlanBreakfast,
      PartnerMealPlanType.halfBoard => l10n.partnerMealPlanHalfBoard,
      PartnerMealPlanType.fullBoard => l10n.partnerMealPlanFullBoard,
      PartnerMealPlanType.allInclusive => l10n.partnerMealPlanAllInclusive,
      PartnerMealPlanType.unknown => l10n.partnerMealPlanUnknown,
    };

String partnerCancellationLabel(
  AppLocalizations l10n,
  PartnerCancellationPolicyType type,
) =>
    switch (type) {
      PartnerCancellationPolicyType.freeCancellation =>
        l10n.partnerCancellationFree,
      PartnerCancellationPolicyType.partiallyRefundable =>
        l10n.partnerCancellationPartial,
      PartnerCancellationPolicyType.nonRefundable =>
        l10n.partnerCancellationNonRefundable,
      PartnerCancellationPolicyType.custom => l10n.partnerCancellationCustom,
      PartnerCancellationPolicyType.unknown => l10n.partnerCancellationUnknown,
    };

String partnerRateSourceLabel(
  AppLocalizations l10n,
  PartnerRateSourceType type,
) =>
    switch (type) {
      PartnerRateSourceType.base => l10n.partnerRateSourceBase,
      PartnerRateSourceType.derived => l10n.partnerRateSourceDerived,
      PartnerRateSourceType.unknown => l10n.partnerRateSourceUnknown,
    };

String partnerRateAdjustmentLabel(
  AppLocalizations l10n,
  PartnerRateAdjustmentType type,
) =>
    switch (type) {
      PartnerRateAdjustmentType.fixedAmount => l10n.partnerRateAdjustmentFixed,
      PartnerRateAdjustmentType.percentage => l10n.partnerRateAdjustmentPercent,
      PartnerRateAdjustmentType.unknown => l10n.partnerRateAdjustmentUnknown,
    };

/// One rate plan in the list.
///
/// Shows only `RatePlanResponse` fields. Amounts appear without a currency
/// symbol; nothing is summed, discounted or projected on the client.
class PartnerRatePlanCard extends StatelessWidget {
  final PartnerRatePlan plan;
  final bool open;
  final bool actionPending;
  final bool canEdit;
  final VoidCallback onOpen;
  final VoidCallback? onToggleActive;

  const PartnerRatePlanCard({
    super.key,
    required this.plan,
    required this.open,
    required this.actionPending,
    required this.canEdit,
    required this.onOpen,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final formats = PartnerRateFormats.of(context);
    final expired = plan.isExpired();

    return Semantics(
      button: true,
      label: [
        plan.rateName,
        partnerRateTypeLabel(l10n, plan.rateType),
        plan.active ? l10n.partnerRateActive : l10n.partnerRateInactive,
        if (expired) l10n.partnerRateExpired,
      ].join('. '),
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: open ? AppColors.ocean600 : AppColors.divider,
              width: open ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppRadii.md),
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
                            plan.rateName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (plan.code != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              plan.code!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    // The nightly amount is the headline figure, deliberately
                    // rendered without a symbol.
                    Text(
                      plan.pricePerNight == null
                          ? l10n.partnerPropertyNotSet
                          : l10n.partnerRatePerNight(
                              formats.amount.format(plan.pricePerNight)),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ocean700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OceanStatusPill(
                          label: partnerRateTypeLabel(l10n, plan.rateType),
                          color: AppColors.ocean600,
                          icon: Icons.local_offer_outlined,
                        ),
                        OceanStatusPill(
                          label: plan.active
                              ? l10n.partnerRateActive
                              : l10n.partnerRateInactive,
                          color: plan.active
                              ? AppColors.success
                              : AppColors.textTertiary,
                          icon: plan.active
                              ? Icons.toggle_on_rounded
                              : Icons.toggle_off_outlined,
                        ),
                        if (plan.isDerived)
                          OceanStatusPill(
                            label: l10n.partnerRateSourceDerived,
                            color: AppColors.violet,
                            icon: Icons.call_split_rounded,
                          ),
                        // Expired is a fact about the dates and is reported
                        // separately from the active flag — a plan can be both.
                        if (expired)
                          OceanStatusPill(
                            label: l10n.partnerRateExpired,
                            color: AppColors.warning,
                            icon: Icons.event_busy_outlined,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        if (plan.startDate != null && plan.endDate != null)
                          _Fact(
                            icon: Icons.date_range_rounded,
                            text: l10n.partnerRateValidity(
                              formats.date.format(plan.startDate!),
                              formats.date.format(plan.endDate!),
                            ),
                          ),
                        if (plan.mealPlanType != null)
                          _Fact(
                            icon: Icons.restaurant_outlined,
                            text:
                                partnerMealPlanLabel(l10n, plan.mealPlanType!),
                          ),
                        _Fact(
                          icon: Icons.low_priority_rounded,
                          text: l10n.partnerRatePriorityValue(
                              formats.integer.format(plan.priority)),
                        ),
                        if (plan.hasRestrictions)
                          _Fact(
                            icon: Icons.rule_rounded,
                            text: l10n.partnerRateHasRestrictions,
                          ),
                      ],
                    ),
                    if (onToggleActive != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: actionPending
                            ? const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : OceanSecondaryButton(
                                label: plan.active
                                    ? l10n.partnerRateDeactivateAction
                                    : l10n.partnerRateActivateAction,
                                icon: plan.active
                                    ? Icons.toggle_off_outlined
                                    : Icons.toggle_on_rounded,
                                fullWidth: false,
                                onPressed: onToggleActive,
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
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
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      );
}

/// A labelled money row. The absence of a currency symbol is intentional and is
/// explained once on the screen rather than repeated per row.
class PartnerRateAmountRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool emphasis;

  const PartnerRateAmountRow({
    super.key,
    required this.label,
    this.value,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shown = value ?? l10n.partnerPropertyNotSet;

    return Semantics(
      container: true,
      label: '$label: $shown',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: emphasis
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                shown,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: value == null
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                  fontStyle:
                      value == null ? FontStyle.italic : FontStyle.normal,
                  fontWeight: emphasis ? FontWeight.w800 : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
