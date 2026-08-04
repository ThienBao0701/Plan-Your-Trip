import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../expenses/expenses_screen.dart';
import 'real_gift_cards_view.dart';

class RewardsHubScreen extends StatelessWidget {
  const RewardsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final credit = app.travelCreditAccount;
    final loyalty = app.loyaltyAccount;
    final membership = app.membershipAccount;
    final claimedCoupons =
        app.coupons.where((coupon) => coupon.isClaimed).length;
    final usableCards =
        app.giftCards.where((card) => card.effectiveStatus.canRedeem).length;

    return _RewardsScaffold(
      title: l10n.rewardsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RewardsHero(
            title: l10n.rewardsTitle,
            subtitle: app.demoMode
                ? l10n.rewardsDemoSubtitle
                : l10n.rewardsRealUnavailableMessage,
          ),
          const SizedBox(height: AppSpacing.md),
          if (!app.demoMode) ...[
            OceanEmptyState(
              title: l10n.rewardsRealEmptyTitle,
              message: l10n.rewardsRealUnavailableMessage,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppBreakpoints.tablet;
              final cards = [
                _RewardNavCard(
                  key: const Key('rewards-card-credits'),
                  icon: Icons.account_balance_wallet_rounded,
                  title: l10n.travelCreditsTitle,
                  value: app.demoMode && credit != null
                      ? formatMinorMoney(
                          context,
                          credit.balanceMinor,
                          credit.currency,
                        )
                      : l10n.rewardsNotConnected,
                  message: l10n.travelCreditsSubtitle,
                  semanticLabel: l10n.travelCreditsSemantic,
                  onTap: () => _open(context, const TravelCreditsScreen()),
                ),
                _RewardNavCard(
                  key: const Key('rewards-card-loyalty'),
                  icon: Icons.auto_awesome_rounded,
                  title: l10n.loyaltyTitle,
                  value: app.demoMode && loyalty != null
                      ? l10n.loyaltyPointsValue(loyalty.currentBalance)
                      : l10n.rewardsNotConnected,
                  message: l10n.loyaltySubtitle,
                  semanticLabel: l10n.loyaltySemantic,
                  onTap: () => _open(context, const LoyaltyScreen()),
                ),
                _RewardNavCard(
                  key: const Key('rewards-card-membership'),
                  icon: Icons.workspace_premium_rounded,
                  title: l10n.membershipTitle,
                  value: app.demoMode && membership != null
                      ? membershipTierLabel(l10n, membership.displayTier)
                      : l10n.rewardsNotConnected,
                  message: l10n.membershipSubtitle,
                  semanticLabel: l10n.membershipSemantic,
                  onTap: () => _open(context, const MembershipScreen()),
                ),
                _RewardNavCard(
                  key: const Key('rewards-card-coupons'),
                  icon: Icons.local_offer_rounded,
                  title: l10n.couponsTitle,
                  value: app.demoMode
                      ? l10n.rewardsCountValue(claimedCoupons)
                      : l10n.rewardsNotConnected,
                  message: l10n.couponsSubtitle,
                  semanticLabel: l10n.couponsSemantic,
                  onTap: () => _open(context, const CouponsScreen()),
                ),
                _RewardNavCard(
                  key: const Key('rewards-card-referral'),
                  icon: Icons.group_add_rounded,
                  title: l10n.referralTitle,
                  value: app.demoMode && app.referralSummary != null
                      ? app.referralSummary!.code
                      : l10n.rewardsNotConnected,
                  message: l10n.referralSubtitle,
                  semanticLabel: l10n.referralSemantic,
                  onTap: () => _open(context, const ReferralScreen()),
                ),
                _RewardNavCard(
                  key: const Key('rewards-card-gift-cards'),
                  icon: Icons.card_giftcard_rounded,
                  title: l10n.giftCardsTitle,
                  value: app.demoMode
                      ? l10n.rewardsCountValue(usableCards)
                      : l10n.rewardsNotConnected,
                  message: l10n.giftCardsSubtitle,
                  semanticLabel: l10n.giftCardsSemantic,
                  onTap: () => _open(context, const GiftCardsScreen()),
                ),
              ];
              if (wide) {
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final card in cards)
                      SizedBox(
                        width: (constraints.maxWidth - AppSpacing.md) / 2,
                        child: card,
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  for (final card in cards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: card,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class TravelCreditsScreen extends StatelessWidget {
  const TravelCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final account = app.travelCreditAccount;
    if (!app.demoMode || account == null) {
      return _RewardsScaffold(
        title: l10n.travelCreditsTitle,
        child: OceanEmptyState(
          title: l10n.rewardsRealEmptyTitle,
          message: l10n.rewardsRealUnavailableMessage,
        ),
      );
    }
    return _RewardsScaffold(
      title: l10n.travelCreditsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BalanceCard(
            icon: Icons.account_balance_wallet_rounded,
            title: l10n.travelCreditsBalance,
            value: formatMinorMoney(
              context,
              account.balanceMinor,
              account.currency,
            ),
            semanticLabel: l10n.travelCreditsBalanceSemantic,
            message: l10n.travelCreditsLocalOnly,
          ),
          const SizedBox(height: AppSpacing.md),
          OceanGlassSurface(
            blur: 0,
            color: AppColors.paleCyan,
            child: Text(
              l10n.travelCreditsNoCashOut,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l10n.travelCreditsTransactions),
          const SizedBox(height: AppSpacing.sm),
          if (app.travelCreditTransactions.isEmpty)
            OceanEmptyState(
              title: l10n.rewardsHistoryEmptyTitle,
              message: l10n.rewardsHistoryEmptyMessage,
            )
          else
            for (final transaction in app.travelCreditTransactions)
              _CreditTransactionTile(
                transaction: transaction,
                currency: account.currency,
              ),
        ],
      ),
    );
  }
}

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final account = app.loyaltyAccount;
    if (!app.demoMode || account == null) {
      return _RewardsScaffold(
        title: l10n.loyaltyTitle,
        child: OceanEmptyState(
          title: l10n.rewardsRealEmptyTitle,
          message: l10n.rewardsRealUnavailableMessage,
        ),
      );
    }
    return _RewardsScaffold(
      title: l10n.loyaltyTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OceanGlassCard(
            semanticLabel: l10n.loyaltyBalanceSemantic,
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _MetricBlock(
                  label: l10n.loyaltyCurrentBalance,
                  value: l10n.loyaltyPointsValue(account.currentBalance),
                  icon: Icons.stars_rounded,
                ),
                _MetricBlock(
                  label: l10n.loyaltyLifetimeEarned,
                  value: l10n.loyaltyPointsValue(account.lifetimePointsEarned),
                  icon: Icons.timeline_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OceanGlassSurface(
            blur: 0,
            color: AppColors.paleCyan,
            child: Text(
              l10n.loyaltyNoDirectRedeem,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l10n.loyaltyTransactions),
          const SizedBox(height: AppSpacing.sm),
          if (app.loyaltyTransactions.isEmpty)
            OceanEmptyState(
              title: l10n.rewardsHistoryEmptyTitle,
              message: l10n.rewardsHistoryEmptyMessage,
            )
          else
            for (final transaction in app.loyaltyTransactions)
              _LoyaltyTransactionTile(transaction: transaction),
        ],
      ),
    );
  }
}

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final account = app.membershipAccount;
    final progress = app.membershipProgress;
    if (!app.demoMode || account == null || progress == null) {
      return _RewardsScaffold(
        title: l10n.membershipTitle,
        child: OceanEmptyState(
          title: l10n.rewardsRealEmptyTitle,
          message: l10n.membershipRealUnavailable,
        ),
      );
    }
    final active = account.active && !account.expired;
    final displayTier = active ? account.displayTier : progress.effectiveTier;
    return _RewardsScaffold(
      title: l10n.membershipTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OceanGlassCard(
            semanticLabel: l10n.membershipTierSemantic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OceanStatusPill(
                      label: active
                          ? l10n.membershipActiveStatus
                          : l10n.membershipPreviewStatus,
                      icon: active
                          ? Icons.verified_rounded
                          : Icons.visibility_rounded,
                      color: active ? AppColors.success : AppColors.ocean,
                    ),
                    if (account.expired)
                      OceanStatusPill(
                        label: l10n.membershipExpiredStatus,
                        icon: Icons.timer_off_rounded,
                        color: AppColors.danger,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  membershipTierLabel(l10n, displayTier),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  active
                      ? l10n.membershipActiveMessage
                      : l10n.membershipPreviewMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  container: true,
                  label:
                      l10n.membershipProgressSemantic(progress.clampedProgress),
                  excludeSemantics: true,
                  child: LinearProgressIndicator(
                    key: const Key('membership-progress'),
                    minHeight: 10,
                    value: progress.clampedProgress / 100,
                    backgroundColor: AppColors.mist,
                    color: AppColors.ocean,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  progress.isHighestTier
                      ? l10n.membershipHighestTier
                      : l10n.membershipNextTier(
                          membershipTierLabel(l10n, progress.nextTier!),
                        ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OceanPrimaryButton(
            key: const Key('membership-enroll'),
            label: active
                ? l10n.membershipEnrolledAction
                : l10n.membershipEnrollAction,
            icon: Icons.workspace_premium_rounded,
            semanticLabel: l10n.membershipEnrollSemantic,
            onPressed: () => _enroll(context, app),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l10n.membershipBenefitsTitle),
          const SizedBox(height: AppSpacing.sm),
          for (final benefit in app.membershipBenefits)
            _BenefitTile(benefit: benefit),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l10n.membershipHistoryTitle),
          const SizedBox(height: AppSpacing.sm),
          for (final item in app.membershipHistory)
            _MembershipHistoryTile(item: item),
        ],
      ),
    );
  }

  void _enroll(BuildContext context, AppState app) {
    final l10n = AppLocalizations.of(context)!;
    final result = app.enrollDemoMembership();
    _showResult(context, l10n, result, l10n.membershipEnrollSuccess);
  }
}

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (!app.demoMode) {
      return _RewardsScaffold(
        title: l10n.couponsTitle,
        child: OceanEmptyState(
          title: l10n.rewardsRealEmptyTitle,
          message: l10n.couponsRealUnavailable,
        ),
      );
    }
    return _RewardsScaffold(
      title: l10n.couponsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CodeEntryCard(
            controller: _code,
            title: l10n.couponClaimTitle,
            label: l10n.couponCodeLabel,
            helper: l10n.couponClaimHelper,
            actionLabel: l10n.couponClaimAction,
            semanticLabel: l10n.couponClaimSemantic,
            onSubmit: () {
              final result = app.claimDemoCoupon(_code.text);
              if (result == RewardActionResult.success) _code.clear();
              _showResult(context, l10n, result, l10n.couponClaimSuccess);
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l10n.couponsTitle),
          const SizedBox(height: AppSpacing.sm),
          if (app.coupons.isEmpty)
            OceanEmptyState(
              title: l10n.couponsEmptyTitle,
              message: l10n.couponsEmptyMessage,
            )
          else
            for (final coupon in app.coupons) _CouponTile(coupon: coupon),
        ],
      ),
    );
  }
}

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _code = TextEditingController();
  bool _copied = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final summary = app.referralSummary;
    if (!app.demoMode || summary == null) {
      return _RewardsScaffold(
        title: l10n.referralTitle,
        child: OceanEmptyState(
          title: l10n.rewardsRealEmptyTitle,
          message: l10n.referralRealUnavailable,
        ),
      );
    }
    return _RewardsScaffold(
      title: l10n.referralTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OceanGlassCard(
            semanticLabel: l10n.referralCodeSemantic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.referralYourCode,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  summary.code,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.referralStats(
                    summary.successfulReferrals,
                    summary.pendingReferrals,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                OceanSecondaryButton(
                  key: const Key('referral-copy'),
                  label: _copied
                      ? l10n.referralCopiedAction
                      : l10n.referralCopyAction,
                  icon: Icons.copy_rounded,
                  semanticLabel: l10n.referralCopySemantic,
                  onPressed: () async {
                    if (!mounted) return;
                    setState(() => _copied = true);
                    await Clipboard.setData(ClipboardData(text: summary.code));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _CodeEntryCard(
            controller: _code,
            title: l10n.referralUseCodeTitle,
            label: l10n.referralCodeLabel,
            helper: l10n.referralUseCodeHelper,
            actionLabel: l10n.referralUseCodeAction,
            semanticLabel: l10n.referralUseCodeSemantic,
            onSubmit: () {
              final result = app.useDemoReferralCode(_code.text);
              if (result == RewardActionResult.success) _code.clear();
              _showResult(context, l10n, result, l10n.referralUseSuccess);
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l10n.referralHistoryTitle),
          const SizedBox(height: AppSpacing.sm),
          for (final item in app.referralHistory)
            _ReferralHistoryTile(item: item),
        ],
      ),
    );
  }
}

class GiftCardsScreen extends StatefulWidget {
  const GiftCardsScreen({super.key});

  @override
  State<GiftCardsScreen> createState() => _GiftCardsScreenState();
}

class _GiftCardsScreenState extends State<GiftCardsScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (!app.demoMode) {
      // UI33: real gift cards are backend-connected. Demo Mode is byte-identical.
      return _RewardsScaffold(
        title: l10n.giftCardsTitle,
        child: const RealGiftCardsView(),
      );
    }
    return _RewardsScaffold(
      title: l10n.giftCardsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CodeEntryCard(
            controller: _code,
            title: l10n.giftCardClaimTitle,
            label: l10n.giftCardCodeLabel,
            helper: l10n.giftCardClaimHelper,
            actionLabel: l10n.giftCardClaimAction,
            semanticLabel: l10n.giftCardClaimSemantic,
            onSubmit: () {
              final result = app.claimDemoGiftCard(_code.text);
              if (result == RewardActionResult.success) _code.clear();
              _showResult(context, l10n, result, l10n.giftCardClaimSuccess);
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(l10n.giftCardsTitle),
          const SizedBox(height: AppSpacing.sm),
          if (app.giftCards.isEmpty)
            OceanEmptyState(
              title: l10n.giftCardsEmptyTitle,
              message: l10n.giftCardsEmptyMessage,
            )
          else
            for (final card in app.giftCards)
              _GiftCardTile(
                card: card,
                onTap: () => _showGiftCard(context, app, card),
              ),
        ],
      ),
    );
  }

  Future<void> _showGiftCard(
    BuildContext context,
    AppState app,
    GiftCard card,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GiftCardDetailSheet(
        card: app.giftCards.firstWhere(
          (item) => item.id == card.id,
          orElse: () => card,
        ),
        onActivate: card.effectiveStatus == GiftCardStatus.issued
            ? () {
                Navigator.pop(context);
                final result = app.activateDemoGiftCard(card.id);
                _showResult(
                  context,
                  AppLocalizations.of(context)!,
                  result,
                  AppLocalizations.of(context)!.giftCardActivateSuccess,
                );
                setState(() {});
              }
            : null,
        onPreview: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.giftCardPreviewReadOnly,
                ),
              ),
            );
        },
      ),
    );
  }
}

class _RewardsScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _RewardsScaffold({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
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
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardsHero extends StatelessWidget {
  final String title;
  final String subtitle;

  const _RewardsHero({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => OceanGlassCard(
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.ocean.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: const Icon(
                Icons.redeem_rounded,
                color: AppColors.ocean,
                size: AppIconSizes.xl,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      );
}

class _RewardNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String message;
  final String semanticLabel;
  final VoidCallback onTap;

  const _RewardNavCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.message,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        child: ExcludeSemantics(
          child: OceanGlassCard(
            onTap: onTap,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.ocean.withValues(alpha: .12),
                  child: Icon(icon, color: AppColors.ocean),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: AppColors.ocean),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      );
}

class _BalanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String message;
  final String semanticLabel;

  const _BalanceCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.message,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) => OceanGlassCard(
        semanticLabel: semanticLabel,
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.ocean.withValues(alpha: .12),
              child: Icon(icon, color: AppColors.ocean),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(color: AppColors.ocean),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricBlock({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 240,
        child: OceanGlassSurface(
          blur: 0,
          color: AppColors.paleCyan,
          child: Row(
            children: [
              Icon(icon, color: AppColors.ocean),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _CodeEntryCard extends StatelessWidget {
  final TextEditingController controller;
  final String title;
  final String label;
  final String helper;
  final String actionLabel;
  final String semanticLabel;
  final VoidCallback onSubmit;

  const _CodeEntryCard({
    required this.controller,
    required this.title,
    required this.label,
    required this.helper,
    required this.actionLabel,
    required this.semanticLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => OceanGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(helper, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: Key('$semanticLabel-field'),
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: const Icon(Icons.confirmation_number_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OceanPrimaryButton(
              label: actionLabel,
              icon: Icons.redeem_rounded,
              semanticLabel: semanticLabel,
              onPressed: onSubmit,
            ),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleLarge,
      );
}

class _CreditTransactionTile extends StatelessWidget {
  final TravelCreditTransaction transaction;
  final String currency;

  const _CreditTransactionTile({
    required this.transaction,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final increase = transaction.transactionType.increasesBalance;
    return _LedgerTile(
      title: travelCreditTransactionLabel(l10n, transaction.transactionType),
      subtitle: transaction.description,
      amount: '${increase ? '+' : '-'}${formatMinorMoney(
        context,
        transaction.amountMinor,
        currency,
      )}',
      color: increase ? AppColors.success : AppColors.danger,
      footer: transaction.expiresAt == null
          ? null
          : l10n.rewardsExpiresOn(_date(context, transaction.expiresAt!)),
    );
  }
}

class _LoyaltyTransactionTile extends StatelessWidget {
  final LoyaltyTransaction transaction;

  const _LoyaltyTransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final increase = transaction.increasesBalance;
    return _LedgerTile(
      title: loyaltyTransactionLabel(l10n, transaction.transactionType),
      subtitle: transaction.description,
      amount: '${increase ? '+' : '-'}${transaction.points} ${l10n.pointsUnit}',
      color: increase ? AppColors.success : AppColors.danger,
    );
  }
}

class _LedgerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final Color color;
  final String? footer;

  const _LedgerTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    this.footer,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: OceanGlassSurface(
          blur: 0,
          color: AppColors.surfaceOverlay,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                    if (footer != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(footer!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ),
      );
}

class _BenefitTile extends StatelessWidget {
  final MembershipBenefit benefit;

  const _BenefitTile({required this.benefit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: OceanGlassSurface(
        blur: 0,
        color: AppColors.surfaceOverlay,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OceanStatusPill(
                  label: membershipTierLabel(l10n, benefit.tier),
                  icon: Icons.workspace_premium_rounded,
                ),
                OceanStatusPill(
                  label: membershipBenefitTypeLabel(l10n, benefit.type),
                  icon: Icons.info_outline_rounded,
                  color: AppColors.turquoise600,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(benefit.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(benefit.description,
                style: Theme.of(context).textTheme.bodyMedium),
            if (benefit.conditions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                benefit.conditions,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MembershipHistoryTile extends StatelessWidget {
  final MembershipHistoryItem item;

  const _MembershipHistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _LedgerTile(
      title: membershipTierLabel(l10n, item.tier),
      subtitle: item.description,
      amount: _date(context, item.changedAt),
      color: AppColors.ocean,
    );
  }
}

class _CouponTile extends StatelessWidget {
  final CustomerCoupon coupon;

  const _CouponTile({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: OceanGlassCard(
        semanticLabel: l10n.couponCardSemantic(coupon.code),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OceanStatusPill(
                  label: coupon.effectiveStatus,
                  icon: Icons.verified_rounded,
                  color: coupon.isUsable ? AppColors.success : AppColors.slate,
                ),
                OceanStatusPill(
                  label: couponTargetLabel(l10n, coupon.targetType),
                  icon: Icons.sell_rounded,
                  color: AppColors.turquoise600,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(coupon.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(coupon.description,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              couponDiscountLabel(context, l10n, coupon),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.ocean),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.couponPreviewReadOnly,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralHistoryTile extends StatelessWidget {
  final ReferralHistoryItem item;

  const _ReferralHistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _LedgerTile(
      title:
          '${referralRoleLabel(l10n, item.role)} · ${referralStatusLabel(l10n, item.status)}',
      subtitle: item.campaignCode,
      amount: _date(context, item.usedAt),
      color: item.status == ReferralStatus.rewarded
          ? AppColors.success
          : AppColors.ocean,
      footer: item.status == ReferralStatus.used
          ? l10n.referralUsedNoReward
          : item.qualifyingBookingId,
    );
  }
}

class _GiftCardTile extends StatelessWidget {
  final GiftCard card;
  final VoidCallback onTap;

  const _GiftCardTile({
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: OceanGlassCard(
        key: Key('gift-card-${card.id}'),
        onTap: onTap,
        semanticLabel: l10n.giftCardCardSemantic(card.maskedCode),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.violet.withValues(alpha: .12),
              child: const Icon(Icons.card_giftcard_rounded,
                  color: AppColors.violet),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.productName,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(card.maskedCode,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    formatMinorMoney(
                      context,
                      card.currentBalanceMinor,
                      card.currency,
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.ocean),
                  ),
                ],
              ),
            ),
            OceanStatusPill(
              label: giftCardStatusLabel(l10n, card.effectiveStatus),
              icon: Icons.verified_rounded,
              color: card.effectiveStatus.canRedeem
                  ? AppColors.success
                  : AppColors.slate,
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftCardDetailSheet extends StatelessWidget {
  final GiftCard card;
  final VoidCallback? onActivate;
  final VoidCallback onPreview;

  const _GiftCardDetailSheet({
    required this.card,
    required this.onActivate,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(card.productName,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(card.maskedCode, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.md),
            OceanStatusPill(
              label: giftCardStatusLabel(l10n, card.effectiveStatus),
              icon: Icons.verified_rounded,
              color: card.effectiveStatus.canRedeem
                  ? AppColors.success
                  : AppColors.slate,
            ),
            const SizedBox(height: AppSpacing.md),
            _MetricBlock(
              label: l10n.giftCardBalance,
              value: formatMinorMoney(
                context,
                card.currentBalanceMinor,
                card.currency,
              ),
              icon: Icons.payments_rounded,
            ),
            if (card.personalMessage.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(card.personalMessage,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(l10n.giftCardTransactionsTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            if (card.transactions.isEmpty)
              Text(l10n.rewardsHistoryEmptyMessage,
                  style: Theme.of(context).textTheme.bodyMedium)
            else
              for (final transaction in card.transactions)
                _LedgerTile(
                  title: giftCardTransactionLabel(
                    l10n,
                    transaction.transactionType,
                  ),
                  subtitle: transaction.description,
                  amount:
                      '${transaction.increasesBalance ? '+' : '-'}${formatMinorMoney(
                    context,
                    transaction.amountMinor,
                    card.currency,
                  )}',
                  color: transaction.increasesBalance
                      ? AppColors.success
                      : AppColors.danger,
                ),
            const SizedBox(height: AppSpacing.lg),
            OceanSecondaryButton(
              label: l10n.giftCardPreviewAction,
              icon: Icons.visibility_rounded,
              semanticLabel: l10n.giftCardPreviewSemantic,
              onPressed: onPreview,
            ),
            if (onActivate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OceanPrimaryButton(
                key: const Key('gift-card-activate'),
                label: l10n.giftCardActivateAction,
                icon: Icons.flash_on_rounded,
                onPressed: onActivate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String formatMinorMoney(
    BuildContext context, int amountMinor, String currency) {
  final amount = currency == 'VND' ? amountMinor.toDouble() : amountMinor / 100;
  return formatMoney(context, amount, currency);
}

String _date(BuildContext context, DateTime value) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(value);

void _showResult(
  BuildContext context,
  AppLocalizations l10n,
  RewardActionResult result,
  String success,
) {
  final message = switch (result) {
    RewardActionResult.success => success,
    RewardActionResult.unavailable => l10n.rewardsActionUnavailable,
    RewardActionResult.blank => l10n.rewardsCodeBlank,
    RewardActionResult.duplicate => l10n.rewardsCodeDuplicate,
    RewardActionResult.rejected => l10n.rewardsCodeRejected,
    RewardActionResult.ownCode => l10n.referralOwnCodeRejected,
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String membershipTierLabel(AppLocalizations l10n, MembershipTier tier) {
  switch (tier) {
    case MembershipTier.bronze:
      return l10n.membershipTierBronze;
    case MembershipTier.silver:
      return l10n.membershipTierSilver;
    case MembershipTier.gold:
      return l10n.membershipTierGold;
    case MembershipTier.platinum:
      return l10n.membershipTierPlatinum;
    case MembershipTier.diamond:
      return l10n.membershipTierDiamond;
  }
}

String membershipBenefitTypeLabel(
  AppLocalizations l10n,
  MembershipBenefitType type,
) {
  switch (type) {
    case MembershipBenefitType.pointsMultiplier:
      return l10n.benefitPointsMultiplier;
    case MembershipBenefitType.memberOnlyCoupons:
      return l10n.benefitMemberCoupons;
    case MembershipBenefitType.prioritySupport:
      return l10n.benefitPrioritySupport;
    case MembershipBenefitType.earlyAccess:
      return l10n.benefitEarlyAccess;
    case MembershipBenefitType.lateCheckout:
      return l10n.benefitLateCheckout;
    case MembershipBenefitType.earlyCheckin:
      return l10n.benefitEarlyCheckin;
    case MembershipBenefitType.roomUpgrade:
      return l10n.benefitRoomUpgrade;
    case MembershipBenefitType.freeBreakfast:
      return l10n.benefitFreeBreakfast;
    case MembershipBenefitType.airportTransfer:
      return l10n.benefitAirportTransfer;
    case MembershipBenefitType.custom:
      return l10n.benefitCustom;
  }
}

String travelCreditTransactionLabel(
  AppLocalizations l10n,
  TravelCreditTransactionType type,
) {
  switch (type) {
    case TravelCreditTransactionType.grant:
      return l10n.creditTxnGrant;
    case TravelCreditTransactionType.promotion:
      return l10n.creditTxnPromotion;
    case TravelCreditTransactionType.refundCredit:
      return l10n.creditTxnRefund;
    case TravelCreditTransactionType.adjustment:
      return l10n.creditTxnAdjustment;
    case TravelCreditTransactionType.redemption:
      return l10n.creditTxnRedemption;
    case TravelCreditTransactionType.expiration:
      return l10n.creditTxnExpiration;
    case TravelCreditTransactionType.reversal:
      return l10n.creditTxnReversal;
  }
}

String loyaltyTransactionLabel(
  AppLocalizations l10n,
  LoyaltyTransactionType type,
) {
  switch (type) {
    case LoyaltyTransactionType.earnBooking:
      return l10n.loyaltyTxnEarnBooking;
    case LoyaltyTransactionType.earnReview:
      return l10n.loyaltyTxnEarnReview;
    case LoyaltyTransactionType.grant:
      return l10n.loyaltyTxnGrant;
    case LoyaltyTransactionType.adjustment:
      return l10n.loyaltyTxnAdjustment;
    case LoyaltyTransactionType.reversal:
      return l10n.loyaltyTxnReversal;
    case LoyaltyTransactionType.redemptionDebit:
      return l10n.loyaltyTxnRedemptionDebit;
    case LoyaltyTransactionType.redemptionRelease:
      return l10n.loyaltyTxnRedemptionRelease;
    case LoyaltyTransactionType.redemptionRefund:
      return l10n.loyaltyTxnRedemptionRefund;
  }
}

String couponTargetLabel(AppLocalizations l10n, CouponTargetType type) {
  switch (type) {
    case CouponTargetType.all:
      return l10n.couponTargetAll;
    case CouponTargetType.hotel:
      return l10n.couponTargetHotel;
    case CouponTargetType.room:
      return l10n.couponTargetRoom;
    case CouponTargetType.placeType:
      return l10n.couponTargetPlaceType;
  }
}

String couponDiscountLabel(
  BuildContext context,
  AppLocalizations l10n,
  CustomerCoupon coupon,
) {
  if (coupon.discountType == CouponDiscountType.percentage) {
    final percent = coupon.discountValue.clamp(0, 100).toInt();
    return l10n.couponPercentageValue(percent);
  }
  final currency = coupon.currency;
  if (currency == null || currency.isEmpty || coupon.discountValue <= 0) {
    return l10n.couponAmountUnavailable;
  }
  return l10n.couponFixedValue(
    formatMinorMoney(context, coupon.discountValue, currency),
  );
}

String referralRoleLabel(AppLocalizations l10n, ReferralRole role) =>
    role == ReferralRole.inviter
        ? l10n.referralRoleInviter
        : l10n.referralRoleInvitee;

String referralStatusLabel(AppLocalizations l10n, ReferralStatus status) =>
    status == ReferralStatus.used
        ? l10n.referralStatusUsed
        : l10n.referralStatusRewarded;

String giftCardStatusLabel(AppLocalizations l10n, GiftCardStatus status) {
  switch (status) {
    case GiftCardStatus.issued:
      return l10n.giftCardStatusIssued;
    case GiftCardStatus.active:
      return l10n.giftCardStatusActive;
    case GiftCardStatus.partiallyRedeemed:
      return l10n.giftCardStatusPartiallyRedeemed;
    case GiftCardStatus.fullyRedeemed:
      return l10n.giftCardStatusFullyRedeemed;
    case GiftCardStatus.expired:
      return l10n.giftCardStatusExpired;
    case GiftCardStatus.cancelled:
      return l10n.giftCardStatusCancelled;
  }
}

String giftCardTransactionLabel(
  AppLocalizations l10n,
  GiftCardTransactionType type,
) {
  switch (type) {
    case GiftCardTransactionType.issue:
      return l10n.giftCardTxnIssue;
    case GiftCardTransactionType.activation:
      return l10n.giftCardTxnActivation;
    case GiftCardTransactionType.redemption:
      return l10n.giftCardTxnRedemption;
    case GiftCardTransactionType.refund:
      return l10n.giftCardTxnRefund;
    case GiftCardTransactionType.expiry:
      return l10n.giftCardTxnExpiry;
  }
}
