import 'package:flutter/material.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/partner/partner_property_form_models.dart';
import '../../../core/partner/partner_property_models.dart';
import '../../../core/partner/property_messages.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../../auth/auth_page_scaffold.dart';
import 'partner_property_editor_state.dart';

/// The Partner property editor — create a draft property, or edit one.
///
/// ## What it is not
///
/// There is no publish action, because no partner endpoint publishes: a
/// property becomes visible to travellers when an administrator moves its
/// `PlaceStatus` to PUBLISHED. There is no image upload, no room configuration
/// and no rates either; those are later phases with their own backends.
///
/// ## Where the options come from
///
/// The property type, the administrative area and the amenities are the
/// admin-managed catalogue, fetched by [PartnerPropertyEditorState]. This screen
/// cannot offer anything the backend did not return, and the backend validates
/// every id again — a refused one comes back named in `fieldErrors` and is shown
/// on the control that caused it.
class PartnerPropertyEditorScreen extends StatefulWidget {
  final PartnerPropertyEditorState state;

  /// Called with the record the server wrote, once a save succeeds.
  final ValueChanged<PartnerPropertyDetail>? onSaved;

  const PartnerPropertyEditorScreen({
    super.key,
    required this.state,
    this.onSaved,
  });

  @override
  State<PartnerPropertyEditorScreen> createState() =>
      _PartnerPropertyEditorScreenState();
}

class _PartnerPropertyEditorScreenState
    extends State<PartnerPropertyEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final PartnerPropertyDetail? _original = widget.state.original;

  late final _name = TextEditingController(text: _original?.name ?? '');
  late final _shortDescription =
      TextEditingController(text: _original?.shortDescription ?? '');
  late final _description =
      TextEditingController(text: _original?.description ?? '');
  late final _address = TextEditingController(text: _original?.address ?? '');
  late final _latitude =
      TextEditingController(text: _original?.latitude?.toString() ?? '');
  late final _longitude =
      TextEditingController(text: _original?.longitude?.toString() ?? '');
  late final _phone = TextEditingController(text: _original?.phone ?? '');
  late final _email = TextEditingController(text: _original?.email ?? '');
  late final _website = TextEditingController(text: _original?.website ?? '');
  // 14:00 / 12:00 are this form's starting suggestion for a brand-new property,
  // shown in the field from the first frame so nothing is submitted the partner
  // has not seen and can change.
  late final _checkIn =
      TextEditingController(text: _original?.checkIn ?? '14:00');
  late final _checkOut =
      TextEditingController(text: _original?.checkOut ?? '12:00');
  late final _childrenPolicy =
      TextEditingController(text: _original?.childrenPolicy ?? '');
  late final _petPolicy =
      TextEditingController(text: _original?.petPolicy ?? '');
  late final _smokingPolicy =
      TextEditingController(text: _original?.smokingPolicy ?? '');
  late final _cancellationPolicy =
      TextEditingController(text: _original?.cancellationPolicy ?? '');
  late final _parkingDescription =
      TextEditingController(text: _original?.parkingDescription ?? '');
  late final _internetDescription =
      TextEditingController(text: _original?.internetDescription ?? '');
  late final _languages =
      TextEditingController(text: _original?.languages.join(', ') ?? '');
  late final _paymentMethods =
      TextEditingController(text: _original?.paymentMethods.join(', ') ?? '');

  static final RegExp _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.state.load();
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _shortDescription,
      _description,
      _address,
      _latitude,
      _longitude,
      _phone,
      _email,
      _website,
      _checkIn,
      _checkOut,
      _childrenPolicy,
      _petPolicy,
      _smokingPolicy,
      _cancellationPolicy,
      _parkingDescription,
      _internetDescription,
      _languages,
      _paymentMethods,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final title = state.isCreating
            ? l10n.partnerPropertyEditorCreateTitle
            : l10n.partnerPropertyEditorEditTitle;
        return AuthPageScaffold(
          title: title,
          heading: title,
          subtitle: l10n.partnerPropertyEditorIntro,
          icon: Icons.apartment_rounded,
          onBack: state.isSaving ? null : () => Navigator.maybePop(context),
          children: switch (state.status) {
            PropertyEditorStatus.loading => [
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.partnerPropertyReferenceLoading),
                    ],
                  ),
                ),
              ],
            PropertyEditorStatus.referenceError => [
                AuthNotice(
                  key: const Key('property-editor-reference-error'),
                  icon: Icons.cloud_off_rounded,
                  message: l10n.partnerPropertyReferenceError,
                ),
                const SizedBox(height: AppSpacing.lg),
                OceanSecondaryButton(
                  key: const Key('property-editor-reference-retry'),
                  label: l10n.partnerActionRetry,
                  icon: Icons.refresh_rounded,
                  onPressed: state.load,
                ),
              ],
            PropertyEditorStatus.ready => _form(context, l10n, state),
          },
        );
      },
    );
  }

  List<Widget> _form(
    BuildContext context,
    AppLocalizations l10n,
    PartnerPropertyEditorState state,
  ) {
    final failure = state.failure;
    return [
      AuthNotice(
        key: const Key('property-editor-draft-notice'),
        icon: Icons.edit_note_rounded,
        message: l10n.partnerPropertyDraftNotice,
      ),
      const SizedBox(height: AppSpacing.lg),
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(context, l10n.partnerPropertyEditorSectionBasics),
            _field(
              fieldKey: 'property-editor-name',
              controller: _name,
              label: l10n.partnerPropertyFieldName,
              icon: Icons.apartment_rounded,
              failure: failure,
              field: PropertyFields.name,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.partnerPropertyValidationName
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              fieldKey: 'property-editor-short-description',
              controller: _shortDescription,
              label: l10n.partnerPropertyFieldShortDescription,
              icon: Icons.short_text_rounded,
              failure: failure,
              field: PropertyFields.shortDescription,
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              fieldKey: 'property-editor-description',
              controller: _description,
              label: l10n.partnerPropertyFieldDescription,
              icon: Icons.notes_rounded,
              maxLines: 4,
              failure: failure,
              field: PropertyFields.description,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              key: const Key('property-editor-category'),
              initialValue: state.categoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.partnerPropertyFieldCategory,
                prefixIcon: const Icon(Icons.category_outlined),
                errorText:
                    propertyFieldMessage(failure, PropertyFields.categoryId),
              ),
              items: [
                for (final option in state.categoryOptions)
                  DropdownMenuItem(value: option.id, child: Text(option.name)),
              ],
              validator: (value) =>
                  value == null ? l10n.partnerPropertyValidationCategory : null,
              onChanged: state.isSaving ? null : state.selectCategory,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              key: const Key('property-editor-subcategory'),
              initialValue: state.subcategoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.partnerPropertyFieldSubcategory,
                prefixIcon: const Icon(Icons.local_offer_outlined),
                errorText:
                    propertyFieldMessage(failure, PropertyFields.subcategoryId),
              ),
              items: [
                for (final option in state.subcategoryOptions)
                  DropdownMenuItem(value: option.id, child: Text(option.name)),
              ],
              onChanged: state.isSaving ? null : state.selectSubcategory,
            ),
            if (!state.isCreating) ...[
              const SizedBox(height: AppSpacing.md),
              _readOnlyRow(
                context,
                label: l10n.partnerPropertyFieldSlug,
                value: _original?.slug ?? '',
                help: l10n.partnerPropertySlugHelp,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _sectionTitle(context, l10n.partnerPropertyEditorSectionLocation),
            _locationPicker(context, l10n, state),
            const SizedBox(height: AppSpacing.md),
            _field(
              fieldKey: 'property-editor-address',
              controller: _address,
              label: l10n.partnerPropertyFieldAddress,
              icon: Icons.place_outlined,
              failure: failure,
              field: PropertyFields.address,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.partnerPropertyValidationAddress
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    fieldKey: 'property-editor-latitude',
                    controller: _latitude,
                    label: l10n.partnerPropertyFieldLatitude,
                    icon: Icons.swap_vert_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    failure: failure,
                    field: PropertyFields.latitude,
                    validator: (value) => _coordinate(
                        value, 90, l10n.partnerPropertyValidationLatitude),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _field(
                    fieldKey: 'property-editor-longitude',
                    controller: _longitude,
                    label: l10n.partnerPropertyFieldLongitude,
                    icon: Icons.swap_horiz_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    failure: failure,
                    field: PropertyFields.longitude,
                    validator: (value) => _coordinate(
                        value, 180, l10n.partnerPropertyValidationLongitude),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _help(context, l10n.partnerPropertyCoordinatesHelp),
            const SizedBox(height: AppSpacing.lg),
            _sectionTitle(context, l10n.partnerPropertyEditorSectionContact),
            _field(
              fieldKey: 'property-editor-phone',
              controller: _phone,
              label: l10n.partnerPropertyFieldPhone,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              failure: failure,
              field: PropertyFields.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              fieldKey: 'property-editor-email',
              controller: _email,
              label: l10n.partnerPropertyFieldEmail,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              failure: failure,
              field: PropertyFields.email,
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return null;
                return _emailPattern.hasMatch(text)
                    ? null
                    : l10n.partnerPropertyValidationEmail;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              fieldKey: 'property-editor-website',
              controller: _website,
              label: l10n.partnerPropertyFieldWebsite,
              icon: Icons.public_outlined,
              keyboardType: TextInputType.url,
              failure: failure,
              field: PropertyFields.website,
            ),
            const SizedBox(height: AppSpacing.lg),
            _sectionTitle(context, l10n.partnerPropertyEditorSectionDetails),
            DropdownButtonFormField<int>(
              key: const Key('property-editor-star-rating'),
              initialValue: state.starRating,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.partnerPropertyFieldStarRating,
                prefixIcon: const Icon(Icons.star_border_rounded),
                helperText: l10n.partnerPropertyStarRatingHelp,
                helperMaxLines: 3,
                errorText:
                    propertyFieldMessage(failure, PropertyFields.starRating),
              ),
              items: [
                for (var rating = 1; rating <= 5; rating++)
                  DropdownMenuItem(value: rating, child: Text('$rating')),
              ],
              validator: (value) => value == null
                  ? l10n.partnerPropertyValidationStarRating
                  : null,
              onChanged: state.isSaving
                  ? null
                  : (value) => state.setStarRating(value ?? state.starRating),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    fieldKey: 'property-editor-check-in',
                    controller: _checkIn,
                    label: l10n.partnerPropertyFieldCheckIn,
                    icon: Icons.login_rounded,
                    failure: failure,
                    field: PropertyFields.checkIn,
                    validator: (value) => _time.hasMatch((value ?? '').trim())
                        ? null
                        : l10n.partnerPropertyValidationTime,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _field(
                    fieldKey: 'property-editor-check-out',
                    controller: _checkOut,
                    label: l10n.partnerPropertyFieldCheckOut,
                    icon: Icons.logout_rounded,
                    failure: failure,
                    field: PropertyFields.checkOut,
                    validator: (value) => _time.hasMatch((value ?? '').trim())
                        ? null
                        : l10n.partnerPropertyValidationTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              fieldKey: 'property-editor-children-policy',
              controller: _childrenPolicy,
              label: l10n.partnerPropertyFieldChildrenPolicy,
              icon: Icons.child_care_outlined,
              maxLines: 2,
              failure: failure,
              field: 'childrenPolicy',
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              fieldKey: 'property-editor-pet-policy',
              controller: _petPolicy,
              label: l10n.partnerPropertyFieldPetPolicy,
              icon: Icons.pets_outlined,
              maxLines: 2,
              failure: failure,
              field: 'petPolicy',
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              fieldKey: 'property-editor-smoking-policy',
              controller: _smokingPolicy,
              label: l10n.partnerPropertyFieldSmokingPolicy,
              icon: Icons.smoke_free_rounded,
              maxLines: 2,
              failure: failure,
              field: 'smokingPolicy',
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              fieldKey: 'property-editor-cancellation-policy',
              controller: _cancellationPolicy,
              label: l10n.partnerPropertyFieldCancellationPolicy,
              icon: Icons.event_busy_outlined,
              maxLines: 2,
              failure: failure,
              field: 'cancellationPolicy',
            ),
            _toggle(
              toggleKey: 'property-editor-free-cancellation',
              value: state.freeCancellation,
              label: l10n.partnerPropertyFreeCancellation,
              onChanged: state.isSaving ? null : state.setFreeCancellation,
            ),
            _toggle(
              toggleKey: 'property-editor-parking-available',
              value: state.parkingAvailable,
              label: l10n.partnerPropertyParkingAvailable,
              onChanged: state.isSaving ? null : state.setParkingAvailable,
            ),
            if (state.parkingAvailable) ...[
              _toggle(
                toggleKey: 'property-editor-parking-free',
                value: state.parkingFree,
                label: l10n.partnerPropertyParkingFree,
                onChanged: state.isSaving ? null : state.setParkingFree,
              ),
              _field(
                fieldKey: 'property-editor-parking-description',
                controller: _parkingDescription,
                label: l10n.partnerPropertyFieldParking,
                icon: Icons.local_parking_outlined,
                maxLines: 2,
                failure: failure,
                field: 'parkingDescription',
              ),
            ],
            _toggle(
              toggleKey: 'property-editor-wifi-available',
              value: state.wifiAvailable,
              label: l10n.partnerPropertyWifiAvailable,
              onChanged: state.isSaving ? null : state.setWifiAvailable,
            ),
            if (state.wifiAvailable) ...[
              _toggle(
                toggleKey: 'property-editor-wifi-free',
                value: state.wifiFree,
                label: l10n.partnerPropertyWifiFree,
                onChanged: state.isSaving ? null : state.setWifiFree,
              ),
              _field(
                fieldKey: 'property-editor-internet-description',
                controller: _internetDescription,
                label: l10n.partnerPropertyFieldWifi,
                icon: Icons.wifi_rounded,
                maxLines: 2,
                failure: failure,
                field: 'internetDescription',
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _field(
              fieldKey: 'property-editor-languages',
              controller: _languages,
              label: l10n.partnerPropertyFieldLanguages,
              icon: Icons.translate_rounded,
              helperText: l10n.partnerPropertyListHelp,
              failure: failure,
              field: 'languages',
            ),
            const SizedBox(height: AppSpacing.md),
            _field(
              fieldKey: 'property-editor-payment-methods',
              controller: _paymentMethods,
              label: l10n.partnerPropertyFieldPaymentMethods,
              icon: Icons.payments_outlined,
              helperText: l10n.partnerPropertyListHelp,
              failure: failure,
              field: 'paymentMethods',
            ),
            const SizedBox(height: AppSpacing.lg),
            _sectionTitle(context, l10n.partnerPropertyEditorSectionAmenities),
            _amenities(context, l10n, state),
          ],
        ),
      ),
      if (failure != null) ...[
        const SizedBox(height: AppSpacing.md),
        AuthNotice(
          key: const Key('property-editor-error'),
          icon: Icons.error_outline_rounded,
          message: propertyFailureMessage(l10n, failure),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      AuthSubmitButton(
        buttonKey: const Key('property-editor-save'),
        label: state.isCreating
            ? l10n.partnerPropertyEditorSaveDraft
            : l10n.partnerPropertyEditorSaveChanges,
        icon: Icons.save_outlined,
        busy: state.isSaving,
        onPressed: _save,
      ),
      const SizedBox(height: AppSpacing.sm),
      OceanSecondaryButton(
        key: const Key('property-editor-cancel'),
        label: l10n.partnerPropertyEditorCancel,
        icon: Icons.close_rounded,
        onPressed: state.isSaving ? null : () => Navigator.maybePop(context),
      ),
    ];
  }

  Widget _locationPicker(
    BuildContext context,
    AppLocalizations l10n,
    PartnerPropertyEditorState state,
  ) {
    final current = state.currentLocationLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (current != null && !state.hasPickedLocation) ...[
          _readOnlyRow(
            context,
            label: l10n.partnerPropertyFieldLocationUnit,
            value: current,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        DropdownButtonFormField<int>(
          key: const Key('property-editor-country'),
          initialValue: state.countryId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.partnerPropertyLocationCountry,
            prefixIcon: const Icon(Icons.public_rounded),
          ),
          items: [
            for (final option in state.countryOptions)
              DropdownMenuItem(value: option.id, child: Text(option.name)),
          ],
          onChanged: state.isSaving ? null : state.selectCountry,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<int>(
          key: const Key('property-editor-province'),
          initialValue: state.provinceId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.partnerPropertyLocationProvince,
            prefixIcon: const Icon(Icons.map_outlined),
            errorText: propertyFieldMessage(
                state.failure, PropertyFields.administrativeUnitId),
          ),
          items: [
            for (final option in state.provinceOptions)
              DropdownMenuItem(value: option.id, child: Text(option.name)),
          ],
          onChanged: state.isSaving ? null : state.selectProvince,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<int>(
          key: const Key('property-editor-area'),
          initialValue: state.areaId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.partnerPropertyLocationArea,
            prefixIcon: const Icon(Icons.location_city_outlined),
          ),
          items: [
            for (final option in state.areaOptions)
              DropdownMenuItem(value: option.id, child: Text(option.name)),
          ],
          onChanged: state.isSaving ? null : state.selectArea,
        ),
        if (state.isLoadingLocationChildren) ...[
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Widget _amenities(
    BuildContext context,
    AppLocalizations l10n,
    PartnerPropertyEditorState state,
  ) {
    final groups = state.amenityGroups;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _help(context, l10n.partnerPropertyAmenitiesHelp),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.partnerPropertyAmenitiesSelected(
              state.selectedAmenityIds.length),
          key: const Key('property-editor-amenities-count'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        for (final entry in groups.entries) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final amenity in entry.value)
                FilterChip(
                  key: Key('property-editor-amenity-${amenity.id}'),
                  label: Text(amenity.name),
                  selected: state.selectedAmenityIds.contains(amenity.id),
                  onSelected: state.isSaving
                      ? null
                      : (_) => state.toggleAmenity(amenity.id),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// A plain Switch with its label rather than a SwitchListTile: the card this
  /// form sits in paints its own background, which would hide a ListTile's ink.
  /// MergeSemantics keeps the two announced as one control.
  Widget _toggle({
    required String toggleKey,
    required bool value,
    required String label,
    required ValueChanged<bool>? onChanged,
  }) =>
      MergeSemantics(
        child: Row(
          children: [
            Switch(key: Key(toggleKey), value: value, onChanged: onChanged),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(label)),
          ],
        ),
      );

  Widget _sectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );

  Widget _help(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      );

  Widget _readOnlyRow(
    BuildContext context, {
    required String label,
    required String value,
    String? help,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(value, style: theme.textTheme.bodyMedium),
        if (help != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          _help(context, help),
        ],
      ],
    );
  }

  Widget _field({
    required String fieldKey,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ApiFailure? failure,
    required String field,
    String? helperText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        key: Key(fieldKey),
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: !widget.state.isSaving,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          helperText: helperText,
          helperMaxLines: 2,
          // The backend's own wording for the field it refused. English only,
          // so the localized summary is always shown next to it, never instead.
          errorText: propertyFieldMessage(failure, field),
        ),
      );

  String? _coordinate(String? value, double bound, String message) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < -bound || parsed > bound) return message;
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;
    if (state.isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // The location is a choice, not a field: the form cannot validate it, so it
    // is checked here and reported on the control that carries it.
    if (state.selectedLocationId == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.partnerPropertyValidationLocation)),
      );
      return;
    }

    final saved = await state.save(PropertyFormText(
      name: _name.text,
      shortDescription: _shortDescription.text,
      description: _description.text,
      address: _address.text,
      latitude: _latitude.text,
      longitude: _longitude.text,
      phone: _phone.text,
      email: _email.text,
      website: _website.text,
      checkIn: _checkIn.text,
      checkOut: _checkOut.text,
      childrenPolicy: _childrenPolicy.text,
      petPolicy: _petPolicy.text,
      smokingPolicy: _smokingPolicy.text,
      cancellationPolicy: _cancellationPolicy.text,
      parkingDescription: _parkingDescription.text,
      internetDescription: _internetDescription.text,
      languages: _languages.text,
      paymentMethods: _paymentMethods.text,
    ));
    if (!mounted || saved == null) return;

    // Only now, with the server's own record in hand, is anything reported as
    // saved.
    widget.onSaved?.call(saved);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(state.isCreating
            ? l10n.partnerPropertyCreatedMessage(saved.name)
            : l10n.partnerPropertySavedMessage(saved.name)),
      ),
    );
    Navigator.maybePop(context);
  }
}
