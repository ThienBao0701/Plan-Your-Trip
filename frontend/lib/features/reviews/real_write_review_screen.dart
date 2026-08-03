import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';

/// UI29 — submit a real review for a COMPLETED booking (`POST /api/reviews`).
/// The overall rating is required (1–5); sub-ratings, title and comment are
/// optional (matching `ReviewDto.ReviewRequest`). A created review is PENDING —
/// it is not shown publicly until a moderator approves it, and this screen says
/// so honestly rather than implying it is live.
class RealWriteReviewScreen extends StatefulWidget {
  final int bookingId;
  final String placeName;

  const RealWriteReviewScreen({
    super.key,
    required this.bookingId,
    required this.placeName,
  });

  @override
  State<RealWriteReviewScreen> createState() => _RealWriteReviewScreenState();
}

class _RealWriteReviewScreenState extends State<RealWriteReviewScreen> {
  bool _submitted = false;
  int _overall = 0;
  int _cleanliness = 0;
  int _service = 0;
  int _location = 0;
  int _value = 0;
  int _facilities = 0;
  final _title = TextEditingController();
  final _content = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  int? _opt(int v) => v >= 1 ? v : null;

  Future<void> _submit(AppState app) async {
    final payload = ReviewCreatePayload(
      bookingId: widget.bookingId,
      ratingOverall: _overall,
      ratingCleanliness: _opt(_cleanliness),
      ratingService: _opt(_service),
      ratingLocation: _opt(_location),
      ratingValue: _opt(_value),
      ratingFacilities: _opt(_facilities),
      title: _title.text,
      content: _content.text,
    );
    final outcome = await app.submitReview(payload);
    if (!mounted) return;
    switch (outcome) {
      case ReviewActionOutcome.success:
        setState(() => _submitted = true); // Show the PENDING confirmation.
        return;
      case ReviewActionOutcome.busy:
        return;
      case ReviewActionOutcome.sessionExpired:
        _reauth();
        return;
      default:
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              SnackBar(content: Text(_messageForOutcome(l10n, outcome))));
    }
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

  String _messageForOutcome(AppLocalizations l10n, ReviewActionOutcome o) {
    return switch (o) {
      ReviewActionOutcome.alreadyReviewed => l10n.reviewSubmitAlreadyMessage,
      ReviewActionOutcome.notCompleted => l10n.reviewSubmitNotCompletedMessage,
      ReviewActionOutcome.forbidden => l10n.reviewSubmitForbiddenMessage,
      ReviewActionOutcome.notFound => l10n.reviewSubmitNotCompletedMessage,
      ReviewActionOutcome.validation => l10n.reviewSubmitValidationMessage,
      ReviewActionOutcome.network => l10n.reviewSubmitNetworkMessage,
      _ => l10n.reviewSubmitServerErrorMessage,
    };
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
        title: Text(l10n.writeReviewTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: _submitted
              ? _submittedView(context, l10n)
              : _form(context, app, l10n),
        ),
      ),
    );
  }

  Widget _submittedView(BuildContext context, AppLocalizations l10n) {
    return ListView(
      key: const Key('write-review-submitted'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        OceanContentConstraint(
          maxWidth: AppBreakpoints.maxContentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                label:
                    '${l10n.writeReviewPendingHeadline}. ${l10n.writeReviewPendingBody}',
                child: OceanGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded,
                              color: AppColors.ocean),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(l10n.writeReviewPendingHeadline,
                                style: Theme.of(context).textTheme.titleLarge),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(l10n.writeReviewPendingBody,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OceanPrimaryButton(
                key: const Key('write-review-done'),
                label: l10n.bookingResultDoneAction,
                icon: Icons.check_rounded,
                onPressed: () => Navigator.of(context).maybePop(true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _form(BuildContext context, AppState app, AppLocalizations l10n) {
    final submitting = app.reviewSubmitting;
    final canSubmit = _overall >= 1 && !submitting;
    return ListView(
      key: const Key('write-review-form'),
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
              if (widget.placeName.trim().isNotEmpty)
                Text(widget.placeName,
                    style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              OceanGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RatingInput(
                      key: const Key('write-review-overall'),
                      label: l10n.writeReviewOverallLabel,
                      required: true,
                      value: _overall,
                      onChanged: (v) => setState(() => _overall = v),
                    ),
                    const Divider(height: AppSpacing.lg),
                    Text(l10n.writeReviewSubRatingsTitle,
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    _RatingInput(
                      label: l10n.reviewRatingCleanliness,
                      value: _cleanliness,
                      onChanged: (v) => setState(() => _cleanliness = v),
                    ),
                    _RatingInput(
                      label: l10n.reviewRatingService,
                      value: _service,
                      onChanged: (v) => setState(() => _service = v),
                    ),
                    _RatingInput(
                      label: l10n.reviewRatingLocation,
                      value: _location,
                      onChanged: (v) => setState(() => _location = v),
                    ),
                    _RatingInput(
                      label: l10n.reviewRatingValue,
                      value: _value,
                      onChanged: (v) => setState(() => _value = v),
                    ),
                    _RatingInput(
                      label: l10n.reviewRatingFacilities,
                      value: _facilities,
                      onChanged: (v) => setState(() => _facilities = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OceanGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const Key('write-review-title'),
                      controller: _title,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: l10n.writeReviewTitleLabel,
                      ),
                    ),
                    TextField(
                      key: const Key('write-review-content'),
                      controller: _content,
                      maxLength: 5000,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: l10n.writeReviewContentLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OceanGlassSurface(
                blur: 0,
                color: AppColors.paleCyan,
                child: Text(l10n.writeReviewModerationNote,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (submitting) ...[
                Semantics(
                  liveRegion: true,
                  label: l10n.writeReviewSubmittingLabel,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.writeReviewSubmittingLabel),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              OceanPrimaryButton(
                key: const Key('write-review-submit'),
                label: submitting
                    ? l10n.writeReviewSubmittingLabel
                    : l10n.writeReviewSubmitAction,
                icon: Icons.rate_review_rounded,
                semanticLabel: l10n.writeReviewSubmitAction,
                onPressed: canSubmit ? () => _submit(app) : null,
              ),
              if (_overall < 1) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.writeReviewOverallRequiredHint,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.slate),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// An accessible 1–5 star INPUT row (label + tappable stars). Each star is a
/// semantic button ("Rate N of 5") ≥48px; the current value is announced.
class _RatingInput extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool required;

  const _RatingInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              required ? '$label *' : label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          for (var i = 1; i <= 5; i++)
            IconButton(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              tooltip: l10n.writeReviewRateStarSemantic(i),
              onPressed: () => onChanged(i),
              icon: Icon(
                i <= value ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.warning,
              ),
            ),
        ],
      ),
    );
  }
}
