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
import 'real_conversations_screen.dart' show conversationStatusLabel;

/// UI41 — Real Mode conversation thread (`GET /api/me/conversations/{id}`). Shows
/// the message history (backend order, oldest first), lets the guest send a
/// message, marks incoming messages read on open, and closes the thread. No
/// realtime — the thread refreshes on send / pull-to-refresh.
class RealConversationThreadScreen extends StatefulWidget {
  final int conversationId;

  const RealConversationThreadScreen({super.key, required this.conversationId});

  @override
  State<RealConversationThreadScreen> createState() =>
      _RealConversationThreadScreenState();
}

class _RealConversationThreadScreenState
    extends State<RealConversationThreadScreen> {
  final TextEditingController _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openThread());
  }

  Future<void> _openThread() async {
    if (!mounted) return;
    final app = AppScope.of(context);
    final outcome = await app.loadRealConversationDetail(widget.conversationId);
    if (!mounted) return;
    // Opening a thread reads its incoming messages (best-effort).
    if (outcome == ConversationOutcome.success) {
      unawaited(app.markRealConversationRead(widget.conversationId));
    }
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
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

  String _messageForOutcome(AppLocalizations l10n, ConversationOutcome o) {
    return switch (o) {
      ConversationOutcome.forbidden => l10n.conversationForbiddenMessage,
      ConversationOutcome.notFound => l10n.conversationGoneMessage,
      ConversationOutcome.unprocessable => l10n.conversationArchivedMessage,
      ConversationOutcome.validation => l10n.conversationEmptyBodyMessage,
      ConversationOutcome.network => l10n.conversationNetworkMessage,
      _ => l10n.conversationActionErrorMessage,
    };
  }

  Future<void> _send(AppState app) async {
    final l10n = AppLocalizations.of(context)!;
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    final outcome = await app.sendRealMessage(widget.conversationId, text);
    if (!mounted) return;
    switch (outcome) {
      case ConversationOutcome.success:
        _composer.clear();
      case ConversationOutcome.sessionExpired:
        _reauth();
      case ConversationOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _close(AppState app) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.conversationCloseConfirmTitle),
        content: Text(l10n.conversationCloseConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('conversation-close-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.lock_outline_rounded),
            label: Text(l10n.conversationCloseAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.closeRealConversation(widget.conversationId);
    if (!mounted) return;
    switch (outcome) {
      case ConversationOutcome.success:
        _snack(l10n.conversationClosedMessage);
      case ConversationOutcome.sessionExpired:
        _reauth();
      case ConversationOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final conv = app.realConversationDetailFor(widget.conversationId);
    final isArchived = conv?.statusView == ConversationStatusView.archived;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(_titleFor(l10n, conv)),
        actions: [
          if (conv != null && conv.statusView == ConversationStatusView.open)
            IconButton(
              key: const Key('conversation-close'),
              tooltip: l10n.conversationCloseAction,
              onPressed:
                  app.realConversationMutating ? null : () => _close(app),
              icon: const Icon(Icons.lock_outline_rounded),
            ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(child: _body(context, app, l10n, conv)),
              if (conv != null && !isArchived)
                _Composer(
                  controller: _composer,
                  sending: app.realConversationSending,
                  onSend: () => _send(app),
                ),
              if (isArchived)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    l10n.conversationArchivedNote,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(AppLocalizations l10n, RealConversation? conv) {
    if (conv == null) return l10n.conversationsTitle;
    if ((conv.subject ?? '').trim().isNotEmpty) return conv.subject!.trim();
    if ((conv.partnerBusinessName ?? '').trim().isNotEmpty) {
      return conv.partnerBusinessName!.trim();
    }
    if ((conv.bookingCode ?? '').trim().isNotEmpty) {
      return l10n.conversationBookingLabel(conv.bookingCode!.trim());
    }
    return l10n.conversationsTitle;
  }

  Widget _body(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
    RealConversation? conv,
  ) {
    if (app.realConversationDetailError == ConversationOutcome.sessionExpired &&
        conv == null) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('conversation-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realConversationDetailLoading && conv == null) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.conversationLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('conversation-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.conversationLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (conv == null) {
      final err = app.realConversationDetailError;
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('conversation-error'),
          message: err == ConversationOutcome.forbidden
              ? l10n.conversationForbiddenMessage
              : err == ConversationOutcome.notFound
                  ? l10n.conversationGoneMessage
                  : l10n.conversationErrorMessage,
          onReload: () => app.loadRealConversationDetail(
            widget.conversationId,
            refresh: true,
          ),
        ),
      );
    }
    final locale = Localizations.localeOf(context).toString();
    return RefreshIndicator(
      onRefresh: () => app.loadRealConversationDetail(
        widget.conversationId,
        refresh: true,
      ),
      child: ListView(
        key: const Key('conversation-content'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  conversationStatusLabel(l10n, conv.statusView),
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (conv.messages.isEmpty)
                  OceanEmptyState(
                    key: const Key('conversation-empty'),
                    title: l10n.conversationNoMessagesTitle,
                    message: l10n.conversationNoMessagesMessage,
                  )
                else
                  for (final m in conv.messages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _MessageBubble(message: m, locale: locale),
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

class _MessageBubble extends StatelessWidget {
  final RealMessage message;
  final String locale;

  const _MessageBubble({required this.message, required this.locale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mine = message.isFromUser;
    final when = message.createdAt != null
        ? DateFormat.MMMd(locale).add_jm().format(message.createdAt!.toLocal())
        : null;
    final sender = mine
        ? l10n.conversationSenderYou
        : ((message.senderName ?? '').trim().isNotEmpty
            ? message.senderName!.trim()
            : _roleLabel(l10n, message.senderRoleView));
    final bubbleColor = mine
        ? AppColors.ocean.withValues(alpha: 0.12)
        : AppColors.slate.withValues(alpha: 0.10);
    return Semantics(
      label: l10n.conversationMessageSemantic(sender, message.body),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                sender,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(message.body, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (when != null)
                    Text(
                      when,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  if (mine && message.readByPartner) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.done_all_rounded,
                        size: 14, color: AppColors.ocean),
                    const SizedBox(width: 2),
                    Text(
                      l10n.conversationSeen,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.ocean),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(AppLocalizations l10n, MessageSenderRoleView v) {
    return switch (v) {
      MessageSenderRoleView.partner => l10n.conversationSenderHost,
      MessageSenderRoleView.admin => l10n.conversationSenderSupport,
      MessageSenderRoleView.system => l10n.conversationSenderSystem,
      _ => l10n.conversationSenderHost,
    };
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: OceanContentConstraint(
        maxWidth: AppBreakpoints.maxContentWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('conversation-composer'),
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.conversationComposerHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              key: const Key('conversation-send'),
              tooltip: l10n.conversationSendSemantic,
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
