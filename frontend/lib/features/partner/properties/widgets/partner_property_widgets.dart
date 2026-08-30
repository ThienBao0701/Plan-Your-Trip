import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/partner/partner_models.dart';
import '../../../../core/partner/partner_property_models.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_radii.dart';
import '../../../../design/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_widgets.dart';

/// Localised label + colour + icon for a `PlaceStatus`.
///
/// All seven backend values are represented and nothing else. State is never
/// communicated by colour alone — every pill carries an icon and a word.
({String label, Color color, IconData icon}) partnerPlaceStatusSpec(
  AppLocalizations l10n,
  PartnerPlaceStatus status,
) =>
    switch (status) {
      PartnerPlaceStatus.published => (
          label: l10n.partnerPropertyStatusPublished,
          color: AppColors.success,
          icon: Icons.public_rounded,
        ),
      PartnerPlaceStatus.approved => (
          label: l10n.partnerPropertyStatusApproved,
          color: AppColors.info,
          icon: Icons.verified_outlined,
        ),
      PartnerPlaceStatus.pendingReview => (
          label: l10n.partnerPropertyStatusPendingReview,
          color: AppColors.warning,
          icon: Icons.hourglass_top_rounded,
        ),
      PartnerPlaceStatus.draft => (
          label: l10n.partnerPropertyStatusDraft,
          color: AppColors.textTertiary,
          icon: Icons.edit_note_rounded,
        ),
      PartnerPlaceStatus.hidden => (
          label: l10n.partnerPropertyStatusHidden,
          color: AppColors.warning,
          icon: Icons.visibility_off_outlined,
        ),
      PartnerPlaceStatus.archived => (
          label: l10n.partnerPropertyStatusArchived,
          color: AppColors.textTertiary,
          icon: Icons.inventory_2_outlined,
        ),
      PartnerPlaceStatus.rejected => (
          label: l10n.partnerPropertyStatusRejected,
          color: AppColors.danger,
          icon: Icons.cancel_outlined,
        ),
      PartnerPlaceStatus.unknown => (
          label: l10n.partnerPropertyStatusUnknown,
          color: AppColors.textTertiary,
          icon: Icons.help_outline_rounded,
        ),
    };

/// A `PlaceStatus` pill.
class PartnerPropertyStatusPill extends StatelessWidget {
  final PartnerPlaceStatus status;

  const PartnerPropertyStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final spec = partnerPlaceStatusSpec(AppLocalizations.of(context)!, status);
    return OceanStatusPill(
      label: spec.label,
      color: spec.color,
      icon: spec.icon,
    );
  }
}

/// One row in the property list.
///
/// Shows only fields present in `PartnerHotelSummaryResponse`. There is no
/// room count, no revenue and no occupancy here — the list endpoint supplies
/// none of them, and a plausible-looking number would be an invention.
class PartnerPropertyCard extends StatelessWidget {
  final PartnerProperty property;

  /// True when this is the workspace's selected property (`PartnerState`).
  final bool selected;

  /// True when this row's detail panel is open.
  final bool open;

  /// True while an activate/deactivate request for this row is in flight.
  final bool actionPending;

  /// Null when the caller's team role cannot perform listing actions.
  final VoidCallback? onToggleActive;
  final VoidCallback onOpen;

  const PartnerPropertyCard({
    super.key,
    required this.property,
    required this.selected,
    required this.open,
    required this.actionPending,
    required this.onOpen,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusSpec = partnerPlaceStatusSpec(l10n, property.placeStatus);

    return Semantics(
      button: true,
      selected: selected,
      label: [
        property.name,
        statusSpec.label,
        property.active
            ? l10n.partnerPropertyActive
            : l10n.partnerPropertyInactive,
        if (selected) l10n.partnerPropertiesSelectedSemantic,
      ].join('. '),
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: open || selected ? AppColors.ocean600 : AppColors.divider,
              width: open || selected ? 2 : 1,
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
                            property.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.check_circle_rounded,
                              size: 18, color: AppColors.ocean600),
                        ],
                      ],
                    ),
                    if (property.address != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: AppSpacing.xxs),
                          Expanded(
                            child: Text(
                              property.address!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PartnerPropertyStatusPill(status: property.placeStatus),
                        _Flag(
                          on: property.active,
                          onLabel: l10n.partnerPropertyActive,
                          offLabel: l10n.partnerPropertyInactive,
                          onIcon: Icons.toggle_on_rounded,
                          offIcon: Icons.toggle_off_outlined,
                          onColor: AppColors.success,
                        ),
                        if (property.verified)
                          _Flag(
                            on: true,
                            onLabel: l10n.partnerPropertyVerified,
                            offLabel: l10n.partnerPropertyVerified,
                            onIcon: Icons.verified_rounded,
                            offIcon: Icons.verified_rounded,
                            onColor: AppColors.info,
                          ),
                        if (property.featured)
                          _Flag(
                            on: true,
                            onLabel: l10n.partnerPropertyFeatured,
                            offLabel: l10n.partnerPropertyFeatured,
                            onIcon: Icons.star_rounded,
                            offIcon: Icons.star_rounded,
                            onColor: AppColors.warning,
                          ),
                        if (property.reviewCount > 0)
                          _Flag(
                            on: true,
                            onLabel: l10n.partnerPropertyRatingSummary(
                              NumberFormat(
                                      '#,##0.0',
                                      Localizations.localeOf(context)
                                          .toString())
                                  .format(property.ratingAvg),
                              property.reviewCount,
                            ),
                            offLabel: '',
                            onIcon: Icons.star_half_rounded,
                            offIcon: Icons.star_half_rounded,
                            onColor: AppColors.textSecondary,
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
                                label: property.active
                                    ? l10n.partnerPropertyDeactivateAction
                                    : l10n.partnerPropertyActivateAction,
                                icon: property.active
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
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

class _Flag extends StatelessWidget {
  final bool on;
  final String onLabel;
  final String offLabel;
  final IconData onIcon;
  final IconData offIcon;
  final Color onColor;

  const _Flag({
    required this.on,
    required this.onLabel,
    required this.offLabel,
    required this.onIcon,
    required this.offIcon,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    final label = on ? onLabel : offLabel;
    if (label.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(on ? onIcon : offIcon,
            size: 15, color: on ? onColor : AppColors.textTertiary),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: on ? AppColors.textSecondary : AppColors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

/// A labelled detail row. A null [value] renders the "not set" placeholder
/// rather than an empty line, because the backend genuinely returns null for
/// most contact and policy fields and a blank row would read as a bug.
class PartnerPropertyField extends StatelessWidget {
  final String label;
  final String? value;

  const PartnerPropertyField({super.key, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shown = value ?? l10n.partnerPropertyNotSet;
    final isMissing = value == null;

    return Semantics(
      container: true,
      label: '$label: $shown',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                shown,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isMissing
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                  fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled group of detail fields. Rendered only when the caller has something
/// to put in it — an empty "Contact" heading over five "not set" rows is noise.
class PartnerPropertySection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const PartnerPropertySection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          ...children,
          const SizedBox(height: AppSpacing.md),
        ],
      );
}
