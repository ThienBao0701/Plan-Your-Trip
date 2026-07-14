# planyourtrip_frontend

A new Flutter project.

## API base URL

The frontend reads the backend URL from `API_BASE_URL`.

Examples:

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
```

Use `localhost` for Flutter Web on the same computer as the backend. Use
`10.0.2.2` for the Android emulator. Use the computer's LAN IP for a physical
phone on the same network.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
