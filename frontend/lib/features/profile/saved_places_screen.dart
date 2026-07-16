import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../core/mock/mock_data.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../places/place_detail_screen.dart';

class SavedPlacesScreen extends StatefulWidget {
  final bool loading;

  const SavedPlacesScreen({super.key, this.loading = false});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final search = TextEditingController();
  final savedIds = <int>{1, 2, 3, 5};
  String selectedCategory = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.savedPlacesTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: widget.loading
              ? const Center(
                  child: SizedBox(width: 420, child: OceanLoadingState()),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    OceanContentConstraint(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OceanSearchField(
                            controller: search,
                            hintText: l10n.savedPlacesSearchHint,
                            onChanged: (_) => setState(() {}),
                            onClear: () => setState(search.clear),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (app.demoMode) _filters(context, _savedPlaces),
                          const SizedBox(height: AppSpacing.md),
                          if (!app.demoMode)
                            OceanEmptyState(
                              title: l10n.savedPlacesRealEmptyTitle,
                              message: l10n.savedPlacesRealEmptyMessage,
                            )
                          else if (_filteredPlaces.isEmpty)
                            OceanEmptyState(
                              title: l10n.savedPlacesDemoEmptyTitle,
                              message: l10n.savedPlacesDemoEmptyMessage,
                            )
                          else ...[
                            Text(
                              l10n.savedPlacesCount(_filteredPlaces.length),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ..._filteredPlaces.map(
                              (place) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: _SavedPlaceCard(
                                  place: place,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PlaceDetailScreen(place: place),
                                    ),
                                  ),
                                  onBookmark: () {
                                    setState(() => savedIds.remove(place.id));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.savedPlacesRemoved),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  List<Place> get _savedPlaces =>
      MockData.places.where((place) => savedIds.contains(place.id)).toList();

  List<Place> get _filteredPlaces {
    final keyword = search.text.trim().toLowerCase();
    return _savedPlaces.where((place) {
      final categoryMatch =
          selectedCategory.isEmpty || place.category == selectedCategory;
      final keywordMatch = keyword.isEmpty ||
          place.name.toLowerCase().contains(keyword) ||
          place.city.toLowerCase().contains(keyword) ||
          place.tags.any((tag) => tag.toLowerCase().contains(keyword));
      return categoryMatch && keywordMatch;
    }).toList();
  }

  Widget _filters(BuildContext context, List<Place> places) {
    final l10n = AppLocalizations.of(context)!;
    final categories = places.map((place) => place.category).toSet().toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(l10n.savedPlacesAllFilter),
              selected: selectedCategory.isEmpty,
              onSelected: (_) => setState(() => selectedCategory = ''),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(category),
                selected: selectedCategory == category,
                onSelected: (_) => setState(() => selectedCategory = category),
              ),
            ),
        ],
      ),
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _SavedPlaceCard({
    required this.place,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Image.network(
              place.imageUrl,
              width: 112,
              height: 112,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 112,
                height: 112,
                color: AppColors.paleCyan,
                child: const Icon(Icons.place_rounded,
                    color: AppColors.ocean, size: AppIconSizes.lg),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OceanStatusPill(
                  label: place.category,
                  icon: Icons.place_outlined,
                  color: AppColors.ocean,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  place.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.warning, size: AppIconSizes.xs),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: l10n.savedPlacesBookmarkSemantic(place.name),
            child: IconButton(
              tooltip: l10n.savedPlacesBookmarkSemantic(place.name),
              onPressed: onBookmark,
              icon: const Icon(Icons.bookmark_rounded, color: AppColors.ocean),
            ),
          ),
        ],
      ),
    );
  }
}
