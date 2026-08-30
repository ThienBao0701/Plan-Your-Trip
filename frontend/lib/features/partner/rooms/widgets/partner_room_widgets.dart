import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/partner/partner_room_models.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_radii.dart';
import '../../../../design/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_widgets.dart';

/// Localised label for a `RoomType`. All nine backend values, plus an explicit
/// "unrecognised" reading rather than a silent blank.
String partnerRoomTypeLabel(AppLocalizations l10n, PartnerRoomType type) =>
    switch (type) {
      PartnerRoomType.standard => l10n.partnerRoomTypeStandard,
      PartnerRoomType.superior => l10n.partnerRoomTypeSuperior,
      PartnerRoomType.deluxe => l10n.partnerRoomTypeDeluxe,
      PartnerRoomType.premier => l10n.partnerRoomTypePremier,
      PartnerRoomType.executive => l10n.partnerRoomTypeExecutive,
      PartnerRoomType.suite => l10n.partnerRoomTypeSuite,
      PartnerRoomType.family => l10n.partnerRoomTypeFamily,
      PartnerRoomType.villa => l10n.partnerRoomTypeVilla,
      PartnerRoomType.bungalow => l10n.partnerRoomTypeBungalow,
      PartnerRoomType.unknown => l10n.partnerRoomTypeUnknown,
    };

/// Localised label for a `BedType`. All seven backend values.
String partnerBedTypeLabel(AppLocalizations l10n, PartnerBedType type) =>
    switch (type) {
      PartnerBedType.single => l10n.partnerBedTypeSingle,
      PartnerBedType.double_ => l10n.partnerBedTypeDouble,
      PartnerBedType.twin => l10n.partnerBedTypeTwin,
      PartnerBedType.queen => l10n.partnerBedTypeQueen,
      PartnerBedType.king => l10n.partnerBedTypeKing,
      PartnerBedType.sofaBed => l10n.partnerBedTypeSofaBed,
      PartnerBedType.bunk => l10n.partnerBedTypeBunk,
      PartnerBedType.unknown => l10n.partnerBedTypeUnknown,
    };

/// One row in the rooms list.
///
/// Shows only fields `HotelRoomResponse` actually carries. Price and inventory
/// appear because the DTO supplies them; occupancy, revenue and booking counts
/// do not appear because it does not.
class PartnerRoomCard extends StatelessWidget {
  final PartnerRoom room;
  final bool open;
  final bool actionPending;
  final VoidCallback onOpen;

  /// Null when the caller's team role cannot perform listing actions.
  final VoidCallback? onToggleActive;

  const PartnerRoomCard({
    super.key,
    required this.room,
    required this.open,
    required this.actionPending,
    required this.onOpen,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat('#,##0', locale);
    final money = NumberFormat('#,##0.##', locale);

    return Semantics(
      button: true,
      label: [
        room.roomName,
        partnerRoomTypeLabel(l10n, room.roomType),
        room.active ? l10n.partnerRoomListed : l10n.partnerRoomUnlisted,
        if (room.isSoldOut) l10n.partnerRoomSoldOut,
      ].join('. '),
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: open ? AppColors.ocean600 : AppColors.divider,
              width: open ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            room.roomName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (room.roomCode != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              room.roomCode!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                          color: room.active
                              ? AppColors.success
                              : AppColors.textTertiary,
                          icon: room.active
                              ? Icons.toggle_on_rounded
                              : Icons.toggle_off_outlined,
                        ),
                        if (room.isSoldOut)
                          OceanStatusPill(
                            label: l10n.partnerRoomSoldOut,
                            color: AppColors.warning,
                            icon: Icons.event_busy_outlined,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        if (room.maxGuests != null)
                          _Fact(
                            icon: Icons.people_alt_outlined,
                            text: l10n.partnerRoomGuestsValue(
                                number.format(room.maxGuests)),
                          ),
                        if (room.bedType != null || room.bedCount != null)
                          _Fact(
                            icon: Icons.bed_outlined,
                            text: [
                              if (room.bedCount != null)
                                number.format(room.bedCount),
                              if (room.bedType != null)
                                partnerBedTypeLabel(l10n, room.bedType!),
                            ].join(' × '),
                          ),
                        if (room.hasInventory)
                          _Fact(
                            icon: Icons.inventory_2_outlined,
                            text: l10n.partnerRoomInventoryValue(
                              number.format(room.availableQuantity),
                              number.format(room.quantity),
                            ),
                          ),
                        if (room.priceFrom != null)
                          _Fact(
                            icon: Icons.sell_outlined,
                            text: l10n.partnerRoomPriceFromValue(
                                money.format(room.priceFrom)),
                          ),
                      ],
                    ),
                    if (onToggleActive != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: actionPending
                            ? const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : OceanSecondaryButton(
                                label: room.active
                                    ? l10n.partnerRoomUnlistAction
                                    : l10n.partnerRoomListAction,
                                icon: room.active
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                fullWidth: false,
                                onPressed: onToggleActive,
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      );
}
