import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/add_to_trip_sheet.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'booking_widgets.dart';

/// Final step of the UI26 booking flow. Renders the GENUINE backend booking
/// created by `POST /api/bookings` from [AppState.lastCreatedBooking] — the
/// server's own booking code, status and pricing. Status wording is honest
/// (PENDING stays "pending", "confirmed" only if the server says so); no
/// payment, voucher, QR, invoice or confirmation is fabricated (those are later
/// phases). Payment is signposted as the next step, not performed here.
class BookingResultScreen extends StatelessWidget {
  final Place hotel;
  final HotelStayCriteria? criteria;

  const BookingResultScreen({super.key, required this.hotel, this.criteria});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final record = app.lastCreatedBooking;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.bookingResultTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: record == null
              ? Center(
                  child: OceanEmptyState(
                    key: const Key('booking-result-missing'),
                    title: l10n.bookingResultTitle,
                    message: l10n.bookingDraftQuoteMissingMessage,
                  ),
                )
              : ListView(
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
                        key: const Key('booking-result-content'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _sections(context, app, l10n, record),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _sections(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
    BookingCreateRecord record,
  ) {
    final view = record.statusView;
    final (String headline, String body) = _statusCopy(l10n, view, record);
    final quotedPrice = app.bookingQuote?.finalQuotedPrice;
    final priceChanged = quotedPrice != null &&
        record.finalPrice != null &&
        (record.finalPrice! - quotedPrice).abs() >= 0.5;
    return [
      Semantics(
        liveRegion: true,
        label: '$headline. $body',
        child: OceanGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _statusIcon(view),
                    color: AppColors.ocean,
                    size: AppIconSizes.lg,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      headline,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(body, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              _CodeRow(
                label: l10n.bookingResultCodeLabel,
                code: record.bookingCode,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    '${l10n.bookingResultStatusLabel}: ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  BookingStatusChip(
                    view: view,
                    label: bookingStatusChipLabel(l10n, view, record.status),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      BookingResultSummaryCard(record: record),
      const SizedBox(height: AppSpacing.md),
      BookingResultPriceCard(record: record),
      if (priceChanged) ...[
        const SizedBox(height: AppSpacing.md),
        OceanGlassSurface(
          key: const Key('booking-result-price-changed'),
          blur: 0,
          color: AppColors.paleCyan,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.ocean),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.bookingPriceChangedNote,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      OceanGlassSurface(
        blur: 0,
        color: AppColors.paleCyan,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.payments_outlined, color: AppColors.ocean),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.bookingResultPaymentNextNote,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      if ((criteria?.tripId) == null) ...[
        OceanSecondaryButton(
          key: const Key('booking-result-add-trip'),
          label: l10n.placeAddToTrip,
          icon: Icons.map_rounded,
          onPressed: () => showAddToTripSheet(context, hotel),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      OceanPrimaryButton(
        key: const Key('booking-result-done'),
        label: l10n.bookingResultDoneAction,
        icon: Icons.check_rounded,
        semanticLabel: l10n.bookingResultDoneAction,
        onPressed: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    ];
  }

  (String, String) _statusCopy(
    AppLocalizations l10n,
    BookingStatusView view,
    BookingCreateRecord record,
  ) {
    switch (view) {
      case BookingStatusView.pending:
        return (
          l10n.bookingStatusPendingHeadline,
          l10n.bookingStatusPendingBody
        );
      case BookingStatusView.confirmed:
        return (
          l10n.bookingStatusConfirmedHeadline,
          l10n.bookingStatusConfirmedBody
        );
      default:
        final label = bookingStatusChipLabel(l10n, view, record.status);
        return (
          l10n.bookingStatusGenericHeadline(label),
          l10n.bookingResultPaymentNextNote,
        );
    }
  }

  IconData _statusIcon(BookingStatusView view) {
    switch (view) {
      case BookingStatusView.confirmed:
      case BookingStatusView.completed:
      case BookingStatusView.checkedOut:
        return Icons.verified_rounded;
      case BookingStatusView.cancelled:
      case BookingStatusView.refunded:
      case BookingStatusView.noShow:
        return Icons.cancel_rounded;
      default:
        return Icons.assignment_turned_in_rounded;
    }
  }
}

/// Booking code row with a screen-reader-friendly, character-spelled semantic
/// label (the compact code is shown visually).
class _CodeRow extends StatelessWidget {
  final String label;
  final String code;

  const _CodeRow({required this.label, required this.code});

  @override
  Widget build(BuildContext context) {
    final spelled = code.split('').join(' ');
    return Semantics(
      label: '$label: $spelled',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Text(
              '$label: ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Expanded(
              child: SelectableText(
                code,
                key: const Key('booking-result-code'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ocean,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
