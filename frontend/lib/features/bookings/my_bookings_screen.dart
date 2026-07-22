import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/add_to_trip_sheet.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../expenses/expenses_screen.dart';
import '../hotels/hotel_utils.dart';
import '../payments/secure_checkout_screen.dart';
import '../places/place_detail_screen.dart';
import '../reviews/reviews_screen.dart';
import '../timeline/timeline_screen.dart';
import 'modify_booking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  final DateTime? today;

  const MyBookingsScreen({super.key, this.today});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  BookingSection _section = BookingSection.all;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final today = widget.today ?? app.now();
    final bookings = app.demoBookings
        .where((booking) => bookingInSection(booking, _section, today: today))
        .toList()
      ..sort((a, b) {
        final date = a.criteria.checkIn.compareTo(b.criteria.checkIn);
        return date == 0 ? a.code.compareTo(b.code) : date;
      });

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.myBookingsTitle),
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
                child: !app.demoMode
                    ? OceanEmptyState(
                        title: l10n.myBookingsRealEmptyTitle,
                        message: l10n.myBookingsRealEmptyMessage,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.myBookingsTitle,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.myBookingsDemoLocalOnly,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _SectionSwitch(
                            selected: _section,
                            onChanged: (section) =>
                                setState(() => _section = section),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (bookings.isEmpty)
                            OceanEmptyState(
                              title: l10n.myBookingsEmptyTitle,
                              message: l10n.myBookingsEmptyMessage,
                            )
                          else
                            for (final booking in bookings)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: _BookingCard(
                                  booking: booking,
                                  onTap: () => _openBooking(booking, today),
                                ),
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

  void _openBooking(DemoBooking booking, DateTime today) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(
          bookingCode: booking.code,
          fallbackBooking: booking,
          today: today,
        ),
      ),
    );
  }
}

class _SectionSwitch extends StatelessWidget {
  final BookingSection selected;
  final ValueChanged<BookingSection> onChanged;

  const _SectionSwitch({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<BookingSection>(
        segments: [
          for (final section in BookingSection.values)
            ButtonSegment(
              value: section,
              label: Text(bookingSectionLabel(l10n, section)),
            ),
        ],
        selected: {selected},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final DemoBooking booking;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return OceanGlassCard(
      key: Key('booking-card-${booking.code}'),
      onTap: onTap,
      semanticLabel: l10n.myBookingCardSemantic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  booking.hotel.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              OceanStatusPill(
                label: bookingStatusLabel(l10n, booking.status),
                icon: Icons.verified_rounded,
                color: booking.status == BookingStatus.cancelled
                    ? AppColors.danger
                    : AppColors.ocean,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(booking.room.roomName,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label:
                    '${date.format(booking.criteria.checkIn)} - ${date.format(booking.criteria.checkOut)}',
                icon: Icons.calendar_month_rounded,
              ),
              Semantics(
                label: l10n.bookingCodeSemantic,
                child: ExcludeSemantics(
                  child: OceanStatusPill(
                    label: booking.code,
                    icon: Icons.confirmation_number_rounded,
                    color: AppColors.turquoise600,
                  ),
                ),
              ),
              if (booking.quote.finalQuotedPrice != null)
                OceanStatusPill(
                  label: formatMoney(
                    context,
                    booking.quote.finalQuotedPrice!,
                    booking.quote.currency,
                  ),
                  icon: Icons.payments_rounded,
                  color: AppColors.success,
                ),
              if (booking.paymentStatus != null)
                OceanStatusPill(
                  label: bookingPaymentStatusLabel(
                    l10n,
                    booking.paymentStatus!,
                  ),
                  icon: Icons.account_balance_wallet_rounded,
                  color: _paymentStatusColor(booking.paymentStatus!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class BookingDetailScreen extends StatefulWidget {
  final String bookingCode;
  final DemoBooking? fallbackBooking;
  final DateTime? today;

  const BookingDetailScreen({
    super.key,
    required this.bookingCode,
    this.fallbackBooking,
    this.today,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _addingToTrip = false;
  bool _savingToWallet = false;
  bool _cancelling = false;
  bool _paymentWorking = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final booking = app.demoBookingByCode(widget.bookingCode);
    final paymentAttempt = booking == null
        ? null
        : app.latestPaymentAttemptForBooking(booking.code);
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.bookingDetailsTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('booking-detail-screen'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: !app.demoMode
                    ? OceanEmptyState(
                        title: l10n.myBookingsRealEmptyTitle,
                        message: l10n.myBookingsRealEmptyMessage,
                      )
                    : booking == null
                        ? OceanEmptyState(
                            title: l10n.bookingDetailMissingTitle,
                            message: l10n.bookingDetailMissingMessage,
                          )
                        : _BookingDetailContent(
                            booking: booking,
                            paymentAttempt: paymentAttempt,
                            addingToTrip: _addingToTrip,
                            savingToWallet: _savingToWallet,
                            cancelling: _cancelling,
                            paymentWorking: _paymentWorking,
                            onAddToTrip: () => _addToItinerary(booking),
                            onSaveWallet: () => _saveBookingToWallet(booking),
                            onWriteReview: () => _openWriteReview(booking),
                            onViewReview: (review) => _openReview(review),
                            onCancel: () => _confirmCancel(booking),
                            onModify: () => _openModify(booking),
                            onOpenPayment: paymentAttempt == null
                                ? null
                                : () => _openPaymentStatus(
                                      booking,
                                      paymentAttempt,
                                    ),
                            onStartCheckout: paymentAttempt == null
                                ? () => _openCheckoutForBooking(booking)
                                : null,
                            onRetryPayment: paymentAttempt == null
                                ? null
                                : () => _retryPayment(booking),
                            onViewPlace: () => _openPlace(booking),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToItinerary(DemoBooking booking) async {
    if (_addingToTrip) return;
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (booking.itineraryAdded ||
        itineraryAlreadyHasBooking(app.timeline, booking)) {
      app.markDemoBookingItineraryAdded(booking.code);
      if (!mounted) return;
      _showSnack(l10n.bookingItineraryAlreadyAdded);
      return;
    }
    final tripId = booking.criteria.tripId;
    final trip = tripId == null ? null : app.tripById(tripId);
    if (trip == null) {
      await showAddToTripSheet(context, booking.hotel);
      return;
    }
    setState(() => _addingToTrip = true);
    final day = booking.criteria.checkIn
            .difference(DateTime(
              trip.startDate.year,
              trip.startDate.month,
              trip.startDate.day,
            ))
            .inDays +
        1;
    final clampedDay = day.clamp(1, trip.days).toInt();
    final added = app.addTimeline(
      TimelineItem(
        id: app.newId,
        tripId: trip.id,
        dayNumber: clampedDay,
        startTime: booking.hotel.hotelDetail?.checkInTime ?? '15:00',
        endTime: '16:00',
        title: booking.hotel.name,
        notes: l10n.bookingItineraryNote(booking.code),
        place: booking.hotel,
        placeId: booking.hotel.id,
        category: 'Hotel',
        estimatedCost: booking.quote.finalQuotedPrice ?? 0,
      ),
    );
    if (!mounted) return;
    setState(() => _addingToTrip = false);
    if (!added) {
      _showSnack(l10n.activitySaveFailed);
      return;
    }
    app.markDemoBookingItineraryAdded(booking.code);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.bookingItineraryAddedMessage),
          action: SnackBarAction(
            label: l10n.plannerOpenTimelineAction,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TimelineScreen(trip: trip)),
            ),
          ),
        ),
      );
  }

  Future<void> _saveBookingToWallet(DemoBooking booking) async {
    if (_savingToWallet) return;
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (!app.demoMode) {
      _showSnack(l10n.walletActionUnavailable);
      return;
    }
    final existed = app.travelWalletItems
        .any((item) => item.linkedBookingId == booking.code);
    setState(() => _savingToWallet = true);
    final imported = app.importDemoBookingToWallet(booking.code);
    if (!mounted) return;
    setState(() => _savingToWallet = false);
    _showSnack(
      imported == null
          ? l10n.walletActionUnavailable
          : existed
              ? l10n.walletBookingAlreadyImportedMessage
              : l10n.walletBookingImportedMessage,
    );
  }

  void _openWriteReview(DemoBooking booking) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final eligibility = app.reviewEligibilityForBooking(booking);
    if (!eligibility.canReview) {
      _showSnack(reviewActionMessage(l10n, eligibility.result));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WriteReviewScreen(booking: booking)),
    );
  }

  void _openReview(TravelerReview review) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewDetailScreen(
          reviewId: review.id,
          authorView: true,
        ),
      ),
    );
  }

  void _openPlace(DemoBooking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PlaceDetailScreen(place: booking.hotel)),
    );
  }

  void _openPaymentStatus(
    DemoBooking booking,
    DemoPaymentAttempt attempt,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentStatusScreen(
          bookingCode: booking.code,
          attemptId: attempt.id,
        ),
      ),
    );
  }

  Future<void> _openModify(DemoBooking booking) async {
    final l10n = AppLocalizations.of(context)!;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ModifyBookingScreen(
          bookingCode: booking.code,
          today: widget.today,
        ),
      ),
    );
    if (!mounted) return;
    if (changed == true) {
      setState(() {});
      _showSnack(l10n.bookingModifySuccessMessage);
    }
  }

  void _openCheckoutForBooking(DemoBooking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecureCheckoutScreen(
          hotel: booking.hotel,
          room: booking.room,
          ratePlan: booking.ratePlan,
          criteria: booking.criteria,
          quote: booking.quote,
          specialRequest: booking.specialRequest,
          existingBookingCode: booking.code,
        ),
      ),
    );
  }

  Future<void> _retryPayment(DemoBooking booking) async {
    if (_paymentWorking) return;
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _paymentWorking = true);
    final result = app.retryDemoPayment(booking.code);
    if (!mounted) return;
    setState(() => _paymentWorking = false);
    if (result.attempt != null) {
      _openPaymentStatus(result.booking ?? booking, result.attempt!);
      return;
    }
    _showSnack(paymentActionResultMessage(l10n, result.result));
  }

  Future<void> _confirmCancel(DemoBooking booking) async {
    if (_cancelling) return;
    final reason = await showDialog<String?>(
      context: context,
      builder: (_) => _CancelBookingDialog(booking: booking),
    );
    if (reason == null || !mounted) return;
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _cancelling = true);
    final result =
        app.cancelDemoBookingWithResult(booking.code, reason: reason);
    if (!mounted) return;
    setState(() => _cancelling = false);
    _showSnack(bookingCancellationResultMessage(l10n, result));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BookingDetailContent extends StatelessWidget {
  final DemoBooking booking;
  final DemoPaymentAttempt? paymentAttempt;
  final bool addingToTrip;
  final bool savingToWallet;
  final bool cancelling;
  final bool paymentWorking;
  final VoidCallback onAddToTrip;
  final VoidCallback onSaveWallet;
  final VoidCallback onWriteReview;
  final ValueChanged<TravelerReview> onViewReview;
  final VoidCallback onCancel;
  final VoidCallback onModify;
  final VoidCallback? onOpenPayment;
  final VoidCallback? onStartCheckout;
  final VoidCallback? onRetryPayment;
  final VoidCallback onViewPlace;

  const _BookingDetailContent({
    required this.booking,
    required this.paymentAttempt,
    required this.addingToTrip,
    required this.savingToWallet,
    required this.cancelling,
    required this.paymentWorking,
    required this.onAddToTrip,
    required this.onSaveWallet,
    required this.onWriteReview,
    required this.onViewReview,
    required this.onCancel,
    required this.onModify,
    required this.onOpenPayment,
    required this.onStartCheckout,
    required this.onRetryPayment,
    required this.onViewPlace,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final total = booking.quote.finalQuotedPrice;
    final eligibility = app.cancellationEligibilityForBooking(booking);
    final modificationEligibility =
        app.modificationEligibilityForBooking(booking);
    final review = _currentUserReview(app, booking);
    final reviewEligibility = app.reviewEligibilityForBooking(booking);
    final cancellationDeadline = booking.quote.cancellationDeadline;
    final freeCancellationDeadlinePassed =
        booking.quote.cancellationPolicyType ==
                CancellationPolicyType.freeCancellation &&
            cancellationDeadline != null &&
            app.now().toUtc().isAfter(cancellationDeadline.toUtc());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          semanticLabel: l10n.bookingDetailSemantic,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  OceanStatusPill(
                    label: l10n.bookingDemoStatus,
                    icon: Icons.science_rounded,
                    color: AppColors.ocean,
                  ),
                  OceanStatusPill(
                    label: bookingStatusLabel(l10n, booking.status),
                    icon: Icons.verified_rounded,
                    color: _bookingStatusColor(booking.status),
                  ),
                  if (booking.paymentStatus != null)
                    OceanStatusPill(
                      label: bookingPaymentStatusLabel(
                        l10n,
                        booking.paymentStatus!,
                      ),
                      icon: Icons.payments_rounded,
                      color: AppColors.success,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                booking.hotel.name,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                booking.room.roomName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.bookingConfirmationLocalOnly,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _BookingMetrics(booking: booking),
        const SizedBox(height: AppSpacing.md),
        _BookingActionsCard(
          booking: booking,
          eligibility: eligibility,
          modificationEligibility: modificationEligibility,
          reviewEligibility: reviewEligibility,
          review: review,
          addingToTrip: addingToTrip,
          savingToWallet: savingToWallet,
          cancelling: cancelling,
          paymentWorking: paymentWorking,
          paymentAttempt: paymentAttempt,
          onAddToTrip: onAddToTrip,
          onSaveWallet: onSaveWallet,
          onWriteReview: onWriteReview,
          onViewReview: onViewReview,
          onCancel: onCancel,
          onModify: onModify,
          onOpenPayment: onOpenPayment,
          onStartCheckout: onStartCheckout,
          onRetryPayment: onRetryPayment,
          onViewPlace: onViewPlace,
        ),
        const SizedBox(height: AppSpacing.md),
        _BookingSectionCard(
          title: l10n.bookingStayOverviewTitle,
          icon: Icons.hotel_rounded,
          children: [
            _DetailRow(
              icon: Icons.confirmation_number_rounded,
              label: l10n.bookingCodeLabel,
              value: l10n.bookingLocalCode(booking.code),
              semanticValue: l10n.bookingCodeSemantic,
            ),
            _DetailRow(
              icon: Icons.calendar_month_rounded,
              label: l10n.bookingDatesLabel,
              value:
                  '${date.format(booking.criteria.checkIn)} - ${date.format(booking.criteria.checkOut)}',
            ),
            _DetailRow(
              icon: Icons.nights_stay_rounded,
              label: l10n.bookingNightsLabel,
              value: l10n.hotelNights(booking.criteria.nights),
            ),
            _DetailRow(
              icon: Icons.group_rounded,
              label: l10n.bookingGuestsLabel,
              value: l10n.hotelGuestSummary(
                booking.criteria.adults,
                booking.criteria.children,
              ),
            ),
            _DetailRow(
              icon: Icons.meeting_room_rounded,
              label: l10n.bookingRoomsLabel,
              value: l10n.bookingRoomsValue(1),
            ),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: l10n.bookingCreatedLabel,
              value: _formatDateTime(context, booking.createdAt),
            ),
            if (booking.confirmedAt != null)
              _DetailRow(
                icon: Icons.check_circle_rounded,
                label: l10n.bookingConfirmedLabel,
                value: _formatDateTime(context, booking.confirmedAt!),
              ),
            if (booking.cancelledAt != null)
              _DetailRow(
                icon: Icons.cancel_rounded,
                label: l10n.bookingCancelledAtLabel,
                value: _formatDateTime(context, booking.cancelledAt!),
              ),
            if (booking.cancellationReason != null)
              _DetailRow(
                icon: Icons.notes_rounded,
                label: l10n.bookingCancellationReasonLabel,
                value: booking.cancellationReason!,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _BookingSectionCard(
          title: l10n.bookingSnapshotTitle,
          icon: Icons.bed_rounded,
          children: [
            _DetailRow(
              icon: Icons.king_bed_rounded,
              label: l10n.bookingRoomLabel,
              value: booking.room.roomName,
            ),
            _DetailRow(
              icon: Icons.tag_rounded,
              label: l10n.bookingRoomCodeLabel,
              value: booking.room.roomCode,
            ),
            _DetailRow(
              icon: Icons.policy_rounded,
              label: l10n.bookingRatePlanLabel,
              value: booking.ratePlan.rateName,
            ),
            if (booking.quote.mealPlanType != null)
              _DetailRow(
                icon: Icons.restaurant_rounded,
                label: l10n.bookingMealPlanLabel,
                value: mealPlanLabel(l10n, booking.quote.mealPlanType!),
              ),
            if (booking.quote.finalNightlyRate != null)
              _DetailRow(
                icon: Icons.payments_rounded,
                label: l10n.bookingFinalNightlyRate,
                value: _formatMoneyValue(
                  context,
                  booking.quote.finalNightlyRate,
                  booking.quote.currency,
                ),
              ),
            if (total != null)
              _DetailRow(
                icon: Icons.receipt_long_rounded,
                label: l10n.bookingTotalLabel,
                value:
                    _formatMoneyValue(context, total, booking.quote.currency),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _BookingSectionCard(
          title: l10n.bookingPolicyTitle,
          icon: Icons.gpp_maybe_rounded,
          children: [
            if (booking.quote.cancellationPolicyType != null)
              _DetailRow(
                icon: Icons.policy_rounded,
                label: l10n.bookingCancellationPolicyLabel,
                value: cancellationPolicyLabel(
                  l10n,
                  booking.quote.cancellationPolicyType!,
                  deadlinePassed: freeCancellationDeadlinePassed,
                ),
              ),
            if (booking.ratePlan.policySummary.trim().isNotEmpty)
              _DetailRow(
                icon: Icons.description_rounded,
                label: l10n.bookingPolicySummaryLabel,
                value: booking.ratePlan.policySummary,
              ),
            if (cancellationDeadline != null)
              _DetailRow(
                icon: Icons.timer_rounded,
                label: l10n.bookingCancellationDeadlineLabel,
                value: _formatDateTime(
                  context,
                  cancellationDeadline,
                ),
              ),
            if (freeCancellationDeadlinePassed)
              OceanGlassSurface(
                blur: 0,
                color: AppColors.paleCyan,
                child: Text(
                  l10n.bookingCancellationDeadlinePassedPolicy,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            _DetailRow(
              icon: booking.quote.refundable
                  ? Icons.check_circle_rounded
                  : Icons.block_rounded,
              label: l10n.bookingRefundableLabel,
              value: booking.quote.refundable
                  ? l10n.bookingRefundableYes
                  : l10n.bookingRefundableNo,
            ),
            OceanGlassSurface(
              blur: 0,
              color: AppColors.paleCyan,
              child: Text(
                l10n.bookingRefundBoundary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (paymentAttempt != null) ...[
          _BookingSectionCard(
            title: l10n.paymentDetailsTitle,
            icon: Icons.payments_rounded,
            children: [
              _DetailRow(
                icon: Icons.account_balance_wallet_rounded,
                label: l10n.paymentProviderLabel,
                value: paymentProviderLabel(l10n, paymentAttempt!.provider),
              ),
              _DetailRow(
                icon: Icons.sync_rounded,
                label: l10n.paymentSessionStatusLabel,
                value: paymentSessionStatusLabel(
                  l10n,
                  paymentAttempt!.sessionStatus,
                ),
              ),
              if (paymentAttempt!.paymentStatus != null)
                _DetailRow(
                  icon: Icons.price_check_rounded,
                  label: l10n.bookingPaymentStatusLabel,
                  value: bookingPaymentStatusLabel(
                    l10n,
                    paymentAttempt!.paymentStatus!,
                  ),
                ),
              if (paymentAttempt!.amountIsSafe)
                _DetailRow(
                  icon: Icons.receipt_long_rounded,
                  label: l10n.paymentAmountLabel,
                  value: formatMoney(
                    context,
                    paymentAttempt!.amount,
                    paymentAttempt!.currency,
                  ),
                ),
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: l10n.paymentCreatedLabel,
                value: _formatDateTime(context, paymentAttempt!.createdAt),
              ),
              if (paymentAttempt!.expiresAt != null &&
                  paymentAttempt!.isPending)
                _DetailRow(
                  icon: Icons.timer_rounded,
                  label: l10n.paymentHoldExpiresLabel,
                  value: _formatDateTime(context, paymentAttempt!.expiresAt!),
                ),
              if (paymentAttempt!.paidAt != null)
                _DetailRow(
                  icon: Icons.check_circle_rounded,
                  label: l10n.paymentPaidAtLabel,
                  value: _formatDateTime(context, paymentAttempt!.paidAt!),
                ),
              if (paymentAttempt!.failedAt != null)
                _DetailRow(
                  icon: Icons.error_rounded,
                  label: l10n.paymentFailedAtLabel,
                  value: _formatDateTime(context, paymentAttempt!.failedAt!),
                ),
              if (paymentAttempt!.cancelledAt != null)
                _DetailRow(
                  icon: Icons.cancel_rounded,
                  label: l10n.paymentCancelledAtLabel,
                  value: _formatDateTime(context, paymentAttempt!.cancelledAt!),
                ),
              if (paymentAttempt!.failureReason != null)
                _DetailRow(
                  icon: Icons.info_rounded,
                  label: l10n.paymentFailureReasonLabel,
                  value: paymentAttempt!.failureReason!,
                ),
              OceanGlassSurface(
                blur: 0,
                color: AppColors.paleCyan,
                child: Text(
                  l10n.paymentNoRefundInference,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _StatusTimelineCard(booking: booking),
      ],
    );
  }

  TravelerReview? _currentUserReview(AppState app, DemoBooking booking) {
    for (final review in app.myReviews()) {
      if (review.bookingCode == booking.code) return review;
    }
    return null;
  }
}

class _BookingActionsCard extends StatelessWidget {
  final DemoBooking booking;
  final DemoPaymentAttempt? paymentAttempt;
  final BookingCancellationEligibility eligibility;
  final BookingModificationEligibility modificationEligibility;
  final ReviewEligibility reviewEligibility;
  final TravelerReview? review;
  final bool addingToTrip;
  final bool savingToWallet;
  final bool cancelling;
  final bool paymentWorking;
  final VoidCallback onAddToTrip;
  final VoidCallback onSaveWallet;
  final VoidCallback onWriteReview;
  final ValueChanged<TravelerReview> onViewReview;
  final VoidCallback onCancel;
  final VoidCallback onModify;
  final VoidCallback? onOpenPayment;
  final VoidCallback? onStartCheckout;
  final VoidCallback? onRetryPayment;
  final VoidCallback onViewPlace;

  const _BookingActionsCard({
    required this.booking,
    required this.paymentAttempt,
    required this.eligibility,
    required this.modificationEligibility,
    required this.reviewEligibility,
    required this.review,
    required this.addingToTrip,
    required this.savingToWallet,
    required this.cancelling,
    required this.paymentWorking,
    required this.onAddToTrip,
    required this.onSaveWallet,
    required this.onWriteReview,
    required this.onViewReview,
    required this.onCancel,
    required this.onModify,
    required this.onOpenPayment,
    required this.onStartCheckout,
    required this.onRetryPayment,
    required this.onViewPlace,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final paymentAction = _paymentAction(l10n);
    return _BookingSectionCard(
      title: l10n.bookingActionsTitle,
      icon: Icons.touch_app_rounded,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OceanSecondaryButton(
              key: const Key('booking-detail-save-wallet'),
              label: l10n.walletSaveBookingAction,
              icon: Icons.wallet_rounded,
              semanticLabel: l10n.walletSaveBookingSemantic,
              fullWidth: false,
              onPressed: savingToWallet ? null : onSaveWallet,
            ),
            OceanSecondaryButton(
              key: const Key('booking-detail-add-itinerary'),
              label: booking.itineraryAdded ||
                      itineraryAlreadyHasBooking(app.timeline, booking)
                  ? l10n.bookingItineraryAdded
                  : l10n.bookingAddItineraryAction,
              icon: Icons.event_available_rounded,
              semanticLabel: l10n.bookingAddItinerarySemantic,
              fullWidth: false,
              onPressed: addingToTrip ? null : onAddToTrip,
            ),
            if (review != null)
              OceanSecondaryButton(
                key: const Key('booking-detail-view-review'),
                label: l10n.bookingViewReviewAction,
                icon: Icons.rate_review_rounded,
                fullWidth: false,
                onPressed: () => onViewReview(review!),
              )
            else
              OceanSecondaryButton(
                key: const Key('booking-detail-write-review'),
                label: l10n.reviewWriteAction,
                icon: Icons.rate_review_rounded,
                semanticLabel: l10n.reviewWriteSemantic(booking.hotel.name),
                fullWidth: false,
                onPressed: reviewEligibility.canReview
                    ? onWriteReview
                    : () {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                reviewActionMessage(
                                  l10n,
                                  reviewEligibility.result,
                                ),
                              ),
                            ),
                          );
                      },
              ),
            if (eligibility.canCancel)
              OceanSecondaryButton(
                key: const Key('booking-cancel'),
                label: l10n.bookingCancelAction,
                icon: Icons.cancel_rounded,
                semanticLabel: l10n.bookingCancelSemantic,
                fullWidth: false,
                onPressed: cancelling ? null : onCancel,
              ),
            if (modificationEligibility.canModify)
              OceanSecondaryButton(
                key: const Key('booking-detail-modify'),
                label: l10n.bookingModifyAction,
                icon: Icons.edit_calendar_rounded,
                semanticLabel: l10n.bookingModifySemantic,
                fullWidth: false,
                onPressed: onModify,
              ),
            if (paymentAction != null)
              OceanSecondaryButton(
                key: const Key('booking-detail-payment-action'),
                label: paymentAction.label,
                icon: paymentAction.icon,
                fullWidth: false,
                onPressed: paymentWorking ? null : paymentAction.onPressed,
              ),
            OceanSecondaryButton(
              key: const Key('booking-detail-view-place'),
              label: l10n.bookingViewPlaceAction,
              icon: Icons.place_rounded,
              fullWidth: false,
              onPressed: onViewPlace,
            ),
          ],
        ),
        if (!eligibility.canCancel) ...[
          const SizedBox(height: AppSpacing.md),
          OceanGlassSurface(
            blur: 0,
            color: AppColors.paleCyan,
            child: Text(
              bookingCancellationResultMessage(l10n, eligibility.result),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        if (!modificationEligibility.canModify) ...[
          const SizedBox(height: AppSpacing.md),
          OceanGlassSurface(
            blur: 0,
            color: AppColors.paleCyan,
            child: Text(
              bookingModificationResultMessage(
                l10n,
                modificationEligibility.result,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        OceanGlassSurface(
          blur: 0,
          color: AppColors.paleCyan,
          child: Text(
            l10n.bookingUnsupportedMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  ({String label, IconData icon, VoidCallback onPressed})? _paymentAction(
    AppLocalizations l10n,
  ) {
    final attempt = paymentAttempt;
    if (attempt == null) {
      if (booking.status == BookingStatus.pending && onStartCheckout != null) {
        return (
          label: l10n.paymentContinueAction,
          icon: Icons.lock_rounded,
          onPressed: onStartCheckout!,
        );
      }
      return null;
    }
    if (attempt.isPending && onOpenPayment != null) {
      return (
        label: l10n.paymentContinueAction,
        icon: Icons.hourglass_top_rounded,
        onPressed: onOpenPayment!,
      );
    }
    if (attempt.canRetry &&
        booking.status == BookingStatus.pending &&
        onRetryPayment != null) {
      return (
        label: l10n.paymentRetryAction,
        icon: Icons.refresh_rounded,
        onPressed: onRetryPayment!,
      );
    }
    if (onOpenPayment != null) {
      return (
        label: l10n.paymentStatusAction,
        icon: Icons.payments_rounded,
        onPressed: onOpenPayment!,
      );
    }
    return null;
  }
}

class _BookingMetrics extends StatelessWidget {
  final DemoBooking booking;

  const _BookingMetrics({required this.booking});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : AppBreakpoints.maxContentWidth;
        final twoColumns = available >= 620;
        final width = twoColumns ? (available - AppSpacing.sm) / 2 : available;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.nights_stay_rounded,
                label: l10n.bookingNightsLabel,
                value: l10n.hotelNights(booking.criteria.nights),
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.group_rounded,
                label: l10n.bookingGuestsLabel,
                value: l10n.hotelGuestSummary(
                  booking.criteria.adults,
                  booking.criteria.children,
                ),
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.receipt_long_rounded,
                label: l10n.bookingTotalLabel,
                value: _formatMoneyValue(
                  context,
                  booking.quote.finalQuotedPrice,
                  booking.quote.currency,
                ),
              ),
            ),
            SizedBox(
              width: width,
              child: _MetricCard(
                icon: Icons.payments_rounded,
                label: l10n.bookingPaymentStatusLabel,
                value: booking.paymentStatus == null
                    ? l10n.walletNoValue
                    : bookingPaymentStatusLabel(l10n, booking.paymentStatus!),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => OceanGlassCard(
        semanticLabel: '$label $value',
        child: Row(
          children: [
            Icon(icon, color: AppColors.ocean),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      );
}

class _BookingSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _BookingSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => OceanGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.ocean),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      );
}

class _StatusTimelineCard extends StatelessWidget {
  final DemoBooking booking;

  const _StatusTimelineCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final events = bookingTimelineFor(booking);
    return _BookingSectionCard(
      title: l10n.bookingTimelineTitle,
      icon: Icons.timeline_rounded,
      children: [
        if (events.isEmpty)
          _DetailRow(
            icon: Icons.info_rounded,
            label: l10n.bookingTimelineTitle,
            value: bookingStatusLabel(l10n, booking.status),
          )
        else
          for (final event in events)
            _DetailRow(
              icon: _timelineIcon(event.code),
              label: bookingTimelineEventLabel(l10n, event.code),
              value: _formatDateTime(context, event.occurredAt),
            ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? semanticValue;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.semanticValue,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label ${semanticValue ?? value}',
        excludeSemantics: semanticValue != null,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.ocean),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelLarge),
                    Text(value, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _CancelBookingDialog extends StatefulWidget {
  final DemoBooking booking;

  const _CancelBookingDialog({required this.booking});

  @override
  State<_CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<_CancelBookingDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final deadline = widget.booking.quote.cancellationDeadline;
    final deadlinePassed = widget.booking.quote.cancellationPolicyType ==
            CancellationPolicyType.freeCancellation &&
        deadline != null &&
        app.now().toUtc().isAfter(deadline.toUtc());
    return AlertDialog(
      title: Text(l10n.bookingCancelConfirmTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.bookingCancelConfirmMessage(widget.booking.code)),
            if (deadline != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.bookingCancellationDeadlineValue(
                  _formatDateTime(context, deadline),
                ),
              ),
            ],
            if (deadlinePassed) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.bookingCancellationDeadlinePassedPolicy),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('booking-cancel-reason-field'),
              controller: _reason,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.bookingCancelReasonLabel,
                helperText: l10n.bookingCancelReasonHelper,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.bookingCancellationLocalWarning),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.profileCancel),
        ),
        FilledButton.icon(
          key: const Key('booking-cancel-confirm'),
          onPressed: () => Navigator.pop(context, _reason.text),
          icon: const Icon(Icons.cancel_rounded),
          label: Text(l10n.bookingCancelAction),
        ),
      ],
    );
  }
}

String bookingSectionLabel(AppLocalizations l10n, BookingSection section) {
  switch (section) {
    case BookingSection.all:
      return l10n.bookingSectionAll;
    case BookingSection.upcoming:
      return l10n.bookingSectionUpcoming;
    case BookingSection.active:
      return l10n.bookingSectionActive;
    case BookingSection.history:
      return l10n.bookingSectionHistory;
    case BookingSection.cancelled:
      return l10n.bookingSectionCancelled;
  }
}

String bookingStatusLabel(AppLocalizations l10n, BookingStatus status) {
  switch (status) {
    case BookingStatus.pending:
      return l10n.bookingStatusPending;
    case BookingStatus.confirmed:
      return l10n.bookingStatusConfirmed;
    case BookingStatus.checkInReady:
      return l10n.bookingStatusCheckInReady;
    case BookingStatus.checkedIn:
      return l10n.bookingStatusCheckedIn;
    case BookingStatus.checkedOut:
      return l10n.bookingStatusCheckedOut;
    case BookingStatus.completed:
      return l10n.bookingStatusCompleted;
    case BookingStatus.cancelled:
      return l10n.bookingStatusCancelled;
    case BookingStatus.refunded:
      return l10n.bookingStatusRefunded;
    case BookingStatus.archived:
      return l10n.bookingStatusArchived;
    case BookingStatus.noShow:
      return l10n.bookingStatusNoShow;
  }
}

String bookingPaymentStatusLabel(
  AppLocalizations l10n,
  BookingPaymentStatus status,
) {
  switch (status) {
    case BookingPaymentStatus.pending:
      return l10n.bookingPaymentStatusPending;
    case BookingPaymentStatus.paid:
      return l10n.bookingPaymentStatusPaid;
    case BookingPaymentStatus.failed:
      return l10n.bookingPaymentStatusFailed;
    case BookingPaymentStatus.cancelled:
      return l10n.bookingPaymentStatusCancelled;
    case BookingPaymentStatus.refunded:
      return l10n.bookingPaymentStatusRefunded;
  }
}

String bookingCancellationResultMessage(
  AppLocalizations l10n,
  BookingCancellationResult result,
) {
  switch (result) {
    case BookingCancellationResult.eligible:
      return l10n.bookingCancelledMessage;
    case BookingCancellationResult.unavailable:
      return l10n.bookingCancellationUnavailableReal;
    case BookingCancellationResult.notFound:
      return l10n.bookingDetailMissingMessage;
    case BookingCancellationResult.forbidden:
      return l10n.bookingCancellationUnavailableForbidden;
    case BookingCancellationResult.alreadyCancelled:
      return l10n.bookingCancellationUnavailableAlready;
    case BookingCancellationResult.completed:
      return l10n.bookingCancellationUnavailableCompleted;
    case BookingCancellationResult.checkInStarted:
      return l10n.bookingCancellationUnavailableStarted;
    case BookingCancellationResult.unsupportedStatus:
      return l10n.bookingCancellationUnavailableGeneric;
  }
}

String bookingTimelineEventLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case 'CREATED':
      return l10n.bookingTimelineCreated;
    case 'PAID':
      return l10n.bookingTimelinePaid;
    case 'CONFIRMED':
      return l10n.bookingTimelineConfirmed;
    case 'MODIFIED':
      return l10n.bookingTimelineModified;
    case 'CHECKED_IN':
      return l10n.bookingTimelineCheckedIn;
    case 'CHECKED_OUT':
      return l10n.bookingTimelineCheckedOut;
    case 'COMPLETED':
      return l10n.bookingTimelineCompleted;
    case 'CANCELLED':
      return l10n.bookingTimelineCancelled;
    case 'ARCHIVED':
      return l10n.bookingTimelineArchived;
    case 'REFUNDED':
      return l10n.bookingTimelineRefunded;
    default:
      return l10n.bookingTimelineUnknown;
  }
}

String mealPlanLabel(AppLocalizations l10n, MealPlanType type) {
  switch (type) {
    case MealPlanType.roomOnly:
      return l10n.mealPlanRoomOnly;
    case MealPlanType.breakfast:
      return l10n.mealPlanBreakfast;
    case MealPlanType.halfBoard:
      return l10n.mealPlanHalfBoard;
    case MealPlanType.fullBoard:
      return l10n.mealPlanFullBoard;
    case MealPlanType.allInclusive:
      return l10n.mealPlanAllInclusive;
  }
}

String cancellationPolicyLabel(
    AppLocalizations l10n, CancellationPolicyType type,
    {bool deadlinePassed = false}) {
  switch (type) {
    case CancellationPolicyType.freeCancellation:
      return deadlinePassed
          ? l10n.cancellationFreeDeadlinePassed
          : l10n.cancellationFree;
    case CancellationPolicyType.partiallyRefundable:
      return l10n.cancellationPartial;
    case CancellationPolicyType.nonRefundable:
      return l10n.cancellationNonRefundable;
    case CancellationPolicyType.custom:
      return l10n.cancellationCustom;
  }
}

Color _bookingStatusColor(BookingStatus status) {
  switch (status) {
    case BookingStatus.cancelled:
    case BookingStatus.noShow:
      return AppColors.danger;
    case BookingStatus.completed:
    case BookingStatus.checkedOut:
    case BookingStatus.refunded:
      return AppColors.success;
    case BookingStatus.pending:
    case BookingStatus.checkInReady:
      return AppColors.warning;
    case BookingStatus.confirmed:
    case BookingStatus.checkedIn:
    case BookingStatus.archived:
      return AppColors.ocean;
  }
}

Color _paymentStatusColor(BookingPaymentStatus status) {
  switch (status) {
    case BookingPaymentStatus.paid:
    case BookingPaymentStatus.refunded:
      return AppColors.success;
    case BookingPaymentStatus.failed:
    case BookingPaymentStatus.cancelled:
      return AppColors.danger;
    case BookingPaymentStatus.pending:
      return AppColors.warning;
  }
}

IconData _timelineIcon(String code) {
  switch (code) {
    case 'CREATED':
      return Icons.add_circle_rounded;
    case 'PAID':
    case 'REFUNDED':
      return Icons.payments_rounded;
    case 'CONFIRMED':
      return Icons.verified_rounded;
    case 'MODIFIED':
      return Icons.edit_calendar_rounded;
    case 'CHECKED_IN':
      return Icons.login_rounded;
    case 'CHECKED_OUT':
      return Icons.logout_rounded;
    case 'COMPLETED':
      return Icons.check_circle_rounded;
    case 'CANCELLED':
      return Icons.cancel_rounded;
    case 'ARCHIVED':
      return Icons.archive_rounded;
    default:
      return Icons.info_rounded;
  }
}

String _formatDateTime(BuildContext context, DateTime value) {
  final formatter =
      DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_jm();
  return formatter.format(value.toLocal());
}

String _formatMoneyValue(
  BuildContext context,
  double? amount,
  String currency,
) {
  final l10n = AppLocalizations.of(context)!;
  if (amount == null || !amount.isFinite || amount < 0) {
    return l10n.walletNoValue;
  }
  return formatMoney(context, amount, currency);
}
