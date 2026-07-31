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

/// Final step of the UI25 booking flow. This is an honest "Booking Ready"
/// screen — it presents the prepared [BookingDraft], not a confirmation. No
/// reservation was created, no payment taken, and no confirmation number is
/// shown, because none exists (the create/payment steps are deferred).
class BookingReadyScreen extends StatelessWidget {
  final Place hotel;

  const BookingReadyScreen({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final draft = app.bookingDraft;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.bookingReadyTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: draft == null
              ? Center(
                  child: OceanEmptyState(
                    key: const Key('booking-ready-missing'),
                    title: l10n.bookingReadyTitle,
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
                        key: const Key('booking-ready-content'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            liveRegion: true,
                            label: l10n.bookingReadySemantic,
                            child: OceanGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.assignment_turned_in_rounded,
                                        color: AppColors.ocean,
                                        size: AppIconSizes.lg,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          l10n.bookingReadyHeadline,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    l10n.bookingReadyBody,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          BookingStayCard(
                            hotelName: draft.hotelName,
                            roomName: draft.roomName,
                            checkIn: draft.checkIn,
                            checkOut: draft.checkOut,
                            nights: draft.nights,
                            adults: draft.adults,
                            children: draft.children,
                            tripLinked: draft.tripId != null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          BookingPlanCard(quote: draft.quote),
                          const SizedBox(height: AppSpacing.md),
                          BookingGuestCard(
                            guest: draft.guest,
                            presets: draft.specialRequestPresets,
                            note: draft.specialRequestNote,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          BookingPriceCard(quote: draft.quote),
                          const SizedBox(height: AppSpacing.lg),
                          if (draft.tripId == null)
                            OceanSecondaryButton(
                              key: const Key('booking-ready-add-trip'),
                              label: l10n.placeAddToTrip,
                              icon: Icons.map_rounded,
                              onPressed: () =>
                                  showAddToTripSheet(context, hotel),
                            ),
                          if (draft.tripId == null)
                            const SizedBox(height: AppSpacing.sm),
                          OceanPrimaryButton(
                            key: const Key('booking-ready-done'),
                            label: l10n.bookingReadyDoneAction,
                            icon: Icons.check_rounded,
                            semanticLabel: l10n.bookingReadyDoneAction,
                            onPressed: () => Navigator.of(context)
                                .popUntil((route) => route.isFirst),
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
