import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../core/mock/mock_data.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'create_trip_screen.dart';
import 'edit_trip_screen.dart';
import 'trip_detail_screen.dart';
import 'trip_sections.dart';

class TripsScreen extends StatelessWidget {
  final DateTime? today;

  const TripsScreen({super.key, this.today});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final visibleTrips = _visibleTrips(app);
    final grouped = groupTripsBySection(visibleTrips, today ?? DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        120,
      ),
      children: [
        OceanContentConstraint(
          maxWidth: AppBreakpoints.maxContentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tripsTitle,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.tripsSubtitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    container: true,
                    button: true,
                    label: l10n.tripsCreateSemantic,
                    child: IconButton.filled(
                      tooltip: l10n.tripsCreateSemantic,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateTripScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (visibleTrips.isEmpty)
                OceanEmptyState(
                  title: l10n.tripsEmptyTitle,
                  message: app.demoMode
                      ? l10n.tripsEmptyMessage
                      : l10n.tripsRealUnavailableMessage,
                  actionLabel: l10n.tripsCreateAction,
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTripScreen()),
                  ),
                )
              else ...[
                _TripSectionView(
                  title: l10n.tripsOngoing,
                  emptyMessage: l10n.tripsOngoingEmpty,
                  trips: grouped[TripSection.ongoing]!,
                ),
                _TripSectionView(
                  title: l10n.tripsUpcoming,
                  emptyMessage: l10n.tripsUpcomingEmpty,
                  trips: grouped[TripSection.upcoming]!,
                ),
                _TripSectionView(
                  title: l10n.tripsPast,
                  emptyMessage: l10n.tripsPastEmpty,
                  trips: grouped[TripSection.past]!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Trip> _visibleTrips(AppState app) {
    if (app.demoMode) return app.trips;
    final seeded = app.trips.length == MockData.trips.length &&
        app.trips.every(
          (trip) => MockData.trips.any(
            (seed) => seed.id == trip.id && seed.title == trip.title,
          ),
        );
    return seeded ? <Trip>[] : app.trips;
  }
}

class _TripSectionView extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<Trip> trips;

  const _TripSectionView({
    required this.title,
    required this.emptyMessage,
    required this.trips,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            if (trips.isEmpty)
              OceanGlassCard(
                child: Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              for (final trip in trips)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _SmartTripCard(trip: trip),
                ),
          ],
        ),
      );
}

class _SmartTripCard extends StatelessWidget {
  final Trip trip;

  const _SmartTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMd(locale);
    final meta = l10n.tripDateTravelerMeta(
      date.format(trip.startDate),
      date.format(trip.endDate),
      trip.travelers,
    );
    return OceanGlassCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
      ),
      padding: EdgeInsets.zero,
      semanticLabel: l10n.tripCardSemantic(trip.title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.xxl),
                ),
                child: Image.network(
                  trip.imageUrl,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => Container(
                    height: 190,
                    color: AppColors.paleCyan,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_rounded,
                      color: AppColors.ocean,
                      size: AppIconSizes.xl,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: PopupMenuButton<String>(
                  tooltip: l10n.tripActionsSemantic(trip.title),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditTripScreen(trip: trip),
                        ),
                      );
                    }
                    if (value == 'delete') {
                      _confirmDelete(context, app, trip);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(l10n.tripEditAction),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        l10n.tripDeleteAction,
                        style: const TextStyle(color: AppColors.coral),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(meta, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OceanStatusPill(
                      label: trip.destination,
                      icon: Icons.place_rounded,
                    ),
                    OceanStatusPill(
                      label: l10n.tripDayCount(trip.days),
                      icon: Icons.calendar_today_rounded,
                      color: AppColors.turquoise600,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState app,
    Trip trip,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tripDeleteConfirmTitle),
        content: Text(l10n.tripDeleteConfirmMessage(trip.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.tripDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    app.deleteTrip(trip.id);
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.tripDeletedMessage)));
  }
}
