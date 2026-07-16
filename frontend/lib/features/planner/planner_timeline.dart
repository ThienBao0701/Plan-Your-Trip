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
import '../places/place_detail_screen.dart';
import '../trips/create_trip_screen.dart';
import 'planner_utils.dart';

enum PlannerPresentationMode { timeline, route }

enum PlannerConflictDecision { changeTime, cancel, saveAnyway }

class PlannerTimelineBody extends StatefulWidget {
  final int? initialTripId;
  final bool lockTripSelection;
  final EdgeInsetsGeometry padding;

  const PlannerTimelineBody({
    super.key,
    this.initialTripId,
    this.lockTripSelection = false,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.xxl,
    ),
  });

  @override
  State<PlannerTimelineBody> createState() => _PlannerTimelineBodyState();
}

class _PlannerTimelineBodyState extends State<PlannerTimelineBody> {
  int? _selectedTripId;
  int _selectedDay = 1;
  PlannerPresentationMode _mode = PlannerPresentationMode.timeline;

  @override
  void initState() {
    super.initState();
    _selectedTripId = widget.initialTripId;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final trips = _plannerTrips(app);
    _syncSelection(trips);

    return ListView(
      key: const PageStorageKey('planner-timeline-scroll'),
      padding: widget.padding,
      children: [
        OceanContentConstraint(
          maxWidth: AppBreakpoints.maxContentWidth,
          child: trips.isEmpty
              ? _NoTripState(onCreate: _openCreateTrip)
              : _PlannerTripContent(
                  trips: trips,
                  selectedTrip: trips.firstWhere(
                    (trip) => trip.id == _selectedTripId,
                    orElse: () => trips.first,
                  ),
                  selectedDay: _selectedDay,
                  mode: _mode,
                  lockTripSelection: widget.lockTripSelection,
                  onTripChanged: widget.lockTripSelection
                      ? null
                      : (tripId) => setState(() {
                            _selectedTripId = tripId;
                            _selectedDay = 1;
                          }),
                  onDayChanged: (day) => setState(() => _selectedDay = day),
                  onModeChanged: (mode) => setState(() => _mode = mode),
                  onCreateTrip: _openCreateTrip,
                  onQuickAddPlace: _showQuickAddPlace,
                  onAddActivity: (trip) => _showActivityEditor(
                    trip: trip,
                    dayNumber: _selectedDay,
                  ),
                  onActivityTap: _showActivityDetail,
                  l10n: l10n,
                ),
        ),
      ],
    );
  }

  List<Trip> _plannerTrips(AppState app) => List<Trip>.from(app.trips)
    ..sort((a, b) {
      final byDate = a.startDate.compareTo(b.startDate);
      return byDate == 0 ? a.id.compareTo(b.id) : byDate;
    });

  void _syncSelection(List<Trip> trips) {
    if (trips.isEmpty) {
      _selectedTripId = null;
      _selectedDay = 1;
      return;
    }
    final currentExists = trips.any((trip) => trip.id == _selectedTripId);
    if (!currentExists) {
      _selectedTripId = widget.initialTripId != null &&
              trips.any((trip) => trip.id == widget.initialTripId)
          ? widget.initialTripId
          : trips.first.id;
      _selectedDay = 1;
      return;
    }
    final trip = trips.firstWhere((trip) => trip.id == _selectedTripId);
    _selectedDay = clampPlannerDay(trip, _selectedDay);
  }

  Future<void> _openCreateTrip() async {
    final created = await Navigator.push<Trip>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripScreen()),
    );
    if (!mounted || created == null) return;
    setState(() {
      _selectedTripId = created.id;
      _selectedDay = 1;
      _mode = PlannerPresentationMode.timeline;
    });
  }

  Future<void> _showActivityEditor({
    required Trip trip,
    required int dayNumber,
    TimelineItem? existing,
  }) async {
    final saved = await showPlannerActivityEditorSheet(
      context,
      trip: trip,
      initialDay: dayNumber,
      existing: existing,
    );
    if (!mounted || saved != true) return;
    setState(() {
      _selectedTripId = trip.id;
      _selectedDay = existing == null ? dayNumber : _selectedDay;
    });
  }

  Future<void> _showActivityDetail(Trip trip, TimelineItem item) async {
    await showPlannerActivityDetailSheet(
      context,
      trip: trip,
      item: item,
      onEdit: () => _showActivityEditor(
        trip: trip,
        dayNumber: item.dayNumber,
        existing: item,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _showQuickAddPlace(Trip trip) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlannerQuickAddPlaceSheet(
        parentContext: context,
        trip: trip,
        initialDay: _selectedDay,
      ),
    );
    if (!mounted || added != true) return;
    setState(() {
      _selectedTripId = trip.id;
      _selectedDay = clampPlannerDay(trip, _selectedDay);
      _mode = PlannerPresentationMode.timeline;
    });
  }
}

class _NoTripState extends StatelessWidget {
  final VoidCallback onCreate;

  const _NoTripState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.plannerTitle,
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.plannerSubtitle,
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        OceanEmptyState(
          title: l10n.plannerEmptyTitle,
          message: l10n.plannerEmptyMessage,
          actionLabel: l10n.plannerCreateTripAction,
          onAction: onCreate,
        ),
      ],
    );
  }
}

class _PlannerTripContent extends StatelessWidget {
  final List<Trip> trips;
  final Trip selectedTrip;
  final int selectedDay;
  final PlannerPresentationMode mode;
  final bool lockTripSelection;
  final ValueChanged<int>? onTripChanged;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<PlannerPresentationMode> onModeChanged;
  final VoidCallback onCreateTrip;
  final ValueChanged<Trip> onQuickAddPlace;
  final ValueChanged<Trip> onAddActivity;
  final void Function(Trip trip, TimelineItem item) onActivityTap;
  final AppLocalizations l10n;

  const _PlannerTripContent({
    required this.trips,
    required this.selectedTrip,
    required this.selectedDay,
    required this.mode,
    required this.lockTripSelection,
    required this.onTripChanged,
    required this.onDayChanged,
    required this.onModeChanged,
    required this.onCreateTrip,
    required this.onQuickAddPlace,
    required this.onAddActivity,
    required this.onActivityTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = sortedPlannerItems(
      app.timeline,
      tripId: selectedTrip.id,
      dayNumber: selectedDay,
    );
    final selectedDate = plannerDateForDay(selectedTrip, selectedDay);
    final locale = Localizations.localeOf(context).toString();
    final fullDate = DateFormat.yMMMMEEEEd(locale).format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlannerHeader(
          trips: trips,
          selectedTrip: selectedTrip,
          lockTripSelection: lockTripSelection,
          onTripChanged: onTripChanged,
          onCreateTrip: onCreateTrip,
        ),
        const SizedBox(height: AppSpacing.md),
        _ModeSwitch(mode: mode, onChanged: onModeChanged),
        const SizedBox(height: AppSpacing.md),
        _DaySelector(
          trip: selectedTrip,
          selectedDay: selectedDay,
          onDayChanged: onDayChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          fullDate,
          key: const Key('planner-selected-date'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        if (mode == PlannerPresentationMode.route)
          _RouteFallback(
            trip: selectedTrip,
            selectedDay: selectedDay,
            items: items,
            onTimeline: () => onModeChanged(PlannerPresentationMode.timeline),
          )
        else
          _TimelineList(
            trip: selectedTrip,
            selectedDay: selectedDay,
            items: items,
            onQuickAddPlace: () => onQuickAddPlace(selectedTrip),
            onAddActivity: () => onAddActivity(selectedTrip),
            onActivityTap: (item) => onActivityTap(selectedTrip, item),
          ),
      ],
    );
  }
}

class _PlannerHeader extends StatelessWidget {
  final List<Trip> trips;
  final Trip selectedTrip;
  final bool lockTripSelection;
  final ValueChanged<int>? onTripChanged;
  final VoidCallback onCreateTrip;

  const _PlannerHeader({
    required this.trips,
    required this.selectedTrip,
    required this.lockTripSelection,
    required this.onTripChanged,
    required this.onCreateTrip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale);
    final tripMeta = l10n.tripDateTravelerMeta(
      date.format(selectedTrip.startDate),
      date.format(selectedTrip.endDate),
      selectedTrip.travelers,
    );
    return OceanGlassCard(
      semanticLabel: l10n.plannerTripSelectorSemantic,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AppBreakpoints.tablet;
          final image = _TripThumb(trip: selectedTrip);
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.plannerTitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                selectedTrip.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(tripMeta, style: Theme.of(context).textTheme.bodyLarge),
            ],
          );
          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!lockTripSelection)
                _TripSelector(
                  trips: trips,
                  selectedTrip: selectedTrip,
                  onChanged: onTripChanged,
                ),
              const SizedBox(height: AppSpacing.xs),
              OceanSecondaryButton(
                label: l10n.plannerCreateTripAction,
                icon: Icons.add_rounded,
                semanticLabel: l10n.tripsCreateSemantic,
                onPressed: onCreateTrip,
              ),
            ],
          );

          if (wide) {
            return Row(
              children: [
                image,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: copy),
                const SizedBox(width: AppSpacing.md),
                SizedBox(width: 260, child: actions),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  image,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: copy),
                ],
              ),
              if (!lockTripSelection || trips.length > 1) ...[
                const SizedBox(height: AppSpacing.md),
                actions,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TripThumb extends StatelessWidget {
  final Trip trip;

  const _TripThumb({required this.trip});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Image.network(
          trip.imageUrl,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => Container(
            width: 76,
            height: 76,
            color: AppColors.paleCyan,
            alignment: Alignment.center,
            child: const Icon(Icons.landscape_rounded, color: AppColors.ocean),
          ),
        ),
      );
}

class _TripSelector extends StatelessWidget {
  final List<Trip> trips;
  final Trip selectedTrip;
  final ValueChanged<int>? onChanged;

  const _TripSelector({
    required this.trips,
    required this.selectedTrip,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.plannerTripSelectorSemantic,
      button: true,
      child: DropdownButtonFormField<int>(
        key: const Key('planner-trip-selector'),
        initialValue: selectedTrip.id,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.plannerTripSelectorLabel,
          prefixIcon: const Icon(Icons.luggage_rounded),
        ),
        items: [
          for (final trip in trips)
            DropdownMenuItem<int>(
              value: trip.id,
              child: Text(
                trip.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged == null
            ? null
            : (value) {
                if (value != null) onChanged!(value);
              },
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final PlannerPresentationMode mode;
  final ValueChanged<PlannerPresentationMode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.plannerModeSemantic,
      child: SegmentedButton<PlannerPresentationMode>(
        segments: [
          ButtonSegment(
            value: PlannerPresentationMode.timeline,
            icon: const Icon(Icons.format_list_bulleted_rounded),
            label: Text(l10n.plannerTimelineMode),
          ),
          ButtonSegment(
            value: PlannerPresentationMode.route,
            icon: const Icon(Icons.map_outlined),
            label: Text(l10n.plannerRouteMode),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final Trip trip;
  final int selectedDay;
  final ValueChanged<int> onDayChanged;

  const _DaySelector({
    required this.trip,
    required this.selectedDay,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final weekday = DateFormat.E(locale);
    final date = DateFormat.MMMd(locale);
    return SizedBox(
      height: 106,
      child: Semantics(
        container: true,
        label: l10n.plannerDaySelectorSemantic,
        child: ListView.separated(
          key: const PageStorageKey('planner-day-selector'),
          scrollDirection: Axis.horizontal,
          itemCount: trip.days,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final dayNumber = index + 1;
            final dayDate = plannerDateForDay(trip, dayNumber);
            final selected = dayNumber == selectedDay;
            return Semantics(
              button: true,
              selected: selected,
              label: l10n.plannerDaySemantic(dayNumber),
              child: ExcludeSemantics(
                child: ChoiceChip(
                  key: Key('planner-day-$dayNumber'),
                  selected: selected,
                  onSelected: (_) => onDayChanged(dayNumber),
                  label: SizedBox(
                    width: 98,
                    height: 70,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.tripOverviewDayLabel(dayNumber)),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${weekday.format(dayDate)}, ${date.format(dayDate)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: selected
                              ? AppColors.ocean
                              : AppColors.turquoise600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  final Trip trip;
  final int selectedDay;
  final List<TimelineItem> items;
  final VoidCallback onQuickAddPlace;
  final VoidCallback onAddActivity;
  final ValueChanged<TimelineItem> onActivityTap;

  const _TimelineList({
    required this.trip,
    required this.selectedDay,
    required this.items,
    required this.onQuickAddPlace,
    required this.onAddActivity,
    required this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          children: [
            OceanSecondaryButton(
              key: const Key('planner-quick-add'),
              label: l10n.plannerQuickAddAction,
              icon: Icons.add_location_alt_rounded,
              semanticLabel: l10n.plannerQuickAddSemantic,
              onPressed: onQuickAddPlace,
              fullWidth: false,
            ),
            OceanPrimaryButton(
              key: const Key('planner-add-activity'),
              label: l10n.plannerAddActivityAction,
              icon: Icons.add_rounded,
              semanticLabel: l10n.plannerAddActivitySemantic,
              onPressed: onAddActivity,
              fullWidth: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          OceanEmptyState(
            title: l10n.plannerEmptyDayTitle,
            message: l10n.plannerEmptyDayMessage,
            actionLabel: l10n.plannerAddActivityAction,
            onAction: onAddActivity,
          )
        else
          Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _TimelineRow(
                  item: items[i],
                  isLast: i == items.length - 1,
                  onTap: () => onActivityTap(items[i]),
                ),
            ],
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineItem item;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineRow({
    required this.item,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final time = '${item.startTime} - ${item.endTime}';
    final valid = plannerHasValidInterval(item);
    return Semantics(
      button: true,
      label: l10n.plannerActivityCardSemantic(item.title, time),
      child: ExcludeSemantics(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 74,
                child: Column(
                  children: [
                    Text(
                      item.startTime,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.ocean),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        color: isLast
                            ? Colors.transparent
                            : AppColors.ocean.withValues(alpha: .24),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: valid ? AppColors.ocean : AppColors.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast
                          ? Colors.transparent
                          : AppColors.ocean.withValues(alpha: .18),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: OceanGlassCard(
                    key: Key('activity-card-${item.id}'),
                    onTap: onTap,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ActivityImage(item: item, size: 86),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                time,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.ocean),
                              ),
                              if (!valid) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                OceanStatusPill(
                                  label: l10n.plannerInvalidTimeLabel,
                                  icon: Icons.error_outline_rounded,
                                  color: AppColors.coral,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  if (item.category.isNotEmpty)
                                    OceanStatusPill(
                                      label: item.category,
                                      icon: Icons.local_activity_rounded,
                                      color: AppColors.turquoise600,
                                    ),
                                  if (item.place != null)
                                    OceanStatusPill(
                                      label: item.place!.locationName,
                                      icon: Icons.place_rounded,
                                    ),
                                ],
                              ),
                              if (item.notes.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  item.notes,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityImage extends StatelessWidget {
  final TimelineItem item;
  final double size;

  const _ActivityImage({required this.item, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final place = item.place;
    if (place == null || place.imageUrl.isEmpty) {
      return _ImageFallback(size: size, icon: Icons.event_note_rounded);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Image.network(
        place.imageUrl,
        key: Key('activity-image-${item.id}'),
        width: size,
        height: size,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => _ImageFallback(
          key: Key('activity-image-fallback-${item.id}'),
          size: size,
          icon: Icons.image_not_supported_rounded,
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final double size;
  final IconData icon;

  const _ImageFallback({
    super.key,
    required this.size,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.paleCyan,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.ocean, size: AppIconSizes.lg),
      );
}

class _RouteFallback extends StatelessWidget {
  final Trip trip;
  final int selectedDay;
  final List<TimelineItem> items;
  final VoidCallback onTimeline;

  const _RouteFallback({
    required this.trip,
    required this.selectedDay,
    required this.items,
    required this.onTimeline,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.plannerRouteFallbackSemantic,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OceanStateView(
            icon: Icons.map_outlined,
            title: l10n.mapUnavailableTitle,
            message: l10n.plannerRouteUnavailableMessage,
            semanticLabel: l10n.plannerRouteFallbackSemantic,
            actionLabel: l10n.plannerBackToTimelineAction,
            onAction: onTimeline,
            primaryAction: false,
          ),
          const SizedBox(height: AppSpacing.md),
          OceanGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.plannerRoutePreviewTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (items.isEmpty)
                  Text(l10n.plannerEmptyDayMessage)
                else
                  for (var i = 0; i < items.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.ocean.withValues(alpha: .12),
                        child: Text('${i + 1}'),
                      ),
                      title: Text(items[i].title),
                      subtitle: Text(items[i].startTime),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerQuickAddPlaceSheet extends StatefulWidget {
  final BuildContext parentContext;
  final Trip trip;
  final int initialDay;

  const _PlannerQuickAddPlaceSheet({
    required this.parentContext,
    required this.trip,
    required this.initialDay,
  });

  @override
  State<_PlannerQuickAddPlaceSheet> createState() =>
      _PlannerQuickAddPlaceSheetState();
}

class _PlannerQuickAddPlaceSheetState
    extends State<_PlannerQuickAddPlaceSheet> {
  final _search = TextEditingController();
  final _start = TextEditingController(text: '10:00');
  final _end = TextEditingController(text: '12:00');
  final _startFocus = FocusNode();
  late int _day;
  int? _selectedPlaceId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _day = clampPlannerDay(widget.trip, widget.initialDay);
  }

  @override
  void dispose() {
    _search.dispose();
    _start.dispose();
    _end.dispose();
    _startFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final places = _filteredPlaces(app);
    final selectedPlace =
        _selectedPlaceId == null ? null : app.placeById(_selectedPlaceId!);

    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetGrabber(),
            Text(l10n.quickAddTitle,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.quickAddSuggestionsTitle(
                l10n.tripOverviewDayLabel(_day),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            OceanSearchField(
              key: const Key('planner-quick-place-search'),
              controller: _search,
              hintText: l10n.quickAddSearchHint,
              onChanged: (_) => setState(() {}),
              onClear: () => setState(_search.clear),
              semanticLabel: l10n.searchFieldSemanticLabel,
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 1; i <= widget.trip.days; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        key: Key('planner-quick-day-$i'),
                        selected: _day == i,
                        label: Text(l10n.tripOverviewDayLabel(i)),
                        onSelected: (_) => setState(() => _day = i),
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
                    key: const Key('planner-quick-start-field'),
                    controller: _start,
                    focusNode: _startFocus,
                    label: l10n.activityStartTimeLabel,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TimeField(
                    key: const Key('planner-quick-end-field'),
                    controller: _end,
                    label: l10n.activityEndTimeLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (places.isEmpty)
              OceanEmptyState(
                title: l10n.quickAddNoPlacesTitle,
                message: l10n.quickAddNoPlacesMessage,
              )
            else
              Column(
                children: [
                  for (final place in places.take(6))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _QuickPlaceOption(
                        key: Key('planner-quick-place-${place.id}'),
                        place: place,
                        selected: _selectedPlaceId == place.id,
                        onTap: () =>
                            setState(() => _selectedPlaceId = place.id),
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
                    key: const Key('planner-quick-place-submit'),
                    label: l10n.quickAddSubmitAction(_day),
                    icon: Icons.add_rounded,
                    onPressed: selectedPlace == null
                        ? null
                        : () => _add(selectedPlace),
                  ),
          ],
        ),
      ),
    );
  }

  List<Place> _filteredPlaces(AppState app) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return app.places;
    return app.places
        .where((place) =>
            place.name.toLowerCase().contains(query) ||
            place.city.toLowerCase().contains(query) ||
            place.category.toLowerCase().contains(query) ||
            place.tags.any((tag) => tag.toLowerCase().contains(query)))
        .toList();
  }

  Future<void> _add(Place place) async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final app = AppScope.of(context);
    if (!AppState.isValidTimeRange(_start.text.trim(), _end.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.activityInvalidTimeRange)),
      );
      _startFocus.requestFocus();
      return;
    }
    setState(() => _submitting = true);
    final item = TimelineItem(
      id: app.newId,
      tripId: widget.trip.id,
      dayNumber: _day,
      startTime: _start.text.trim(),
      endTime: _end.text.trim(),
      title: place.name,
      notes: place.description,
      place: place,
      placeId: place.id,
      category: place.category,
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
    Navigator.pop(context, true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.quickAddAddedMessage(
          place.name,
          widget.trip.title,
          _day,
        )),
      ),
    );
  }
}

class _QuickPlaceOption extends StatelessWidget {
  final Place place;
  final bool selected;
  final VoidCallback onTap;

  const _QuickPlaceOption({
    super.key,
    required this.place,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => OceanGlassSurface(
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
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Image.network(
                place.imageUrl,
                width: 76,
                height: 64,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => Container(
                  width: 76,
                  height: 64,
                  color: AppColors.paleCyan,
                  child:
                      const Icon(Icons.place_rounded, color: AppColors.ocean),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${place.locationName} · ${place.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

Future<bool?> showPlannerActivityEditorSheet(
  BuildContext context, {
  required Trip trip,
  required int initialDay,
  TimelineItem? existing,
  Place? place,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ActivityEditorSheet(
      parentContext: context,
      trip: trip,
      initialDay: initialDay,
      existing: existing,
      place: place,
    ),
  );
}

class _ActivityEditorSheet extends StatefulWidget {
  final BuildContext parentContext;
  final Trip trip;
  final int initialDay;
  final TimelineItem? existing;
  final Place? place;

  const _ActivityEditorSheet({
    required this.parentContext,
    required this.trip,
    required this.initialDay,
    this.existing,
    this.place,
  });

  @override
  State<_ActivityEditorSheet> createState() => _ActivityEditorSheetState();
}

class _ActivityEditorSheetState extends State<_ActivityEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final FocusNode _startFocus;
  late final FocusNode _titleFocus;
  late int _day;
  late String _category;
  bool _submitting = false;

  static const _categories = [
    'Activity',
    'Hotel',
    'Food',
    'Transport',
    'Shopping',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final place = widget.place ?? existing?.place;
    _title = TextEditingController(text: existing?.title ?? place?.name ?? '');
    _notes = TextEditingController(
      text: existing?.notes ?? place?.description ?? '',
    );
    _start = TextEditingController(text: existing?.startTime ?? '09:00');
    _end = TextEditingController(text: existing?.endTime ?? '10:00');
    _day =
        clampPlannerDay(widget.trip, existing?.dayNumber ?? widget.initialDay);
    _category = existing?.category ?? place?.category ?? 'Activity';
    _startFocus = FocusNode();
    _titleFocus = FocusNode();
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _start.dispose();
    _end.dispose();
    _startFocus.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetGrabber(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? l10n.activityAddTitle
                        : l10n.activityEditTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.activityCloseAction,
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('activity-title-field'),
              controller: _title,
              focusNode: _titleFocus,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.activityTitleLabel,
                prefixIcon: const Icon(Icons.edit_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('activity-notes-field'),
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.activityNotesLabel,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.activityDayLabel,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 1; i <= widget.trip.days; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        key: Key('activity-day-$i'),
                        selected: _day == i,
                        label: Text(l10n.tripOverviewDayLabel(i)),
                        onSelected: (_) => setState(() => _day = i),
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
                    key: const Key('activity-start-field'),
                    controller: _start,
                    focusNode: _startFocus,
                    label: l10n.activityStartTimeLabel,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TimeField(
                    key: const Key('activity-end-field'),
                    controller: _end,
                    label: l10n.activityEndTimeLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.activityCategoryLabel,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final category in _categories)
                  ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _submitting
                ? const Center(
                    child: SizedBox(width: 280, child: OceanLoadingState()))
                : OceanPrimaryButton(
                    key: const Key('activity-save-button'),
                    label: widget.existing == null
                        ? l10n.activityAddAction
                        : l10n.activitySaveAction,
                    semanticLabel: widget.existing == null
                        ? l10n.activityAddSemantic
                        : l10n.activitySaveSemantic,
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final title = _title.text.trim();
    if (title.isEmpty) {
      _showLocalSnack(l10n.activityTitleRequired);
      _titleFocus.requestFocus();
      return;
    }
    if (!AppState.isValidTimeRange(_start.text.trim(), _end.text.trim())) {
      _showLocalSnack(l10n.activityInvalidTimeRange);
      _startFocus.requestFocus();
      return;
    }
    if (!plannerDayIsInTrip(widget.trip, _day)) {
      _showLocalSnack(l10n.activityOutOfRangeDay);
      return;
    }

    setState(() => _submitting = true);
    final app = AppScope.of(context);
    final existing = widget.existing;
    final place = widget.place ?? existing?.place;
    final candidate = existing == null
        ? TimelineItem(
            id: app.newId,
            tripId: widget.trip.id,
            dayNumber: _day,
            startTime: _start.text.trim(),
            endTime: _end.text.trim(),
            title: title,
            notes: _notes.text.trim(),
            place: place,
            placeId: place?.id,
            category: _category,
            estimatedCost: existing?.estimatedCost ?? 0,
          )
        : existing.copyWith(
            dayNumber: _day,
            startTime: _start.text.trim(),
            endTime: _end.text.trim(),
            title: title,
            notes: _notes.text.trim(),
            category: _category,
          );

    final conflict = findPlannerConflict(
      app.timeline,
      candidate,
      ignoreId: existing?.id,
    );
    if (conflict != null) {
      setState(() => _submitting = false);
      final decision = await showPlannerConflictSheet(
        context,
        conflict: conflict,
        candidate: candidate,
        isEdit: existing != null,
      );
      if (!mounted) return;
      if (decision == PlannerConflictDecision.changeTime) {
        _startFocus.requestFocus();
        return;
      }
      if (decision != PlannerConflictDecision.saveAnyway) return;
      setState(() => _submitting = true);
    }

    final saved = existing == null
        ? app.addTimeline(candidate)
        : app.updateTimeline(candidate);
    if (!saved) {
      if (mounted) {
        setState(() => _submitting = false);
        _showLocalSnack(l10n.activitySaveFailed);
      }
      return;
    }
    if (!mounted || !widget.parentContext.mounted) return;
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    Navigator.pop(context, true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? l10n.activityAddedMessage
              : l10n.activitySavedMessage,
        ),
      ),
    );
  }

  void _showLocalSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    return Semantics(
      textField: true,
      label: label,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.datetime,
        decoration: InputDecoration(
          labelText: label,
          helperText: l10n.activityTimeHint,
          prefixIcon: const Icon(Icons.schedule_rounded),
        ),
      ),
    );
  }
}

Future<void> showPlannerActivityDetailSheet(
  BuildContext context, {
  required Trip trip,
  required TimelineItem item,
  required VoidCallback onEdit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ActivityDetailSheet(
      parentContext: context,
      trip: trip,
      item: item,
      onEdit: onEdit,
    ),
  );
}

class _ActivityDetailSheet extends StatelessWidget {
  final BuildContext parentContext;
  final Trip trip;
  final TimelineItem item;
  final VoidCallback onEdit;

  const _ActivityDetailSheet({
    required this.parentContext,
    required this.trip,
    required this.item,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetGrabber(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.activityDetailTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                OceanSecondaryButton(
                  key: Key('activity-edit-${item.id}'),
                  label: l10n.activityEditAction,
                  icon: Icons.edit_rounded,
                  semanticLabel: l10n.activityEditSemantic(item.title),
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                  fullWidth: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ActivityImage(item: item, size: 118),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      OceanStatusPill(
                        label: item.category,
                        icon: Icons.local_activity_rounded,
                        color: AppColors.turquoise600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: Icons.schedule_rounded,
              title: '${item.startTime} - ${item.endTime}',
              subtitle: l10n.tripOverviewDayLabel(item.dayNumber),
            ),
            if (item.place != null) ...[
              _DetailRow(
                icon: Icons.place_rounded,
                title: item.place!.name,
                subtitle: item.place!.locationName,
                trailing: TextButton(
                  onPressed: () {
                    final nav = Navigator.of(parentContext);
                    Navigator.pop(context);
                    nav.push(MaterialPageRoute(
                      builder: (_) => PlaceDetailScreen(place: item.place!),
                    ));
                  },
                  child: Text(l10n.activityViewPlaceAction),
                ),
              ),
            ],
            if (item.estimatedCost > 0)
              _DetailRow(
                icon: Icons.account_balance_wallet_rounded,
                title: l10n.activityEstimatedCostLabel,
                subtitle: money.format(item.estimatedCost),
              ),
            if (item.notes.isNotEmpty)
              _DetailRow(
                icon: Icons.notes_rounded,
                title: l10n.activityNotesLabel,
                subtitle: item.notes,
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
            const SizedBox(height: AppSpacing.md),
            OceanSecondaryButton(
              label: l10n.activityCloseAction,
              icon: Icons.close_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            OceanSecondaryButton(
              key: Key('activity-delete-${item.id}'),
              label: l10n.activityDeleteAction,
              icon: Icons.delete_outline_rounded,
              semanticLabel: l10n.activityDeleteSemantic(item.title),
              onPressed: () => _delete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final app = AppScope.of(parentContext);
    final messenger = ScaffoldMessenger.of(parentContext);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.activityDeleteConfirmTitle),
        content: Text(l10n.activityDeleteConfirmMessage(item.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            key: const Key('activity-confirm-delete'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.activityDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    app.deleteTimeline(item.id);
    if (!context.mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.activityDeletedMessage)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: OceanGlassSurface(
          blur: 0,
          color: AppColors.surfaceOverlay,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.ocean.withValues(alpha: .10),
                child: Icon(icon, color: AppColors.ocean),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      );
}

Future<PlannerConflictDecision?> showPlannerConflictSheet(
  BuildContext context, {
  required TimelineItem conflict,
  required TimelineItem candidate,
  required bool isEdit,
}) {
  return showModalBottomSheet<PlannerConflictDecision>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ConflictSheet(
      conflict: conflict,
      candidate: candidate,
      isEdit: isEdit,
    ),
  );
}

class _ConflictSheet extends StatelessWidget {
  final TimelineItem conflict;
  final TimelineItem candidate;
  final bool isEdit;

  const _ConflictSheet({
    required this.conflict,
    required this.candidate,
    required this.isEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetGrabber(),
            Text(l10n.activityConflictTitle,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            OceanGlassSurface(
              blur: 0,
              color: AppColors.coral.withValues(alpha: .10),
              border: Border.all(color: AppColors.coral.withValues(alpha: .25)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.coral),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.activityConflictMessage(
                        conflict.title,
                        '${candidate.startTime} - ${candidate.endTime}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ConflictItem(item: conflict),
            const SizedBox(height: AppSpacing.lg),
            OceanPrimaryButton(
              key: const Key('conflict-change-time'),
              label: l10n.activityConflictChangeTime,
              icon: Icons.schedule_rounded,
              onPressed: () => Navigator.pop(
                context,
                PlannerConflictDecision.changeTime,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            OceanSecondaryButton(
              key: const Key('conflict-add-anyway'),
              label: isEdit
                  ? l10n.activityConflictSaveAnyway
                  : l10n.activityConflictAddAnyway,
              icon: Icons.warning_amber_rounded,
              onPressed: () => _confirmAnyway(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              key: const Key('conflict-cancel'),
              onPressed: () =>
                  Navigator.pop(context, PlannerConflictDecision.cancel),
              child: Text(l10n.profileCancel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAnyway(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.activityConflictKeepBothTitle),
        content: Text(l10n.activityConflictKeepBothMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            key: const Key('conflict-confirm-add-anyway'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.activityConflictKeepBothAction),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context, PlannerConflictDecision.saveAnyway);
    }
  }
}

class _ConflictItem extends StatelessWidget {
  final TimelineItem item;

  const _ConflictItem({required this.item});

  @override
  Widget build(BuildContext context) => OceanGlassSurface(
        blur: 0,
        color: AppColors.surfaceOverlay,
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.paleCyan,
              child: Icon(Icons.local_activity_rounded, color: AppColors.ocean),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.startTime} - ${item.endTime}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.ocean),
                  ),
                  Text(item.title,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 48,
          height: 5,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.disabled,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
      );
}
