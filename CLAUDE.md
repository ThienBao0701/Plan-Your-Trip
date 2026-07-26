# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository shape

This is a monorepo (no submodules) with two independent packages sharing one `.git`:

- **Backend** — Java/Spring Boot REST API at the repo root (`src/`, `pom.xml`). Source of truth for
  all business logic.
- **Frontend** — Flutter mobile/web app at `frontend/` (`frontend/lib`, `frontend/pubspec.yaml`).

Each side has its own detailed guidance file — read the one relevant to your task:

- `frontend/CLAUDE.md` — permanent, detailed frontend instructions (state architecture, demo-mode
  convention, UI-N phase workflow, design system, scope/git rules). Treat it as authoritative for
  anything under `frontend/`.
- `CLAUDE_backend.md` — early backend design notes (data model sketch, Vietnamese/Unicode DB
  conventions). It predates most of the current backend and is **out of date** on tech choices (it
  describes JdbcTemplate-only access and a 6-table schema; the backend has since grown into a full
  JPA-based domain with 149 entities, 92 controllers, 82 services). Its Unicode/`NVARCHAR`/
  `Vietnamese_CI_AI` guidance still applies whenever SQL Server is the target datasource.
- Current frontend work branch is `feature/frontend-ui-v2`; see `frontend/CLAUDE.md` §2 for the
  live status of in-progress UI phases before starting new frontend work.

Work on one side at a time and stay inside its directory unless a task explicitly spans both
(e.g. adding a new endpoint and wiring it into the Flutter client).

## Backend (repo root)

### Commands

```sh
./mvnw spring-boot:run                 # run the API (defaults to H2 in-memory, port 8080)
./mvnw test                            # run the full test suite
./mvnw test -Dtest=BookingTest          # run a single test class
./mvnw test -Dtest=BookingTest#createsBookingWithValidPayload   # single test method
./mvnw compile                         # compile only / fast check
```

`DataInitializer` (`config/DataInitializer.java`, active on any profile except `prod`) seeds demo
data (locations, categories, places, hotels, users, etc.) on startup — useful context when a test
or manual run behaves differently than expected.

By default the app runs against an in-memory H2 database (`spring.jpa.hibernate.ddl-auto=update`)
so no external DB setup is needed for local dev/tests. SQL Server (`mssql-jdbc`) is on the
classpath for real deployments — override `SPRING_DATASOURCE_*` env vars to point at it. Swagger
UI is available at `/swagger-ui.html` when running.

### Architecture

Layering is strict **Controller → Service → Repository → Model (JPA entity)**, with a `dto/`
package for request/response shapes (controllers do not return entities directly) and a small
`mapper/` package for entity↔DTO conversion. Package-by-layer, not package-by-feature — e.g. all
controllers live in `controller/` regardless of domain.

- **Auth**: stateless JWT. `security/JwtAuthenticationFilter` runs before
  `UsernamePasswordAuthenticationFilter`; `security/JwtService` issues/validates tokens;
  `security/UserPrincipal` / `AuthUser` carry the authenticated identity;
  `config/AuthUserResolver` injects it into controller method params.
- **Authorization**: role-gated by URL prefix in `config/SecurityConfig` — `/api/admin/**` requires
  `ROLE_ADMIN`, `/api/partner/**` requires `ROLE_PARTNER` or `ROLE_ADMIN` (except
  `/api/partner/profile/**`, just authenticated), everything else requires authentication except an
  explicit allowlist (`/api/auth/**`, `/api/health`, `/api/webhooks/payments/**`, public GETs on
  locations/categories/amenities/places/room pricing/rate-plans, Swagger, H2 console).
- **Errors**: `exception/GlobalExceptionHandler` (`@RestControllerAdvice`) converts exceptions to a
  uniform `{timestamp, status, error, message, path}` JSON body. `exception/ApiException` is the
  general-purpose thrown-from-service-layer exception carrying an explicit `HttpStatus`. Prefer
  throwing `ApiException` from services over ad-hoc exception types.
- **Concurrency**: two different locking strategies coexist by design — optimistic locking
  (`@Version`, surfaces as HTTP 409 via `GlobalExceptionHandler`) for some entities (e.g.
  `CustomerMembership`), pessimistic `SELECT ... FOR UPDATE` for others (e.g. `LoyaltyAccount`,
  `TravelCreditAccount`). Check the relevant service's class Javadoc before assuming which one
  applies to an entity you're changing.
- **Payments**: `PaymentProviderProperties`/`payment.providers.*` config supports multiple gateways
  (VNPay, PayOS, Stripe, MoMo). Webhook signature verification is real; the outbound checkout-API
  call is intentionally mocked/offline pending real provider credentials — don't assume a live
  payment integration exists.
- **Naming split**: three parallel controller families by audience — plain (`Booking`, `Trip`,
  `Place`, ...) for end users, `Admin*` for admin-only management endpoints, `Partner*` for
  property/partner-facing endpoints. When adding a feature, place the endpoint in the matching
  family rather than overloading an existing controller across audiences.
- Tests live under `src/test/java/com/example/planyourtrip/` as one flat package, one class per
  feature/domain (not mirroring the main package structure).

## Frontend (`frontend/`)

Flutter app; **read `frontend/CLAUDE.md` in full before making changes here** — it is maintained
as the permanent, detailed spec for this package (state management, demo-mode vs. real backend,
design system, UI-N phase/test/commit convention, accessibility, and git workflow rules). Quick
orientation only:

```sh
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api
flutter analyze
flutter test
flutter test test/some_test.dart
flutter gen-l10n
```

- Single global `AppState extends ChangeNotifier` (`lib/core/app_state.dart`) holds all app data;
  no per-feature repository/BLoC layer.
- `AppState.demoMode` switches every feature between an in-memory mock dataset
  (`lib/core/mock/mock_data.dart`) and (currently mostly unimplemented) real backend calls via
  `lib/core/network/api_client.dart`.
- Screens are under `lib/features/<domain>/`; shared design-system widgets under
  `lib/design/*` and `lib/shared/widgets/`.
