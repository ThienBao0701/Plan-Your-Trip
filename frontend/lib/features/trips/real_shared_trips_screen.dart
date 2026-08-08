import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'real_trip_detail_screen.dart';
import 'trip_companion_screen.dart' show collaboratorRoleLabel;
import 'trips_screen.dart' show realTripStatusLabel;

/// UI49 — Real Mode "shared with me" trips (`GET /api/me/trips/shared`). Lists
/// trips the authenticated user collaborates on (active only, newest first).
/// Read-only: each row opens the existing [RealTripDetailScreen] (the detail
/// endpoint is collaborator-viewable). No leave/accept/reject exists in the
/// backend, so none is shown.
class RealSharedTripsScreen extends StatefulWidget {
  const RealSharedTripsScreen({super.key});

  @override
  State<RealSharedTripsScreen> createState() => _RealSharedTripsScreenState();
}

class _RealSharedTripsScreenState extends State<RealSharedTripsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealSharedTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.sharedWithMeTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    if (app.realSharedTripsError == SharedTripsOutcome.sessionExpired &&
        !app.realSharedTripsLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('shared-trips-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realSharedTripsLoading && !app.realSharedTripsLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.sharedTripsRealLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('shared-trips-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.sharedTripsRealLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realSharedTripsError != null && !app.realSharedTripsLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('shared-trips-error'),
          message: app.realSharedTripsError == SharedTripsOutcome.forbidden
              ? l10n.sharedTripsRealForbiddenMessage
              : app.realSharedTripsError == SharedTripsOutcome.notFound
                  ? l10n.sharedTripsRealGoneMessage
                  : l10n.sharedTripsRealErrorMessage,
          onReload: () => app.loadRealSharedTrips(refresh: true),
        ),
      );
    }
    final trips = app.realSharedTrips;
    return RefreshIndicator(
      onRefresh: () => app.loadRealSharedTrips(refresh: true),
      child: ListView(
        key: const Key('shared-trips-content'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (trips.isEmpty)
                  OceanEmptyState(
                    key: const Key('shared-trips-empty'),
                    title: l10n.sharedTripsRealEmptyTitle,
                    message: l10n.sharedTripsRealEmptyMessage,
                  )
                else
                  for (final trip in trips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _SharedTripCard(trip: trip),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _centered(Widget child) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Center(child: child),
          ),
        ],
      );
}

class _SharedTripCard extends StatelessWidget {
  final RealSharedTrip trip;

  const _SharedTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMd(locale);
    final range = (trip.startDate != null && trip.endDate != null)
        ? '${date.format(trip.startDate!)} – ${date.format(trip.endDate!)}'
        : null;
    final roleView = trip.roleView;
    final isEditor = roleView == TripCollaboratorRole.editor;
    final title =
        trip.title.trim().isEmpty ? l10n.sharedTripsRealUntitled : trip.title;
    return OceanGlassCard(
      key: Key('shared-trip-card-${trip.tripId}'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RealTripDetailScreen(tripId: trip.tripId),
        ),
      ),
      semanticLabel: l10n.tripCardSemantic(title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if ((trip.destination ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              trip.destination!.trim(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (trip.ownerName.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.sharedWithMeOwnerLabel(trip.ownerName.trim()),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: realTripStatusLabel(l10n, trip.statusView, trip.status),
                icon: Icons.flag_rounded,
                color: AppColors.ocean,
              ),
              if (roleView != null)
                OceanStatusPill(
                  label: collaboratorRoleLabel(l10n, roleView),
                  icon:
                      isEditor ? Icons.edit_rounded : Icons.visibility_rounded,
                  color: isEditor ? AppColors.turquoise600 : AppColors.slate,
                ),
              if (range != null)
                OceanStatusPill(
                  label: range,
                  icon: Icons.event_rounded,
                  color: AppColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
