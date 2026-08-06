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
import '../expenses/real_trip_expenses_screen.dart';
import '../places/place_detail_screen.dart';
import 'real_trip_documents_screen.dart';
import 'real_trip_notes_screen.dart';
import 'real_trip_packing_screen.dart';
import 'trips_screen.dart' show realTripStatusLabel;

/// Read-only Real Mode trip detail. Renders the backend `TripResponse`
/// (days → items) in backend order, showing only real fields. Editing and
/// reordering are intentionally disabled (out of UI-20 scope) with an honest
/// explanation. A place-linked item can be opened via UI-19 hydration.
class RealTripDetailScreen extends StatefulWidget {
  final int tripId;

  const RealTripDetailScreen({super.key, required this.tripId});

  @override
  State<RealTripDetailScreen> createState() => _RealTripDetailScreenState();
}

class _RealTripDetailScreenState extends State<RealTripDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).loadRealTripDetail(widget.tripId);
    });
  }

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

  Future<void> _viewPlace(int placeId) async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await app.hydrateRealPlace(placeId);
    if (!mounted) return;
    switch (result) {
      case PlaceHydrationResult.success:
        final place = app.getHydratedRealPlace(placeId);
        if (place != null) {
          navigator.push(
            MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
          );
        }
      case PlaceHydrationResult.sessionExpired:
        _reauth();
      case PlaceHydrationResult.notFound:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.placeHydrationUnavailableMessage)),
        );
      case PlaceHydrationResult.network:
      case PlaceHydrationResult.serverError:
      case PlaceHydrationResult.unavailable:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.placeHydrationErrorMessage)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final detail = app.realTripDetailFor(widget.tripId);

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(detail?.title ?? l10n.tripDetailRealTitle),
        actions: [
          IconButton(
            key: const Key('real-trip-notes'),
            tooltip: l10n.notesRealTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RealTripNotesScreen(
                  tripId: widget.tripId,
                  tripTitle: detail?.title,
                ),
              ),
            ),
            icon: const Icon(Icons.edit_note_rounded),
          ),
          IconButton(
            key: const Key('real-trip-packing'),
            tooltip: l10n.packingRealTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RealTripPackingScreen(
                  tripId: widget.tripId,
                  tripTitle: detail?.title,
                ),
              ),
            ),
            icon: const Icon(Icons.checklist_rounded),
          ),
          IconButton(
            key: const Key('real-trip-documents'),
            tooltip: l10n.tripDocumentsTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RealTripDocumentsScreen(
                  tripId: widget.tripId,
                  tripTitle: detail?.title,
                ),
              ),
            ),
            icon: const Icon(Icons.folder_copy_rounded),
          ),
          IconButton(
            key: const Key('real-trip-expenses'),
            tooltip: l10n.expensesTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RealTripExpensesScreen(
                  tripId: widget.tripId,
                  tripTitle: detail?.title,
                ),
              ),
            ),
            icon: const Icon(Icons.account_balance_wallet_rounded),
          ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: _body(context, app, l10n, detail),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
    TripDetailRecord? detail,
  ) {
    if (app.realTripDetailLoading && detail == null) {
      return Center(
        child: SizedBox(
          width: 420,
          child: OceanLoadingState(message: l10n.tripDetailRealLoadingMessage),
        ),
      );
    }
    if (detail == null) {
      final err = app.realTripDetailError;
      if (err == TripActionResult.sessionExpired) {
        return Center(
          child: SizedBox(
            width: 420,
            child: OceanEmptyState(
              key: const Key('real-trip-detail-session-expired'),
              title: l10n.tripsRealSessionExpiredTitle,
              message: l10n.tripsRealSessionExpiredMessage,
              actionLabel: l10n.tripsRealSignInAction,
              onAction: _reauth,
            ),
          ),
        );
      }
      if (err == TripActionResult.notFound) {
        return Center(
          child: SizedBox(
            width: 420,
            child: OceanEmptyState(
              key: const Key('real-trip-detail-unavailable'),
              title: l10n.tripDetailRealUnavailableTitle,
              message: l10n.tripDetailRealUnavailableMessage,
            ),
          ),
        );
      }
      return Center(
        child: SizedBox(
          width: 420,
          child: OceanRecoverableErrorState(
            key: const Key('real-trip-detail-error'),
            message: err == TripActionResult.forbidden
                ? l10n.tripRealPermissionDeniedMessage
                : l10n.tripDetailRealErrorMessage,
            onReload: () => app.loadRealTripDetail(widget.tripId),
          ),
        ),
      );
    }

    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMEd(locale);
    final range = (detail.startDate != null && detail.endDate != null)
        ? '${date.format(detail.startDate!)} – ${date.format(detail.endDate!)}'
        : null;

    return ListView(
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
              OceanGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.title,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    if (range != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        range,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    if (detail.description != null &&
                        detail.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        detail.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (detail.destination != null &&
                            detail.destination!.isNotEmpty)
                          OceanStatusPill(
                            label: detail.destination!,
                            icon: Icons.place_rounded,
                          ),
                        OceanStatusPill(
                          label: realTripStatusLabel(
                            l10n,
                            detail.status,
                            detail.statusRaw,
                          ),
                          icon: Icons.flag_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Editing/reordering is out of UI-20 scope — say so honestly
              // instead of showing controls that do nothing.
              Semantics(
                container: true,
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.tripDetailRealEditDisabledNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (detail.days.isEmpty)
                OceanGlassCard(
                  key: const Key('real-trip-detail-no-days'),
                  child: Text(
                    l10n.tripDetailRealNoDaysMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                for (final day in detail.days)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _DayCard(
                      day: day,
                      locale: locale,
                      onViewPlace: _viewPlace,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final TripDayRecord day;
  final String locale;
  final ValueChanged<int> onViewPlace;

  const _DayCard({
    required this.day,
    required this.locale,
    required this.onViewPlace,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabel = day.date != null
        ? '${l10n.tripDayLabel(day.dayNumber)} · '
            '${DateFormat.MMMEd(locale).format(day.date!)}'
        : l10n.tripDayLabel(day.dayNumber);
    return OceanGlassCard(
      key: Key('real-trip-day-${day.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dayLabel, style: Theme.of(context).textTheme.titleLarge),
          if (day.title != null && day.title!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(day.title!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (day.items.isEmpty)
            Text(
              l10n.tripDetailRealNoItemsMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final item in day.items)
              _ItemRow(item: item, onViewPlace: onViewPlace),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final TripItemRecord item;
  final ValueChanged<int> onViewPlace;

  const _ItemRow({required this.item, required this.onViewPlace});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final inFlight =
        item.placeId != null && app.isRealPlaceHydrationInFlight(item.placeId!);
    final time = (item.startTime != null && item.startTime!.isNotEmpty)
        ? item.startTime!
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              time ?? '—',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (item.customDescription != null &&
                    item.customDescription!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.customDescription!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (item.hasPlace)
            inFlight
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    key: Key('real-trip-item-details-${item.id}'),
                    onPressed: () => onViewPlace(item.placeId!),
                    child: Text(l10n.savedPlacesViewDetailsAction),
                  ),
        ],
      ),
    );
  }
}
