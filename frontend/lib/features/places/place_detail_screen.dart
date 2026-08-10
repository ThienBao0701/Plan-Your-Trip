import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/enum_labels.dart';
import '../../shared/widgets/add_to_trip_sheet.dart';
import '../../shared/widgets/bookmark_button.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import '../expenses/expenses_screen.dart';
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
    // Real Mode renders the rich hydrated place-detail record (gallery, grouped
    // opening hours, coordinates, metadata, rich hotel experience). Everything
    // below (the demo path) stays byte-for-byte unchanged.
    if (!app.demoMode) {
      return _RealPlaceDetailView(place: place);
    }
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(place.name),
        actions: [
          BookmarkButton(placeId: place.id, placeName: place.name),
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

// ─────────────────────────────────────────────────────────────────────────────
// UI23 — Real Mode place / hotel detail
// ─────────────────────────────────────────────────────────────────────────────

/// Real Mode detail view. Renders the full hydrated [PlaceDetailRecord]
/// (gallery, header, coordinates, grouped opening hours, place amenities,
/// metadata, and the rich hotel experience) for [place]. Every section is gated
/// on backend-confirmed data and hidden when absent — nothing is fabricated. It
/// reuses the UI19 hydration pipeline (single loader / cache / logout reset), so
/// entries that already hydrated incur no extra HTTP; a direct entry self-loads
/// with loading / retry / session states.
class _RealPlaceDetailView extends StatefulWidget {
  final Place place;

  const _RealPlaceDetailView({required this.place});

  @override
  State<_RealPlaceDetailView> createState() => _RealPlaceDetailViewState();
}

class _RealPlaceDetailViewState extends State<_RealPlaceDetailView> {
  PlaceHydrationResult? _lastResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppScope.of(context);
      // Record the view so the real "Recently viewed" list populates from
      // normal browsing (the backend does not auto-record on GET). Fire and
      // forget; the method guards demo mode and swallows its own errors.
      unawaited(app.recordRealRecentlyView(widget.place.id));
      if (app.getHydratedRealPlaceDetail(widget.place.id) == null &&
          !app.isRealPlaceHydrationInFlight(widget.place.id)) {
        _load();
      }
    });
  }

  Future<void> _load({bool refresh = false}) async {
    final result = await AppScope.of(context)
        .hydrateRealPlace(widget.place.id, refresh: refresh);
    if (mounted) setState(() => _lastResult = result);
  }

  Future<void> _refresh() => _load(refresh: true);

  void _reauth() {
    showOceanSessionExpiredSheet(
      context,
      onLogin: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      onReturnHome: () => Navigator.of(context).pop(),
    );
  }

  void _openHotelAvailability() {
    final app = AppScope.of(context);
    final today = app.now();
    final upcoming = _nextUpcomingTrip(app.trips, today);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotelRoomSelectionScreen(
          hotel: widget.place,
          initialCriteria: defaultHotelCriteria(today: today, trip: upcoming)
              .copyWith(destination: widget.place.city),
          today: today,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final record = app.getHydratedRealPlaceDetail(widget.place.id);
    final loading = app.isRealPlaceHydrationInFlight(widget.place.id);
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(widget.place.name),
        actions: [
          BookmarkButton(
            placeId: widget.place.id,
            placeName: widget.place.name,
          ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                OceanContentConstraint(
                  maxWidth: AppBreakpoints.maxContentWidth,
                  child: record != null
                      ? _content(context, l10n, record)
                      : _placeholder(context, l10n, loading),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(
    BuildContext context,
    AppLocalizations l10n,
    bool loading,
  ) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: OceanLoadingState(message: l10n.placeDetailRealLoadingMessage),
      );
    }
    if (_lastResult == PlaceHydrationResult.sessionExpired) {
      return OceanEmptyState(
        key: const Key('real-detail-session-expired'),
        title: l10n.tripsRealSessionExpiredTitle,
        message: l10n.tripsRealSessionExpiredMessage,
        actionLabel: l10n.tripsRealSignInAction,
        onAction: _reauth,
      );
    }
    final message = _lastResult == PlaceHydrationResult.notFound
        ? l10n.placeDetailRealNotFoundMessage
        : l10n.placeDetailRealErrorMessage;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: OceanRecoverableErrorState(
        key: const Key('real-detail-error'),
        message: message,
        onReload: _refresh,
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    PlaceDetailRecord record,
  ) {
    final theme = Theme.of(context);
    final place = widget.place;
    final images = _galleryImagesFor(record);
    final hasHours = record.groupedOpeningHours.isNotEmpty;
    final hasCoordinates = record.latitude != null && record.longitude != null;
    final description = (record.description?.trim().isNotEmpty ?? false)
        ? record.description!
        : (record.shortDescription ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RealGallery(images: images, placeName: record.name),
        const SizedBox(height: AppSpacing.lg),
        // Header card.
        OceanGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record.name, style: theme.textTheme.displaySmall),
              if (_locationLine(record).isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(_locationLine(record), style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if ((record.categoryName ?? '').isNotEmpty)
                    OceanStatusPill(
                      label: record.categoryName!,
                      icon: Icons.place_outlined,
                    ),
                  if (record.priceLevel > 0)
                    OceanStatusPill(
                      label: '\$' * record.priceLevel.clamp(0, 4),
                      icon: Icons.payments_rounded,
                      color: AppColors.turquoise600,
                    ),
                  if (hasHours)
                    OceanStatusPill(
                      label: record.openNow
                          ? l10n.placeOpenNow
                          : l10n.placeClosedNow,
                      icon: record.openNow
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      color: record.openNow
                          ? AppColors.success
                          : AppColors.textTertiary,
                    ),
                ],
              ),
              if (record.ratingAvg > 0) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.ocean, size: AppIconSizes.sm),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      record.ratingAvg.toStringAsFixed(1),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: AppColors.ocean),
                    ),
                    if (record.ratingCount > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.placeReviewCount(record.ratingCount),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        // Highlights.
        if (description.isNotEmpty || record.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          OceanGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.placeHighlightsTitle,
                    style: theme.textTheme.titleLarge),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(description, style: theme.textTheme.bodyLarge),
                ],
                if (record.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final tag in record.tags) Chip(label: Text('#$tag')),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        // Opening hours.
        if (hasHours) ...[
          const SizedBox(height: AppSpacing.md),
          OceanGlassCard(
            key: const Key('real-opening-hours'),
            semanticLabel: l10n.placeOpeningHoursTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.placeOpeningHoursTitle,
                          style: theme.textTheme.titleLarge),
                    ),
                    OceanStatusPill(
                      label: record.openNow
                          ? l10n.placeOpenNow
                          : l10n.placeClosedNow,
                      icon: record.openNow
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      color: record.openNow
                          ? AppColors.success
                          : AppColors.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final group in record.groupedOpeningHours)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(group.days,
                              style: theme.textTheme.bodyMedium),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            group.closed ||
                                    group.openTime == null ||
                                    group.closeTime == null
                                ? l10n.placeOpeningHoursClosed
                                : '${_shortHm(group.openTime)}–${_shortHm(group.closeTime)}',
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        // Coordinates / address.
        if (hasCoordinates || record.address.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          OceanGlassCard(
            key: const Key('real-place-coordinates'),
            semanticLabel: l10n.placeCoordinatesTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.placeCoordinatesTitle,
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                if (record.address.isNotEmpty)
                  _InfoRow(icon: Icons.place_rounded, text: record.address),
                if (hasCoordinates)
                  _InfoRow(
                    icon: Icons.my_location_rounded,
                    text: l10n.placeCoordinatesValue(
                      record.latitude!.toStringAsFixed(5),
                      record.longitude!.toStringAsFixed(5),
                    ),
                  ),
                if ((record.googleMapUrl ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.map_rounded,
                          color: AppColors.ocean, size: AppIconSizes.sm),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: SelectableText(
                          record.googleMapUrl!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.ocean),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        // Place-level amenities.
        if (record.amenities.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          OceanGlassCard(
            key: const Key('real-place-amenities'),
            semanticLabel: l10n.placeAmenitiesTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.placeAmenitiesTitle,
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final a in record.amenities) Chip(label: Text(a.name)),
                  ],
                ),
              ],
            ),
          ),
        ],
        // Metadata.
        if (record.metadata != null && !record.metadata!.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _MetadataCard(metadata: record.metadata!),
        ],
        // Rich hotel experience.
        if (record.hotelDetailRich != null) ...[
          const SizedBox(height: AppSpacing.md),
          _RealHotelExperience(
            placeName: record.name,
            detail: record.hotelDetailRich!,
            onAvailability: _openHotelAvailability,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PlaceReviewSummaryCard(place: place),
        const SizedBox(height: AppSpacing.lg),
        OceanPrimaryButton(
          label: l10n.placeAddToTrip,
          semanticLabel: l10n.placeAddToTripSemantic(place.name),
          icon: Icons.add_location_alt_rounded,
          onPressed: () => showAddToTripSheet(context, place),
        ),
      ],
    );
  }

  String _locationLine(PlaceDetailRecord record) {
    final path = record.locationFullPath?.trim() ?? '';
    if (path.isNotEmpty) return path;
    return record.locationName;
  }

  List<PlaceGalleryImageRecord> _galleryImagesFor(PlaceDetailRecord record) {
    if (record.galleryImages.isNotEmpty) return record.galleryImages;
    final cover = record.coverImageUrl;
    if (cover != null && cover.isNotEmpty) {
      return [PlaceGalleryImageRecord(id: 0, url: cover, cover: true)];
    }
    return const [];
  }
}

/// Next trip whose end date is not before [today], soonest first (mirrors the
/// demo detail screen's trip lookup for the availability entry).
Trip? _nextUpcomingTrip(List<Trip> trips, DateTime today) {
  final current = hotelDateOnly(today);
  final candidates = trips
      .where((trip) => !hotelDateOnly(trip.endDate).isBefore(current))
      .toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  return candidates.isEmpty ? null : candidates.first;
}

String _shortHm(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final parts = raw.split(':');
  return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : raw;
}

/// A backend gallery carousel: swipeable images with dot indicators and a
/// full-screen preview on tap. The primary image carries the `place-detail-image`
/// key (and the empty-state placeholder `place-detail-image-fallback`) so the
/// UI19 hydration tests keep asserting the same contract. No fabricated images.
class _RealGallery extends StatefulWidget {
  final List<PlaceGalleryImageRecord> images;
  final String placeName;

  const _RealGallery({required this.images, required this.placeName});

  @override
  State<_RealGallery> createState() => _RealGalleryState();
}

class _RealGalleryState extends State<_RealGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen(int initial) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .92),
      builder: (_) => _FullscreenGallery(
        images: widget.images,
        initialIndex: initial,
        placeName: widget.placeName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.images.isEmpty) {
      return _galleryPlaceholder();
    }
    return Semantics(
      label: l10n.placeGallerySemantic(widget.placeName, widget.images.length),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.images.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final image = widget.images[i];
                  return GestureDetector(
                    onTap: () => _openFullscreen(i),
                    child: Image.network(
                      image.url,
                      key: i == 0 ? const Key('place-detail-image') : null,
                      height: 320,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, __, ___) =>
                          _imageFallback(keyed: i == 0),
                    ),
                  );
                },
              ),
            ),
            if (widget.images.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.images.length; i++)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _index
                              ? AppColors.white
                              : AppColors.white.withValues(alpha: .5),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _galleryPlaceholder() => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        child: _imageFallback(keyed: true),
      );

  Widget _imageFallback({required bool keyed}) => Container(
        key: keyed ? const Key('place-detail-image-fallback') : null,
        height: 320,
        color: AppColors.paleCyan,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_rounded,
          color: AppColors.ocean,
          size: AppIconSizes.xl,
        ),
      );
}

class _FullscreenGallery extends StatefulWidget {
  final List<PlaceGalleryImageRecord> images;
  final int initialIndex;
  final String placeName;

  const _FullscreenGallery({
    required this.images,
    required this.initialIndex,
    required this.placeName,
  });

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            itemBuilder: (context, i) => InteractiveViewer(
              child: Center(
                child: Image.network(
                  widget.images[i].url,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_rounded,
                    color: AppColors.white,
                    size: AppIconSizes.xl,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: SafeArea(
              child: IconButton(
                tooltip: l10n.placeGalleryClose,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the full nullable place [PlaceMetadataRecord] with localized labels.
/// Enum values degrade to a humanized token if the backend ever adds a value.
class _MetadataCard extends StatelessWidget {
  final PlaceMetadataRecord metadata;

  const _MetadataCard({required this.metadata});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sections = <Widget>[];

    void addWrap(String title, List<String> labels) {
      if (labels.isEmpty) return;
      sections.add(_titledWrap(context, title, labels));
    }

    if (metadata.estimatedVisitMinutes != null &&
        metadata.estimatedVisitMinutes! > 0) {
      addWrap(l10n.metadataVisitDurationTitle, [
        _formatDurationFree(context, metadata.estimatedVisitMinutes!),
      ]);
    }
    addWrap(
      l10n.metadataTravelStylesTitle,
      metadata.travelStyles.map((v) => _travelStyleLabel(l10n, v)).toList(),
    );
    addWrap(
      l10n.metadataBestSeasonsTitle,
      metadata.bestSeasons.map((v) => _bestSeasonLabel(l10n, v)).toList(),
    );
    addWrap(
      l10n.metadataBestVisitTimesTitle,
      metadata.bestVisitTimes.map((v) => _bestVisitTimeLabel(l10n, v)).toList(),
    );
    addWrap(
      l10n.metadataWeatherTitle,
      metadata.weatherTypes.map((v) => _weatherLabel(l10n, v)).toList(),
    );
    if (metadata.budgetLevel != null) {
      addWrap(l10n.metadataBudgetTitle,
          [_budgetLabel(l10n, metadata.budgetLevel!)]);
    }
    if (metadata.difficultyLevel != null) {
      addWrap(l10n.metadataDifficultyTitle,
          [_difficultyLabel(l10n, metadata.difficultyLevel!)]);
    }
    if (metadata.accessibilityLevel != null) {
      addWrap(l10n.metadataAccessibilityTitle,
          [_accessibilityLabel(l10n, metadata.accessibilityLevel!)]);
    }
    if (metadata.crowdLevel != null) {
      addWrap(
          l10n.metadataCrowdTitle, [_crowdLabel(l10n, metadata.crowdLevel!)]);
    }
    final flags = metadata.activeFlags.map((f) => _flagLabel(l10n, f)).toList();
    addWrap(l10n.metadataHighlightsTitle, flags);

    return OceanGlassCard(
      key: const Key('real-metadata'),
      semanticLabel: l10n.placeMetadataTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.placeMetadataTitle, style: theme.textTheme.titleLarge),
          for (final section in sections) ...[
            const SizedBox(height: AppSpacing.sm),
            section,
          ],
          if ((metadata.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.metadataNotesTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(metadata.notes!.trim(), style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

Widget _titledWrap(BuildContext context, String title, List<String> labels) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.xxs),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [for (final label in labels) Chip(label: Text(label))],
      ),
    ],
  );
}

String _formatDurationFree(BuildContext context, int minutes) {
  final l10n = AppLocalizations.of(context)!;
  if (minutes < 60) return l10n.placeDurationMinutes(minutes);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return l10n.placeDurationHours(hours);
  return l10n.placeDurationHoursMinutes(hours, rest);
}

/// The rich hotel experience: pills, distances, parking/wifi, languages,
/// payment methods, grouped facilities, services, policies, and room previews.
/// Reuses the demo booking availability entry point. Backend fields only.
class _RealHotelExperience extends StatelessWidget {
  final String placeName;
  final HotelDetailRecord detail;
  final VoidCallback onAvailability;

  const _RealHotelExperience({
    required this.placeName,
    required this.detail,
    required this.onAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return OceanGlassCard(
      key: const Key('real-hotel-detail'),
      semanticLabel: l10n.hotelDetailTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.hotelDetailTitle, style: theme.textTheme.titleLarge),
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
              if (detail.breakfastIncluded)
                OceanStatusPill(
                  label: l10n.hotelBreakfastIncluded,
                  icon: Icons.restaurant_rounded,
                  color: AppColors.coral,
                ),
              if (detail.airportShuttle)
                OceanStatusPill(
                  label: l10n.hotelAirportShuttle,
                  icon: Icons.airport_shuttle_rounded,
                  color: AppColors.violet,
                ),
              if (detail.freeCancellation)
                OceanStatusPill(
                  label: l10n.availabilityRealFreeCancellation,
                  icon: Icons.verified_rounded,
                  color: AppColors.turquoise600,
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
          if (detail.parking.hasInfo)
            _InfoRow(
              icon: Icons.local_parking_rounded,
              text: _parkingText(l10n, detail.parking),
            ),
          if (detail.internet.hasInfo)
            _InfoRow(
              icon: Icons.wifi_rounded,
              text: _internetText(l10n, detail.internet),
            ),
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
            Text(l10n.hotelFacilitiesTitle, style: theme.textTheme.titleMedium),
            for (final group in detail.groupedFacilities) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(_facilityGroupLabel(l10n, group.key),
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xxs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final f in group.value)
                    Chip(label: Text(f.facilityName)),
                ],
              ),
            ],
          ],
          if (detail.services.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.hotelServicesTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final s in detail.services)
                  Chip(
                    label: Text(s.available
                        ? s.serviceName
                        : l10n.hotelServiceUnavailable(s.serviceName)),
                  ),
              ],
            ),
          ],
          if (_hasPolicies(detail)) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.hotelPoliciesTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            if ((detail.cancellationPolicy ?? '').isNotEmpty)
              _PolicyRow(
                title: l10n.hotelPolicyCancellation,
                body: detail.cancellationPolicy!,
              ),
            if ((detail.paymentPolicy ?? '').isNotEmpty)
              _PolicyRow(
                title: l10n.hotelPolicyPayment,
                body: detail.paymentPolicy!,
              ),
            if ((detail.childrenPolicy ?? '').isNotEmpty)
              _PolicyRow(
                title: l10n.hotelPolicyChildren,
                body: detail.childrenPolicy!,
              ),
            if ((detail.petPolicy ?? '').isNotEmpty)
              _PolicyRow(
                title: l10n.hotelPolicyPet,
                body: detail.petPolicy!,
              ),
            if ((detail.smokingPolicy ?? '').isNotEmpty)
              _PolicyRow(
                title: l10n.hotelPolicySmoking,
                body: detail.smokingPolicy!,
              ),
          ],
          if (detail.rooms.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.hotelRoomPreviewTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            for (final room in detail.rooms)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _RealRoomPreviewCard(room: room),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          OceanPrimaryButton(
            key: const Key('hotel-detail-check-availability'),
            label: l10n.hotelCheckAvailabilityAction,
            icon: Icons.king_bed_rounded,
            semanticLabel: l10n.hotelCheckAvailabilitySemantic(placeName),
            onPressed: onAvailability,
          ),
        ],
      ),
    );
  }

  bool _hasPolicies(HotelDetailRecord d) =>
      (d.cancellationPolicy ?? '').isNotEmpty ||
      (d.paymentPolicy ?? '').isNotEmpty ||
      (d.childrenPolicy ?? '').isNotEmpty ||
      (d.petPolicy ?? '').isNotEmpty ||
      (d.smokingPolicy ?? '').isNotEmpty;

  String _parkingText(AppLocalizations l10n, HotelParkingRecord p) {
    final status = !p.available
        ? l10n.hotelParkingUnavailable
        : p.free
            ? l10n.hotelParkingFree
            : l10n.hotelParkingPaid;
    final desc = p.description?.trim() ?? '';
    return desc.isEmpty ? status : '$status · $desc';
  }

  String _internetText(AppLocalizations l10n, HotelInternetRecord i) {
    final status = !i.wifiAvailable
        ? l10n.hotelWifiUnavailable
        : i.wifiFree
            ? l10n.hotelWifiFree
            : l10n.hotelWifiPaid;
    final desc = i.description?.trim() ?? '';
    return desc.isEmpty ? status : '$status · $desc';
  }
}

class _PolicyRow extends StatelessWidget {
  final String title;
  final String body;

  const _PolicyRow({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelLarge),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// A read-only preview of one backend [HotelRoom]. Booking continuation stays in
/// the availability flow; this only surfaces the room's confirmed attributes.
class _RealRoomPreviewCard extends StatelessWidget {
  final HotelRoom room;

  const _RealRoomPreviewCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return OceanGlassSurface(
      key: Key('real-room-preview-${room.id}'),
      blur: 0,
      color: AppColors.surfaceOverlay,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(room.roomName, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: roomTypeLabel(l10n, room.roomType),
                icon: Icons.hotel_class_rounded,
              ),
              OceanStatusPill(
                label: bedTypeLabel(l10n, room.bedType, room.bedCount),
                icon: Icons.bed_rounded,
                color: AppColors.turquoise600,
              ),
              OceanStatusPill(
                label: l10n.hotelMaxGuests(room.maxGuests),
                icon: Icons.group_rounded,
                color: AppColors.ocean400,
              ),
              if (room.roomSizeSqm != null && room.roomSizeSqm! > 0)
                OceanStatusPill(
                  label: l10n.hotelRoomSize(room.roomSizeSqm!),
                  icon: Icons.square_foot_rounded,
                  color: AppColors.violet,
                ),
            ],
          ),
          if (room.priceFrom != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.hotelFromPrice(formatMoney(context, room.priceFrom!, 'VND')),
              style:
                  theme.textTheme.titleSmall?.copyWith(color: AppColors.ocean),
            ),
          ],
          if (room.amenities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(room.amenities.join(' · '), style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

// ── Localized enum labels (raw backend UPPER token → l10n; humanized fallback) ─

// Shared personalization-dimension labels live in `shared/enum_labels.dart`
// (reused by the real Interest Profile, UI-52). These thin wrappers keep the
// existing call sites unchanged while routing to the single source of truth.
String _humanizeEnum(String raw) => humanizeEnumToken(raw);

String _travelStyleLabel(AppLocalizations l10n, String raw) =>
    travelStyleLabel(l10n, raw);

String _bestVisitTimeLabel(AppLocalizations l10n, String raw) {
  switch (raw.toUpperCase()) {
    case 'EARLY_MORNING':
      return l10n.bestVisitTimeEarlyMorning;
    case 'MORNING':
      return l10n.bestVisitTimeMorning;
    case 'AFTERNOON':
      return l10n.bestVisitTimeAfternoon;
    case 'SUNSET':
      return l10n.bestVisitTimeSunset;
    case 'EVENING':
      return l10n.bestVisitTimeEvening;
    case 'NIGHT':
      return l10n.bestVisitTimeNight;
    default:
      return _humanizeEnum(raw);
  }
}

String _bestSeasonLabel(AppLocalizations l10n, String raw) {
  switch (raw.toUpperCase()) {
    case 'SPRING':
      return l10n.bestSeasonSpring;
    case 'SUMMER':
      return l10n.bestSeasonSummer;
    case 'AUTUMN':
      return l10n.bestSeasonAutumn;
    case 'WINTER':
      return l10n.bestSeasonWinter;
    case 'ALL_YEAR':
      return l10n.bestSeasonAllYear;
    default:
      return _humanizeEnum(raw);
  }
}

String _weatherLabel(AppLocalizations l10n, String raw) =>
    weatherTypeLabel(l10n, raw);

String _budgetLabel(AppLocalizations l10n, String raw) =>
    budgetLevelLabel(l10n, raw);

String _difficultyLabel(AppLocalizations l10n, String raw) {
  switch (raw.toUpperCase()) {
    case 'EASY':
      return l10n.difficultyEasy;
    case 'MODERATE':
      return l10n.difficultyModerate;
    case 'HARD':
      return l10n.difficultyHard;
    default:
      return _humanizeEnum(raw);
  }
}

String _accessibilityLabel(AppLocalizations l10n, String raw) =>
    accessibilityLevelLabel(l10n, raw);

String _crowdLabel(AppLocalizations l10n, String raw) =>
    crowdLevelLabel(l10n, raw);

String _flagLabel(AppLocalizations l10n, String flag) {
  switch (flag) {
    case 'romantic':
      return l10n.flagRomantic;
    case 'familyFriendly':
      return l10n.flagFamilyFriendly;
    case 'kidFriendly':
      return l10n.flagKidFriendly;
    case 'petFriendly':
      return l10n.flagPetFriendly;
    case 'wheelchairFriendly':
      return l10n.flagWheelchairFriendly;
    case 'photographySpot':
      return l10n.flagPhotographySpot;
    case 'sunsetSpot':
      return l10n.flagSunsetSpot;
    case 'sunriseSpot':
      return l10n.flagSunriseSpot;
    case 'indoor':
      return l10n.flagIndoor;
    case 'outdoor':
      return l10n.flagOutdoor;
    case 'rainyDaySuitable':
      return l10n.flagRainyDaySuitable;
    default:
      return _humanizeEnum(flag);
  }
}

String _facilityGroupLabel(AppLocalizations l10n, String raw) {
  switch (raw.toUpperCase()) {
    case 'GENERAL':
      return l10n.facilityGroupGeneral;
    case 'WELLNESS':
      return l10n.facilityGroupWellness;
    case 'BUSINESS':
      return l10n.facilityGroupBusiness;
    case 'FOOD':
      return l10n.facilityGroupFood;
    case 'OUTDOOR':
      return l10n.facilityGroupOutdoor;
    case 'FAMILY':
      return l10n.facilityGroupFamily;
    case 'ACCESSIBILITY':
      return l10n.facilityGroupAccessibility;
    default:
      return _humanizeEnum(raw);
  }
}
