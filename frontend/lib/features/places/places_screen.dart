import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/add_to_trip_sheet.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'place_detail_screen.dart';

enum ExploreMode { list, map }

enum ExploreSort { relevance, rating, duration }

class PlacesScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;

  const PlacesScreen({super.key, this.initialQuery, this.initialCategory});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  late final TextEditingController search;
  String? selectedCategory;
  final selectedTags = <String>{};
  ExploreMode mode = ExploreMode.list;
  ExploreSort sort = ExploreSort.relevance;

  @override
  void initState() {
    super.initState();
    search = TextEditingController(text: widget.initialQuery ?? '');
    selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final results = _sorted(
      app.filteredPlaces(
        PlaceQuery(
          keyword: search.text.trim().isEmpty ? null : search.text.trim(),
          category: selectedCategory,
          tags: selectedTags.toList(),
        ),
      ),
    );
    final allTags = app.places.expand((place) => place.tags).toSet().toList()
      ..sort();

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.searchTitle),
        actions: [
          Semantics(
            button: true,
            label: l10n.exploreFiltersSemantic,
            child: IconButton(
              tooltip: l10n.exploreFiltersSemantic,
              onPressed: () => _showFilters(context, allTags),
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SearchBar(
                      controller: search,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => setState(() {}),
                      onClear: () => setState(search.clear),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ModeSwitch(
                      mode: mode,
                      onChanged: (value) => setState(() => mode = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CategoryChips(
                      categories: app.categories,
                      selected: selectedCategory,
                      onSelected: (category) =>
                          setState(() => selectedCategory = category),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.searchResultCount(results.length),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            onPressed: _hasFilters ? _clearFilters : null,
                            icon: const Icon(Icons.filter_list_off_rounded),
                            label: Text(l10n.searchClearFilters),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (results.isEmpty)
                      OceanEmptyState(
                        title: l10n.searchEmptyTitle,
                        message: l10n.searchEmptyMessage,
                        actionLabel: l10n.searchClearFilters,
                        onAction: _clearFilters,
                      )
                    else if (mode == ExploreMode.list)
                      _ResultList(
                        results: results,
                        onPlace: _openPlace,
                        onAdd: (place) => showAddToTripSheet(context, place),
                        onBookmark: (place) => _bookmark(place),
                      )
                    else
                      _MapFallback(
                        results: results,
                        onListMode: () =>
                            setState(() => mode = ExploreMode.list),
                        onPlace: _openPlace,
                        onBookmark: _bookmark,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasFilters =>
      search.text.trim().isNotEmpty ||
      selectedCategory != null ||
      selectedTags.isNotEmpty ||
      sort != ExploreSort.relevance;

  void _clearFilters() {
    setState(() {
      search.clear();
      selectedCategory = null;
      selectedTags.clear();
      sort = ExploreSort.relevance;
    });
  }

  List<Place> _sorted(List<Place> places) {
    final copy = [...places];
    switch (sort) {
      case ExploreSort.relevance:
        return copy;
      case ExploreSort.rating:
        copy.sort((a, b) => b.rating.compareTo(a.rating));
        return copy;
      case ExploreSort.duration:
        copy.sort((a, b) =>
            a.estimatedDurationMinutes.compareTo(b.estimatedDurationMinutes));
        return copy;
    }
  }

  void _openPlace(Place place) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
    );
  }

  void _bookmark(Place place) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          app.demoMode
              ? l10n.savedPlacesDemoLocalOnly
              : l10n.savedPlacesRealEmptyMessage,
        ),
      ),
    );
  }

  Future<void> _showFilters(BuildContext context, List<String> allTags) {
    final l10n = AppLocalizations.of(context)!;
    var draftSort = sort;
    final draftTags = {...selectedTags};
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => OceanGlassBottomSheet(
        child: StatefulBuilder(
          builder: (context, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.searchFiltersTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.searchSortTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.searchSortRelevance),
                      selected: draftSort == ExploreSort.relevance,
                      onSelected: (_) => setSheetState(
                          () => draftSort = ExploreSort.relevance),
                    ),
                    ChoiceChip(
                      label: Text(l10n.searchSortRating),
                      selected: draftSort == ExploreSort.rating,
                      onSelected: (_) =>
                          setSheetState(() => draftSort = ExploreSort.rating),
                    ),
                    ChoiceChip(
                      label: Text(l10n.searchSortDuration),
                      selected: draftSort == ExploreSort.duration,
                      onSelected: (_) =>
                          setSheetState(() => draftSort = ExploreSort.duration),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.searchTagsTitle,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in allTags)
                      FilterChip(
                        label: Text(tag),
                        selected: draftTags.contains(tag),
                        onSelected: (selected) {
                          setSheetState(() {
                            selected
                                ? draftTags.add(tag)
                                : draftTags.remove(tag);
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                OceanPrimaryButton(
                  label: l10n.searchApplyFilters,
                  icon: Icons.check_rounded,
                  onPressed: () {
                    setState(() {
                      sort = draftSort;
                      selectedTags
                        ..clear()
                        ..addAll(draftTags);
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      key: const Key('explore-search-field'),
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : Semantics(
                button: true,
                label: l10n.searchClearSemantic,
                child: IconButton(
                  tooltip: l10n.searchClearSemantic,
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_rounded),
                ),
              ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final ExploreMode mode;
  final ValueChanged<ExploreMode> onChanged;

  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      label: l10n.searchModeSemantic,
      child: SegmentedButton<ExploreMode>(
        segments: [
          ButtonSegment(
            value: ExploreMode.list,
            icon: const Icon(Icons.view_list_rounded),
            label: Text(l10n.searchListMode),
          ),
          ButtonSegment(
            value: ExploreMode.map,
            icon: const Icon(Icons.map_outlined),
            label: Text(l10n.searchMapMode),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(l10n.savedPlacesAllFilter),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                avatar: Icon(category.icon, size: AppIconSizes.xs),
                label: Text(category.name),
                selected: selected == category.id,
                onSelected: (_) => onSelected(category.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  final List<Place> results;
  final ValueChanged<Place> onPlace;
  final ValueChanged<Place> onAdd;
  final ValueChanged<Place> onBookmark;

  const _ResultList({
    required this.results,
    required this.onPlace,
    required this.onAdd,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final place in results)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SearchResultCard(
                place: place,
                onTap: () => onPlace(place),
                onAdd: () => onAdd(place),
                onBookmark: () => onBookmark(place),
              ),
            ),
        ],
      );
}

class _SearchResultCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onBookmark;

  const _SearchResultCard({
    required this.place,
    required this.onTap,
    required this.onAdd,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget addButton() => Semantics(
          button: true,
          label: l10n.placeAddToTripSemantic(place.name),
          child: IconButton.filled(
            tooltip: l10n.placeAddToTripSemantic(place.name),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
          ),
        );

    Widget details({required bool includeAddButton}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.savedPlacesBookmarkSemantic(place.name),
                  child: IconButton(
                    tooltip: l10n.savedPlacesBookmarkSemantic(place.name),
                    onPressed: onBookmark,
                    icon: const Icon(Icons.bookmark_border_rounded),
                  ),
                ),
              ],
            ),
            Text(
              '${place.locationName} · ${place.city}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (place.rating > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xxs,
                runSpacing: AppSpacing.xxs,
                children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.ocean, size: AppIconSizes.xs),
                  Text(
                    place.rating.toStringAsFixed(1),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.ocean),
                  ),
                  if (place.reviewCount > 0)
                    Text(
                      l10n.placeReviewCount(place.reviewCount),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            OceanStatusPill(
              label: place.category,
              icon: Icons.place_outlined,
            ),
            if (includeAddButton) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: addButton(),
              ),
            ],
          ],
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 360;
        final imageSize =
            constraints.maxWidth < 180 ? constraints.maxWidth : 180.0;
        return OceanGlassCard(
          onTap: onTap,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _PlaceImage(place: place, size: imageSize)),
                    const SizedBox(height: AppSpacing.md),
                    details(includeAddButton: true),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PlaceImage(place: place, size: 132),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: details(includeAddButton: false)),
                    addButton(),
                  ],
                ),
        );
      },
    );
  }
}

class _MapFallback extends StatelessWidget {
  final List<Place> results;
  final VoidCallback onListMode;
  final ValueChanged<Place> onPlace;
  final ValueChanged<Place> onBookmark;

  const _MapFallback({
    required this.results,
    required this.onListMode,
    required this.onPlace,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = results.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          semanticLabel: l10n.mapFallbackSemantic,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.mapUnavailableTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.mapUnavailableMessage,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              AspectRatio(
                aspectRatio: 1.35,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.paleCyan,
                    borderRadius: BorderRadius.circular(AppRadii.xxl),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _SchematicMapPainter()),
                      ),
                      for (var i = 0; i < preview.length; i++)
                        _MapPin(
                          place: preview[i],
                          index: i,
                          onTap: () => onPlace(preview[i]),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OceanSecondaryButton(
                label: l10n.searchBackToList,
                icon: Icons.view_list_rounded,
                onPressed: onListMode,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SearchResultCard(
          place: results.first,
          onTap: () => onPlace(results.first),
          onAdd: () => showAddToTripSheet(context, results.first),
          onBookmark: () => onBookmark(results.first),
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  final Place place;
  final int index;
  final VoidCallback onTap;

  const _MapPin({
    required this.place,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const offsets = [
      Alignment(-.65, -.35),
      Alignment(.10, -.10),
      Alignment(.62, -.45),
      Alignment(-.34, .32),
      Alignment(.45, .42),
      Alignment(-.05, .70),
    ];
    return Align(
      alignment: offsets[index % offsets.length],
      child: Semantics(
        button: true,
        label: place.name,
        child: IconButton.filled(
          onPressed: onTap,
          icon: Icon(_iconForCategory(place.category)),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Food':
      case 'Restaurants':
      case 'Cafe':
        return Icons.restaurant_rounded;
      case 'Hotels':
        return Icons.hotel_rounded;
      case 'Nature':
        return Icons.terrain_rounded;
      case 'Culture':
        return Icons.museum_rounded;
      default:
        return Icons.place_rounded;
    }
  }
}

class _SchematicMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final water = Paint()..color = AppColors.aqua.withValues(alpha: .14);
    final land = Paint()..color = AppColors.mint.withValues(alpha: .12);
    final road = Paint()
      ..color = AppColors.ocean.withValues(alpha: .18)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawOval(
      Rect.fromLTWH(size.width * .52, -20, size.width * .55, size.height * .8),
      water,
    );
    canvas.drawOval(
      Rect.fromLTWH(-30, size.height * .08, size.width * .7, size.height * .85),
      land,
    );
    final path = Path()
      ..moveTo(size.width * .08, size.height * .74)
      ..cubicTo(size.width * .35, size.height * .46, size.width * .50,
          size.height * .55, size.width * .88, size.height * .22);
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlaceImage extends StatelessWidget {
  final Place place;
  final double size;

  const _PlaceImage({required this.place, required this.size});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Image.network(
          place.imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: AppColors.paleCyan,
            alignment: Alignment.center,
            child: const Icon(
              Icons.place_rounded,
              color: AppColors.ocean,
              size: AppIconSizes.lg,
            ),
          ),
        ),
      );
}
