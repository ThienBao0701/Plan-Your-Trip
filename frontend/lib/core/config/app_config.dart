class AppConfig {
  // Local development backend port is 8081: port 8080 is occupied by Windows
  // AgentService on the development machine, so local Spring Boot is started with
  // SERVER_PORT=8081 (see PlanYourTrip-Pro-Launcher-V3.1-Fixed). This is LOCAL ONLY —
  // the Dockerised app still listens on 8080 inside its own network, where Nginx
  // reverse-proxies to it and the browser never talks to the app port directly.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081/api',
  );

  static const apiBaseUrlHelp =
      'Set --dart-define=API_BASE_URL=http://localhost:8081/api for Flutter Web on this computer. '
      'For Android emulator use http://10.0.2.2:8081/api. '
      'For a physical phone use this computer LAN IP, for example http://192.168.1.10:8081/api.';
}
