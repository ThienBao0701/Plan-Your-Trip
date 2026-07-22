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
import '../payments/secure_checkout_screen.dart';
import 'hotel_room_selection_screen.dart';
import 'hotel_utils.dart';

class HotelBookingReviewScreen extends StatefulWidget {
  final Place hotel;
  final HotelRoom room;
  final HotelRatePlan ratePlan;
  final HotelStayCriteria criteria;
  final HotelPricingQuote quote;

  const HotelBookingReviewScreen({
    super.key,
    required this.hotel,
    required this.room,
    required this.ratePlan,
    required this.criteria,
    required this.quote,
  });

  @override
  State<HotelBookingReviewScreen> createState() =>
      _HotelBookingReviewScreenState();
}

class _HotelBookingReviewScreenState extends State<HotelBookingReviewScreen> {
  final _specialRequest = TextEditingController();
  bool _termsAccepted = false;

  @override
  void dispose() {
    _specialRequest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final blocked = quoteBlocksConfirmation(widget.quote, now: app.now());
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StaySummary(
                      hotel: widget.hotel,
                      room: widget.room,
                      criteria: widget.criteria,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PlanSummary(
                      ratePlan: widget.ratePlan,
                      quote: widget.quote,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AccountSummary(email: app.email),
                    const SizedBox(height: AppSpacing.md),
                    OceanGlassCard(
                      child: TextField(
                        key: const Key('booking-special-request'),
                        controller: _specialRequest,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: l10n.bookingSpecialRequestLabel,
                          helperText: l10n.bookingSpecialRequestHelper,
                          prefixIcon: const Icon(Icons.notes_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _QuoteBreakdown(quote: widget.quote),
                    const SizedBox(height: AppSpacing.md),
                    if (blocked)
                      OceanRecoverableErrorState(
                        message: _blockedMessage(l10n, widget.quote, app.now()),
                      )
                    else
                      OceanGlassSurface(
                        blur: 0,
                        color: AppColors.paleCyan,
                        child: Text(
                          app.demoMode
                              ? l10n.bookingDemoBoundaryMessage
                              : l10n.bookingRealUnavailableMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    CheckboxListTile(
                      key: const Key('booking-terms-checkbox'),
                      contentPadding: EdgeInsets.zero,
                      value: _termsAccepted,
                      onChanged: (value) =>
                          setState(() => _termsAccepted = value ?? false),
                      title: Text(l10n.bookingTermsAcknowledgement),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OceanPrimaryButton(
                      key: const Key('booking-confirm'),
                      label: l10n.checkoutContinueAction,
                      icon: Icons.lock_rounded,
                      semanticLabel: l10n.bookingConfirmSemantic,
                      onPressed:
                          blocked || !_termsAccepted ? null : _openCheckout,
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

  void _openCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecureCheckoutScreen(
          hotel: widget.hotel,
          room: widget.room,
          ratePlan: widget.ratePlan,
          criteria: widget.criteria,
          quote: widget.quote,
          specialRequest: _specialRequest.text.trim(),
        ),
      ),
    );
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

class _StaySummary extends StatelessWidget {
  final Place hotel;
  final HotelRoom room;
  final HotelStayCriteria criteria;

  const _StaySummary({
    required this.hotel,
    required this.room,
    required this.criteria,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hotel.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(room.roomName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label:
                    '${date.format(criteria.checkIn)} - ${date.format(criteria.checkOut)}',
                icon: Icons.calendar_month_rounded,
              ),
              OceanStatusPill(
                label: l10n.hotelNights(criteria.nights),
                icon: Icons.nights_stay_rounded,
                color: AppColors.turquoise600,
              ),
              OceanStatusPill(
                label:
                    l10n.hotelGuestSummary(criteria.adults, criteria.children),
                icon: Icons.group_rounded,
                color: AppColors.ocean,
              ),
              OceanStatusPill(
                label: l10n.hotelOneRoomOnly,
                icon: Icons.meeting_room_rounded,
                color: AppColors.violet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  final HotelRatePlan ratePlan;
  final HotelPricingQuote quote;

  const _PlanSummary({required this.ratePlan, required this.quote});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingSelectedPlanTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(ratePlan.rateName,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: mealPlanLabel(l10n, ratePlan.mealPlan),
                icon: Icons.restaurant_rounded,
              ),
              OceanStatusPill(
                label: cancellationPolicyLabel(
                  l10n,
                  ratePlan.cancellationPolicyType,
                ),
                icon: Icons.policy_rounded,
                color:
                    ratePlan.refundable ? AppColors.success : AppColors.coral,
              ),
            ],
          ),
          if (ratePlan.policySummary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              ratePlan.policySummary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.bookingQuoteExpiry(
              DateFormat.Hm(Localizations.localeOf(context).toString())
                  .format(quote.quoteExpiresAt),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  final String? email;

  const _AccountSummary({required this.email});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingAccountTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            email ?? l10n.profileEmailMissing,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.bookingAccountReadOnly,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _QuoteBreakdown extends StatelessWidget {
  final HotelPricingQuote quote;

  const _QuoteBreakdown({required this.quote});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = quote.finalQuotedPrice;
    return OceanGlassCard(
      semanticLabel: l10n.bookingPriceSemantic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingPriceTitle,
              semanticsLabel: l10n.bookingPriceSemantic,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          if (quote.finalNightlyRate != null)
            _PriceRow(
              label: l10n.bookingFinalNightlyRate,
              value:
                  formatMoney(context, quote.finalNightlyRate!, quote.currency),
            ),
          if (quote.staySubtotal != null)
            _PriceRow(
              label: l10n.bookingStaySubtotal,
              value: formatMoney(context, quote.staySubtotal!, quote.currency),
            ),
          if (quote.promotionDiscount > 0)
            _PriceRow(
              label: l10n.bookingPromotionDiscount,
              value:
                  '-${formatMoney(context, quote.promotionDiscount, quote.currency)}',
            ),
          const Divider(height: AppSpacing.lg),
          _PriceRow(
            label: l10n.bookingFinalQuotedPrice,
            value: total == null
                ? l10n.bookingQuoteUnavailable
                : formatMoney(context, total, quote.currency),
            emphasized: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.bookingCustomerBenefitsExcluded,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            l10n.bookingQuoteNoReservation,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          for (final warning in quote.warnings) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(warning, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: AppColors.ocean)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
