import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../expenses/expenses_screen.dart';
import '../timeline/timeline_screen.dart';
import 'edit_trip_screen.dart';

final _money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
final _date = DateFormat('dd/MM/yyyy');

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});
  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final spent = app.totalForTrip(_trip.id);
    final remaining = _trip.budget - spent;

    return Scaffold(
        appBar: AppBar(title: Text(_trip.destination), actions: [
          IconButton(
              onPressed: () async {
                final updated = await Navigator.push<Trip>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditTripScreen(trip: _trip)));
                if (updated != null && mounted) {
                  setState(() => _trip = updated);
                }
              },
              icon: const Icon(Icons.edit_rounded)),
        ]),
        body: BubbleBackground(
            child: SafeArea(
                child: ListView(padding: const EdgeInsets.all(20), children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.network(_trip.imageUrl,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      height: 260,
                      color: AppColors.violet.withValues(alpha: .25)))),
          const SizedBox(height: 18),
          GlassCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_trip.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                _infoRow(Icons.place_rounded, _trip.destination),
                _infoRow(Icons.calendar_month_rounded,
                    '${_date.format(_trip.startDate)} → ${_date.format(_trip.endDate)}'),
                _infoRow(Icons.schedule_rounded, '${_trip.days} days'),
                _infoRow(Icons.people_rounded,
                    '${_trip.travelers} traveler${_trip.travelers == 1 ? '' : 's'}'),
                if (_trip.notes.isNotEmpty) ...[
                  const Divider(height: 20),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.notes_rounded,
                        size: 16, color: AppColors.slate),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(_trip.notes,
                            style: const TextStyle(color: AppColors.slate))),
                  ]),
                ],
              ])),
          const SizedBox(height: 12),
          // Budget summary
          GlassCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Budget',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                Row(children: [
                  _budgetChip('Total budget', _money.format(_trip.budget),
                      AppColors.ocean),
                  const SizedBox(width: 10),
                  _budgetChip('Spent', _money.format(spent), AppColors.coral),
                  const SizedBox(width: 10),
                  _budgetChip(
                      'Left',
                      _money.format(remaining.clamp(0, double.infinity)),
                      remaining >= 0 ? AppColors.mint : AppColors.coral),
                ]),
              ])),
          const SizedBox(height: 16),
          GlassButton(
              text: 'Open Trip Planner Timeline',
              icon: Icons.timeline_rounded,
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TimelineScreen(trip: _trip)))),
          const SizedBox(height: 12),
          GlassButton(
              text: 'View Expenses',
              icon: Icons.receipt_long_rounded,
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ExpensesScreen(filterTripId: _trip.id)))),
        ]))));
  }

  Widget _infoRow(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.slate),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppColors.ink)),
      ]));

  Widget _budgetChip(String label, String value, Color color) => Expanded(
          child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withValues(alpha: .08)),
        child: Column(children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.slate)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: color, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      ));
}
