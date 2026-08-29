import 'package:flutter/material.dart';

import '../../core/partner/partner_state.dart';
import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'widgets/partner_state_views.dart';

/// The partner dashboard, rendered from `GET /api/partner/extranet/home`.
///
/// Every number here is a field the backend computed. Nothing is derived,
/// summed, or estimated on the client — occupancy, revenue and availability are
/// backend responsibilities, and a plausible-looking client-side figure would be
/// worse than none.
///
/// C0 scope: the counts the extranet home already returns, plus the property
/// scope. Finance, analytics and the operational modules are later phases; the
/// nested `financeSummary` this endpoint also returns is intentionally not
/// surfaced here so the Finance module owns that presentation.
class PartnerDashboardScreen extends StatelessWidget {
  const PartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final overview = partner.overview;

    if (overview == null) {
      return PartnerWorkspaceStatusView(status: partner.status);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WorkspaceSummaryCard(),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.partnerDashboardTodayHeading,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        LayoutBuilder(
          builder: (context, constraints) {
            // Two columns on a phone, four on a console. Wrap keeps the tiles
            // readable at large text scales instead of clipping a fixed grid.
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 520
                    ? 3
                    : 2;
            const spacing = AppSpacing.sm;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            final tiles = <Widget>[
              PartnerMetricTile(
                label: l10n.partnerMetricArrivals,
                value: '${overview.todaysArrivals}',
                icon: Icons.login_rounded,
                accent: AppColors.success,
              ),
              PartnerMetricTile(
                label: l10n.partnerMetricDepartures,
                value: '${overview.todaysDepartures}',
                icon: Icons.logout_rounded,
                accent: AppColors.info,
              ),
              PartnerMetricTile(
                label: l10n.partnerMetricUnreadMessages,
                value: '${overview.unreadMessages}',
                icon: Icons.forum_rounded,
                accent: AppColors.violet,
              ),
              PartnerMetricTile(
                label: l10n.partnerMetricPendingReviews,
                value: '${overview.pendingReviews}',
                icon: Icons.rate_review_rounded,
                accent: AppColors.warning,
              ),
              PartnerMetricTile(
                label: l10n.partnerMetricActivePromotions,
                value: '${overview.activePromotions}',
                icon: Icons.local_offer_rounded,
                accent: AppColors.coral,
              ),
              PartnerMetricTile(
                label: l10n.partnerMetricNotifications,
                value: '${overview.unreadNotifications}',
                icon: Icons.notifications_rounded,
                accent: AppColors.ocean600,
              ),
              PartnerMetricTile(
                label: l10n.partnerMetricProperties,
                value: '${overview.ownedHotelCount}',
                icon: Icons.apartment_rounded,
              ),
              PartnerMetricTile(
                label: l10n.partnerMetricActiveRooms,
                value: '${overview.activeRoomCount}',
                icon: Icons.meeting_room_rounded,
              ),
            ];
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final tile in tiles) SizedBox(width: width, child: tile),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const _PropertyScopeCard(),
      ],
    );
  }
}

class _WorkspaceSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final partner = PartnerScope.of(context);
    final overview = partner.overview!;

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
                style: theme.textTheme.titleLarge?.copyWith(
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The workspace's property scope, from `GET /api/partner/hotels`.
///
/// Selecting a property here sets the context later modules will operate in. It
/// performs no request of its own in C0 — the scope exists so the modules built
/// on top of it inherit a single, backend-authorized property list rather than
/// each inventing one.
class _PropertyScopeCard extends StatelessWidget {
  const _PropertyScopeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final partner = PartnerScope.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.partnerPropertyScopeHeading,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (partner.propertiesUnavailable)
            Text(
              l10n.partnerPropertyScopeUnavailable,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
              ),
            )
          else if (partner.properties.isEmpty)
            Text(
              l10n.partnerPropertyScopeEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final property in partner.properties)
                  _PropertyChip(
                    label: property.name,
                    active: property.active,
                    selected: partner.selectedPropertyId == property.id,
                    onTap: () => partner.selectProperty(property.id),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PropertyChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool selected;
  final VoidCallback onTap;

  const _PropertyChip({
    required this.label,
    required this.active,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      selected: selected,
      label: active ? label : l10n.partnerPropertyInactiveSemantic(label),
      child: Material(
        color: selected ? AppColors.ocean700 : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_outline,
                  size: 16,
                  color: selected ? AppColors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
