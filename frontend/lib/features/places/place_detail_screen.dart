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
import '../hotels/hotel_room_selection_screen.dart';
import '../hotels/hotel_utils.dart';
import '../reviews/reviews_screen.dart';

class PlaceDetailScreen extends StatelessWidget {
  final Place place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final saved = app.isPlaceSaved(place.id);
    final bookmarkLabel = saved
        ? l10n.savedPlacesRemoveSemantic(place.name)
        : l10n.savedPlacesSaveSemantic(place.name);
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
            toggled: saved,
            label: bookmarkLabel,
            child: IconButton(
              tooltip: bookmarkLabel,
              onPressed: () => _bookmark(context),
              icon: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: saved ? AppColors.ocean : null,
              ),
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
                    if (place.hotelDetail != null) ...[
                      _HotelDetailSection(
                        place: place,
                        onAvailability: () => _openHotelAvailability(context),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    PlaceReviewSummaryCard(place: place),
                    const SizedBox(height: AppSpacing.md),
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
    final wasSaved = app.isPlaceSaved(place.id);
    final outcome =
        wasSaved ? app.removeSavedPlace(place.id) : app.savePlace(place.id);
    final message = switch (outcome) {
      SavedPlaceActionResult.success => wasSaved
          ? l10n.savedPlacesRemovedPlace(place.name)
          : l10n.savedPlacesSavedMessage(place.name),
      SavedPlaceActionResult.duplicate =>
        l10n.savedPlacesAlreadySavedMessage(place.name),
      SavedPlaceActionResult.unavailable => l10n.savedPlacesRealEmptyMessage,
      SavedPlaceActionResult.forbidden =>
        l10n.savedPlacesActionForbiddenMessage,
      SavedPlaceActionResult.notFound => l10n.savedPlacesMissingMessage,
      SavedPlaceActionResult.invalidNote => l10n.savedPlacesNoteTooLongMessage,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

  void _openHotelAvailability(BuildContext context) {
    final app = AppScope.of(context);
    final today = app.now();
    final upcoming = _nextTrip(app.trips, today);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotelRoomSelectionScreen(
          hotel: place,
          initialCriteria: defaultHotelCriteria(today: today, trip: upcoming)
              .copyWith(destination: place.city),
          today: today,
        ),
      ),
    );
  }

  Trip? _nextTrip(List<Trip> trips, DateTime today) {
    final current = hotelDateOnly(today);
    final candidates = trips
        .where((trip) => !hotelDateOnly(trip.endDate).isBefore(current))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return candidates.isEmpty ? null : candidates.first;
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

class _HotelDetailSection extends StatelessWidget {
  final Place place;
  final VoidCallback onAvailability;

  const _HotelDetailSection({
    required this.place,
    required this.onAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detail = place.hotelDetail!;
    return OceanGlassCard(
      semanticLabel: l10n.hotelDetailTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.hotelDetailTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (detail.starRating != null)
                OceanStatusPill(
                  label: l10n.hotelStars(detail.starRating!),
                  icon: Icons.star_rounded,
                ),
              if (detail.checkInTime != null && detail.checkOutTime != null)
                OceanStatusPill(
                  label: l10n.hotelCheckInOutMeta(
                    detail.checkInTime!,
                    detail.checkOutTime!,
                  ),
                  icon: Icons.schedule_rounded,
                  color: AppColors.turquoise600,
                ),
              if (detail.availableRooms != null && detail.availableRooms! > 0)
                OceanStatusPill(
                  label: l10n.hotelAvailableRooms(detail.availableRooms!),
                  icon: Icons.meeting_room_rounded,
                  color: AppColors.success,
                ),
              if (detail.breakfastIncluded == true)
                OceanStatusPill(
                  label: l10n.hotelBreakfastIncluded,
                  icon: Icons.restaurant_rounded,
                  color: AppColors.coral,
                ),
              if (detail.airportShuttle == true)
                OceanStatusPill(
                  label: l10n.hotelAirportShuttle,
                  icon: Icons.airport_shuttle_rounded,
                  color: AppColors.violet,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (detail.distanceToBeachMeters != null &&
              detail.distanceToBeachMeters! > 0)
            _InfoRow(
              icon: Icons.beach_access_rounded,
              text: l10n.hotelDistanceBeach(detail.distanceToBeachMeters!),
            ),
          if (detail.distanceToCityCenterMeters != null &&
              detail.distanceToCityCenterMeters! > 0)
            _InfoRow(
              icon: Icons.location_city_rounded,
              text:
                  l10n.hotelDistanceCenter(detail.distanceToCityCenterMeters!),
            ),
          if (detail.parking != null)
            _InfoRow(icon: Icons.local_parking_rounded, text: detail.parking!),
          if (detail.internet != null)
            _InfoRow(icon: Icons.wifi_rounded, text: detail.internet!),
          if (detail.languages.isNotEmpty)
            _InfoRow(
              icon: Icons.translate_rounded,
              text: l10n.hotelLanguages(detail.languages.join(', ')),
            ),
          if (detail.paymentMethods.isNotEmpty)
            _InfoRow(
              icon: Icons.payments_rounded,
              text: l10n.hotelPaymentMethods(detail.paymentMethods.join(', ')),
            ),
          if (detail.facilities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.hotelFacilitiesTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final item in detail.facilities) Chip(label: Text(item)),
              ],
            ),
          ],
          if (detail.services.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.hotelServicesTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final item in detail.services) Chip(label: Text(item)),
              ],
            ),
          ],
          if (detail.rooms.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.hotelRoomPreviewTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail.rooms.take(2).map((room) => room.roomName).join(' · '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          OceanPrimaryButton(
            key: const Key('hotel-detail-check-availability'),
            label: l10n.hotelCheckAvailabilityAction,
            icon: Icons.king_bed_rounded,
            semanticLabel: l10n.hotelCheckAvailabilitySemantic(place.name),
            onPressed: onAvailability,
          ),
        ],
      ),
    );
  }
}
