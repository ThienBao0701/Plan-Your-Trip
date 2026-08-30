import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/partner/partner_promotion_models.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_radii.dart';
import '../../../../design/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../partner_vouchers_state.dart';

/// Formats promotion figures.
///
/// **Promotion amounts carry no currency symbol.** `PromotionResponse` has no
/// currency field — exactly like `RatePlan` in C5 — so `discountValue`,
/// `maxDiscountAmount` and `minimumSpend` are rendered as grouped numbers and
/// the screen says once that the API supplies no currency. The pricing preview
/// is the one exception: `PricingBreakdownResponse` *does* carry `currency`, and
/// [PartnerPricingBreakdownView] shows that code beside its amounts.
class PartnerPromotionFormats {
  final NumberFormat amount;
  final NumberFormat integer;
  final NumberFormat decimal;
  final DateFormat date;

  PartnerPromotionFormats(String locale)
      : amount = NumberFormat('#,##0.##', locale),
        integer = NumberFormat('#,##0', locale),
        decimal = NumberFormat('#,##0.##', locale),
        date = DateFormat.yMMMd(locale);

  static PartnerPromotionFormats of(BuildContext context) =>
      PartnerPromotionFormats(Localizations.localeOf(context).toString());
}

String partnerPromotionTypeLabel(
  AppLocalizations l10n,
  PartnerPromotionType type,
) =>
    switch (type) {
      PartnerPromotionType.general => l10n.partnerPromotionTypeGeneral,
      PartnerPromotionType.room => l10n.partnerPromotionTypeRoom,
      PartnerPromotionType.hotel => l10n.partnerPromotionTypeHotel,
      PartnerPromotionType.member => l10n.partnerPromotionTypeMember,
      PartnerPromotionType.earlyBird => l10n.partnerPromotionTypeEarlyBird,
      PartnerPromotionType.lastMinute => l10n.partnerPromotionTypeLastMinute,
      PartnerPromotionType.weekend => l10n.partnerPromotionTypeWeekend,
      PartnerPromotionType.holiday => l10n.partnerPromotionTypeHoliday,
      PartnerPromotionType.unknown => l10n.partnerPromotionTypeUnknown,
    };

String partnerDiscountTypeLabel(
  AppLocalizations l10n,
  PartnerDiscountType type,
) =>
    switch (type) {
      PartnerDiscountType.percentage => l10n.partnerDiscountTypePercentage,
      PartnerDiscountType.fixedAmount => l10n.partnerDiscountTypeFixed,
      PartnerDiscountType.unknown => l10n.partnerDiscountTypeUnknown,
    };

/// Describes what a promotion applies to.
///
/// A `ROOM` target is named only when the room is among those loaded; otherwise
/// the generic label is used rather than a guess. A `HOTEL` `targetId` is a
/// **`HotelDetail` id**, which no partner endpoint resolves to a name, so it is
/// never presented as a property name.
String partnerPromotionTargetLabel(
  AppLocalizations l10n,
  PartnerPromotionTargetType type,
  String? roomName,
  int? targetId,
) =>
    switch (type) {
      PartnerPromotionTargetType.all => l10n.partnerPromotionTargetAll,
      PartnerPromotionTargetType.hotel => l10n.partnerPromotionTargetHotel,
      PartnerPromotionTargetType.room => roomName != null
          ? l10n.partnerPromotionTargetRoomNamed(roomName)
          : l10n.partnerPromotionTargetRoom,
      PartnerPromotionTargetType.unknown => l10n.partnerPromotionTargetUnknown,
    };

/// One promotion in the list.
///
/// Renders only `PromotionResponse` fields. Nothing is discounted, summed or
/// projected on the client — the pricing engine owns all of that.
class PartnerPromotionCard extends StatelessWidget {
  final PartnerPromotion promotion;

  /// Resolved room name for a `ROOM` target, when known.
  final String? targetRoomName;

  final bool open;
  final bool actionPending;
  final VoidCallback onOpen;

  /// Null when the signed-in partner may not write — the button is then absent
  /// rather than shown disabled.
  final VoidCallback? onToggleActive;

  const PartnerPromotionCard({
    super.key,
    required this.promotion,
    required this.open,
    required this.actionPending,
    required this.onOpen,
    this.targetRoomName,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerPromotionFormats.of(context);
    final expired = promotion.isExpired();
    final scheduled = promotion.isScheduled();

    return Semantics(
      button: true,
      label: [
        promotion.name,
        partnerPromotionTypeLabel(l10n, promotion.promotionType),
        promotion.active
            ? l10n.partnerPromotionActive
            : l10n.partnerPromotionInactive,
        if (expired) l10n.partnerPromotionExpired,
        if (scheduled) l10n.partnerPromotionScheduled,
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
                            promotion.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (promotion.code != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              promotion.code!,
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
                    const SizedBox(height: AppSpacing.xxs),
                    // The discount is the headline. A percentage gets a `%`
                    // because the DTO says it is one; a fixed amount gets no
                    // symbol because the DTO names no currency.
                    Text(
                      _headlineDiscount(l10n, f),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ocean700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OceanStatusPill(
                          label: partnerPromotionTypeLabel(
                              l10n, promotion.promotionType),
                          color: AppColors.ocean600,
                          icon: Icons.sell_outlined,
                        ),
                        OceanStatusPill(
                          label: promotion.active
                              ? l10n.partnerPromotionActive
                              : l10n.partnerPromotionInactive,
                          color: promotion.active
                              ? AppColors.success
                              : AppColors.textTertiary,
                          icon: promotion.active
                              ? Icons.toggle_on_rounded
                              : Icons.toggle_off_outlined,
                        ),
                        // Expired and scheduled are facts about the window,
                        // reported separately from the active flag — a
                        // promotion can be active and expired at once.
                        if (expired)
                          OceanStatusPill(
                            label: l10n.partnerPromotionExpired,
                            color: AppColors.warning,
                            icon: Icons.event_busy_outlined,
                          ),
                        if (scheduled)
                          OceanStatusPill(
                            label: l10n.partnerPromotionScheduled,
                            color: AppColors.violet,
                            icon: Icons.schedule_rounded,
                          ),
                        if (!promotion.stackable)
                          OceanStatusPill(
                            label: l10n.partnerPromotionExclusivePill,
                            color: AppColors.ocean700,
                            icon: Icons.filter_1_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        _Fact(
                          icon: Icons.percent_rounded,
                          text: partnerDiscountTypeLabel(
                              l10n, promotion.discountType),
                        ),
                        _Fact(
                          icon: Icons.my_location_rounded,
                          text: partnerPromotionTargetLabel(
                            l10n,
                            promotion.targetType,
                            targetRoomName,
                            promotion.targetId,
                          ),
                        ),
                        if (promotion.startDate != null &&
                            promotion.endDate != null)
                          _Fact(
                            icon: Icons.date_range_rounded,
                            text: l10n.partnerPromotionValidity(
                              f.date.format(promotion.startDate!),
                              f.date.format(promotion.endDate!),
                            ),
                          ),
                        _Fact(
                          icon: Icons.low_priority_rounded,
                          text: l10n.partnerPromotionPriorityValue(
                              f.integer.format(promotion.priority)),
                        ),
                        if (promotion.hasConditions)
                          _Fact(
                            icon: Icons.rule_rounded,
                            text: l10n.partnerPromotionHasConditions,
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
                                label: promotion.active
                                    ? l10n.partnerPromotionDeactivateAction
                                    : l10n.partnerPromotionActivateAction,
                                icon: promotion.active
                                    ? Icons.toggle_off_outlined
                                    : Icons.toggle_on_rounded,
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

  String _headlineDiscount(AppLocalizations l10n, PartnerPromotionFormats f) {
    final value = promotion.discountValue;
    if (value == null) return l10n.partnerPropertyNotSet;
    final formatted = f.decimal.format(value);
    return promotion.isPercentage ? '$formatted%' : formatted;
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

/// A short inline statement — a limitation, a warning, or an explanation.
class PartnerPromotionNotice extends StatelessWidget {
  final String message;
  final bool warning;

  const PartnerPromotionNotice({
    super.key,
    required this.message,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.warning : AppColors.ocean600;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Never state something by colour alone.
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            size: 18,
            color: color,
          ),
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
    );
  }
}

/// The pricing engine's breakdown for one stay.
///
/// Every number here came from `PricingBreakdownResponse`; none is computed,
/// re-derived or cross-checked locally. This payload does carry a currency, so
/// amounts are shown with the backend's own code.
class PartnerPricingBreakdownView extends StatelessWidget {
  final PartnerPricingPreview preview;

  const PartnerPricingBreakdownView({super.key, required this.preview});

  /// Qualifies an amount with the server-supplied currency code, or leaves it
  /// bare when the server sent none. No symbol is ever guessed.
  String _money(PartnerPromotionFormats f, String absent, double? value) {
    if (value == null) return absent;
    final formatted = f.amount.format(value);
    final currency = preview.currency;
    return currency == null ? formatted : '$formatted $currency';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerPromotionFormats.of(context);
    final absent = l10n.partnerPropertyNotSet;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            preview.roomName ?? l10n.partnerPromotionPreviewHeading,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (preview.checkIn != null && preview.checkOut != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.partnerPromotionPreviewStay(
                f.date.format(preview.checkIn!),
                f.date.format(preview.checkOut!),
                f.integer.format(preview.nights),
              ),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _AmountRow(
            label: l10n.partnerPromotionPreviewBase,
            value: _money(f, absent, preview.basePrice),
          ),
          _AmountRow(
            label: preview.ratePlanName == null
                ? l10n.partnerPromotionPreviewRatePlan
                : l10n.partnerPromotionPreviewRatePlanNamed(
                    preview.ratePlanName!),
            value: _money(f, absent, preview.ratePlanPrice),
          ),
          _AmountRow(
            label: l10n.partnerPromotionPreviewDiscount,
            value: _money(f, absent, preview.promotionDiscount),
          ),
          const Divider(height: AppSpacing.lg),
          _AmountRow(
            label: l10n.partnerPromotionPreviewTotal,
            value: _money(f, absent, preview.finalPrice),
            emphasis: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.partnerPromotionPreviewAppliedHeading,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          if (!preview.hasPromotions)
            Text(
              l10n.partnerPromotionPreviewNoneApplied,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            )
          else
            for (final applied in preview.appliedPromotions)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        _appliedLabel(l10n, applied),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      // The amount this promotion actually removed, as the
                      // engine itself reported it.
                      l10n.partnerPromotionPreviewAppliedAmount(
                          _money(f, absent, applied.discountApplied)),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _appliedLabel(AppLocalizations l10n, PartnerAppliedPromotion applied) {
    final name = applied.name ?? l10n.partnerPromotionPreviewUnnamed;
    final code = applied.code;
    return code == null ? name : '$name · $code';
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasis;

  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    emphasis ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: emphasis ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: (emphasis
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.bodySmall)
                  ?.copyWith(
                fontWeight: FontWeight.w800,
                color: emphasis ? AppColors.ocean700 : AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The outcome of a booking-voucher check.
///
/// Three distinct answers, never conflated:
///   * verified **and** eligible — the guest may be admitted;
///   * verified but **not** eligible — the backend's own `reason` is shown;
///   * not recognised — the uniform 404, which may mean an invalid signature, an
///     unknown booking, or another partner's booking. The UI says exactly that
///     and does not pretend to know which.
class PartnerVoucherResultCard extends StatelessWidget {
  final PartnerVoucherCheckStatus status;
  final PartnerVoucherVerification? result;
  final String? errorMessage;

  const PartnerVoucherResultCard({
    super.key,
    required this.status,
    this.result,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerPromotionFormats.of(context);
    final voucher = result;

    if (status != PartnerVoucherCheckStatus.verified || voucher == null) {
      final (icon, color, title, message) = switch (status) {
        PartnerVoucherCheckStatus.notRecognised => (
            Icons.help_outline_rounded,
            AppColors.warning,
            l10n.partnerVoucherNotRecognisedTitle,
            l10n.partnerVoucherNotRecognisedMessage,
          ),
        PartnerVoucherCheckStatus.empty => (
            Icons.edit_outlined,
            AppColors.textTertiary,
            l10n.partnerVoucherEmptyTitle,
            l10n.partnerVoucherEmptyMessage,
          ),
        PartnerVoucherCheckStatus.unauthorized => (
            Icons.lock_outline_rounded,
            AppColors.danger,
            l10n.partnerVoucherFailedTitle,
            l10n.partnerDashboardErrorUnauthorized,
          ),
        PartnerVoucherCheckStatus.forbidden => (
            Icons.block_rounded,
            AppColors.danger,
            l10n.partnerVoucherFailedTitle,
            l10n.partnerDashboardErrorForbidden,
          ),
        _ => (
            Icons.cloud_off_rounded,
            AppColors.danger,
            l10n.partnerVoucherFailedTitle,
            errorMessage ?? l10n.partnerDashboardErrorGeneric,
          ),
      };
      return OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child:
            _Verdict(icon: icon, color: color, title: title, message: message),
      );
    }

    // `verified` is the signature check; `eligible` is the stay/status check.
    // They are separate answers and are shown separately.
    final admit = voucher.eligible;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Verdict(
            icon: admit
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: admit ? AppColors.success : AppColors.warning,
            title: admit
                ? l10n.partnerVoucherEligibleTitle
                : l10n.partnerVoucherNotEligibleTitle,
            // The backend's own explanation, verbatim; no client-side reasoning.
            message: voucher.reason ??
                (admit
                    ? l10n.partnerVoucherEligibleMessage
                    : l10n.partnerVoucherNotEligibleMessage),
          ),
          const SizedBox(height: AppSpacing.md),
          _VoucherFacts(voucher: voucher, formats: f),
          const SizedBox(height: AppSpacing.sm),
          Text(
            // Says plainly that verifying is not checking in.
            l10n.partnerVoucherReadOnlyNote,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _Verdict({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoucherFacts extends StatelessWidget {
  final PartnerVoucherVerification voucher;
  final PartnerPromotionFormats formats;

  const _VoucherFacts({required this.voucher, required this.formats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stay = voucher.checkInDate != null && voucher.checkOutDate != null
        ? l10n.partnerVoucherStayValue(
            formats.date.format(voucher.checkInDate!),
            formats.date.format(voucher.checkOutDate!),
            formats.integer.format(voucher.nights),
          )
        : null;
    final occupancy = voucher.adults == null && voucher.children == null
        ? null
        : l10n.partnerVoucherOccupancyValue(
            formats.integer.format(voucher.adults ?? 0),
            formats.integer.format(voucher.children ?? 0),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
            label: l10n.partnerVoucherFieldBooking, value: voucher.bookingCode),
        _Row(
            label: l10n.partnerVoucherFieldBookingStatus,
            value: voucher.bookingStatus),
        _Row(label: l10n.partnerVoucherFieldGuest, value: voucher.guestName),
        _Row(label: l10n.partnerVoucherFieldProperty, value: voucher.hotelName),
        _Row(label: l10n.partnerVoucherFieldRoom, value: voucher.roomName),
        _Row(label: l10n.partnerVoucherFieldStay, value: stay),
        _Row(label: l10n.partnerVoucherFieldOccupancy, value: occupancy),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;

  const _Row({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              // An absent field is stated as absent, never filled in.
              value ?? l10n.partnerPropertyNotSet,
              style: theme.textTheme.bodySmall?.copyWith(
                color: value == null
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
                fontWeight: value == null ? FontWeight.w400 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
