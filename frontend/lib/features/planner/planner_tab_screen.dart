import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../timeline/timeline_screen.dart';
import '../trips/create_trip_screen.dart';

class PlannerTabScreen extends StatelessWidget {
  const PlannerTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    return ListView(
      key: const PageStorageKey('planner-tab-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        Text(
          l10n?.plannerTitle ?? 'Planner',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n?.plannerSubtitle ??
              'Open a trip timeline and continue planning.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (app.trips.isEmpty)
          OceanEmptyState(
            title: l10n?.plannerEmptyTitle ?? 'No trips to plan yet',
            message: l10n?.plannerEmptyMessage ??
                'Create a trip before building a timeline.',
            actionLabel: l10n?.plannerCreateTripAction ?? 'Create a trip',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateTripScreen()),
            ),
          )
        else
          ...app.trips.map(
            (trip) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PlannerTripCard(trip: trip),
            ),
          ),
      ],
    );
  }
}

class _PlannerTripCard extends StatelessWidget {
  final Trip trip;

  const _PlannerTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = DateFormat('dd/MM/yyyy');
    final meta = l10n?.plannerTripMeta(
          trip.destination,
          trip.days,
          trip.travelers,
        ) ??
        '${trip.destination} · ${trip.days} days · ${trip.travelers} travelers';

    return OceanGlassCard(
      semanticLabel: l10n?.plannerTripCardSemantic ?? 'Trip planner card',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Image.network(
              trip.imageUrl,
              width: 82,
              height: 82,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 82,
                height: 82,
                color: AppColors.paleCyan,
                child: const Icon(
                  Icons.map_rounded,
                  color: AppColors.ocean,
                  size: AppIconSizes.lg,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  meta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${date.format(trip.startDate)} - ${date.format(trip.endDate)}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OceanSecondaryButton(
                  fullWidth: false,
                  label: l10n?.plannerOpenTimelineAction ?? 'Open timeline',
                  icon: Icons.timeline_rounded,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TimelineScreen(trip: trip),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
