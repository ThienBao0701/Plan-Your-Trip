import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';

class CreateTripScreen extends StatefulWidget {
  final String? prefilledDestination;
  final int? prefilledTravelers;
  final DateTimeRange? prefilledDateRange;
  const CreateTripScreen(
      {super.key,
      this.prefilledDestination,
      this.prefilledTravelers,
      this.prefilledDateRange});
  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _destCtrl;
  late final TextEditingController _budgetCtrl;
  final TextEditingController _notesCtrl = TextEditingController();
  late int _travelers;
  DateTimeRange? _dateRange;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _destCtrl = TextEditingController(text: widget.prefilledDestination ?? '');
    _titleCtrl = TextEditingController(
        text: widget.prefilledDestination?.isNotEmpty == true
            ? '${widget.prefilledDestination} trip'
            : '');
    _travelers = widget.prefilledTravelers ?? 2;
    _dateRange = widget.prefilledDateRange;
    _budgetCtrl = TextEditingController();
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
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
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
    if (_dateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick travel dates.')));
      return;
    }
    setState(() => _saving = true);
    final app = AppScope.of(context);
    final budget = double.tryParse(
            _budgetCtrl.text.replaceAll(',', '').replaceAll('.', '')) ??
        0;
    final trip = Trip(
      id: app.newId,
      title: _titleCtrl.text.trim().isEmpty
          ? '$dest trip'
          : _titleCtrl.text.trim(),
      destination: dest,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=900&q=80',
      startDate: _dateRange!.start,
      endDate: _dateRange!.end,
      travelers: _travelers,
      budget: budget,
      notes: _notesCtrl.text.trim(),
    );
    app.addTrip(trip);
    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      setState(() => _saving = false);
      nav.pop();
      messenger.showSnackBar(
          SnackBar(content: Text('${trip.title} created successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final dateLabel = _dateRange == null
        ? 'Pick travel dates'
        : '${fmt.format(_dateRange!.start)} → ${fmt.format(_dateRange!.end)}';

    return Scaffold(
        appBar: AppBar(title: const Text('New trip')),
        body: BubbleBackground(
            child: SafeArea(
                child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Plan your next adventure',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          GlassCard(
              child: Column(children: [
            GlassTextField(
                controller: _destCtrl,
                hint: 'Destination (city or region)',
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
                hint: 'Notes (optional)',
                icon: Icons.notes_rounded),
            const SizedBox(height: 20),
            _saving
                ? const PremiumLoading()
                : GlassButton(
                    text: 'Create trip',
                    icon: Icons.check_rounded,
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
