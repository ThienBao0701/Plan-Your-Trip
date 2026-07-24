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
import '../../shared/widgets/glass_widgets.dart';
import '../expenses/expenses_screen.dart';
import '../places/place_detail_screen.dart';
import 'hotel_room_selection_screen.dart';
import 'hotel_utils.dart';

class HotelSearchScreen extends StatefulWidget {
  final DateTime? today;
  final HotelStayCriteria? initialCriteria;

  const HotelSearchScreen({
    super.key,
    this.today,
    this.initialCriteria,
  });

  @override
  State<HotelSearchScreen> createState() => _HotelSearchScreenState();
}

class _HotelSearchScreenState extends State<HotelSearchScreen> {
  late HotelStayCriteria _criteria;
  final _destination = TextEditingController();
  bool _initialized = false;
  bool _submitting = false;

  DateTime get _today =>
      hotelDateOnly(widget.today ?? AppScope.of(context).now());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final app = AppScope.of(context);
    final upcoming = _nextTrip(app.trips, widget.today ?? app.now());
    _criteria = widget.initialCriteria ??
        defaultHotelCriteria(today: widget.today ?? app.now(), trip: upcoming);
    _destination.text = _criteria.destination;
    _initialized = true;
  }

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (!_initialized) {
      return const Scaffold(body: Center(child: OceanLoadingState()));
    }
    final hotels = filterHotels(accommodationPlaces(app.places), _criteria);
    final trip =
        _criteria.tripId == null ? null : app.tripById(_criteria.tripId!);

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.hotelsTitle),
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
                    _HotelHero(
                      title: l10n.hotelsTitle,
                      subtitle: l10n.hotelsSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OceanGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (trip != null) ...[
                            OceanStatusPill(
                              label: l10n.hotelsTripPrefillLabel(trip.title),
                              icon: Icons.map_rounded,
                              color: AppColors.ocean,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          TextField(
                            key: const Key('hotel-destination-field'),
                            controller: _destination,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              labelText: l10n.hotelsDestinationLabel,
                              hintText: l10n.hotelsDestinationHint,
                              prefixIcon: const Icon(Icons.search_rounded),
                            ),
                            onChanged: (value) => setState(() {
                              _criteria =
                                  _criteria.copyWith(destination: value);
                            }),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _CriteriaControls(
                            criteria: _criteria,
                            onChanged: (criteria) => setState(() {
                              _criteria = criteria;
                              _destination.text = criteria.destination;
                            }),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OceanGlassSurface(
                            blur: 0,
                            color: AppColors.paleCyan,
                            child: Text(
                              l10n.hotelsLocalPreviewMessage,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          OceanPrimaryButton(
                            key: const Key('hotel-search-submit'),
                            label: l10n.hotelsSearchAction,
                            icon: Icons.hotel_rounded,
                            semanticLabel: l10n.hotelsSearchSemantic,
                            onPressed: _submitting ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.hotelsResultCount(hotels.length),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearDestination,
                          icon: const Icon(Icons.filter_list_off_rounded),
                          label: Text(l10n.searchClearFilters),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (hotels.isEmpty)
                      OceanEmptyState(
                        title: l10n.hotelsEmptyTitle,
                        message: l10n.hotelsEmptyMessage,
                        actionLabel: l10n.searchClearFilters,
                        onAction: _clearDestination,
                      )
                    else
                      _HotelResults(
                        hotels: hotels,
                        criteria: _criteria,
                        onDetail: _openDetail,
                        onRooms: _openRooms,
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

  void _clearDestination() {
    setState(() {
      _destination.clear();
      _criteria = _criteria.copyWith(destination: '');
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final error = validateHotelCriteria(_criteria, today: _today);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_criteriaErrorText(l10n, error))),
      );
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  void _openDetail(Place hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: hotel)),
    );
  }

  void _openRooms(Place hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotelRoomSelectionScreen(
          hotel: hotel,
          initialCriteria: _criteria,
          today: widget.today,
        ),
      ),
    );
  }

  void _bookmark(Place hotel) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final wasSaved = app.isPlaceSaved(hotel.id);
    final outcome =
        wasSaved ? app.removeSavedPlace(hotel.id) : app.savePlace(hotel.id);
    final message = switch (outcome) {
      SavedPlaceActionResult.success => wasSaved
          ? l10n.savedPlacesRemovedPlace(hotel.name)
          : l10n.savedPlacesSavedMessage(hotel.name),
      SavedPlaceActionResult.duplicate =>
        l10n.savedPlacesAlreadySavedMessage(hotel.name),
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

  Trip? _nextTrip(List<Trip> trips, DateTime today) {
    final current = hotelDateOnly(today);
    final candidates = trips
        .where((trip) => !hotelDateOnly(trip.endDate).isBefore(current))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return candidates.isEmpty ? null : candidates.first;
  }

  String _criteriaErrorText(
    AppLocalizations l10n,
    HotelCriteriaError error,
  ) {
    switch (error) {
      case HotelCriteriaError.pastCheckIn:
        return l10n.hotelsValidationPastCheckIn;
      case HotelCriteriaError.checkOutNotAfterCheckIn:
        return l10n.hotelsValidationCheckout;
      case HotelCriteriaError.invalidAdults:
        return l10n.hotelsValidationAdults;
      case HotelCriteriaError.invalidChildren:
        return l10n.hotelsValidationChildren;
      case HotelCriteriaError.invalidExtraBeds:
        return l10n.hotelsValidationExtraBeds;
    }
  }
}

class _HotelHero extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HotelHero({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => OceanGlassCard(
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.ocean.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: const Icon(
                Icons.hotel_rounded,
                color: AppColors.ocean,
                size: AppIconSizes.xl,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
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

class _CriteriaControls extends StatelessWidget {
  final HotelStayCriteria criteria;
  final ValueChanged<HotelStayCriteria> onChanged;

  const _CriteriaControls({
    required this.criteria,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _CriteriaTile(
          key: const Key('hotel-checkin-next'),
          icon: Icons.login_rounded,
          label: l10n.hotelsCheckInLabel,
          value: date.format(criteria.checkIn),
          onTap: () => onChanged(criteria.copyWith(
            checkIn: criteria.checkIn.add(const Duration(days: 1)),
            checkOut: criteria.checkOut
                    .isAfter(criteria.checkIn.add(const Duration(days: 1)))
                ? criteria.checkOut
                : criteria.checkIn.add(const Duration(days: 2)),
            tripId: null,
          )),
        ),
        _CriteriaTile(
          key: const Key('hotel-checkout-next'),
          icon: Icons.logout_rounded,
          label: l10n.hotelsCheckOutLabel,
          value: date.format(criteria.checkOut),
          onTap: () => onChanged(criteria.copyWith(
            checkOut: criteria.checkOut.add(const Duration(days: 1)),
            tripId: null,
          )),
        ),
        _CounterTile(
          label: l10n.hotelsAdultsLabel,
          value: criteria.adults,
          incrementKey: const Key('hotel-adults-increment'),
          decrementKey: const Key('hotel-adults-decrement'),
          onIncrement: () => onChanged(criteria.copyWith(
            adults: criteria.adults + 1,
            tripId: null,
          )),
          onDecrement: () => onChanged(criteria.copyWith(
            adults: (criteria.adults - 1).clamp(1, 20),
            tripId: null,
          )),
        ),
        _CounterTile(
          label: l10n.hotelsChildrenLabel,
          value: criteria.children,
          incrementKey: const Key('hotel-children-increment'),
          decrementKey: const Key('hotel-children-decrement'),
          onIncrement: () => onChanged(criteria.copyWith(
            children: criteria.children + 1,
            tripId: null,
          )),
          onDecrement: () => onChanged(criteria.copyWith(
            children: (criteria.children - 1).clamp(0, 10),
            tripId: null,
          )),
        ),
      ],
    );
  }
}

class _CriteriaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _CriteriaTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 210,
        child: OceanGlassSurface(
          blur: 0,
          color: AppColors.surfaceOverlay,
          onTap: onTap,
          child: Row(
            children: [
              Icon(icon, color: AppColors.ocean, size: AppIconSizes.sm),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _CounterTile extends StatelessWidget {
  final String label;
  final int value;
  final Key incrementKey;
  final Key decrementKey;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CounterTile({
    required this.label,
    required this.value,
    required this.incrementKey,
    required this.decrementKey,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 210,
        child: OceanGlassSurface(
          blur: 0,
          color: AppColors.surfaceOverlay,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      '$value',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: decrementKey,
                tooltip: '$label -',
                onPressed: onDecrement,
                icon: const Icon(Icons.remove_rounded),
              ),
              IconButton(
                key: incrementKey,
                tooltip: '$label +',
                onPressed: onIncrement,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      );
}

class _HotelResults extends StatelessWidget {
  final List<Place> hotels;
  final HotelStayCriteria criteria;
  final ValueChanged<Place> onDetail;
  final ValueChanged<Place> onRooms;
  final ValueChanged<Place> onBookmark;

  const _HotelResults({
    required this.hotels,
    required this.criteria,
    required this.onDetail,
    required this.onRooms,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AppBreakpoints.tablet;
          if (wide) {
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final hotel in hotels)
                  SizedBox(
                    width: (constraints.maxWidth - AppSpacing.md) / 2,
                    child: _HotelCard(
                      hotel: hotel,
                      criteria: criteria,
                      onDetail: () => onDetail(hotel),
                      onRooms: () => onRooms(hotel),
                      onBookmark: () => onBookmark(hotel),
                    ),
                  ),
              ],
            );
          }
          return Column(
            children: [
              for (final hotel in hotels)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _HotelCard(
                    hotel: hotel,
                    criteria: criteria,
                    onDetail: () => onDetail(hotel),
                    onRooms: () => onRooms(hotel),
                    onBookmark: () => onBookmark(hotel),
                  ),
                ),
            ],
          );
        },
      );
}

class _HotelCard extends StatelessWidget {
  final Place hotel;
  final HotelStayCriteria criteria;
  final VoidCallback onDetail;
  final VoidCallback onRooms;
  final VoidCallback onBookmark;

  const _HotelCard({
    required this.hotel,
    required this.criteria,
    required this.onDetail,
    required this.onRooms,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final saved = app.isPlaceSaved(hotel.id);
    final bookmarkLabel = saved
        ? l10n.savedPlacesRemoveSemantic(hotel.name)
        : l10n.savedPlacesSaveSemantic(hotel.name);
    final rooms = availableRoomsFor(hotel, criteria);
    final price =
        rooms.map((room) => room.priceFrom).whereType<double>().fold<double?>(
            null,
            (min, value) => min == null
                ? value
                : value < min
                    ? value
                    : min);
    return OceanGlassCard(
      onTap: onDetail,
      semanticLabel: l10n.hotelCardSemantic(hotel.name),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Image.network(
              hotel.imageUrl,
              height: 180,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: AppColors.paleCyan,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.hotel_rounded,
                  color: AppColors.ocean,
                  size: AppIconSizes.xl,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  hotel.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (hotel.rating > 0)
                OceanStatusPill(
                  label: hotel.rating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  color: AppColors.ocean,
                ),
              Semantics(
                button: true,
                toggled: saved,
                label: bookmarkLabel,
                child: IconButton(
                  tooltip: bookmarkLabel,
                  onPressed: onBookmark,
                  icon: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: saved ? AppColors.ocean : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${hotel.locationName} · ${hotel.city}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (hotel.hotelDetail?.starRating != null)
                OceanStatusPill(
                  label: l10n.hotelStars(hotel.hotelDetail!.starRating!),
                  icon: Icons.star_border_rounded,
                ),
              if (price != null)
                OceanStatusPill(
                  label: l10n.hotelFromPrice(
                    formatMoney(context, price, 'VND'),
                  ),
                  icon: Icons.payments_rounded,
                  color: AppColors.turquoise600,
                ),
              OceanStatusPill(
                label: l10n.hotelAvailableRooms(rooms.length),
                icon: Icons.meeting_room_rounded,
                color:
                    rooms.isEmpty ? AppColors.textSecondary : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hotel.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OceanSecondaryButton(
                  key: Key('hotel-detail-${hotel.id}'),
                  label: l10n.placeHighlightsTitle,
                  icon: Icons.info_outline_rounded,
                  onPressed: onDetail,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OceanPrimaryButton(
                  key: Key('hotel-rooms-${hotel.id}'),
                  label: l10n.hotelViewRoomsAction,
                  icon: Icons.king_bed_rounded,
                  semanticLabel:
                      l10n.hotelCheckAvailabilitySemantic(hotel.name),
                  onPressed: onRooms,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
