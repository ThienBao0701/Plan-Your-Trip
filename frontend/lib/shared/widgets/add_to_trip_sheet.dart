import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
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
