import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../core/mock/mock_data.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../places/real_recently_viewed_screen.dart';
import '../rewards/rewards_screen.dart';
import '../reviews/reviews_screen.dart';
import '../wallet/travel_wallet_screen.dart';
import 'notifications_screen.dart';
import 'real_customer_profile_screen.dart';
import 'saved_places_screen.dart';
import 'settings_screen.dart';
import 'static_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDemo = app.demoMode;
    final unreadNotifications = isDemo ? app.unreadNotificationCount : 0;
    // Real Mode: load the signed-in identity + travel profile exactly once.
    // Only kick off when neither loaded, in-flight, nor already errored — so a
    // failed load is NOT retried on every rebuild (no request storm), and Demo
    // Mode never touches the network.
    final needIdentity = !isDemo &&
        !app.realIdentityLoaded &&
        !app.realIdentityLoading &&
        app.realIdentityError == null;
    final needProfile = !isDemo &&
        !app.realProfileLoaded &&
        !app.realProfileLoading &&
        app.realProfileError == null;
    if (needIdentity || needProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (needIdentity) app.loadRealAccountIdentity();
        if (needProfile) app.loadRealCustomerProfile();
      });
    }
    final identity = app.realIdentity;
    return ListView(
      key: const PageStorageKey('profile-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.profileTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Semantics(
              button: true,
              label: l10n.profileSettingsSemantic,
              child: IconButton.filledTonal(
                tooltip: l10n.profileSettingsSemantic,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                icon: const Icon(Icons.settings_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OceanGlassCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.ocean.withValues(alpha: .12),
                child: Icon(
                  isDemo ? Icons.flight_takeoff_rounded : Icons.person_rounded,
                  color: AppColors.ocean,
                  size: AppIconSizes.xl,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isDemo
                    ? l10n.profileDemoName
                    : ((identity?.fullName ?? '').trim().isNotEmpty
                        ? identity!.fullName
                        : l10n.profileRealAccountTitle),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                isDemo
                    ? (app.email ?? MockData.demoEmail)
                    : ((identity?.email ?? '').trim().isNotEmpty
                        ? identity!.email
                        : (app.email ?? l10n.profileEmailMissing)),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  OceanStatusPill(
                    label: isDemo
                        ? l10n.profileDemoStatus
                        : l10n.profileRealStatus,
                    icon: isDemo
                        ? Icons.science_rounded
                        : Icons.cloud_done_rounded,
                    color: isDemo ? AppColors.ocean : AppColors.success,
                  ),
                  if (!isDemo && (identity?.role ?? '').trim().isNotEmpty)
                    OceanStatusPill(
                      label: identity!.role,
                      icon: Icons.badge_rounded,
                      color: AppColors.ocean,
                      semanticLabel: l10n.profileRoleSemantic(identity.role),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OceanGlassCard(
          child: Row(
            children: [
              _ProfileStat(
                icon: Icons.work_rounded,
                value: isDemo ? '${app.trips.length}' : '-',
                label: l10n.profileTripsStat,
              ),
              const _StatDivider(),
              _ProfileStat(
                icon: Icons.bookmark_rounded,
                value: isDemo ? '${app.savedPlaceCount}' : '-',
                label: l10n.profileSavedPlacesStat,
              ),
              const _StatDivider(),
              _ProfileStat(
                icon: Icons.notifications_rounded,
                value: isDemo ? '$unreadNotifications' : '-',
                label: l10n.profileNotificationsStat,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.profileTravelPreferences,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isDemo)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OceanStatusPill(
                label: l10n.profileDemoPreferences.split(', ')[0],
                icon: Icons.restaurant_rounded,
                color: AppColors.coral,
              ),
              OceanStatusPill(
                label: l10n.profileDemoPreferences.split(', ')[1],
                icon: Icons.museum_rounded,
                color: AppColors.turquoise600,
              ),
              OceanStatusPill(
                label: l10n.profileDemoPreferences.split(', ')[2],
                icon: Icons.terrain_rounded,
                color: AppColors.ocean,
              ),
            ],
          )
        else
          _RealPreferencesSummary(profile: app.realProfile),
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(l10n.profileAccountSection),
        _ProfileNavCard(
          icon: Icons.settings_rounded,
          title: l10n.profileSettings,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        _ProfileNavCard(
          icon: Icons.bookmark_rounded,
          title: l10n.profileSavedPlaces,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavedPlacesScreen()),
          ),
        ),
        // UI32: real customer profile edit lives on the backend only. Shown in
        // Real Mode; Demo Mode is byte-identical (no extra card).
        if (!isDemo)
          _ProfileNavCard(
            key: const Key('profile-edit'),
            icon: Icons.manage_accounts_rounded,
            title: l10n.profileEditTitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RealCustomerProfileScreen(),
              ),
            ),
          ),
        // UI31: real recently-viewed lives on the backend only. Shown in Real
        // Mode; Demo Mode is byte-identical (no extra card).
        if (!isDemo)
          _ProfileNavCard(
            key: const Key('profile-recently-viewed'),
            icon: Icons.history_rounded,
            title: l10n.recentlyViewedTitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RealRecentlyViewedScreen(),
              ),
            ),
          ),
        _ProfileNavCard(
          icon: Icons.notifications_rounded,
          title: l10n.profileNotifications,
          badgeCount: unreadNotifications,
          badgeSemanticLabel:
              l10n.profileNotificationsUnreadBadge(unreadNotifications),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        _ProfileNavCard(
          icon: Icons.hotel_rounded,
          title: l10n.myBookingsTitle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
          ),
        ),
        _ProfileNavCard(
          key: const Key('profile-my-reviews'),
          icon: Icons.rate_review_rounded,
          title: l10n.myReviewsTitle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
          ),
        ),
        _ProfileNavCard(
          key: const Key('profile-rewards'),
          icon: Icons.redeem_rounded,
          title: l10n.rewardsTitle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RewardsHubScreen()),
          ),
        ),
        _ProfileNavCard(
          key: const Key('profile-wallet'),
          icon: Icons.wallet_rounded,
          title: l10n.travelWalletTitle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TravelWalletScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SectionHeader(l10n.profileLegalSection),
        _ProfileNavCard(
          icon: Icons.privacy_tip_rounded,
          title: l10n.profilePrivacyPolicy,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StaticPage(title: l10n.profilePrivacyPolicy),
            ),
          ),
        ),
        _ProfileNavCard(
          icon: Icons.gavel_rounded,
          title: l10n.profileTerms,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StaticPage(title: l10n.profileTerms),
            ),
          ),
        ),
        _ProfileNavCard(
          icon: Icons.info_outline_rounded,
          title: l10n.profileAboutApp,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StaticPage(title: l10n.profileAboutApp),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OceanSecondaryButton(
          label: l10n.profileLogout,
          icon: Icons.logout_rounded,
          semanticLabel: l10n.profileLogoutSemantic,
          onPressed: () => _confirmLogout(context, app),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            l10n.profileVersion,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, AppState app) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileLogoutConfirmTitle),
        content: Text(l10n.profileLogoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.profileConfirmLogout),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await app.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.ocean, size: AppIconSizes.md),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ocean,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 58,
        color: AppColors.divider,
      );
}

class _ProfileNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int badgeCount;
  final String? badgeSemanticLabel;
  final VoidCallback onTap;

  const _ProfileNavCard({
    super.key,
    required this.icon,
    required this.title,
    this.badgeCount = 0,
    this.badgeSemanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: OceanGlassCard(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                decoration: BoxDecoration(
                  color: AppColors.ocean.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child:
                    Icon(icon, color: AppColors.ocean, size: AppIconSizes.sm),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                OceanStatusPill(
                  label: '$badgeCount',
                  icon: Icons.mark_email_unread_rounded,
                  color: AppColors.coral,
                  semanticLabel: badgeSemanticLabel,
                ),
              ],
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0,
          ),
        ),
      );
}

/// Real Mode read-only preview of the customer's travel preferences
/// (`GET /api/me/profile`). Editing lives on [RealCustomerProfileScreen] via the
/// dedicated nav card — this only surfaces the backend-provided values. Nothing
/// is fabricated: an unloaded profile shows a neutral prompt.
class _RealPreferencesSummary extends StatelessWidget {
  final CustomerProfileRecord? profile;

  const _RealPreferencesSummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = profile;
    final pills = <Widget>[
      if (p != null && (p.preferredLanguage ?? '').trim().isNotEmpty)
        OceanStatusPill(
          label: p.preferredLanguage!.trim(),
          icon: Icons.translate_rounded,
          color: AppColors.ocean,
        ),
      if (p != null && (p.preferredCurrency ?? '').trim().isNotEmpty)
        OceanStatusPill(
          label: p.preferredCurrency!.trim(),
          icon: Icons.payments_rounded,
          color: AppColors.turquoise600,
        ),
      if (p != null && (p.dietaryPreference ?? '').trim().isNotEmpty)
        OceanStatusPill(
          label: p.dietaryPreference!.trim(),
          icon: Icons.restaurant_rounded,
          color: AppColors.coral,
        ),
      if (p != null && (p.travelStyle ?? '').trim().isNotEmpty)
        OceanStatusPill(
          label: p.travelStyle!.trim(),
          icon: Icons.explore_rounded,
          color: AppColors.ocean,
        ),
    ];
    return OceanGlassCard(
      key: const Key('profile-real-preferences'),
      child: pills.isEmpty
          ? Text(
              l10n.profileEditEmptyPreferences,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: pills,
            ),
    );
  }
}
