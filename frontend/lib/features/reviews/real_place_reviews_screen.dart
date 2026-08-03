import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'review_widgets.dart';

/// UI29 — a place's PUBLIC reviews (`GET /api/places/{id}/reviews`). The backend
/// returns approved reviews only, so no moderation status is shown. Read-only.
class RealPlaceReviewsScreen extends StatefulWidget {
  final int placeId;
  final String placeName;

  const RealPlaceReviewsScreen({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  State<RealPlaceReviewsScreen> createState() => _RealPlaceReviewsScreenState();
}

class _RealPlaceReviewsScreenState extends State<RealPlaceReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadPlaceReviews(widget.placeId);
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
        title: Text(
          widget.placeName.trim().isEmpty
              ? l10n.placeReviewsTitle
              : widget.placeName,
        ),
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    final error = app.placeReviewsError;
    if (error == ReviewActionOutcome.sessionExpired &&
        !app.placeReviewsLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('place-reviews-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.placeReviewsLoading && !app.placeReviewsLoaded) {
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
    if (error != null && !app.placeReviewsLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('place-reviews-error'),
          message: l10n.reviewsListErrorMessage,
          onReload: () => app.loadPlaceReviews(widget.placeId, refresh: true),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => app.loadPlaceReviews(widget.placeId, refresh: true),
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
                if (app.placeReviews.isEmpty)
                  OceanEmptyState(
                    key: const Key('place-reviews-empty'),
                    title: l10n.placeReviewsEmptyTitle,
                    message: l10n.placeReviewsEmptyMessage,
                  )
                else
                  for (final review in app.placeReviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: RealReviewCard(record: review),
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
