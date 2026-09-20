# Role / UI / Permission — Frozen Contract

**Status:** FROZEN · **Date:** 2026-08-27 · **Branch:** `develop` · **Backend HEAD at freeze:** `1c1115c`
**Frontend reference:** `feature/frontend-ui-v2` (integration repo, `frontend/`).

This document is the authoritative decision record for the Plan Your Trip role model, authorization
boundaries, and shipped UI surfaces. It precedes public production deployment (STEP 2+). It was produced
by a read-only audit of the authoritative backend worktree and the Flutter frontend; nothing in the
application was changed to write it. Where the repository does not define a concept, it is marked **TBD**
rather than invented.

> **Precedence:** if a design conversation or external material conflicts with this document, the
> *repository code* wins and the conflict must be raised explicitly before any change. Do not convert an
> assumption into "confirmed product truth."

---

## A. Role model freeze

**Confirmed system roles (exactly three):** `USER`, `PARTNER`, `ADMIN`.

- The system role is a single free-text `String` field, `User.role`, defaulting to `"USER"`
  (`model/User.java`). There is **no** role hierarchy and **no** multi-role assignment.
- `security/JwtAuthenticationFilter` grants exactly one authority per user: `"ROLE_" + user.getRole()`.
- Seed users (`config/DataInitializer`): `demo@planyourtrip.com` = USER, `partner@planyourtrip.com` =
  PARTNER, `admin@planyourtrip.com` = ADMIN.
- `ROLE_ADMIN` is the only `ROLE_` literal in the backend. `ADMIN` is the ceiling.

**Deliberately NOT modeled (TBD — do not implement without a confirmed spec):**

- **`SUPER_ADMIN`** — does not exist. Decision: **keep ADMIN-only**; `SUPER_ADMIN` stays TBD. Introducing
  it later is a real backend change (role hierarchy/authorities + endpoint gating + tests).
- **`SUPER_PARTNER`** — does not exist as a system role and has **no source truth** in the repository.
  Decision: **keep TBD**; do not fabricate a platform super-partner. The only elevated partner concept is
  the **intra-organization** `PartnerTeamRole` (below), which is scoped within a single partner org, not
  platform-wide.

**Partner team scoping (in-app, not a Spring role):** `model/PartnerTeamRole` = `OWNER, MANAGER,
FRONT_DESK, FINANCE, VIEWER`. Enforced in the **service layer** (e.g. `PartnerSettingsService`
`requireRole`/`requireOwner`, `PartnerProfileService` team-member checks), not by URL rules. This governs
who inside one partner organization may perform which partner action; it does not cross org boundaries.

---

## B. Authorization freeze

Authorization is **enforced server-side** — URL rules in `config/SecurityConfig` plus service-layer
ownership/team checks. The frontend performs **no** authorization and does not even read the system role.
Method security (`@PreAuthorize`) is used only 3× (redundant with URL rules).

**Ratified URL authorization map (verbatim intent from `SecurityConfig.securityFilterChain`):**

| Matcher | Rule |
|---|---|
| `/api/auth/**`, `/api/health/**`, `/api/webhooks/payments/**` | permitAll (webhooks are signature-verified) |
| `swagger-ui/**`, `v3/api-docs/**`, `h2-console/**` | permitAll **only when profile ≠ prod** (DB-06) |
| `GET` `/api/locations/**`, `/api/categories/**`, `/api/amenities/**`, `/api/places`, `/api/places/**`, `/api/rooms/*/pricing`, `/api/rooms/*/rate-plans[/**]`, `/api/trips/public/**` | permitAll |
| `POST` `/api/rooms/*/pricing/quote` | permitAll (read-only quote) |
| `/api/admin/**` | `hasRole("ADMIN")` |
| `/api/partner/profile/**` | `authenticated` (any logged-in user — partner onboarding) |
| `/api/partner/**` | `hasAnyRole("PARTNER", "ADMIN")` |
| any other request | `authenticated` |

Stateless JWT; CSRF disabled; sessions `STATELESS`; 401/403 emit the uniform JSON error body.

**Scope semantics (authoritative):**

- **Partner endpoints are self-scoped by identity.** Partner controllers resolve the partner via
  `partnerProfileRepo.findByUserId(uid)`. Therefore an `ADMIN` calling `/api/partner/**` resolves to
  *their own* (normally absent) partner profile → empty/404; it does **not** grant cross-partner data.
  Cross-partner administrative power flows only through `/api/admin/**`
  (`AdminPartnerController`, `PartnerProfileService.adminApprove`, etc.).
- **User data is owner-scoped** under `/api/me/**`.
- **Moderation lifecycle exists** in the domain model: `DRAFT → PENDING/SUBMITTED → APPROVED/REJECTED →
  PUBLISHED/ARCHIVED`. Approve/reject/publish are ADMIN operations.

**Frozen rule going forward:** hiding a control in any future UI is **not** authorization. Every
partner/admin action must remain enforced by a backend URL rule and/or service ownership check.

---

## C. Navigation / routing freeze

**Shipped frontend for this deployment = the USER APP only.**

- The Flutter app (`frontend/lib/features/`) covers customer domains only: auth, home, places,
  categories, hotels, bookings, payments, trips, planner, timeline, expenses, wallet, rewards, reviews,
  conversations, recommendations, ai, profile. Real-backend integration is complete through UI-52.
- `AppState` does not store the system role; `api_client.dart` calls only `/api/me/**`, `/api/places/**`,
  `/api/bookings`, `/api/reviews`, `/api/payments` — **no** `/api/partner/**` or `/api/admin/**`.
- **Partner Extranet, Admin CMS, and any Super Admin console have NO frontend.** Their backends exist and
  are tested, but building their UIs is **deferred** (see Deferred backlog). No role-based routing is
  introduced now.

---

## Confirmed vs TBD matrix

| Surface / Role | Backend | Frontend | Status |
|---|---|---|---|
| USER app | Yes (`/api/me/**`, public GETs) | Yes (complete, UI-52) | **CONFIRMED** |
| PARTNER extranet | Yes (15 `Partner*` controllers, 14 tests) | None | **CONFIRMED backend / UI DEFERRED** |
| ADMIN CMS | Yes (~37 `Admin*` controllers, 2 tests) | None | **CONFIRMED backend / UI DEFERRED** |
| SUPER_ADMIN | None | None | **TBD** |
| SUPER_PARTNER | None (only intra-org `PartnerTeamRole`) | None | **TBD** |

---

## Known gaps (documented, intentionally DEFERRED this phase)

1. **Partner Extranet frontend** — net-new Flutter surface against existing `/api/partner/**`.
2. **Admin CMS frontend** — net-new Flutter surface against existing `/api/admin/**`.
3. **`SUPER_ADMIN` role** — only if/when a confirmed spec exists; requires role hierarchy + gating + tests.
4. **`SUPER_PARTNER` model** — only if source truth is provided; otherwise remains TBD.
5. **General business-change audit trail** — today only `BookingCheckInAudit` / `BookingCheckOutAudit`
   entities + a partner activity log exist. A cross-entity actor/timestamp/before-after/reason trail for
   sensitive changes is **not** implemented.
6. **Negative authorization / IDOR test matrix** — partner ownership is exercised by the 14 `Partner*`
   tests, but there is no dedicated cross-tenant / vertical-privilege negative suite.

Each item is deferred by decision on 2026-08-27, not by oversight.

---

## Deferred roadmap (order; not started)

A. Role freeze (this doc) → B. Authorization freeze (this doc) → C. Navigation freeze (this doc) →
D. User UI polish → E. Partner Extranet frontend → F. Admin CMS frontend → G. Super Admin (only if
confirmed) → H. Super Partner (only if source truth) → I. API integration → J. role/authz tests →
K. full regression → L. production deployment (STEP 2+). Do not reach L until A–K are stable.

## Must not be regressed

Docker production stack, main-compose SQL Server edition, Flyway-owned schema, DB-06 production secret
validators and exposed-surface hardening, unpublished DB port and app:8080, and the completed user-app
real integration and passing test suites (backend 1408 pass / 1 gated-skip; frontend 1132 pass).

---

## Amendment A — Partner account lifecycle (Phase A, 2026-09-17)

**Status:** APPROVED product decision, recorded here as an explicit and narrow amendment. Only the points
below change; every other section of this document stands as written.

1. **Partner self-registration.** `POST /api/auth/partner/register` creates an account whose system role is
   `PARTNER`, assigned server-side. No request can choose or influence a role. The account must verify its
   email address before it can sign in. (`USER` self-registration is unchanged; `ADMIN` accounts are still
   only provisioned — `ProductionBootstrap` / `DataInitializer` — and never self-registered.)
2. **Business approval is unchanged and still required.** The Partner business profile lifecycle
   (`DRAFT → SUBMITTED → APPROVED / REJECTED`, `SUSPENDED`) and the Admin approve/reject/suspend operations
   are unchanged. Every Partner property, room, rate, calendar and booking operation still requires an
   `APPROVED` profile.
3. **Property publication (future phase — not implemented by Phase A).** Once the Property Commerce phase
   ships, an approved Partner publishes its own property without per-property Admin approval. Admin keeps the
   moderation states `HIDDEN`, `REJECTED` and `ARCHIVED`. For Partner-owned properties this will supersede
   the §B sentence "Approve/reject/publish are ADMIN operations"; until that phase ships, `PlaceStatus` is
   still changed only through the Admin place endpoints.
4. **Role model and URL authorization map: unchanged.** Still exactly `USER`, `PARTNER`, `ADMIN`. The backend
   now fails closed on any other stored role value (it authenticates nothing). The new public endpoints fall
   under the existing `/api/auth/**` permitAll rule; `PUT /api/me/password` falls under `authenticated`.

See `ACCOUNT_LIFECYCLE.md` for the implemented behaviour.
