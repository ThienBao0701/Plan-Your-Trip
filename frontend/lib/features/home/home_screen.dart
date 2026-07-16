import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
import '../categories/category_discovery_screen.dart';
import '../places/place_detail_screen.dart';
import '../places/places_screen.dart';
import '../trips/create_trip_screen.dart';
import '../trips/trip_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final DateTime? today;

  const HomeScreen({super.key, this.today});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _openSearch({String? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlacesScreen(
          initialQuery: search.text.trim(),
          initialCategory: category,
        ),
      ),
    );
  }

  void _openCategory(Category category) {
    final mode = CategoryDiscoveryTaxonomy.modeForCategory(category);
    if (mode == null) {
      _openSearch(category: category.id);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDiscoveryScreen(
          mode: mode,
          initialRoot: CategoryDiscoveryTaxonomy.rootForCategory(category),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final featured = app.filteredPlaces(const PlaceQuery(isFeatured: true));
    final upcoming = _nextTrip(app.trips);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        120,
      ),
      children: [
        OceanContentConstraint(
          maxWidth: AppBreakpoints.maxContentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.exploreHeroTitle,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.exploreHeroSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SearchEntry(
                controller: search,
                onSearch: () => _openSearch(),
                onFilter: () => _openSearch(),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (upcoming == null)
                OceanEmptyState(
                  title: l10n.exploreNoUpcomingTitle,
                  message: app.demoMode
                      ? l10n.exploreNoUpcomingMessage
                      : l10n.tripsRealUnavailableMessage,
                  actionLabel: l10n.tripsCreateAction,
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateTripScreen(),
                    ),
                  ),
                )
              else
                _UpcomingTripCard(
                  trip: upcoming,
                  today: widget.today,
                  plannedActivities: app.timeline
                      .where((item) => item.tripId == upcoming.id)
                      .length,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripDetailScreen(trip: upcoming),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                title: l10n.exploreCategoriesTitle,
                action: l10n.exploreSeeAll,
                onAction: () => _openSearch(),
              ),
              const SizedBox(height: AppSpacing.sm),
              _CategoryShortcuts(
                categories: app.categories,
                onCategory: _openCategory,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                title: l10n.exploreRecommendedTitle,
                action: l10n.exploreSeeAll,
                onAction: () => _openSearch(),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (featured.isEmpty)
                OceanEmptyState(
                  title: l10n.exploreNoPlacesTitle,
                  message: l10n.exploreNoPlacesMessage,
                )
              else
                _FeaturedPlaces(
                  places: featured,
                  onPlace: (place) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaceDetailScreen(place: place),
                    ),
                  ),
                  onAdd: (place) => showAddToTripSheet(context, place),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Trip? _nextTrip(List<Trip> trips) {
    final today = widget.today ?? DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final candidates = trips
        .where((trip) => !DateTime(
              trip.endDate.year,
              trip.endDate.month,
              trip.endDate.day,
            ).isBefore(current))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return candidates.isEmpty ? null : candidates.first;
  }
}

class _SearchEntry extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onFilter;

  const _SearchEntry({
    required this.controller,
    required this.onSearch,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      radius: AppRadii.sheet,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('explore-home-search'),
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                hintText: l10n.exploreSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.exploreSearchActionSemantic,
            child: IconButton(
              tooltip: l10n.exploreSearchActionSemantic,
              onPressed: onSearch,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.exploreFiltersSemantic,
            child: IconButton(
              tooltip: l10n.exploreFiltersSemantic,
              onPressed: onFilter,
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTripCard extends StatelessWidget {
  final Trip trip;
  final DateTime? today;
  final int plannedActivities;
  final VoidCallback onTap;

  const _UpcomingTripCard({
    required this.trip,
    required this.today,
    required this.plannedActivities,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.MMMd(Localizations.localeOf(context).toString());
    final targetActivities = (trip.days * 2).clamp(1, 999);
    final progress = (plannedActivities / targetActivities).clamp(0.0, 1.0);
    return OceanGlassCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      semanticLabel: l10n.exploreUpcomingTripSemantic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NetworkImageFrame(
            imageUrl: trip.imageUrl,
            height: 190,
            radius: AppRadii.xxl,
            fallbackIcon: Icons.landscape_rounded,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OceanStatusPill(
                  label: l10n.tripDaysAway(_daysUntil(trip.startDate)),
                  icon: Icons.calendar_month_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  trip.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.tripDateTravelerMeta(
                    date.format(trip.startDate),
                    date.format(trip.endDate),
                    trip.travelers,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.explorePlanningProgress(plannedActivities),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.ocean),
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.mist,
                    color: AppColors.ocean,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _daysUntil(DateTime date) {
    final now = today ?? DateTime.now();
    final current = DateTime(now.year, now.month, now.day);
    final start = DateTime(date.year, date.month, date.day);
    final days = start.difference(current).inDays;
    return days < 0 ? 0 : days;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(action),
          ),
        ],
      );
}

class _CategoryShortcuts extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category> onCategory;

  const _CategoryShortcuts({
    required this.categories,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.take(8).length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final category = categories[index];
            return SizedBox(
              width: 132,
              child: OceanGlassCard(
                onTap: () => onCategory(category),
                padding: const EdgeInsets.all(AppSpacing.sm),
                semanticLabel: category.name,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: category.color.withValues(alpha: .14),
                      child: Icon(category.icon, color: category.color),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      category.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

class _FeaturedPlaces extends StatelessWidget {
  final List<Place> places;
  final ValueChanged<Place> onPlace;
  final ValueChanged<Place> onAdd;

  const _FeaturedPlaces({
    required this.places,
    required this.onPlace,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AppBreakpoints.tablet;
          if (wide) {
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: places
                  .map(
                    (place) => SizedBox(
                      width: (constraints.maxWidth - AppSpacing.md) / 2,
                      child: _PlacePreviewCard(
                        place: place,
                        onTap: () => onPlace(place),
                        onAdd: () => onAdd(place),
                      ),
                    ),
                  )
                  .toList(),
            );
          }
          return Column(
            children: places
                .map(
                  (place) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _PlacePreviewCard(
                      place: place,
                      onTap: () => onPlace(place),
                      onAdd: () => onAdd(place),
                    ),
                  ),
                )
                .toList(),
          );
        },
      );
}

class _PlacePreviewCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _PlacePreviewCard({
    required this.place,
    required this.onTap,
    required this.onAdd,
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
          _NetworkImageFrame(
            imageUrl: place.imageUrl,
            height: 104,
            width: 104,
            radius: AppRadii.lg,
            fallbackIcon: Icons.place_rounded,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OceanStatusPill(
                  label: place.category,
                  icon: Icons.place_outlined,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  place.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: l10n.placeAddToTripSemantic(place.name),
            child: IconButton.filled(
              tooltip: l10n.placeAddToTripSemantic(place.name),
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkImageFrame extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double? width;
  final double radius;
  final IconData fallbackIcon;

  const _NetworkImageFrame({
    required this.imageUrl,
    required this.height,
    this.width,
    required this.radius,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          imageUrl,
          height: height,
          width: width ?? double.infinity,
          fit: BoxFit.cover,
          semanticLabel: '',
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => Container(
            height: height,
            width: width ?? double.infinity,
            color: AppColors.paleCyan,
            alignment: Alignment.center,
            child: Icon(
              fallbackIcon,
              color: AppColors.ocean,
              size: AppIconSizes.lg,
            ),
          ),
        ),
      );
}
