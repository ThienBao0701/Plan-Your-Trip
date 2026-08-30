import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design/app_colors.dart';
import '../../../../design/app_radii.dart';
import '../../../../design/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../partner_calendar_state.dart';

/// Date and number formats for the calendar.
///
/// Every format is locale-driven — `DateFormat.E`/`.d`/`.yMMMd` follow the
/// operator's locale rather than a hard-coded pattern.
class PartnerCalendarFormats {
  final DateFormat weekday;
  final DateFormat dayOfMonth;
  final DateFormat monthDay;
  final DateFormat full;
  final NumberFormat integer;

  PartnerCalendarFormats(String locale)
      : weekday = DateFormat.E(locale),
        dayOfMonth = DateFormat.d(locale),
        monthDay = DateFormat.MMMd(locale),
        full = DateFormat.yMMMd(locale),
        integer = NumberFormat('#,##0', locale);

  static PartnerCalendarFormats of(BuildContext context) =>
      PartnerCalendarFormats(Localizations.localeOf(context).toString());
}

String partnerNightStateLabel(AppLocalizations l10n, PartnerNightState state) =>
    switch (state) {
      PartnerNightState.open => l10n.partnerCalendarStateOpen,
      PartnerNightState.soldOut => l10n.partnerCalendarStateSoldOut,
      PartnerNightState.stopSell => l10n.partnerCalendarStateStopSell,
      PartnerNightState.noRecord => l10n.partnerCalendarStateNoRecord,
    };

/// Colour **and** icon for a night state — colour is never the only signal.
({Color color, IconData icon}) partnerNightStateVisual(
        PartnerNightState state) =>
    switch (state) {
      PartnerNightState.open => (
          color: AppColors.success,
          icon: Icons.check_circle_outline_rounded
        ),
      PartnerNightState.soldOut => (
          color: AppColors.ocean700,
          icon: Icons.do_not_disturb_on_outlined
        ),
      PartnerNightState.stopSell => (
          color: AppColors.danger,
          icon: Icons.block_rounded
        ),
      PartnerNightState.noRecord => (
          color: AppColors.textTertiary,
          icon: Icons.help_outline_rounded
        ),
    };

/// The legend. Every entry maps to a real backend condition, and the four
/// availability questions are kept apart rather than merged into one word.
class PartnerCalendarLegend extends StatelessWidget {
  const PartnerCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.partnerCalendarLegendHeading,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (final state in PartnerNightState.values)
              _LegendEntry(
                color: partnerNightStateVisual(state).color,
                icon: partnerNightStateVisual(state).icon,
                label: partnerNightStateLabel(l10n, state),
              ),
            _LegendEntry(
              color: AppColors.warning,
              icon: Icons.login_rounded,
              label: l10n.partnerCalendarLegendClosedArrival,
            ),
            _LegendEntry(
              color: AppColors.warning,
              icon: Icons.logout_rounded,
              label: l10n.partnerCalendarLegendClosedDeparture,
            ),
            _LegendEntry(
              color: AppColors.violet,
              icon: Icons.person_rounded,
              label: l10n.partnerCalendarLegendOccupied,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          // The single most misread thing on an operations calendar.
          l10n.partnerCalendarLegendNote,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendEntry({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(AppRadii.xs),
              border: Border.all(color: color.withValues(alpha: .5)),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
}

/// One room-night square in the grid.
///
/// Shows the night's state, the arrival/departure restrictions as separate
/// corner marks, and the backend's own sold count. It renders nothing it did not
/// receive: a night with no inventory row is drawn as unknown, not as free.
class PartnerCalendarCellTile extends StatelessWidget {
  final PartnerCalendarCell cell;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  const PartnerCalendarCellTile({
    super.key,
    required this.cell,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = PartnerCalendarFormats.of(context);
    final visual = partnerNightStateVisual(cell.state);
    final day = cell.day;

    return Semantics(
      button: true,
      label: [
        f.full.format(cell.date),
        partnerNightStateLabel(l10n, cell.state),
        if (cell.isOccupied)
          l10n.partnerCalendarSoldValue(f.integer.format(cell.sold)),
        if (day?.closedArrival ?? false)
          l10n.partnerCalendarLegendClosedArrival,
        if (day?.closedDeparture ?? false)
          l10n.partnerCalendarLegendClosedDeparture,
      ].join('. '),
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.xs),
            child: Container(
              height: 54,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(AppRadii.xs),
                border: Border.all(
                  color: selected
                      ? AppColors.ocean700
                      : isToday
                          ? AppColors.ocean600
                          : visual.color.withValues(alpha: .35),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(visual.icon, size: 14, color: visual.color),
                        if (day != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            f.integer.format(day.availableInventory),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: visual.color,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Occupancy, straight from `soldInventory`.
                  if (cell.isOccupied)
                    PositionedDirectional(
                      bottom: 2,
                      start: 3,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_rounded,
                              size: 9, color: AppColors.violet),
                          Text(
                            f.integer.format(cell.sold),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.violet,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // CTA and CTD are separate marks because they restrict
                  // different things — the first night and the last night.
                  if (day?.closedArrival ?? false)
                    const PositionedDirectional(
                      top: 2,
                      start: 3,
                      child: Icon(Icons.login_rounded,
                          size: 10, color: AppColors.warning),
                    ),
                  if (day?.closedDeparture ?? false)
                    const PositionedDirectional(
                      top: 2,
                      end: 3,
                      child: Icon(Icons.logout_rounded,
                          size: 10, color: AppColors.warning),
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

/// The day column header.
class PartnerCalendarDayHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;

  const PartnerCalendarDayHeader({
    super.key,
    required this.date,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final f = PartnerCalendarFormats.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          Text(
            f.weekday.format(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isToday ? AppColors.ocean700 : AppColors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            f.dayOfMonth.format(date),
            style: theme.textTheme.labelLarge?.copyWith(
              color: isToday ? AppColors.ocean700 : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// The room label at the start of each grid row.
class PartnerCalendarRoomHeader extends StatelessWidget {
  final String roomName;
  final String? roomCode;
  final bool hasError;

  const PartnerCalendarRoomHeader({
    super.key,
    required this.roomName,
    this.roomCode,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            roomName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (roomCode != null)
            Text(
              roomCode!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          if (hasError)
            const Icon(Icons.cloud_off_rounded,
                size: 14, color: AppColors.danger),
        ],
      ),
    );
  }
}

/// One room's row in the mobile day view.
///
/// Mobile gets a **focused single day** rather than a fourteen-column grid: one
/// card per room for the chosen date, with the same facts the grid cell carries.
class PartnerCalendarDayRoomCard extends StatelessWidget {
  final String roomName;
  final String? roomCode;
  final PartnerCalendarCell cell;
  final bool selected;
  final VoidCallback onTap;

  const PartnerCalendarDayRoomCard({
    super.key,
    required this.roomName,
    required this.cell,
    required this.selected,
    required this.onTap,
    this.roomCode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerCalendarFormats.of(context);
    final visual = partnerNightStateVisual(cell.state);
    final day = cell.day;

    return Semantics(
      button: true,
      label: [roomName, partnerNightStateLabel(l10n, cell.state)].join('. '),
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected ? AppColors.ocean700 : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(visual.icon, size: 20, color: visual.color),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roomName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            partnerNightStateLabel(l10n, cell.state),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xxs,
                      children: [
                        if (day != null)
                          Text(
                            f.integer.format(day.availableInventory),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: visual.color,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        if (cell.isOccupied)
                          const Icon(Icons.person_rounded,
                              size: 16, color: AppColors.violet),
                        if (day?.closedArrival ?? false)
                          const Icon(Icons.login_rounded,
                              size: 14, color: AppColors.warning),
                        if (day?.closedDeparture ?? false)
                          const Icon(Icons.logout_rounded,
                              size: 14, color: AppColors.warning),
                      ],
                    ),
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

/// A short inline statement — a limitation, a warning, or an explanation.
class PartnerCalendarNotice extends StatelessWidget {
  final String message;
  final bool warning;

  const PartnerCalendarNotice({
    super.key,
    required this.message,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.warning : AppColors.ocean600;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            size: 18,
            color: color,
          ),
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
    );
  }
}

/// A window total.
class PartnerCalendarMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const PartnerCalendarMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            '$value · $label',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// A labelled fact inside the selected-night panel.
class PartnerCalendarFact extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;

  const PartnerCalendarFact({
    super.key,
    required this.label,
    this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              value ?? l10n.partnerPropertyNotSet,
              style: theme.textTheme.bodySmall?.copyWith(
                color: valueColor ??
                    (value == null
                        ? AppColors.textTertiary
                        : AppColors.textPrimary),
                fontWeight: value == null ? FontWeight.w400 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A yes/no answer to one of the four availability questions.
class PartnerCalendarAnswer extends StatelessWidget {
  final String question;
  final bool answer;

  /// Why the answer is no, when the backend rule explains it.
  final String? reason;

  const PartnerCalendarAnswer({
    super.key,
    required this.question,
    required this.answer,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = answer ? AppColors.success : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            answer ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textPrimary),
                ),
                if (!answer && reason != null)
                  Text(
                    reason!,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact status pill for the window summary.
class PartnerCalendarWindowPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const PartnerCalendarWindowPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) =>
      OceanStatusPill(label: label, color: color, icon: icon);
}
