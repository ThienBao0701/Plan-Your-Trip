import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'booking_ready_screen.dart';
import 'booking_widgets.dart';

/// Step 3 of the UI25 booking flow. A read-only review of the stay, rate plan,
/// price, guest details and requests, gated behind an explicit terms
/// acknowledgement (CLAUDE.md §11) before the booking is prepared. "Prepare
/// booking" builds a client-side [BookingDraft] only — it never creates a
/// reservation, takes payment, or issues a confirmation number.
class BookingReviewScreen extends StatefulWidget {
  final Place hotel;
  final HotelStayCriteria criteria;

  const BookingReviewScreen({
    super.key,
    required this.hotel,
    required this.criteria,
  });

  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  void _prepare(AppState app) {
    final outcome = app.finalizeBookingDraft(tripId: widget.criteria.tripId);
    if (outcome == BookingDraftOutcome.ready) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingReadyScreen(hotel: widget.hotel),
        ),
      );
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final message = switch (outcome) {
      BookingDraftOutcome.invalid => l10n.bookingDraftInvalidMessage,
      BookingDraftOutcome.quoteMissing => l10n.bookingDraftQuoteMissingMessage,
      _ => l10n.bookingRealUnavailableMessage,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final quote = app.bookingQuote;
    final room = app.selectedRoom;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.bookingReviewTitle),
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
                child: quote == null
                    ? Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: OceanRecoverableErrorState(
                          key: const Key('booking-review-missing'),
                          message: l10n.bookingDraftQuoteMissingMessage,
                          onReload: () => Navigator.maybePop(context),
                        ),
                      )
                    : Column(
                        key: const Key('booking-review-content'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const BookingStepHeader(current: 3, total: 3),
                          BookingStayCard(
                            hotelName: widget.hotel.name,
                            roomName: room?.roomName ?? quote.roomName,
                            checkIn: widget.criteria.checkIn,
                            checkOut: widget.criteria.checkOut,
                            nights: quote.nights,
                            adults: quote.adults,
                            children: quote.children,
                            tripLinked: widget.criteria.tripId != null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          BookingPlanCard(quote: quote, room: room),
                          const SizedBox(height: AppSpacing.md),
                          BookingGuestCard(
                            guest: BookingGuestInfo(
                              fullName: app.bookingGuestName.trim(),
                              email: app.bookingContactEmail.trim(),
                              phone: app.bookingContactPhone.trim(),
                              country: app.bookingGuestCountry.trim(),
                              arrivalTime: app.bookingArrivalTime.trim(),
                            ),
                            presets: app.bookingSpecialRequestPresets,
                            note: app.bookingSpecialRequestNote,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          BookingPriceCard(quote: quote),
                          const SizedBox(height: AppSpacing.md),
                          OceanGlassSurface(
                            blur: 0,
                            color: AppColors.paleCyan,
                            child: Text(
                              l10n.bookingDraftNoReservationNote,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          CheckboxListTile(
                            key: const Key('booking-terms-checkbox'),
                            contentPadding: EdgeInsets.zero,
                            value: app.bookingTermsAccepted,
                            onChanged: (value) =>
                                app.setBookingTermsAccepted(value ?? false),
                            title: Text(l10n.bookingDraftTermsAcknowledgement),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          OceanPrimaryButton(
                            key: const Key('booking-prepare-action'),
                            label: l10n.bookingPrepareAction,
                            icon: Icons.assignment_turned_in_rounded,
                            semanticLabel: l10n.bookingPrepareSemantic,
                            onPressed: app.bookingTermsAccepted
                                ? () => _prepare(app)
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
}
