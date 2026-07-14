import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/travel_cards.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          Row(children: [
            Expanded(
                child: Text('My trips',
                    style: Theme.of(context).textTheme.headlineMedium)),
            IconButton.filled(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateTripScreen())),
                icon: const Icon(Icons.add_rounded))
          ]),
          const SizedBox(height: 12),
          if (app.trips.isEmpty)
            GlassCard(
                child: Column(children: [
              const Icon(Icons.map_rounded, size: 48, color: AppColors.slate),
              const SizedBox(height: 12),
              const Text('No trips yet',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 4),
              const Text('Create your first trip to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate)),
              const SizedBox(height: 16),
              GlassButton(
                  text: 'Create a trip',
                  icon: Icons.add_rounded,
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateTripScreen()))),
            ])),
          ...app.trips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Stack(children: [
                TripCard(
                    trip: t,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TripDetailScreen(trip: t)))),
                Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                        color: Colors.transparent,
                        child: PopupMenuButton<String>(
                            icon: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black45,
                                child: Icon(Icons.more_vert_rounded,
                                    color: Colors.white, size: 18)),
                            onSelected: (v) {
                              if (v == 'delete') {
                                _confirmDelete(context, app, t.id, t.title);
                              }
                            },
                            itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        Icon(Icons.delete_outline_rounded,
                                            color: AppColors.coral, size: 18),
                                        SizedBox(width: 8),
                                        Text('Delete trip',
                                            style: TextStyle(
                                                color: AppColors.coral))
                                      ])),
                                ])))
              ]))),
        ]);
  }

  void _confirmDelete(
      BuildContext ctx, AppState app, int tripId, String title) {
    final nav = Navigator.of(ctx);
    final messenger = ScaffoldMessenger.of(ctx);
    showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: const Text('Delete trip?'),
                content: Text(
                    'Delete "$title"? This will also remove all timeline items and expenses.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.coral),
                      onPressed: () {
                        app.deleteTrip(tripId);
                        nav.pop();
                        messenger.showSnackBar(
                            const SnackBar(content: Text('Trip deleted.')));
                      },
                      child: const Text('Delete')),
                ]));
  }
}
