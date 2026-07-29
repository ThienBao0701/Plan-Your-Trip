import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../features/auth/login_screen.dart';
import '../../features/planner/planner_timeline.dart';
import '../../features/planner/planner_utils.dart';
import '../../features/timeline/timeline_screen.dart';
import '../../features/trips/create_trip_screen.dart';
import '../../l10n/app_localizations.dart';
import 'glass_widgets.dart';

Future<void> showAddToTripSheet(BuildContext context, Place place) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddToTripSheet(parentContext: context, place: place),
  );
}

class _AddToTripSheet extends StatefulWidget {
  final BuildContext parentContext;
  final Place place;

  const _AddToTripSheet({required this.parentContext, required this.place});

  @override
  State<_AddToTripSheet> createState() => _AddToTripSheetState();
}

class _AddToTripSheetState extends State<_AddToTripSheet> {
  final _start = TextEditingController(text: '10:00');
  final _end = TextEditingController(text: '12:00');
  final _startFocus = FocusNode();
  int? _selectedTripId;
  int _selectedDay = 1;
  bool _submitting = false;
  bool _navigating = false;
  // Real Mode selection: a concrete backend day id, or a request to append a
  // brand-new day (for trips that have none yet).
  int? _selectedDayId;
  bool _useNewDay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppScope.of(context);
      if (!app.demoMode) app.loadRealTrips();
    });
  }

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _startFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Real Mode has its own trip/day loading + backend-confirmed add flow.
    if (!app.demoMode) return _buildRealSheet(context, app, l10n);
    final trips = List<Trip>.from(app.trips)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    Trip? selectedTrip;
    if (_selectedTripId != null) {
      try {
        selectedTrip = trips.firstWhere((trip) => trip.id == _selectedTripId);
      } catch (_) {
        selectedTrip = null;
      }
    }
    if (selectedTrip == null && trips.isNotEmpty && _selectedTripId != null) {
      _selectedTripId = trips.first.id;
      _selectedDay = 1;
    }

    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            Text(l10n.quickAddTitle,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.quickAddPlaceSubtitle(widget.place.name),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (trips.isEmpty)
              OceanEmptyState(
                title: l10n.quickAddNoTripTitle,
                message: l10n.quickAddNoTripMessage,
                actionLabel: l10n.plannerCreateTripAction,
                onAction: _openCreateTrip,
              )
            else ...[
              Text(l10n.quickAddSelectTripLabel,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final trip in trips)
                _TripOption(
                  key: Key('quick-add-trip-${trip.id}'),
                  trip: trip,
                  selected: selectedTrip?.id == trip.id,
                  onTap: () => setState(() {
                    _selectedTripId = trip.id;
                    _selectedDay = 1;
                  }),
                ),
              if (selectedTrip != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.quickAddSelectDayLabel,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 1; i <= selectedTrip.days; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: ChoiceChip(
                            key: Key('quick-add-day-$i'),
                            selected: _selectedDay == i,
                            label: Text(l10n.tripOverviewDayLabel(i)),
                            onSelected: (_) => setState(() => _selectedDay = i),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        key: const Key('quick-add-start-field'),
                        controller: _start,
                        focusNode: _startFocus,
                        label: l10n.activityStartTimeLabel,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _TimeField(
                        key: const Key('quick-add-end-field'),
                        controller: _end,
                        label: l10n.activityEndTimeLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                OceanGlassSurface(
                  blur: 0,
                  color: AppColors.paleCyan,
                  child: Text(
                    l10n.plannerLocalOnlyMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _submitting
                    ? const Center(
                        child: SizedBox(width: 280, child: OceanLoadingState()))
                    : OceanPrimaryButton(
                        key: const Key('quick-add-submit'),
                        label: l10n.quickAddSubmitAction(_selectedDay),
                        icon: Icons.add_rounded,
                        semanticLabel:
                            l10n.placeAddToTripSemantic(widget.place.name),
                        onPressed: _confirm,
                      ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateTrip() async {
    if (_navigating) return;
    _navigating = true;
    final nav = Navigator.of(widget.parentContext);
    Navigator.pop(context);
    final created = await nav.push<Trip>(
      MaterialPageRoute(builder: (_) => const CreateTripScreen()),
    );
    _navigating = false;
    if (!mounted || created == null) return;
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final app = AppScope.of(context);
    final trip = app.tripById(_selectedTripId ?? -1);
    if (trip == null) return;
    if (!AppState.isValidTimeRange(_start.text.trim(), _end.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.activityInvalidTimeRange)),
      );
      _startFocus.requestFocus();
      return;
    }
    if (!plannerDayIsInTrip(trip, _selectedDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.activityOutOfRangeDay)),
      );
      return;
    }
    setState(() => _submitting = true);
    final item = TimelineItem(
      id: app.newId,
      tripId: trip.id,
      dayNumber: _selectedDay,
      startTime: _start.text.trim(),
      endTime: _end.text.trim(),
      title: widget.place.name,
      notes: widget.place.description,
      place: widget.place,
      placeId: widget.place.id,
      category: widget.place.category,
      estimatedCost: 0,
    );
    final conflict = findPlannerConflict(app.timeline, item);
    if (conflict != null) {
      setState(() => _submitting = false);
      final decision = await showPlannerConflictSheet(
        context,
        conflict: conflict,
        candidate: item,
        isEdit: false,
      );
      if (!mounted) return;
      if (decision == PlannerConflictDecision.changeTime) {
        _startFocus.requestFocus();
        return;
      }
      if (decision != PlannerConflictDecision.saveAnyway) return;
      setState(() => _submitting = true);
    }
    final added = app.addTimeline(item);
    if (!added) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.activitySaveFailed)),
        );
      }
      return;
    }
    if (!mounted || !widget.parentContext.mounted) return;
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final nav = Navigator.of(widget.parentContext);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.quickAddAddedMessage(
          widget.place.name,
          trip.title,
          _selectedDay,
        )),
        action: SnackBarAction(
          label: l10n.plannerOpenTimelineAction,
          onPressed: () => nav.push(
            MaterialPageRoute(builder: (_) => TimelineScreen(trip: trip)),
          ),
        ),
      ),
    );
  }

  // ── Real Mode add-to-trip ─────────────────────────────────────────────────

  Widget _buildRealSheet(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
  ) {
    final trips = app.realTrips;
    final selectedId = _selectedTripId;
    final detail =
        selectedId == null ? null : app.realTripDetailFor(selectedId);

    Widget body;
    if (app.realTripsLoading && !app.realTripsLoaded) {
      body = Center(
        child: SizedBox(
          width: 280,
          child: OceanLoadingState(message: l10n.addToTripRealLoadingTrips),
        ),
      );
    } else if (app.realTripsError != null && trips.isEmpty) {
      final err = app.realTripsError!;
      body = err == TripActionResult.sessionExpired
          ? OceanEmptyState(
              title: l10n.tripsRealSessionExpiredTitle,
              message: l10n.tripsRealSessionExpiredMessage,
              actionLabel: l10n.tripsRealSignInAction,
              onAction: _reauthReal,
            )
          : OceanRecoverableErrorState(
              message: l10n.tripsRealErrorMessage,
              onReload: () => app.loadRealTrips(refresh: true),
            );
    } else if (trips.isEmpty) {
      body = OceanEmptyState(
        key: const Key('real-quick-add-empty'),
        title: l10n.quickAddNoTripTitle,
        message: l10n.addToTripRealNoTripsMessage,
        actionLabel: l10n.plannerCreateTripAction,
        onAction: _openCreateTrip,
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.addToTripRealSelectTripLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final trip in trips)
            _RealTripOption(
              key: Key('real-quick-add-trip-${trip.id}'),
              trip: trip,
              selected: selectedId == trip.id,
              onTap: () {
                setState(() {
                  _selectedTripId = trip.id;
                  _selectedDayId = null;
                  _useNewDay = false;
                });
                app.loadRealTripDetail(trip.id);
              },
            ),
          if (selectedId != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildRealDaySection(context, app, l10n, selectedId, detail),
          ],
        ],
      );
    }

    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            Text(
              l10n.quickAddTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.quickAddPlaceSubtitle(widget.place.name),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            body,
          ],
        ),
      ),
    );
  }

  Widget _buildRealDaySection(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
    int tripId,
    TripDetailRecord? detail,
  ) {
    if (app.realTripDetailLoading && detail == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (detail == null) {
      final err = app.realTripDetailError;
      if (err == TripActionResult.sessionExpired) {
        return OceanEmptyState(
          title: l10n.tripsRealSessionExpiredTitle,
          message: l10n.tripsRealSessionExpiredMessage,
          actionLabel: l10n.tripsRealSignInAction,
          onAction: _reauthReal,
        );
      }
      return OceanRecoverableErrorState(
        message: err == TripActionResult.forbidden
            ? l10n.tripRealPermissionDeniedMessage
            : l10n.tripDetailRealErrorMessage,
        onReload: () => app.loadRealTripDetail(tripId),
      );
    }

    final locale = Localizations.localeOf(context).toString();
    final newDayNumber = detail.nextDayNumber;
    final busy = _submitting || app.realTripActionInFlight;
    final onlyNewDay = detail.days.isEmpty;
    final canSubmit =
        !busy && (_useNewDay || onlyNewDay || _selectedDayId != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.addToTripRealSelectDayLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final day in detail.days)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    key: Key('real-quick-add-day-${day.id}'),
                    selected: !_useNewDay && _selectedDayId == day.id,
                    label: Text(
                      day.date != null
                          ? '${l10n.tripDayLabel(day.dayNumber)} · '
                              '${DateFormat.MMMd(locale).format(day.date!)}'
                          : l10n.tripDayLabel(day.dayNumber),
                    ),
                    onSelected: (_) => setState(() {
                      _useNewDay = false;
                      _selectedDayId = day.id;
                    }),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: ChoiceChip(
                  key: const Key('real-quick-add-new-day'),
                  selected: _useNewDay || onlyNewDay,
                  label: Text(l10n.addToTripRealNewDayOption(newDayNumber)),
                  onSelected: (_) => setState(() {
                    _useNewDay = true;
                    _selectedDayId = null;
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OceanGlassSurface(
          blur: 0,
          color: AppColors.paleCyan,
          child: Text(
            l10n.addToTripRealPlanningNote,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        busy
            ? Center(
                child: SizedBox(
                  width: 280,
                  child: OceanLoadingState(
                    message: l10n.addToTripRealAddingMessage,
                  ),
                ),
              )
            : OceanPrimaryButton(
                key: const Key('real-quick-add-submit'),
                label: l10n.placeAddToTrip,
                icon: Icons.add_rounded,
                semanticLabel: l10n.placeAddToTripSemantic(widget.place.name),
                onPressed:
                    canSubmit ? () => _confirmReal(detail, newDayNumber) : null,
              ),
      ],
    );
  }

  Future<void> _confirmReal(TripDetailRecord detail, int newDayNumber) async {
    final app = AppScope.of(context);
    if (_submitting || app.realTripActionInFlight) return;
    final tripId = _selectedTripId;
    if (tripId == null) return;
    setState(() => _submitting = true);

    int? dayId = (_useNewDay || detail.days.isEmpty) ? null : _selectedDayId;
    if (dayId == null) {
      // Append a new day first (verified POST .../days), then place the item.
      final dayResult = await app.createRealTripDay(
        tripId: tripId,
        dayNumber: newDayNumber,
      );
      if (!mounted) return;
      if (dayResult.result != TripActionResult.success ||
          dayResult.dayId == null) {
        setState(() => _submitting = false);
        _handleRealFailure(dayResult.result);
        return;
      }
      dayId = dayResult.dayId;
    }

    final result = await app.addRealTripPlace(
      dayId: dayId!,
      placeId: widget.place.id,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result == TripActionResult.success) {
      _finishRealSuccess();
      return;
    }
    _handleRealFailure(result);
  }

  void _finishRealSuccess() {
    if (!widget.parentContext.mounted) {
      Navigator.pop(context);
      return;
    }
    final l10n = AppLocalizations.of(widget.parentContext)!;
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.addToTripRealAddedMessage(widget.place.name)),
      ),
    );
  }

  void _handleRealFailure(TripActionResult result) {
    final l10n = AppLocalizations.of(context)!;
    if (result == TripActionResult.sessionExpired) {
      _reauthReal();
      return;
    }
    final message = switch (result) {
      TripActionResult.forbidden => l10n.tripRealPermissionDeniedMessage,
      TripActionResult.notFound => l10n.addToTripRealTripUnavailableMessage,
      TripActionResult.unprocessable => l10n.addToTripRealUnpublishedMessage,
      _ => l10n.addToTripRealErrorMessage,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _reauthReal() {
    if (!widget.parentContext.mounted) return;
    final nav = Navigator.of(widget.parentContext);
    Navigator.pop(context); // close the add-to-trip sheet first
    showOceanSessionExpiredSheet(
      widget.parentContext,
      onLogin: () {
        nav.pop();
        nav.push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      },
      onReturnHome: () => nav.pop(),
    );
  }
}

class _RealTripOption extends StatelessWidget {
  final TripSummaryRecord trip;
  final bool selected;
  final VoidCallback onTap;

  const _RealTripOption({
    super.key,
    required this.trip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale);
    final range = (trip.startDate != null && trip.endDate != null)
        ? '${date.format(trip.startDate!)} - ${date.format(trip.endDate!)}'
        : null;
    return OceanGlassSurface(
      blur: 0,
      color: selected
          ? AppColors.ocean.withValues(alpha: .10)
          : AppColors.surfaceOverlay,
      border: Border.all(
        color: selected ? AppColors.ocean : AppColors.divider,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            Icons.map_rounded,
            color: selected ? AppColors.ocean : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (range != null)
                  Text(range, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: AppColors.ocean),
        ],
      ),
    );
  }
}

class _TripOption extends StatelessWidget {
  final Trip trip;
  final bool selected;
  final VoidCallback onTap;

  const _TripOption({
    super.key,
    required this.trip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale);
    return OceanGlassSurface(
      blur: 0,
      color: selected
          ? AppColors.ocean.withValues(alpha: .10)
          : AppColors.surfaceOverlay,
      border: Border.all(
        color: selected ? AppColors.ocean : AppColors.divider,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.map_rounded,
              color: selected ? AppColors.ocean : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.title,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${date.format(trip.startDate)} - ${date.format(trip.endDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: AppColors.ocean),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;

  const _TimeField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        helperText: l10n.activityTimeHint,
        prefixIcon: const Icon(Icons.schedule_rounded),
      ),
    );
  }
}
