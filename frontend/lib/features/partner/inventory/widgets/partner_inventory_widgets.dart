import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/partner/partner_inventory_models.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_radii.dart';
import '../../../../design/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

/// Per-day restriction chips. Each maps to one backend flag and one PATCH
/// endpoint, so the three are never merged into a single "closed" badge — they
/// have different effects and different fixes.
class PartnerInventoryFlagChip extends StatelessWidget {
  final String label;
  final bool value;
  final IconData icon;
  final Color activeColor;
  final bool enabled;
  final bool pending;
  final ValueChanged<bool>? onChanged;

  const PartnerInventoryFlagChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.activeColor,
    this.enabled = true,
    this.pending = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interactive = enabled && onChanged != null && !pending;

    return Semantics(
      button: interactive,
      enabled: interactive,
      toggled: value,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: value
              ? activeColor.withValues(alpha: 0.14)
              : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: InkWell(
            onTap: interactive ? () => onChanged!(!value) : null,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Container(
              constraints:
                  const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pending)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      icon,
                      size: 15,
                      color: value ? activeColor : AppColors.textTertiary,
                    ),
                  const SizedBox(width: AppSpacing.xxs),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: value ? activeColor : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One inventory day rendered as a card — the mobile and tablet representation.
///
/// Carries exactly the same data as the desktop table row; a dense table is not
/// squeezed onto a phone and nothing is dropped to make it fit.
class PartnerInventoryDayCard extends StatelessWidget {
  final PartnerInventoryDay day;
  final bool pending;
  final bool canEdit;
  final void Function(PartnerInventoryFlag flag, bool value)? onFlagChanged;

  const PartnerInventoryDayCard({
    super.key,
    required this.day,
    required this.pending,
    required this.canEdit,
    this.onFlagChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.MMMEd(locale);
    final number = NumberFormat('#,##0', locale);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: day.hasRestriction ? AppColors.warning : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateFmt.format(day.date),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PartnerInventoryStateBadge(day: day),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xxs,
            children: [
              _Metric(
                label: l10n.partnerInventoryTotal,
                value: number.format(day.totalInventory),
              ),
              _Metric(
                label: l10n.partnerInventoryAvailable,
                value: number.format(day.availableInventory),
                emphasis: true,
              ),
              _Metric(
                label: l10n.partnerInventorySold,
                value: number.format(day.soldInventory),
              ),
              _Metric(
                label: l10n.partnerInventoryBlocked,
                value: number.format(day.blockedInventory),
              ),
              _Metric(
                label: l10n.partnerInventoryMaintenance,
                value: number.format(day.maintenanceInventory),
              ),
            ],
          ),
          if (day.isInconsistent) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.partnerInventoryInconsistent,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.warning),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          PartnerInventoryFlagRow(
            day: day,
            pending: pending,
            canEdit: canEdit,
            onFlagChanged: onFlagChanged,
          ),
        ],
      ),
    );
  }
}

/// The three restriction toggles for one day.
class PartnerInventoryFlagRow extends StatelessWidget {
  final PartnerInventoryDay day;
  final bool pending;
  final bool canEdit;
  final void Function(PartnerInventoryFlag flag, bool value)? onFlagChanged;

  const PartnerInventoryFlagRow({
    super.key,
    required this.day,
    required this.pending,
    required this.canEdit,
    this.onFlagChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        PartnerInventoryFlagChip(
          label: l10n.partnerInventoryStopSell,
          value: day.stopSell,
          icon: Icons.block_outlined,
          activeColor: AppColors.danger,
          enabled: canEdit,
          pending: pending,
          onChanged: onFlagChanged == null
              ? null
              : (v) => onFlagChanged!(PartnerInventoryFlag.stopSell, v),
        ),
        PartnerInventoryFlagChip(
          label: l10n.partnerInventoryClosedArrival,
          value: day.closedArrival,
          icon: Icons.login_rounded,
          activeColor: AppColors.warning,
          enabled: canEdit,
          pending: pending,
          onChanged: onFlagChanged == null
              ? null
              : (v) => onFlagChanged!(PartnerInventoryFlag.closedArrival, v),
        ),
        PartnerInventoryFlagChip(
          label: l10n.partnerInventoryClosedDeparture,
          value: day.closedDeparture,
          icon: Icons.logout_rounded,
          activeColor: AppColors.warning,
          enabled: canEdit,
          pending: pending,
          onChanged: onFlagChanged == null
              ? null
              : (v) => onFlagChanged!(PartnerInventoryFlag.closedDeparture, v),
        ),
      ],
    );
  }
}

/// Whether guests can book this date, using the backend's own rule.
///
/// Deliberately three distinct readings — "stopped", "sold out" and "bookable"
/// have different causes, and collapsing them would hide which lever to pull.
class PartnerInventoryStateBadge extends StatelessWidget {
  final PartnerInventoryDay day;

  const PartnerInventoryStateBadge({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color, icon) = day.stopSell
        ? (
            l10n.partnerInventoryStateStopped,
            AppColors.danger,
            Icons.block_outlined
          )
        : day.isSoldOut
            ? (
                l10n.partnerInventoryStateSoldOut,
                AppColors.warning,
                Icons.event_busy_outlined
              )
            : (
                l10n.partnerInventoryStateBookable,
                AppColors.success,
                Icons.check_circle_outline_rounded
              );

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
              // Flexible, not a bare Text: this badge renders inside a
              // fixed-width table column, where the longer labels (and the
              // Vietnamese strings) would otherwise overflow the row.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasis;

  const _Metric({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: emphasis ? AppColors.ocean700 : AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
