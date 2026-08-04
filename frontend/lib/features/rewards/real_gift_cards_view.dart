import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';

/// UI33 — Real Mode gift cards (`GET /api/me/gift-cards`, `/{id}`,
/// `/{id}/transactions`, `POST /claim`, `POST /{id}/activate`). Prepaid
/// promotional value only. Rendered inside the existing rewards Gift Cards
/// scaffold, replacing the real-mode placeholder. A 401 never logs the user out.
class RealGiftCardsView extends StatefulWidget {
  const RealGiftCardsView({super.key});

  @override
  State<RealGiftCardsView> createState() => _RealGiftCardsViewState();
}

class _RealGiftCardsViewState extends State<RealGiftCardsView> {
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealGiftCards();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
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

  String _messageForOutcome(AppLocalizations l10n, GiftCardActionOutcome o) {
    return switch (o) {
      GiftCardActionOutcome.notFound => l10n.giftCardsRealNotFound,
      GiftCardActionOutcome.conflict => l10n.giftCardsRealConflict,
      GiftCardActionOutcome.validation => l10n.giftCardsRealValidation,
      GiftCardActionOutcome.network => l10n.giftCardsRealNetwork,
      _ => l10n.giftCardsRealActionError,
    };
  }

  Future<void> _claim(AppState app) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await app.claimRealGiftCard(_code.text);
    if (!mounted) return;
    switch (outcome) {
      case GiftCardActionOutcome.success:
        _code.clear();
        _snack(l10n.giftCardsRealClaimSuccess);
      case GiftCardActionOutcome.sessionExpired:
        _reauth();
      case GiftCardActionOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _openCard(AppState app, RealGiftCardSummary card) async {
    app.loadRealGiftCardDetail(card.id);
    app.loadRealGiftCardTransactions(card.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GiftCardDetailSheet(
        cardId: card.id,
        onActivate: () => _activate(app, card.id),
        onReauth: _reauth,
        messageForOutcome: _messageForOutcome,
      ),
    );
  }

  Future<void> _activate(AppState app, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await app.activateRealGiftCard(id);
    if (!mounted) return;
    switch (outcome) {
      case GiftCardActionOutcome.success:
        _snack(l10n.giftCardsRealActivateSuccess);
      case GiftCardActionOutcome.sessionExpired:
        _reauth();
      case GiftCardActionOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (app.realGiftCardsError == GiftCardActionOutcome.sessionExpired &&
        !app.realGiftCardsLoaded) {
      return OceanSessionExpiredState(
        key: const Key('gift-cards-session-expired'),
        onLogin: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
        onReturnHome: () => Navigator.maybePop(context),
      );
    }
    if (app.realGiftCardsLoading && !app.realGiftCardsLoaded) {
      return Semantics(
        liveRegion: true,
        label: l10n.giftCardsRealLoadingMessage,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            const CircularProgressIndicator(key: Key('gift-cards-loading')),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.giftCardsRealLoadingMessage),
          ],
        ),
      );
    }
    if (app.realGiftCardsError != null && !app.realGiftCardsLoaded) {
      return OceanRecoverableErrorState(
        key: const Key('gift-cards-error'),
        message: l10n.giftCardsRealErrorMessage,
        onReload: () => app.loadRealGiftCards(refresh: true),
      );
    }

    final claiming = app.giftCardActionInFlight.contains(-1);
    return Column(
      key: const Key('gift-cards-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClaimCard(
          controller: _code,
          claiming: claiming,
          onSubmit: claiming ? null : () => _claim(app),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.giftCardsTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (app.realGiftCards.isEmpty)
          OceanEmptyState(
            key: const Key('gift-cards-empty'),
            title: l10n.giftCardsEmptyTitle,
            message: l10n.giftCardsRealEmptyMessage,
          )
        else ...[
          for (final card in app.realGiftCards)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _GiftCardTile(
                card: card,
                onTap: () => _openCard(app, card),
              ),
            ),
          if (app.realGiftCardsHasMore) ...[
            const SizedBox(height: AppSpacing.xs),
            OceanSecondaryButton(
              key: const Key('gift-cards-load-more'),
              label: l10n.giftCardsRealLoadMore,
              icon: Icons.expand_more_rounded,
              onPressed: app.realGiftCardsLoadingMore
                  ? null
                  : () => app.loadMoreRealGiftCards(),
            ),
          ],
        ],
      ],
    );
  }
}

String giftCardStatusLabel(AppLocalizations l10n, GiftCardStatusView v) {
  return switch (v) {
    GiftCardStatusView.issued => l10n.giftCardStatusIssued,
    GiftCardStatusView.active => l10n.giftCardStatusActive,
    GiftCardStatusView.partiallyRedeemed =>
      l10n.giftCardStatusPartiallyRedeemed,
    GiftCardStatusView.fullyRedeemed => l10n.giftCardStatusFullyRedeemed,
    GiftCardStatusView.expired => l10n.giftCardStatusExpired,
    GiftCardStatusView.cancelled => l10n.giftCardStatusCancelled,
    GiftCardStatusView.unknown => l10n.giftCardStatusUnknown,
  };
}

Color giftCardStatusColor(GiftCardStatusView v) {
  return switch (v) {
    GiftCardStatusView.active => AppColors.success,
    GiftCardStatusView.partiallyRedeemed => AppColors.turquoise600,
    GiftCardStatusView.issued => AppColors.ocean,
    GiftCardStatusView.fullyRedeemed => AppColors.textSecondary,
    GiftCardStatusView.expired => AppColors.warning,
    GiftCardStatusView.cancelled => AppColors.danger,
    GiftCardStatusView.unknown => AppColors.textSecondary,
  };
}

String giftCardMoney(double amount, String currency) {
  final value = amount.toStringAsFixed(2);
  return currency.isEmpty ? value : '$value $currency';
}

class _ClaimCard extends StatelessWidget {
  final TextEditingController controller;
  final bool claiming;
  final VoidCallback? onSubmit;

  const _ClaimCard({
    required this.controller,
    required this.claiming,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.giftCardsRealClaimTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.giftCardsRealClaimHelper,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassTextField(
            key: const Key('gift-cards-claim-field'),
            controller: controller,
            hint: l10n.giftCardCodeLabel,
            icon: Icons.confirmation_number_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          OceanPrimaryButton(
            key: const Key('gift-cards-claim-submit'),
            label: l10n.giftCardClaimAction,
            icon: Icons.redeem_rounded,
            semanticLabel: l10n.giftCardClaimSemantic,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _GiftCardTile extends StatelessWidget {
  final RealGiftCardSummary card;
  final VoidCallback onTap;

  const _GiftCardTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = card.statusView;
    return OceanGlassCard(
      key: Key('gift-card-tile-${card.id}'),
      onTap: onTap,
      semanticLabel: l10n.giftCardCardSemantic(card.maskedCode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.productName.trim().isEmpty
                      ? card.maskedCode
                      : card.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              OceanStatusPill(
                label: giftCardStatusLabel(l10n, view),
                icon: Icons.card_giftcard_rounded,
                color: giftCardStatusColor(view),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            card.maskedCode,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            giftCardMoney(card.currentBalance, card.currency),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.ocean),
          ),
          Text(
            l10n.giftCardBalance,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _GiftCardDetailSheet extends StatelessWidget {
  final int cardId;
  final VoidCallback onActivate;
  final VoidCallback onReauth;
  final String Function(AppLocalizations, GiftCardActionOutcome)
      messageForOutcome;

  const _GiftCardDetailSheet({
    required this.cardId,
    required this.onActivate,
    required this.onReauth,
    required this.messageForOutcome,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final detail = app.giftCardDetailCache[cardId];
    final loading = app.giftCardDetailLoadingId == cardId && detail == null;
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: loading
            ? const Padding(
                key: Key('gift-card-detail-loading'),
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            : detail == null
                ? OceanEmptyState(
                    key: const Key('gift-card-detail-error'),
                    title: l10n.giftCardsEmptyTitle,
                    message: l10n.giftCardsRealErrorMessage,
                  )
                : _detail(context, app, l10n, detail),
      ),
    );
  }

  Widget _detail(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
    RealGiftCardDetail detail,
  ) {
    final view = detail.statusView;
    final df = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final transactions = app.giftCardTransactionsCache[cardId] ?? const [];
    final txLoading = app.giftCardTransactionsLoadingId == cardId;
    final activating = app.giftCardActionInFlight.contains(cardId);
    return Column(
      key: const Key('gift-card-detail-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                detail.productName.trim().isEmpty
                    ? l10n.giftCardsTitle
                    : detail.productName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            OceanStatusPill(
              label: giftCardStatusLabel(l10n, view),
              icon: Icons.card_giftcard_rounded,
              color: giftCardStatusColor(view),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          detail.maskedCode,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          label: l10n.giftCardsRealBalanceSemantic(
            giftCardMoney(detail.currentBalance, detail.currency),
          ),
          child: Text(
            giftCardMoney(detail.currentBalance, detail.currency),
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(color: AppColors.ocean),
          ),
        ),
        Text(
          l10n.giftCardBalance,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        if (detail.personalMessage.trim().isNotEmpty) ...[
          Text(
            detail.personalMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            if (detail.issuedAt != null)
              OceanStatusPill(
                label: df.format(detail.issuedAt!.toLocal()),
                icon: Icons.event_available_rounded,
                color: AppColors.turquoise600,
              ),
            if (detail.expiresAt != null)
              OceanStatusPill(
                label: df.format(detail.expiresAt!.toLocal()),
                icon: Icons.timer_outlined,
                color: AppColors.warning,
              ),
          ],
        ),
        if (view == GiftCardStatusView.issued) ...[
          const SizedBox(height: AppSpacing.md),
          OceanPrimaryButton(
            key: const Key('gift-card-activate'),
            label: l10n.giftCardsRealActivateAction,
            icon: Icons.check_circle_outline_rounded,
            onPressed: activating
                ? null
                : () {
                    Navigator.pop(context);
                    onActivate();
                  },
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.giftCardTransactionsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (txLoading && transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (transactions.isEmpty)
          Text(
            l10n.giftCardsEmptyMessage,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          )
        else
          for (final tx in transactions) _TransactionRow(tx: tx),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final RealGiftCardTransaction tx;

  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final df = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final positive = tx.increasesBalance;
    final sign = positive ? '+' : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            positive
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: AppSpacing.md,
            color: positive ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  giftCardTxnLabel(l10n, tx.transactionType),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (tx.createdAt != null)
                  Text(
                    df.format(tx.createdAt!.toLocal()),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            '$sign${tx.amount.abs().toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: positive ? AppColors.success : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

String giftCardTxnLabel(AppLocalizations l10n, String type) {
  return switch (type) {
    'ISSUE' => l10n.giftCardTxnIssue,
    'ACTIVATION' => l10n.giftCardTxnActivation,
    'REDEMPTION' => l10n.giftCardTxnRedemption,
    'REFUND' => l10n.giftCardTxnRefund,
    'EXPIRY' => l10n.giftCardTxnExpiry,
    _ => type,
  };
}
