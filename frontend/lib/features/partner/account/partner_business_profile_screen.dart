import 'package:flutter/material.dart';

import '../../../core/auth/auth_error.dart';
import '../../../core/auth/auth_messages.dart';
import '../../../core/partner/partner_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../../auth/auth_page_scaffold.dart';
import 'partner_business_profile_state.dart';

/// The Partner business profile form — `POST /api/partner/profile`, and
/// optionally `/submit`.
///
/// Every field here is one the backend's `PartnerProfileRequest` accepts; none is
/// invented. Saving keeps the profile a DRAFT the Partner can still edit;
/// submitting hands it to an administrator, which is the only path to approval.
class PartnerBusinessProfileScreen extends StatefulWidget {
  final PartnerBusinessProfileState state;

  const PartnerBusinessProfileScreen({super.key, required this.state});

  @override
  State<PartnerBusinessProfileScreen> createState() =>
      _PartnerBusinessProfileScreenState();
}

class _PartnerBusinessProfileScreenState
    extends State<PartnerBusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PartnerProfile? _existing = widget.state.profile;

  late final _businessName =
      TextEditingController(text: _existing?.businessName ?? '');
  late final _representative =
      TextEditingController(text: _existing?.representativeName ?? '');
  late final _phone = TextEditingController(text: _existing?.phone ?? '');
  late final _email = TextEditingController(text: _existing?.email ?? '');
  late final _address = TextEditingController(text: _existing?.address ?? '');
  late final _taxCode = TextEditingController(text: _existing?.taxCode ?? '');
  late final _website = TextEditingController(text: _existing?.website ?? '');

  late PartnerBusinessType _businessType =
      _existing?.businessTypeValue == PartnerBusinessType.unknown
          ? PartnerBusinessType.hotel
          : _existing?.businessTypeValue ?? PartnerBusinessType.hotel;

  AuthFailure? _failure;

  @override
  void dispose() {
    _businessName.dispose();
    _representative.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _taxCode.dispose();
    _website.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final saving = widget.state.saving;
        final failure = _failure;
        return AuthPageScaffold(
          title: l10n.partnerBusinessHeading,
          heading: l10n.partnerBusinessHeading,
          subtitle: l10n.partnerBusinessStatusDraftBody,
          icon: Icons.business_rounded,
          onBack: saving ? null : () => Navigator.maybePop(context),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(
                    key: 'business-name',
                    controller: _businessName,
                    label: l10n.partnerBusinessFieldName,
                    icon: Icons.storefront_rounded,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<PartnerBusinessType>(
                    key: const Key('business-type'),
                    initialValue: _businessType,
                    decoration: InputDecoration(
                      labelText: l10n.partnerBusinessFieldType,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: [
                      for (final type in PartnerBusinessType.selectable)
                        DropdownMenuItem(
                          value: type,
                          child: Text(partnerBusinessTypeLabel(l10n, type)),
                        ),
                    ],
                    onChanged: saving
                        ? null
                        : (value) => setState(
                            () => _businessType = value ?? _businessType),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    key: 'business-representative',
                    controller: _representative,
                    label: l10n.partnerBusinessFieldRepresentative,
                    icon: Icons.person_outline_rounded,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    key: 'business-phone',
                    controller: _phone,
                    label: l10n.partnerBusinessFieldPhone,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    key: 'business-email',
                    controller: _email,
                    label: l10n.partnerBusinessFieldEmail,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    l10n: l10n,
                    validator: (value) => _emailValidator(l10n, value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    key: 'business-address',
                    controller: _address,
                    label: l10n.partnerBusinessFieldAddress,
                    icon: Icons.place_outlined,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    key: 'business-tax-code',
                    controller: _taxCode,
                    label: l10n.partnerBusinessOptionalSuffix(
                        l10n.partnerBusinessFieldTaxCode),
                    icon: Icons.receipt_long_outlined,
                    l10n: l10n,
                    optional: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(
                    key: 'business-website',
                    controller: _website,
                    label: l10n.partnerBusinessOptionalSuffix(
                        l10n.partnerBusinessFieldWebsite),
                    icon: Icons.public_outlined,
                    l10n: l10n,
                    optional: true,
                  ),
                ],
              ),
            ),
            if (failure != null) ...[
              const SizedBox(height: AppSpacing.md),
              AuthNotice(
                key: const Key('business-profile-error'),
                icon: Icons.error_outline_rounded,
                message: failure.serverMessage ??
                    authFailureMessage(l10n, failure),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AuthSubmitButton(
              buttonKey: const Key('business-profile-save'),
              label: l10n.partnerBusinessSaveAction,
              icon: Icons.save_outlined,
              busy: saving,
              onPressed: () => _save(submit: false),
            ),
            const SizedBox(height: AppSpacing.sm),
            OceanSecondaryButton(
              key: const Key('business-profile-submit'),
              label: l10n.partnerBusinessSubmitAction,
              icon: Icons.send_rounded,
              onPressed: saving ? null : () => _save(submit: true),
            ),
          ],
        );
      },
    );
  }

  Widget _field({
    required String key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppLocalizations l10n,
    TextInputType? keyboardType,
    bool optional = false,
    FormFieldValidator<String>? validator,
  }) =>
      TextFormField(
        key: Key(key),
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        validator: validator ??
            (optional
                ? null
                : (value) => (value?.trim() ?? '').isEmpty
                    ? l10n.partnerBusinessValidationRequired
                    : null),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      );

  String? _emailValidator(AppLocalizations l10n, String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return l10n.partnerBusinessValidationRequired;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : l10n.authValidationEmail;
  }

  /// Saves, and — when asked — submits for review in the same action. The
  /// submission only runs if the save succeeded, so a refused edit never reports
  /// a submission that did not happen.
  Future<void> _save({required bool submit}) async {
    if (widget.state.saving) return;
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final saved = await widget.state.save(PartnerProfileDraft(
      businessName: _businessName.text,
      businessType: _businessType,
      representativeName: _representative.text,
      phone: _phone.text,
      email: _email.text,
      address: _address.text,
      taxCode: _taxCode.text,
      website: _website.text,
    ));
    if (!mounted) return;
    if (!saved.success) {
      setState(() => _failure = saved.failure);
      return;
    }
    if (!submit) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.partnerBusinessSavedMessage)),
      );
      navigator.maybePop();
      return;
    }

    final submitted = await widget.state.submit();
    if (!mounted) return;
    if (!submitted.success) {
      setState(() => _failure = submitted.failure);
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.partnerBusinessSubmittedMessage)),
    );
    navigator.maybePop();
  }
}

/// The localized name of a business type.
String partnerBusinessTypeLabel(
  AppLocalizations l10n,
  PartnerBusinessType type,
) =>
    switch (type) {
      PartnerBusinessType.hotel => l10n.partnerBusinessTypeHotel,
      PartnerBusinessType.restaurant => l10n.partnerBusinessTypeRestaurant,
      PartnerBusinessType.cafe => l10n.partnerBusinessTypeCafe,
      PartnerBusinessType.tourOperator => l10n.partnerBusinessTypeTourOperator,
      PartnerBusinessType.transport => l10n.partnerBusinessTypeTransport,
      PartnerBusinessType.other => l10n.partnerBusinessTypeOther,
      PartnerBusinessType.unknown => l10n.partnerBusinessTypeUnknown,
    };
