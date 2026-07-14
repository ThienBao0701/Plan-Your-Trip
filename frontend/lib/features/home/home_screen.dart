import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/add_to_trip_sheet.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/travel_cards.dart';
import '../places/place_detail_screen.dart';
import '../places/places_screen.dart';
import '../trips/create_trip_screen.dart';
import '../trips/trip_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;
  int _travelers = 2;
  DateTimeRange? _dateRange;
  final _destCtrl = TextEditingController();

  @override
  void dispose() {
    _destCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final featured = app.filteredPlaces(PlaceQuery(
      category: _selectedCategory,
      isFeatured: true,
    ));
    final nearby = app.filteredPlaces(const PlaceQuery(isNearby: true));

    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          Text('Where will you\nwander?',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 14),
          GlassSearchBar(
              hint: 'Search Da Lat, Vung Tau, cafes, hotels...',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PlacesScreen()))),
          const SizedBox(height: 16),
          _TripBuilderCard(
            travelers: _travelers,
            dateRange: _dateRange,
            destController: _destCtrl,
            onPickDates: _pickDates,
            onPickTravelers: _pickTravelers,
            onBuild: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CreateTripScreen(
                          prefilledDestination: _destCtrl.text.trim(),
                          prefilledTravelers: _travelers,
                          prefilledDateRange: _dateRange,
                        ))),
          ),
          const SizedBox(height: 20),
          _section(context, 'Explore by category'),
          _categoryChips(app),
          const SizedBox(height: 20),
          _section(context, 'Featured places'),
          if (featured.isEmpty)
            const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: PremiumEmptyState('No places in this category yet.')),
          if (featured.isNotEmpty)
            SizedBox(
                height: 310,
                child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: featured.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (ctx, i) => SizedBox(
                        width: 280,
                        child: PlaceCard(
                            place: featured[i],
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        PlaceDetailScreen(place: featured[i]))),
                            onAdd: () =>
                                showAddToTripSheet(context, featured[i]))))),
          const SizedBox(height: 24),
          _section(context, 'Popular trips'),
          if (app.trips.isEmpty)
            Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlassCard(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateTripScreen())),
                    child: const Row(children: [
                      Icon(Icons.add_circle_outline_rounded,
                          color: AppColors.ocean),
                      SizedBox(width: 12),
                      Text('Create your first trip',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ocean))
                    ]))),
          ...app.trips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TripCard(
                  trip: t,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TripDetailScreen(trip: t)))))),
          const SizedBox(height: 24),
          if (nearby.isNotEmpty) ...[
            _section(context, 'Nearby recommendations'),
            ...nearby.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: PlaceCard(
                    place: p,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PlaceDetailScreen(place: p))),
                    onAdd: () => showAddToTripSheet(context, p)))),
          ],
        ]);
  }

  Widget _section(BuildContext c, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(t, style: Theme.of(c).textTheme.titleLarge));

  Widget _categoryChips(AppState app) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _chip('All', Icons.apps_rounded, null),
          ...app.categories.take(8).map((c) => _chip(c.name, c.icon, c.id)),
        ]),
      );

  Widget _chip(String name, IconData icon, String? categoryId) {
    final selected = _selectedCategory == categoryId;
    return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  size: 16, color: selected ? Colors.white : AppColors.slate),
              const SizedBox(width: 4),
              Text(name),
            ]),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = categoryId),
            selectedColor: AppColors.ocean,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w600)));
  }
}

// ── Trip builder quick-access card ──────────────────────────────────────────

class _TripBuilderCard extends StatelessWidget {
  final int travelers;
  final DateTimeRange? dateRange;
  final TextEditingController destController;
  final VoidCallback onPickDates;
  final VoidCallback onPickTravelers;
  final VoidCallback onBuild;

  const _TripBuilderCard({
    required this.travelers,
    required this.dateRange,
    required this.destController,
    required this.onPickDates,
    required this.onPickTravelers,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');
    final dateLabel = dateRange == null
        ? 'Pick dates'
        : '${fmt.format(dateRange!.start)} – ${fmt.format(dateRange!.end)}';

    return GlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Plan your trip',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
      const SizedBox(height: 14),
      TextField(
          controller: destController,
          decoration: const InputDecoration(
              hintText: 'Where to?',
              prefixIcon: Icon(Icons.place_rounded),
              filled: true,
              fillColor: Color(0x12000000))),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: _PlanPill(Icons.calendar_month_rounded, dateLabel,
                onTap: onPickDates)),
        const SizedBox(width: 10),
        _PlanPill(Icons.people_rounded, '$travelers travelers',
            onTap: onPickTravelers),
      ]),
      const SizedBox(height: 14),
      GlassButton(
          text: 'Create smart itinerary',
          icon: Icons.auto_awesome_rounded,
          onPressed: onBuild),
    ]));
  }
}

class _PlanPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _PlanPill(this.icon, this.text, {required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: AppColors.ocean.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppColors.ocean.withValues(alpha: .18))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: AppColors.ocean),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.ink))
          ])));
}

// ── Traveler count dialog ────────────────────────────────────────────────────

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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
