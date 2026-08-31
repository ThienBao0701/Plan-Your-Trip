import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
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
/// Moderation itself (`PATCH /api/admin/reviews/{id}/moderate`) exists and is
/// audited as of D1a, but is **not** wired in D1b: it changes what the public
/// sees and needs an explicit confirmation flow. A visible notice says so
/// rather than leaving an operator to guess why no control is present.
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
            ? _ReviewsList(rows: state.rows)
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
              Text(l10n.adminReviewReadOnlyNotice,
                  style: Theme.of(context).textTheme.bodySmall),
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

/// Reviews are prose, so a card list reads better than a table at every width —
/// this is the one admin grid that does not switch to a `DataTable`.
class _ReviewsList extends StatelessWidget {
  final List<AdminReviewRow> rows;

  const _ReviewsList({required this.rows});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
              ],
            ),
          ),
        );
      },
    );
  }
}
