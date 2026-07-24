# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository. These are permanent project instructions — follow them exactly.

## 1. Product vision

Plan Your Trip is intended to become a **commercial travel-planning and booking product**,
not only a graduation demo. Correctness, data integrity, and shippable UX quality matter
more than speed of feature count.

- The **user mobile frontend** (this `frontend/` package) is the current priority.
- **Partner** and **Admin** surfaces do not exist yet and will be developed later as
  separate work — do not build them speculatively or fold their concerns into user-facing
  screens.

## 2. Current repository state

- Working branch: `feature/frontend-ui-v2`.
- The frontend has shipped UI-1 through UI-15 as individual commits (see `git log`).
  **UI-16 (Saved Places & Collections)** is the latest phase and, as of this writing, is
  implemented but **uncommitted** (`test/ui16_saved_places_collections_test.dart` is
  untracked; `AppState`, models, mock data, several screens, and l10n files are modified).
  Treat UI-16 as the current dirty phase — see the workflow rules in §11 before starting
  UI-17 or any new phase.
- Backend Foundation v1.0: referenced as complete. Note — no `backend-v1.0-foundation` git
  tag exists in this monorepo as of this writing (only `phase-7.30`, `v0.6.0`, `v0.7.18`
  are present). Do not assume the tag exists; verify with `git tag -l` before relying on it.
- Backend source (`../src`, `../pom.xml`, `../CLAUDE_backend.md`) is **read-only** from the
  frontend's perspective unless a task explicitly authorizes backend changes. This repo is
  a single monorepo (no submodules) — the backend has no separate `.git`.

## 3. Commands

```sh
flutter pub get                                   # install deps
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8080/api   # Android emulator
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api          # physical device (LAN IP)

flutter analyze                                   # static analysis (flutter_lints)
flutter test                                      # run all tests
flutter test test/ui16_saved_places_collections_test.dart   # run a single test file
flutter test test/ui16_saved_places_collections_test.dart --plain-name "saved-place model"  # single test case

flutter gen-l10n                                  # regenerate lib/l10n/app_localizations*.dart after editing .arb files
dart format .                                     # format before reporting a phase done
```

`API_BASE_URL` defaults to `http://localhost:8080/api` (`lib/core/config/app_config.dart`) when not passed via `--dart-define`.

## 4. Existing Flutter architecture

### Single global state object

`lib/core/app_state.dart` defines `AppState extends ChangeNotifier` — a large, single
store (~3200 lines) holding *all* app data: session, every domain list (trips, timeline,
expenses, bookings, saved places/collections, wallet, rewards, notifications, reviews...).
It's exposed app-wide via `AppScope` (`InheritedNotifier<AppState>`, bottom of the same
file) and read in widgets with `AppScope.of(context)`. There is no separate
repository/BLoC/provider-per-feature layer — new features extend `AppState` directly. Do
not introduce a second state-management system alongside it.

Mutation methods on `AppState` return typed result enums (e.g. `SavedPlaceActionResult`,
`SavedCollectionActionResult`, `BookingModificationResult`, `BookingCancellationResult`)
instead of throwing. Callers branch on the returned enum to decide what to show the user.
Follow this pattern for new mutations rather than introducing exceptions.

### Demo mode vs. real backend

- `ApiClient` (`lib/core/network/api_client.dart`) only implements `login`/`register`
  against the real backend. Logging in with `MockData.demoEmail`/`demoPassword` short-circuits
  to a fake `demo-token` without hitting the network.
- `AppState.demoMode` (persisted via `SessionStorage`) controls which data source every
  other feature uses: when `true`, all lists are seeded from `lib/core/mock/mock_data.dart`
  (`MockData.*`, in-memory only, resets on logout); when `false` (a real, non-demo login),
  those same lists are simply empty — there's no real backend wiring yet for
  trips/bookings/wallet/etc. Most `AppState` mutators explicitly check `demoMode` and
  return `*.unavailable` when it's off.
- When adding a feature, check whether it should follow this demo/mock convention or is
  genuinely wiring up a new backend endpoint via `ApiClient`. Preserve Demo Mode until a
  feature is explicitly migrated to real APIs (see §5).

### Domain models

`lib/core/mock/app_models.dart` (~3900 lines) holds every domain model, enum, and the
`*Result`/`*Eligibility` value types returned by `AppState`. `lib/core/mock/mock_data.dart`
holds the static demo dataset (`MockData` class) those models are seeded from.

### Persistence

- `lib/core/storage/session_storage.dart` — email/token/demo flag (`shared_preferences`).
- `lib/core/storage/preference_storage.dart` — locale override and toggle settings.

### Feature/screen structure

`lib/features/<domain>/*_screen.dart`, one directory per domain: `auth`, `home`, `trips`,
`planner`, `hotels`, `bookings`, `payments`, `places`, `categories`, `expenses`, `reviews`,
`rewards`, `wallet`, `profile`, `timeline`. `AppShell` (`lib/features/home/app_shell.dart`)
is the post-login 4-tab shell (Explore / Trips / Planner / Profile); it keeps all four tab
subtrees alive via `Offstage`/`TickerMode` rather than rebuilding on tab switch.

### Design system ("Ocean Glass")

`lib/design/*` defines the tokens (colors, typography, spacing, radii, shadows, gradients,
motion, breakpoints) consumed by `AppTheme.light()`. `lib/shared/widgets/glass_widgets.dart`
holds the reusable glassmorphism components (`BubbleBackground`, `OceanContentConstraint`,
`OceanBottomNavigationBar`, `OceanNavigationDestination`, etc.); `lib/shared/widgets/travel_cards.dart`
and `add_to_trip_sheet.dart` hold other shared cross-feature widgets. Reuse these for new
screens instead of raw Material widgets to keep visuals consistent.

### Localization

`lib/l10n/app_en.arb` / `app_vi.arb` are the source strings (`l10n.yaml`: template is
`app_en.arb`); `app_localizations*.dart` are generated — edit the `.arb` files and run
`flutter gen-l10n`, don't hand-edit the generated files.

### UI-N feature/test/commit convention

Features are built and committed incrementally as `UI-N` (see `git log`: "add UI-15
notification and activity center", "add UI-14 pending booking modification flow", ...).
Each `UI-N` has a matching widget test file `test/uiN_<feature>_test.dart`. When adding a
new feature, follow this pairing: implement the screen(s)/`AppState` methods, add
`test/ui<N>_<feature>_test.dart`, and (the user will) commit as
`feat(frontend): add UI-<N> <short description>`.

### Testing conventions

Tests are Flutter widget tests under `test/`. The established pattern (see e.g.
`test/ui16_saved_places_collections_test.dart`):

- `setUp(() => SharedPreferences.setMockInitialValues({}))` to stub persistence.
- A local `testApp({required child, AppState? app, Locale? locale})` helper that wraps
  `child` in `AppScope(notifier: app ?? AppState(), child: MaterialApp(...))` with the
  app's localization delegates/theme wired up.
- A `realApp()` helper (or similar) that builds an `AppState` with `demoMode = false` and
  empty lists, to exercise the non-demo code paths alongside the default demo-seeded state.
- Network images are common in cards; tests typically install a `FlutterError.onError`
  override to ignore `NetworkImageLoadException` during `pumpAndSettle()`.

## 5. Scope rules

- Work only inside `frontend/` unless a task explicitly authorizes touching the backend or
  monorepo root.
- Inspect before implementing: read the relevant screen(s), `AppState` methods, models, and
  existing tests before writing new code.
- Never duplicate an existing screen, service, model, state owner, widget system,
  navigation system, theme system, localization key, or backend contract — search first
  (`Grep`/`Glob`), extend what exists.
- One coherent UI phase (`UI-N`) at a time.
- Never start the next phase while the current phase is dirty or uncommitted (check
  `git status` — see §2 for the current UI-16 state).
- Never silently expand scope beyond what the current phase requires.

## 6. Backend integration rules

- The backend is the source of truth for all business logic.
- Flutter must **not** calculate booking prices, discounts, availability, loyalty points,
  voucher validity, recommendation scores, or AI context client-side — these are backend
  responsibilities even in features not yet wired up.
- When wiring a real endpoint, explicitly map backend DTOs to typed Dart models in
  `app_models.dart` — don't pass raw JSON through the UI layer.
- Keep `Map<String, dynamic>` at transport/decode boundaries only (inside `ApiClient` /
  `fromJson` constructors); everything above that layer should be typed.
- Preserve Demo Mode (§4) until a feature is explicitly migrated to real APIs.
- **Real Mode must never report fake success.** If a real-backend code path isn't
  implemented yet, surface the appropriate `*.unavailable`/error result — never fabricate a
  success state to make a screen look done.

## 7. Design direction

- Reuse the current Ocean Glass foundation (`lib/design/*`, `lib/shared/widgets/glass_widgets.dart`).
- Target feel: premium, calm, travel-focused, modern, accessible, and commercially
  shippable — not a student prototype.
- Use Apple, Agoda, Airbnb, Booking.com, and Google Maps only as quality references for
  polish and interaction patterns — never copy their assets or layouts directly.
- Avoid excessive blur, decorative clutter, inconsistent corner radii, and one-off visual
  styles that don't trace back to `lib/design/*` tokens.

## 8. Motion and performance

- Use shared motion tokens (`lib/design/app_motion.dart`) rather than ad-hoc durations/curves.
- Respect reduce-motion settings (`MediaQuery.disableAnimations` / platform accessibility
  setting) wherever animations are added.
- Do not promise or claim guaranteed 120 FPS in code comments, docs, or UI copy.
- Prefer `transform`/`opacity` animations over layout-triggering properties.
- Avoid unnecessary rebuilds, nested `BackdropFilter`/blur widgets, eager large list
  builds, and oversized image decoding (use `cacheWidth`/`cacheHeight` where relevant).
- Profile before optimizing — don't hand-tune performance without a measured problem.

## 9. UX state requirements

Every network-backed screen should eventually support:

- initial loading
- skeleton or appropriate progress state
- content
- empty state
- retryable error
- non-retryable error
- offline/cached state where relevant
- pull-to-refresh where relevant
- pagination where relevant

Not every existing screen has all of these today (most demo-mode screens assume data is
already present) — add the missing states when a phase's scope covers that screen, don't
retrofit unrelated screens as a side effect.

## 10. Accessibility

- Localized semantics (`Semantics` labels driven by `AppLocalizations`, not hardcoded strings).
- Text scaling support — avoid fixed-height text containers that clip at larger scale factors.
- Logical focus order for keyboard/switch-access navigation.
- Keyboard support where applicable (web/desktop targets).
- Minimum touch targets (48x48 logical px per Material guidance).
- Do not communicate state by color alone (pair color with icon/text/shape).
- Reduce motion (see §8).
- Screen-reader-safe icon and QR actions — icon-only buttons need a semantic label; QR/scan
  affordances need an accessible text alternative.

## 11. Security and destructive actions

Never automatically perform the following without explicit user confirmation in the UI
flow (a confirm dialog/step, not just a button tap):

- booking confirmation
- payment
- cancellation
- check-in
- check-out
- account deletion
- destructive itinerary replacement

## 12. Required workflow for every UI phase

1. Verify branch, HEAD/upstream, and `git status`.
2. Inspect relevant files and tests before writing code.
3. Perform a real gap analysis (what exists vs. what the phase needs).
4. State the exact minimal scope for this phase.
5. Implement.
6. Run `dart format .`.
7. Run `flutter analyze`.
8. Run focused tests for the phase (`flutter test test/ui<N>_..._test.dart`).
9. Run the full `flutter test` suite.
10. Run a build only when the phase requires it (e.g. web/platform-specific behavior).
11. Check localization parity (every new/changed string exists in both `app_en.arb` and
    `app_vi.arb`, and `flutter gen-l10n` was re-run).
12. Report exact changed paths and `git status`.
13. Do **not** commit or push (see §13).

## 13. Git rules

- The user performs `git add`, `commit`, `push`, tags, and branch changes.
- Never run destructive git commands (`reset --hard`, `checkout --`, `clean -f`, force push, etc.).
- Do not stage files (`git add`) on the user's behalf.
- Keep UI phase changes clean and isolated so the user can commit each phase independently.

## 14. Current roadmap

- UI17: real Saved Collections integration and contract boundary
- UI18: recommendation and personalized Home
- UI19: production networking, error mapping, loading states
- UI20: offline cache and network awareness
- UI21: universal search and infinite scroll
- UI22: booking voucher and QR experience
- UI23: map/list synchronization and route motion
- UI24: AI Context and AI Chat shell
- UI25: voice assistant foundation
- UI26: tablet adaptive layouts
- UI27: dark mode, accessibility, and reduce motion
- UI28: performance and frame-jank hardening
- UI29: partner dashboard, charts, and scanner
- UI30: release candidate and production hardening

## 15. Final checklist (before reporting any phase done)

- No duplicate systems introduced.
- No unrelated file changes.
- No fake real-mode success.
- Localization EN/VI parity.
- `flutter analyze` clean.
- Focused tests green.
- Full `flutter test` suite green.
- Exact `git status` reported.
- Nothing staged, committed, or pushed.
