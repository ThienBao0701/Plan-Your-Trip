import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';

/// A read-only 1–5 star display with a single localized semantic label (so a
/// screen reader announces "4 of 5", not five separate icons).
class ReviewStars extends StatelessWidget {
  final int rating;
  final double size;

  const ReviewStars({super.key, required this.rating, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clamped = rating.clamp(0, 5);
    return Semantics(
      label: l10n.reviewStarsSemantic(clamped),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                i <= clamped ? Icons.star_rounded : Icons.star_border_rounded,
                size: size,
                color: AppColors.warning,
              ),
          ],
        ),
      ),
    );
  }
}

/// Localized label for a review status. Only used where a status can be
/// non-approved (the user's own reviews); public place reviews are always
/// approved. Unknown values fall back to the raw server string honestly.
String reviewStatusLabel(
  AppLocalizations l10n,
  ReviewStatusView view,
  String raw,
) {
  switch (view) {
    case ReviewStatusView.pending:
      return l10n.reviewStatusPending;
    case ReviewStatusView.approved:
      return l10n.reviewStatusApproved;
    case ReviewStatusView.rejected:
      return l10n.reviewStatusRejected;
    case ReviewStatusView.hidden:
      return l10n.reviewStatusHidden;
    case ReviewStatusView.reported:
      return l10n.reviewStatusReported;
    case ReviewStatusView.unknown:
      return raw.trim().isEmpty ? l10n.reviewStatusUnknown : raw.trim();
  }
}

/// A status chip (icon + text, never colour alone) for a review's moderation
/// status. Shown on the user's own reviews so PENDING/REJECTED are honest.
class ReviewStatusChip extends StatelessWidget {
  final ReviewStatusView view;
  final String rawStatus;

  const ReviewStatusChip({
    super.key,
    required this.view,
    required this.rawStatus,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (IconData icon, Color color) = switch (view) {
      ReviewStatusView.approved => (Icons.verified_rounded, AppColors.success),
      ReviewStatusView.pending => (
          Icons.hourglass_top_rounded,
          AppColors.ocean
        ),
      ReviewStatusView.rejected ||
      ReviewStatusView.hidden ||
      ReviewStatusView.reported =>
        (Icons.visibility_off_rounded, AppColors.coral),
      ReviewStatusView.unknown => (Icons.help_outline_rounded, AppColors.ocean),
    };
    return OceanStatusPill(
      label: reviewStatusLabel(l10n, view, rawStatus),
      icon: icon,
      color: color,
    );
  }
}

/// One review row shared by the place-reviews and my-reviews lists. Renders only
/// backend fields — reviewer/place name, overall rating, title, date, moderation
/// status (when [showStatus]) and the property's reply (when present). Nothing is
/// fabricated. When [showPlace] the header is the place name (my-reviews); else
/// the reviewer name (a place's public reviews).
class RealReviewCard extends StatelessWidget {
  final ReviewSummaryRecord record;
  final bool showPlace;
  final bool showStatus;

  const RealReviewCard({
    super.key,
    required this.record,
    this.showPlace = false,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final header = showPlace
        ? (record.placeName.trim().isEmpty
            ? l10n.reviewUnknownPlace
            : record.placeName)
        : (record.userName.trim().isEmpty
            ? l10n.reviewAnonymousReviewer
            : record.userName);
    final reply = record.partnerReply;
    return OceanGlassCard(
      key: Key('real-review-card-${record.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(header,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (showStatus) ...[
                const SizedBox(width: AppSpacing.sm),
                ReviewStatusChip(
                  view: record.statusView,
                  rawStatus: record.status,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (record.ratingOverall != null)
            ReviewStars(rating: record.ratingOverall!),
          if ((record.title ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(record.title!.trim(),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
          if (record.createdAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              date.format(record.createdAt!.toLocal()),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.slate),
            ),
          ],
          if (reply != null && reply.content.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            OceanGlassSurface(
              blur: 0,
              color: AppColors.paleCyan,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded,
                          color: AppColors.ocean, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          (reply.partnerDisplayName ?? '').trim().isEmpty
                              ? l10n.reviewPartnerReplyTitle
                              : reply.partnerDisplayName!.trim(),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(reply.content.trim(),
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
