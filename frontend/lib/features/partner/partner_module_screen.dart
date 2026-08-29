import 'package:flutter/material.dart';

import '../../core/partner/partner_state.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'partner_navigation.dart';

/// Placeholder for a partner module whose UI has not been built yet.
///
/// It states plainly that the module is planned and names the backend surface
/// it will be built against. It renders **no data at all** — showing invented
/// bookings or fabricated revenue here would be exactly the fake real-mode
/// success the project forbids, and would be far more damaging in an operations
/// console than in a consumer screen.
class PartnerModuleScreen extends StatelessWidget {
  final PartnerDestination destination;

  const PartnerModuleScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final partner = PartnerScope.of(context);
    final writable = destination.isWritableBy(partner.teamRole);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(destination.selectedIcon,
                  color: AppColors.ocean700, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  destination.label(l10n),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              OceanStatusPill(
                label: l10n.partnerModulePlannedBadge,
                color: AppColors.textTertiary,
                icon: Icons.construction_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.partnerModulePlannedMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.partnerModuleEndpointHint(destination.route),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          if (!writable) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    l10n.partnerModuleReadOnlyForRole,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
