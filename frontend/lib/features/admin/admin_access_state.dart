import 'package:flutter/foundation.dart';

import '../../core/admin/admin_access_models.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_failure.dart';
import 'widgets/admin_widgets.dart';

/// RBAC R6 — the outcome of one profile change, for the screen to word.
class AdminProfileChangeResult {
  final AdminAccount? account;
  final ApiFailure? failure;

  const AdminProfileChangeResult.succeeded(this.account) : failure = null;
  const AdminProfileChangeResult.failed(this.failure) : account = null;

  bool get success => failure == null;

  String? get code => failure?.code;

  bool get stepUpRequired => code == 'STEP_UP_REQUIRED';
}

/// RBAC R6 — administrators and their admin profiles
/// (`GET /api/admin/access/admins`, `PUT …/{userId}/profiles`, RBAC V1.1 §25.4).
///
/// The server decides everything: only a `PLATFORM_OWNER` may list or change
/// profiles, nobody changes their own, the last platform owner cannot be
/// removed and a change needs a fresh session. This state only reports what
/// the server answered and refreshes the list after every write.
class AdminAccessManagementState extends ChangeNotifier {
  final ApiClient api;

  AdminAccessManagementState({required this.api});

  AdminLoadStatus _status = AdminLoadStatus.idle;
  List<AdminAccount> _admins = const [];
  final Set<int> _busy = {};

  AdminLoadStatus get status => _status;
  List<AdminAccount> get admins => _admins;
  bool isBusy(int userId) => _busy.contains(userId);

  Future<void> load() async {
    _status = AdminLoadStatus.loading;
    notifyListeners();
    final result = await api.getAdminAccounts();
    if (result.success) {
      _admins = result.data ?? const [];
      _status = AdminLoadStatus.ready;
    } else {
      _status = adminStatusFor(result.errorKind);
    }
    notifyListeners();
  }

  /// Replaces [userId]'s profiles. A second call while one is in flight for
  /// the same administrator is ignored (returns null).
  Future<AdminProfileChangeResult?> replaceProfiles(
    int userId,
    List<AdminProfile> profiles, {
    String? reason,
  }) async {
    if (_busy.contains(userId)) return null;
    _busy.add(userId);
    notifyListeners();
    try {
      final result = await api.replaceAdminProfiles(
        userId: userId,
        profiles: profiles,
        reason: reason,
      );
      if (result.success) {
        await load();
        return AdminProfileChangeResult.succeeded(result.data);
      }
      final failure =
          result.failure ?? const ApiFailure.of(ApiErrorKind.network);
      // A write that may or may not have happened, or a list that changed
      // under us, is re-read so the screen shows the server's state.
      if (failure.kind == ApiErrorKind.uncertain ||
          failure.kind == ApiErrorKind.conflict ||
          failure.kind == ApiErrorKind.notFound) {
        await load();
      }
      return AdminProfileChangeResult.failed(failure);
    } finally {
      _busy.remove(userId);
      notifyListeners();
    }
  }
}
