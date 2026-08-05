import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';

/// UI39 — Real Mode personalized recommendations
/// (`GET /api/me/recommendations`, Phase 7.23). Lists the customer's active
/// recommendation feed (paginated), lets them regenerate it, opens a detail
/// sheet (tracking the click), and dismisses items. Read + engagement only — the
/// backend never claims or reserves anything, so nothing here is fabricated.
class RealRecommendationsScreen extends StatefulWidget {
  const RealRecommendationsScreen({super.key});

  @override
  State<RealRecommendationsScreen> createState() =>
      _RealRecommendationsScreenState();
}

class _RealRecommendationsScreenState extends State<RealRecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealRecommendations();
    });
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

  String _messageForOutcome(AppLocalizations l10n, RecommendationOutcome o) {
    return switch (o) {
      RecommendationOutcome.notFound => l10n.recommendationsGoneMessage,
      RecommendationOutcome.network => l10n.recommendationsNetworkMessage,
      _ => l10n.recommendationsActionErrorMessage,
    };
  }

  Future<void> _generate(AppState app) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await app.generateRealRecommendations();
    if (!mounted) return;
    switch (outcome) {
      case RecommendationOutcome.success:
        _snack(l10n.recommendationsGeneratedMessage);
      case RecommendationOutcome.sessionExpired:
        _reauth();
      case RecommendationOutcome.busy:
        break;
      default:
        _snack(l10n.recommendationsGenerateErrorMessage);
    }
  }

  Future<void> _dismiss(AppState app, RealRecommendation r) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await app.dismissRealRecommendation(r.id);
    if (!mounted) return;
    switch (outcome) {
      case RecommendationOutcome.success:
        _snack(l10n.recommendationsDismissedMessage);
      case RecommendationOutcome.sessionExpired:
        _reauth();
      case RecommendationOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _open(AppState app, RealRecommendation r) async {
    // Opening tracks a click (idempotent, best-effort) and shows detail.
    unawaited(app.trackRealRecommendationClick(r.id));
    unawaited(app.loadRealRecommendationDetail(r.id));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecommendationDetailSheet(id: r.id, fallback: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final canGenerate =
        !app.realRecommendationsGenerating && !app.realRecommendationsLoading;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.recommendationsTitle),
        actions: [
          if (app.realRecommendationsLoaded)
            IconButton(
              key: const Key('recommendations-generate'),
              tooltip: l10n.recommendationsGenerateSemantic,
              onPressed: canGenerate ? () => _generate(app) : null,
              icon: app.realRecommendationsGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
            ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    if (app.realRecommendationsError == RecommendationOutcome.sessionExpired &&
        !app.realRecommendationsLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('recommendations-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realRecommendationsLoading && !app.realRecommendationsLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.recommendationsLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                key: Key('recommendations-loading'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.recommendationsLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realRecommendationsError != null &&
        !app.realRecommendationsLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('recommendations-error'),
          message: l10n.recommendationsErrorMessage,
          onReload: () => app.loadRealRecommendations(refresh: true),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => app.loadRealRecommendations(refresh: true),
      child: ListView(
        key: const Key('recommendations-content'),
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
                if (app.realRecommendations.isEmpty)
                  OceanEmptyState(
                    key: const Key('recommendations-empty'),
                    title: l10n.recommendationsEmptyTitle,
                    message: l10n.recommendationsEmptyMessage,
                  )
                else ...[
                  for (final r in app.realRecommendations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _RecommendationCard(
                        rec: r,
                        onTap: () => _open(app, r),
                        onDismiss: () => _dismiss(app, r),
                      ),
                    ),
                  if (app.realRecommendationsHasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: OceanSecondaryButton(
                        key: const Key('recommendations-load-more'),
                        label: l10n.recommendationsLoadMore,
                        onPressed: app.realRecommendationsLoadingMore
                            ? null
                            : () => app.loadMoreRealRecommendations(),
                      ),
                    ),
                ],
              ],
            ),
          ),
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

// ── Type / engagement presentation helpers (text + icon + colour, never
//    colour-only) ────────────────────────────────────────────────────────────

String recommendationTypeLabel(
  AppLocalizations l10n,
  RecommendationTypeView view,
) {
  return switch (view) {
    RecommendationTypeView.place => l10n.recommendationTypePlace,
    RecommendationTypeView.hotel => l10n.recommendationTypeHotel,
    RecommendationTypeView.room => l10n.recommendationTypeRoom,
    RecommendationTypeView.promotion => l10n.recommendationTypePromotion,
    RecommendationTypeView.coupon => l10n.recommendationTypeCoupon,
    RecommendationTypeView.tripIdea => l10n.recommendationTypeTripIdea,
    RecommendationTypeView.unknown => l10n.recommendationTypeOther,
  };
}

IconData recommendationTypeIcon(RecommendationTypeView view) {
  return switch (view) {
    RecommendationTypeView.place => Icons.place_rounded,
    RecommendationTypeView.hotel => Icons.hotel_rounded,
    RecommendationTypeView.room => Icons.bed_rounded,
    RecommendationTypeView.promotion => Icons.local_offer_rounded,
    RecommendationTypeView.coupon => Icons.confirmation_number_rounded,
    RecommendationTypeView.tripIdea => Icons.lightbulb_rounded,
    RecommendationTypeView.unknown => Icons.recommend_rounded,
  };
}

Color recommendationTypeColor(RecommendationTypeView view) {
  return switch (view) {
    RecommendationTypeView.place => AppColors.ocean,
    RecommendationTypeView.hotel => AppColors.turquoise600,
    RecommendationTypeView.room => AppColors.turquoise600,
    RecommendationTypeView.promotion => AppColors.warning,
    RecommendationTypeView.coupon => AppColors.success,
    RecommendationTypeView.tripIdea => AppColors.ocean,
    RecommendationTypeView.unknown => AppColors.slate,
  };
}

class _RecommendationCard extends StatelessWidget {
  final RealRecommendation rec;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _RecommendationCard({
    required this.rec,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeView = rec.typeView;
    final title = (rec.targetSummary ?? '').trim().isNotEmpty
        ? rec.targetSummary!.trim()
        : ((rec.placeName ?? rec.hotelName ?? '').trim().isNotEmpty
            ? (rec.placeName ?? rec.hotelName)!.trim()
            : l10n.recommendationUntitled);
    final reason = (rec.reasonText ?? '').trim();
    final engagement = rec.engagementView;
    return OceanGlassCard(
      key: Key('recommendation-card-${rec.id}'),
      onTap: onTap,
      semanticLabel: l10n.recommendationCardSemantic(title),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    reason,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OceanStatusPill(
                      label: recommendationTypeLabel(l10n, typeView),
                      icon: recommendationTypeIcon(typeView),
                      color: recommendationTypeColor(typeView),
                    ),
                    OceanStatusPill(
                      label: '${rec.score}',
                      semanticLabel:
                          l10n.recommendationScoreSemantic(rec.score),
                      icon: Icons.insights_rounded,
                      color: AppColors.ocean,
                    ),
                    if (engagement == RecommendationEngagementView.clicked)
                      OceanStatusPill(
                        label: l10n.recommendationStateClicked,
                        icon: Icons.touch_app_rounded,
                        color: AppColors.info,
                      ),
                    if (engagement == RecommendationEngagementView.converted)
                      OceanStatusPill(
                        label: l10n.recommendationStateConverted,
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('recommendation-dismiss-${rec.id}'),
            tooltip: l10n.recommendationsDismissSemantic(title),
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _RecommendationDetailSheet extends StatelessWidget {
  final int id;
  final RealRecommendation fallback;

  const _RecommendationDetailSheet({required this.id, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final rec = app.recommendationDetailCache[id] ?? fallback;
    final typeView = rec.typeView;
    final title = (rec.targetSummary ?? '').trim().isNotEmpty
        ? rec.targetSummary!.trim()
        : ((rec.placeName ?? rec.hotelName ?? '').trim().isNotEmpty
            ? (rec.placeName ?? rec.hotelName)!.trim()
            : l10n.recommendationUntitled);
    final df = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return SafeArea(
      child: Padding(
        key: const Key('recommendation-detail-content'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OceanStatusPill(
                  label: recommendationTypeLabel(l10n, typeView),
                  icon: recommendationTypeIcon(typeView),
                  color: recommendationTypeColor(typeView),
                ),
                OceanStatusPill(
                  label: '${rec.score}',
                  semanticLabel: l10n.recommendationScoreSemantic(rec.score),
                  icon: Icons.insights_rounded,
                  color: AppColors.ocean,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if ((rec.reasonText ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.recommendationDetailReason,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                rec.reasonText!.trim(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (rec.generatedAt != null)
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: l10n.recommendationDetailGenerated(
                  df.format(rec.generatedAt!.toLocal()),
                ),
              ),
            if (rec.expiresAt != null)
              _DetailRow(
                icon: Icons.event_busy_rounded,
                label: l10n.recommendationDetailExpires(
                  df.format(rec.expiresAt!.toLocal()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
