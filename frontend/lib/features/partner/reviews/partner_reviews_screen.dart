import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/mock/app_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_radii.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../widgets/partner_metric_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_reviews_state.dart';

/// The Partner Reviews module (C12) — the `reviews` destination.
///
/// ## What the backend actually gives a partner
///
/// | Capability | Endpoint | C12 |
/// |---|---|---|
/// | Reply (create or replace) | `PUT /api/partner/reviews/{id}/reply` | ✅ |
/// | List a property's reviews | `GET /api/places/{placeId}/reviews` (public) | ✅ reused from UI-29 |
/// | Read a review's text | — | ⛔ 403 to a partner |
/// | Delete a reply | — | ⛔ no endpoint |
/// | Moderate / hide / flag | — | ⛔ admin-only |
///
/// **A partner cannot read a review's body.** `ReviewService.getReview` gates
/// `GET /api/reviews/{id}` on `checkOwnerOrAdmin` against the review's *author*,
/// so a partner is refused with 403. The screen says this plainly instead of
/// leaving an operator to wonder why they are replying to a title and a rating.
///
/// Aggregate rating and moderation counts belong to C11's Analytics module and
/// are not restated here.
class PartnerReviewsScreen extends StatefulWidget {
  const PartnerReviewsScreen({super.key});

  @override
  State<PartnerReviewsScreen> createState() => _PartnerReviewsScreenState();
}

class _PartnerReviewsScreenState extends State<PartnerReviewsScreen> {
  PartnerReviewsState? _reviews;
  PartnerState? _partner;
  int? _syncedPropertyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    final rebind = !identical(partner, _partner);
    if (rebind) {
      _partner = partner;
      _reviews?.dispose();
      _reviews = PartnerReviewsState(api: partner.api);
      _syncedPropertyId = null;
    }

    final selected = partner.selectedPropertyId;
    if (partner.isReady && (rebind || selected != _syncedPropertyId)) {
      _syncedPropertyId = selected;
      final reviews = _reviews!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) reviews.load(partner, selected);
      });
    }
  }

  @override
  void dispose() {
    _reviews?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final reviews = _reviews;

    if (!partner.isReady || reviews == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return AnimatedBuilder(
      animation: reviews,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OceanGlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.partnerReviewsTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.partnerReviewsAnalyticsPointer,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Body(partner: partner, reviews: reviews),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final PartnerState partner;
  final PartnerReviewsState reviews;

  const _Body({required this.partner, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (reviews.status) {
      case PartnerReviewsStatus.noProperty:
        return OceanStateView(
          icon: Icons.apartment_outlined,
          title: l10n.partnerReviewsNoPropertyTitle,
          message: l10n.partnerReviewsNoPropertyMessage,
          semanticLabel: l10n.partnerReviewsNoPropertyTitle,
        );
      case PartnerReviewsStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
            status: PartnerWorkspaceStatus.unauthorized);
      case PartnerReviewsStatus.forbidden:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.forbidden,
          detail: reviews.errorMessage,
          onPrimaryAction: () => reviews.refresh(partner),
        );
      case PartnerReviewsStatus.notFound:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.onboardingRequired,
          onPrimaryAction: () => reviews.refresh(partner),
        );
      case PartnerReviewsStatus.error:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.error,
          detail: reviews.errorMessage,
          onPrimaryAction: () => reviews.refresh(partner),
        );
      case PartnerReviewsStatus.idle:
      case PartnerReviewsStatus.loading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(partner: partner, reviews: reviews),
            const SizedBox(height: AppSpacing.md),
            const _ReviewsLoading(),
          ],
        );
      case PartnerReviewsStatus.ready:
        break;
    }

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppBreakpoints.desktop;
    final open = reviews.openReview;

    if (reviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(partner: partner, reviews: reviews),
          const SizedBox(height: AppSpacing.md),
          OceanStateView(
            icon: Icons.rate_review_outlined,
            title: l10n.partnerReviewsEmptyTitle,
            message: l10n.partnerReviewsEmptyMessage,
            semanticLabel: l10n.partnerReviewsEmptyTitle,
          ),
        ],
      );
    }

    final list = reviews.isFilteredEmpty
        ? OceanStateView(
            icon: Icons.filter_alt_off_outlined,
            title: l10n.partnerReviewsNoMatchTitle,
            message: l10n.partnerReviewsNoMatchMessage,
            semanticLabel: l10n.partnerReviewsNoMatchTitle,
            actionLabel: l10n.partnerReviewsFilterAll,
            onAction: () => reviews.setFilter(PartnerReviewFilter.all),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final review in reviews.visibleReviews)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ReviewCard(
                    review: review,
                    open: open?.id == review.id,
                    onOpen: () => reviews.openReviewDetail(review.id),
                  ),
                ),
            ],
          );

    final detail = open == null
        ? null
        : _ReplyPanel(partner: partner, reviews: reviews, review: open);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(partner: partner, reviews: reviews),
        const SizedBox(height: AppSpacing.md),
        // The review body is never available to a partner; saying so once, up
        // front, is better than an operator hunting for a missing field.
        PartnerMetricNotice(message: l10n.partnerReviewsNoBodyNotice),
        const SizedBox(height: AppSpacing.md),
        if (isDesktop && detail != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: list),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 3, child: detail),
            ],
          )
        else ...[
          list,
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.md),
            detail,
          ],
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final PartnerState partner;
  final PartnerReviewsState reviews;

  const _Header({required this.partner, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  // The list is the property's public approved list; that is
                  // exactly the set a reply is allowed on.
                  l10n.partnerReviewsScopeNote,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              IconButton(
                onPressed:
                    reviews.isLoading ? null : () => reviews.refresh(partner),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.partnerActionRefresh,
              ),
            ],
          ),
          if (reviews.isReady && reviews.reviews.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final filter in PartnerReviewFilter.values)
                  ChoiceChip(
                    label: Text(switch (filter) {
                      PartnerReviewFilter.all =>
                        l10n.partnerReviewsFilterAllCount(
                            '${reviews.reviews.length}'),
                      PartnerReviewFilter.needsReply =>
                        l10n.partnerReviewsFilterNeedsReplyCount(
                            '${reviews.needsReplyCount}'),
                      PartnerReviewFilter.replied =>
                        l10n.partnerReviewsFilterRepliedCount(
                            '${reviews.repliedCount}'),
                    }),
                    selected: reviews.filter == filter,
                    onSelected: (_) => reviews.setFilter(filter),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: reviews.filter == filter
                          ? AppColors.textInverse
                          : AppColors.textPrimary,
                    ),
                    selectedColor: AppColors.ocean700,
                    backgroundColor: AppColors.surfaceMuted,
                    showCheckmark: false,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewsLoading extends StatelessWidget {
  const _ReviewsLoading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.partnerStatusLoadingTitle,
      liveRegion: true,
      child: OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One review, showing only the fields a partner can actually see.
class _ReviewCard extends StatelessWidget {
  final ReviewSummaryRecord review;
  final bool open;
  final VoidCallback onOpen;

  const _ReviewCard({
    required this.review,
    required this.open,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale);
    final replied = review.partnerReply != null;

    return Semantics(
      button: true,
      label: [
        if (review.ratingOverall != null)
          l10n.partnerReviewsRatingValue('${review.ratingOverall}'),
        review.title ?? l10n.partnerReviewsNoTitle,
        replied ? l10n.partnerReviewsReplied : l10n.partnerReviewsNeedsReply,
      ].join('. '),
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: open ? AppColors.ocean600 : AppColors.divider,
              width: open ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (review.ratingOverall != null) ...[
                          const Icon(Icons.star_rounded,
                              size: 18, color: AppColors.warning),
                          const SizedBox(width: 2),
                          Text(
                            '${review.ratingOverall}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Expanded(
                          child: Text(
                            review.title ?? l10n.partnerReviewsNoTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        OceanStatusPill(
                          label: replied
                              ? l10n.partnerReviewsReplied
                              : l10n.partnerReviewsNeedsReply,
                          color:
                              replied ? AppColors.success : AppColors.warning,
                          icon: replied
                              ? Icons.reply_rounded
                              : Icons.mark_chat_unread_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      [
                        if (review.userName.isNotEmpty) review.userName,
                        if (review.createdAt != null)
                          date.format(review.createdAt!),
                      ].join(' · '),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The reply composer for one review.
class _ReplyPanel extends StatefulWidget {
  final PartnerState partner;
  final PartnerReviewsState reviews;
  final ReviewSummaryRecord review;

  const _ReplyPanel({
    required this.partner,
    required this.reviews,
    required this.review,
  });

  @override
  State<_ReplyPanel> createState() => _ReplyPanelState();
}

class _ReplyPanelState extends State<_ReplyPanel> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.review.partnerReply?.content ?? '');
  int? _loadedFor;

  @override
  void initState() {
    super.initState();
    _loadedFor = widget.review.id;
  }

  @override
  void didUpdateWidget(covariant _ReplyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different review, or a reply that changed server-side, replaces the
    // draft — a stale draft beside another review would be worse than losing it.
    if (_loadedFor != widget.review.id) {
      _loadedFor = widget.review.id;
      _controller.text = widget.review.partnerReply?.content ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateTime = DateFormat.yMMMd(locale).add_Hm();
    final review = widget.review;
    final reply = review.partnerReply;
    final canReply = widget.reviews.canReplyTo(review);
    final pending = widget.reviews.pendingReplyId == review.id;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.partnerReviewsReplyHeading,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.reviews.closeDetail,
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.partnerReviewsCloseReply,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            review.title ?? l10n.partnerReviewsNoTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (reply != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.partnerReviewsCurrentReply,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reply.content,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    [
                      if (reply.partnerDisplayName != null)
                        reply.partnerDisplayName!,
                      if (reply.repliedAt != null)
                        l10n.partnerReviewsRepliedAt(
                            dateTime.format(reply.repliedAt!)),
                      if (reply.updatedAt != null &&
                          reply.updatedAt != reply.repliedAt)
                        l10n.partnerReviewsEditedAt(
                            dateTime.format(reply.updatedAt!)),
                    ].join(' · '),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!canReply)
            PartnerMetricNotice(
              warning: true,
              message: l10n.partnerReviewsNotApprovedNotice,
            )
          else ...[
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 8,
              maxLength: 5000,
              decoration: InputDecoration(
                labelText: l10n.partnerReviewsReplyField,
                helperText: l10n.partnerReviewsReplyHelp,
                helperMaxLines: 3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // The reply is public and there is no delete endpoint — an operator
            // must know that before pressing publish.
            PartnerMetricNotice(message: l10n.partnerReviewsPublicNotice),
            const SizedBox(height: AppSpacing.sm),
            if (pending)
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OceanPrimaryButton(
                  label: reply == null
                      ? l10n.partnerReviewsPublishReply
                      : l10n.partnerReviewsUpdateReply,
                  fullWidth: false,
                  onPressed: () => _confirmAndSend(context, reply != null),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmAndSend(BuildContext context, bool isEdit) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final content = _controller.text;

    if (content.trim().isEmpty) {
      messenger?.showSnackBar(
          SnackBar(content: Text(l10n.partnerReviewsReplyEmpty)));
      return;
    }

    // Publishing is public and cannot be undone, so it is confirmed explicitly.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit
            ? l10n.partnerReviewsUpdateReply
            : l10n.partnerReviewsPublishReply),
        content: Text(l10n.partnerReviewsPublishConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.partnerBookingActionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.partnerBookingActionConfirmCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await widget.reviews.submitReply(
      partner: widget.partner,
      reviewId: widget.review.id,
      content: content,
    );
    if (!context.mounted) return;

    messenger?.showSnackBar(SnackBar(
      content: Text(switch (result) {
        PartnerReplyResult.success => l10n.partnerReviewsReplyPublished,
        PartnerReplyResult.unauthorized =>
          l10n.partnerDashboardErrorUnauthorized,
        PartnerReplyResult.forbidden => l10n.partnerDashboardErrorForbidden,
        PartnerReplyResult.notFound => l10n.partnerReviewsNotFound,
        PartnerReplyResult.notReplyable => l10n.partnerReviewsNotApprovedNotice,
        PartnerReplyResult.validation => l10n.partnerReviewsReplyEmpty,
        PartnerReplyResult.uncertain => l10n.partnerReviewsReplyUncertain,
        PartnerReplyResult.failed => l10n.partnerPropertyActionFailed,
      }),
    ));
  }
}
