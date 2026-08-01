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

/// Composes the single backend-supported `specialRequest` string from the
/// user-selected presets, arrival time and free note (in a stable, localized
/// order). The backend has NO guest name / email / phone / country field, so
/// those are deliberately excluded here — only text the user actually entered as
/// a request is submitted. Returns null when nothing was requested. Capped to
/// [BookingValidation.maxNoteLength] to match the local guard.
String? composeBookingSpecialRequest(
  AppLocalizations l10n,
  Set<SpecialRequestPreset> presets,
  String arrivalTime,
  String note,
) {
  final parts = <String>[];
  for (final preset in SpecialRequestPreset.values) {
    if (presets.contains(preset)) {
      parts.add(specialRequestPresetLabel(l10n, preset));
    }
  }
  final arrival = arrivalTime.trim();
  if (arrival.isNotEmpty) {
    parts.add('${l10n.bookingArrivalTimeLabel}: $arrival');
  }
  final trimmedNote = note.trim();
  if (trimmedNote.isNotEmpty) parts.add(trimmedNote);
  if (parts.isEmpty) return null;
  var combined = parts.join('\n');
  if (combined.length > BookingValidation.maxNoteLength) {
    combined = combined.substring(0, BookingValidation.maxNoteLength);
  }
  return combined;
}

/// Localized short label for a booking status. PENDING / CONFIRMED (the states a
/// freshly-created booking can hold) are localized; any other/unknown value
/// shows the raw server code honestly rather than a coerced label.
String bookingStatusChipLabel(
  AppLocalizations l10n,
  BookingStatusView view,
  String raw,
) {
  switch (view) {
    case BookingStatusView.pending:
      return l10n.bookingStatusPendingLabel;
    case BookingStatusView.confirmed:
      return l10n.bookingStatusConfirmedLabel;
    default:
      return raw.trim().isEmpty ? l10n.bookingStatusUnknownLabel : raw.trim();
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

/// A status chip that always pairs an icon + localized text (never colour alone,
/// per CLAUDE.md §10). The colour is advisory; the label is authoritative.
class BookingStatusChip extends StatelessWidget {
  final BookingStatusView view;
  final String label;

  const BookingStatusChip({
    super.key,
    required this.view,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (view) {
      BookingStatusView.pending => (
          Icons.hourglass_top_rounded,
          AppColors.ocean
        ),
      BookingStatusView.confirmed => (
          Icons.verified_rounded,
          AppColors.success
        ),
      BookingStatusView.checkInReady || BookingStatusView.checkedIn => (
          Icons.login_rounded,
          AppColors.turquoise600
        ),
      BookingStatusView.checkedOut || BookingStatusView.completed => (
          Icons.check_circle_rounded,
          AppColors.success
        ),
      BookingStatusView.cancelled ||
      BookingStatusView.refunded ||
      BookingStatusView.noShow =>
        (Icons.cancel_rounded, AppColors.coral),
      BookingStatusView.archived => (
          Icons.inventory_2_rounded,
          AppColors.ocean400
        ),
      BookingStatusView.unknown => (
          Icons.help_outline_rounded,
          AppColors.ocean
        ),
    };
    return OceanStatusPill(label: label, icon: icon, color: color);
  }
}

/// Stay snapshot for the booking-result screen, built entirely from the server's
/// [BookingCreateRecord] (no client-side computation).
class BookingResultSummaryCard extends StatelessWidget {
  final BookingCreateRecord record;

  const BookingResultSummaryCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final checkIn = record.checkIn;
    final checkOut = record.checkOut;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingSummaryStayTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(record.hotelName,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(record.roomName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (checkIn != null && checkOut != null)
                OceanStatusPill(
                  label: '${date.format(checkIn)} - ${date.format(checkOut)}',
                  icon: Icons.calendar_month_rounded,
                ),
              OceanStatusPill(
                label: l10n.hotelNights(record.nights),
                icon: Icons.nights_stay_rounded,
                color: AppColors.turquoise600,
              ),
              OceanStatusPill(
                label: l10n.hotelGuestSummary(record.adults, record.children),
                icon: Icons.group_rounded,
                color: AppColors.ocean,
              ),
              if ((record.selectedRatePlanName ?? '').isNotEmpty)
                OceanStatusPill(
                  label: record.selectedRatePlanName!,
                  icon: Icons.sell_rounded,
                  color: AppColors.violet,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Price breakdown for the booking-result screen. Every figure is the server's
/// own final pricing from the create response — nothing is recomputed.
class BookingResultPriceCard extends StatelessWidget {
  final BookingCreateRecord record;

  const BookingResultPriceCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cur = record.currency;
    return OceanGlassCard(
      semanticLabel: l10n.bookingPriceSemantic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingPriceTitle,
              semanticsLabel: l10n.bookingPriceSemantic,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          if (record.basePrice != null)
            _PriceRow(
              label: l10n.bookingResultBaseLabel,
              value: formatMoney(context, record.basePrice!, cur),
            ),
          if ((record.discountAmount ?? 0) > 0)
            _PriceRow(
              label: l10n.bookingPromotionDiscount,
              value: '-${formatMoney(context, record.discountAmount!, cur)}',
            ),
          const Divider(height: AppSpacing.lg),
          _PriceRow(
            label: l10n.bookingFinalQuotedPrice,
            value: record.finalPrice == null
                ? l10n.bookingQuoteUnavailable
                : formatMoney(context, record.finalPrice!, cur),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}
