import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'booking_guest_info_screen.dart';
import 'booking_widgets.dart';

/// Step 1 of the UI25 booking flow. Shows the backend-priced summary for the
/// room selected in UI24 over the current stay, fetched from the real read-only
/// quote endpoint (`POST /api/rooms/{id}/pricing/quote`). No reservation is
/// created here. Reached only in Real Mode via the availability "Continue to
/// booking" CTA (which gates on a selected room).
class BookingSummaryScreen extends StatefulWidget {
  final Place hotel;
  final HotelStayCriteria criteria;

  const BookingSummaryScreen({
    super.key,
    required this.hotel,
    required this.criteria,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadQuote();
    });
  }

  Future<void> _loadQuote({bool refresh = false}) async {
    final app = AppScope.of(context);
    final roomId = app.selectedRoomId;
    if (roomId == null) return;
    await app.loadBookingQuote(
      roomId: roomId,
      checkIn: widget.criteria.checkIn,
      checkOut: widget.criteria.checkOut,
      adults: widget.criteria.adults,
      children: widget.criteria.children,
      extraBeds: widget.criteria.extraBeds,
      ratePlanId: app.selectedRatePlanId,
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

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingGuestInfoScreen(
          hotel: widget.hotel,
          criteria: widget.criteria,
        ),
      ),
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
        title: Text(l10n.bookingSummaryTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => _loadQuote(refresh: true),
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
                      const BookingStepHeader(current: 1, total: 3),
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
    if (app.bookingQuoteLoading && app.bookingQuote == null) {
      return Padding(
        key: const Key('booking-summary-loading'),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: OceanLoadingState(message: l10n.bookingQuoteLoadingMessage),
      );
    }

    final error = app.bookingQuoteError;
    if (error != null && app.bookingQuote == null) {
      if (error == BookingQuoteOutcome.sessionExpired) {
        return OceanEmptyState(
          key: const Key('booking-summary-session-expired'),
          title: l10n.tripsRealSessionExpiredTitle,
          message: l10n.tripsRealSessionExpiredMessage,
          actionLabel: l10n.tripsRealSignInAction,
          onAction: _reauth,
        );
      }
      final message = switch (error) {
        BookingQuoteOutcome.forbidden => l10n.tripRealPermissionDeniedMessage,
        BookingQuoteOutcome.invalidDates =>
          l10n.bookingQuoteInvalidDatesMessage,
        _ => l10n.bookingQuoteErrorMessage,
      };
      return OceanRecoverableErrorState(
        key: const Key('booking-summary-error'),
        message: message,
        onReload: () => _loadQuote(refresh: true),
      );
    }

    final quote = app.bookingQuote;
    if (quote == null) {
      // No selection / not yet loaded — show a gentle loading placeholder
      // rather than a fabricated state.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: OceanLoadingState(message: l10n.bookingQuoteLoadingMessage),
      );
    }

    final room = app.selectedRoom;
    return Column(
      key: const Key('booking-summary-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        BookingPriceCard(quote: quote),
        const SizedBox(height: AppSpacing.lg),
        OceanPrimaryButton(
          key: const Key('booking-summary-continue'),
          label: l10n.bookingGuestInfoContinueAction,
          icon: Icons.person_outline_rounded,
          semanticLabel: l10n.bookingGuestInfoContinueAction,
          onPressed: _continue,
        ),
      ],
    );
  }
}
