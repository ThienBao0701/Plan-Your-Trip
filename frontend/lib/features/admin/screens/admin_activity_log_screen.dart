import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_feature_states.dart';
import '../widgets/admin_widgets.dart';

/// The administrative audit trail — `GET /api/admin/activity-logs`, added in
/// D1a to close the D0-1 finding that all 111 admin mutations were unrecorded.
///
/// Three properties of this screen are deliberate:
///
///  * **No sort control.** Ordering is fixed newest-first by the backend and is
///    not client-controllable; the trail has no sort-injection surface, and
///    offering a control the server would ignore would misrepresent that.
///  * **No mutation of any kind.** The trail is append-only by construction —
///    the backend repository exposes no delete method — so an administrator
///    cannot rewrite the record of their own actions from here or anywhere.
///  * **Fields are rendered verbatim.** `beforeState`/`afterState` are short
///    safe scalars by backend policy, which additionally refuses to store
///    credential-shaped text; the client displays them as opaque strings and
///    never interprets or re-resolves them.
class AdminActivityLogScreen extends StatelessWidget {
  final AdminActivityLogState state;

  const AdminActivityLogScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final body = state.isReady && !state.isEmpty
            ? _ActivityList(rows: state.rows)
            : AdminStateView(
                status: state.status,
                message: state.errorMessage,
                emptyMessage: l10n.adminActivityEmpty,
                onRetry: state.refresh,
              );

        return AdminGridScaffold(
          isLoading: state.isLoading,
          page: state.isReady ? state.page : null,
          onPageChanged: state.goToPage,
          toolbar: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adminActivityFixedOrder,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              AdminFilterChips(
                values: AdminActivityLogState.knownActions,
                selected: state.actionFilter,
                enabled: !state.isLoading,
                onChanged: state.setActionFilter,
                labelOf: (_, v) => v,
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List<AdminActivityLogRow> rows;

  const _ActivityList({required this.rows});

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
        final actor = r.isSystemActor
            ? l10n.adminActivitySystemActor
            : AdminFormats.text(context, r.actorEmail);

        return OceanGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      r.isSystemActor
                          ? Icons.settings_suggest_outlined
                          : Icons.person_outline,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Both texts flex: an action verb and a timestamp together
                    // exceed 320dp, so neither may claim its natural width.
                    Expanded(
                      flex: 3,
                      child: Text(
                        AdminFormats.text(context, r.action),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      flex: 2,
                      child: Text(
                        AdminFormats.dateTime(context, r.createdAt),
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AdminCardRow(label: l10n.adminActivityActor, value: actor),
                AdminCardRow(
                  label: l10n.adminActivityTarget,
                  value: r.targetType == null
                      ? AdminFormats.text(context, null)
                      : '${r.targetType}'
                          '${r.targetId == null ? '' : ' #${r.targetId}'}',
                ),
                if (r.description != null)
                  AdminCardRow(
                      label: l10n.adminActivityDescription,
                      value: r.description!),
                if (r.hasStateTransition)
                  AdminCardRow(
                    label: l10n.adminActivityBefore,
                    value: '${AdminFormats.text(context, r.beforeState)} → '
                        '${AdminFormats.text(context, r.afterState)}',
                    emphasise: true,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
