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

class ModifyBookingScreen extends StatefulWidget {
  final String bookingCode;
  final DateTime? today;

  const ModifyBookingScreen({
    super.key,
    required this.bookingCode,
    this.today,
  });

  @override
  State<ModifyBookingScreen> createState() => _ModifyBookingScreenState();
}

class _ModifyBookingScreenState extends State<ModifyBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();
  final _adultsController = TextEditingController();
  final _childrenController = TextEditingController();
  final _extraBedsController = TextEditingController();

  bool _initialized = false;
  bool _reviewing = false;
  bool _submitting = false;
  int? _selectedRatePlanId;
  DateTime? _initialVersion;
  BookingModificationDraft? _draft;
  HotelRatePlan? _proposedRatePlan;
  HotelPricingQuote? _proposedQuote;
  String? _message;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final app = AppScope.of(context);
    final booking = app.demoBookingByCode(widget.bookingCode);
    if (booking != null) {
      final formatter = DateFormat('yyyy-MM-dd');
      _checkInController.text = formatter.format(booking.criteria.checkIn);
      _checkOutController.text = formatter.format(booking.criteria.checkOut);
      _adultsController.text = booking.criteria.adults.toString();
      _childrenController.text = booking.criteria.children.toString();
      _extraBedsController.text = booking.criteria.extraBeds.toString();
      _selectedRatePlanId = booking.ratePlan.ratePlanId;
      _initialVersion = booking.modificationVersion;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _checkInController.dispose();
    _checkOutController.dispose();
    _adultsController.dispose();
    _childrenController.dispose();
    _extraBedsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final booking = app.demoBookingByCode(widget.bookingCode);
    final eligibility = booking == null
        ? const BookingModificationEligibility(
            result: BookingModificationResult.notFound,
          )
        : app.modificationEligibilityForBooking(booking);

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () {
            if (_reviewing) {
              setState(() => _reviewing = false);
              return;
            }
            Navigator.maybePop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.bookingModifyTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('modify-booking-screen'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: booking == null
                    ? OceanEmptyState(
                        title: l10n.bookingDetailMissingTitle,
                        message: l10n.bookingDetailMissingMessage,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ModifyHero(
                            booking: booking,
                            eligibility: eligibility,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (!eligibility.canModify)
                            OceanRecoverableErrorState(
                              message: bookingModificationResultMessage(
                                l10n,
                                eligibility.result,
                              ),
                            )
                          else if (_reviewing &&
                              _draft != null &&
                              _proposedRatePlan != null &&
                              _proposedQuote != null)
                            _ReviewStep(
                              booking: booking,
                              draft: _draft!,
                              ratePlan: _proposedRatePlan!,
                              quote: _proposedQuote!,
                              submitting: _submitting,
                              message: _message,
                              onBack: () => setState(() {
                                _reviewing = false;
                                _message = null;
                              }),
                              onConfirm: () => _confirm(booking),
                            )
                          else
                            _EditStep(
                              formKey: _formKey,
                              booking: booking,
                              checkInController: _checkInController,
                              checkOutController: _checkOutController,
                              adultsController: _adultsController,
                              childrenController: _childrenController,
                              extraBedsController: _extraBedsController,
                              selectedRatePlanId: _selectedRatePlanId,
                              message: _message,
                              onRatePlanChanged: (value) => setState(
                                () => _selectedRatePlanId = value,
                              ),
                              onReview: () => _buildReview(booking),
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

  void _buildReview(DemoBooking booking) {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = _readDraft();
    if (draft == null) {
      setState(() => _message = l10n.bookingModifyInvalidDates);
      return;
    }
    if (!draft.changes(booking)) {
      setState(() => _message = l10n.bookingModifyNoChanges);
      return;
    }
    final error = validateHotelCriteria(
      booking.criteria.copyWith(
        checkIn: draft.checkIn,
        checkOut: draft.checkOut,
        adults: draft.adults,
        children: draft.children,
        extraBeds: draft.extraBeds,
      ),
      today: widget.today ?? AppScope.of(context).now(),
    );
    if (error != null) {
      setState(() => _message = _criteriaErrorMessage(l10n, error));
      return;
    }
    if (draft.adults > booking.room.maxAdults ||
        draft.children > booking.room.maxChildren ||
        draft.adults + draft.children > booking.room.maxGuests) {
      setState(() => _message = l10n.bookingModifyCapacityExceeded);
      return;
    }
    final ratePlan = _ratePlanById(booking, draft.ratePlanId);
    if (ratePlan == null || !ratePlan.eligible) {
      setState(() {
        _message = ratePlan?.reason ?? l10n.bookingModifyUnavailableRoomRate;
      });
      return;
    }
    final proposedCriteria = booking.criteria.copyWith(
      checkIn: hotelDateOnly(draft.checkIn),
      checkOut: hotelDateOnly(draft.checkOut),
      adults: draft.adults,
      children: draft.children,
      extraBeds: draft.extraBeds,
    );
    final quote = buildLocalHotelQuote(
      hotel: booking.hotel,
      room: booking.room,
      ratePlan: ratePlan,
      criteria: proposedCriteria,
      generatedAt: AppScope.of(context).now(),
      currency: booking.quote.currency,
    );
    final amount = quote.finalQuotedPrice;
    if (amount == null ||
        !amount.isFinite ||
        amount < 0 ||
        quote.currency != booking.quote.currency ||
        !quote.inventoryAvailable) {
      setState(() => _message = l10n.bookingModifyQuoteUnavailable);
      return;
    }
    setState(() {
      _draft = draft;
      _proposedRatePlan = ratePlan;
      _proposedQuote = quote;
      _reviewing = true;
      _message = null;
    });
  }

  Future<void> _confirm(DemoBooking booking) async {
    if (_submitting) return;
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final draft = _draft;
    final ratePlan = _proposedRatePlan;
    final quote = _proposedQuote;
    final version = _initialVersion;
    if (draft == null || ratePlan == null || quote == null || version == null) {
      setState(() => _message = l10n.bookingModifyQuoteUnavailable);
      return;
    }
    setState(() => _submitting = true);
    await Future<void>.delayed(Duration.zero);
    final result = app.modifyDemoBooking(
      bookingCode: booking.code,
      expectedVersion: version,
      draft: draft,
      ratePlan: ratePlan,
      proposedQuote: quote,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result == BookingModificationResult.available) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _reviewing = false;
      _message = bookingModificationResultMessage(l10n, result);
    });
  }

  BookingModificationDraft? _readDraft() {
    final formatter = DateFormat('yyyy-MM-dd');
    final checkIn = _parseDate(formatter, _checkInController.text.trim());
    final checkOut = _parseDate(formatter, _checkOutController.text.trim());
    final adults = int.tryParse(_adultsController.text.trim());
    final children = int.tryParse(_childrenController.text.trim());
    final extraBeds = int.tryParse(_extraBedsController.text.trim());
    if (checkIn == null ||
        checkOut == null ||
        adults == null ||
        children == null ||
        extraBeds == null) {
      return null;
    }
    return BookingModificationDraft(
      checkIn: hotelDateOnly(checkIn),
      checkOut: hotelDateOnly(checkOut),
      adults: adults,
      children: children,
      extraBeds: extraBeds,
      ratePlanId: _selectedRatePlanId,
    );
  }

  DateTime? _parseDate(DateFormat formatter, String value) {
    try {
      return hotelDateOnly(formatter.parseStrict(value));
    } on FormatException {
      return null;
    }
  }

  HotelRatePlan? _ratePlanById(DemoBooking booking, int? ratePlanId) {
    final id = ratePlanId ?? booking.ratePlan.ratePlanId;
    for (final plan in booking.room.ratePlans) {
      if (plan.ratePlanId == id) return plan;
    }
    return null;
  }

  String _criteriaErrorMessage(
    AppLocalizations l10n,
    HotelCriteriaError error,
  ) {
    switch (error) {
      case HotelCriteriaError.pastCheckIn:
      case HotelCriteriaError.checkOutNotAfterCheckIn:
        return l10n.bookingModifyInvalidDates;
      case HotelCriteriaError.invalidAdults:
      case HotelCriteriaError.invalidChildren:
      case HotelCriteriaError.invalidExtraBeds:
        return l10n.bookingModifyInvalidGuests;
    }
  }
}

class _ModifyHero extends StatelessWidget {
  final DemoBooking booking;
  final BookingModificationEligibility eligibility;

  const _ModifyHero({
    required this.booking,
    required this.eligibility,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.bookingModifySemantic,
      container: true,
      explicitChildNodes: true,
      child: OceanGlassCard(
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
                  label: eligibility.canModify
                      ? l10n.bookingModifyAvailableLabel
                      : l10n.bookingModifyUnavailableLabel,
                  icon: eligibility.canModify
                      ? Icons.edit_calendar_rounded
                      : Icons.lock_rounded,
                  color: eligibility.canModify
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.bookingModifyTitle,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(booking.hotel.name,
                style: Theme.of(context).textTheme.titleLarge),
            Text(booking.room.roomName,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: l10n.bookingCodeSemantic,
              container: true,
              child: ExcludeSemantics(
                child: Text(
                  l10n.bookingLocalCode(booking.code),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.bookingModifyIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final DemoBooking booking;
  final TextEditingController checkInController;
  final TextEditingController checkOutController;
  final TextEditingController adultsController;
  final TextEditingController childrenController;
  final TextEditingController extraBedsController;
  final int? selectedRatePlanId;
  final String? message;
  final ValueChanged<int?> onRatePlanChanged;
  final VoidCallback onReview;

  const _EditStep({
    required this.formKey,
    required this.booking,
    required this.checkInController,
    required this.checkOutController,
    required this.adultsController,
    required this.childrenController,
    required this.extraBedsController,
    required this.selectedRatePlanId,
    required this.message,
    required this.onRatePlanChanged,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModifySectionCard(
          title: l10n.bookingModifyEditTitle,
          icon: Icons.tune_rounded,
          children: [
            Text(
              l10n.bookingModifyEditableFields,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Form(
              key: formKey,
              child: Column(
                children: [
                  _DateField(
                    key: const Key('modify-check-in-field'),
                    controller: checkInController,
                    label: l10n.bookingModifyCheckInLabel,
                  ),
                  _DateField(
                    key: const Key('modify-check-out-field'),
                    controller: checkOutController,
                    label: l10n.bookingModifyCheckOutLabel,
                  ),
                  _NumberField(
                    key: const Key('modify-adults-field'),
                    controller: adultsController,
                    label: l10n.bookingModifyAdultsLabel,
                  ),
                  _NumberField(
                    key: const Key('modify-children-field'),
                    controller: childrenController,
                    label: l10n.bookingModifyChildrenLabel,
                  ),
                  _NumberField(
                    key: const Key('modify-extra-beds-field'),
                    controller: extraBedsController,
                    label: l10n.bookingModifyExtraBedsLabel,
                  ),
                  DropdownButtonFormField<int>(
                    key: const Key('modify-rate-plan-field'),
                    initialValue: selectedRatePlanId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.bookingModifyRatePlanLabel,
                      helperText: l10n.bookingModifyRatePlanHelper,
                    ),
                    items: [
                      for (final plan in booking.room.ratePlans)
                        DropdownMenuItem<int>(
                          value: plan.ratePlanId,
                          enabled: plan.eligible,
                          child: Text(plan.rateName),
                        ),
                    ],
                    onChanged: onRatePlanChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _BoundaryCard(),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.md),
          OceanRecoverableErrorState(message: message!),
        ],
        const SizedBox(height: AppSpacing.lg),
        OceanPrimaryButton(
          key: const Key('modify-review-action'),
          label: l10n.bookingModifyContinueReviewAction,
          icon: Icons.fact_check_rounded,
          semanticLabel: l10n.bookingModifyContinueReviewAction,
          onPressed: onReview,
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final DemoBooking booking;
  final BookingModificationDraft draft;
  final HotelRatePlan ratePlan;
  final HotelPricingQuote quote;
  final bool submitting;
  final String? message;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  const _ReviewStep({
    required this.booking,
    required this.draft,
    required this.ratePlan,
    required this.quote,
    required this.submitting,
    required this.message,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModifySectionCard(
          title: l10n.bookingModifyReviewTitle,
          icon: Icons.fact_check_rounded,
          children: [
            Text(
              l10n.bookingModifyReviewInstruction,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _CompareRow(
              label: l10n.bookingModifyCheckInLabel,
              current: _formatDate(context, booking.criteria.checkIn),
              proposed: _formatDate(context, draft.checkIn),
              changed: hotelDateOnly(booking.criteria.checkIn) !=
                  hotelDateOnly(draft.checkIn),
            ),
            _CompareRow(
              label: l10n.bookingModifyCheckOutLabel,
              current: _formatDate(context, booking.criteria.checkOut),
              proposed: _formatDate(context, draft.checkOut),
              changed: hotelDateOnly(booking.criteria.checkOut) !=
                  hotelDateOnly(draft.checkOut),
            ),
            _CompareRow(
              label: l10n.bookingNightsLabel,
              current: l10n.hotelNights(booking.criteria.nights),
              proposed: l10n.hotelNights(
                hotelDateOnly(draft.checkOut)
                    .difference(hotelDateOnly(draft.checkIn))
                    .inDays,
              ),
              changed: booking.criteria.nights !=
                  hotelDateOnly(draft.checkOut)
                      .difference(hotelDateOnly(draft.checkIn))
                      .inDays,
            ),
            _CompareRow(
              label: l10n.bookingGuestsLabel,
              current: l10n.hotelGuestSummary(
                booking.criteria.adults,
                booking.criteria.children,
              ),
              proposed: l10n.hotelGuestSummary(draft.adults, draft.children),
              changed: booking.criteria.adults != draft.adults ||
                  booking.criteria.children != draft.children,
            ),
            _CompareRow(
              label: l10n.bookingModifyExtraBedsLabel,
              current: booking.criteria.extraBeds.toString(),
              proposed: draft.extraBeds.toString(),
              changed: booking.criteria.extraBeds != draft.extraBeds,
            ),
            _CompareRow(
              label: l10n.bookingModifyRatePlanLabel,
              current: booking.ratePlan.rateName,
              proposed: ratePlan.rateName,
              changed: booking.ratePlan.ratePlanId != ratePlan.ratePlanId,
            ),
            _CompareRow(
              label: l10n.bookingTotalLabel,
              current: formatMoney(
                context,
                booking.quote.finalQuotedPrice ?? 0,
                booking.quote.currency,
              ),
              proposed: formatMoney(
                context,
                quote.finalQuotedPrice ?? 0,
                quote.currency,
              ),
              changed: booking.quote.finalQuotedPrice != quote.finalQuotedPrice,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ModifySectionCard(
          title: l10n.bookingPolicyTitle,
          icon: Icons.gpp_maybe_rounded,
          children: [
            _InfoLine(
              icon: Icons.policy_rounded,
              label: l10n.bookingModifyProposedLabel,
              value: ratePlan.policySummary.trim().isEmpty
                  ? l10n.bookingModifySnapshotBoundary
                  : ratePlan.policySummary,
            ),
            _InfoLine(
              icon: Icons.price_change_rounded,
              label: l10n.bookingModifyPriceBoundaryLabel,
              value: l10n.bookingModifyPriceBoundary,
            ),
            _InfoLine(
              icon: Icons.inventory_2_rounded,
              label: l10n.bookingModifyAvailabilityBoundaryLabel,
              value: l10n.bookingModifyAvailabilityBoundary,
            ),
            _InfoLine(
              icon: Icons.payments_rounded,
              label: l10n.bookingModifyPaymentBoundaryLabel,
              value: l10n.bookingModifyPaymentBoundary,
            ),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.md),
          OceanRecoverableErrorState(message: message!),
        ],
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OceanSecondaryButton(
              key: const Key('modify-back-edit-action'),
              label: l10n.bookingModifyBackToEditAction,
              icon: Icons.arrow_back_rounded,
              fullWidth: false,
              onPressed: submitting ? null : onBack,
            ),
            OceanPrimaryButton(
              key: const Key('modify-confirm-action'),
              label: l10n.bookingModifyConfirmAction,
              icon: Icons.check_circle_rounded,
              fullWidth: false,
              semanticLabel: l10n.bookingModifyConfirmAction,
              onPressed: submitting ? null : onConfirm,
            ),
          ],
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _DateField({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.datetime,
        decoration: InputDecoration(
          labelText: label,
          helperText: l10n.bookingModifyDateHelp,
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? l10n.bookingModifyRequiredField
            : null,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _NumberField({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value == null || value.trim().isEmpty
            ? l10n.bookingModifyRequiredField
            : null,
      ),
    );
  }
}

class _BoundaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ModifySectionCard(
      title: l10n.bookingModifyBoundariesTitle,
      icon: Icons.shield_rounded,
      children: [
        _InfoLine(
          icon: Icons.science_rounded,
          label: l10n.bookingModifyDemoLabel,
          value: l10n.bookingModifyDemoBoundary,
        ),
        _InfoLine(
          icon: Icons.hotel_rounded,
          label: l10n.bookingModifyRoomUnchanged,
          value: l10n.bookingModifyRoomCountUnchanged,
        ),
        _InfoLine(
          icon: Icons.public_rounded,
          label: l10n.bookingModifyLiveRepricingTitle,
          value: l10n.bookingModifyLiveRepricingUnavailable,
        ),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String current;
  final String proposed;
  final bool changed;

  const _CompareRow({
    required this.label,
    required this.current,
    required this.proposed,
    required this.changed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        label:
            '$label $current ${changed ? proposed : l10n.bookingModifyUnchangedLabel}',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(label,
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  OceanStatusPill(
                    label: changed
                        ? l10n.bookingModifyChangedLabel
                        : l10n.bookingModifyUnchangedLabel,
                    icon: changed
                        ? Icons.compare_arrows_rounded
                        : Icons.check_rounded,
                    color: changed ? AppColors.warning : AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text('${l10n.bookingModifyCurrentLabel}: $current',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text('${l10n.bookingModifyProposedLabel}: $proposed',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
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
      );
}

class _ModifySectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ModifySectionCard({
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

String bookingModificationResultMessage(
  AppLocalizations l10n,
  BookingModificationResult result,
) {
  switch (result) {
    case BookingModificationResult.available:
      return l10n.bookingModifySuccessMessage;
    case BookingModificationResult.unavailable:
      return l10n.bookingModifyUnavailableReal;
    case BookingModificationResult.notFound:
      return l10n.bookingModifyUnavailableNotFound;
    case BookingModificationResult.forbidden:
      return l10n.bookingModifyUnavailableForbidden;
    case BookingModificationResult.onlyPending:
      return l10n.bookingModifyUnavailableOnlyPending;
    case BookingModificationResult.activePaymentStarted:
      return l10n.bookingModifyUnavailablePaymentStarted;
    case BookingModificationResult.roomRateUnavailable:
      return l10n.bookingModifyUnavailableRoomRate;
    case BookingModificationResult.stayStarted:
      return l10n.bookingModifyUnavailableStarted;
    case BookingModificationResult.invalidDates:
      return l10n.bookingModifyInvalidDates;
    case BookingModificationResult.invalidGuests:
      return l10n.bookingModifyInvalidGuests;
    case BookingModificationResult.capacityExceeded:
      return l10n.bookingModifyCapacityExceeded;
    case BookingModificationResult.quoteUnavailable:
      return l10n.bookingModifyQuoteUnavailable;
    case BookingModificationResult.noChanges:
      return l10n.bookingModifyNoChanges;
    case BookingModificationResult.stale:
      return l10n.bookingModifyStale;
  }
}

String _formatDate(BuildContext context, DateTime value) {
  final formatter =
      DateFormat.yMMMd(Localizations.localeOf(context).toString());
  return formatter.format(value);
}
