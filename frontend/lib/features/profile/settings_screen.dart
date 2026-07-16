import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/mock_data.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/forgot_password_screen.dart';
import 'static_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        title: Text(l10n.settingsTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              OceanContentConstraint(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionTitle(l10n.settingsLanguageRegion),
                    OceanGlassCard(
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.language_rounded,
                            title: l10n.settingsLanguage,
                            subtitle: _languageLabel(context, app),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _chooseLanguage(context, app),
                          ),
                          const Divider(),
                          _SettingsTile(
                            icon: Icons.attach_money_rounded,
                            title: l10n.settingsCurrency,
                            subtitle: 'VND',
                            trailing: const Icon(Icons.lock_outline_rounded),
                          ),
                          const Divider(),
                          _SettingsTile(
                            icon: Icons.schedule_rounded,
                            title: l10n.settingsTimeFormat,
                            subtitle: '24h',
                            trailing: const Icon(Icons.lock_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(l10n.settingsNotifications),
                    OceanGlassCard(
                      child: Column(
                        children: [
                          _SwitchTile(
                            icon: Icons.calendar_month_rounded,
                            title: l10n.settingsTripReminders,
                            subtitle: l10n.settingsLocalOnly,
                            value: app.tripRemindersEnabled,
                            onChanged: app.setTripRemindersEnabled,
                          ),
                          const Divider(),
                          _SwitchTile(
                            icon: Icons.hotel_rounded,
                            title: l10n.settingsBookingUpdates,
                            subtitle: l10n.settingsLocalOnly,
                            value: app.bookingUpdatesEnabled,
                            onChanged: app.setBookingUpdatesEnabled,
                          ),
                          const Divider(),
                          _SwitchTile(
                            icon: Icons.tips_and_updates_rounded,
                            title: l10n.settingsTravelTips,
                            subtitle: l10n.settingsLocalOnly,
                            value: app.travelTipsEnabled,
                            onChanged: app.setTravelTipsEnabled,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(l10n.settingsAppearance),
                    OceanGlassCard(
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.light_mode_rounded,
                            title: l10n.settingsTheme,
                            subtitle: l10n.settingsThemeLight,
                            trailing: const Icon(Icons.lock_outline_rounded),
                          ),
                          const Divider(),
                          _SwitchTile(
                            icon: Icons.motion_photos_off_rounded,
                            title: l10n.settingsReduceMotion,
                            subtitle: l10n.settingsStoredOnDevice,
                            value: app.reduceMotionEnabled,
                            onChanged: app.setReduceMotionEnabled,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionTitle(l10n.settingsAccountSecurity),
                    OceanGlassCard(
                      child: Column(
                        children: [
                          _SettingsTile(
                            icon: Icons.key_rounded,
                            title: l10n.settingsPasswordReset,
                            subtitle: l10n.settingsPasswordResetSubtitle,
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen(
                                  initialEmail: app.email ?? '',
                                ),
                              ),
                            ),
                          ),
                          const Divider(),
                          _SettingsTile(
                            icon: Icons.privacy_tip_rounded,
                            title: l10n.settingsPrivacy,
                            subtitle: l10n.profilePrivacyPolicy,
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StaticPage(
                                    title: l10n.profilePrivacyPolicy),
                              ),
                            ),
                          ),
                          const Divider(),
                          _SettingsTile(
                            icon: Icons.info_outline_rounded,
                            title: l10n.settingsAbout,
                            subtitle: l10n.profileAboutApp,
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StaticPage(title: l10n.profileAboutApp),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (app.demoMode) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(l10n.settingsDemoData),
                      OceanGlassCard(
                        child: _SettingsTile(
                          icon: Icons.restore_rounded,
                          title: l10n.settingsResetDemoData,
                          subtitle: l10n.settingsResetDemoSubtitle,
                          trailing: TextButton(
                            onPressed: () => _resetDemo(context, app),
                            child: Text(l10n.settingsReset),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Text(
                        app.demoMode
                            ? l10n.demoModeLabel
                            : l10n.settingsConnectedReal,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textTertiary),
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

  String _languageLabel(BuildContext context, AppState app) {
    final l10n = AppLocalizations.of(context)!;
    switch (app.localeOverride?.languageCode) {
      case 'en':
        return l10n.settingsLanguageEnglish;
      case 'vi':
        return l10n.settingsLanguageVietnamese;
      default:
        return l10n.settingsLanguageDevice;
    }
  }

  Future<void> _chooseLanguage(BuildContext context, AppState app) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => OceanGlassBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              label: l10n.settingsLanguageDevice,
              selected: app.localeOverride == null,
              onTap: () async {
                await app.setLocaleOverride(null);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
            ),
            _LanguageOption(
              label: l10n.settingsLanguageEnglish,
              selected: app.localeOverride?.languageCode == 'en',
              onTap: () async {
                await app.setLocaleOverride(const Locale('en'));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
            ),
            _LanguageOption(
              label: l10n.settingsLanguageVietnamese,
              selected: app.localeOverride?.languageCode == 'vi',
              onTap: () async {
                await app.setLocaleOverride(const Locale('vi'));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetDemo(BuildContext context, AppState app) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsResetDemoConfirmTitle),
        content: Text(l10n.settingsResetDemoConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.settingsReset),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await app.logout();
    await app.login(MockData.demoEmail, MockData.demoPassword);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.settingsDemoRestored)));
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 0, AppSpacing.sm),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              _SettingsIcon(icon),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              trailing,
            ],
          ),
        ),
      );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            _SettingsIcon(icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Semantics(
              toggled: value,
              label: title,
              child: Switch(
                value: value,
                activeThumbColor: AppColors.ocean,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      );
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;

  const _SettingsIcon(this.icon);

  @override
  Widget build(BuildContext context) => Container(
        width: AppSpacing.minTouchTarget,
        height: AppSpacing.minTouchTarget,
        decoration: BoxDecoration(
          color: AppColors.ocean.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Icon(icon, color: AppColors.ocean, size: AppIconSizes.sm),
      );
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: ListTile(
          minVerticalPadding: AppSpacing.sm,
          title: Text(label, style: Theme.of(context).textTheme.titleMedium),
          trailing: selected
              ? const Icon(Icons.check_circle_rounded, color: AppColors.ocean)
              : null,
          onTap: onTap,
        ),
      );
}
