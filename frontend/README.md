# planyourtrip_frontend

The Plan Your Trip Flutter web frontend: one codebase that builds three
independent applications.

## Application surfaces

| Surface | Entrypoint | Local URL |
|---|---|---|
| User (traveller app) | `lib/main_user.dart` | http://localhost:64117/ |
| Partner workspace | `lib/main_partner.dart` | http://localhost:64118/ |
| Admin console | `lib/main_admin.dart` | http://localhost:64119/ |

```powershell
flutter run -d chrome -t lib/main_user.dart --web-port 64117
flutter run -d chrome -t lib/main_partner.dart --web-port 64118
flutter run -d chrome -t lib/main_admin.dart --web-port 64119
```

Architecture, routing, sign-in, Demo Mode, backend configuration and the
production domain mapping are in [docs/APP_SURFACES.md](docs/APP_SURFACES.md).

## API base URL

The frontend reads the backend URL from `API_BASE_URL`.

Examples:

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8081/api
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8081/api
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8081/api
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
