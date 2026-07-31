import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'booking_review_screen.dart';
import 'booking_widgets.dart';

/// Step 2 of the UI25 booking flow. Collects the primary guest, contact details,
/// arrival time and special requests. The backend booking request accepts none
/// of the name/phone/country/arrival fields (the booker is the JWT user), so
/// these are autosaved to [AppState] as local-only draft data — surfaced as an
/// honest note. Validation is client-side; no submission happens here.
class BookingGuestInfoScreen extends StatefulWidget {
  final Place hotel;
  final HotelStayCriteria criteria;

  const BookingGuestInfoScreen({
    super.key,
    required this.hotel,
    required this.criteria,
  });

  @override
  State<BookingGuestInfoScreen> createState() => _BookingGuestInfoScreenState();
}

class _BookingGuestInfoScreenState extends State<BookingGuestInfoScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _country = TextEditingController();
  final _arrival = TextEditingController();
  final _note = TextEditingController();
  bool _submitted = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      final app = AppScope.of(context);
      app.prefillBookingContactEmail();
      _name.text = app.bookingGuestName;
      _email.text = app.bookingContactEmail;
      _phone.text = app.bookingContactPhone;
      _country.text = app.bookingGuestCountry;
      _arrival.text = app.bookingArrivalTime;
      _note.text = app.bookingSpecialRequestNote;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _country.dispose();
    _arrival.dispose();
    _note.dispose();
    super.dispose();
  }

  void _continue(AppState app) {
    if (!app.validateBookingDraft().isValid) {
      setState(() => _submitted = true);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingReviewScreen(
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
    final v = app.validateBookingDraft();
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.bookingGuestInfoTitle),
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
                    const BookingStepHeader(current: 2, total: 3),
                    OceanGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.bookingGuestSectionTitle,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            key: const Key('booking-guest-name'),
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            maxLength: BookingValidation.maxNameLength,
                            onChanged: (value) =>
                                app.updateBookingGuestField(name: value),
                            decoration: InputDecoration(
                              labelText: l10n.bookingGuestNameLabel,
                              prefixIcon: const Icon(Icons.person_rounded),
                              counterText: '',
                              errorText: (_submitted && v.nameRequired)
                                  ? l10n.bookingValidationNameRequired
                                  : (v.nameTooLong
                                      ? l10n.bookingValidationTooLong
                                      : null),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            key: const Key('booking-guest-email'),
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) =>
                                app.updateBookingGuestField(email: value),
                            decoration: InputDecoration(
                              labelText: l10n.bookingGuestEmailLabel,
                              prefixIcon: const Icon(Icons.email_rounded),
                              errorText: v.emailInvalid
                                  ? l10n.bookingValidationEmailInvalid
                                  : ((_submitted && v.emailRequired)
                                      ? l10n.bookingValidationEmailRequired
                                      : null),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            key: const Key('booking-guest-phone'),
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            maxLength: BookingValidation.maxPhoneLength,
                            onChanged: (value) =>
                                app.updateBookingGuestField(phone: value),
                            decoration: InputDecoration(
                              labelText: l10n.bookingGuestPhoneLabel,
                              prefixIcon: const Icon(Icons.phone_rounded),
                              counterText: '',
                              errorText: v.phoneInvalid
                                  ? l10n.bookingValidationPhoneInvalid
                                  : (v.phoneTooLong
                                      ? l10n.bookingValidationTooLong
                                      : null),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            key: const Key('booking-guest-country'),
                            controller: _country,
                            textCapitalization: TextCapitalization.words,
                            maxLength: BookingValidation.maxCountryLength,
                            onChanged: (value) =>
                                app.updateBookingGuestField(country: value),
                            decoration: InputDecoration(
                              labelText: l10n.bookingGuestCountryLabel,
                              prefixIcon: const Icon(Icons.public_rounded),
                              counterText: '',
                              errorText: v.countryTooLong
                                  ? l10n.bookingValidationTooLong
                                  : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            key: const Key('booking-guest-arrival'),
                            controller: _arrival,
                            onChanged: (value) =>
                                app.updateBookingGuestField(arrivalTime: value),
                            decoration: InputDecoration(
                              labelText: l10n.bookingArrivalTimeLabel,
                              hintText: l10n.bookingArrivalTimeHint,
                              prefixIcon: const Icon(Icons.schedule_rounded),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.bookingGuestLocalOnlyNote,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SpecialRequests(app: app),
                    const SizedBox(height: AppSpacing.md),
                    OceanGlassCard(
                      child: TextField(
                        key: const Key('booking-guest-note'),
                        controller: _note,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: BookingValidation.maxNoteLength,
                        onChanged: app.setBookingSpecialRequestNote,
                        decoration: InputDecoration(
                          labelText: l10n.bookingSpecialRequestNoteLabel,
                          helperText: l10n.bookingSpecialRequestNoteHelper,
                          prefixIcon: const Icon(Icons.notes_rounded),
                          errorText: v.noteTooLong
                              ? l10n.bookingValidationTooLong
                              : null,
                        ),
                      ),
                    ),
                    if (_submitted && !v.isValid) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        key: const Key('booking-guest-validation'),
                        _firstError(l10n, v),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.coral),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    OceanPrimaryButton(
                      key: const Key('booking-guest-continue'),
                      label: l10n.bookingReviewContinueAction,
                      icon: Icons.fact_check_outlined,
                      semanticLabel: l10n.bookingReviewContinueAction,
                      onPressed: () => _continue(app),
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

  String _firstError(AppLocalizations l10n, BookingValidation v) {
    if (v.nameRequired) return l10n.bookingValidationNameRequired;
    if (v.emailRequired) return l10n.bookingValidationEmailRequired;
    if (v.emailInvalid) return l10n.bookingValidationEmailInvalid;
    if (v.phoneInvalid) return l10n.bookingValidationPhoneInvalid;
    return l10n.bookingValidationTooLong;
  }
}

class _SpecialRequests extends StatelessWidget {
  final AppState app;

  const _SpecialRequests({required this.app});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingSpecialRequestsTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final preset in SpecialRequestPreset.values)
                FilterChip(
                  key: Key('special-request-${preset.name}'),
                  label: Text(specialRequestPresetLabel(l10n, preset)),
                  avatar: Icon(specialRequestPresetIcon(preset),
                      size: AppSpacing.md),
                  selected: app.bookingSpecialRequestPresets.contains(preset),
                  onSelected: (_) => app.toggleBookingSpecialRequest(preset),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
