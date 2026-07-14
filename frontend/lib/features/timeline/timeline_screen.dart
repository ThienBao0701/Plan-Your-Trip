import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/travel_cards.dart';

class TimelineScreen extends StatefulWidget {
  final Trip trip;
  const TimelineScreen({super.key, required this.trip});
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  int day = 1;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = app.itemsForTrip(widget.trip.id, day);
    return Scaffold(
        appBar: AppBar(title: const Text('Trip Planner')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSheet(context, app),
            label: const Text('Add activity'),
            icon: const Icon(Icons.add_rounded)),
        body: BubbleBackground(
            child: SafeArea(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                    children: [
              Text(widget.trip.title,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                  '${widget.trip.destination} · ${widget.trip.days} days · ${widget.trip.travelers} travelers',
                  style: const TextStyle(
                      color: AppColors.slate, fontWeight: FontWeight.w500)),
              const SizedBox(height: 14),
              GlassCard(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                          children: List.generate(
                              widget.trip.days,
                              (i) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                          minWidth: 72, minHeight: 48),
                                      child: ChoiceChip(
                                          label: Text('Day ${i + 1}'),
                                          selected: day == i + 1,
                                          onSelected: (_) => setState(
                                              () => day = i + 1)))))))),
              const SizedBox(height: 18),
              if (items.isEmpty)
                const PremiumEmptyState(
                    'No activities yet. Tap + to add your first activity.'),
              ...items.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                              color: AppColors.coral.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(28)),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.coral)),
                      onDismissed: (_) => app.deleteTimeline(e.id),
                      child: TimelineCard(
                          item: e,
                          onEdit: () => _showEditSheet(context, app, e),
                          onDelete: () => app.deleteTimeline(e.id))))),
            ]))));
  }

  void _showAddSheet(BuildContext context, AppState app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivitySheet(
        parentContext: context,
        tripId: widget.trip.id,
        dayNumber: day,
        onSave: (item) => app.addTimeline(item),
      ),
    );
  }

  void _showEditSheet(BuildContext context, AppState app, TimelineItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivitySheet(
        parentContext: context,
        tripId: widget.trip.id,
        dayNumber: day,
        existing: item,
        onSave: (updated) => app.updateTimeline(updated),
      ),
    );
  }
}

// ── Add / Edit activity bottom sheet ────────────────────────────────────────

class _ActivitySheet extends StatefulWidget {
  final BuildContext parentContext;
  final int tripId;
  final int dayNumber;
  final TimelineItem? existing;
  final bool Function(TimelineItem) onSave;

  const _ActivitySheet({
    required this.parentContext,
    required this.tripId,
    required this.dayNumber,
    required this.onSave,
    this.existing,
  });

  @override
  State<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends State<_ActivitySheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late String _startTime;
  late String _endTime;
  late String _category;

  static const _categories = [
    'Activity',
    'Hotel',
    'Food',
    'Transport',
    'Shopping',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _startTime = e?.startTime ?? '09:00';
    _endTime = e?.endTime ?? '11:00';
    _category = e?.category ?? 'Activity';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a title.')));
      return;
    }
    if (!AppState.isValidTimeRange(_startTime, _endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('End time must be later than start time.')));
      return;
    }
    final existing = widget.existing;
    final item = existing != null
        ? existing.copyWith(
            title: title,
            notes: _notesCtrl.text.trim(),
            startTime: _startTime,
            endTime: _endTime,
            category: _category,
          )
        : TimelineItem(
            id: DateTime.now().millisecondsSinceEpoch,
            tripId: widget.tripId,
            dayNumber: widget.dayNumber,
            startTime: _startTime,
            endTime: _endTime,
            title: title,
            notes: _notesCtrl.text.trim(),
            category: _category,
          );
    final saved = widget.onSave(item);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save activity for this trip day.')));
      return;
    }
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
        content:
            Text(existing == null ? 'Activity added!' : 'Activity updated!')));
  }

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: AppColors.slate.withValues(alpha: .4),
                        borderRadius: BorderRadius.circular(2)))),
            Text(widget.existing == null ? 'Add activity' : 'Edit activity',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    hintText: 'Activity title',
                    prefixIcon: Icon(Icons.edit_rounded))),
            const SizedBox(height: 12),
            TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    hintText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes_rounded))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _TimeBtn(
                      label: 'Start',
                      time: _startTime,
                      onTap: () => _pickTime(isStart: true))),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('→', style: TextStyle(fontSize: 18))),
              Expanded(
                  child: _TimeBtn(
                      label: 'End',
                      time: _endTime,
                      onTap: () => _pickTime(isStart: false))),
            ]),
            const SizedBox(height: 12),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: _categories
                        .map((c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                                label: Text(c),
                                selected: _category == c,
                                onSelected: (_) =>
                                    setState(() => _category = c))))
                        .toList())),
            const SizedBox(height: 20),
            GlassButton(
                text: widget.existing == null ? 'Add activity' : 'Save changes',
                icon: Icons.check_rounded,
                onPressed: _save),
          ])));
}

class _TimeBtn extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  const _TimeBtn(
      {required this.label, required this.time, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.ocean.withValues(alpha: .08),
              border:
                  Border.all(color: AppColors.ocean.withValues(alpha: .25))),
          child: Column(children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.slate)),
            const SizedBox(height: 2),
            Text(time,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: AppColors.ocean)),
          ])));
}
