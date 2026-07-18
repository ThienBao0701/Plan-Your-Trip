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
import '../bookings/my_bookings_screen.dart';
import '../expenses/expenses_screen.dart';
import '../home/app_shell.dart';
import '../timeline/timeline_screen.dart';
import 'hotel_utils.dart';

class HotelBookingConfirmationScreen extends StatefulWidget {
  final DemoBooking booking;

  const HotelBookingConfirmationScreen({
    super.key,
    required this.booking,
  });

  @override
  State<HotelBookingConfirmationScreen> createState() =>
      _HotelBookingConfirmationScreenState();
}

class _HotelBookingConfirmationScreenState
    extends State<HotelBookingConfirmationScreen> {
  bool _adding = false;
  bool _savingToWallet = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booking = _currentBooking(context);
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.bookingConfirmationTitle),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OceanGlassCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.ocean,
                            size: 64,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.bookingConfirmationTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          OceanStatusPill(
                            label: l10n.bookingDemoStatus,
                            icon: Icons.science_rounded,
                            color: AppColors.ocean,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.bookingLocalCode(booking.code),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OceanGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.hotel.name,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: AppSpacing.xs),
                          Text(booking.room.roomName,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.md),
                          _Info(
                            icon: Icons.calendar_month_rounded,
                            text:
                                '${date.format(booking.criteria.checkIn)} - ${date.format(booking.criteria.checkOut)} · ${l10n.hotelNights(booking.criteria.nights)}',
                          ),
                          _Info(
                            icon: Icons.group_rounded,
                            text: l10n.hotelGuestSummary(
                              booking.criteria.adults,
                              booking.criteria.children,
                            ),
                          ),
                          _Info(
                            icon: Icons.policy_rounded,
                            text: booking.ratePlan.rateName,
                          ),
                          _Info(
                            icon: Icons.payments_rounded,
                            text: formatMoney(
                              context,
                              booking.quote.finalQuotedPrice ?? 0,
                              booking.quote.currency,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OceanGlassSurface(
                      blur: 0,
                      color: AppColors.paleCyan,
                      child: Text(
                        l10n.bookingConfirmationLocalOnly,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OceanPrimaryButton(
                      key: const Key('booking-add-itinerary'),
                      label: booking.itineraryAdded
                          ? l10n.bookingItineraryAdded
                          : l10n.bookingAddItineraryAction,
                      icon: Icons.event_available_rounded,
                      semanticLabel: l10n.bookingAddItinerarySemantic,
                      onPressed:
                          _adding ? null : () => _addToItinerary(booking),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OceanSecondaryButton(
                      key: const Key('booking-save-wallet'),
                      label: l10n.walletSaveBookingAction,
                      icon: Icons.wallet_rounded,
                      semanticLabel: l10n.walletSaveBookingSemantic,
                      onPressed: _savingToWallet
                          ? null
                          : () => _saveBookingToWallet(booking),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OceanSecondaryButton(
                      key: const Key('booking-view-booking'),
                      label: l10n.bookingViewBookingAction,
                      icon: Icons.list_alt_rounded,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyBookingsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OceanSecondaryButton(
                      label: l10n.bookingReturnHomeAction,
                      icon: Icons.home_rounded,
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AppShell()),
                        (_) => false,
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

  DemoBooking _currentBooking(BuildContext context) {
    final app = AppScope.of(context);
    for (final item in app.demoBookings) {
      if (item.code == widget.booking.code) return item;
    }
    return widget.booking;
  }

  Future<void> _addToItinerary(DemoBooking booking) async {
    if (_adding) return;
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (booking.itineraryAdded ||
        itineraryAlreadyHasBooking(app.timeline, booking)) {
      app.markDemoBookingItineraryAdded(booking.code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingItineraryAlreadyAdded)),
      );
      return;
    }
    final tripId = booking.criteria.tripId;
    final trip = tripId == null ? null : app.tripById(tripId);
    if (trip == null) {
      await showAddToTripSheet(context, booking.hotel);
      return;
    }
    setState(() => _adding = true);
    final day = booking.criteria.checkIn
            .difference(DateTime(
                trip.startDate.year, trip.startDate.month, trip.startDate.day))
            .inDays +
        1;
    final clampedDay = day.clamp(1, trip.days);
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
    setState(() => _adding = false);
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.activitySaveFailed)),
      );
      return;
    }
    app.markDemoBookingItineraryAdded(booking.code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.walletActionUnavailable)),
      );
      return;
    }
    final existed = app.travelWalletItems
        .any((item) => item.linkedBookingId == booking.code);
    setState(() => _savingToWallet = true);
    final imported = app.importDemoBookingToWallet(booking.code);
    if (!mounted) return;
    setState(() => _savingToWallet = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          imported == null
              ? l10n.walletActionUnavailable
              : existed
                  ? l10n.walletBookingAlreadyImportedMessage
                  : l10n.walletBookingImportedMessage,
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Info({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: AppColors.ocean),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      );
}
