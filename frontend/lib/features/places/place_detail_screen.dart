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

class PlaceDetailScreen extends StatelessWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(place.name),
        actions: [
          Semantics(
            button: true,
            label: l10n.savedPlacesBookmarkSemantic(place.name),
            child: IconButton(
              tooltip: l10n.savedPlacesBookmarkSemantic(place.name),
              onPressed: () => _bookmark(context),
              icon: const Icon(Icons.bookmark_border_rounded),
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
                    _HeroImage(place: place),
                    const SizedBox(height: AppSpacing.lg),
                    OceanGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${place.locationName} · ${place.city}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              OceanStatusPill(
                                label: place.category,
                                icon: Icons.place_outlined,
                              ),
                              if (place.priceLevel.isNotEmpty)
                                OceanStatusPill(
                                  label: place.priceLevel,
                                  icon: Icons.payments_rounded,
                                  color: AppColors.turquoise600,
                                ),
                              if (place.estimatedDurationMinutes > 0)
                                OceanStatusPill(
                                  label: _formatDuration(
                                    context,
                                    place.estimatedDurationMinutes,
                                  ),
                                  icon: Icons.schedule_rounded,
                                  color: AppColors.ocean400,
                                ),
                            ],
                          ),
                          if (place.rating > 0) ...[
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.ocean,
                                    size: AppIconSizes.sm),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  place.rating.toStringAsFixed(1),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: AppColors.ocean),
                                ),
                                if (place.reviewCount > 0) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    l10n.placeReviewCount(place.reviewCount),
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OceanGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.placeHighlightsTitle,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: AppSpacing.sm),
                          Text(place.description,
                              style: Theme.of(context).textTheme.bodyLarge),
                          if (place.tags.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                for (final tag in place.tags)
                                  Chip(label: Text('#$tag')),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (place.openingHours != null || place.address.isNotEmpty)
                      OceanGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.placeUsefulInfoTitle,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: AppSpacing.sm),
                            if (place.openingHours != null)
                              _InfoRow(
                                icon: Icons.access_time_rounded,
                                text: place.openingHours!,
                              ),
                            if (place.address.isNotEmpty)
                              _InfoRow(
                                icon: Icons.place_rounded,
                                text: place.address,
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    if (_isTransportation(place)) ...[
                      OceanGlassCard(
                        semanticLabel: l10n.categoryTransportUnavailableTitle,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.categoryTransportUnavailableTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.categoryTransportUnavailableMessage,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    OceanGlassCard(
                      child: Text(
                        l10n.mapUnavailableMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OceanPrimaryButton(
                      label: l10n.placeAddToTrip,
                      semanticLabel: l10n.placeAddToTripSemantic(place.name),
                      icon: Icons.add_location_alt_rounded,
                      onPressed: () => showAddToTripSheet(context, place),
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

  void _bookmark(BuildContext context) {
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

  String _formatDuration(BuildContext context, int minutes) {
    final l10n = AppLocalizations.of(context)!;
    if (minutes < 60) return l10n.placeDurationMinutes(minutes);
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (rest == 0) return l10n.placeDurationHours(hours);
    return l10n.placeDurationHoursMinutes(hours, rest);
  }

  bool _isTransportation(Place place) {
    final slug = place.effectiveCategorySlug.toLowerCase();
    final label = place.category.toLowerCase();
    return slug == 'transportation' ||
        label == 'transportation' ||
        label == 'transport';
  }
}

class _HeroImage extends StatelessWidget {
  final Place place;

  const _HeroImage({required this.place});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        child: Image.network(
          place.imageUrl,
          key: const Key('place-detail-image'),
          height: 320,
          width: double.infinity,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => Container(
            key: const Key('place-detail-image-fallback'),
            height: 320,
            color: AppColors.paleCyan,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_rounded,
              color: AppColors.ocean,
              size: AppIconSizes.xl,
            ),
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: AppColors.ocean, size: AppIconSizes.sm),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      );
}
