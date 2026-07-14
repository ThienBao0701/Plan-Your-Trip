import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _email = 'last_login_email';
  static const _token = 'jwt_token';
  static const _demo = 'demo_mode';
  Future<void> save(
      {required String email, String? token, required bool demo}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_email, email);
    if (token != null) await p.setString(_token, token);
    await p.setBool(_demo, demo);
  }

  Future<String?> email() async =>
      (await SharedPreferences.getInstance()).getString(_email);
  Future<String?> token() async =>
      (await SharedPreferences.getInstance()).getString(_token);
  Future<bool> demo() async =>
      (await SharedPreferences.getInstance()).getBool(_demo) ?? true;
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_email);
    await p.remove(_token);
    await p.remove(_demo);
  }
}
