import 'package:flutter/material.dart';

import '../../../../core/partner/partner_models.dart';
import '../../../../core/partner/partner_property_form_models.dart';
import '../../../../core/partner/property_messages.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import 'property_wizard_state.dart';

/// Every text field of the wizard, owned by the screen rather than by a step.
///
/// The steps come and go as the partner moves through them; the controllers do
/// not. That is what makes stepping backwards and forwards lossless — nothing
/// typed is ever rebuilt from scratch.
class PropertyWizardControllers {
  final name = TextEditingController();
  final shortDescription = TextEditingController();
  final description = TextEditingController();
  final address = TextEditingController();
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final website = TextEditingController();
  final checkIn = TextEditingController();
  final checkOut = TextEditingController();
  final childrenPolicy = TextEditingController();
  final petPolicy = TextEditingController();
  final smokingPolicy = TextEditingController();
  final cancellationPolicy = TextEditingController();
  final parkingDescription = TextEditingController();
  final internetDescription = TextEditingController();
  final languages = TextEditingController();
  final paymentMethods = TextEditingController();
  final amenitySearch = TextEditingController();

  List<TextEditingController> get _all => [
        name,
        shortDescription,
        description,
        address,
        latitude,
        longitude,
        phone,
        email,
        website,
        checkIn,
        checkOut,
        childrenPolicy,
        petPolicy,
        smokingPolicy,
        cancellationPolicy,
        parkingDescription,
        internetDescription,
        languages,
        paymentMethods,
        amenitySearch,
      ];

  /// Pushes the state's values into the fields — after a load, a save (the
  /// server may have normalised something) or a discard.
  void syncFrom(PropertyWizardState state) {
    void set(TextEditingController controller, String value) {
      if (controller.text == value) return;
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }

    set(name, state.name);
    set(shortDescription, state.shortDescription);
    set(description, state.description);
    set(address, state.address);
    set(latitude, state.latitude);
    set(longitude, state.longitude);
    set(phone, state.phone);
    set(email, state.email);
    set(website, state.website);
    set(checkIn, state.checkIn);
    set(checkOut, state.checkOut);
    set(childrenPolicy, state.childrenPolicy);
    set(petPolicy, state.petPolicy);
    set(smokingPolicy, state.smokingPolicy);
    set(cancellationPolicy, state.cancellationPolicy);
    set(parkingDescription, state.parkingDescription);
    set(internetDescription, state.internetDescription);
    set(languages, state.languages);
    set(paymentMethods, state.paymentMethods);
  }

  void dispose() {
    for (final controller in _all) {
      controller.dispose();
    }
  }
}

/// The body of whichever step is open.
class PropertyWizardStepView extends StatelessWidget {
  final PropertyWizardState state;
  final PropertyWizardControllers controllers;

  /// Focused after every step change, so assistive technology lands on the new
  /// step's heading rather than staying where the old step was.
  final FocusNode headingFocus;

  final VoidCallback onEditBusinessProfile;
  final ValueChanged<PropertyWizardStep> onJump;

  const PropertyWizardStepView({
    super.key,
    required this.state,
    required this.controllers,
    required this.headingFocus,
    required this.onEditBusinessProfile,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n),
        const SizedBox(height: AppSpacing.lg),
        ...switch (state.currentStep) {
          PropertyWizardStep.businessProfile => _businessProfile(context, l10n),
          PropertyWizardStep.basics => _basics(context, l10n),
          PropertyWizardStep.location => _location(context, l10n),
          PropertyWizardStep.contact => _contact(context, l10n),
          PropertyWizardStep.amenities => _amenities(context, l10n),
          PropertyWizardStep.policies => _policies(context, l10n),
          PropertyWizardStep.review => _review(context, l10n),
        },
      ],
    );
  }

  Widget _heading(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final step = state.currentStep;
    return Semantics(
      header: true,
      label: l10n.partnerWizardStepSemantic(
        step.index + 1,
        PropertyWizardStep.values.length,
        stepLabel(l10n, step),
      ),
      child: Focus(
        focusNode: headingFocus,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.partnerWizardStepOf(
                  step.index + 1, PropertyWizardStep.values.length),
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(stepLabel(l10n, step), style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(stepIntro(l10n, step), style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  // ── Step 0: business profile readiness ───────────────────────────────────

  List<Widget> _businessProfile(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final profile = state.profileStatus;
    final approved = state.isProfileApproved;
    return [
      Container(
        key: const Key('wizard-profile-status'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: approved ? AppColors.paleCyan : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              approved ? Icons.verified_rounded : Icons.lock_outline_rounded,
              color: approved ? AppColors.ocean : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    approved
                        ? l10n.partnerWizardProfileApproved
                        : l10n.partnerWizardProfileBlocked,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(_statusBody(l10n, profile),
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      // A summary of the profile, never a second form for it: the business
      // details have one owner, and it is the account area.
      if (state.profile != null) ...[
        _summaryRow(context, l10n.partnerBusinessFieldName,
            state.profile!.businessName),
        _summaryRow(context, l10n.partnerBusinessFieldRepresentative,
            state.profile!.representativeName),
        if (state.profile!.phone != null)
          _summaryRow(
              context, l10n.partnerBusinessFieldPhone, state.profile!.phone!),
        if (state.profile!.email != null)
          _summaryRow(
              context, l10n.partnerBusinessFieldEmail, state.profile!.email!),
        if (state.profile!.rejectReason != null)
          _summaryRow(context, l10n.partnerBusinessHeading,
              l10n.partnerBusinessRejectReason(state.profile!.rejectReason!)),
        const SizedBox(height: AppSpacing.md),
      ],
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: OceanSecondaryButton(
          key: const Key('wizard-profile-edit'),
          label: l10n.partnerWizardProfileEditAction,
          icon: Icons.business_outlined,
          fullWidth: false,
          onPressed: onEditBusinessProfile,
        ),
      ),
    ];
  }

  String _statusBody(AppLocalizations l10n, PartnerVerificationStatus status) =>
      switch (status) {
        PartnerVerificationStatus.draft => l10n.partnerBusinessStatusDraftBody,
        PartnerVerificationStatus.submitted =>
          l10n.partnerBusinessStatusSubmittedBody,
        PartnerVerificationStatus.approved =>
          l10n.partnerBusinessStatusApprovedBody,
        PartnerVerificationStatus.rejected =>
          l10n.partnerBusinessStatusRejectedBody,
        PartnerVerificationStatus.suspended =>
          l10n.partnerBusinessStatusSuspendedBody,
        PartnerVerificationStatus.unknown =>
          l10n.partnerBusinessStatusUnknownBody,
      };

  // ── Step 1: basics ───────────────────────────────────────────────────────

  List<Widget> _basics(BuildContext context, AppLocalizations l10n) => [
        _field(
          fieldKey: 'wizard-name',
          controller: controllers.name,
          label: l10n.partnerPropertyFieldName,
          icon: Icons.apartment_rounded,
          field: PropertyFields.name,
          onChanged: (value) => state.setText(() => state.name = value),
          validator: (value) => (value ?? '').trim().isEmpty
              ? l10n.partnerPropertyValidationName
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          fieldKey: 'wizard-short-description',
          controller: controllers.shortDescription,
          label: l10n.partnerPropertyFieldShortDescription,
          icon: Icons.short_text_rounded,
          field: PropertyFields.shortDescription,
          onChanged: (value) =>
              state.setText(() => state.shortDescription = value),
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          fieldKey: 'wizard-description',
          controller: controllers.description,
          label: l10n.partnerPropertyFieldDescription,
          icon: Icons.notes_rounded,
          field: PropertyFields.description,
          maxLines: 4,
          onChanged: (value) => state.setText(() => state.description = value),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<int>(
          key: const Key('wizard-category'),
          initialValue: state.categoryId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.partnerPropertyFieldCategory,
            prefixIcon: const Icon(Icons.category_outlined),
            errorText:
                propertyFieldMessage(state.failure, PropertyFields.categoryId),
          ),
          items: [
            for (final option in state.catalogue.categoryOptions)
              DropdownMenuItem(value: option.id, child: Text(option.name)),
          ],
          validator: (value) =>
              value == null ? l10n.partnerPropertyValidationCategory : null,
          onChanged: state.isSaving ? null : state.selectCategory,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<int>(
          key: const Key('wizard-subcategory'),
          initialValue: state.subcategoryId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.partnerPropertyFieldSubcategory,
            prefixIcon: const Icon(Icons.local_offer_outlined),
            errorText: propertyFieldMessage(
                state.failure, PropertyFields.subcategoryId),
          ),
          items: [
            for (final option
                in state.catalogue.subcategoryOptions(state.categoryId))
              DropdownMenuItem(value: option.id, child: Text(option.name)),
          ],
          onChanged: state.isSaving ? null : state.selectSubcategory,
        ),
        const SizedBox(height: AppSpacing.md),
        // Never defaulted: the schema demands 1–5 and has no "unclassified",
        // so the partner declares it or the step does not pass.
        DropdownButtonFormField<int>(
          key: const Key('wizard-star-rating'),
          initialValue: state.starRating,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.partnerPropertyFieldStarRating,
            prefixIcon: const Icon(Icons.star_border_rounded),
            helperText: l10n.partnerPropertyStarRatingHelp,
            helperMaxLines: 3,
            errorText:
                propertyFieldMessage(state.failure, PropertyFields.starRating),
          ),
          items: [
            for (var rating = 1; rating <= 5; rating++)
              DropdownMenuItem(value: rating, child: Text('$rating')),
          ],
          validator: (value) =>
              value == null ? l10n.partnerPropertyValidationStarRating : null,
          onChanged: state.isSaving ? null : state.setStarRating,
        ),
      ];

  // ── Step 2: location ─────────────────────────────────────────────────────

  List<Widget> _location(BuildContext context, AppLocalizations l10n) {
    final catalogue = state.catalogue;
    final label = state.locationLabel;
    return [
      if (label != null) ...[
        _summaryRow(context, l10n.partnerWizardLocationSelected, label,
            key: const Key('wizard-location-path')),
        const SizedBox(height: AppSpacing.md),
      ],
      DropdownButtonFormField<int>(
        key: const Key('wizard-country'),
        initialValue: catalogue.countryId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.partnerPropertyLocationCountry,
          prefixIcon: const Icon(Icons.public_rounded),
        ),
        items: [
          for (final option in catalogue.countryOptions)
            DropdownMenuItem(value: option.id, child: Text(option.name)),
        ],
        onChanged: state.isSaving ? null : catalogue.selectCountry,
      ),
      const SizedBox(height: AppSpacing.md),
      DropdownButtonFormField<int>(
        key: const Key('wizard-province'),
        initialValue: catalogue.provinceId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.partnerPropertyLocationProvince,
          prefixIcon: const Icon(Icons.map_outlined),
          errorText: propertyFieldMessage(
              state.failure, PropertyFields.administrativeUnitId),
        ),
        items: [
          for (final option in catalogue.provinceOptions)
            DropdownMenuItem(value: option.id, child: Text(option.name)),
        ],
        onChanged: state.isSaving ? null : catalogue.selectProvince,
      ),
      const SizedBox(height: AppSpacing.md),
      DropdownButtonFormField<int>(
        key: const Key('wizard-area'),
        initialValue: catalogue.areaId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.partnerPropertyLocationArea,
          prefixIcon: const Icon(Icons.location_city_outlined),
        ),
        items: [
          for (final option in catalogue.areaOptions)
            DropdownMenuItem(value: option.id, child: Text(option.name)),
        ],
        onChanged: state.isSaving ? null : catalogue.selectArea,
      ),
      if (catalogue.isLoadingChildren) ...[
        const SizedBox(height: AppSpacing.sm),
        const LinearProgressIndicator(),
      ],
      const SizedBox(height: AppSpacing.md),
      _field(
        fieldKey: 'wizard-address',
        controller: controllers.address,
        label: l10n.partnerPropertyFieldAddress,
        icon: Icons.place_outlined,
        field: PropertyFields.address,
        onChanged: (value) => state.setText(() => state.address = value),
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
              fieldKey: 'wizard-latitude',
              controller: controllers.latitude,
              label: l10n.partnerPropertyFieldLatitude,
              icon: Icons.swap_vert_rounded,
              field: PropertyFields.latitude,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              onChanged: (value) => state.setText(() => state.latitude = value),
              validator: (value) =>
                  PropertyWizardState.isValidCoordinate(value ?? '', 90)
                      ? null
                      : l10n.partnerPropertyValidationLatitude,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _field(
              fieldKey: 'wizard-longitude',
              controller: controllers.longitude,
              label: l10n.partnerPropertyFieldLongitude,
              icon: Icons.swap_horiz_rounded,
              field: PropertyFields.longitude,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              onChanged: (value) =>
                  state.setText(() => state.longitude = value),
              validator: (value) =>
                  PropertyWizardState.isValidCoordinate(value ?? '', 180)
                      ? null
                      : l10n.partnerPropertyValidationLongitude,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(l10n.partnerPropertyCoordinatesHelp,
          style: Theme.of(context).textTheme.bodySmall),
    ];
  }

  // ── Step 3: contact ──────────────────────────────────────────────────────

  List<Widget> _contact(BuildContext context, AppLocalizations l10n) => [
        _field(
          fieldKey: 'wizard-phone',
          controller: controllers.phone,
          label: l10n.partnerPropertyFieldPhone,
          icon: Icons.phone_outlined,
          field: PropertyFields.phone,
          keyboardType: TextInputType.phone,
          onChanged: (value) => state.setText(() => state.phone = value),
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          fieldKey: 'wizard-email',
          controller: controllers.email,
          label: l10n.partnerPropertyFieldEmail,
          icon: Icons.mail_outline_rounded,
          field: PropertyFields.email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => state.setText(() => state.email = value),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return null;
            return PropertyWizardState.emailPattern.hasMatch(text)
                ? null
                : l10n.partnerPropertyValidationEmail;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          fieldKey: 'wizard-website',
          controller: controllers.website,
          label: l10n.partnerPropertyFieldWebsite,
          icon: Icons.public_outlined,
          field: PropertyFields.website,
          keyboardType: TextInputType.url,
          onChanged: (value) => state.setText(() => state.website = value),
        ),
      ];

  // ── Step 4: amenities ────────────────────────────────────────────────────

  List<Widget> _amenities(BuildContext context, AppLocalizations l10n) {
    final query = controllers.amenitySearch.text.trim().toLowerCase();
    final groups = <String, List<PropertyAmenityOption>>{};
    for (final entry in state.catalogue.amenityGroups.entries) {
      final matches = entry.value
          .where((amenity) =>
              query.isEmpty || amenity.name.toLowerCase().contains(query))
          .toList();
      if (matches.isNotEmpty) groups[entry.key] = matches;
    }
    return [
      TextField(
        key: const Key('wizard-amenity-search'),
        controller: controllers.amenitySearch,
        decoration: InputDecoration(
          labelText: l10n.partnerWizardAmenitiesSearch,
          prefixIcon: const Icon(Icons.search_rounded),
        ),
        onChanged: (_) => state.setText(() {}),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        l10n.partnerPropertyAmenitiesSelected(state.amenityIds.length),
        key: const Key('wizard-amenities-count'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      if (groups.isEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.partnerWizardAmenitiesEmpty,
            key: const Key('wizard-amenities-empty'),
            style: Theme.of(context).textTheme.bodySmall),
      ],
      for (final entry in groups.entries) ...[
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final amenity in entry.value)
              FilterChip(
                key: Key('wizard-amenity-${amenity.id}'),
                label: Text(amenity.name),
                selected: state.amenityIds.contains(amenity.id),
                onSelected: state.isSaving
                    ? null
                    : (_) => state.toggleAmenity(amenity.id),
              ),
          ],
        ),
      ],
    ];
  }

  // ── Step 5: details and policies ─────────────────────────────────────────

  List<Widget> _policies(BuildContext context, AppLocalizations l10n) => [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                fieldKey: 'wizard-check-in',
                controller: controllers.checkIn,
                label: l10n.partnerPropertyFieldCheckIn,
                icon: Icons.login_rounded,
                field: PropertyFields.checkIn,
                onChanged: (value) =>
                    state.setText(() => state.checkIn = value),
                validator: (value) => PropertyWizardState.timePattern
                        .hasMatch((value ?? '').trim())
                    ? null
                    : l10n.partnerPropertyValidationTime,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _field(
                fieldKey: 'wizard-check-out',
                controller: controllers.checkOut,
                label: l10n.partnerPropertyFieldCheckOut,
                icon: Icons.logout_rounded,
                field: PropertyFields.checkOut,
                onChanged: (value) =>
                    state.setText(() => state.checkOut = value),
                validator: (value) => PropertyWizardState.timePattern
                        .hasMatch((value ?? '').trim())
                    ? null
                    : l10n.partnerPropertyValidationTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          fieldKey: 'wizard-children-policy',
          controller: controllers.childrenPolicy,
          label: l10n.partnerPropertyFieldChildrenPolicy,
          icon: Icons.child_care_outlined,
          field: 'childrenPolicy',
          maxLines: 2,
          onChanged: (value) =>
              state.setText(() => state.childrenPolicy = value),
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          fieldKey: 'wizard-pet-policy',
          controller: controllers.petPolicy,
          label: l10n.partnerPropertyFieldPetPolicy,
          icon: Icons.pets_outlined,
          field: 'petPolicy',
          maxLines: 2,
          onChanged: (value) => state.setText(() => state.petPolicy = value),
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          fieldKey: 'wizard-smoking-policy',
          controller: controllers.smokingPolicy,
          label: l10n.partnerPropertyFieldSmokingPolicy,
          icon: Icons.smoke_free_rounded,
          field: 'smokingPolicy',
          maxLines: 2,
          onChanged: (value) =>
              state.setText(() => state.smokingPolicy = value),
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          fieldKey: 'wizard-cancellation-policy',
          controller: controllers.cancellationPolicy,
          label: l10n.partnerPropertyFieldCancellationPolicy,
          icon: Icons.event_busy_outlined,
          field: 'cancellationPolicy',
          maxLines: 2,
          onChanged: (value) =>
              state.setText(() => state.cancellationPolicy = value),
        ),
        _toggle(
          toggleKey: 'wizard-free-cancellation',
          value: state.freeCancellation,
          label: l10n.partnerPropertyFreeCancellation,
          onChanged: state.isSaving
              ? null
              : (value) => state.setFlag(() => state.freeCancellation = value),
        ),
        _toggle(
          toggleKey: 'wizard-parking-available',
          value: state.parkingAvailable,
          label: l10n.partnerPropertyParkingAvailable,
          onChanged: state.isSaving
              ? null
              : (value) => state.setFlag(() {
                    state.parkingAvailable = value;
                    if (!value) state.parkingFree = false;
                  }),
        ),
        if (state.parkingAvailable) ...[
          _toggle(
            toggleKey: 'wizard-parking-free',
            value: state.parkingFree,
            label: l10n.partnerPropertyParkingFree,
            onChanged: state.isSaving
                ? null
                : (value) => state.setFlag(() => state.parkingFree = value),
          ),
          _field(
            fieldKey: 'wizard-parking-description',
            controller: controllers.parkingDescription,
            label: l10n.partnerPropertyFieldParking,
            icon: Icons.local_parking_outlined,
            field: 'parkingDescription',
            maxLines: 2,
            onChanged: (value) =>
                state.setText(() => state.parkingDescription = value),
          ),
        ],
        _toggle(
          toggleKey: 'wizard-wifi-available',
          value: state.wifiAvailable,
          label: l10n.partnerPropertyWifiAvailable,
          onChanged: state.isSaving
              ? null
              : (value) => state.setFlag(() {
                    state.wifiAvailable = value;
                    if (!value) state.wifiFree = false;
                  }),
        ),
        if (state.wifiAvailable) ...[
          _toggle(
            toggleKey: 'wizard-wifi-free',
            value: state.wifiFree,
            label: l10n.partnerPropertyWifiFree,
            onChanged: state.isSaving
                ? null
                : (value) => state.setFlag(() => state.wifiFree = value),
          ),
          _field(
            fieldKey: 'wizard-internet-description',
            controller: controllers.internetDescription,
            label: l10n.partnerPropertyFieldWifi,
            icon: Icons.wifi_rounded,
            field: 'internetDescription',
            maxLines: 2,
            onChanged: (value) =>
                state.setText(() => state.internetDescription = value),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _field(
          fieldKey: 'wizard-languages',
          controller: controllers.languages,
          label: l10n.partnerPropertyFieldLanguages,
          icon: Icons.translate_rounded,
          field: 'languages',
          helperText: l10n.partnerPropertyListHelp,
          onChanged: (value) => state.setText(() => state.languages = value),
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          fieldKey: 'wizard-payment-methods',
          controller: controllers.paymentMethods,
          label: l10n.partnerPropertyFieldPaymentMethods,
          icon: Icons.payments_outlined,
          field: 'paymentMethods',
          helperText: l10n.partnerPropertyListHelp,
          onChanged: (value) =>
              state.setText(() => state.paymentMethods = value),
        ),
      ];

  // ── Step 6: review ───────────────────────────────────────────────────────

  List<Widget> _review(BuildContext context, AppLocalizations l10n) {
    final notSet = l10n.partnerPropertyNotSet;
    final selectedAmenities = state.catalogue.amenityOptions
        .where((amenity) => state.amenityIds.contains(amenity.id))
        .map((amenity) => amenity.name)
        .toList();
    final subcategory = state.catalogue
        .subcategoryOptions(state.categoryId)
        .where((option) => option.id == state.subcategoryId)
        .map((option) => option.name)
        .join();
    final category = state.catalogue.categoryOptions
        .where((option) => option.id == state.categoryId)
        .map((option) => option.name)
        .join();

    return [
      _reviewSection(
        context,
        l10n,
        step: PropertyWizardStep.basics,
        rows: [
          (l10n.partnerPropertyFieldName, state.name.trim()),
          (l10n.partnerPropertyFieldCategory, category),
          (l10n.partnerPropertyFieldSubcategory, subcategory),
          (
            l10n.partnerPropertyFieldStarRating,
            state.starRating?.toString() ?? ''
          ),
        ],
        notSet: notSet,
      ),
      _reviewSection(
        context,
        l10n,
        step: PropertyWizardStep.location,
        rows: [
          (l10n.partnerWizardLocationSelected, state.locationLabel ?? ''),
          (l10n.partnerPropertyFieldAddress, state.address.trim()),
          (
            l10n.partnerPropertyFieldCoordinates,
            [state.latitude.trim(), state.longitude.trim()]
                        .where((value) => value.isNotEmpty)
                        .length ==
                    2
                ? '${state.latitude.trim()}, ${state.longitude.trim()}'
                : ''
          ),
        ],
        notSet: notSet,
      ),
      _reviewSection(
        context,
        l10n,
        step: PropertyWizardStep.contact,
        rows: [
          (l10n.partnerPropertyFieldPhone, state.phone.trim()),
          (l10n.partnerPropertyFieldEmail, state.email.trim()),
          (l10n.partnerPropertyFieldWebsite, state.website.trim()),
        ],
        notSet: notSet,
      ),
      _reviewSection(
        context,
        l10n,
        step: PropertyWizardStep.amenities,
        rows: [
          (
            l10n.partnerPropertyFieldAmenities,
            selectedAmenities.isEmpty ? '' : selectedAmenities.join(', ')
          ),
        ],
        notSet: notSet,
      ),
      _reviewSection(
        context,
        l10n,
        step: PropertyWizardStep.policies,
        rows: [
          (l10n.partnerPropertyFieldCheckIn, state.checkIn.trim()),
          (l10n.partnerPropertyFieldCheckOut, state.checkOut.trim()),
          (
            l10n.partnerPropertyFieldChildrenPolicy,
            state.childrenPolicy.trim()
          ),
          (l10n.partnerPropertyFieldPetPolicy, state.petPolicy.trim()),
          (l10n.partnerPropertyFieldSmokingPolicy, state.smokingPolicy.trim()),
          (
            l10n.partnerPropertyFieldCancellationPolicy,
            state.cancellationPolicy.trim()
          ),
          (l10n.partnerPropertyFieldLanguages, state.languages.trim()),
          (
            l10n.partnerPropertyFieldPaymentMethods,
            state.paymentMethods.trim()
          ),
        ],
        notSet: notSet,
      ),
    ];
  }

  Widget _reviewSection(
    BuildContext context,
    AppLocalizations l10n, {
    required PropertyWizardStep step,
    required List<(String, String)> rows,
    required String notSet,
  }) {
    final theme = Theme.of(context);
    final complete = state.isStepComplete(step);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                complete
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                size: 18,
                color: complete ? AppColors.ocean : AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  stepLabel(l10n, step),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              // Status is never colour alone: the word is there too.
              Text(
                complete
                    ? l10n.partnerWizardReviewComplete
                    : l10n.partnerWizardReviewIncomplete,
                key: Key('wizard-review-status-${step.name}'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                key: Key('wizard-review-fix-${step.name}'),
                onPressed: () => onJump(step),
                child: Text(l10n.partnerWizardReviewFix),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(row.$1, style: theme.textTheme.bodySmall),
                  ),
                  Expanded(
                    child: Text(
                      row.$2.isEmpty ? notSet : row.$2,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Shared pieces ────────────────────────────────────────────────────────

  Widget _summaryRow(BuildContext context, String label, String value,
      {Key? key}) {
    final theme = Theme.of(context);
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _field({
    required String fieldKey,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String field,
    required ValueChanged<String> onChanged,
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
        enabled: !state.isSaving,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          helperText: helperText,
          helperMaxLines: 2,
          // The backend's own wording for the field it refused, in English,
          // always beside the localized summary rather than instead of it.
          errorText: propertyFieldMessage(state.failure, field),
        ),
      );

  /// A plain Switch with its label rather than a SwitchListTile: the card this
  /// form sits in paints its own background, which would hide a ListTile's ink.
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
}

/// The localized name of a step — used by the rail, the heading and the review.
String stepLabel(AppLocalizations l10n, PropertyWizardStep step) =>
    switch (step) {
      PropertyWizardStep.businessProfile =>
        l10n.partnerWizardStepBusinessProfile,
      PropertyWizardStep.basics => l10n.partnerWizardStepBasics,
      PropertyWizardStep.location => l10n.partnerWizardStepLocation,
      PropertyWizardStep.contact => l10n.partnerWizardStepContact,
      PropertyWizardStep.amenities => l10n.partnerWizardStepAmenities,
      PropertyWizardStep.policies => l10n.partnerWizardStepPolicies,
      PropertyWizardStep.review => l10n.partnerWizardStepReview,
    };

String stepIntro(AppLocalizations l10n, PropertyWizardStep step) =>
    switch (step) {
      PropertyWizardStep.businessProfile => l10n.partnerWizardProfileIntro,
      PropertyWizardStep.basics => l10n.partnerWizardBasicsIntro,
      PropertyWizardStep.location => l10n.partnerWizardLocationIntro,
      PropertyWizardStep.contact => l10n.partnerWizardContactIntro,
      PropertyWizardStep.amenities => l10n.partnerWizardAmenitiesIntro,
      PropertyWizardStep.policies => l10n.partnerWizardPoliciesIntro,
      PropertyWizardStep.review => l10n.partnerWizardReviewIntro,
    };
