import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'booking_result_screen.dart';
import 'booking_widgets.dart';

/// Step 3 (final) of the booking flow. A read-only review of the stay, rate
/// plan, price, guest details and requests, gated behind an explicit terms
/// acknowledgement (CLAUDE.md §11). In Real Mode the "Create booking" action
/// performs the real `POST /api/bookings` submission (UI26) — the server's own
/// booking code / status / pricing is then shown on [BookingResultScreen]. On
/// any failure the draft/guest form are preserved; a submission that could not
/// be confirmed (timeout / malformed success) is surfaced as uncertain, never as
/// a clean failure the user could blindly resubmit.
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
  // The user has explicitly acknowledged that resubmitting after an uncertain
  // outcome may create a duplicate booking. Only then is a resubmit allowed.
  bool _acknowledgedUncertain = false;

  Future<void> _submit(AppState app) async {
    final l10n = AppLocalizations.of(context)!;
    final specialRequest = composeBookingSpecialRequest(
      l10n,
      app.bookingSpecialRequestPresets,
      app.bookingArrivalTime,
      app.bookingSpecialRequestNote,
    );
    final outcome = await app.submitRealBooking(
      specialRequest: specialRequest,
      tripId: widget.criteria.tripId,
    );
    if (!mounted) return;
    switch (outcome) {
      case BookingSubmissionOutcome.success:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingResultScreen(
              hotel: widget.hotel,
              criteria: widget.criteria,
            ),
          ),
        );
        return;
      case BookingSubmissionOutcome.sessionExpired:
        _reauth();
        return;
      case BookingSubmissionOutcome.uncertain:
        // Stay on the screen; the uncertain banner + acknowledgement gate render
        // from app state. Reset any prior acknowledgement so a fresh, explicit
        // one is required before another attempt.
        setState(() => _acknowledgedUncertain = false);
        return;
      case BookingSubmissionOutcome.busy:
        return;
      default:
        // Recoverable failure — draft preserved. Surface an honest message.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(_messageForOutcome(l10n, outcome))),
          );
    }
  }

  String _messageForOutcome(
    AppLocalizations l10n,
    BookingSubmissionOutcome outcome,
  ) {
    return switch (outcome) {
      BookingSubmissionOutcome.validation =>
        l10n.bookingSubmitValidationMessage,
      BookingSubmissionOutcome.forbidden => l10n.bookingSubmitForbiddenMessage,
      BookingSubmissionOutcome.notFound =>
        l10n.bookingSubmitRoomUnavailableMessage,
      BookingSubmissionOutcome.conflict => l10n.bookingSubmitConflictMessage,
      BookingSubmissionOutcome.unprocessable =>
        l10n.bookingSubmitUnprocessableMessage,
      BookingSubmissionOutcome.serverError =>
        l10n.bookingSubmitServerErrorMessage,
      BookingSubmissionOutcome.network => l10n.bookingSubmitNetworkMessage,
      BookingSubmissionOutcome.invalid => l10n.bookingDraftInvalidMessage,
      BookingSubmissionOutcome.quoteMissing =>
        l10n.bookingDraftQuoteMissingMessage,
      _ => l10n.bookingRealUnavailableMessage,
    };
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
    final quote = app.bookingQuote;
    final room = app.selectedRoom;
    final submitting = app.realBookingSubmitting;
    final uncertain = app.realBookingSubmissionUncertain;
    final canSubmit = app.bookingTermsAccepted &&
        !submitting &&
        (!uncertain || _acknowledgedUncertain);
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
                              l10n.bookingGuestLocalOnlyNote,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          CheckboxListTile(
                            key: const Key('booking-terms-checkbox'),
                            contentPadding: EdgeInsets.zero,
                            value: app.bookingTermsAccepted,
                            onChanged: submitting
                                ? null
                                : (value) =>
                                    app.setBookingTermsAccepted(value ?? false),
                            title: Text(l10n.bookingDraftTermsAcknowledgement),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          if (uncertain) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _UncertainBanner(
                              acknowledged: _acknowledgedUncertain,
                              onAcknowledgedChanged: (v) =>
                                  setState(() => _acknowledgedUncertain = v),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          if (submitting) ...[
                            Semantics(
                              liveRegion: true,
                              label: l10n.bookingCreatingLabel,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(l10n.bookingCreatingLabel),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          OceanPrimaryButton(
                            key: const Key('booking-submit-action'),
                            label: submitting
                                ? l10n.bookingCreatingLabel
                                : l10n.bookingCreateAction,
                            icon: Icons.check_circle_outline_rounded,
                            semanticLabel: l10n.bookingCreateSemantic,
                            onPressed: canSubmit ? () => _submit(app) : null,
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

/// Honest uncertain-submission warning: the booking may or may not have been
/// created. No blind resubmit — the user must explicitly acknowledge the
/// duplicate risk before another attempt is allowed.
class _UncertainBanner extends StatelessWidget {
  final bool acknowledged;
  final ValueChanged<bool> onAcknowledgedChanged;

  const _UncertainBanner({
    required this.acknowledged,
    required this.onAcknowledgedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: OceanGlassSurface(
        key: const Key('booking-submit-uncertain'),
        blur: 0,
        color: AppColors.paleCyan,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.help_outline_rounded, color: AppColors.coral),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.bookingSubmitUncertainTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.coral),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.bookingSubmitUncertainBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                key: const Key('booking-submit-uncertain-ack'),
                contentPadding: EdgeInsets.zero,
                value: acknowledged,
                onChanged: (v) => onAcknowledgedChanged(v ?? false),
                title: Text(l10n.bookingSubmitUncertainAcknowledge),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
