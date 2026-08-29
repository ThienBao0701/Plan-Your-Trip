import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _email = 'last_login_email';
  static const _token = 'jwt_token';
  static const _demo = 'demo_mode';
  static const _role = 'user_role';

  /// [role] is the backend's `UserDto.role` wire value (`USER`/`PARTNER`/
  /// `ADMIN`) or null when it is absent or unrecognised. It is persisted so a
  /// restored session can route by role without an extra round trip; a null
  /// clears any previously stored value so a stale role can never outlive the
  /// account that had it. It is a *routing hint only* — the JWT, not this
  /// string, is what the backend authorizes against.
  Future<void> save({
    required String email,
    String? token,
    required bool demo,
    String? role,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_email, email);
    if (token != null) await p.setString(_token, token);
    await p.setBool(_demo, demo);
    if (role == null) {
      await p.remove(_role);
    } else {
      await p.setString(_role, role);
    }
  }

  Future<String?> email() async =>
      (await SharedPreferences.getInstance()).getString(_email);
  Future<String?> token() async =>
      (await SharedPreferences.getInstance()).getString(_token);
  Future<bool> demo() async =>
      (await SharedPreferences.getInstance()).getBool(_demo) ?? true;
  Future<String?> role() async =>
      (await SharedPreferences.getInstance()).getString(_role);
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_email);
    await p.remove(_token);
    await p.remove(_demo);
    await p.remove(_role);
  }
}
