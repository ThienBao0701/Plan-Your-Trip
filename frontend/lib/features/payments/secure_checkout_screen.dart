import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../bookings/my_bookings_screen.dart' as bookings;
import '../expenses/expenses_screen.dart';
import '../hotels/hotel_booking_confirmation_screen.dart';
import '../hotels/hotel_utils.dart' as hotel_utils;
import '../places/place_detail_screen.dart';

class SecureCheckoutScreen extends StatefulWidget {
  final Place hotel;
  final HotelRoom room;
  final HotelRatePlan ratePlan;
  final HotelStayCriteria criteria;
  final HotelPricingQuote quote;
  final String specialRequest;

  const SecureCheckoutScreen({
    super.key,
    required this.hotel,
    required this.room,
    required this.ratePlan,
    required this.criteria,
    required this.quote,
    this.specialRequest = '',
  });

  @override
  State<SecureCheckoutScreen> createState() => _SecureCheckoutScreenState();
}

class _SecureCheckoutScreenState extends State<SecureCheckoutScreen> {
  CheckoutPaymentProvider _provider = CheckoutPaymentProvider.mock;
  bool _submitting = false;
  String? _idempotencyKey;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final blocked =
        hotel_utils.quoteBlocksConfirmation(widget.quote, now: app.now());
    final canSubmit = app.demoMode && !blocked && !_submitting;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.checkoutTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('secure-checkout-screen'),
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
                    _CheckoutHero(
                      hotel: widget.hotel,
                      room: widget.room,
                      quote: widget.quote,
                      demoMode: app.demoMode,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CheckoutStayCard(
                      hotel: widget.hotel,
                      room: widget.room,
                      ratePlan: widget.ratePlan,
                      criteria: widget.criteria,
                      quote: widget.quote,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PaymentProviderCard(
                      selected: _provider,
                      enabled: app.demoMode && !blocked && !_submitting,
                      onChanged: (provider) =>
                          setState(() => _provider = provider),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SecurityBoundaryCard(demoMode: app.demoMode),
                    const SizedBox(height: AppSpacing.md),
                    _ReadOnlyBenefitsCard(demoMode: app.demoMode),
                    if (blocked) ...[
                      const SizedBox(height: AppSpacing.md),
                      OceanRecoverableErrorState(
                        message: _blockedMessage(l10n, widget.quote, app.now()),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    OceanPrimaryButton(
                      key: const Key('checkout-submit'),
                      label: app.demoMode
                          ? l10n.checkoutCreateDemoPaymentAction
                          : l10n.checkoutRealUnavailableAction,
                      icon: Icons.lock_rounded,
                      semanticLabel: l10n.checkoutSubmitSemantic,
                      onPressed: canSubmit ? _submit : null,
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

  Future<void> _submit() async {
    if (_submitting) return;
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final result = app.startDemoCheckout(
      hotel: widget.hotel,
      room: widget.room,
      ratePlan: widget.ratePlan,
      quote: widget.quote,
      criteria: widget.criteria,
      specialRequest: widget.specialRequest,
      provider: _provider,
      idempotencyKey: _checkoutIdempotencyKey(app),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    final booking = result.booking;
    final attempt = result.attempt;
    if ((result.created ||
            result.result == DemoPaymentActionResult.duplicate) &&
        booking != null &&
        attempt != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentStatusScreen(
            bookingCode: booking.code,
            attemptId: attempt.id,
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
            content: Text(paymentActionResultMessage(l10n, result.result))),
      );
  }

  String _checkoutIdempotencyKey(AppState app) {
    return _idempotencyKey ??= [
      'checkout',
      app.demoBookings.length,
      widget.hotel.id,
      widget.room.id,
      widget.ratePlan.ratePlanId,
      widget.criteria.checkIn.toIso8601String(),
      widget.criteria.checkOut.toIso8601String(),
      widget.criteria.adults,
      widget.criteria.children,
    ].join('-');
  }

  String _blockedMessage(
    AppLocalizations l10n,
    HotelPricingQuote quote,
    DateTime now,
  ) {
    if (quote.finalQuotedPrice == null) {
      return quote.eligibilityReason ?? l10n.bookingQuoteUnavailable;
    }
    if (!quote.inventoryAvailable) return l10n.bookingInventoryUnavailable;
    if (now.isAfter(quote.quoteExpiresAt)) return l10n.bookingQuoteExpired;
    return l10n.bookingQuoteUnavailable;
  }
}

class PaymentStatusScreen extends StatefulWidget {
  final String bookingCode;
  final String? attemptId;

  const PaymentStatusScreen({
    super.key,
    required this.bookingCode,
    this.attemptId,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  String? _activeAttemptId;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _activeAttemptId = widget.attemptId;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final booking = app.demoBookingByCode(widget.bookingCode);
    final attempt = _currentAttempt(app);
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.paymentStatusTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('payment-status-screen'),
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
                        title: l10n.paymentRealUnavailableTitle,
                        message: l10n.paymentRealUnavailableMessage,
                      )
                    : booking == null || attempt == null
                        ? OceanEmptyState(
                            title: l10n.paymentMissingTitle,
                            message: l10n.paymentMissingMessage,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PaymentHero(
                                booking: booking,
                                attempt: attempt,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _PaymentDetailsCard(
                                booking: booking,
                                attempt: attempt,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _PaymentActionsCard(
                                booking: booking,
                                attempt: attempt,
                                working: _working,
                                onComplete: () => _complete(attempt),
                                onFail: () => _fail(attempt),
                                onCancel: () => _cancel(attempt),
                                onRetry: () => _retry(booking),
                                onOpenBooking: () => _openBooking(booking),
                                onOpenConfirmation: attempt.isSuccessful &&
                                        booking.status ==
                                            BookingStatus.confirmed
                                    ? () => _openConfirmation(booking)
                                    : null,
                                onOpenHotel: () => _openHotel(booking),
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

  DemoPaymentAttempt? _currentAttempt(AppState app) {
    final attemptId = _activeAttemptId;
    if (attemptId != null) {
      final exact = app.paymentAttemptById(attemptId);
      if (exact != null) return exact;
    }
    return app.latestPaymentAttemptForBooking(widget.bookingCode);
  }

  Future<void> _run(DemoPaymentActionResult Function() action) async {
    if (_working) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _working = true);
    await Future<void>.delayed(Duration.zero);
    final result = action();
    if (!mounted) return;
    setState(() => _working = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(paymentActionResultMessage(l10n, result))),
      );
  }

  Future<void> _complete(DemoPaymentAttempt attempt) => _run(
        () => AppScope.of(context).completeDemoPayment(attempt.id),
      );

  Future<void> _fail(DemoPaymentAttempt attempt) => _run(
        () => AppScope.of(context).failDemoPayment(
          attempt.id,
          reason: AppLocalizations.of(context)!.paymentDemoFailureReason,
        ),
      );

  Future<void> _cancel(DemoPaymentAttempt attempt) => _run(
        () => AppScope.of(context).cancelDemoPaymentAttempt(attempt.id),
      );

  Future<void> _retry(DemoBooking booking) async {
    if (_working) return;
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _working = true);
    await Future<void>.delayed(Duration.zero);
    final result = app.retryDemoPayment(booking.code);
    if (!mounted) return;
    setState(() {
      _working = false;
      if (result.attempt != null) _activeAttemptId = result.attempt!.id;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
            content: Text(paymentActionResultMessage(l10n, result.result))),
      );
  }

  void _openBooking(DemoBooking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => bookings.BookingDetailScreen(bookingCode: booking.code),
      ),
    );
  }

  void _openConfirmation(DemoBooking booking) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HotelBookingConfirmationScreen(booking: booking),
      ),
    );
  }

  void _openHotel(DemoBooking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(place: booking.hotel),
      ),
    );
  }
}

class _CheckoutHero extends StatelessWidget {
  final Place hotel;
  final HotelRoom room;
  final HotelPricingQuote quote;
  final bool demoMode;

  const _CheckoutHero({
    required this.hotel,
    required this.room,
    required this.quote,
    required this.demoMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = quote.finalQuotedPrice;
    return OceanGlassCard(
      semanticLabel: l10n.checkoutSemantic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: demoMode
                    ? l10n.bookingDemoStatus
                    : l10n.checkoutRealModeLabel,
                icon: demoMode ? Icons.science_rounded : Icons.cloud_rounded,
                color: demoMode ? AppColors.ocean : AppColors.warning,
              ),
              OceanStatusPill(
                label: l10n.checkoutSecureBoundaryPill,
                icon: Icons.lock_rounded,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.checkoutSecureTitle,
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(hotel.name, style: Theme.of(context).textTheme.titleLarge),
          Text(room.roomName, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.checkoutWholeStayTotal,
              style: Theme.of(context).textTheme.labelLarge),
          Text(
            total == null
                ? l10n.bookingQuoteUnavailable
                : formatMoney(context, total, quote.currency),
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: AppColors.ocean),
          ),
        ],
      ),
    );
  }
}

class _CheckoutStayCard extends StatelessWidget {
  final Place hotel;
  final HotelRoom room;
  final HotelRatePlan ratePlan;
  final HotelStayCriteria criteria;
  final HotelPricingQuote quote;

  const _CheckoutStayCard({
    required this.hotel,
    required this.room,
    required this.ratePlan,
    required this.criteria,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return _CheckoutSectionCard(
      title: l10n.checkoutStaySnapshotTitle,
      icon: Icons.hotel_rounded,
      children: [
        _InfoRow(
          icon: Icons.place_rounded,
          label: l10n.bookingHotelLabel,
          value: hotel.name,
        ),
        _InfoRow(
          icon: Icons.king_bed_rounded,
          label: l10n.bookingRoomLabel,
          value: room.roomName,
        ),
        _InfoRow(
          icon: Icons.policy_rounded,
          label: l10n.bookingRatePlanLabel,
          value: ratePlan.rateName,
        ),
        _InfoRow(
          icon: Icons.calendar_month_rounded,
          label: l10n.bookingDatesLabel,
          value:
              '${date.format(criteria.checkIn)} - ${date.format(criteria.checkOut)}',
        ),
        _InfoRow(
          icon: Icons.nights_stay_rounded,
          label: l10n.bookingNightsLabel,
          value: l10n.hotelNights(criteria.nights),
        ),
        _InfoRow(
          icon: Icons.group_rounded,
          label: l10n.bookingGuestsLabel,
          value: l10n.hotelGuestSummary(criteria.adults, criteria.children),
        ),
        if (quote.cancellationPolicyType != null)
          _InfoRow(
            icon: Icons.gpp_maybe_rounded,
            label: l10n.bookingCancellationPolicyLabel,
            value: bookings.cancellationPolicyLabel(
              l10n,
              quote.cancellationPolicyType!,
            ),
          ),
        if (ratePlan.policySummary.trim().isNotEmpty)
          _InfoRow(
            icon: Icons.description_rounded,
            label: l10n.bookingPolicySummaryLabel,
            value: ratePlan.policySummary,
          ),
      ],
    );
  }
}

class _PaymentProviderCard extends StatelessWidget {
  final CheckoutPaymentProvider selected;
  final bool enabled;
  final ValueChanged<CheckoutPaymentProvider> onChanged;

  const _PaymentProviderCard({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  static const _providers = [
    CheckoutPaymentProvider.mock,
    CheckoutPaymentProvider.vnpay,
    CheckoutPaymentProvider.payos,
    CheckoutPaymentProvider.momo,
    CheckoutPaymentProvider.stripe,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CheckoutSectionCard(
      title: l10n.checkoutProviderTitle,
      icon: Icons.account_balance_wallet_rounded,
      children: [
        Text(
          l10n.checkoutProviderHelper,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final provider in _providers)
          _ProviderOption(
            key: Key('checkout-provider-${provider.code}'),
            provider: provider,
            selected: selected == provider,
            enabled: enabled && provider.hasCustomerSessionGateway,
            onTap: () => onChanged(provider),
          ),
      ],
    );
  }
}

class _ProviderOption extends StatelessWidget {
  final CheckoutPaymentProvider provider;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ProviderOption({
    super.key,
    required this.provider,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = selected ? AppColors.ocean : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: paymentProviderLabel(l10n, provider),
        child: ExcludeSemantics(
          child: OceanGlassSurface(
            blur: 0,
            color: selected
                ? AppColors.ocean.withValues(alpha: .10)
                : AppColors.surfaceOverlay,
            border: Border.all(
              color: selected ? AppColors.ocean : AppColors.divider,
            ),
            onTap: enabled ? onTap : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: enabled ? color : AppColors.disabled,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paymentProviderLabel(l10n, provider),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        provider == CheckoutPaymentProvider.mock
                            ? l10n.checkoutMockProviderSubtitle
                            : l10n.checkoutHostedProviderSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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
}

class _SecurityBoundaryCard extends StatelessWidget {
  final bool demoMode;

  const _SecurityBoundaryCard({required this.demoMode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CheckoutSectionCard(
      title: l10n.checkoutSecurityTitle,
      icon: Icons.shield_rounded,
      children: [
        OceanGlassSurface(
          blur: 0,
          color: AppColors.paleCyan,
          child: Text(
            demoMode
                ? l10n.checkoutDemoSecurityBoundary
                : l10n.checkoutRealUnavailableMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.checkoutNoSensitiveFields,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ReadOnlyBenefitsCard extends StatelessWidget {
  final bool demoMode;

  const _ReadOnlyBenefitsCard({required this.demoMode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CheckoutSectionCard(
      title: l10n.checkoutBenefitsBoundaryTitle,
      icon: Icons.workspace_premium_rounded,
      children: [
        Text(
          demoMode
              ? l10n.checkoutBenefitsReadOnlyDemo
              : l10n.checkoutBenefitsReadOnlyReal,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _PaymentHero extends StatelessWidget {
  final DemoBooking booking;
  final DemoPaymentAttempt attempt;

  const _PaymentHero({
    required this.booking,
    required this.attempt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      semanticLabel: l10n.paymentStatusSemantic,
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
                label: paymentSessionStatusLabel(l10n, attempt.sessionStatus),
                icon: paymentStatusIcon(attempt),
                color: paymentStatusColor(attempt),
              ),
              if (booking.paymentStatus != null)
                OceanStatusPill(
                  label: bookings.bookingPaymentStatusLabel(
                    l10n,
                    booking.paymentStatus!,
                  ),
                  icon: Icons.payments_rounded,
                  color: paymentStatusColor(attempt),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            paymentResultTitle(l10n, attempt),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(booking.hotel.name,
              style: Theme.of(context).textTheme.titleLarge),
          Text(booking.room.roomName,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          Text(
            attempt.amountIsSafe
                ? formatMoney(context, attempt.amount, attempt.currency)
                : l10n.walletNoValue,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: AppColors.ocean),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.paymentDemoLocalOnly,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PaymentDetailsCard extends StatelessWidget {
  final DemoBooking booking;
  final DemoPaymentAttempt attempt;

  const _PaymentDetailsCard({
    required this.booking,
    required this.attempt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _CheckoutSectionCard(
      title: l10n.paymentDetailsTitle,
      icon: Icons.receipt_long_rounded,
      children: [
        _InfoRow(
          icon: Icons.confirmation_number_rounded,
          label: l10n.bookingCodeLabel,
          value: l10n.bookingLocalCode(booking.code),
          semanticValue: l10n.bookingCodeSemantic,
        ),
        _InfoRow(
          icon: Icons.account_balance_wallet_rounded,
          label: l10n.paymentProviderLabel,
          value: paymentProviderLabel(l10n, attempt.provider),
        ),
        _InfoRow(
          icon: Icons.sync_rounded,
          label: l10n.paymentSessionStatusLabel,
          value: paymentSessionStatusLabel(l10n, attempt.sessionStatus),
        ),
        if (attempt.paymentStatus != null)
          _InfoRow(
            icon: Icons.payments_rounded,
            label: l10n.bookingPaymentStatusLabel,
            value: bookings.bookingPaymentStatusLabel(
              l10n,
              attempt.paymentStatus!,
            ),
          ),
        if (attempt.amountIsSafe)
          _InfoRow(
            icon: Icons.price_check_rounded,
            label: l10n.paymentAmountLabel,
            value: formatMoney(context, attempt.amount, attempt.currency),
          ),
        _InfoRow(
          icon: Icons.schedule_rounded,
          label: l10n.paymentCreatedLabel,
          value: formatDateTime(context, attempt.createdAt),
        ),
        if (attempt.expiresAt != null && attempt.isPending)
          _InfoRow(
            icon: Icons.timer_rounded,
            label: l10n.paymentHoldExpiresLabel,
            value: formatDateTime(context, attempt.expiresAt!),
          ),
        if (attempt.paidAt != null)
          _InfoRow(
            icon: Icons.check_circle_rounded,
            label: l10n.paymentPaidAtLabel,
            value: formatDateTime(context, attempt.paidAt!),
          ),
        if (attempt.failedAt != null)
          _InfoRow(
            icon: Icons.error_rounded,
            label: l10n.paymentFailedAtLabel,
            value: formatDateTime(context, attempt.failedAt!),
          ),
        if (attempt.cancelledAt != null)
          _InfoRow(
            icon: Icons.cancel_rounded,
            label: l10n.paymentCancelledAtLabel,
            value: formatDateTime(context, attempt.cancelledAt!),
          ),
        if (attempt.refundedAt != null)
          _InfoRow(
            icon: Icons.currency_exchange_rounded,
            label: l10n.paymentRefundedAtLabel,
            value: formatDateTime(context, attempt.refundedAt!),
          ),
        if (attempt.safeProviderReference != null)
          _InfoRow(
            icon: Icons.shield_rounded,
            label: l10n.paymentReferenceLabel,
            value: maskSensitiveReference(attempt.safeProviderReference!),
            semanticValue: l10n.paymentMaskedReferenceSemantic,
          ),
        if (attempt.failureReason != null)
          _InfoRow(
            icon: Icons.info_rounded,
            label: l10n.paymentFailureReasonLabel,
            value: attempt.failureReason!,
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
    );
  }
}

class _PaymentActionsCard extends StatelessWidget {
  final DemoBooking booking;
  final DemoPaymentAttempt attempt;
  final bool working;
  final VoidCallback onComplete;
  final VoidCallback onFail;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onOpenBooking;
  final VoidCallback? onOpenConfirmation;
  final VoidCallback onOpenHotel;

  const _PaymentActionsCard({
    required this.booking,
    required this.attempt,
    required this.working,
    required this.onComplete,
    required this.onFail,
    required this.onCancel,
    required this.onRetry,
    required this.onOpenBooking,
    required this.onOpenConfirmation,
    required this.onOpenHotel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canRetry =
        attempt.canRetry && booking.status == BookingStatus.pending;
    return _CheckoutSectionCard(
      title: l10n.paymentActionsTitle,
      icon: Icons.touch_app_rounded,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (attempt.isPending)
              OceanPrimaryButton(
                key: const Key('payment-complete-demo'),
                label: l10n.paymentCompleteDemoAction,
                icon: Icons.verified_rounded,
                fullWidth: false,
                semanticLabel: l10n.paymentCompleteDemoSemantic,
                onPressed: working ? null : onComplete,
              ),
            if (attempt.isPending)
              OceanSecondaryButton(
                key: const Key('payment-fail-demo'),
                label: l10n.paymentFailDemoAction,
                icon: Icons.error_rounded,
                fullWidth: false,
                onPressed: working ? null : onFail,
              ),
            if (attempt.isPending)
              OceanSecondaryButton(
                key: const Key('payment-cancel-demo'),
                label: l10n.paymentCancelDemoAction,
                icon: Icons.cancel_rounded,
                fullWidth: false,
                onPressed: working ? null : onCancel,
              ),
            if (canRetry)
              OceanPrimaryButton(
                key: const Key('payment-retry'),
                label: l10n.paymentRetryAction,
                icon: Icons.refresh_rounded,
                fullWidth: false,
                onPressed: working ? null : onRetry,
              ),
            if (onOpenConfirmation != null)
              OceanPrimaryButton(
                key: const Key('payment-open-confirmation'),
                label: l10n.paymentContinueConfirmationAction,
                icon: Icons.fact_check_rounded,
                fullWidth: false,
                onPressed: onOpenConfirmation,
              ),
            OceanSecondaryButton(
              key: const Key('payment-view-booking'),
              label: l10n.bookingViewBookingAction,
              icon: Icons.list_alt_rounded,
              fullWidth: false,
              onPressed: onOpenBooking,
            ),
            OceanSecondaryButton(
              key: const Key('payment-return-hotel'),
              label: l10n.bookingViewPlaceAction,
              icon: Icons.place_rounded,
              fullWidth: false,
              onPressed: onOpenHotel,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OceanGlassSurface(
          blur: 0,
          color: AppColors.paleCyan,
          child: Text(
            attempt.isPending
                ? l10n.paymentPendingBoundary
                : l10n.paymentTerminalBoundary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _CheckoutSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _CheckoutSectionCard({
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? semanticValue;

  const _InfoRow({
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

String paymentProviderLabel(
  AppLocalizations l10n,
  CheckoutPaymentProvider provider,
) {
  switch (provider) {
    case CheckoutPaymentProvider.mock:
      return l10n.paymentProviderMock;
    case CheckoutPaymentProvider.vnpay:
      return l10n.paymentProviderVnpay;
    case CheckoutPaymentProvider.payos:
      return l10n.paymentProviderPayos;
    case CheckoutPaymentProvider.momo:
      return l10n.paymentProviderMomo;
    case CheckoutPaymentProvider.stripe:
      return l10n.paymentProviderStripe;
    case CheckoutPaymentProvider.applePay:
      return l10n.paymentProviderApplePay;
    case CheckoutPaymentProvider.googlePay:
      return l10n.paymentProviderGooglePay;
    case CheckoutPaymentProvider.manual:
      return l10n.paymentProviderManual;
  }
}

String paymentSessionStatusLabel(
  AppLocalizations l10n,
  PaymentSessionStatus status,
) {
  switch (status) {
    case PaymentSessionStatus.newSession:
      return l10n.paymentSessionStatusNew;
    case PaymentSessionStatus.pending:
      return l10n.paymentSessionStatusPending;
    case PaymentSessionStatus.authorized:
      return l10n.paymentSessionStatusAuthorized;
    case PaymentSessionStatus.captured:
      return l10n.paymentSessionStatusCaptured;
    case PaymentSessionStatus.failed:
      return l10n.paymentSessionStatusFailed;
    case PaymentSessionStatus.cancelled:
      return l10n.paymentSessionStatusCancelled;
    case PaymentSessionStatus.expired:
      return l10n.paymentSessionStatusExpired;
  }
}

String paymentResultTitle(AppLocalizations l10n, DemoPaymentAttempt attempt) {
  if (attempt.isSuccessful) return l10n.paymentResultSuccessTitle;
  switch (attempt.sessionStatus) {
    case PaymentSessionStatus.failed:
      return l10n.paymentResultFailedTitle;
    case PaymentSessionStatus.cancelled:
      return l10n.paymentResultCancelledTitle;
    case PaymentSessionStatus.expired:
      return l10n.paymentResultExpiredTitle;
    case PaymentSessionStatus.newSession:
    case PaymentSessionStatus.pending:
    case PaymentSessionStatus.authorized:
      return l10n.paymentResultPendingTitle;
    case PaymentSessionStatus.captured:
      return l10n.paymentResultSuccessTitle;
  }
}

Color paymentStatusColor(DemoPaymentAttempt attempt) {
  if (attempt.isSuccessful) return AppColors.success;
  switch (attempt.sessionStatus) {
    case PaymentSessionStatus.failed:
    case PaymentSessionStatus.cancelled:
    case PaymentSessionStatus.expired:
      return AppColors.danger;
    case PaymentSessionStatus.authorized:
    case PaymentSessionStatus.pending:
    case PaymentSessionStatus.newSession:
      return AppColors.warning;
    case PaymentSessionStatus.captured:
      return AppColors.success;
  }
}

IconData paymentStatusIcon(DemoPaymentAttempt attempt) {
  if (attempt.isSuccessful) return Icons.check_circle_rounded;
  switch (attempt.sessionStatus) {
    case PaymentSessionStatus.failed:
      return Icons.error_rounded;
    case PaymentSessionStatus.cancelled:
      return Icons.cancel_rounded;
    case PaymentSessionStatus.expired:
      return Icons.timer_off_rounded;
    case PaymentSessionStatus.authorized:
      return Icons.verified_user_rounded;
    case PaymentSessionStatus.pending:
    case PaymentSessionStatus.newSession:
      return Icons.hourglass_top_rounded;
    case PaymentSessionStatus.captured:
      return Icons.check_circle_rounded;
  }
}

String paymentActionResultMessage(
  AppLocalizations l10n,
  DemoPaymentActionResult result,
) {
  switch (result) {
    case DemoPaymentActionResult.success:
      return l10n.paymentActionSuccess;
    case DemoPaymentActionResult.unavailable:
      return l10n.paymentActionUnavailable;
    case DemoPaymentActionResult.notFound:
      return l10n.paymentMissingMessage;
    case DemoPaymentActionResult.duplicate:
      return l10n.paymentDuplicatePrevented;
    case DemoPaymentActionResult.invalidState:
      return l10n.paymentActionInvalidState;
    case DemoPaymentActionResult.quoteUnavailable:
      return l10n.bookingQuoteUnavailable;
    case DemoPaymentActionResult.bookingUnavailable:
      return l10n.bookingDetailMissingMessage;
  }
}

String formatDateTime(BuildContext context, DateTime value) {
  final formatter =
      DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_jm();
  return formatter.format(value.toLocal());
}
