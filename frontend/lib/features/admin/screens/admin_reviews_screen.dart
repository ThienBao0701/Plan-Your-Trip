import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../design/app_radii.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_feature_states.dart';
import '../widgets/admin_widgets.dart';

/// Admin reviews grid — `GET /api/admin/reviews`, paginated in D1a.
///
/// This surface shows the review **body**, which the partner extranet cannot:
/// D0 verified live that `content` is present for an administrator and absent
/// for a partner. That asymmetry is the reason moderation belongs here.
///
/// ## Moderation (D8)
///
/// `PATCH /api/admin/reviews/{id}/moderate` is wired here. It changes what the
/// public sees, so nothing happens on a single tap: Approve, Reject and Hide
/// each open a confirmation that states the consequence, and Reject additionally
/// requires a reason, because the backend forwards it to the review's author.
///
/// The three offered statuses are `APPROVED`, `REJECTED` and `HIDDEN`.
/// `ReviewStatus` also contains `PENDING` and `REPORTED`; neither is offered,
/// because moving a review back to either is not a moderation decision the
/// product defines. The backend imposes **no** transition rules, so the only
/// thing disabled here is the action matching the row's current status — an
/// affordance, not an invented rule.
class AdminReviewsScreen extends StatelessWidget {
  final AdminReviewsState state;

  const AdminReviewsScreen({super.key, required this.state});

  static const List<AdminSortOption> _sorts = [
    AdminSortOption(field: 'createdAt', label: _createdAt),
    AdminSortOption(field: 'ratingOverall', label: _rating),
    AdminSortOption(field: 'status', label: _status),
    AdminSortOption(field: 'approvedAt', label: _approvedAt),
  ];

  static String _createdAt(AppLocalizations l) => l.adminSortCreatedAt;
  static String _rating(AppLocalizations l) => l.adminSortRating;
  static String _status(AppLocalizations l) => l.adminSortStatus;
  static String _approvedAt(AppLocalizations l) => l.adminSortApprovedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final body = state.isReady && !state.isEmpty
            ? _ReviewsList(state: state)
            : AdminStateView(
                status: state.status,
                message: state.errorMessage,
                emptyMessage: l10n.adminReviewsEmpty,
                onRetry: state.refresh,
              );

        return AdminGridScaffold(
          isLoading: state.isLoading,
          page: state.isReady ? state.page : null,
          onPageChanged: state.goToPage,
          toolbar: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adminReviewModerationNotice,
                  key: const Key('admin-reviews-moderation-notice'),
                  style: Theme.of(context).textTheme.bodySmall),
              if (state.moderationUncertain) ...[
                const SizedBox(height: AppSpacing.xs),
                _ModerationBanner(
                  key: const Key('admin-reviews-uncertain'),
                  warning: true,
                  message: l10n.adminReviewModerationUncertain,
                ),
              ] else if (state.moderationError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _ModerationBanner(
                  key: const Key('admin-reviews-error'),
                  warning: false,
                  message: state.moderationError!,
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              AdminFilterChips(
                values: AdminReviewsState.statusValues,
                selected: state.statusFilter,
                enabled: !state.isLoading,
                onChanged: state.setStatusFilter,
                labelOf: (_, v) => v,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AdminSortControl(
                  options: _sorts,
                  selectedField: state.sortField,
                  descending: state.sortDescending,
                  enabled: !state.isLoading,
                  onChanged: state.setSort,
                ),
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }
}

class _ModerationBanner extends StatelessWidget {
  final String message;
  final bool warning;

  const _ModerationBanner({
    super.key,
    required this.message,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = warning ? scheme.tertiary : scheme.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Icon(warning ? Icons.warning_amber_rounded : Icons.error_outline,
              size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Reviews are prose, so a card list reads better than a table at every width —
/// this is the one admin grid that does not switch to a `DataTable`.
class _ReviewsList extends StatelessWidget {
  final AdminReviewsState state;

  const _ReviewsList({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = state.rows;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final r = rows[i];
        return OceanGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        AdminFormats.text(context, r.placeName),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (r.ratingOverall != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16),
                          const SizedBox(width: 2),
                          Text('${r.ratingOverall}'),
                        ],
                      ),
                    const SizedBox(width: AppSpacing.xs),
                    AdminStatusChip(status: r.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (r.title != null)
                  Text(r.title!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                if (r.content != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(r.content!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: AppSpacing.xs),
                AdminCardRow(
                    label: l10n.adminReviewAuthor,
                    value: AdminFormats.text(context, r.userName)),
                AdminCardRow(
                    label: l10n.adminSortCreatedAt,
                    value: AdminFormats.date(context, r.createdAt)),
                if (r.reportedCount > 0)
                  AdminCardRow(
                    label: l10n.adminFilterStatus,
                    value: l10n.adminReviewReported(r.reportedCount),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  r.hasPartnerReply
                      ? l10n.adminReviewPartnerReply
                      : l10n.adminReviewNoReply,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (r.hasPartnerReply)
                  Text(r.partnerReply!.content!,
                      style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                _ModerationActions(state: state, review: r),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModerationActions extends StatelessWidget {
  final AdminReviewsState state;
  final AdminReviewRow review;

  const _ModerationActions({required this.state, required this.review});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (state.isModeratingReview(review.id)) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          key: Key('admin-review-moderating-${review.id}'),
          width: 20,
          height: 20,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Single-flight is global: while any review is being moderated no other
    // action is offered, because a second request would notify another author
    // and write another audit row before the first has settled.
    final busy = state.isModerating;

    Widget action(
        String status, String label, String keySuffix, VoidCallback onPressed) {
      final isCurrent = review.status == status;
      return Tooltip(
        message: isCurrent ? l10n.adminReviewActionCurrent : label,
        child: TextButton(
          key: Key('admin-review-$keySuffix-${review.id}'),
          onPressed: (busy || isCurrent) ? null : onPressed,
          child: Text(label),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        action('APPROVED', l10n.adminReviewApprove, 'approve',
            () => _confirmSimple(context, 'APPROVED')),
        action('REJECTED', l10n.adminReviewReject, 'reject',
            () => _confirmReject(context)),
        action('HIDDEN', l10n.adminReviewHide, 'hide',
            () => _confirmSimple(context, 'HIDDEN')),
      ],
    );
  }

  /// Approve and Hide need only an acknowledgement of the consequence.
  Future<void> _confirmSimple(BuildContext context, String status) async {
    final l10n = AppLocalizations.of(context)!;
    final approving = status == 'APPROVED';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: Key('admin-review-confirm-${status.toLowerCase()}'),
        icon: const Icon(Icons.gavel_rounded),
        title: Text(approving
            ? l10n.adminReviewApproveTitle
            : l10n.adminReviewHideTitle),
        content: Text(approving
            ? l10n.adminReviewApproveWarning
            : l10n.adminReviewHideWarning),
        actions: [
          TextButton(
            key: const Key('admin-review-confirm-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.adminPartnerCancel),
          ),
          FilledButton(
            key: const Key('admin-review-confirm-ok'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(approving
                ? l10n.adminReviewApproveConfirm
                : l10n.adminReviewHideConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _send(context, status: status);
  }

  /// Rejecting forwards a reason to the review's author, so the dialog collects
  /// one and refuses to submit without it.
  Future<void> _confirmReject(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RejectDialog(),
    );
    if (reason == null || !context.mounted) return;
    await _send(context, status: 'REJECTED', rejectReason: reason);
  }

  Future<void> _send(
    BuildContext context, {
    required String status,
    String? rejectReason,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await state.moderate(
      review.id,
      status: status,
      rejectReason: rejectReason,
    );
    if (!context.mounted) return;
    // The uncertain case has its own persistent banner; a transient snackbar
    // would understate it.
    if (!ok && state.moderationUncertain) return;
    messenger?.showSnackBar(SnackBar(
      content: Text(
          ok ? l10n.adminReviewModerated : l10n.adminReviewModerationFailed),
    ));
  }
}

/// Returns the trimmed reason on confirm, or null on cancel.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      key: const Key('admin-review-confirm-rejected'),
      icon: Icon(Icons.gavel_rounded, color: scheme.error),
      title: Text(l10n.adminReviewRejectTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.adminReviewRejectWarning),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('admin-review-reject-reason'),
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
            decoration: InputDecoration(
              labelText: l10n.adminReviewRejectReasonLabel,
              helperText: l10n.adminReviewRejectReasonHelp,
              helperMaxLines: 2,
              errorText:
                  _showError ? l10n.adminReviewRejectReasonRequired : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('admin-review-confirm-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.adminPartnerCancel),
        ),
        FilledButton(
          key: const Key('admin-review-confirm-ok'),
          onPressed: _submit,
          child: Text(l10n.adminReviewRejectConfirm),
        ),
      ],
    );
  }
}
