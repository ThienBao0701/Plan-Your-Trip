import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'create_trip_screen.dart';
import 'edit_trip_screen.dart';
import 'real_shared_trips_screen.dart';
import 'real_trip_detail_screen.dart';
import 'trip_companion_screen.dart';
import 'trip_detail_screen.dart';
import 'trip_sections.dart';

class TripsScreen extends StatelessWidget {
  final DateTime? today;

  const TripsScreen({super.key, this.today});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // Real Mode is fetch-backed and has its own loading/empty/error/refresh
    // lifecycle; Demo Mode keeps the exact local behaviour below.
    if (!app.demoMode) return const _RealTripsView();
    final l10n = AppLocalizations.of(context)!;
    final visibleTrips = app.trips;
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
              _SharedWithMeEntry(
                count: app.visibleSharedTrips().length,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SharedWithMeScreen()),
                ),
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
}

/// Real Mode trips tab — loads the authenticated user's trips from the backend
/// with honest loading / empty / error / refresh / session-expired states.
class _RealTripsView extends StatefulWidget {
  const _RealTripsView();

  @override
  State<_RealTripsView> createState() => _RealTripsViewState();
}

class _RealTripsViewState extends State<_RealTripsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).loadRealTrips();
    });
  }

  Future<void> _refresh() => AppScope.of(context).loadRealTrips(refresh: true);

  void _openCreate() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateTripScreen()),
      );

  void _reauth() {
    showOceanSessionExpiredSheet(
      context,
      onLogin: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      onReturnHome: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;

    Widget content;
    if (app.realTripsLoading && !app.realTripsLoaded) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: OceanLoadingState(message: l10n.tripsRealLoadingMessage),
      );
    } else if (app.realTripsError != null && app.realTrips.isEmpty) {
      final err = app.realTripsError!;
      if (err == TripActionResult.sessionExpired) {
        content = OceanEmptyState(
          key: const Key('real-trips-session-expired'),
          title: l10n.tripsRealSessionExpiredTitle,
          message: l10n.tripsRealSessionExpiredMessage,
          actionLabel: l10n.tripsRealSignInAction,
          onAction: _reauth,
        );
      } else {
        content = OceanRecoverableErrorState(
          key: const Key('real-trips-error'),
          message: err == TripActionResult.forbidden
              ? l10n.tripRealPermissionDeniedMessage
              : l10n.tripsRealErrorMessage,
          onReload: () => app.loadRealTrips(refresh: true),
        );
      }
    } else if (app.realTrips.isEmpty) {
      content = OceanEmptyState(
        key: const Key('real-trips-empty'),
        title: l10n.tripsEmptyTitle,
        message: l10n.tripsRealEmptyMessage,
        actionLabel: l10n.tripsCreateAction,
        onAction: _openCreate,
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final trip in app.realTrips)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _RealTripCard(trip: trip),
            ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                        onPressed: _openCreate,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _RealSharedWithMeEntry(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RealSharedTripsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Real Mode entry point into the "shared with me" trips surface
/// (`GET /api/me/trips/shared`). Kept separate from the demo `_SharedWithMeEntry`
/// (which shows a local demo count) — this one carries no count and always opens
/// the backend-backed list.
class _RealSharedWithMeEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _RealSharedWithMeEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      key: const Key('real-shared-trips-entry'),
      onTap: onTap,
      semanticLabel: l10n.sharedTripsRealEntrySemantic,
      child: Row(
        children: [
          Container(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.ocean.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.group_rounded,
              color: AppColors.ocean,
              size: AppIconSizes.sm,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sharedTripsRealEntryTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  l10n.sharedTripsRealEntrySubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _RealTripCard extends StatelessWidget {
  final TripSummaryRecord trip;

  const _RealTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMd(locale);
    final range = (trip.startDate != null && trip.endDate != null)
        ? '${date.format(trip.startDate!)} – ${date.format(trip.endDate!)}'
        : null;
    return OceanGlassCard(
      key: Key('real-trip-card-${trip.id}'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RealTripDetailScreen(tripId: trip.id),
        ),
      ),
      semanticLabel: l10n.tripCardSemantic(trip.title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (range != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(range, style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (trip.destination != null && trip.destination!.isNotEmpty)
                OceanStatusPill(
                  label: trip.destination!,
                  icon: Icons.place_rounded,
                ),
              OceanStatusPill(
                label: l10n.tripDayCount(trip.dayCount),
                icon: Icons.calendar_today_rounded,
                color: AppColors.turquoise600,
              ),
              OceanStatusPill(
                label: realTripStatusLabel(l10n, trip.status, trip.statusRaw),
                icon: Icons.flag_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Localised label for a real trip status, falling back to the raw backend
/// value for any status the client doesn't yet know (never fabricated).
String realTripStatusLabel(
  AppLocalizations l10n,
  TripPlanStatusValue status,
  String raw,
) =>
    switch (status) {
      TripPlanStatusValue.planning => l10n.tripStatusPlanning,
      TripPlanStatusValue.active => l10n.tripStatusActive,
      TripPlanStatusValue.completed => l10n.tripStatusCompleted,
      TripPlanStatusValue.cancelled => l10n.tripStatusCancelled,
      TripPlanStatusValue.unknown => raw.isEmpty ? l10n.tripStatusUnknown : raw,
    };

class _SharedWithMeEntry extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _SharedWithMeEntry({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      key: const Key('shared-with-me-action'),
      onTap: onTap,
      semanticLabel: l10n.sharedWithMeTitle,
      child: Row(
        children: [
          Container(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.ocean.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.group_rounded,
              color: AppColors.ocean,
              size: AppIconSizes.sm,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sharedWithMeTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  l10n.sharedWithMeCount(count),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
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
