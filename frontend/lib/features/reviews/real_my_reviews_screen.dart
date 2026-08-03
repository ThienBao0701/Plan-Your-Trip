import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'review_widgets.dart';

/// UI29 — the authenticated user's own reviews (`GET /api/me/reviews`). Shows the
/// honest moderation status (PENDING/APPROVED/REJECTED) per review. Read-only.
class RealMyReviewsScreen extends StatefulWidget {
  const RealMyReviewsScreen({super.key});

  @override
  State<RealMyReviewsScreen> createState() => _RealMyReviewsScreenState();
}

class _RealMyReviewsScreenState extends State<RealMyReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadMyReviews();
    });
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
        title: Text(l10n.reviewsMineTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    final error = app.myReviewsError;
    if (error == ReviewActionOutcome.sessionExpired && !app.myReviewsLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('my-reviews-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.myReviewsLoading && !app.myReviewsLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.reviewsListLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.reviewsListLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (error != null && !app.myReviewsLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('my-reviews-error'),
          message: l10n.reviewsListErrorMessage,
          onReload: () => app.loadMyReviews(refresh: true),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => app.loadMyReviews(refresh: true),
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
                if (app.realMyReviews.isEmpty)
                  OceanEmptyState(
                    key: const Key('my-reviews-empty'),
                    title: l10n.reviewsMineEmptyTitle,
                    message: l10n.reviewsMineEmptyMessage,
                  )
                else
                  for (final review in app.realMyReviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: RealReviewCard(
                        record: review,
                        showPlace: true,
                        showStatus: true,
                      ),
                    ),
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
