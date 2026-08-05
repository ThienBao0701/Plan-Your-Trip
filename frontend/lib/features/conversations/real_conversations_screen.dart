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
import 'real_conversation_thread_screen.dart';

/// UI41 — Real Mode conversation inbox (`GET /api/me/conversations`). Lists the
/// guest's message threads with a partner (one per booking), newest activity
/// first, and opens a thread. Request/response only — there is no realtime, so
/// the list refreshes on demand. Nothing is fabricated.
class RealConversationsScreen extends StatefulWidget {
  const RealConversationsScreen({super.key});

  @override
  State<RealConversationsScreen> createState() =>
      _RealConversationsScreenState();
}

class _RealConversationsScreenState extends State<RealConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealConversations();
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
        title: Text(l10n.conversationsTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    if (app.realConversationsError == ConversationOutcome.sessionExpired &&
        !app.realConversationsLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('conversations-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realConversationsLoading && !app.realConversationsLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.conversationsLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                key: Key('conversations-loading'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.conversationsLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realConversationsError != null && !app.realConversationsLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('conversations-error'),
          message: l10n.conversationsErrorMessage,
          onReload: () => app.loadRealConversations(refresh: true),
        ),
      );
    }
    final locale = Localizations.localeOf(context).toString();
    return RefreshIndicator(
      onRefresh: () => app.loadRealConversations(refresh: true),
      child: ListView(
        key: const Key('conversations-content'),
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
                if (app.realConversations.isEmpty)
                  OceanEmptyState(
                    key: const Key('conversations-empty'),
                    title: l10n.conversationsEmptyTitle,
                    message: l10n.conversationsEmptyMessage,
                  )
                else
                  for (final c in app.realConversations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ConversationTile(
                        summary: c,
                        locale: locale,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RealConversationThreadScreen(
                              conversationId: c.id,
                            ),
                          ),
                        ),
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

// ── Status presentation (text + colour, never colour-only) ────────────────────

String conversationStatusLabel(
  AppLocalizations l10n,
  ConversationStatusView v,
) {
  return switch (v) {
    ConversationStatusView.open => l10n.conversationStatusOpen,
    ConversationStatusView.closed => l10n.conversationStatusClosed,
    ConversationStatusView.archived => l10n.conversationStatusArchived,
    ConversationStatusView.unknown => l10n.conversationStatusOpen,
  };
}

Color conversationStatusColor(ConversationStatusView v) {
  return switch (v) {
    ConversationStatusView.open => AppColors.success,
    ConversationStatusView.closed => AppColors.slate,
    ConversationStatusView.archived => AppColors.slate,
    ConversationStatusView.unknown => AppColors.slate,
  };
}

class _ConversationTile extends StatelessWidget {
  final RealConversationSummary summary;
  final String locale;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.summary,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = (summary.subject ?? '').trim().isNotEmpty
        ? summary.subject!.trim()
        : (summary.bookingCode?.trim().isNotEmpty == true
            ? l10n.conversationBookingLabel(summary.bookingCode!.trim())
            : l10n.conversationUntitled);
    final preview = (summary.lastMessagePreview ?? '').trim();
    final when = summary.lastMessageAt != null
        ? DateFormat.MMMd(locale).add_jm().format(
              summary.lastMessageAt!.toLocal(),
            )
        : null;
    return OceanGlassCard(
      key: Key('conversation-tile-${summary.id}'),
      onTap: onTap,
      semanticLabel: l10n.conversationTileSemantic(
        title,
        summary.unreadCount,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (when != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        when,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    preview,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OceanStatusPill(
                      label: conversationStatusLabel(l10n, summary.statusView),
                      icon: Icons.forum_rounded,
                      color: conversationStatusColor(summary.statusView),
                    ),
                    if (summary.unreadCount > 0)
                      OceanStatusPill(
                        label:
                            l10n.conversationUnreadBadge(summary.unreadCount),
                        semanticLabel:
                            l10n.conversationUnreadBadge(summary.unreadCount),
                        icon: Icons.mark_chat_unread_rounded,
                        color: AppColors.ocean,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.xs),
            child: Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
