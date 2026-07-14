import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';

class EditTripScreen extends StatefulWidget {
  final Trip trip;
  const EditTripScreen({super.key, required this.trip});
  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _destCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _notesCtrl;
  late int _travelers;
  late DateTimeRange _dateRange;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.trip;
    _titleCtrl = TextEditingController(text: t.title);
    _destCtrl = TextEditingController(text: t.destination);
    _budgetCtrl = TextEditingController(
        text: t.budget > 0 ? t.budget.toInt().toString() : '');
    _notesCtrl = TextEditingController(text: t.notes);
    _travelers = t.travelers;
    _dateRange = DateTimeRange(start: t.startDate, end: t.endDate);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _destCtrl.dispose();
    _budgetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _pickDates() async {
    final now = DateTime.now().subtract(const Duration(days: 365));
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 1460)),
      initialDateRange: _dateRange,
    );
    if (range != null && mounted) setState(() => _dateRange = range);
  }

  void _pickTravelers() {
    showDialog(
      context: context,
      builder: (_) => _TravelerDialog(
        count: _travelers,
        onChanged: (v) => setState(() => _travelers = v),
      ),
    );
  }

  void _save() async {
    final dest = _destCtrl.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a destination.')));
      return;
    }
    setState(() => _saving = true);
    final app = AppScope.of(context);
    final budget = double.tryParse(
            _budgetCtrl.text.replaceAll(',', '').replaceAll('.', '')) ??
        widget.trip.budget;
    final updated = widget.trip.copyWith(
      title: _titleCtrl.text.trim().isEmpty
          ? widget.trip.title
          : _titleCtrl.text.trim(),
      destination: dest,
      startDate: _dateRange.start,
      endDate: _dateRange.end,
      travelers: _travelers,
      budget: budget,
      notes: _notesCtrl.text.trim(),
    );
    final shortened = updated.days < widget.trip.days;
    final hasOutOfRangeItems = app.timeline.any(
        (item) => item.tripId == updated.id && item.dayNumber > updated.days);
    if (shortened && hasOutOfRangeItems) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: const Text('Move activities?'),
              content: Text(
                  'This shorter trip has ${updated.days} days. Activities from removed days will move to Day ${updated.days}.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Move to last day')),
              ],
            ),
          ) ??
          false;
      if (!mounted) return;
      if (!confirmed) {
        setState(() => _saving = false);
        return;
      }
    }
    app.updateTrip(updated);
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      setState(() => _saving = false);
      nav.pop(updated);
      messenger.showSnackBar(const SnackBar(content: Text('Trip updated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final dateLabel =
        '${fmt.format(_dateRange.start)} → ${fmt.format(_dateRange.end)}';

    return Scaffold(
        appBar: AppBar(title: Text('Edit ${widget.trip.title}')),
        body: BubbleBackground(
            child: SafeArea(
                child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Update your trip',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          GlassCard(
              child: Column(children: [
            GlassTextField(
                controller: _destCtrl,
                hint: 'Destination',
                icon: Icons.place_rounded),
            const SizedBox(height: 12),
            GlassTextField(
                controller: _titleCtrl,
                hint: 'Trip title',
                icon: Icons.drive_file_rename_outline_rounded),
            const SizedBox(height: 12),
            _PickerRow(
                icon: Icons.calendar_month_rounded,
                label: dateLabel,
                onTap: _pickDates),
            const SizedBox(height: 12),
            _PickerRow(
                icon: Icons.people_rounded,
                label: '$_travelers traveler${_travelers == 1 ? '' : 's'}',
                onTap: _pickTravelers),
            const SizedBox(height: 12),
            GlassTextField(
                controller: _budgetCtrl,
                hint: 'Budget (₫)',
                icon: Icons.savings_rounded,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            GlassTextField(
                controller: _notesCtrl,
                hint: 'Notes',
                icon: Icons.notes_rounded),
            const SizedBox(height: 20),
            _saving
                ? const PremiumLoading()
                : GlassButton(
                    text: 'Update trip',
                    icon: Icons.save_rounded,
                    onPressed: _save),
          ])),
        ]))));
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerRow(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: .70),
              border: Border.all(color: Colors.white.withValues(alpha: .80))),
          child: Row(children: [
            Icon(icon, color: AppColors.ocean),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
          ])));
}

class _TravelerDialog extends StatefulWidget {
  final int count;
  final ValueChanged<int> onChanged;
  const _TravelerDialog({required this.count, required this.onChanged});
  @override
  State<_TravelerDialog> createState() => _TravelerDialogState();
}

class _TravelerDialogState extends State<_TravelerDialog> {
  late int _count;
  @override
  void initState() {
    super.initState();
    _count = widget.count;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Travelers'),
          content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                    onPressed:
                        _count > 1 ? () => setState(() => _count--) : null,
                    icon: const Icon(Icons.remove_rounded)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('$_count',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w900))),
                IconButton.filledTonal(
                    onPressed: () => setState(() => _count++),
                    icon: const Icon(Icons.add_rounded)),
              ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () {
                  widget.onChanged(_count);
                  Navigator.pop(context);
                },
                child: const Text('Confirm')),
          ]);
}
