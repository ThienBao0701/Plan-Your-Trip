import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'notifications_screen.dart'
    show notificationTypeLabel, notificationPriorityLabel;

/// UI30 — Real Mode notification center. Lists the user's real notifications
/// (`GET /api/me/notifications`), marks one/all read and deletes, all against the
/// verified backend. Rendered in place of the demo notification list when
/// [AppState.demoMode] is false; the demo experience is untouched. Nothing is
/// fabricated — read state and the list only change after the server confirms.
class RealNotificationsBody extends StatefulWidget {
  const RealNotificationsBody({super.key});

  @override
  State<RealNotificationsBody> createState() => _RealNotificationsBodyState();
}

class _RealNotificationsBodyState extends State<RealNotificationsBody> {
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealNotifications();
    });
  }

  void _afterAction(AppState app, RealNotificationOutcome outcome) {
    if (!mounted) return;
    if (outcome == RealNotificationOutcome.success ||
        outcome == RealNotificationOutcome.busy) {
      return;
    }
    if (outcome == RealNotificationOutcome.sessionExpired) {
      _reauth();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final message = switch (outcome) {
      RealNotificationOutcome.forbidden =>
        l10n.notificationActionForbiddenMessage,
      RealNotificationOutcome.network => l10n.notificationActionNetworkMessage,
      _ => l10n.notificationActionServerErrorMessage,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _open(AppState app, RealNotificationRecord n) async {
    if (!n.read) {
      final outcome = await app.markRealNotificationRead(n.id);
      if (outcome != RealNotificationOutcome.success &&
          outcome != RealNotificationOutcome.busy) {
        _afterAction(app, outcome);
      }
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OceanGlassBottomSheet(
        child: _RealNotificationDetailSheet(
          notificationId: n.id,
          onDelete: () {
            Navigator.pop(context);
            _confirmDelete(app, n.id);
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(AppState app, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notificationDeleteConfirmTitle),
        content: Text(l10n.notificationDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('real-notification-delete-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.notificationDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.deleteRealNotification(id);
    if (!mounted) return;
    if (outcome == RealNotificationOutcome.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context)!.notificationDeletedMessage)));
    } else {
      _afterAction(app, outcome);
    }
  }

  Future<void> _markAll(AppState app) async {
    final outcome = await app.markAllRealNotificationsRead();
    _afterAction(app, outcome);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (app.realNotificationsError == RealNotificationOutcome.sessionExpired &&
        !app.realNotificationsLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('real-notifications-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realNotificationsLoading && !app.realNotificationsLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.notificationsRealLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.notificationsRealLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realNotificationsError != null && !app.realNotificationsLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('real-notifications-error'),
          message: l10n.notificationsRealErrorMessage,
          onReload: () => app.loadRealNotifications(refresh: true),
        ),
      );
    }

    final all = app.realNotifications;
    final visible = _unreadOnly ? all.where((n) => !n.read).toList() : all;
    final unread = app.realNotificationsUnreadCount;
    final busy = app.notificationActionInFlight.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () => app.loadRealNotifications(refresh: true),
      child: ListView(
        key: const Key('real-notifications-content'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          _RealNotificationHeader(
            unreadCount: unread,
            totalCount: all.length,
            onMarkAllRead: unread == 0 || busy ? null : () => _markAll(app),
          ),
          const SizedBox(height: AppSpacing.md),
          _UnreadFilter(
            unreadOnly: _unreadOnly,
            onChanged: (v) => setState(() => _unreadOnly = v),
          ),
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            OceanEmptyState(
              key: const Key('real-notifications-empty'),
              title: l10n.notificationsRealEmptyTitle,
              message: _unreadOnly
                  ? l10n.notificationFilterEmptyMessage
                  : l10n.notificationsRealEmptyMessage,
            )
          else
            for (final n in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _RealNotificationCard(
                  record: n,
                  onTap: () => _open(app, n),
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
        children: [Center(child: child)],
      );
}

class _RealNotificationHeader extends StatelessWidget {
  final int unreadCount;
  final int totalCount;
  final VoidCallback? onMarkAllRead;

  const _RealNotificationHeader({
    required this.unreadCount,
    required this.totalCount,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      semanticLabel: l10n.notificationCenterSemantic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OceanStatusPill(
                label: l10n.notificationUnreadCount(unreadCount),
                semanticLabel:
                    l10n.notificationUnreadCountSemantic(unreadCount),
                icon: Icons.mark_email_unread_rounded,
                color: unreadCount == 0 ? AppColors.success : AppColors.coral,
              ),
              OceanStatusPill(
                label: l10n.notificationTotalCount(totalCount),
                icon: Icons.inbox_rounded,
                color: AppColors.turquoise600,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.notificationsRealSubtitle,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          OceanSecondaryButton(
            key: const Key('real-notifications-mark-all'),
            label: l10n.notificationsMarkAllRead,
            icon: Icons.done_all_rounded,
            semanticLabel: l10n.notificationMarkAllReadSemantic,
            onPressed: onMarkAllRead,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}

class _UnreadFilter extends StatelessWidget {
  final bool unreadOnly;
  final ValueChanged<bool> onChanged;

  const _UnreadFilter({required this.unreadOnly, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<bool>(
        key: const Key('real-notification-filter'),
        selected: {unreadOnly},
        onSelectionChanged: (v) => onChanged(v.first),
        segments: [
          ButtonSegment(
            value: false,
            icon: const Icon(Icons.all_inbox_rounded, size: AppIconSizes.xs),
            label: Text(l10n.notificationFilterAll),
          ),
          ButtonSegment(
            value: true,
            icon: const Icon(Icons.mark_email_unread_rounded,
                size: AppIconSizes.xs),
            label: Text(l10n.notificationFilterUnread),
          ),
        ],
      ),
    );
  }
}

class _RealNotificationCard extends StatelessWidget {
  final RealNotificationRecord record;
  final VoidCallback onTap;

  const _RealNotificationCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = record.typeView;
    final typeLabel = type != null
        ? notificationTypeLabel(l10n, type)
        : (record.notificationType.trim().isEmpty
            ? l10n.notificationTypeSystem
            : record.notificationType.trim());
    final icon = realNotificationIcon(type);
    final color = realNotificationColor(type);
    final time = _formatTime(context, record.createdAt);
    final readLabel = record.read
        ? l10n.notificationReadSemantic
        : l10n.notificationUnreadSemantic;
    return OceanGlassCard(
      key: Key('real-notification-card-${record.id}'),
      onTap: onTap,
      semanticLabel: l10n.notificationCardSemantic(
          readLabel, typeLabel, record.title, time),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OceanStatusPill(label: typeLabel, icon: icon, color: color),
              OceanStatusPill(
                label: record.read
                    ? l10n.notificationReadLabel
                    : l10n.notificationUnreadLabel,
                icon: record.read
                    ? Icons.drafts_rounded
                    : Icons.mark_email_unread_rounded,
                color: record.read ? AppColors.textSecondary : AppColors.coral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            record.title.trim().isEmpty ? typeLabel : record.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (record.message.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(record.message, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (time.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(time,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _RealNotificationDetailSheet extends StatelessWidget {
  final int notificationId;
  final VoidCallback onDelete;

  const _RealNotificationDetailSheet({
    required this.notificationId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    RealNotificationRecord? n;
    for (final item in app.realNotifications) {
      if (item.id == notificationId) {
        n = item;
        break;
      }
    }
    if (n == null) {
      return OceanEmptyState(
        title: l10n.notificationMissingTitle,
        message: l10n.notificationMissingMessage,
      );
    }
    final type = n.typeView;
    final priority = n.priorityView;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(n.title.trim().isEmpty ? l10n.notificationTypeSystem : n.title,
              style: Theme.of(context).textTheme.headlineSmall),
          if (n.message.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(n.message, style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: type != null
                    ? notificationTypeLabel(l10n, type)
                    : l10n.notificationTypeSystem,
                icon: realNotificationIcon(type),
                color: realNotificationColor(type),
              ),
              if (priority != null)
                OceanStatusPill(
                  label: notificationPriorityLabel(l10n, priority),
                  icon: Icons.priority_high_rounded,
                  color: AppColors.ocean,
                ),
              OceanStatusPill(
                label: n.read
                    ? l10n.notificationReadLabel
                    : l10n.notificationUnreadLabel,
                icon: n.read
                    ? Icons.drafts_rounded
                    : Icons.mark_email_unread_rounded,
                color: n.read ? AppColors.textSecondary : AppColors.coral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (n.createdAt != null)
            _SheetRow(
              icon: Icons.schedule_rounded,
              label: l10n.notificationCreatedAtLabel,
              value: _formatDateTime(context, n.createdAt!),
            ),
          if (n.readAt != null)
            _SheetRow(
              icon: Icons.done_rounded,
              label: l10n.notificationReadAtLabel,
              value: _formatDateTime(context, n.readAt!),
            ),
          const SizedBox(height: AppSpacing.md),
          OceanSecondaryButton(
            key: const Key('real-notification-delete'),
            label: l10n.notificationDeleteAction,
            icon: Icons.delete_outline_rounded,
            semanticLabel: l10n.notificationDeleteSemantic,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SheetRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.ocean, size: AppIconSizes.sm),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Icon for a notification type view. Mirrors the demo palette so real and demo
/// notifications read the same. A null/unknown type falls back to a neutral icon.
IconData realNotificationIcon(UserNotificationType? type) {
  switch (type) {
    case UserNotificationType.booking:
    case UserNotificationType.reservation:
      return Icons.hotel_rounded;
    case UserNotificationType.payment:
      return Icons.account_balance_wallet_rounded;
    case UserNotificationType.trip:
      return Icons.map_rounded;
    case UserNotificationType.review:
      return Icons.rate_review_rounded;
    case UserNotificationType.promotion:
      return Icons.redeem_rounded;
    case UserNotificationType.message:
      return Icons.forum_rounded;
    case UserNotificationType.partner:
    case UserNotificationType.admin:
    case UserNotificationType.system:
    case null:
      return Icons.info_rounded;
  }
}

Color realNotificationColor(UserNotificationType? type) {
  switch (type) {
    case UserNotificationType.booking:
    case UserNotificationType.reservation:
      return AppColors.ocean;
    case UserNotificationType.payment:
      return AppColors.success;
    case UserNotificationType.trip:
      return AppColors.turquoise600;
    case UserNotificationType.review:
      return AppColors.violet;
    case UserNotificationType.promotion:
      return AppColors.warning;
    case UserNotificationType.message:
      return AppColors.aqua;
    case UserNotificationType.partner:
    case UserNotificationType.admin:
    case UserNotificationType.system:
    case null:
      return AppColors.textSecondary;
  }
}

String _formatTime(BuildContext context, DateTime? value) {
  if (value == null) return '';
  return DateFormat.MMMd(Localizations.localeOf(context).toString())
      .add_jm()
      .format(value.toLocal());
}

String _formatDateTime(BuildContext context, DateTime value) {
  return DateFormat.yMMMd(Localizations.localeOf(context).toString())
      .add_jm()
      .format(value.toLocal());
}
