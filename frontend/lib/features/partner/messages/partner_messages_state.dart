import 'package:flutter/foundation.dart';

import '../../../core/mock/app_models.dart';
import '../../../core/network/api_client.dart';

/// Where the Messages module stands.
enum PartnerMessagesStatus {
  idle,
  loading,
  ready,

  /// 401 — the session is not (or no longer) authenticated. Never a logout.
  unauthorized,

  /// 403 — the system role is not admitted, or the partner profile exists but
  /// is not `APPROVED`.
  forbidden,

  /// 404 — no partner profile resolves for this account. Uniform: it is also
  /// what a team member who does not own the profile receives.
  notFound,

  /// Network failure, timeout, malformed payload or 5xx. Retryable.
  error,
}

/// Outcome of opening one thread.
enum PartnerThreadResult {
  success,
  unauthorized,
  forbidden,

  /// Uniform 404 — unknown thread, **or** one owned by another partner. The two
  /// are indistinguishable on purpose and must stay that way in the UI.
  notFound,
  failed,
}

/// Outcome of sending a host reply.
enum PartnerSendResult {
  success,
  unauthorized,
  forbidden,

  /// Uniform 404 — unknown thread, or another partner's.
  notFound,

  /// 422 — the conversation is ARCHIVED and can no longer receive messages.
  archived,

  /// 400 — blank body. Pre-empted client-side, so this should be unreachable.
  validation,

  /// A send is already in flight. Never a second request.
  busy,

  failed,

  /// The request timed out. The message **may already have been stored** — the
  /// backend has no idempotency key and no duplicate protection, so retrying
  /// could post it twice. The operator must re-read the thread instead.
  uncertain,
}

/// State for the Partner Messages module (D5) — the host side of the guest↔host
/// conversation the customer app already has under `/api/me/conversations`.
///
/// ## What the backend gives a partner
///
/// | Capability | Endpoint | D5 |
/// |---|---|---|
/// | List threads | `GET /api/partner/conversations` | ✅ |
/// | Read a thread | `GET /api/partner/conversations/{id}` | ✅ |
/// | Reply as host | `POST /api/partner/conversations/{id}/messages` (201) | ✅ |
/// | Mark read | `PATCH /api/partner/conversations/{id}/read` | ✅ |
/// | Close | `PATCH /api/partner/conversations/{id}/close` | ⛔ excluded (see below) |
/// | Start a thread | — | ⛔ guests only |
///
/// ## The list is unpaginated, and that is the server's shape
///
/// `PartnerConversationController.getMine` returns a bare
/// `List<ConversationSummaryResponse>` — no page, no size, no sort parameters.
/// The complete inbox arrives in one response and is rendered in full. There is
/// no pagination and no infinite scroll here, and inventing client-side paging
/// over an already-complete list would only hide how much was actually served.
///
/// ## Nothing is re-sorted
///
/// The backend orders conversations by `lastMessageAt` descending and a thread's
/// messages by `createdAt` ascending. Both are rendered exactly as served.
///
/// ## Close is deliberately absent
///
/// The endpoint exists, but `ConversationService.sendMessage` silently flips a
/// CLOSED conversation back to OPEN on the guest's next message. A Close control
/// would therefore promise a state the backend does not keep, so D5 does not
/// offer one.
///
/// ## Read state is the server's
///
/// `unreadCount` counts messages the *partner* has not read. Only
/// `PATCH /read` clears it — sending a reply does not, because
/// `sendMessage` marks only the sender's own message read on their side. This
/// class never computes or adjusts an unread count locally.
class PartnerMessagesState extends ChangeNotifier {
  final ApiClient api;

  PartnerMessagesState({required this.api});

  PartnerMessagesStatus _status = PartnerMessagesStatus.idle;
  String? _errorMessage;

  List<RealConversationSummary> _conversations = const [];

  RealConversation? _thread;
  int? _openConversationId;
  bool _threadLoading = false;
  PartnerThreadResult? _threadError;

  bool _sending = false;

  /// Guards against a stale response overwriting a newer one.
  int _loadToken = 0;
  int _threadToken = 0;

  PartnerMessagesStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// The complete inbox as served. Never filtered, never re-sorted.
  List<RealConversationSummary> get conversations =>
      List.unmodifiable(_conversations);

  /// The open thread, or null when the inbox is showing.
  RealConversation? get thread => _thread;
  int? get openConversationId => _openConversationId;
  bool get threadLoading => _threadLoading;
  PartnerThreadResult? get threadError => _threadError;

  bool get isLoading => _status == PartnerMessagesStatus.loading;
  bool get isReady => _status == PartnerMessagesStatus.ready;
  bool get isRetryable => _status == PartnerMessagesStatus.error;

  /// The partner genuinely has no conversations.
  bool get isEmpty => isReady && _conversations.isEmpty;

  /// A send is in flight. The composer must stay disabled while this is true —
  /// a second POST would create a second message.
  bool get isSending => _sending;

  /// Total unread across the inbox, summed from the server's own per-thread
  /// counts. This is the same quantity the shell badge shows; it is never
  /// adjusted locally.
  int get totalUnread =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  /// Whether the open thread can still receive a message. An ARCHIVED thread is
  /// a guaranteed 422, so the composer must not offer a doomed action.
  bool get canSendToOpenThread {
    final t = _thread;
    if (t == null) return false;
    return t.statusView != ConversationStatusView.archived;
  }

  /// Whether sending would reopen the open thread. Worth saying out loud rather
  /// than letting a status flip silently.
  bool get openThreadReopensOnSend =>
      _thread?.statusView == ConversationStatusView.closed;

  /// Loads the inbox.
  Future<void> load() async {
    final token = ++_loadToken;
    _status = PartnerMessagesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await api.getPartnerConversations();
    if (token != _loadToken) return;

    if (!result.success) {
      _conversations = const [];
      _status = _statusFor(result.errorKind);
      _errorMessage = result.message;
      notifyListeners();
      return;
    }

    _conversations = result.data ?? const [];
    _status = PartnerMessagesStatus.ready;
    _errorMessage = null;

    // A thread that is no longer in the inbox must not stay open beside it.
    final open = _openConversationId;
    if (open != null && !_conversations.any((c) => c.id == open)) {
      _openConversationId = null;
      _thread = null;
      _threadError = null;
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  /// Opens one thread, then marks it read.
  ///
  /// The read call is **best effort**: if it fails the thread stays on screen
  /// exactly as loaded. Failing to clear a badge is not a reason to throw away a
  /// conversation the operator is reading.
  Future<PartnerThreadResult> openThread(int conversationId) async {
    final token = ++_threadToken;
    _openConversationId = conversationId;
    _threadLoading = true;
    _threadError = null;
    if (_thread?.id != conversationId) _thread = null;
    notifyListeners();

    final result = await api.getPartnerConversation(conversationId);
    if (token != _threadToken) return PartnerThreadResult.failed;

    if (!result.success) {
      _threadLoading = false;
      _thread = null;
      _threadError = switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerThreadResult.unauthorized,
        ApiErrorKind.forbidden => PartnerThreadResult.forbidden,
        ApiErrorKind.notFound => PartnerThreadResult.notFound,
        _ => PartnerThreadResult.failed,
      };
      notifyListeners();
      return _threadError!;
    }

    _thread = result.data;
    _threadLoading = false;
    _threadError = null;
    notifyListeners();

    await _markRead(conversationId, token);
    return PartnerThreadResult.success;
  }

  /// Re-reads the open thread without re-running mark-read.
  Future<void> reloadOpenThread() async {
    final id = _openConversationId;
    if (id == null) return;
    final token = ++_threadToken;
    _threadLoading = true;
    notifyListeners();

    final result = await api.getPartnerConversation(id);
    if (token != _threadToken) return;

    _threadLoading = false;
    if (result.success) {
      _thread = result.data;
      _threadError = null;
    }
    // A failed re-read leaves the thread as it was rather than blanking it.
    notifyListeners();
  }

  /// Marks the guest's messages read, then refreshes the inbox so the row's
  /// `unreadCount` reflects what the server now holds.
  Future<void> _markRead(int conversationId, int token) async {
    final result = await api.markPartnerConversationRead(conversationId);
    if (token != _threadToken) return;
    if (!result.success) return; // best effort — the thread stays as loaded.

    _thread = result.data ?? _thread;
    notifyListeners();
    await load();
  }

  void closeThread() {
    if (_openConversationId == null && _thread == null) return;
    _threadToken++;
    _openConversationId = null;
    _thread = null;
    _threadError = null;
    _threadLoading = false;
    notifyListeners();
  }

  /// Sends a host reply to the open thread.
  ///
  /// Single-flight: a second call while one is in flight returns
  /// [PartnerSendResult.busy] without issuing a request, because a duplicate
  /// POST would create a duplicate message.
  ///
  /// Nothing is rendered optimistically. On 201 the thread is re-read and the
  /// inbox refreshed, so what appears on screen is what the server actually
  /// stored — including its server-generated timestamp.
  Future<PartnerSendResult> sendMessage(String body) async {
    final id = _openConversationId;
    if (id == null) return PartnerSendResult.failed;
    if (_sending) return PartnerSendResult.busy;
    if (body.trim().isEmpty) return PartnerSendResult.validation;
    if (!canSendToOpenThread) return PartnerSendResult.archived;

    _sending = true;
    notifyListeners();

    final result = await api.sendPartnerConversationMessage(id, body);

    _sending = false;

    if (!result.success) {
      notifyListeners();
      return switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerSendResult.unauthorized,
        ApiErrorKind.forbidden => PartnerSendResult.forbidden,
        ApiErrorKind.notFound => PartnerSendResult.notFound,
        ApiErrorKind.unprocessable => PartnerSendResult.archived,
        ApiErrorKind.validation => PartnerSendResult.validation,
        // Timeout on a non-idempotent POST. Never retried automatically.
        ApiErrorKind.uncertain => PartnerSendResult.uncertain,
        _ => PartnerSendResult.failed,
      };
    }

    // The message body, its id and its timestamp are the server's. Re-reading is
    // the only honest way to show what was stored.
    await reloadOpenThread();
    await load();
    return PartnerSendResult.success;
  }

  PartnerMessagesStatus _statusFor(ApiErrorKind? kind) => switch (kind) {
        ApiErrorKind.unauthorized => PartnerMessagesStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerMessagesStatus.forbidden,
        ApiErrorKind.notFound => PartnerMessagesStatus.notFound,
        _ => PartnerMessagesStatus.error,
      };

  void reset() {
    _loadToken++;
    _threadToken++;
    _status = PartnerMessagesStatus.idle;
    _errorMessage = null;
    _conversations = const [];
    _thread = null;
    _openConversationId = null;
    _threadLoading = false;
    _threadError = null;
    _sending = false;
    notifyListeners();
  }
}
