import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_room_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../properties/widgets/partner_property_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_rooms_state.dart';
import 'widgets/partner_room_widgets.dart';

/// The Partner Rooms module — room-type inventory for one property.
///
/// ## Backend contract (verified in `backend-v1`/`develop` and live on :8081)
///
/// | Action | Endpoint |
/// |---|---|
/// | List | `GET /api/partner/rooms?hotelId={id}` (hotelId **required**) |
/// | Detail | `GET /api/partner/rooms/{roomId}` |
/// | List room | `PATCH /api/partner/rooms/{roomId}/activate` |
/// | Unlist room | `PATCH /api/partner/rooms/{roomId}/deactivate` |
///
/// **No create, no delete.** `PUT /api/partner/rooms/{roomId}` exists but is
/// deliberately not wired: `HotelRoomService.fill` overwrites all 20 fields and
/// `syncAmenities` deletes and rebuilds the amenity set, so a partial submit
/// would silently destroy data. An edit form needs the complete pre-filled
/// record, `roomCode` 409 handling and `availableQuantity <= quantity`
/// validation — its own phase, exactly as C2 deferred property editing.
///
/// ## Property context
///
/// The list endpoint's `hotelId` is mandatory, so this screen cannot render
/// anything without a selected property. It reads that selection from
/// [PartnerState] — the owner established in C2 — and never keeps its own copy,
/// never defaults to an arbitrary property, and reloads when the workspace
/// selection changes underneath it.
class PartnerRoomsScreen extends StatefulWidget {
  const PartnerRoomsScreen({super.key});

  @override
  State<PartnerRoomsScreen> createState() => _PartnerRoomsScreenState();
}

class _PartnerRoomsScreenState extends State<PartnerRoomsScreen> {
  PartnerRoomsState? _rooms;
  PartnerState? _partner;
  int? _syncedPropertyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    final rebind = !identical(partner, _partner);
    if (rebind) {
      _partner = partner;
      _rooms?.dispose();
      _rooms = PartnerRoomsState(api: partner.api);
      _syncedPropertyId = null;
    }

    // Follow the workspace's property selection. This is the only place the
    // two are joined: PartnerState owns the selection, this screen reacts.
    final selected = partner.selectedPropertyId;
    if (partner.isReady && (rebind || selected != _syncedPropertyId)) {
      _syncedPropertyId = selected;
      final rooms = _rooms!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) rooms.load(partner, selected);
      });
    }
  }

  @override
  void dispose() {
    _rooms?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final partner = _partner;
    final rooms = _rooms;
    if (partner == null || rooms == null) return;
    await rooms.load(partner, partner.selectedPropertyId);
  }

  @override
  Widget build(BuildContext context) {
    final partner = PartnerScope.of(context);
    final rooms = _rooms;

    if (!partner.isReady || rooms == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return AnimatedBuilder(
      animation: rooms,
      builder: (context, _) => _RoomsBody(
        partner: partner,
        rooms: rooms,
        onReload: _reload,
      ),
    );
  }
}

class _RoomsBody extends StatelessWidget {
  final PartnerState partner;
  final PartnerRoomsState rooms;
  final Future<void> Function() onReload;

  const _RoomsBody({
    required this.partner,
    required this.rooms,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Session/lifecycle failures speak the workspace's vocabulary.
    switch (rooms.status) {
      case PartnerRoomsStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
            status: PartnerWorkspaceStatus.unauthorized);
      case PartnerRoomsStatus.forbidden:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.forbidden,
          detail: rooms.errorMessage,
          onPrimaryAction: onReload,
        );
      case PartnerRoomsStatus.error:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.error,
          detail: rooms.errorMessage,
          onPrimaryAction: onReload,
        );
      default:
        break;
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.desktop;
    final detailOpen = rooms.openRoomId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoomsHeader(partner: partner, rooms: rooms, onReload: onReload),
        const SizedBox(height: AppSpacing.md),
        if (partner.properties.length > 1) ...[
          _PropertySwitcher(partner: partner, rooms: rooms),
          const SizedBox(height: AppSpacing.md),
        ],
        if (rooms.status == PartnerRoomsStatus.noProperties)
          OceanStateView(
            icon: Icons.apartment_outlined,
            title: l10n.partnerRoomsNoPropertiesTitle,
            message: l10n.partnerRoomsNoPropertiesMessage,
            semanticLabel: l10n.partnerRoomsNoPropertiesTitle,
          )
        else if (rooms.status == PartnerRoomsStatus.noPropertySelected)
          OceanStateView(
            icon: Icons.touch_app_outlined,
            title: l10n.partnerRoomsSelectPropertyTitle,
            message: l10n.partnerRoomsSelectPropertyMessage,
            semanticLabel: l10n.partnerRoomsSelectPropertyTitle,
          )
        else if (rooms.status == PartnerRoomsStatus.propertyUnavailable)
          OceanStateView(
            icon: Icons.error_outline_rounded,
            title: l10n.partnerRoomsPropertyUnavailableTitle,
            message: l10n.partnerRoomsPropertyUnavailableMessage,
            semanticLabel: l10n.partnerRoomsPropertyUnavailableTitle,
            actionLabel: l10n.partnerActionRetry,
            onAction: onReload,
          )
        else if (rooms.isLoading || rooms.status == PartnerRoomsStatus.idle)
          const _RoomsLoading()
        else if (rooms.isEmpty)
          OceanStateView(
            icon: Icons.meeting_room_outlined,
            title: l10n.partnerRoomsEmptyTitle,
            message: l10n.partnerRoomsEmptyMessage,
            semanticLabel: l10n.partnerRoomsEmptyTitle,
          )
        else if (isWide && detailOpen)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _RoomList(partner: partner, rooms: rooms, compact: true),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 3, child: _RoomDetailPanel(rooms: rooms)),
            ],
          )
        else if (detailOpen)
          _RoomDetailPanel(rooms: rooms)
        else
          _RoomList(partner: partner, rooms: rooms, compact: false),
      ],
    );
  }
}

class _RoomsHeader extends StatelessWidget {
  final PartnerState partner;
  final PartnerRoomsState rooms;
  final Future<void> Function() onReload;

  const _RoomsHeader({
    required this.partner,
    required this.rooms,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final property = partner.selectedProperty;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.partnerNavRooms,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Always name the property the rooms belong to — the room
                    // record itself carries no property reference, so the
                    // context has to be stated rather than inferred.
                    Text(
                      property == null
                          ? l10n.partnerRoomsNoPropertyContext
                          : l10n.partnerRoomsForProperty(property.name),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: rooms.isLoading ? null : onReload,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.partnerActionRefresh,
              ),
            ],
          ),
          if (rooms.isReady && rooms.rooms.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xxs,
              children: [
                _HeaderFact(
                  icon: Icons.meeting_room_outlined,
                  text: l10n.partnerRoomsCount(rooms.rooms.length),
                ),
                _HeaderFact(
                  icon: Icons.toggle_on_rounded,
                  text: l10n.partnerRoomsListedCount(rooms.activeCount),
                ),
                if (rooms.soldOutCount > 0)
                  _HeaderFact(
                    icon: Icons.event_busy_outlined,
                    text: l10n.partnerRoomsSoldOutCount(rooms.soldOutCount),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderFact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderFact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
}

/// Switches the **workspace** property, which this screen then follows.
///
/// Only rendered when the partner owns more than one property; a single-property
/// partner is never asked to choose (C2's `replaceProperties` already selected
/// it). Selecting here goes through `PartnerState.selectProperty`, which ignores
/// any id the backend did not authorize.
class _PropertySwitcher extends StatelessWidget {
  final PartnerState partner;
  final PartnerRoomsState rooms;

  const _PropertySwitcher({required this.partner, required this.rooms});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.partnerRoomsPropertyScope,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final property in partner.properties)
                ChoiceChip(
                  label: Text(
                    property.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: partner.selectedPropertyId == property.id,
                  onSelected: rooms.isLoading
                      ? null
                      : (_) => partner.selectProperty(property.id),
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: partner.selectedPropertyId == property.id
                        ? AppColors.textInverse
                        : AppColors.textPrimary,
                  ),
                  selectedColor: AppColors.ocean700,
                  backgroundColor: AppColors.surfaceMuted,
                  showCheckmark: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomsLoading extends StatelessWidget {
  const _RoomsLoading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.partnerStatusLoadingTitle,
      liveRegion: true,
      child: OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoomList extends StatelessWidget {
  final PartnerState partner;
  final PartnerRoomsState rooms;
  final bool compact;

  const _RoomList({
    required this.partner,
    required this.rooms,
    required this.compact,
  });

  /// `PartnerRoomService` applies **no** `PartnerTeamRole` check — it resolves
  /// the caller with `partnerProfileRepo.findByUserId`, so only the profile
  /// owner reaches these endpoints at all. Gating the affordance on OWNER
  /// mirrors that exactly, and an unknown role fails closed. UX only.
  bool get _canAct => partner.teamRole == PartnerTeamRole.owner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_canAct) ...[
          _RoleNotice(message: l10n.partnerRoomActionsOwnerOnly),
          const SizedBox(height: AppSpacing.sm),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppSpacing.sm;
            final columns =
                compact ? 1 : (constraints.maxWidth / 340).floor().clamp(1, 3);
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final room in rooms.rooms)
                  SizedBox(
                    width: width,
                    child: PartnerRoomCard(
                      room: room,
                      open: rooms.openRoomId == room.id,
                      actionPending: rooms.pendingActionRoomId == room.id,
                      onOpen: () => rooms.openRoom(room.id),
                      onToggleActive:
                          _canAct ? () => _toggle(context, room) : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, PartnerRoom room) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await rooms.setActive(room.id, activate: !room.active);
    if (!context.mounted) return;

    final message = switch (result) {
      PartnerRoomActionResult.success => room.active
          ? l10n.partnerRoomUnlistedMessage(room.roomName)
          : l10n.partnerRoomListedMessage(room.roomName),
      PartnerRoomActionResult.unauthorized =>
        l10n.partnerDashboardErrorUnauthorized,
      PartnerRoomActionResult.forbidden => l10n.partnerDashboardErrorForbidden,
      PartnerRoomActionResult.notFound => l10n.partnerRoomActionNotFound,
      PartnerRoomActionResult.uncertain => l10n.partnerPropertyActionUncertain,
      PartnerRoomActionResult.failed => l10n.partnerPropertyActionFailed,
    };
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RoleNotice extends StatelessWidget {
  final String message;

  const _RoleNotice({required this.message});

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
}

class _RoomDetailPanel extends StatelessWidget {
  final PartnerRoomsState rooms;

  const _RoomDetailPanel({required this.rooms});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.partnerRoomDetailHeading,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: rooms.closeDetail,
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.partnerRoomCloseDetail,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (rooms.isDetailLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (rooms.hasDetailError)
            _RoomDetailError(rooms: rooms)
          else if (rooms.detail != null)
            _RoomDetailContent(room: rooms.detail!)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _RoomDetailError extends StatelessWidget {
  final PartnerRoomsState rooms;

  const _RoomDetailError({required this.rooms});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = switch (rooms.detailErrorKind) {
      ApiErrorKind.unauthorized => l10n.partnerDashboardErrorUnauthorized,
      ApiErrorKind.forbidden => l10n.partnerDashboardErrorForbidden,
      ApiErrorKind.notFound => l10n.partnerRoomDetailNotFound,
      ApiErrorKind.timeout => l10n.partnerDashboardErrorTimeout,
      ApiErrorKind.network => l10n.partnerDashboardErrorNetwork,
      ApiErrorKind.server => l10n.partnerDashboardErrorServer,
      _ => l10n.partnerDashboardErrorGeneric,
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 18, color: AppColors.danger),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            OceanSecondaryButton(
              label: l10n.partnerActionRetry,
              icon: Icons.refresh_rounded,
              fullWidth: false,
              onPressed: () {
                final id = rooms.openRoomId;
                if (id != null) rooms.openRoom(id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomDetailContent extends StatelessWidget {
  final PartnerRoom room;

  const _RoomDetailContent({required this.room});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final money = NumberFormat('#,##0.##', locale);
    final number = NumberFormat('#,##0', locale);
    final decimal = NumberFormat('#,##0.#', locale);
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();

    String? yesNo(bool value) =>
        value ? l10n.partnerRoomYes : l10n.partnerRoomNo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          room.roomName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            OceanStatusPill(
              label: partnerRoomTypeLabel(l10n, room.roomType),
              color: AppColors.ocean600,
              icon: Icons.category_outlined,
            ),
            OceanStatusPill(
              label: room.active
                  ? l10n.partnerRoomListed
                  : l10n.partnerRoomUnlisted,
              color: room.active ? AppColors.success : AppColors.textTertiary,
              icon: room.active
                  ? Icons.toggle_on_rounded
                  : Icons.toggle_off_outlined,
            ),
            // Sold out is an inventory fact, deliberately separate from the
            // listing flag — a sold-out room is still a listed room.
            if (room.isSoldOut)
              OceanStatusPill(
                label: l10n.partnerRoomSoldOut,
                color: AppColors.warning,
                icon: Icons.event_busy_outlined,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        PartnerPropertySection(
          title: l10n.partnerRoomSectionIdentity,
          children: [
            PartnerPropertyField(
                label: l10n.partnerRoomFieldCode, value: room.roomCode),
            PartnerPropertyField(
              label: l10n.partnerRoomFieldType,
              value: partnerRoomTypeLabel(l10n, room.roomType),
            ),
            PartnerPropertyField(
                label: l10n.partnerRoomFieldDescription,
                value: room.description),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerRoomSectionBeds,
          children: [
            PartnerPropertyField(
              label: l10n.partnerRoomFieldBedType,
              value: room.bedType == null
                  ? null
                  : partnerBedTypeLabel(l10n, room.bedType!),
            ),
            PartnerPropertyField(
              label: l10n.partnerRoomFieldBedCount,
              value:
                  room.bedCount == null ? null : number.format(room.bedCount),
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerRoomSectionCapacity,
          children: [
            PartnerPropertyField(
              label: l10n.partnerRoomFieldMaxGuests,
              value:
                  room.maxGuests == null ? null : number.format(room.maxGuests),
            ),
            PartnerPropertyField(
              label: l10n.partnerRoomFieldMaxAdults,
              value:
                  room.maxAdults == null ? null : number.format(room.maxAdults),
            ),
            PartnerPropertyField(
              label: l10n.partnerRoomFieldMaxChildren,
              value: room.maxChildren == null
                  ? null
                  : number.format(room.maxChildren),
            ),
            PartnerPropertyField(
              label: l10n.partnerRoomFieldSize,
              value: room.roomSizeSqm == null
                  ? null
                  : l10n.partnerRoomSizeValue(decimal.format(room.roomSizeSqm)),
            ),
            PartnerPropertyField(
              label: l10n.partnerRoomFieldFloor,
              value: room.floorNumber == null
                  ? null
                  : number.format(room.floorNumber),
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerRoomSectionInventory,
          children: [
            PartnerPropertyField(
              label: l10n.partnerRoomFieldQuantity,
              value:
                  room.quantity == null ? null : number.format(room.quantity),
            ),
            PartnerPropertyField(
              label: l10n.partnerRoomFieldAvailable,
              value: room.availableQuantity == null
                  ? null
                  : number.format(room.availableQuantity),
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerRoomSectionPricing,
          children: [
            PartnerPropertyField(
              label: l10n.partnerRoomFieldPriceFrom,
              value:
                  room.priceFrom == null ? null : money.format(room.priceFrom),
            ),
            PartnerPropertyField(
              label: l10n.partnerRoomFieldOriginalPrice,
              value: room.originalPrice == null
                  ? null
                  : money.format(room.originalPrice),
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerRoomSectionConditions,
          children: [
            PartnerPropertyField(
                label: l10n.partnerRoomFieldBreakfast,
                value: yesNo(room.breakfastIncluded)),
            PartnerPropertyField(
                label: l10n.partnerRoomFieldFreeCancellation,
                value: yesNo(room.freeCancellation)),
            PartnerPropertyField(
                label: l10n.partnerRoomFieldInstantConfirmation,
                value: yesNo(room.instantConfirmation)),
            PartnerPropertyField(
                label: l10n.partnerRoomFieldSmoking,
                value: yesNo(room.smokingAllowed)),
          ],
        ),

        // Only rendered when the backend actually returned amenities — an empty
        // "Amenities" heading would imply data that is simply not configured.
        if (room.amenities.isNotEmpty)
          PartnerPropertySection(
            title: l10n.partnerRoomSectionAmenities,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  for (final amenity in room.amenities)
                    OceanStatusPill(
                      label: amenity.name,
                      color: AppColors.textSecondary,
                      icon: Icons.check_rounded,
                    ),
                ],
              ),
            ],
          ),

        PartnerPropertySection(
          title: l10n.partnerRoomSectionMedia,
          children: [
            PartnerPropertyField(
              label: l10n.partnerRoomFieldImages,
              value: room.galleryImages.isEmpty && room.coverImageUrl == null
                  ? null
                  : number.format(room.galleryImages.length),
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerPropertySectionMetadata,
          children: [
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldCreated,
              value: room.createdAt == null
                  ? null
                  : dateFmt.format(room.createdAt!),
            ),
            PartnerPropertyField(
              label: l10n.partnerPropertyFieldUpdated,
              value: room.updatedAt == null
                  ? null
                  : dateFmt.format(room.updatedAt!),
            ),
          ],
        ),
      ],
    );
  }
}
