import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../shared/widgets/add_to_trip_sheet.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../shared/widgets/travel_cards.dart';
import 'place_detail_screen.dart';

class PlacesScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  const PlacesScreen({super.key, this.initialQuery, this.initialCategory});
  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  late final TextEditingController _searchCtrl;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery ?? '');
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final query = PlaceQuery(
      keyword: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      category: _selectedCategory,
    );
    final results = app.filteredPlaces(query);

    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          Text('Explore places',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search hotels, food, cafes, attractions...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        })
                    : null,
              )),
          const SizedBox(height: 12),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip(context, 'All', null),
                ...app.categories.map((c) => _chip(context, c.name, c.id)),
              ])),
          const SizedBox(height: 18),
          if (results.isEmpty)
            const PremiumEmptyState(
                'No places found. Try a different search or category.'),
          ...results.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PlaceCard(
                  place: p,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PlaceDetailScreen(place: p))),
                  onAdd: () => showAddToTripSheet(context, p)))),
        ]);
  }

  Widget _chip(BuildContext context, String name, String? categoryId) {
    final selected = _selectedCategory == categoryId;
    return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
            label: Text(name),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = categoryId)));
  }
}
