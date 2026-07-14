class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  static const apiBaseUrlHelp =
      'Set --dart-define=API_BASE_URL=http://localhost:8080/api for Flutter Web on this computer. '
      'For Android emulator use http://10.0.2.2:8080/api. '
      'For a physical phone use this computer LAN IP, for example http://192.168.1.10:8080/api.';
}
