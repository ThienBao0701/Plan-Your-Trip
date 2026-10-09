import 'auth_link_token.dart';

/// RBAC R5 — the partner invitation link's one-time token, held in memory
/// between the moment the link is opened and the moment it is used.
///
/// The backend sends `<partner app>/accept-invitation#token=…` (RBAC V1.1 §13.1
/// step 7): the token is in the **fragment**, so it never reaches a server log,
/// an access log or a `Referer`. On first read it is taken out of the address bar
/// ([AuthLinkToken.clear]) and kept here so it survives the Partner sign-in that
/// may come in between (the gate rebuilds the screen after sign-in, and the
/// address bar no longer carries it).
///
/// It is held **only** in this process's memory: never written to
/// `SharedPreferences`, session storage or any other durable store, never put in
/// a query parameter, never logged, never sent anywhere but
/// `POST /api/me/partner-invitations/accept|decline` — in the request body. It
/// is dropped once used, refused for good, or declined. A full page reload
/// before then loses it; the invitee opens the emailed link again.
class PartnerInvitationLink {
  PartnerInvitationLink._();

  static const String location = '/accept-invitation';

  static String? _pending;

  /// Captures the token from the current URL's fragment, once, and clears it
  /// from the address bar. A token already captured is kept.
  static void capture({Uri? from}) {
    final token = AuthLinkToken.read(from: from);
    if (token == null) return;
    _pending = token;
    AuthLinkToken.clear(location);
  }

  /// The token waiting to be used, or null.
  static String? get pending => _pending;

  static bool get hasPending => _pending != null;

  /// Drops the token — after acceptance, a final refusal, or a decline.
  static void clear() => _pending = null;

  /// Test hook: puts a token in place as if a link had been opened.
  static void debugSet(String? token) => _pending = token;
}
