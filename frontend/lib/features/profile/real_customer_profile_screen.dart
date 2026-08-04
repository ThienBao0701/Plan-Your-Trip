import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';

/// UI32 — Real Mode customer profile (`GET /api/me`, `GET`/`PUT /api/me/profile`).
/// Shows the signed-in identity and an editable travel profile. The backend PUT
/// is full-replace, so save resends every field from the loaded record; the raw
/// passport number is write-only (echoed back only masked), so its field is empty
/// by default with an explicit warning. Nothing is fabricated — a 401 never logs
/// the user out.
class RealCustomerProfileScreen extends StatefulWidget {
  const RealCustomerProfileScreen({super.key});

  @override
  State<RealCustomerProfileScreen> createState() =>
      _RealCustomerProfileScreenState();
}

class _RealCustomerProfileScreenState extends State<RealCustomerProfileScreen> {
  final _avatarUrl = TextEditingController();
  final _language = TextEditingController();
  final _currency = TextEditingController();
  final _paymentMethod = TextEditingController();
  final _nationality = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _accessibility = TextEditingController();
  final _dietary = TextEditingController();
  final _travelStyle = TextEditingController();
  final _passport = TextEditingController();
  bool _marketing = false;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppScope.of(context);
      app.loadRealAccountIdentity();
      app.loadRealCustomerProfile();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _avatarUrl,
      _language,
      _currency,
      _paymentMethod,
      _nationality,
      _emergencyName,
      _emergencyPhone,
      _accessibility,
      _dietary,
      _travelStyle,
      _passport,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedIfNeeded(CustomerProfileRecord p) {
    if (_seeded) return;
    _seeded = true;
    _avatarUrl.text = p.avatarUrl ?? '';
    _language.text = p.preferredLanguage ?? '';
    _currency.text = p.preferredCurrency ?? '';
    _paymentMethod.text = p.preferredPaymentMethod ?? '';
    _nationality.text = p.nationality ?? '';
    _emergencyName.text = p.emergencyContactName ?? '';
    _emergencyPhone.text = p.emergencyContactPhone ?? '';
    _accessibility.text = p.accessibilityNeeds ?? '';
    _dietary.text = p.dietaryPreference ?? '';
    _travelStyle.text = p.travelStyle ?? '';
    _marketing = p.marketingConsent;
  }

  String? _clean(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  void _reauth() {
    showOceanSessionExpiredSheet(
      context,
      onLogin: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      onReturnHome: () => Navigator.of(context).pop(),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(AppState app) async {
    final l10n = AppLocalizations.of(context)!;
    final update = CustomerProfileUpdate(
      avatarUrl: _clean(_avatarUrl),
      preferredLanguage: _clean(_language),
      preferredCurrency: _clean(_currency),
      preferredPaymentMethod: _clean(_paymentMethod),
      nationality: _clean(_nationality),
      passportNumber: _clean(_passport),
      emergencyContactName: _clean(_emergencyName),
      emergencyContactPhone: _clean(_emergencyPhone),
      accessibilityNeeds: _clean(_accessibility),
      travelStyle: _clean(_travelStyle),
      dietaryPreference: _clean(_dietary),
      marketingConsent: _marketing,
    );
    final outcome = await app.updateRealCustomerProfile(update);
    if (!mounted) return;
    switch (outcome) {
      case CustomerProfileOutcome.success:
        // The stored passport is now (re)masked; clear the write-only input.
        _passport.clear();
        _snack(l10n.profileEditSavedMessage);
      case CustomerProfileOutcome.sessionExpired:
        _reauth();
      case CustomerProfileOutcome.forbidden:
        _snack(l10n.profileEditForbiddenMessage);
      case CustomerProfileOutcome.network:
        _snack(l10n.profileEditNetworkMessage);
      case CustomerProfileOutcome.busy:
        break;
      default:
        _snack(l10n.profileEditSaveErrorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.profileEditTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    if (app.realProfileError == CustomerProfileOutcome.sessionExpired &&
        !app.realProfileLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('customer-profile-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realProfileLoading && !app.realProfileLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.profileEditLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                key: Key('customer-profile-loading'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.profileEditLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realProfileError == CustomerProfileOutcome.notFound &&
        !app.realProfileLoaded) {
      return _centered(
        OceanEmptyState(
          key: const Key('customer-profile-missing'),
          title: l10n.profileEditMissingMessage,
        ),
      );
    }
    if (app.realProfileError != null && !app.realProfileLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('customer-profile-error'),
          message: l10n.profileEditErrorMessage,
          onReload: () => app.loadRealCustomerProfile(refresh: true),
        ),
      );
    }
    final profile = app.realProfile;
    if (profile == null) {
      // Loaded flag not yet set and no error — brief transient before content.
      return _centered(const CircularProgressIndicator());
    }
    _seedIfNeeded(profile);
    return _content(context, app, l10n, profile);
  }

  Widget _content(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
    CustomerProfileRecord profile,
  ) {
    final identity = app.realIdentity;
    final masked = (profile.passportNumberMasked ?? '').trim();
    return RefreshIndicator(
      onRefresh: () => app.loadRealCustomerProfile(refresh: true),
      child: ListView(
        key: const Key('customer-profile-content'),
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
                // Identity summary (read-only, GET /api/me).
                OceanGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sectionText(l10n.profileEditIdentitySection),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        (identity?.fullName ?? '').trim().isNotEmpty
                            ? identity!.fullName
                            : l10n.profileRealAccountTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        (identity?.email ?? '').trim().isNotEmpty
                            ? identity!.email
                            : (app.email ?? l10n.profileEmailMissing),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if ((identity?.role ?? '').trim().isNotEmpty)
                            OceanStatusPill(
                              label: identity!.role,
                              icon: Icons.badge_rounded,
                              color: AppColors.ocean,
                              semanticLabel:
                                  l10n.profileRoleSemantic(identity.role),
                            ),
                          OceanStatusPill(
                            label: '${profile.completionPercentage}%',
                            icon: Icons.donut_large_rounded,
                            color: AppColors.success,
                            semanticLabel: l10n.profileCompletionSemantic(
                              profile.completionPercentage,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Preferences (editable, PUT /api/me/profile).
                Text(
                  _sectionText(l10n.profileEditPreferencesSection),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                _field(l10n.profileFieldLanguage, _language,
                    icon: Icons.translate_rounded),
                _field(l10n.profileFieldCurrency, _currency,
                    icon: Icons.payments_rounded),
                _field(l10n.profileFieldPaymentMethod, _paymentMethod,
                    icon: Icons.credit_card_rounded),
                _field(l10n.profileFieldDietaryPreference, _dietary,
                    icon: Icons.restaurant_rounded),
                _field(l10n.profileFieldTravelStyle, _travelStyle,
                    icon: Icons.explore_rounded),
                _field(l10n.profileFieldAvatar, _avatarUrl,
                    icon: Icons.image_rounded, keyboardType: TextInputType.url),
                SwitchListTile(
                  key: const Key('customer-profile-marketing'),
                  contentPadding: EdgeInsets.zero,
                  value: _marketing,
                  onChanged: (v) => setState(() => _marketing = v),
                  title: Text(l10n.profileEditMarketingLabel),
                ),
                const SizedBox(height: AppSpacing.md),
                // Contact & documents (editable).
                Text(
                  _sectionText(l10n.profileEditContactSection),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                _field(l10n.profileFieldNationality, _nationality,
                    icon: Icons.public_rounded),
                _field(l10n.profileFieldEmergencyName, _emergencyName,
                    icon: Icons.contact_emergency_rounded),
                _field(l10n.profileFieldEmergencyPhone, _emergencyPhone,
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone),
                _field(l10n.profileFieldAccessibility, _accessibility,
                    icon: Icons.accessible_rounded),
                _labelledField(
                  label: l10n.profileEditPassportLabel,
                  child: GlassTextField(
                    key: const Key('customer-profile-passport'),
                    controller: _passport,
                    hint: l10n.profileEditOptionalHint,
                    icon: Icons.badge_outlined,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xs,
                    bottom: AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: AppSpacing.md,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          masked.isNotEmpty
                              ? l10n.profileEditPassportWarning(masked)
                              : l10n.profileEditPassportHint,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OceanPrimaryButton(
                  key: const Key('customer-profile-save'),
                  label: l10n.profileEditSaveAction,
                  icon: Icons.save_rounded,
                  onPressed: app.realProfileSaving ? null : () => _save(app),
                ),
                if (app.realProfileSaving) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sectionText(String s) => s.toUpperCase();

  Widget _field(
    String label,
    TextEditingController controller, {
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return _labelledField(
      label: label,
      child: GlassTextField(
        controller: controller,
        hint: l10n.profileEditOptionalHint,
        icon: icon,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _labelledField({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xxs),
          child,
        ],
      ),
    );
  }

  Widget _centered(Widget child) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Center(child: child),
          ),
        ],
      );
}
