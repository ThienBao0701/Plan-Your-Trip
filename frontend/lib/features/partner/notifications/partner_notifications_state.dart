import 'package:flutter/foundation.dart';

import '../../../core/mock/app_models.dart';
import '../../../core/network/api_client.dart';

/// Where the Notifications module stands.
enum PartnerNotificationsStatus {
  idle,
  loading,
  ready,

  /// 401 — the session is not (or no longer) authenticated. Never a logout.
  unauthorized,

  /// 403 — the caller is refused. On this endpoint that is cross-user access;
  /// the notification stack answers 403 here, unlike conversations' 404.
  forbidden,

  /// 404 — the resource is gone.
  notFound,

  /// Network failure, timeout, malformed payload or 5xx. Retryable.
  error,
}

/// Outcome of a per-notification or bulk mutation.
enum PartnerNotificationActionResult {
  success,
  unauthorized,

  /// 403 — this notification belongs to another user.
  forbidden,

  /// 404 — the notification no longer exists.
  notFound,

  /// A mutation for this notification (or a mark-all) is already in flight.
  busy,

  failed,
}

/// Where a notification points, once the server has told us.
///
/// The **list** endpoint does not carry `relatedEntityType`/`relatedEntityId` at
/// all — only `PATCH /{id}/read` returns the full `NotificationResponse`. So a
/// target is knowable only after a mark-read, and only for that one row.
@immutable
class PartnerNotificationTarget {
  final NotificationRelatedEntity? entity;
  final int? entityId;

  const PartnerNotificationTarget({this.entity, this.entityId});

  bool get isResolvable => entity != null && entityId != null;
}

/// State for the Partner Notification Centre (D6).
///
/// ## This is the user's complete inbox, not a partner-only feed
///
/// `Notification` has exactly one ownership axis — `recipientUser`. There is
/// **no field** saying "this reached you as a partner". `GET /api/me/notifications`
/// therefore returns everything the signed-in account received: the ten
/// partner-directed triggers (profile approved/rejected/suspended, hotel
/// assigned, property/rate-plan/promotion/payout updated, team invite, new
/// review, guest message), plus admin broadcasts, plus anything they received as
/// a traveller.
///
/// D6 deliberately shows **all** of it. Filtering to `PARTNER`/`REVIEW`/`MESSAGE`
/// would hide admin broadcasts and system notices an operator may need, and
/// would present `notificationType` as an audience field, which it is not.
///
/// ## The list is unpaginated
///
/// `NotificationController.getMine` returns a bare `List<NotificationSummaryResponse>`
/// — no page, size or sort parameters. The complete inbox arrives in one
/// response and is rendered in full, newest first, exactly as served.
///
/// ## Nothing is mutated optimistically
///
/// Read state, the unread count and deletion all come back from the server
/// before local state changes. `read`/`readAt` live on the server and sync
/// across devices, so echoing a guess locally would be inventing a fact the
/// server owns.
///
/// ## Deep links are not guessed
///
/// See [targetFor] and [hasSupportedPartnerDestination].
class PartnerNotificationsState extends ChangeNotifier {
  final ApiClient api;

  PartnerNotificationsState({required this.api});

  PartnerNotificationsStatus _status = PartnerNotificationsStatus.idle;
  String? _errorMessage;

  List<RealNotificationRecord> _notifications = const [];

  /// The server's own unread count (`GET /unread-count`). Never derived locally
  /// — the shell badge and this number must not drift apart by arithmetic.
  int? _serverUnread;

  /// Full records returned by `PATCH /{id}/read`, keyed by id. These are the
  /// only place `relatedEntityType`/`relatedEntityId` ever appear.
  final Map<int, RealNotificationRecord> _details = {};

  /// Ids with a mutation in flight — a second request for the same row is
  /// refused rather than queued.
  final Set<int> _pending = {};
  bool _markingAll = false;

  int _loadToken = 0;

  PartnerNotificationsStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// The complete inbox as served — newest first, never re-sorted, never filtered.
  List<RealNotificationRecord> get notifications =>
      List.unmodifiable(_notifications);

  /// The server's unread count, or null before it has been read.
  int? get serverUnread => _serverUnread;

  bool get isLoading => _status == PartnerNotificationsStatus.loading;
  bool get isReady => _status == PartnerNotificationsStatus.ready;
  bool get isRetryable => _status == PartnerNotificationsStatus.error;
  bool get isEmpty => isReady && _notifications.isEmpty;

  bool get isMarkingAll => _markingAll;
  bool isPending(int id) => _pending.contains(id);

  /// True when at least one row is still unread, per the server's own flags.
  bool get hasUnread => _notifications.any((n) => !n.read);

  /// **No partner destination accepts an entity id.** Every screen in the
  /// partner shell is a zero-argument `const` constructor dispatched by menu
  /// key, so there is nothing a `(relatedEntityType, relatedEntityId)` pair
  /// could address. D6 therefore resolves a target and shows it, but never
  /// navigates — guessing `MESSAGE -> messages` or `REVIEW -> reviews` would
  /// invent routing the backend never specified.
  static const bool hasSupportedPartnerDestination = false;

  /// The resolved target for a notification, if it has been marked read and the
  /// server returned one. Null while only the summary is known.
  PartnerNotificationTarget? targetFor(int id) {
    final detail = _details[id];
    if (detail == null) return null;
    return PartnerNotificationTarget(
      entity: detail.relatedEntityView,
      entityId: detail.relatedEntityId,
    );
  }

  /// Loads the inbox and the server's unread count together.
  Future<void> load() async {
    final token = ++_loadToken;
    _status = PartnerNotificationsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await api.getNotifications();
    if (token != _loadToken) return;

    if (!result.success) {
      _notifications = const [];
      _serverUnread = null;
      _status = _statusFor(result.errorKind);
      _errorMessage = result.message;
      notifyListeners();
      return;
    }

    _notifications = result.data ?? const [];
    _status = PartnerNotificationsStatus.ready;
    _errorMessage = null;

    // Drop cached detail for rows that are no longer in the inbox.
    _details.removeWhere((id, _) => !_notifications.any((n) => n.id == id));
    notifyListeners();

    await _refreshUnread(token);
  }

  Future<void> refresh() => load();

  /// Asks the server for the unread count. Best effort: a failure leaves the
  /// list on screen and simply reports no count rather than a fabricated one.
  Future<void> _refreshUnread(int token) async {
    final result = await api.getUnreadNotificationCount();
    if (token != _loadToken) return;
    _serverUnread = result.success ? result.data : null;
    notifyListeners();
  }

  /// Marks one notification read.
  ///
  /// Idempotent on the server, but a row that is already read is not re-sent —
  /// there is nothing to change and the round trip would be waste.
  ///
  /// On success the full `NotificationResponse` comes back, which is the only
  /// way to learn `relatedEntityType`/`relatedEntityId`; it is cached for
  /// [targetFor]. Local state is updated **only** from the server's record.
  Future<PartnerNotificationActionResult> markRead(int id) async {
    if (_markingAll || _pending.contains(id)) {
      return PartnerNotificationActionResult.busy;
    }
    final current = _notifications.where((n) => n.id == id).firstOrNull;
    if (current == null) return PartnerNotificationActionResult.notFound;
    if (current.read) {
      // Already read: nothing to mutate. Not an error, not a request.
      return PartnerNotificationActionResult.success;
    }

    _pending.add(id);
    notifyListeners();

    final result = await api.markNotificationRead(id);

    _pending.remove(id);

    if (!result.success) {
      notifyListeners();
      return _actionResultFor(result.errorKind);
    }

    final updated = result.data;
    if (updated != null) {
      _details[id] = updated;
      // Replace the row with the server's own record — no locally-flipped flag.
      _notifications = [
        for (final n in _notifications)
          if (n.id == id) updated else n,
      ];
    }
    notifyListeners();

    await _refreshUnread(_loadToken);
    return PartnerNotificationActionResult.success;
  }

  /// Marks every notification read, then re-reads the inbox.
  ///
  /// The response is a bare count, not the updated rows, so the list must be
  /// re-read rather than patched locally.
  Future<PartnerNotificationActionResult> markAllRead() async {
    if (_markingAll || _pending.isNotEmpty) {
      return PartnerNotificationActionResult.busy;
    }
    _markingAll = true;
    notifyListeners();

    final result = await api.markAllNotificationsRead();

    _markingAll = false;

    if (!result.success) {
      notifyListeners();
      return _actionResultFor(result.errorKind);
    }

    await load();
    return PartnerNotificationActionResult.success;
  }

  /// Deletes one notification.
  ///
  /// **Hard delete with no undo** — the backend has no archive and no
  /// soft-delete. The caller is expected to have confirmed. The row is removed
  /// only after the server confirms, never optimistically.
  Future<PartnerNotificationActionResult> delete(int id) async {
    if (_markingAll || _pending.contains(id)) {
      return PartnerNotificationActionResult.busy;
    }
    _pending.add(id);
    notifyListeners();

    final result = await api.deleteNotification(id);

    _pending.remove(id);

    if (!result.success) {
      notifyListeners();
      return _actionResultFor(result.errorKind);
    }

    _notifications =
        _notifications.where((n) => n.id != id).toList(growable: false);
    _details.remove(id);
    notifyListeners();

    await _refreshUnread(_loadToken);
    return PartnerNotificationActionResult.success;
  }

  PartnerNotificationsStatus _statusFor(ApiErrorKind? kind) => switch (kind) {
        ApiErrorKind.unauthorized => PartnerNotificationsStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerNotificationsStatus.forbidden,
        ApiErrorKind.notFound => PartnerNotificationsStatus.notFound,
        _ => PartnerNotificationsStatus.error,
      };

  PartnerNotificationActionResult _actionResultFor(ApiErrorKind? kind) =>
      switch (kind) {
        ApiErrorKind.unauthorized =>
          PartnerNotificationActionResult.unauthorized,
        ApiErrorKind.forbidden => PartnerNotificationActionResult.forbidden,
        ApiErrorKind.notFound => PartnerNotificationActionResult.notFound,
        _ => PartnerNotificationActionResult.failed,
      };

  void reset() {
    _loadToken++;
    _status = PartnerNotificationsStatus.idle;
    _errorMessage = null;
    _notifications = const [];
    _serverUnread = null;
    _details.clear();
    _pending.clear();
    _markingAll = false;
    notifyListeners();
  }
}
