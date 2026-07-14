import 'package:flutter/material.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/add_to_trip_sheet.dart';
import '../../shared/widgets/glass_widgets.dart';

class PlaceDetailScreen extends StatelessWidget {
  final Place place;
  const PlaceDetailScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(place.name)),
      body: BubbleBackground(
          child: SafeArea(
              child: ListView(padding: const EdgeInsets.all(20), children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.network(place.imageUrl,
                height: 320,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    height: 320,
                    color: AppColors.ocean.withValues(alpha: .18)))),
        const SizedBox(height: 18),
        GlassCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(place.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
              '${place.locationName} · ${place.category} · ${place.priceLevel}',
              style: const TextStyle(
                  color: AppColors.ocean, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
            Text('  ${place.rating}',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('  (${place.reviewCount} reviews)',
                style: const TextStyle(color: AppColors.slate)),
          ]),
          const SizedBox(height: 8),
          if (place.estimatedDurationMinutes > 0)
            _infoRow(Icons.schedule_rounded,
                _formatDuration(place.estimatedDurationMinutes)),
          if (place.openingHours != null)
            _infoRow(Icons.access_time_rounded, place.openingHours!),
          if (place.address.isNotEmpty)
            _infoRow(Icons.place_rounded, place.address),
          const SizedBox(height: 14),
          Text(place.description, style: Theme.of(context).textTheme.bodyLarge),
          if (place.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
                spacing: 6,
                runSpacing: 6,
                children: place.tags
                    .map((t) => Chip(
                        label: Text('#$t',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.ocean)),
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.ocean.withValues(alpha: .08),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact))
                    .toList()),
          ],
          const SizedBox(height: 18),
          GlassButton(
              text: 'Add to trip',
              icon: Icons.add_location_alt_rounded,
              onPressed: () => showAddToTripSheet(context, place)),
        ]))
      ]))));

  Widget _infoRow(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.slate),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: AppColors.slate))),
      ]));

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}
