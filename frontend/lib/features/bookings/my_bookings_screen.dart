import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../expenses/expenses_screen.dart';
import '../hotels/hotel_utils.dart';

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
                                  onTap: () => _showBooking(booking),
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

  Future<void> _showBooking(DemoBooking booking) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(
        booking: booking,
        onCancel: booking.status.canCancel
            ? () {
                Navigator.pop(context);
                _confirmCancel(booking);
              }
            : null,
        onPayment: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.bookingPaymentUnavailable,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(DemoBooking booking) async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final reason = await showDialog<String?>(
      context: context,
      builder: (_) => const _CancelBookingDialog(),
    );
    if (reason == null || !mounted) return;
    app.cancelDemoBooking(
      booking.code,
      reason: reason.trim().isEmpty ? null : reason.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.bookingCancelledMessage)),
    );
  }
}

class _CancelBookingDialog extends StatefulWidget {
  const _CancelBookingDialog();

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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.bookingCancelConfirmTitle),
      content: TextField(
        controller: _reason,
        decoration: InputDecoration(labelText: l10n.bookingCancelReasonLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.profileCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _reason.text),
          child: Text(l10n.bookingCancelAction),
        ),
      ],
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
      semanticLabel: l10n.myBookingCardSemantic(booking.code),
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
              OceanStatusPill(
                label: booking.code,
                icon: Icons.confirmation_number_rounded,
                color: AppColors.turquoise600,
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
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingDetailSheet extends StatelessWidget {
  final DemoBooking booking;
  final VoidCallback? onCancel;
  final VoidCallback onPayment;

  const _BookingDetailSheet({
    required this.booking,
    required this.onCancel,
    required this.onPayment,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.bookingDetailsTitle,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            Text(booking.hotel.name,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(booking.room.roomName,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: Icons.confirmation_number_rounded,
              text: l10n.bookingLocalCode(booking.code),
            ),
            _DetailRow(
              icon: Icons.calendar_month_rounded,
              text:
                  '${date.format(booking.criteria.checkIn)} - ${date.format(booking.criteria.checkOut)}',
            ),
            _DetailRow(
              icon: Icons.verified_rounded,
              text: bookingStatusLabel(l10n, booking.status),
            ),
            if (booking.quote.finalQuotedPrice != null)
              _DetailRow(
                icon: Icons.payments_rounded,
                text: formatMoney(
                  context,
                  booking.quote.finalQuotedPrice!,
                  booking.quote.currency,
                ),
              ),
            if (booking.cancellationReason != null)
              _DetailRow(
                icon: Icons.notes_rounded,
                text: booking.cancellationReason!,
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
            OceanSecondaryButton(
              label: l10n.bookingPaymentUnavailableAction,
              icon: Icons.credit_card_off_rounded,
              onPressed: onPayment,
            ),
            if (onCancel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OceanSecondaryButton(
                key: const Key('booking-cancel'),
                label: l10n.bookingCancelAction,
                icon: Icons.cancel_rounded,
                semanticLabel: l10n.bookingCancelSemantic,
                onPressed: onCancel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

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
