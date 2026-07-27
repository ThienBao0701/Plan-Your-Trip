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
import '../../shared/widgets/bookmark_button.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../places/place_detail_screen.dart';
import '../places/places_screen.dart';

enum CategoryDiscoveryMode { foodCafe, thingsToDo, transportation }

enum PlaceCategoryRoot { food, cafe, attraction, entertainment, transportation }

extension PlaceCategoryRootData on PlaceCategoryRoot {
  String get slug {
    switch (this) {
      case PlaceCategoryRoot.food:
        return 'food';
      case PlaceCategoryRoot.cafe:
        return 'cafe';
      case PlaceCategoryRoot.attraction:
        return 'attraction';
      case PlaceCategoryRoot.entertainment:
        return 'entertainment';
      case PlaceCategoryRoot.transportation:
        return 'transportation';
    }
  }

  String get backendType {
    switch (this) {
      case PlaceCategoryRoot.food:
        return 'FOOD';
      case PlaceCategoryRoot.cafe:
        return 'CAFE';
      case PlaceCategoryRoot.attraction:
        return 'ATTRACTION';
      case PlaceCategoryRoot.entertainment:
        return 'ENTERTAINMENT';
      case PlaceCategoryRoot.transportation:
        return 'TRANSPORTATION';
    }
  }

  IconData get icon {
    switch (this) {
      case PlaceCategoryRoot.food:
        return Icons.restaurant_rounded;
      case PlaceCategoryRoot.cafe:
        return Icons.coffee_rounded;
      case PlaceCategoryRoot.attraction:
        return Icons.attractions_rounded;
      case PlaceCategoryRoot.entertainment:
        return Icons.local_activity_rounded;
      case PlaceCategoryRoot.transportation:
        return Icons.directions_bus_rounded;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case PlaceCategoryRoot.food:
        return l10n.categoryRootFood;
      case PlaceCategoryRoot.cafe:
        return l10n.categoryRootCafe;
      case PlaceCategoryRoot.attraction:
        return l10n.categoryRootAttraction;
      case PlaceCategoryRoot.entertainment:
        return l10n.categoryRootEntertainment;
      case PlaceCategoryRoot.transportation:
        return l10n.categoryRootTransportation;
    }
  }
}

class CategoryDiscoveryTaxonomy {
  const CategoryDiscoveryTaxonomy._();

  static List<PlaceCategoryRoot> rootsFor(CategoryDiscoveryMode mode) {
    switch (mode) {
      case CategoryDiscoveryMode.foodCafe:
        return const [PlaceCategoryRoot.food, PlaceCategoryRoot.cafe];
      case CategoryDiscoveryMode.thingsToDo:
        return const [
          PlaceCategoryRoot.attraction,
          PlaceCategoryRoot.entertainment,
        ];
      case CategoryDiscoveryMode.transportation:
        return const [PlaceCategoryRoot.transportation];
    }
  }

  static CategoryDiscoveryMode? modeForCategory(Category category) {
    switch (category.slug) {
      case 'food':
      case 'cafe':
        return CategoryDiscoveryMode.foodCafe;
      case 'attraction':
      case 'photo-spot':
      case 'tour':
      case 'entertainment':
        return CategoryDiscoveryMode.thingsToDo;
      case 'transportation':
        return CategoryDiscoveryMode.transportation;
      default:
        return null;
    }
  }

  static PlaceCategoryRoot? rootForCategory(Category category) {
    for (final root in PlaceCategoryRoot.values) {
      if (root.slug == category.slug) return root;
    }
    if (category.slug == 'photo-spot' || category.slug == 'tour') {
      return PlaceCategoryRoot.attraction;
    }
    return null;
  }

  static bool matchesRoot(Place place, PlaceCategoryRoot root) {
    final slug = place.effectiveCategorySlug.toLowerCase();
    final label = place.category.toLowerCase();
    switch (root) {
      case PlaceCategoryRoot.food:
        return slug == 'food' || label == 'restaurants' || label == 'food';
      case PlaceCategoryRoot.cafe:
        return slug == 'cafe' || label == 'cafe' || label == 'cafes';
      case PlaceCategoryRoot.attraction:
        return slug == 'attraction' ||
            slug == 'photo-spot' ||
            slug == 'tour' ||
            label == 'attractions' ||
            label == 'photo spots' ||
            label == 'culture' ||
            label == 'nature';
      case PlaceCategoryRoot.entertainment:
        return slug == 'entertainment' ||
            label == 'entertainment' ||
            label == 'nightlife';
      case PlaceCategoryRoot.transportation:
        return slug == 'transportation' ||
            label == 'transportation' ||
            label == 'transport';
    }
  }
}

class CategoryDiscoveryScreen extends StatefulWidget {
  final CategoryDiscoveryMode mode;
  final PlaceCategoryRoot? initialRoot;
  final String? initialQuery;

  const CategoryDiscoveryScreen({
    super.key,
    required this.mode,
    this.initialRoot,
    this.initialQuery,
  });

  @override
  State<CategoryDiscoveryScreen> createState() =>
      _CategoryDiscoveryScreenState();
}

class _CategoryDiscoveryScreenState extends State<CategoryDiscoveryScreen> {
  late final TextEditingController _search;
  PlaceCategoryRoot? _selectedRoot;
  ExploreMode _mode = ExploreMode.list;
  double? _minRating;
  String? _priceLevel;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery ?? '');
    _selectedRoot = widget.initialRoot;
  }

  @override
  void didUpdateWidget(covariant CategoryDiscoveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.initialRoot != widget.initialRoot) {
      _selectedRoot = widget.initialRoot;
    }
    if (oldWidget.initialQuery != widget.initialQuery) {
      _search.text = widget.initialQuery ?? '';
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final roots = CategoryDiscoveryTaxonomy.rootsFor(widget.mode);
    final results = _results(app, roots);
    final heroPlace = results.isNotEmpty ? results.first : _heroFallback(app);

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(_title(l10n)),
        actions: [
          Semantics(
            button: true,
            label: l10n.categoryFiltersSemantic,
            child: IconButton(
              tooltip: l10n.categoryFiltersSemantic,
              onPressed: () => _showFilters(context),
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
                    _CategoryHero(
                      title: _title(l10n),
                      subtitle: _subtitle(l10n),
                      place: heroPlace,
                      fallbackIcon: _modeIcon,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OceanSearchField(
                      key: const Key('category-search-field'),
                      controller: _search,
                      hintText: _searchHint(l10n),
                      semanticLabel: l10n.searchFieldSemanticLabel,
                      onChanged: (_) => setState(() {}),
                      onClear: () => setState(_search.clear),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ModeSwitch(
                      mode: _mode,
                      onChanged: (mode) => setState(() => _mode = mode),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _RootChips(
                      roots: roots,
                      selected: _selectedRoot,
                      onSelected: (root) =>
                          setState(() => _selectedRoot = root),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OceanGlassSurface(
                      blur: 0,
                      color: AppColors.paleCyan,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.mode ==
                              CategoryDiscoveryMode.transportation) ...[
                            Text(
                              l10n.categoryTransportUnavailableTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                          ],
                          Text(
                            widget.mode == CategoryDiscoveryMode.transportation
                                ? l10n.categoryTransportUnavailableMessage
                                : l10n.categoryLocalPreviewMessage,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.searchResultCount(results.length),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _hasFilters ? _clearFilters : null,
                          icon: const Icon(Icons.filter_list_off_rounded),
                          label: Text(l10n.searchClearFilters),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (results.isEmpty)
                      OceanEmptyState(
                        title: l10n.categoryEmptyTitle,
                        message: l10n.categoryEmptyMessage,
                        actionLabel: l10n.searchClearFilters,
                        onAction: _clearFilters,
                      )
                    else if (_mode == ExploreMode.map)
                      _CategoryMapFallback(
                        mode: widget.mode,
                        results: results,
                        onListMode: () =>
                            setState(() => _mode = ExploreMode.list),
                        onPlace: _openPlace,
                        onAdd: _addToTrip,
                      )
                    else
                      _CategoryResultList(
                        results: results,
                        onPlace: _openPlace,
                        onAdd: _addToTrip,
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

  IconData get _modeIcon {
    switch (widget.mode) {
      case CategoryDiscoveryMode.foodCafe:
        return Icons.restaurant_rounded;
      case CategoryDiscoveryMode.thingsToDo:
        return Icons.attractions_rounded;
      case CategoryDiscoveryMode.transportation:
        return Icons.directions_bus_rounded;
    }
  }

  bool get _hasFilters =>
      _search.text.trim().isNotEmpty ||
      _selectedRoot != null ||
      _minRating != null ||
      _priceLevel != null ||
      _mode != ExploreMode.list;

  void _clearFilters() {
    setState(() {
      _search.clear();
      _selectedRoot = null;
      _minRating = null;
      _priceLevel = null;
      _mode = ExploreMode.list;
    });
  }

  List<Place> _results(AppState app, List<PlaceCategoryRoot> roots) {
    final activeRoots = _selectedRoot == null ? roots : [_selectedRoot!];
    var places = app.places
        .where((place) => activeRoots.any(
              (root) => CategoryDiscoveryTaxonomy.matchesRoot(place, root),
            ))
        .toList();
    final keyword = _search.text.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      places = places
          .where((place) =>
              place.name.toLowerCase().contains(keyword) ||
              place.description.toLowerCase().contains(keyword) ||
              place.locationName.toLowerCase().contains(keyword) ||
              place.city.toLowerCase().contains(keyword) ||
              place.tags.any((tag) => tag.toLowerCase().contains(keyword)))
          .toList();
    }
    if (_minRating != null) {
      places = places.where((place) => place.rating >= _minRating!).toList();
    }
    if (_priceLevel != null) {
      places =
          places.where((place) => place.priceLevel == _priceLevel).toList();
    }
    places.sort((a, b) {
      final featured = (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
      if (featured != 0) return featured;
      final rating = b.rating.compareTo(a.rating);
      return rating == 0 ? a.name.compareTo(b.name) : rating;
    });
    return places;
  }

  Place? _heroFallback(AppState app) {
    for (final place in app.places) {
      if (CategoryDiscoveryTaxonomy.rootsFor(widget.mode)
          .any((root) => CategoryDiscoveryTaxonomy.matchesRoot(place, root))) {
        return place;
      }
    }
    return null;
  }

  String _title(AppLocalizations l10n) {
    switch (widget.mode) {
      case CategoryDiscoveryMode.foodCafe:
        return l10n.categoryFoodTitle;
      case CategoryDiscoveryMode.thingsToDo:
        return l10n.categoryThingsTitle;
      case CategoryDiscoveryMode.transportation:
        return l10n.categoryTransportTitle;
    }
  }

  String _subtitle(AppLocalizations l10n) {
    switch (widget.mode) {
      case CategoryDiscoveryMode.foodCafe:
        return l10n.categoryFoodSubtitle;
      case CategoryDiscoveryMode.thingsToDo:
        return l10n.categoryThingsSubtitle;
      case CategoryDiscoveryMode.transportation:
        return l10n.categoryTransportSubtitle;
    }
  }

  String _searchHint(AppLocalizations l10n) {
    switch (widget.mode) {
      case CategoryDiscoveryMode.foodCafe:
        return l10n.categoryFoodSearchHint;
      case CategoryDiscoveryMode.thingsToDo:
        return l10n.categoryThingsSearchHint;
      case CategoryDiscoveryMode.transportation:
        return l10n.categoryTransportSearchHint;
    }
  }

  Future<void> _showFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    var draftRating = _minRating;
    var draftPrice = _priceLevel;
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
                Text(l10n.categoryFiltersTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.categoryFilterRating,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.savedPlacesAllFilter),
                      selected: draftRating == null,
                      onSelected: (_) =>
                          setSheetState(() => draftRating = null),
                    ),
                    ChoiceChip(
                      label: Text(l10n.categoryFilterRating45),
                      selected: draftRating == 4.5,
                      onSelected: (_) => setSheetState(() => draftRating = 4.5),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.categoryFilterPrice,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.categoryFilterPriceAny),
                      selected: draftPrice == null,
                      onSelected: (_) => setSheetState(() => draftPrice = null),
                    ),
                    for (final price in const ['\$', '\$\$', '\$\$\$'])
                      ChoiceChip(
                        label: Text(price),
                        selected: draftPrice == price,
                        onSelected: (_) =>
                            setSheetState(() => draftPrice = price),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                OceanPrimaryButton(
                  label: l10n.categoryFilterApply,
                  icon: Icons.check_rounded,
                  onPressed: () {
                    setState(() {
                      _minRating = draftRating;
                      _priceLevel = draftPrice;
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

  void _openPlace(Place place) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
    );
  }

  void _addToTrip(Place place) => showAddToTripSheet(context, place);
}

class _CategoryHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final Place? place;
  final IconData fallbackIcon;

  const _CategoryHero({
    required this.title,
    required this.subtitle,
    required this.place,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) => OceanGlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.xxl),
              ),
              child: place == null
                  ? Container(
                      height: 210,
                      color: AppColors.paleCyan,
                      alignment: Alignment.center,
                      child: Icon(
                        fallbackIcon,
                        color: AppColors.ocean,
                        size: AppIconSizes.xl,
                      ),
                    )
                  : Image.network(
                      place!.imageUrl,
                      height: 210,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, __, ___) => Container(
                        height: 210,
                        color: AppColors.paleCyan,
                        alignment: Alignment.center,
                        child: Icon(
                          fallbackIcon,
                          color: AppColors.ocean,
                          size: AppIconSizes.xl,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      );
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

class _RootChips extends StatelessWidget {
  final List<PlaceCategoryRoot> roots;
  final PlaceCategoryRoot? selected;
  final ValueChanged<PlaceCategoryRoot?> onSelected;

  const _RootChips({
    required this.roots,
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
              label: Text(l10n.categoryRootAll),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final root in roots)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                avatar: Icon(root.icon, size: AppIconSizes.xs),
                label: Text(root.label(l10n)),
                selected: selected == root,
                onSelected: (_) => onSelected(root),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryResultList extends StatelessWidget {
  final List<Place> results;
  final ValueChanged<Place> onPlace;
  final ValueChanged<Place> onAdd;

  const _CategoryResultList({
    required this.results,
    required this.onPlace,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final place in results)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _CategoryPlaceCard(
                place: place,
                onTap: () => onPlace(place),
                onAdd: () => onAdd(place),
              ),
            ),
        ],
      );
}

class _CategoryPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _CategoryPlaceCard({
    required this.place,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final image = _PlaceThumb(place: place, compact: compact);
        final details = _PlaceDetails(
          place: place,
          onAdd: onAdd,
        );
        return OceanGlassCard(
          onTap: onTap,
          semanticLabel: place.name,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    image,
                    const SizedBox(height: AppSpacing.md),
                    details,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image,
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: details),
                  ],
                ),
        );
      },
    );
  }
}

class _PlaceDetails extends StatelessWidget {
  final Place place;
  final VoidCallback onAdd;

  const _PlaceDetails({
    required this.place,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
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
            BookmarkButton(placeId: place.id, placeName: place.name),
          ],
        ),
        Text(
          '${place.locationName} · ${place.city}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            OceanStatusPill(label: place.category, icon: Icons.place_outlined),
            if (place.rating > 0)
              OceanStatusPill(
                label: place.rating.toStringAsFixed(1),
                icon: Icons.star_rounded,
                color: AppColors.ocean,
              ),
            if (place.priceLevel.isNotEmpty)
              OceanStatusPill(
                label: place.priceLevel,
                icon: Icons.payments_rounded,
                color: AppColors.turquoise600,
              ),
            if (place.estimatedDurationMinutes > 0)
              OceanStatusPill(
                label: _duration(context, place.estimatedDurationMinutes),
                icon: Icons.schedule_rounded,
                color: AppColors.violet,
              ),
          ],
        ),
        if (place.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            place.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: OceanSecondaryButton(
            key: Key('category-add-${place.id}'),
            label: l10n.placeAddToTrip,
            icon: Icons.add_rounded,
            fullWidth: false,
            semanticLabel: l10n.placeAddToTripSemantic(place.name),
            onPressed: onAdd,
          ),
        ),
      ],
    );
  }

  String _duration(BuildContext context, int minutes) {
    final l10n = AppLocalizations.of(context)!;
    if (minutes < 60) return l10n.placeDurationMinutes(minutes);
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (rest == 0) return l10n.placeDurationHours(hours);
    return l10n.placeDurationHoursMinutes(hours, rest);
  }
}

class _PlaceThumb extends StatelessWidget {
  final Place place;
  final bool compact;

  const _PlaceThumb({required this.place, required this.compact});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Image.network(
          place.imageUrl,
          width: compact ? double.infinity : 136,
          height: compact ? 180 : 136,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => Container(
            width: compact ? double.infinity : 136,
            height: compact ? 180 : 136,
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

class _CategoryMapFallback extends StatelessWidget {
  final CategoryDiscoveryMode mode;
  final List<Place> results;
  final VoidCallback onListMode;
  final ValueChanged<Place> onPlace;
  final ValueChanged<Place> onAdd;

  const _CategoryMapFallback({
    required this.mode,
    required this.results,
    required this.onListMode,
    required this.onPlace,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = mode == CategoryDiscoveryMode.transportation
        ? l10n.categoryTransportUnavailableMessage
        : l10n.mapUnavailableMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanStateView(
          icon: Icons.map_outlined,
          title: l10n.mapUnavailableTitle,
          message: message,
          actionLabel: l10n.searchBackToList,
          onAction: onListMode,
          semanticLabel: l10n.mapFallbackSemantic,
          primaryAction: false,
        ),
        const SizedBox(height: AppSpacing.md),
        _CategoryPlaceCard(
          place: results.first,
          onTap: () => onPlace(results.first),
          onAdd: () => onAdd(results.first),
        ),
      ],
    );
  }
}
