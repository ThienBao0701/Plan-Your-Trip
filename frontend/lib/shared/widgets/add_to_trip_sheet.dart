import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../features/trips/create_trip_screen.dart';
import '../../features/trips/trip_detail_screen.dart';
import 'glass_widgets.dart';

final _money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

Future<void> showAddToTripSheet(BuildContext context, Place place) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AddToTripSheet(parentContext: context, place: place),
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
  Trip? _selectedTrip;
  int _selectedDay = 1;
  String _startTime = '10:00';
  String _endTime = '12:00';
  bool _navigating = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final trips = app.trips;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                            color: AppColors.slate.withValues(alpha: .4),
                            borderRadius: BorderRadius.circular(2)))),
                Text('Add to trip',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(widget.place.name,
                    style: const TextStyle(
                        color: AppColors.ocean, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                if (trips.isEmpty) ...[
                  const Text('You have no trips yet.',
                      style: TextStyle(color: AppColors.slate)),
                  const SizedBox(height: 12),
                  GlassButton(
                      text: 'Create a trip first',
                      icon: Icons.add_rounded,
                      onPressed: () {
                        if (_navigating) return;
                        _navigating = true;
                        final nav = Navigator.of(widget.parentContext);
                        Navigator.of(context).pop();
                        nav.push(MaterialPageRoute(
                            builder: (_) => const CreateTripScreen()));
                      }),
                ] else ...[
                  Text('Select trip',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...trips.map((t) => _TripOption(
                        trip: t,
                        selected: _selectedTrip?.id == t.id,
                        onTap: () => setState(() {
                          _selectedTrip = t;
                          _selectedDay = 1;
                        }),
                      )),
                  if (_selectedTrip != null) ...[
                    const SizedBox(height: 16),
                    Text('Select day',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: List.generate(
                                _selectedTrip!.days,
                                (i) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                        label: Text('Day ${i + 1}'),
                                        selected: _selectedDay == i + 1,
                                        onSelected: (_) => setState(
                                            () => _selectedDay = i + 1)))))),
                    const SizedBox(height: 16),
                    Text('Time range',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(children: [
                      _TimeButton(
                          label: 'Start',
                          time: _startTime,
                          onTap: () => _pickTime(isStart: true)),
                      const SizedBox(width: 12),
                      const Text('→', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      _TimeButton(
                          label: 'End',
                          time: _endTime,
                          onTap: () => _pickTime(isStart: false)),
                    ]),
                    const SizedBox(height: 20),
                    GlassButton(
                        text: 'Add to Day $_selectedDay',
                        icon: Icons.add_rounded,
                        onPressed: _confirm),
                  ],
                ],
              ])),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final parts = (isStart ? _startTime : _endTime).split(':');
    final initial =
        TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final str =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _startTime = str;
      } else {
        _endTime = str;
      }
    });
  }

  void _confirm() {
    if (_selectedTrip == null) return;
    final app = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final nav = Navigator.of(widget.parentContext);
    final trip = _selectedTrip!;
    if (!AppState.isValidTimeRange(_startTime, _endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('End time must be later than start time.')));
      return;
    }
    final item = TimelineItem(
      id: app.newId,
      tripId: trip.id,
      dayNumber: _selectedDay,
      startTime: _startTime,
      endTime: _endTime,
      title: widget.place.name,
      notes: widget.place.description,
      place: widget.place,
      placeId: widget.place.id,
      category: widget.place.category,
      estimatedCost: 0,
    );
    if (!app.addTimeline(item)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not add this activity to the selected trip.')));
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
        content: Text(
            '${widget.place.name} added to ${trip.title} · Day $_selectedDay'),
        action: SnackBarAction(
            label: 'View trip',
            onPressed: () {
              nav.push(MaterialPageRoute(
                  builder: (_) => TripDetailScreen(trip: trip)));
            })));
  }
}

class _TripOption extends StatelessWidget {
  final Trip trip;
  final bool selected;
  final VoidCallback onTap;
  const _TripOption(
      {required this.trip, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: selected
                  ? AppColors.ocean.withValues(alpha: .12)
                  : Colors.white.withValues(alpha: .5),
              border: Border.all(
                  color: selected ? AppColors.ocean : Colors.transparent,
                  width: 2)),
          child: Row(children: [
            Icon(Icons.map_rounded,
                color: selected ? AppColors.ocean : AppColors.slate),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(trip.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.ocean : AppColors.ink)),
                  Text('${trip.days} days • ${trip.travelers} travelers',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.slate)),
                ])),
            Text(_money.format(trip.budget),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate)),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.ocean)
          ])));
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  const _TimeButton(
      {required this.label, required this.time, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.ocean.withValues(alpha: .1),
              border: Border.all(color: AppColors.ocean.withValues(alpha: .3))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.slate)),
            Text(time,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.ocean)),
          ])));
}
