import 'package:flutter/material.dart';

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
import 'hotel_room_selection_screen.dart';

/// UI24 — Real Mode room detail + selection. Renders a single backend
/// [AvailableRoomRecord] (from the UI22 availability result — no re-fetch) and
/// loads the room's real, public rate plans (`GET /rooms/{id}/rate-plans`) for
/// the price breakdown, cancellation terms and eligibility. Selecting a room +
/// rate plan is client-side (the backend checkout is offline/mocked). Every
/// value comes from the backend; missing fields are hidden, never fabricated.
class RealRoomDetailScreen extends StatefulWidget {
  final Place hotel;
  final AvailableRoomRecord room;
  final HotelStayCriteria criteria;

  const RealRoomDetailScreen({
    super.key,
    required this.hotel,
    required this.room,
    required this.criteria,
  });

  @override
  State<RealRoomDetailScreen> createState() => _RealRoomDetailScreenState();
}

class _RealRoomDetailScreenState extends State<RealRoomDetailScreen> {
  int? _chosenRatePlanId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppScope.of(context);
      // Preselect the plan already chosen for this room, if any.
      if (app.selectedRoomId == widget.room.roomId) {
        setState(() => _chosenRatePlanId = app.selectedRatePlanId);
      }
      _loadRatePlans();
    });
  }

  Future<void> _loadRatePlans({bool refresh = false}) {
    return AppScope.of(context).loadRoomRatePlans(
      roomId: widget.room.roomId,
      checkIn: widget.criteria.checkIn,
      checkOut: widget.criteria.checkOut,
      adults: widget.criteria.adults,
      children: widget.criteria.children,
      extraBeds: widget.criteria.extraBeds,
      refresh: refresh,
    );
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

  void _confirmSelection() {
    AppScope.of(context)
        .selectRoom(widget.room.roomId, ratePlanId: _chosenRatePlanId);
    Navigator.of(context).maybePop();
  }

  List<String> _galleryUrls(AppState app) {
    // Prefer the room's real gallery from the (already-cached) UI23 hotel
    // detail; fall back to the availability cover image. No extra HTTP.
    final detail = app.getHydratedRealPlaceDetail(widget.hotel.id);
    final rooms = detail?.hotelDetailRich?.rooms;
    if (rooms != null) {
      for (final r in rooms) {
        if (r.id == widget.room.roomId) {
          final urls = <String>[
            if ((r.coverImageUrl ?? '').isNotEmpty) r.coverImageUrl!,
            ...r.galleryImages.where((u) => u.isNotEmpty),
          ];
          if (urls.isNotEmpty) return urls.toSet().toList();
        }
      }
    }
    final cover = widget.room.coverImageUrl;
    return (cover != null && cover.isNotEmpty) ? [cover] : const [];
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final room = widget.room;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(room.roomName),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => _loadRatePlans(refresh: true),
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
                      _RoomGallery(
                          urls: _galleryUrls(app), roomName: room.roomName),
                      const SizedBox(height: AppSpacing.lg),
                      _RoomInfoCard(room: room),
                      const SizedBox(height: AppSpacing.md),
                      _RoomPriceCard(room: room),
                      const SizedBox(height: AppSpacing.md),
                      _ratePlansSection(context, app, l10n),
                      const SizedBox(height: AppSpacing.lg),
                      OceanPrimaryButton(
                        key: const Key('real-room-select-action'),
                        label: l10n.roomSelectAction,
                        icon: Icons.check_circle_rounded,
                        semanticLabel: l10n.roomSelectSemantic(room.roomName),
                        onPressed: _confirmSelection,
                      ),
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

  Widget _ratePlansSection(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final loadingThisRoom = app.roomRatePlansLoading &&
        app.roomRatePlansRoomId == widget.room.roomId;
    final forThisRoom = app.roomRatePlansRoomId == widget.room.roomId;
    final error = forThisRoom ? app.roomRatePlansError : null;
    final plans = forThisRoom ? app.roomRatePlans : const <HotelRatePlan>[];

    Widget body;
    if (loadingThisRoom && plans.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: OceanLoadingState(message: l10n.roomRatePlansLoadingMessage),
      );
    } else if (error != null && plans.isEmpty) {
      if (error == RatePlanOutcome.sessionExpired) {
        body = OceanEmptyState(
          key: const Key('real-rate-plans-session-expired'),
          title: l10n.tripsRealSessionExpiredTitle,
          message: l10n.tripsRealSessionExpiredMessage,
          actionLabel: l10n.tripsRealSignInAction,
          onAction: _reauth,
        );
      } else {
        final message = error == RatePlanOutcome.invalidDates
            ? l10n.roomRatePlansInvalidDatesMessage
            : error == RatePlanOutcome.notFound
                ? l10n.roomRatePlansEmptyMessage
                : l10n.roomRatePlansErrorMessage;
        body = OceanRecoverableErrorState(
          key: const Key('real-rate-plans-error'),
          message: message,
          onReload: () => _loadRatePlans(refresh: true),
        );
      }
    } else if (plans.isEmpty) {
      body = OceanEmptyState(
        key: const Key('real-rate-plans-empty'),
        title: l10n.roomRatePlansEmptyTitle,
        message: l10n.roomRatePlansEmptyMessage,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final plan in plans)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RealRatePlanCard(
                plan: plan,
                selected: _chosenRatePlanId == plan.ratePlanId,
                onSelect: plan.eligible
                    ? () => setState(() => _chosenRatePlanId = plan.ratePlanId)
                    : null,
              ),
            ),
        ],
      );
    }

    return OceanGlassCard(
      key: const Key('real-rate-plans'),
      semanticLabel: l10n.roomRatePlansTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(l10n.roomRatePlansTitle,
                style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.sm),
          body,
        ],
      ),
    );
  }
}

String humanizeRoomToken(String raw) {
  final cleaned = raw.replaceAll('_', ' ').trim().toLowerCase();
  if (cleaned.isEmpty) return raw;
  return cleaned
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _RoomGallery extends StatefulWidget {
  final List<String> urls;
  final String roomName;

  const _RoomGallery({required this.urls, required this.roomName});

  @override
  State<_RoomGallery> createState() => _RoomGalleryState();
}

class _RoomGalleryState extends State<_RoomGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.urls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        child: _fallback(keyed: true),
      );
    }
    return Semantics(
      label: l10n.roomDetailImageSemantic(widget.roomName),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => Image.network(
                  widget.urls[i],
                  key: i == 0 ? const Key('real-room-detail-image') : null,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => _fallback(keyed: i == 0),
                ),
              ),
            ),
            if (widget.urls.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.urls.length; i++)
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

  Widget _fallback({required bool keyed}) => Container(
        key: keyed ? const Key('real-room-detail-image-fallback') : null,
        height: 280,
        color: AppColors.paleCyan,
        alignment: Alignment.center,
        child: const Icon(
          Icons.king_bed_rounded,
          color: AppColors.ocean,
          size: AppIconSizes.xl,
        ),
      );
}

class _RoomInfoCard extends StatelessWidget {
  final AvailableRoomRecord room;

  const _RoomInfoCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pills = <Widget>[
      if ((room.roomType ?? '').isNotEmpty)
        OceanStatusPill(
          label: humanizeRoomToken(room.roomType!),
          icon: Icons.hotel_class_rounded,
        ),
      if ((room.bedType ?? '').isNotEmpty)
        OceanStatusPill(
          label: room.bedCount != null && room.bedCount! > 1
              ? l10n.roomBedConfig(
                  room.bedCount!, humanizeRoomToken(room.bedType!))
              : humanizeRoomToken(room.bedType!),
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
    final occupancy = <String>[
      if (room.maxAdults != null && room.maxAdults! > 0)
        l10n.roomOccupancyAdults(room.maxAdults!),
      if (room.maxChildren != null && room.maxChildren! > 0)
        l10n.roomOccupancyChildren(room.maxChildren!),
    ];

    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(room.roomName, style: theme.textTheme.titleLarge),
          if ((room.roomCode ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(l10n.roomCodeLabel(room.roomCode!),
                style: theme.textTheme.bodySmall),
          ],
          if (pills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: pills),
          ],
          if (badges.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: badges),
          ],
          if (occupancy.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.roomOccupancyTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(occupancy.join(' · '), style: theme.textTheme.bodyMedium),
          ],
          if (room.amenities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.placeAmenitiesTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [for (final a in room.amenities) Chip(label: Text(a))],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoomPriceCard extends StatelessWidget {
  final AvailableRoomRecord room;

  const _RoomPriceCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (room.pricePerNight == null) return const SizedBox.shrink();
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.roomPriceTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          if (room.hasDiscount)
            Text(
              l10n.availabilityRealOriginalPrice(
                formatMoney(context, room.originalPricePerNight!, 'VND'),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: AppColors.textTertiary,
              ),
            ),
          Text(
            l10n.availabilityRealPerNight(
              formatMoney(context, room.pricePerNight!, 'VND'),
            ),
            style:
                theme.textTheme.titleMedium?.copyWith(color: AppColors.ocean),
          ),
          if (room.totalPrice != null && room.nights > 0)
            Text(
              l10n.availabilityRealTotalForNights(
                formatMoney(context, room.totalPrice!, 'VND'),
                room.nights,
              ),
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _RealRatePlanCard extends StatelessWidget {
  final HotelRatePlan plan;
  final bool selected;
  final VoidCallback? onSelect;

  const _RealRatePlanCard({
    required this.plan,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final enabled = onSelect != null;
    return OceanGlassSurface(
      key: Key('real-rate-plan-${plan.ratePlanId}'),
      blur: 0,
      color: selected
          ? AppColors.ocean.withValues(alpha: .10)
          : enabled
              ? AppColors.surfaceOverlay
              : AppColors.mist,
      border: Border.all(
        color: selected ? AppColors.ocean : AppColors.divider,
      ),
      onTap: onSelect,
      semanticLabel: selected
          ? l10n.roomRatePlanSelectedSemantic(plan.rateName)
          : l10n.roomRatePlanSemantic(plan.rateName),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.rateName, style: theme.textTheme.titleMedium),
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
                label: plan.refundable
                    ? l10n.ratePlanRefundable
                    : l10n.ratePlanNonRefundable,
                icon: Icons.policy_rounded,
                color: plan.refundable ? AppColors.success : AppColors.coral,
              ),
            ],
          ),
          if (plan.hasBreakdown) ...[
            const SizedBox(height: AppSpacing.sm),
            if (plan.finalNightlyRate != null)
              Text(
                l10n.ratePlanFinalNightly(
                  formatMoney(context, plan.finalNightlyRate!, 'VND'),
                ),
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.ocean),
              ),
            if (plan.baseNightlyRate != null &&
                plan.baseNightlyRate != plan.finalNightlyRate)
              Text(
                l10n.ratePlanBaseNightly(
                  formatMoney(context, plan.baseNightlyRate!, 'VND'),
                ),
                style: theme.textTheme.bodySmall,
              ),
            if (plan.staySubtotal != null && plan.nights > 0)
              Text(
                l10n.ratePlanStaySubtotal(
                  formatMoney(context, plan.staySubtotal!, 'VND'),
                  plan.nights,
                ),
                style: theme.textTheme.bodyMedium,
              ),
          ],
          if (plan.policySummary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(plan.policySummary, style: theme.textTheme.bodySmall),
          ],
          if (!plan.eligible) ...[
            const SizedBox(height: AppSpacing.sm),
            OceanRecoverableErrorState(
              message: (plan.reason ?? '').isNotEmpty
                  ? plan.reason!
                  : l10n.roomRatePlanIneligible,
            ),
          ],
        ],
      ),
    );
  }
}
