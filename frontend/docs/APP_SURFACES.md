# Application surfaces

Plan Your Trip's Flutter frontend is **one codebase that builds three independent web applications**:

| Surface | Who it is for | Entrypoint | Local URL | Future production origin |
|---|---|---|---|---|
| **User** | Travellers (`USER`) | `lib/main_user.dart` | http://localhost:64117/ | `https://www.planyourtrip.com/` |
| **Partner** | Property partners (`PARTNER`) | `lib/main_partner.dart` | http://localhost:64118/ | `https://partner.planyourtrip.com/` |
| **Admin** | Platform administrators (`ADMIN`) | `lib/main_admin.dart` | http://localhost:64119/ | `https://admin.planyourtrip.com/` |

The backend is shared: http://localhost:8081/ locally (`https://api.planyourtrip.com/` in the future).

## 1. Architecture overview

```
lib/
  main_user.dart ─┐
  main_partner.dart ─┼─► app/bootstrap.dart ─► SurfaceApp(surface) ─► SurfaceGate ─► surface shell
  main_admin.dart ─┘        (shared)             (per surface)          (per location)
  main.dart           backward-compatible: --dart-define=APP_SURFACE=user|partner|admin (default user)

  app/
    app_surface.dart         AppSurface enum: role family, Demo Mode, sign-up, public URL
    surface_scope.dart       the running surface, available to every route
    bootstrap.dart           session restore, per-surface state, path URLs, runApp
    surface_app.dart         MaterialApp per surface; every location → one gate route
    surface_gate.dart        signed out → sign-in, wrong role → 403, admitted → shell
    surface_session.dart     sign out back to the surface's own root
    routing/
      surface_router.dart    base router: resolve, title, signed-out entry, shell
      user_router.dart       /, /trips, /planner, /profile
      partner_router.dart    /, /dashboard … /settings (13 destinations)
      admin_router.dart      /, /dashboard … /reference-data … /activity-log
  core/  design/  l10n/  shared/  features/   unchanged, shared by all three
```

**Shared by all three:** `AppState`/`AppScope` (session, token, locale), `ApiClient` and `API_BASE_URL`,
the Ocean Glass design system, localization, domain models and every feature screen.

**Owned by one surface:** its routes, its shell, and the domain state only it uses — `PartnerState` is
created only by the Partner surface and `AdminState` only by the Admin surface, so the traveller app does no
partner or admin work at start-up.

This is not three copies of the app, not three packages and not a micro-frontend: `SurfaceApp`,
`SurfaceGate` and the routers are a thin layer over the existing shells (`AppShell`, `PartnerAppShell`,
`AdminAppShell`), which are unchanged apart from reporting their destination and offering sign-out.

## 2. Surface model

`AppSurface` is the single decision point. Each surface admits **exactly one role family**:

| Surface | Admits | Refuses |
|---|---|---|
| `user` | `USER` | `PARTNER`, `ADMIN`, unknown |
| `partner` | `PARTNER` | `USER`, `ADMIN`, unknown |
| `admin` | `ADMIN` | `USER`, `PARTNER`, unknown |

Partner team roles (`OWNER`, `MANAGER`, `FRONT_DESK`, `FINANCE`, `VIEWER`) are **inside** the Partner
workspace and shape it as they did before; they are not surfaces. No `SUPER_ADMIN` / `SUPER_PARTNER` exists.

The Partner surface refuses `ADMIN` even though the backend's `/api/partner/**` URL rule admits it: partner
endpoints self-scope to the caller's own partner profile, which an administrator does not have. Cross-partner
administration is the Admin console's job.

## 3. Local ports

| Surface | Port |
|---|---|
| User | 64117 |
| Partner | 64118 |
| Admin | 64119 |
| Backend | 8081 |

Each port is a separate **browser origin**, so each surface keeps its own session (`SharedPreferences` is
per-origin `localStorage` on the web). Signing in to one surface does not sign you in to another.

## 4. Run the User surface

```powershell
cd "D:\Plan Your Trip\Plan-Your-Trip-integration\frontend"
flutter run -d chrome -t lib/main_user.dart --web-port 64117
```

## 5. Run the Partner surface

```powershell
cd "D:\Plan Your Trip\Plan-Your-Trip-integration\frontend"
flutter run -d chrome -t lib/main_partner.dart --web-port 64118
```

## 6. Run the Admin surface

```powershell
cd "D:\Plan Your Trip\Plan-Your-Trip-integration\frontend"
flutter run -d chrome -t lib/main_admin.dart --web-port 64119
```

Run each in its own terminal; they are independent processes. `-d web-server` instead of `-d chrome` serves
the same build without launching Chrome.

## 7. Backend configuration

```powershell
cd "D:\Plan Your Trip\Plan-Your-Trip-backend-v1"
$env:VOUCHER_SIGNING_SECRET="local-dev-voucher-secret-2026-plan-your-trip-32chars"
$env:SERVER_PORT="8081"
.\mvnw.cmd spring-boot:run
```

All three surfaces call the backend through `ApiClient`, whose base URL is `API_BASE_URL`
(`lib/core/config/app_config.dart`, default `http://localhost:8081/api`). It is independent of the surface:

```powershell
flutter run -d chrome -t lib/main_partner.dart --web-port 64118 --dart-define=API_BASE_URL=http://localhost:8081/api
```

No screen names a host, and no port is ever used to infer a permission.

## 8. Authentication behavior

`SurfaceGate` is the root of every location and decides — from the session already restored before the first
frame — exactly one of:

1. **No session (401)** → the surface's own sign-in. The User surface keeps its onboarding first; Partner and
   Admin open straight on sign-in.
2. **A role the surface does not admit, including an unrecognised role (403)** → *You don't have access to this
   application*, with a single **Sign out** action. No shell is built, so nothing protected is rendered and
   then hidden, and no partner or admin endpoint is called.
3. **An admitted session** → the surface's shell at the requested location.

Sign-in is one shared `LoginScreen`; the running surface sets its copy and actions. A successful sign-in never
chooses a destination by role — it returns to the surface's root, whose gate admits or refuses the account.
Sign-out (Profile in the User surface, the sidebar in Partner and Admin) clears the session and returns to that
surface's sign-in. Nothing navigates to another surface.

This is **UX routing, not authorization.** The backend authorizes every request against the JWT;
`PartnerRouteGuard` and `AdminRouteGuard` remain beneath the gate as a second client-side check.

## 9. Demo Mode behavior

| Surface | Demo Mode |
|---|---|
| User | Available — signs in the local traveller demo account (role `USER`, mock data, no backend). |
| Partner | Not offered. |
| Admin | Not offered. |

There is no partner or admin mock data, and a demo partner or administrator would fabricate authorization, so
the Partner and Admin sign-in screens show neither Demo Mode nor self sign-up and say that an existing account
is needed. Self sign-up creates `USER` accounts, which only the traveller app admits.

## 10. Routing and deep links

Paths are root-relative per surface — there is no `/user`, `/partner` or `/admin` prefix. Path URL strategy is
on (`/bookings`, not `/#/bookings`).

| Surface | Locations |
|---|---|
| User | `/` Explore · `/trips` · `/planner` · `/profile` |
| Partner | `/` or `/dashboard` · `/hotels` · `/rooms` · `/calendar` · `/pricing` · `/bookings` · `/messages` · `/promotions` · `/reviews` · `/finance` · `/analytics` · `/notifications` · `/settings` |
| Admin | `/` or `/dashboard` · `/bookings` · `/partners` · `/catalog` · `/media` · `/reference-data` · `/payments` · `/invoices` · `/reviews` · `/activity-log` |

- Opening or refreshing a location opens that destination (after sign-in, if needed).
- A path the surface does not serve — including a role-prefixed one such as `/partner/bookings` — opens the
  surface's own root and the address bar is corrected. Nothing redirects to another surface.
- Moving between destinations updates the address bar by replacing the current history entry, so a refresh
  reopens where you are. The browser Back button does not step between destinations (the shells switch in
  place rather than through the navigator).
- In the User surface, screens pushed from a tab keep the tab's location; after signing in from onboarding the
  traveller app opens on Explore, as before.
- Inside the app, Partner and Admin destinations keep their established route strings (`/partner/bookings`,
  `/admin/reference-data`) — the Partner ones match the backend's extranet menu. Only the browser location drops
  the prefix.

**Serving:** `flutter run` falls back to `index.html` for deep links. A production host must do the same
(single-page-app fallback: serve `index.html` for any path that is not a file).

## 11. Future production domain mapping

Each surface is built separately and deployed to its own origin; no business logic changes:

```sh
flutter build web -t lib/main_user.dart    --dart-define=API_BASE_URL=https://api.planyourtrip.com/api -o build/web-user
flutter build web -t lib/main_partner.dart --dart-define=API_BASE_URL=https://api.planyourtrip.com/api -o build/web-partner
flutter build web -t lib/main_admin.dart   --dart-define=API_BASE_URL=https://api.planyourtrip.com/api -o build/web-admin
```

| Build | Serve at |
|---|---|
| `build/web-user` | `https://www.planyourtrip.com/` |
| `build/web-partner` | `https://partner.planyourtrip.com/` |
| `build/web-admin` | `https://admin.planyourtrip.com/` |

The backend must allow those origins (CORS). If a future workflow needs to link across surfaces, read the
origin from `AppSurface.publicUrl` — configured with `--dart-define=USER_APP_URL=…`, `PARTNER_APP_URL=…` or
`ADMIN_APP_URL=…` — rather than naming a host in a screen. V1 does not link across surfaces.

## 12. Known limitations

- **Demo Mode is traveller-only** (see §9).
- **Back button:** destination changes replace the history entry (see §10).
- **Legacy sessions:** a session stored before roles were persisted has no role and is refused as unknown;
  signing in again restores access.
- **`APP_SURFACE` with `lib/main.dart`:** an unknown value, or a value that disagrees with a dedicated
  entrypoint, boots a configuration error instead of any surface.
