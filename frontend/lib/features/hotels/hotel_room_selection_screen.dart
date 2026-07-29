import 'dart:async';

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
import '../auth/login_screen.dart';
import '../expenses/expenses_screen.dart';
import 'hotel_booking_review_screen.dart';
import 'hotel_utils.dart';

class HotelRoomSelectionScreen extends StatefulWidget {
  final Place hotel;
  final HotelStayCriteria initialCriteria;
  final DateTime? today;
  final DateTime? quoteTime;

  const HotelRoomSelectionScreen({
    super.key,
    required this.hotel,
    required this.initialCriteria,
    this.today,
    this.quoteTime,
  });

  @override
  State<HotelRoomSelectionScreen> createState() =>
      _HotelRoomSelectionScreenState();
}

class _HotelRoomSelectionScreenState extends State<HotelRoomSelectionScreen> {
  late HotelStayCriteria _criteria;
  int? _selectedRoomId;
  int? _selectedRatePlanId;

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // Real Mode: fetch real backend availability instead of the demo dataset.
    // Everything below (the demo path) stays byte-for-byte unchanged.
    if (!app.demoMode) {
      return _RealHotelAvailabilityView(
        hotel: widget.hotel,
        initialCriteria: _criteria,
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final rooms = availableRoomsFor(widget.hotel, _criteria);
    final selectedRoom = _selectedRoom(rooms);
    final selectedRatePlan = _selectedRatePlan(selectedRoom);
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.hotelRoomsTitle),
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
                    _CriteriaSummary(
                      hotel: widget.hotel,
                      criteria: _criteria,
                      onChange: _changeCriteria,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.hotelAvailableRoomsTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (rooms.isEmpty)
                      OceanEmptyState(
                        title: l10n.hotelNoAvailabilityTitle,
                        message: l10n.hotelNoAvailabilityMessage,
                      )
                    else
                      for (final room in rooms)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _RoomCard(
                            room: room,
                            selected: _selectedRoomId == room.id,
                            onTap: () => setState(() {
                              _selectedRoomId = room.id;
                              _selectedRatePlanId = null;
                            }),
                          ),
                        ),
                    if (selectedRoom != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.hotelRatePlansTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final plan in selectedRoom.ratePlans)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _RatePlanCard(
                            plan: plan,
                            selected: _selectedRatePlanId == plan.ratePlanId,
                            onTap: plan.eligible
                                ? () => setState(() {
                                      _selectedRatePlanId = plan.ratePlanId;
                                    })
                                : null,
                          ),
                        ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    OceanPrimaryButton(
                      key: const Key('hotel-rate-continue'),
                      label: l10n.hotelContinueReviewAction,
                      icon: Icons.receipt_long_rounded,
                      semanticLabel: l10n.hotelContinueReviewSemantic,
                      onPressed: selectedRoom != null &&
                              selectedRatePlan != null &&
                              selectedRatePlan.eligible
                          ? () => _openReview(selectedRoom, selectedRatePlan)
                          : null,
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

  HotelRoom? _selectedRoom(List<HotelRoom> rooms) {
    for (final room in rooms) {
      if (room.id == _selectedRoomId) return room;
    }
    return null;
  }

  HotelRatePlan? _selectedRatePlan(HotelRoom? room) {
    if (room == null) return null;
    for (final plan in room.ratePlans) {
      if (plan.ratePlanId == _selectedRatePlanId) return plan;
    }
    return null;
  }

  void _changeCriteria(HotelStayCriteria criteria) {
    setState(() {
      _criteria = criteria;
      _selectedRoomId = null;
      _selectedRatePlanId = null;
    });
  }

  void _openReview(HotelRoom room, HotelRatePlan plan) {
    final app = AppScope.of(context);
    final generatedAt = widget.quoteTime ?? app.now();
    final quote = buildLocalHotelQuote(
      hotel: widget.hotel,
      room: room,
      ratePlan: plan,
      criteria: _criteria,
      generatedAt: generatedAt,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotelBookingReviewScreen(
          hotel: widget.hotel,
          room: room,
          ratePlan: plan,
          criteria: _criteria,
          quote: quote,
        ),
      ),
    );
  }
}

class _CriteriaSummary extends StatelessWidget {
  final Place hotel;
  final HotelStayCriteria criteria;
  final ValueChanged<HotelStayCriteria> onChange;

  const _CriteriaSummary({
    required this.hotel,
    required this.criteria,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hotel.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${date.format(criteria.checkIn)} - ${date.format(criteria.checkOut)} · ${l10n.hotelNights(criteria.nights)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label:
                    l10n.hotelGuestSummary(criteria.adults, criteria.children),
                icon: Icons.group_rounded,
              ),
              OceanStatusPill(
                label: l10n.hotelOneRoomOnly,
                icon: Icons.meeting_room_rounded,
                color: AppColors.turquoise600,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OceanSecondaryButton(
                key: const Key('hotel-criteria-increment-adults'),
                label: l10n.hotelAddAdultAction,
                icon: Icons.person_add_alt_rounded,
                fullWidth: false,
                onPressed: () => onChange(criteria.copyWith(
                  adults: criteria.adults + 1,
                  tripId: null,
                )),
              ),
              OceanSecondaryButton(
                key: const Key('hotel-criteria-next-night'),
                label: l10n.hotelExtendStayAction,
                icon: Icons.nights_stay_rounded,
                fullWidth: false,
                onPressed: () => onChange(criteria.copyWith(
                  checkOut: criteria.checkOut.add(const Duration(days: 1)),
                  tripId: null,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final HotelRoom room;
  final bool selected;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      key: Key('room-card-${room.id}'),
      onTap: onTap,
      semanticLabel: l10n.hotelRoomCardSemantic(room.roomName),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final image = _RoomImage(room: room, compact: compact);
          final details = _RoomDetails(room: room, selected: selected);
          return compact
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
                );
        },
      ),
    );
  }
}

class _RoomImage extends StatelessWidget {
  final HotelRoom room;
  final bool compact;

  const _RoomImage({required this.room, required this.compact});

  @override
  Widget build(BuildContext context) {
    final imageUrl = room.coverImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _fallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Image.network(
        imageUrl,
        width: compact ? double.infinity : 150,
        height: compact ? 170 : 150,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        width: compact ? double.infinity : 150,
        height: compact ? 170 : 150,
        decoration: BoxDecoration(
          color: AppColors.paleCyan,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.king_bed_rounded,
          color: AppColors.ocean,
          size: AppIconSizes.xl,
        ),
      );
}

class _RoomDetails extends StatelessWidget {
  final HotelRoom room;
  final bool selected;

  const _RoomDetails({required this.room, required this.selected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                room.roomName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.ocean),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(room.description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
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
        const SizedBox(height: AppSpacing.sm),
        if (room.priceFrom != null)
          Text(
            l10n.hotelFromPrice(formatMoney(context, room.priceFrom!, 'VND')),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.ocean),
          ),
        if (room.amenities.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            room.amenities.join(' · '),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

class _RatePlanCard extends StatelessWidget {
  final HotelRatePlan plan;
  final bool selected;
  final VoidCallback? onTap;

  const _RatePlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = onTap != null;
    return OceanGlassSurface(
      key: Key('rate-plan-${plan.ratePlanId}'),
      blur: 0,
      color: selected
          ? AppColors.ocean.withValues(alpha: .10)
          : enabled
              ? AppColors.surfaceOverlay
              : AppColors.mist,
      border: Border.all(
        color: selected ? AppColors.ocean : AppColors.divider,
      ),
      onTap: onTap,
      semanticLabel: l10n.hotelRatePlanSemantic(plan.rateName),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.rateName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: AppColors.ocean),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: mealPlanLabel(l10n, plan.mealPlan),
                icon: Icons.restaurant_rounded,
              ),
              OceanStatusPill(
                label: cancellationPolicyLabel(
                  l10n,
                  plan.cancellationPolicyType,
                ),
                icon: Icons.policy_rounded,
                color: plan.refundable ? AppColors.success : AppColors.coral,
              ),
            ],
          ),
          if (plan.finalNightlyRate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              formatMoney(context, plan.finalNightlyRate!, 'VND'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.ocean),
            ),
          ],
          if (plan.policySummary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(plan.policySummary,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (!plan.eligible && plan.reason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            OceanRecoverableErrorState(message: plan.reason!),
          ],
        ],
      ),
    );
  }
}

String roomTypeLabel(AppLocalizations l10n, RoomType type) {
  switch (type) {
    case RoomType.standard:
      return l10n.roomTypeStandard;
    case RoomType.superior:
      return l10n.roomTypeSuperior;
    case RoomType.deluxe:
      return l10n.roomTypeDeluxe;
    case RoomType.premier:
      return l10n.roomTypePremier;
    case RoomType.executive:
      return l10n.roomTypeExecutive;
    case RoomType.suite:
      return l10n.roomTypeSuite;
    case RoomType.family:
      return l10n.roomTypeFamily;
    case RoomType.villa:
      return l10n.roomTypeVilla;
    case RoomType.bungalow:
      return l10n.roomTypeBungalow;
  }
}

String bedTypeLabel(AppLocalizations l10n, BedType type, int count) {
  final label = switch (type) {
    BedType.single => l10n.bedTypeSingle,
    BedType.double => l10n.bedTypeDouble,
    BedType.twin => l10n.bedTypeTwin,
    BedType.queen => l10n.bedTypeQueen,
    BedType.king => l10n.bedTypeKing,
    BedType.sofaBed => l10n.bedTypeSofaBed,
    BedType.bunk => l10n.bedTypeBunk,
  };
  return count <= 1 ? label : l10n.hotelBedCount(count, label);
}

String mealPlanLabel(AppLocalizations l10n, MealPlanType type) {
  switch (type) {
    case MealPlanType.roomOnly:
      return l10n.mealPlanRoomOnly;
    case MealPlanType.breakfast:
      return l10n.mealPlanBreakfast;
    case MealPlanType.halfBoard:
      return l10n.mealPlanHalfBoard;
    case MealPlanType.fullBoard:
      return l10n.mealPlanFullBoard;
    case MealPlanType.allInclusive:
      return l10n.mealPlanAllInclusive;
  }
}

String cancellationPolicyLabel(
  AppLocalizations l10n,
  CancellationPolicyType type,
) {
  switch (type) {
    case CancellationPolicyType.freeCancellation:
      return l10n.cancellationFree;
    case CancellationPolicyType.partiallyRefundable:
      return l10n.cancellationPartial;
    case CancellationPolicyType.nonRefundable:
      return l10n.cancellationNonRefundable;
    case CancellationPolicyType.custom:
      return l10n.cancellationCustom;
  }
}

/// Real Mode availability view: fetches real bookable rooms + prices from
/// `GET /api/places/{placeId}/availability` for the selected hotel place and
/// stay criteria. Renders only backend-confirmed fields — nothing synthesized.
/// The demo booking-review continuation is intentionally not wired here (the
/// backend checkout is offline/mocked); this is an honest availability view.
class _RealHotelAvailabilityView extends StatefulWidget {
  final Place hotel;
  final HotelStayCriteria initialCriteria;

  const _RealHotelAvailabilityView({
    required this.hotel,
    required this.initialCriteria,
  });

  @override
  State<_RealHotelAvailabilityView> createState() =>
      _RealHotelAvailabilityViewState();
}

class _RealHotelAvailabilityViewState
    extends State<_RealHotelAvailabilityView> {
  late HotelStayCriteria _criteria;

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load({bool refresh = false}) {
    return AppScope.of(context).loadRealAvailability(
      placeId: widget.hotel.id,
      checkIn: _criteria.checkIn,
      checkOut: _criteria.checkOut,
      adults: _criteria.adults,
      children: _criteria.children,
      refresh: refresh,
    );
  }

  Future<void> _refresh() => _load(refresh: true);

  void _changeCriteria(HotelStayCriteria criteria) {
    setState(() => _criteria = criteria);
    _load();
  }

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
        title: Text(l10n.hotelRoomsTitle),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CriteriaSummary(
                        hotel: widget.hotel,
                        criteria: _criteria,
                        onChange: _changeCriteria,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _content(context, app, l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AppState app, AppLocalizations l10n) {
    final loadingForThisHotel = (app.realAvailabilityLoading) &&
        app.realAvailabilityPlaceId == widget.hotel.id;
    if (loadingForThisHotel && app.realAvailability == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: OceanLoadingState(message: l10n.availabilityRealLoadingMessage),
      );
    }

    final error = app.realAvailabilityError;
    if (error != null && app.realAvailability == null) {
      if (error == HotelAvailabilityOutcome.sessionExpired) {
        return OceanEmptyState(
          key: const Key('real-availability-session-expired'),
          title: l10n.tripsRealSessionExpiredTitle,
          message: l10n.tripsRealSessionExpiredMessage,
          actionLabel: l10n.tripsRealSignInAction,
          onAction: _reauth,
        );
      }
      final message = switch (error) {
        HotelAvailabilityOutcome.forbidden =>
          l10n.tripRealPermissionDeniedMessage,
        HotelAvailabilityOutcome.invalidDates =>
          l10n.availabilityRealInvalidDatesMessage,
        _ => l10n.availabilityRealErrorMessage,
      };
      return OceanRecoverableErrorState(
        key: const Key('real-availability-error'),
        message: message,
        onReload: () => _load(refresh: true),
      );
    }

    final result = app.realAvailability;
    final rooms = result?.availableRooms ?? const <AvailableRoomRecord>[];
    if (rooms.isEmpty) {
      return OceanEmptyState(
        key: const Key('real-availability-empty'),
        title: l10n.hotelNoAvailabilityTitle,
        message: l10n.hotelNoAvailabilityMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.hotelAvailableRoomsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Text(
          l10n.availabilityRealRoomCount(rooms.length),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final room in rooms)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _RealAvailableRoomCard(room: room),
          ),
      ],
    );
  }
}

/// Renders one real [AvailableRoomRecord]. Missing values are hidden, never
/// synthesized. The availability DTO carries no currency code, so prices use
/// the app's default VND formatting (documented as a known limitation).
class _RealAvailableRoomCard extends StatelessWidget {
  final AvailableRoomRecord room;

  const _RealAvailableRoomCard({required this.room});

  static String _humanizeToken(String raw) {
    final cleaned = raw.replaceAll('_', ' ').trim().toLowerCase();
    if (cleaned.isEmpty) return raw;
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pills = <Widget>[
      if (room.roomType != null && room.roomType!.isNotEmpty)
        OceanStatusPill(
          label: _humanizeToken(room.roomType!),
          icon: Icons.hotel_class_rounded,
        ),
      if (room.bedType != null && room.bedType!.isNotEmpty)
        OceanStatusPill(
          label: _humanizeToken(room.bedType!),
          icon: Icons.bed_rounded,
          color: AppColors.turquoise600,
        ),
      if (room.maxGuests != null && room.maxGuests! > 0)
        OceanStatusPill(
          label: l10n.hotelMaxGuests(room.maxGuests!),
          icon: Icons.group_rounded,
          color: AppColors.ocean400,
        ),
      if (room.roomSizeSqm != null && room.roomSizeSqm! > 0)
        OceanStatusPill(
          label: l10n.hotelRoomSize(room.roomSizeSqm!.round()),
          icon: Icons.square_foot_rounded,
          color: AppColors.violet,
        ),
    ];

    final badges = <Widget>[
      if (room.breakfastIncluded)
        OceanStatusPill(
          label: l10n.hotelBreakfastIncluded,
          icon: Icons.free_breakfast_rounded,
          color: AppColors.ocean,
        ),
      if (room.freeCancellation)
        OceanStatusPill(
          label: l10n.availabilityRealFreeCancellation,
          icon: Icons.verified_rounded,
          color: AppColors.turquoise600,
        ),
      if (room.instantConfirmation)
        OceanStatusPill(
          label: l10n.availabilityRealInstantConfirmation,
          icon: Icons.bolt_rounded,
          color: AppColors.ocean400,
        ),
    ];

    return OceanGlassCard(
      key: Key('real-room-card-${room.roomId}'),
      semanticLabel: l10n.hotelRoomCardSemantic(room.roomName),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final image =
              _RealRoomImage(url: room.coverImageUrl, compact: compact);
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.roomName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (pills.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: pills,
                ),
              ],
              if (badges.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: badges,
                ),
              ],
              if (room.pricePerNight != null) ...[
                const SizedBox(height: AppSpacing.sm),
                if (room.hasDiscount)
                  Text(
                    l10n.availabilityRealOriginalPrice(
                      formatMoney(context, room.originalPricePerNight!, 'VND'),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textTertiary,
                        ),
                  ),
                Text(
                  l10n.availabilityRealPerNight(
                    formatMoney(context, room.pricePerNight!, 'VND'),
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.ocean),
                ),
                if (room.totalPrice != null && room.nights > 0)
                  Text(
                    l10n.availabilityRealTotalForNights(
                      formatMoney(context, room.totalPrice!, 'VND'),
                      room.nights,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
              if (room.amenities.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  room.amenities.join(' · '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          );
          return compact
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
                );
        },
      ),
    );
  }
}

/// Image for a real room card — placeholder when the backend has no cover.
class _RealRoomImage extends StatelessWidget {
  final String? url;
  final bool compact;

  const _RealRoomImage({required this.url, required this.compact});

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
          width: compact ? double.infinity : 150,
          height: compact ? 170 : 150,
          decoration: BoxDecoration(
            color: AppColors.paleCyan,
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.king_bed_rounded,
            color: AppColors.ocean,
            size: AppIconSizes.xl,
          ),
        );
    if (url == null || url!.isEmpty) return fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Image.network(
        url!,
        width: compact ? double.infinity : 150,
        height: compact ? 170 : 150,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }
}
