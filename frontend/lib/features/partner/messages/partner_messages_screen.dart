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
import 'partner_messages_state.dart';

/// The Partner Messages module (D5) — the `messages` destination.
///
/// ## Why this module exists
///
/// The backend already told the operator to be here: `PartnerExtranetService`
/// publishes `MenuItem("messages", …, enabled: true, unreadMessages)` and emits
/// a "Reply to guest messages" quick action whenever the count is above zero.
/// Guests could open a thread and write into it; no host could read or answer.
/// This module closes that, and changes nothing on the server.
///
/// ## What the backend gives a partner
///
/// | Capability | Endpoint | D5 |
/// |---|---|---|
/// | List threads | `GET /api/partner/conversations` | ✅ |
/// | Read a thread | `GET /api/partner/conversations/{id}` | ✅ |
/// | Reply as host | `POST /api/partner/conversations/{id}/messages` (201) | ✅ |
/// | Mark read | `PATCH /api/partner/conversations/{id}/read` | ✅ |
/// | Close | `PATCH /api/partner/conversations/{id}/close` | ⛔ excluded |
/// | Start a thread | — | ⛔ guests only |
///
/// ## The inbox row cannot show the guest's name
///
/// `ConversationSummaryResponse` carries `bookingCode`, `subject`, a preview and
/// `unreadCount` — but **no `userName`**. Only the thread response
/// (`ConversationResponse`) identifies the guest. Rows are therefore titled by
/// subject and booking, and the guest's name appears once the thread is open.
/// Inventing a name in the list would be exactly the fabricated data this
/// project forbids.
class PartnerMessagesScreen extends StatefulWidget {
  const PartnerMessagesScreen({super.key});

  @override
  State<PartnerMessagesScreen> createState() => _PartnerMessagesScreenState();
}

class _PartnerMessagesScreenState extends State<PartnerMessagesScreen> {
  PartnerMessagesState? _messages;
  PartnerState? _partner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    if (identical(partner, _partner)) return;

    _partner = partner;
    _messages?.dispose();
    _messages = PartnerMessagesState(api: partner.api);

    if (partner.isReady) {
      final messages = _messages!;
      // Decision B: refresh on screen entry.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) messages.load();
      });
    }
  }

  @override
  void dispose() {
    _messages?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final messages = _messages;

    // The workspace gate is authoritative — including a suspended membership.
    // A 404 from the module itself is shown as "not available to you".
    if (!partner.isReady || messages == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return AnimatedBuilder(
      animation: messages,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OceanGlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.partnerMessagesTitle,
                  key: const Key('partner-messages-title'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.partnerMessagesSubtitle,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Body(messages: messages),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final PartnerMessagesState messages;

  const _Body({required this.messages});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (messages.status) {
      case PartnerMessagesStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
          key: Key('partner-messages-unauthorized'),
          status: PartnerWorkspaceStatus.unauthorized,
        );
      case PartnerMessagesStatus.forbidden:
        return PartnerWorkspaceStatusView(
          key: const Key('partner-messages-forbidden'),
          status: PartnerWorkspaceStatus.forbidden,
          detail: messages.errorMessage,
          onPrimaryAction: messages.refresh,
        );
      case PartnerMessagesStatus.notFound:
        return PartnerWorkspaceStatusView(
          key: const Key('partner-messages-notfound'),
          status: PartnerWorkspaceStatus.forbidden,
          detail: messages.errorMessage,
        );
      case PartnerMessagesStatus.error:
        return PartnerWorkspaceStatusView(
          key: const Key('partner-messages-error'),
          status: PartnerWorkspaceStatus.error,
          detail: messages.errorMessage,
          onPrimaryAction: messages.refresh,
        );
      case PartnerMessagesStatus.idle:
      case PartnerMessagesStatus.loading:
        return OceanStateView(
          key: const Key('partner-messages-loading'),
          icon: Icons.forum_outlined,
          title: l10n.partnerMessagesTitle,
          message: l10n.partnerMessagesLoading,
          semanticLabel: l10n.partnerMessagesLoading,
          showProgress: true,
        );
      case PartnerMessagesStatus.ready:
        break;
    }

    if (messages.isEmpty) {
      return OceanStateView(
        key: const Key('partner-messages-empty'),
        icon: Icons.forum_outlined,
        title: l10n.partnerMessagesEmptyTitle,
        message: l10n.partnerMessagesEmptyMessage,
        semanticLabel: l10n.partnerMessagesEmptyTitle,
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppBreakpoints.desktop;
    final threadOpen = messages.openConversationId != null;

    final inbox = _Inbox(messages: messages);
    final thread = threadOpen ? _Thread(messages: messages) : null;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: inbox),
          if (thread != null) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 3, child: thread),
          ],
        ],
      );
    }

    // On a narrow layout the thread replaces the inbox — a back control returns.
    return thread ?? inbox;
  }
}

class _Inbox extends StatelessWidget {
  final PartnerMessagesState messages;

  const _Inbox({required this.messages});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unread = messages.totalUnread;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (unread > 0) ...[
          PartnerMetricNotice(
            message: l10n.partnerMessagesUnreadTotal(
                unread, messages.conversations.length),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // The endpoint takes no page or size; saying so is more honest than
        // implying a truncated view.
        PartnerMetricNotice(message: l10n.partnerMessagesUnpaginatedNotice),
        const SizedBox(height: AppSpacing.md),
        for (final conversation in messages.conversations)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ConversationRow(
              conversation: conversation,
              selected: messages.openConversationId == conversation.id,
              onOpen: () => messages.openThread(conversation.id),
            ),
          ),
      ],
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final RealConversationSummary conversation;
  final bool selected;
  final VoidCallback onOpen;

  const _ConversationRow({
    required this.conversation,
    required this.selected,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateTime = DateFormat.yMMMd(locale).add_Hm();
    final code = conversation.bookingCode;
    final unread = conversation.unreadCount;

    return Semantics(
      button: true,
      selected: selected,
      label: code == null ? null : l10n.partnerMessagesOpenSemantic(code),
      child: InkWell(
        key: Key('partner-messages-row-${conversation.id}'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: OceanGlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      conversation.subject ?? l10n.partnerMessagesNoSubject,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (unread > 0)
                    OceanStatusPill(
                      key: Key('partner-messages-unread-${conversation.id}'),
                      label: l10n.partnerMessagesUnreadBadge(unread),
                      color: AppColors.ocean600,
                      icon: Icons.mark_email_unread_outlined,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  if (code != null)
                    Text(
                      l10n.partnerMessagesBookingLabel(code),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  if (code != null) const SizedBox(width: AppSpacing.xs),
                  Text(
                    _statusLabel(l10n, conversation.statusView),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                // Null when the thread has no messages yet — a real state the
                // backend can serve, not an error.
                conversation.lastMessagePreview ??
                    l10n.partnerMessagesNoPreview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              if (conversation.lastMessageAt != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  dateTime.format(conversation.lastMessageAt!),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Thread extends StatefulWidget {
  final PartnerMessagesState messages;

  const _Thread({required this.messages});

  @override
  State<_Thread> createState() => _ThreadState();
}

class _ThreadState extends State<_Thread> {
  final TextEditingController _composer = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Enables/disables the send control as the operator types.
    _composer.addListener(_onComposerChanged);
  }

  void _onComposerChanged() => setState(() {});

  @override
  void dispose() {
    _composer.removeListener(_onComposerChanged);
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final messages = widget.messages;
    final thread = messages.thread;

    if (messages.threadError != null && thread == null) {
      return OceanStateView(
        key: const Key('partner-messages-thread-unavailable'),
        icon: Icons.forum_outlined,
        // Uniform for "unknown" and "another partner's" alike. The backend
        // answers 404 for both on purpose; the UI must not narrow that.
        title: l10n.partnerMessagesUnavailableTitle,
        message: l10n.partnerMessagesUnavailableMessage,
        semanticLabel: l10n.partnerMessagesUnavailableTitle,
        actionLabel: l10n.partnerMessagesBackToInbox,
        onAction: messages.closeThread,
      );
    }

    if (thread == null) {
      return OceanStateView(
        key: const Key('partner-messages-thread-loading'),
        icon: Icons.forum_outlined,
        title: l10n.partnerMessagesTitle,
        message: l10n.partnerMessagesThreadLoading,
        semanticLabel: l10n.partnerMessagesThreadLoading,
        showProgress: true,
      );
    }

    final archived = thread.statusView == ConversationStatusView.archived;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('partner-messages-back'),
                onPressed: messages.closeThread,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: l10n.partnerMessagesBackToInbox,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // The guest is identified here, where the backend
                      // actually supplies a name.
                      l10n.partnerMessagesGuestLabel(
                          thread.userName ?? l10n.partnerMessagesSenderGuest),
                      key: const Key('partner-messages-thread-guest'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (thread.bookingCode != null)
                      Text(
                        l10n.partnerMessagesBookingLabel(thread.bookingCode!),
                        key: const Key('partner-messages-thread-booking'),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              OceanStatusPill(
                label: _statusLabel(l10n, thread.statusView),
                color: archived ? AppColors.textTertiary : AppColors.ocean600,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (thread.messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                l10n.partnerMessagesThreadEmpty,
                key: const Key('partner-messages-thread-empty'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            // Rendered exactly as served — the backend orders messages
            // oldest-first and nothing is re-sorted here.
            for (final message in thread.messages)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MessageBubble(message: message),
              ),
          const SizedBox(height: AppSpacing.md),
          if (archived)
            PartnerMetricNotice(
              key: const Key('partner-messages-archived-notice'),
              warning: true,
              message: l10n.partnerMessagesArchivedNotice,
            )
          else ...[
            if (messages.openThreadReopensOnSend) ...[
              PartnerMetricNotice(
                key: const Key('partner-messages-closed-notice'),
                message: l10n.partnerMessagesClosedNotice,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextField(
              key: const Key('partner-messages-composer'),
              controller: _composer,
              minLines: 2,
              maxLines: 6,
              // No maxLength: the backend validates `@NotBlank` only and stores
              // TEXT, so a client-side cap would be an invented rule.
              enabled: !messages.isSending,
              decoration: InputDecoration(
                labelText: l10n.partnerMessagesComposerLabel,
                hintText: l10n.partnerMessagesComposerHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (messages.isSending)
              const Center(
                key: Key('partner-messages-sending'),
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
                  key: const Key('partner-messages-send'),
                  label: l10n.partnerMessagesSend,
                  icon: Icons.send_rounded,
                  fullWidth: false,
                  // Disabled on a blank composer, mirroring `@NotBlank`, and
                  // while a send is in flight — a duplicate POST would create a
                  // duplicate message.
                  onPressed: _composer.text.trim().isEmpty ? null : _send,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final body = _composer.text;

    final result = await widget.messages.sendMessage(body);
    if (!mounted) return;

    // Cleared only on a confirmed 201. On anything else the operator keeps
    // their text — especially on `uncertain`, where retyping from memory would
    // be the worst outcome.
    if (result == PartnerSendResult.success) _composer.clear();

    messenger?.showSnackBar(SnackBar(
      content: Text(switch (result) {
        PartnerSendResult.success => l10n.partnerMessagesSent,
        PartnerSendResult.unauthorized =>
          l10n.partnerDashboardErrorUnauthorized,
        PartnerSendResult.forbidden => l10n.partnerDashboardErrorForbidden,
        PartnerSendResult.notFound => l10n.partnerMessagesUnavailableTitle,
        PartnerSendResult.archived => l10n.partnerMessagesArchivedNotice,
        PartnerSendResult.validation => l10n.partnerMessagesSendEmpty,
        PartnerSendResult.busy => l10n.partnerMessagesSending,
        // Never followed by an automatic resend.
        PartnerSendResult.uncertain => l10n.partnerMessagesSendUncertain,
        PartnerSendResult.failed => l10n.partnerMessagesSendFailed,
      }),
    ));
  }
}

class _MessageBubble extends StatelessWidget {
  final RealMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateTime = DateFormat.yMMMd(locale).add_Hm();

    // The host is "me"; the guest and support are the other side.
    final role = message.senderRoleView;
    final mine = role == MessageSenderRoleView.partner;
    final who = switch (role) {
      MessageSenderRoleView.partner => l10n.partnerMessagesSenderHost,
      MessageSenderRoleView.user =>
        message.senderName ?? l10n.partnerMessagesSenderGuest,
      MessageSenderRoleView.admin => l10n.partnerMessagesSenderSupport,
      MessageSenderRoleView.system => l10n.partnerMessagesSenderSupport,
      MessageSenderRoleView.unknown =>
        message.senderName ?? l10n.partnerMessagesSenderGuest,
    };

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: Key('partner-messages-bubble-${message.id}'),
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: mine ? AppColors.mist : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              who,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: mine ? AppColors.ocean700 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.body,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textPrimary),
            ),
            if (message.createdAt != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                dateTime.format(message.createdAt!),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _statusLabel(AppLocalizations l10n, ConversationStatusView status) =>
    switch (status) {
      ConversationStatusView.open => l10n.partnerMessagesStatusOpen,
      ConversationStatusView.closed => l10n.partnerMessagesStatusClosed,
      ConversationStatusView.archived => l10n.partnerMessagesStatusArchived,
      ConversationStatusView.unknown => l10n.partnerMessagesStatusOpen,
    };
