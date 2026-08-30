import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/partner/partner_booking_models.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_radii.dart';
import '../../../../design/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_widgets.dart';

/// Formats booking figures.
///
/// **Bookings do carry a currency**, unlike rate plans (C5) and promotions (C7):
/// `BookingResponse`, the summary, `PaymentResponse` and the invoice all supply
/// `String currency` (live: `"VND"`). Amounts are rendered with the server's own
/// code appended. No currency is converted and none is inferred from the app
/// locale — a null currency yields a bare number rather than a guessed symbol.
class PartnerBookingFormats {
  final NumberFormat amount;
  final NumberFormat integer;
  final DateFormat date;
  final DateFormat dateTime;

  PartnerBookingFormats(String locale)
      : amount = NumberFormat('#,##0.##', locale),
        integer = NumberFormat('#,##0', locale),
        date = DateFormat.yMMMd(locale),
        dateTime = DateFormat.yMMMd(locale).add_Hm();

  static PartnerBookingFormats of(BuildContext context) =>
      PartnerBookingFormats(Localizations.localeOf(context).toString());

  /// Qualifies an amount with the server-supplied currency code, or leaves it
  /// bare when the server sent none.
  String money(double? value, String? currency, String absent) {
    if (value == null) return absent;
    final formatted = amount.format(value);
    return currency == null ? formatted : '$formatted $currency';
  }
}

String partnerBookingStatusLabel(
  AppLocalizations l10n,
  PartnerBookingStatus status,
) =>
    switch (status) {
      PartnerBookingStatus.pending => l10n.partnerBookingStatusPending,
      PartnerBookingStatus.confirmed => l10n.partnerBookingStatusConfirmed,
      PartnerBookingStatus.checkInReady =>
        l10n.partnerBookingStatusCheckInReady,
      PartnerBookingStatus.checkedIn => l10n.partnerBookingStatusCheckedIn,
      PartnerBookingStatus.checkedOut => l10n.partnerBookingStatusCheckedOut,
      PartnerBookingStatus.completed => l10n.partnerBookingStatusCompleted,
      PartnerBookingStatus.cancelled => l10n.partnerBookingStatusCancelled,
      PartnerBookingStatus.refunded => l10n.partnerBookingStatusRefunded,
      PartnerBookingStatus.archived => l10n.partnerBookingStatusArchived,
      PartnerBookingStatus.noShow => l10n.partnerBookingStatusNoShow,
      PartnerBookingStatus.unknown => l10n.partnerBookingStatusUnknown,
    };

/// Colour and icon for a status. Colour is never the only signal — every pill
/// carries its own text label and an icon.
({Color color, IconData icon}) partnerBookingStatusVisual(
        PartnerBookingStatus status) =>
    switch (status) {
      PartnerBookingStatus.pending => (
          color: AppColors.warning,
          icon: Icons.schedule_rounded
        ),
      PartnerBookingStatus.confirmed => (
          color: AppColors.ocean600,
          icon: Icons.event_available_rounded
        ),
      PartnerBookingStatus.checkInReady => (
          color: AppColors.ocean700,
          icon: Icons.how_to_reg_outlined
        ),
      PartnerBookingStatus.checkedIn => (
          color: AppColors.success,
          icon: Icons.login_rounded
        ),
      PartnerBookingStatus.checkedOut => (
          color: AppColors.violet,
          icon: Icons.logout_rounded
        ),
      PartnerBookingStatus.completed => (
          color: AppColors.success,
          icon: Icons.task_alt_rounded
        ),
      PartnerBookingStatus.cancelled => (
          color: AppColors.danger,
          icon: Icons.cancel_outlined
        ),
      PartnerBookingStatus.refunded => (
          color: AppColors.danger,
          icon: Icons.currency_exchange_rounded
        ),
      PartnerBookingStatus.archived => (
          color: AppColors.textTertiary,
          icon: Icons.inventory_2_outlined
        ),
      PartnerBookingStatus.noShow => (
          color: AppColors.danger,
          icon: Icons.person_off_outlined
        ),
      PartnerBookingStatus.unknown => (
          color: AppColors.textTertiary,
          icon: Icons.help_outline_rounded
        ),
    };

String partnerStayStateLabel(AppLocalizations l10n, PartnerStayState state) =>
    switch (state) {
      PartnerStayState.upcoming => l10n.partnerStayStateUpcoming,
      PartnerStayState.readyForCheckIn => l10n.partnerStayStateReady,
      PartnerStayState.inHouse => l10n.partnerStayStateInHouse,
      PartnerStayState.checkedOut => l10n.partnerStayStateCheckedOut,
      PartnerStayState.completed => l10n.partnerStayStateCompleted,
      PartnerStayState.cancelled => l10n.partnerStayStateCancelled,
      PartnerStayState.noShow => l10n.partnerStayStateNoShow,
      PartnerStayState.expired => l10n.partnerStayStateExpired,
      PartnerStayState.unknown => l10n.partnerStayStateUnknown,
    };

String partnerStayWarningLabel(
  AppLocalizations l10n,
  PartnerStayWarning warning,
) =>
    switch (warning) {
      PartnerStayWarning.cancelledStay => l10n.partnerStayWarningCancelled,
      PartnerStayWarning.completedStay => l10n.partnerStayWarningCompleted,
      PartnerStayWarning.currentlyStaying => l10n.partnerStayWarningInHouse,
      PartnerStayWarning.checkOutOverdue =>
        l10n.partnerStayWarningCheckOutOverdue,
      PartnerStayWarning.futureBooking => l10n.partnerStayWarningFuture,
      PartnerStayWarning.checkInOverdue =>
        l10n.partnerStayWarningCheckInOverdue,
      PartnerStayWarning.unknown => l10n.partnerStayWarningUnknown,
    };

String partnerBookingActionLabel(
  AppLocalizations l10n,
  PartnerBookingAction action,
) =>
    switch (action) {
      PartnerBookingAction.checkIn => l10n.partnerBookingActionCheckIn,
      PartnerBookingAction.checkOut => l10n.partnerBookingActionCheckOut,
      PartnerBookingAction.noShow => l10n.partnerBookingActionNoShow,
      PartnerBookingAction.complete => l10n.partnerBookingActionComplete,
    };

String partnerBookingQuickFilterLabel(
  AppLocalizations l10n,
  PartnerBookingQuickFilter filter,
) =>
    switch (filter) {
      PartnerBookingQuickFilter.arrivalToday =>
        l10n.partnerBookingFilterArrivals,
      PartnerBookingQuickFilter.departureToday =>
        l10n.partnerBookingFilterDepartures,
      PartnerBookingQuickFilter.upcoming => l10n.partnerBookingFilterUpcoming,
      PartnerBookingQuickFilter.inHouse => l10n.partnerBookingFilterInHouse,
      PartnerBookingQuickFilter.cancelled => l10n.partnerBookingFilterCancelled,
      PartnerBookingQuickFilter.completed => l10n.partnerBookingFilterCompleted,
    };

/// Localizes a timeline event token.
///
/// The server also sends an English `description`; that is shown as supporting
/// detail rather than as the headline, so the primary label stays in the
/// operator's language.
String partnerBookingEventLabel(AppLocalizations l10n, String event) =>
    switch (event) {
      'CREATED' => l10n.partnerBookingEventCreated,
      'PAID' => l10n.partnerBookingEventPaid,
      'CONFIRMED' => l10n.partnerBookingEventConfirmed,
      'CHECKED_IN' => l10n.partnerBookingEventCheckedIn,
      'CHECKED_OUT' => l10n.partnerBookingEventCheckedOut,
      'COMPLETED' => l10n.partnerBookingEventCompleted,
      'CANCELLED' => l10n.partnerBookingEventCancelled,
      'ARCHIVED' => l10n.partnerBookingEventArchived,
      'MODIFIED' => l10n.partnerBookingEventModified,
      'REVIEW_SUBMITTED' => l10n.partnerBookingEventReview,
      _ => event,
    };

/// A booking status, as text plus icon plus colour — never colour alone.
class PartnerBookingStatusPill extends StatelessWidget {
  final PartnerBookingStatus status;

  const PartnerBookingStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = partnerBookingStatusVisual(status);
    return OceanStatusPill(
      label: partnerBookingStatusLabel(l10n, status),
      color: visual.color,
      icon: visual.icon,
    );
  }
}

/// A short inline statement — a limitation, a warning, or an explanation.
class PartnerBookingNotice extends StatelessWidget {
  final String message;
  final bool warning;

  const PartnerBookingNotice({
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

/// The dense desktop booking table.
///
/// Columns show only `PartnerBookingSummaryResponse` fields. `guestEmail` is on
/// the DTO but is **not** a column: a dense operational table is the wrong place
/// for a guest's contact address, and the detail panel already carries it where
/// a front desk would actually need it.
class PartnerBookingTable extends StatelessWidget {
  final List<PartnerBookingSummary> bookings;
  final int? openBookingId;
  final void Function(int bookingId) onOpen;

  const PartnerBookingTable({
    super.key,
    required this.bookings,
    required this.onOpen,
    this.openBookingId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerBookingFormats.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1020),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(178),
              1: FixedColumnWidth(150),
              2: FixedColumnWidth(160),
              3: FixedColumnWidth(112),
              4: FixedColumnWidth(112),
              5: FixedColumnWidth(64),
              6: FixedColumnWidth(148),
              7: FixedColumnWidth(150),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.divider),
                  ),
                ),
                children: [
                  _HeadCell(l10n.partnerBookingColumnCode),
                  _HeadCell(l10n.partnerBookingColumnGuest),
                  _HeadCell(l10n.partnerBookingColumnRoom),
                  _HeadCell(l10n.partnerBookingColumnCheckIn),
                  _HeadCell(l10n.partnerBookingColumnCheckOut),
                  _HeadCell(l10n.partnerBookingColumnNights),
                  _HeadCell(l10n.partnerBookingColumnStatus),
                  _HeadCell(l10n.partnerBookingColumnTotal),
                ],
              ),
              for (final booking in bookings)
                TableRow(
                  decoration: BoxDecoration(
                    color: openBookingId == booking.id
                        ? AppColors.ocean600.withValues(alpha: .08)
                        : null,
                    border: const Border(
                      bottom: BorderSide(color: AppColors.divider, width: .5),
                    ),
                  ),
                  children: [
                    _BodyCell(
                      child: _CodeButton(
                        code: booking.bookingCode,
                        onTap: () => onOpen(booking.id),
                      ),
                    ),
                    _BodyCell(
                      child: Text(
                        booking.guestName ?? l10n.partnerPropertyNotSet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    _BodyCell(
                      child: Text(
                        booking.roomName ?? l10n.partnerPropertyNotSet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    _BodyCell(
                      child: Text(
                        booking.checkIn == null
                            ? l10n.partnerPropertyNotSet
                            : f.date.format(booking.checkIn!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    _BodyCell(
                      child: Text(
                        booking.checkOut == null
                            ? l10n.partnerPropertyNotSet
                            : f.date.format(booking.checkOut!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    _BodyCell(
                      // Server-computed and half-open; never recalculated here.
                      child: Text(
                        f.integer.format(booking.nights),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    _BodyCell(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: PartnerBookingStatusPill(status: booking.status),
                      ),
                    ),
                    _BodyCell(
                      child: Text(
                        f.money(booking.finalPrice, booking.currency,
                            l10n.partnerPropertyNotSet),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeadCell extends StatelessWidget {
  final String label;

  const _HeadCell(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
              ),
        ),
      );
}

class _BodyCell extends StatelessWidget {
  final Widget child;

  const _BodyCell({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: child,
      );
}

class _CodeButton extends StatelessWidget {
  final String code;
  final VoidCallback onTap;

  const _CodeButton({required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: code,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadii.xs),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: AppSpacing.xxs,
                ),
                child: Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ocean700,
                      ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// One booking as a card, for tablet and mobile where the table cannot fit.
class PartnerBookingCard extends StatelessWidget {
  final PartnerBookingSummary booking;
  final bool open;
  final VoidCallback onOpen;

  const PartnerBookingCard({
    super.key,
    required this.booking,
    required this.open,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerBookingFormats.of(context);

    return Semantics(
      button: true,
      label: [
        booking.bookingCode,
        if (booking.guestName != null) booking.guestName!,
        partnerBookingStatusLabel(l10n, booking.status),
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
                            booking.bookingCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        PartnerBookingStatusPill(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      booking.guestName ?? l10n.partnerPropertyNotSet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        if (booking.roomName != null)
                          _Fact(
                            icon: Icons.bed_outlined,
                            text: booking.roomName!,
                          ),
                        if (booking.checkIn != null && booking.checkOut != null)
                          _Fact(
                            icon: Icons.date_range_rounded,
                            text: l10n.partnerBookingStayRange(
                              f.date.format(booking.checkIn!),
                              f.date.format(booking.checkOut!),
                            ),
                          ),
                        _Fact(
                          icon: Icons.nights_stay_outlined,
                          text: l10n.partnerBookingNightsValue(
                              f.integer.format(booking.nights)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      f.money(booking.finalPrice, booking.currency,
                          l10n.partnerPropertyNotSet),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ocean700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

/// The backend's own lifecycle timeline.
///
/// Every entry came from `BookingService.buildTimeline`; no local audit log is
/// fabricated. The event token is localized as the headline, and the server's
/// English `description` is shown beneath it as supporting detail — the same
/// treatment C7 gave the server's voucher reason.
class PartnerBookingTimelineView extends StatelessWidget {
  final List<PartnerBookingTimelineEvent> events;

  const PartnerBookingTimelineView({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerBookingFormats.of(context);

    if (events.isEmpty) {
      return Text(
        l10n.partnerBookingTimelineEmpty,
        style:
            theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final event in events)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.circle, size: 8, color: AppColors.ocean600),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerBookingEventLabel(l10n, event.event),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (event.description != null)
                        Text(
                          event.description!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  event.occurredAt == null
                      ? l10n.partnerPropertyNotSet
                      : f.dateTime.format(event.occurredAt!),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A labelled amount row inside the price or payment group.
class PartnerBookingAmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasis;

  const PartnerBookingAmountRow({
    super.key,
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

/// One payment on the booking.
///
/// Shows the safe summary only. `providerTransactionId` and `checkoutUrl` are
/// not even parsed by [PartnerBookingPayment], so no gateway identifier and no
/// live payment link can reach this widget.
class PartnerBookingPaymentRow extends StatelessWidget {
  final PartnerBookingPayment payment;

  const PartnerBookingPaymentRow({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerBookingFormats.of(context);
    final paid = payment.status == 'PAID';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  payment.paymentCode ?? l10n.partnerBookingPaymentUnnamed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                f.money(payment.amount, payment.currency,
                    l10n.partnerPropertyNotSet),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (payment.status != null)
                OceanStatusPill(
                  // The raw backend status string — no local re-interpretation
                  // of a payment state the client does not own.
                  label: payment.status!,
                  color: paid ? AppColors.success : AppColors.textTertiary,
                  icon: paid
                      ? Icons.check_circle_outline_rounded
                      : Icons.pending_outlined,
                ),
              if (payment.paymentMethod != null)
                _Fact(
                  icon: Icons.account_balance_wallet_outlined,
                  text: payment.paymentMethod!,
                ),
              if (payment.paidAt != null)
                _Fact(
                  icon: Icons.event_available_rounded,
                  text: f.dateTime.format(payment.paidAt!),
                ),
            ],
          ),
          if (payment.failureReason != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              payment.failureReason!,
              style:
                  theme.textTheme.labelSmall?.copyWith(color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}

/// One historical modification of the booking, made by the guest.
///
/// A partner can read this and cannot create one — `BookingService.modify` is
/// the customer's endpoint and answers 403 to anyone else.
class PartnerStayModificationRow extends StatelessWidget {
  final PartnerStayModification modification;

  const PartnerStayModificationRow({super.key, required this.modification});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerBookingFormats.of(context);
    final m = modification;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.modifiedAt == null
                ? l10n.partnerPropertyNotSet
                : f.dateTime.format(m.modifiedAt!),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          if (m.changedDates &&
              m.previousCheckIn != null &&
              m.newCheckIn != null)
            _Change(
              label: l10n.partnerBookingModificationDates,
              from: '${f.date.format(m.previousCheckIn!)}'
                  '${m.previousCheckOut == null ? '' : ' – ${f.date.format(m.previousCheckOut!)}'}',
              to: '${f.date.format(m.newCheckIn!)}'
                  '${m.newCheckOut == null ? '' : ' – ${f.date.format(m.newCheckOut!)}'}',
            ),
          if (m.changedOccupancy)
            _Change(
              label: l10n.partnerBookingModificationOccupancy,
              from: l10n.partnerBookingOccupancyValue(
                f.integer.format(m.previousAdults),
                f.integer.format(m.previousChildren),
              ),
              to: l10n.partnerBookingOccupancyValue(
                f.integer.format(m.newAdults),
                f.integer.format(m.newChildren),
              ),
            ),
          if (m.previousRatePlan != null || m.newRatePlan != null)
            _Change(
              label: l10n.partnerBookingModificationRatePlan,
              from: m.previousRatePlan ?? l10n.partnerPropertyNotSet,
              to: m.newRatePlan ?? l10n.partnerPropertyNotSet,
            ),
          if (m.changedPrice)
            _Change(
              label: l10n.partnerBookingModificationPrice,
              // The modification history records no currency of its own; the
              // booking's currency is the one in force.
              from: m.previousPrice == null
                  ? l10n.partnerPropertyNotSet
                  : f.amount.format(m.previousPrice),
              to: m.newPrice == null
                  ? l10n.partnerPropertyNotSet
                  : f.amount.format(m.newPrice),
            ),
        ],
      ),
    );
  }
}

class _Change extends StatelessWidget {
  final String label;
  final String from;
  final String to;

  const _Change({required this.label, required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.xxs,
        children: [
          Text(
            '$label:',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            from,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const Icon(Icons.arrow_right_alt_rounded,
              size: 14, color: AppColors.textTertiary),
          Text(
            to,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One check-in or check-out audit row.
///
/// These are the backend's own immutable rows, at most one of each per booking.
/// When none exists the panel says so rather than implying the operation never
/// happened through some other channel.
class PartnerStayAuditRow extends StatelessWidget {
  final PartnerStayCheckAudit audit;
  final String label;

  const PartnerStayAuditRow({
    super.key,
    required this.audit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerBookingFormats.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined,
              size: 16, color: AppColors.success),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  [
                    if (audit.timestamp != null)
                      f.dateTime.format(audit.timestamp!),
                    // MANUAL or QR_SCAN — recorded only for a check-out.
                    if (audit.method != null) audit.method!,
                  ].join(' · '),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (audit.partnerUserId != null)
            Text(
              l10n.partnerBookingAuditByUser('${audit.partnerUserId}'),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }
}
