import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../expenses/expenses_screen.dart';
import 'hotel_room_selection_screen.dart'
    show mealPlanLabel, cancellationPolicyLabel;

/// Localized label for a special-request preset.
String specialRequestPresetLabel(
  AppLocalizations l10n,
  SpecialRequestPreset preset,
) {
  switch (preset) {
    case SpecialRequestPreset.lateCheckIn:
      return l10n.specialRequestLateCheckIn;
    case SpecialRequestPreset.highFloor:
      return l10n.specialRequestHighFloor;
    case SpecialRequestPreset.quietRoom:
      return l10n.specialRequestQuietRoom;
    case SpecialRequestPreset.twinBed:
      return l10n.specialRequestTwinBed;
    case SpecialRequestPreset.largeBed:
      return l10n.specialRequestLargeBed;
  }
}

IconData specialRequestPresetIcon(SpecialRequestPreset preset) {
  switch (preset) {
    case SpecialRequestPreset.lateCheckIn:
      return Icons.nightlight_round;
    case SpecialRequestPreset.highFloor:
      return Icons.apartment_rounded;
    case SpecialRequestPreset.quietRoom:
      return Icons.volume_off_rounded;
    case SpecialRequestPreset.twinBed:
      return Icons.bed_rounded;
    case SpecialRequestPreset.largeBed:
      return Icons.king_bed_rounded;
  }
}

/// A localized, screen-reader-announced "Step N of M" header shown atop each
/// step of the booking flow so the progression is explicit and accessible.
class BookingStepHeader extends StatelessWidget {
  final int current;
  final int total;

  const BookingStepHeader({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = l10n.bookingStepLabel(current, total);
    return Semantics(
      header: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.ocean,
                letterSpacing: 0.4,
              ),
        ),
      ),
    );
  }
}

/// Stay snapshot (hotel, room, dates, nights, guests) shared by the summary,
/// review and ready screens. All values are passed in — nothing is computed.
class BookingStayCard extends StatelessWidget {
  final String hotelName;
  final String roomName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int adults;
  final int children;
  final bool tripLinked;

  const BookingStayCard({
    super.key,
    required this.hotelName,
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    this.tripLinked = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingSummaryStayTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(hotelName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(roomName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: '${date.format(checkIn)} - ${date.format(checkOut)}',
                icon: Icons.calendar_month_rounded,
              ),
              OceanStatusPill(
                label: l10n.hotelNights(nights),
                icon: Icons.nights_stay_rounded,
                color: AppColors.turquoise600,
              ),
              OceanStatusPill(
                label: l10n.hotelGuestSummary(adults, children),
                icon: Icons.group_rounded,
                color: AppColors.ocean,
              ),
              OceanStatusPill(
                label: l10n.hotelOneRoomOnly,
                icon: Icons.meeting_room_rounded,
                color: AppColors.violet,
              ),
              if (tripLinked)
                OceanStatusPill(
                  label: l10n.bookingTripLinkedLabel,
                  icon: Icons.map_rounded,
                  color: AppColors.ocean400,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rate-plan snapshot (name, meal plan, cancellation, breakfast, refundability)
/// derived entirely from the backend quote + selected room record.
class BookingPlanCard extends StatelessWidget {
  final HotelPricingQuote quote;
  final AvailableRoomRecord? room;

  const BookingPlanCard({super.key, required this.quote, this.room});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pills = <Widget>[
      if (quote.mealPlanType != null)
        OceanStatusPill(
          label: mealPlanLabel(l10n, quote.mealPlanType!),
          icon: Icons.restaurant_rounded,
        ),
      if (quote.cancellationPolicyType != null)
        OceanStatusPill(
          label: cancellationPolicyLabel(l10n, quote.cancellationPolicyType!),
          icon: Icons.policy_rounded,
          color: quote.refundable ? AppColors.success : AppColors.coral,
        ),
      if (room?.breakfastIncluded ?? false)
        OceanStatusPill(
          label: l10n.hotelBreakfastIncluded,
          icon: Icons.free_breakfast_rounded,
          color: AppColors.ocean,
        ),
      if (room?.freeCancellation ?? false)
        OceanStatusPill(
          label: l10n.availabilityRealFreeCancellation,
          icon: Icons.verified_rounded,
          color: AppColors.turquoise600,
        ),
    ];
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingSelectedPlanTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            quote.selectedRatePlanName ?? room?.roomName ?? '',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (pills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: pills,
            ),
          ],
        ],
      ),
    );
  }
}

/// Price breakdown card. Every figure comes straight from the backend quote —
/// no taxes are synthesized (the backend exposes none) and no total is computed
/// client-side. Formatting uses the quote's own currency.
class BookingPriceCard extends StatelessWidget {
  final HotelPricingQuote quote;

  const BookingPriceCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = quote.finalQuotedPrice;
    return OceanGlassCard(
      semanticLabel: l10n.bookingPriceSemantic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingPriceTitle,
              semanticsLabel: l10n.bookingPriceSemantic,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          if (quote.finalNightlyRate != null)
            _PriceRow(
              label: l10n.bookingFinalNightlyRate,
              value:
                  formatMoney(context, quote.finalNightlyRate!, quote.currency),
            ),
          if (quote.staySubtotal != null)
            _PriceRow(
              label: l10n.bookingStaySubtotal,
              value: formatMoney(context, quote.staySubtotal!, quote.currency),
            ),
          if (quote.promotionDiscount > 0)
            _PriceRow(
              label: l10n.bookingPromotionDiscount,
              value:
                  '-${formatMoney(context, quote.promotionDiscount, quote.currency)}',
            ),
          const Divider(height: AppSpacing.lg),
          _PriceRow(
            label: l10n.bookingFinalQuotedPrice,
            value: total == null
                ? l10n.bookingQuoteUnavailable
                : formatMoney(context, total, quote.currency),
            emphasized: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.bookingCustomerBenefitsExcluded,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            l10n.bookingQuoteNoReservation,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          for (final warning in quote.warnings) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(warning, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Read-only guest + special-request summary shared by the review and ready
/// screens.
class BookingGuestCard extends StatelessWidget {
  final BookingGuestInfo guest;
  final Set<SpecialRequestPreset> presets;
  final String note;

  const BookingGuestCard({
    super.key,
    required this.guest,
    required this.presets,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <Widget>[
      if (guest.fullName.isNotEmpty)
        _InfoRow(label: l10n.bookingGuestNameLabel, value: guest.fullName),
      if (guest.email.isNotEmpty)
        _InfoRow(label: l10n.bookingGuestEmailLabel, value: guest.email),
      if (guest.phone.isNotEmpty)
        _InfoRow(label: l10n.bookingGuestPhoneLabel, value: guest.phone),
      if (guest.country.isNotEmpty)
        _InfoRow(label: l10n.bookingGuestCountryLabel, value: guest.country),
      if (guest.arrivalTime.isNotEmpty)
        _InfoRow(
          label: l10n.bookingArrivalTimeLabel,
          value: guest.arrivalTime,
        ),
    ];
    final hasRequests = presets.isNotEmpty || note.trim().isNotEmpty;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingReviewGuestTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          ...rows,
          const SizedBox(height: AppSpacing.md),
          Text(l10n.bookingSpecialRequestsTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          if (!hasRequests)
            Text(l10n.bookingNoSpecialRequests,
                style: Theme.of(context).textTheme.bodyMedium)
          else ...[
            if (presets.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final preset in presets)
                    OceanStatusPill(
                      label: specialRequestPresetLabel(l10n, preset),
                      icon: specialRequestPresetIcon(preset),
                    ),
                ],
              ),
            if (note.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(note.trim(), style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: AppColors.ocean)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
