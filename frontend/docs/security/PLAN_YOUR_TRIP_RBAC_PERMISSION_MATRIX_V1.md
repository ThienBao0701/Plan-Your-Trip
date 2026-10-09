# Plan Your Trip — RBAC & Permission Matrix V1.0

| | |
|---|---|
| **Status** | DESIGN — revision 1.1, ready to freeze. **Nothing in this document is implemented.** |
| **Date** | 2026-10-04 |
| **Revision** | 1.0 initial design → **1.1** resolves every finding of the final product/security review (verdict *PASS WITH FINDINGS*); see Appendix B |
| **Backend audited** | `develop` @ `0eeaee4` (worktree `Plan-Your-Trip-backend-v1`) |
| **Frontend audited** | `feature/frontend-ui-v2` @ `0bceacc` (`Plan-Your-Trip-integration/frontend`) |
| **Extends** | `ROLE_UI_PERMISSION_FREEZE.md` (backend repo root) §A–§C and its Amendment A |
| **Changes to code** | none — this is a design/audit document only |

**Precedence.** Until a phase in §32 ships, the repository code and `ROLE_UI_PERMISSION_FREEZE.md` remain
the authority. Where this document proposes changing a frozen rule it says so explicitly ("**Freeze change**").
The product decisions of §31 are locked for V1; everything else here becomes binding only when the phase that
implements it is approved.

**Path conventions** (line numbers are those at the audited baselines):

| Prefix | Meaning |
|---|---|
| `be/` | `Plan-Your-Trip-backend-v1/src/main/java/com/example/planyourtrip/` |
| `be-test/` | `Plan-Your-Trip-backend-v1/src/test/java/com/example/planyourtrip/` |
| `be-db/` | `Plan-Your-Trip-backend-v1/src/main/resources/db/migration/` |
| `fe/` | `Plan-Your-Trip-integration/frontend/lib/` |

The integration repository root also contains a `src/` tree and `pom.xml`: an older backend copy last changed
in "phase 7.30". It is **not** the authoritative backend and was not used for any statement below.

---

## 1. Executive summary

**What exists today.** Three system roles (`USER`, `PARTNER`, `ADMIN`), one Spring authority per request,
URL-prefix authorization, and **identity-based tenant scoping**: every Partner operational endpoint resolves
"the company whose registrant is the caller" through one of **13 copy-pasted `myApprovedProfileOrThrow`
helpers**. A five-value `PartnerTeamRole` (`OWNER, MANAGER, FRONT_DESK, FINANCE, VIEWER`) exists, but it is
honoured by exactly **one** service — `PartnerSettingsService` (settings, payout account, team). Every other
Partner endpoint answers a non-owner team member with 404, so delegated work (a receptionist checking a guest
in, an accountant reading statements) is impossible. Admin is all-or-nothing: `hasRole("ADMIN")` opens all
**181** admin endpoints in **38** controllers. There is no property-level scope anywhere.

**What this document specifies.**

1. Keep `USER` / `PARTNER` / `ADMIN` and the JWT exactly as they are. No new JWT roles, no permission claims.
2. Add two server-resolved layers under the system role:
   - **PARTNER → workspace membership** in one company (the existing `PartnerProfile`), holding one or more
     **grants** `(role, scope)` where scope is `COMPANY:<id>`, `PROPERTY:<id>` or `UNIT:<id>` (a room type).
   - **ADMIN → admin profiles** (one or more per administrator).
   - `USER` gets no RBAC layer: travellers stay owner-scoped by identity.
3. **9 partner roles** and **11 admin profiles** are **default permission bundles** over a catalogue of
   **100 permissions** (54 partner + 46 admin; 88 backed by existing endpoints, 12 reserved for capabilities
   that have no endpoint yet).
4. One normative evaluator (§4.5) classifies every endpoint as `RESOURCE`, `COLLECTION` or `COMPANY`, derives
   scope from the target **on the server**, applies **scope floors**, and makes 403-vs-404 depend on the
   resource type. A property grant can never act as a company grant.
5. Owner protection, last-owner locking, delegation limits, mandatory owner security notifications, step-up
   re-authentication, financial isolation, field-level protection of guest and payment data, and a
   never-readable class for bearer instruments are explicit invariants (§27).
6. Rollout is safe by construction: no migration ever hands owner-management or payout power to an account
   that does not have it today, and owner protections ship **before** the permission matrix is enforced (§32).

**Most important gaps found** (full register in §4.6): team roles unenforced outside settings (G1); a workspace
action silently promotes a traveller account to `PARTNER` (G3); no invitation consent and an account-enumeration
404 (G5); no owner/last-owner protection (G6); team changes unaudited and hard-deleted (G7); every team role can
read payout metadata (G8); room and calendar writes mix content, inventory and price in one payload (G10);
admin is a single all-powerful role (G12); an active team member can create a second company (G23); partner
booking responses carry traveller-only and payment-link fields (G25).

---

## 2. Current authorization architecture discovered in the repository

### 2.1 Authentication

| Step | Evidence | Behaviour |
|---|---|---|
| Token format | `be/security/JwtService.java:13` | Hand-rolled HS256. Claims: `sub` (user id), `email`, `ver` (token version), `exp` (24 h). **No role claim, no permission claim, no `iat`.** |
| Token parse | `be/security/JwtService.java:15` | Signature + expiry; a non-integer `ver` is invalid; missing `ver` reads as 0. |
| Per-request account check | `be/security/JwtAuthenticationFilter.java:46-54` | Loads the user on **every** request; authenticates only if `enabled` and `tokenVersion == ver`. |
| Role → authority | `be/security/JwtAuthenticationFilter.java:49-50`, `be/model/AccountRole.java` | `AccountRole.parse` is exact and fails closed; grants exactly one authority `ROLE_<role>`. Unknown/null/differently-cased roles grant nothing (request stays anonymous). |
| Principal | `be/security/UserPrincipal.java`, `be/config/AuthUserResolver.java` | Controllers receive `@AuthUser Long uid`; missing principal → `ApiException(401)`. |
| Fresh token on credential change | `PUT /api/me/password` (`ACCOUNT_LIFECYCLE.md` §6) | Returns a newly issued token; the pattern reused by step-up (§18 O-7). |

Consequence that this design relies on: **revocation is already immediate**. Because nothing about the account
is trusted from the token except `sub` and `ver`, anything the server resolves per request (membership,
grants, profiles) takes effect on the next request without touching the JWT.

### 2.2 URL authorization

`be/config/SecurityConfig.java:46-81` (stateless, CSRF disabled, uniform 401/403 JSON from the entry point and
access-denied handler at `:84-95`):

| Matcher | Rule |
|---|---|
| `/api/auth/**`, `/api/health/**`, `/api/webhooks/payments/**` | `permitAll` |
| Swagger / H2 console | `permitAll` only when profile ≠ `prod` |
| `GET /api/locations/**`, `/api/categories/**`, `/api/amenities/**`, `/api/places[/**]`, `/api/rooms/*/pricing`, `/api/rooms/*/rate-plans[/**]`, `/api/trips/public/**` | `permitAll` |
| `POST /api/rooms/*/pricing/quote` | `permitAll` |
| `/api/admin/**` | `hasRole("ADMIN")` (`:78`) |
| `/api/partner/profile/**` | `authenticated()` (`:79`) — onboarding |
| `/api/partner/**` | `hasAnyRole("PARTNER","ADMIN")` (`:80`) |
| everything else (incl. `/api/me/**`) | `authenticated()` (`:81`) |

**Method security is not used.** There is no `@EnableMethodSecurity` and no `@PreAuthorize` in `be/`; the
word appears only in three controller comments ("no per-controller @PreAuthorize needed"). The freeze
document's remark that `@PreAuthorize` is "used only 3×" is no longer accurate at `0eeaee4`.

### 2.3 Partner tenant resolution — two mechanisms

**(a) Owner-only, ×13.** These services each contain a private `myApprovedProfileOrThrow(userId)` that does
`partnerProfiles.findByUserId(userId)` → 404 `Partner profile not found` if absent → 403 `Partner profile is
not approved` unless `APPROVED`:

`ConversationService`, `PartnerActivityLogService`, `PartnerAnalyticsService`, `PartnerBookingService`,
`PartnerCalendarService`, `PartnerExtranetService`, `PartnerFinanceService`, `PartnerPricingService`,
`PartnerPromotionService`, `PartnerPropertyService` (`:386`), `PartnerRoomService`,
`PartnerVoucherVerificationService`, `ReviewService` (all in `be/service/`).

`findByUserId` only matches the **registrant** (`partner_profiles.user_id`, unique). A team member is never the
registrant, so all of these endpoints answer a team member with **404**.

**(b) Team-aware, ×1.** `be/service/PartnerSettingsService.java:234-246` `resolveAccess`:

```java
PartnerProfile ownProfile = partnerProfileRepo.findByUserId(userId).orElse(null);
if (ownProfile != null) { requireApproved(ownProfile); return new PartnerAccess(ownProfile, OWNER); }
PartnerTeamMember membership = teamMemberRepo.findByUserIdAndActiveTrue(userId)
    .orElseThrow(() -> new ApiException(NOT_FOUND, "Partner profile not found"));
requireApproved(membership.getPartnerProfile());
return new PartnerAccess(profile, membership.getRole());
```

Role checks there: `SETTINGS_WRITE_ROLES = {OWNER, MANAGER}` (`:32-33`), `PAYOUT_WRITE_ROLES = {OWNER, FINANCE}`
(`:34-35`), `requireRole` → 403 `Your role does not allow you to …` (`:253-256`), `requireOwner` → 403 `Only
the partner owner can manage team members` (`:258-261`).

**(c) Onboarding.** `PartnerProfileService.createOrUpdateMyProfile` (`be/service/PartnerProfileService.java:46-59`),
behind the `authenticated()` rule, creates a new profile for **any** signed-in caller who owns none — including
an active team member of another company (G23).

### 2.4 Ownership chain (cross-company protection that exists today)

| Resource | Ownership check | On mismatch |
|---|---|---|
| Property (`Place`) | `places.findByIdAndOwnerId(id, profileId)` — `be/repository/PlaceRepository.java:57`, used at `be/service/PartnerPropertyService.java:394` | 404 `Hotel not found` |
| Property list | `findAllByOwnerId(profileId)` (`PlaceRepository.java:54`) | — |
| Room (`HotelRoom`) | `ownedRoomOrThrow` in `PartnerRoomService:93`, `PartnerPricingService:184`, `PartnerCalendarService:115` (room → hotelDetail → place → owner) | 404 `Room not found` |
| Rate plan / occupancy price | `PartnerPricingService:169,193` | 404 |
| Booking | `ownedBookingOrThrow` (`booking.hotel.owner`) in `PartnerBookingService`; by code in `PartnerVoucherVerificationService:130` | 404 `Booking not found` |
| Promotion | `PartnerPromotionService.isOwnedTarget` / `validateTargetOwnership` — target type `HOTEL` (a **`hotel_details.id`**, resolved through `hotelDetails.findById`) or `ROOM` must belong to the caller; target type `ALL` is forbidden for partners (`:118-133`) | 404; 403 for `ALL` |
| Conversation | `ConversationService.ownedByPartnerOrThrow` (`:317`) compares the **denormalized** `conversations.partner_profile_id`; the partner list query is `findByPartnerProfileIdOrderByLastMessageAtDesc` (`be/repository/ConversationRepository.java:20`). `conversations.booking_id` is `NOT NULL` (`be/model/Conversation.java:22-24`) | 404 |
| Review reply | `ReviewService:292` | 404 |
| Finance / analytics `hotelId` filter | `PartnerFinanceService:256`; every analytics and finance endpoint already accepts an optional `hotelId` | 404 |

`Place` carries `owner` (`owner_partner_profile_id`, the authoritative tenant link), `ownerUser`
(`owner_user_id`, legacy, deliberately untouched by Phase C) and `createdBy` (`be/model/Place.java:80-92`).
Only `owner` is used for authorization; this design keeps it that way.

### 2.5 Admin authorization

- URL rule only. 38 `Admin*` controllers, 181 endpoints, 111 of them writes; no further check inside.
- Six user-facing services add an **owner-or-admin** override with a raw string comparison and answer a
  non-owner with **403**: `BookingService:306,342`, `InvoiceService:185`, `InventoryReservationService:290`,
  `PaymentGatewayService:509`, `PaymentService:265`, `ReviewService:351`
  (`if (!"ADMIN".equals(requestingUser.getRole())) throw 403 "Access denied"`).
- Partner lifecycle decisions are admin-only and audited: `PartnerProfileService.adminApprove/adminReject/
  adminSuspend` (`be/service/PartnerProfileService.java:147,202,226`).
- `HOTEL_ASSIGN_OWNER` (`be/service/PartnerPropertyService.java:362`) moves a property between companies.
- `BookingService.adminUpdateStatus` (`:874`) sets the status, and on `CANCELLED` only releases the inventory
  hold — it moves no money (refunds are separate endpoints).
- One endpoint, `PATCH /api/admin/places/{id}/status`, performs every listing status transition, including
  publication.

### 2.6 Who can write a system role

| Writer | Effect |
|---|---|
| `AuthService.java:163` (`newAccount`) | `USER` (traveller register) or `PARTNER` (partner register) — decided by endpoint, never by body |
| `ProductionBootstrap.java:168-169` | bootstrap `ADMIN`, enabled |
| `DataInitializer.java:548` | dev/test seed users |
| `PartnerProfileService.java:162-165` | on approval: registrant → `PARTNER` unless `ADMIN` |
| `PartnerSettingsService.java:167-170` | **on team add: any non-ADMIN/PARTNER target → `PARTNER`** |
| `AuthService.java:134`, `AccountService.java:118` | `tokenVersion + 1` on password change / reset |

No endpoint disables an account, changes a role administratively, or changes an email address
(`ACCOUNT_LIFECYCLE.md` §13; the only `setEmail` is in `AuthService.newAccount`).

### 2.7 Audit

| Trail | Evidence | Semantics |
|---|---|---|
| `AdminActivityLog` | `be/model/AdminActivityLog.java`, `be/service/AdminActivityLogService.java:83-101` | Append-only (repository does not extend `JpaRepository`); actor id + **email snapshot**; `before_state`/`after_state`; written **inside** the mutating transaction and **fails closed**; credential-shaped text refused (`FORBIDDEN` pattern `:58`). **114** distinct actions, pinned by `be-test/AdminAuditInfrastructureTest`. |
| `PartnerActivityLog` | `be/service/PartnerActivityLogService.java:42` | Best-effort: silently **no-ops** on a missing profile/actor; actor is a foreign key (no snapshot); no before/after; 7 actions in use: `BOOKING_STATUS_CHANGED`, `PAYOUT_ACCOUNT_UPDATED`, `PROMOTION_UPDATED`, `PROPERTY_CREATED`, `PROPERTY_UPDATED`, `RATE_PLAN_UPDATED`, `TEAM_MEMBER_ADDED`. |
| `BookingCheckInAudit` / `BookingCheckOutAudit` | `PartnerCheckInService:157-165`, `PartnerCheckOutService` | Records `partnerProfileId` and `partnerUserId` per operation. |

### 2.8 Error semantics today

| Situation | Response |
|---|---|
| No / invalid / expired / version-mismatched token, disabled account, unknown role | 401 (entry point, `SecurityConfig:85-89`) |
| Authenticated, wrong URL tree (e.g. `USER` → `/api/partner/**`) | 403 (access-denied handler, `SecurityConfig:90-94`; `GlobalExceptionHandler:99`) |
| Partner: no own profile and no active membership | 404 `Partner profile not found` |
| Partner: profile not `APPROVED` | 403 `Partner profile is not approved` (no `code`) |
| Partner: resource of another company | 404 (same body as a missing id) |
| Partner team role insufficient (settings service only) | 403 with a message, no `code` |
| User side: another user's booking/invoice/payment/review | **403** `Access denied` (existence leak; see §26) |
| Unmapped route (e.g. `PATCH /api/partner/hotels/{id}/status`) | **500** — `NoResourceFoundException` is not handled; only `NoHandlerFoundException` is (`GlobalExceptionHandler:105`, catch-all `:181`) — observed in Phase C |

Phase A added an optional `code` and `fieldErrors` to the uniform error body (`be/exception/ApiException.java`).

### 2.9 Frontend

| Piece | Evidence | Behaviour |
|---|---|---|
| Surfaces | `fe/app/app_surface.dart:54` `admits` | Three origins; each admits exactly one system role. Partner surface refuses `ADMIN` (and `USER`) although the backend URL rule admits `ADMIN`. |
| Root gate | `fe/app/surface_gate.dart:46` | No session → sign-in; wrong role → `SurfaceAccessDeniedScreen`; else shell. Documented as UX routing, not authorization. |
| System role | `fe/core/app_role.dart` | `AppRole.parse` exact, fails closed to `unknown`. |
| Admin guard | `fe/features/admin/admin_routes.dart:65` `AdminRouteGuard`; `fe/core/admin/admin_state.dart:52` | `ADMIN` only. No admin sub-permissions. |
| Team role mirror | `fe/core/partner/partner_models.dart:54-90` | Same five values + `unknown`; `canEditSettings`, `canEditPayout`, `canManageTeam` mirror the backend sets. |
| Role resolution | `fe/core/partner/partner_state.dart:234` | Profile owner ⇒ `OWNER` (no request). |
| Team members | `fe/core/partner/partner_state.dart:259-280` | A non-owner member ends in `PartnerWorkspaceStatus.teamMemberUnsupported` — the workspace is unusable for them, matching the backend's 404s. |
| Navigation | `fe/features/partner/partner_navigation.dart:99-100` | `isWritableBy`: only `settings` is role-filtered. |
| Client gating sites | `partner_properties_screen.dart:200,447`, `partner_rooms_screen.dart:438`, `partner_rates_screen.dart:519`, `partner_inventory_screen.dart:543`, `partner_promotions_screen.dart:426` (`teamRole == owner`); `partner_policies_state.dart:422-426`; `partner_settings_screen.dart:165,569` | Six owner-only checks + policy/settings/team/payout mirrors. |
| Server menu | `be/service/PartnerExtranetService.java:109-131` | Returns all 13 destinations with `visible=true`, independent of role. |

### 2.10 Sensitive fields partners receive today, and protections that already exist

- `PartnerBookingDetailResponse` embeds the **traveller** `BookingResponse` (`be/dto/BookingDto.java:45-80`):
  `userId`, `userFullName`, `userEmail`, `specialRequest`, `partnerNote`, `cancelReason`, `couponCode`,
  `couponDiscountAmount`, `creditAmountUsed`, `loyaltyDiscountAmount`, `loyaltyPointsRedeemed`,
  `giftCardAmountUsed`, plus `PaymentResponse` rows with `provider`, `providerTransactionId`, `checkoutUrl`,
  `failureReason` (`be/dto/PaymentDto.java:16-32`). The summary row carries `guestName`, `guestEmail`.
- Existing protections to preserve:
  - `PartnerGuestStayDto` deliberately excludes payment/transaction ids, gift-card codes, coupon secrets,
    loyalty ledger detail, JWTs, the voucher signing secret and **any QR payload** (class javadoc).
  - The voucher `qrPayload` (HMAC-signed `PYT-V1.<bookingCode>.<sig>`, `be/dto/BookingVoucherDto.java:24-30`) is
    returned only by `GET /api/me/bookings/{bookingId}/voucher` to the booking's traveller.
  - `GiftCardResponse.fullCode` is populated only in the response of a successful issuance or claim/activation;
    every other read path, including admin listings, returns `maskedCode` only (`be/dto/GiftCardDto.java:121-128`).
  - `payment_sessions.callback_token` (`be-db/V1__initial_schema.sql:50`) appears in no response DTO.

---

## 3. Current roles and where they are used

### 3.1 System roles

| Role | Created by | Enforced by | Read by the frontend |
|---|---|---|---|
| `USER` | `POST /api/auth/register` | `authenticated()` rules; owner checks in user services | `AppSurface.user` |
| `PARTNER` | `POST /api/auth/partner/register`; Admin approval of a traveller application (`PartnerProfileService:163`); **team add** (`PartnerSettingsService:168`) | `/api/partner/**` URL rule + the tenant resolution of §2.3 | `AppSurface.partner` |
| `ADMIN` | `ProductionBootstrap` (prod), `DataInitializer` (dev/test) — never self-registered | `/api/admin/**` URL rule; owner-or-admin overrides (§2.5); also admitted on `/api/partner/**` | `AppSurface.admin`, `AdminRouteGuard` |

### 3.2 Partner team roles (`be/model/PartnerTeamRole.java`)

| Role | Backend rule that names it | Effect today |
|---|---|---|
| `OWNER` | implicit for the registrant (`resolveAccess:236-238`); `requireOwner` (team add/update/remove); in both write sets | Full access as registrant. A *non-registrant* member with role `OWNER` can manage the team but still gets 404 on every operational endpoint. |
| `MANAGER` | `SETTINGS_WRITE_ROLES` | Can write `/api/partner/settings`; nothing else beyond reads of settings/payout/team. |
| `FINANCE` | `PAYOUT_WRITE_ROLES` | Can write `/api/partner/payout-account`; cannot read `/api/partner/finance/**` (404). |
| `FRONT_DESK` | — (no rule names it) | Can only read settings, payout metadata and team. Cannot check anyone in. |
| `VIEWER` | — | Same reads as `FRONT_DESK` (test `PartnerSettingsTest.viewer_cannotUpdateSettings`). |

Storage: `partner_team_members(partner_profile_id, user_id, role, active, invited_at, joined_at, …)` with unique
`(partner_profile_id, user_id)` (`be-db/V1__initial_schema.sql:48,176`) and a **system-named CHECK constraint**
`role in ('OWNER','MANAGER','FRONT_DESK','FINANCE','VIEWER')` (`:48`). Approval lazily creates the registrant's
OWNER row (`PartnerProfileService.ensureOwnerTeamMember`, `:187-199`).

Tests: `be-test/PartnerSettingsTest` covers team add/update/remove, `viewer_cannotUpdateSettings`,
`finance_canUpdatePayoutMetadata`, unapproved and unauthenticated refusal. There is no cross-tenant or
per-role negative matrix for the other 14 partner controllers.

### 3.3 Other role-like concepts (not part of this RBAC)

| Concept | Where | Why it is out of scope |
|---|---|---|
| `TripCollaboratorRole` (`EDITOR`, …) | `TripPlannerService:359` and 5 sibling services | Traveller trip sharing; owner-scoped per trip. Untouched. |
| `PartnerVerificationStatus` (`DRAFT, SUBMITTED, APPROVED, REJECTED, SUSPENDED`) | `be/model/PartnerVerificationStatus.java` | Company **lifecycle gate**, kept as a precondition (§24 B4), not a role. |
| `PlaceStatus` | `be/model/PlaceStatus.java` | Listing lifecycle and public visibility (`PublicListingVisibility`). Not changed. |
| `MessageSenderRole` | conversations | Message attribution, not authorization. |

---

## 4. Proposed RBAC architecture

### 4.1 Layers

```
Request
  └─ L0 Authentication ............ unchanged — JWT sub + ver, account enabled, exact system role
  └─ L1 System role / URL tree .... unchanged — USER | PARTNER | ADMIN
  └─ L2 Context
        USER    → none (owner-scoped by identity, as today)
        PARTNER → the caller's single workspace W (own PartnerProfile, or the one ACTIVE membership),
                  company APPROVED for operational endpoints
        ADMIN   → admin profile assignments (≥ 1)
  └─ L3 Permission ................ union of the permission bundles of the caller's grants/profiles
  └─ L4 Scope (partner only) ...... grants at COMPANY / PROPERTY / UNIT, filtered by scope floors,
                                     matched against the target derived from the database
  └─ L5 Business rules ............ lifecycle, owner protection, last owner, delegation, step-up
```

A request is allowed only if **every** layer allows it. L0/L1 stay in the security filter chain exactly as
today. L2–L5 are evaluated by one server-side authorization service, never by the client.

### 4.2 Vocabulary (mapped to existing entities — no new "company" entity)

| Term | Is | Identifier |
|---|---|---|
| **Company** / workspace | the existing `PartnerProfile` | `partner_profiles.id` |
| **Primary owner** | `PartnerProfile.user` (the registrant) | `partner_profiles.user_id` |
| **Property** | `Place` + its `HotelDetail` | `places.id`, tenant via `places.owner_partner_profile_id` |
| **Unit** | `HotelRoom` — in V1 a **room type** (sellable type with a `quantity`); physical rooms do not exist in the schema (§31 Q9) | `hotel_rooms.id` |
| **Membership** | a `partner_team_members` row; status `ACTIVE`, `SUSPENDED` or `REVOKED` | `partner_team_members.id` |
| **Grant** | `(role, scopeType, scopeId)` attached to a membership | new (§12.3) |
| **Scope floor** | the narrowest grant type that may satisfy a permission: `C`, `P` or `U` (§4.5) | attribute of a permission |
| **Endpoint kind** | `RESOURCE`, `COLLECTION` or `COMPANY` (§4.5); onboarding/self endpoints are `SELF` | attribute of an endpoint |
| **Parent context** | the minimal identity of the property/room a grant sits inside (§11.7) | — |
| **Admin profile** | a named bundle of admin permissions held by an `ADMIN` account | new (§12.4) |

### 4.3 Principles

1. **Roles are default bundles, permissions are the unit of enforcement.** Code checks permissions, never
   role names (one documented exception: the primary-owner identity in §18).
2. **Business capabilities, not screens.** One permission per capability that a backend endpoint protects.
3. **One vocabulary for both tiers.** The same permission keys are evaluated by the backend and returned to
   the frontend.
4. **Scope comes from the resource, not the request.** The server derives company, property and unit from the
   id being acted on. A client-supplied company id, owner id or scope is never trusted (Phase C already ignores
   a body `ownerId`; the same rule generalises).
5. **A narrower grant never widens.** A `PROPERTY` or `UNIT` grant never satisfies a company-level check.
6. **Fail closed.** Unknown role, unknown permission key, unknown scope, missing membership, non-`ACTIVE`
   membership, non-`APPROVED` company → no access.
7. **Least privilege by default; delegation never exceeds the delegator.**
8. **Security-sensitive mutations are audited transactionally** (the `AdminActivityLog` standard, not the
   best-effort partner log), and owners are always told about them.

### 4.4 Why not more JWT roles, and why not Spring authorities for permissions

- JWT roles would be stale for up to 24 h and cannot express "PROPERTY:123". The filter already re-reads the
  account per request, so server-side resolution costs one more indexed lookup and gives immediate revocation.
- A flat `GrantedAuthority` list cannot express scope. Permissions are therefore evaluated by a dedicated
  service that receives `(user, permission, endpoint, target)`; `ROLE_*` authorities remain for L1 only.

### 4.5 Normative evaluator

This section is the single source of truth for authorization decisions. Every later section (scope §11,
access document §25.2, errors §26, invariants §27) is a consequence of it.

**Definitions**

```
W(user)            the caller's workspace:
                     own PartnerProfile if one exists (any status), else
                     the company of the caller's single ACTIVE membership, else none.
                   WS-1 (§11.6) guarantees at most one candidate.
G(user)            the caller's effective grants in W:
                     ∅ unless W.verificationStatus == APPROVED (operational endpoints only);
                     primary owner (W.user == user) ⇒ { OWNER@COMPANY:W };
                     otherwise the grants of the ACTIVE membership.
floor(p)           C → {COMPANY}   P → {COMPANY, PROPERTY}   U → {COMPANY, PROPERTY, UNIT}
E(p)               effective scopes of permission p:
                     { g.scope | g ∈ G(user), p ∈ bundle(g.role), g.scope.type ∈ floor(p) }
                   A grant below p's floor contributes nothing to E(p) — it is not "rounded up".
covers(s, t)       COMPANY:c  covers every property and unit of c
                   PROPERTY:p covers PROPERTY:p and every UNIT of p
                   UNIT:u     covers UNIT:u only
                   Never upward: PROPERTY never covers COMPANY; UNIT never covers PROPERTY.
view(type)         the designated view permission of a resource type (table below).
scopeOf(type, id)  the target's (company, property, unit) read from the database (§11.2).
```

**Designated view permission per resource type** (used for the 403-vs-404 decision):

| Resource type | view(type) | | Resource type | view(type) |
|---|---|---|---|---|
| property | P14 `partner.property.view` | | booking (incl. by code), stay | P34 `partner.booking.view` |
| room (unit) | P21 `partner.room.view` | | conversation | P42 `partner.conversation.view` |
| calendar day / inventory | P26 `partner.inventory.view` | | review (of a place) | P44 `partner.review.view` |
| rate plan, occupancy price | P29 `partner.rate.view` | | membership | P07 `partner.team.view` |
| promotion | P32 `partner.promotion.view` | | invitation | P07 `partner.team.view` |

**Endpoint kinds.** Every partner handler is registered (§24 B11) with exactly one kind, one primary
permission `p`, and — for `RESOURCE`/`COLLECTION` — one resource type.

```
RESOURCE (one identified target: GET/PUT/PATCH/DELETE …/{id}, actions on a booking code, writes whose body
          names a target such as a promotion's HOTEL/ROOM)
  1. t := scopeOf(type, id)                       missing                     ⇒ 404
  2. t.company ≠ W                                                             ⇒ 404
  3. ∃ s ∈ E(p) with covers(s, t)                                              ⇒ ALLOW → L5
  4. ∃ s ∈ E(view(type)) with covers(s, t)                                     ⇒ 403 PERMISSION_DENIED
  5. otherwise                                                                 ⇒ 404
     (a member without the resource type's view permission never learns that the id exists, even if an
      unrelated view permission — e.g. property.view — covers the same property)

COLLECTION (lists and aggregates of a resource type: GET /hotels, /bookings, /analytics/*, /finance/revenue …)
  1. E(p) = ∅                                                                  ⇒ 403 PERMISSION_DENIED
     (a collection's existence is not secret)
  2. S := ⋃ { properties (or units, for unit collections) covered by s | s ∈ E(p) }
     COMPANY:W contributes every property of W; PROPERTY:p contributes {p}; UNIT:u contributes {u}
  3. the query and every aggregate are computed in the database over S only (§24 B5, §20 FI-3)
  4. an optional filter (e.g. ?hotelId=) outside S                             ⇒ 404 (same as a missing id)
  5. endpoints marked "COMPANY ONLY" in §25.1 are not COLLECTIONs; they are COMPANY endpoints

COMPANY (company-level objects: settings write, team, payout account, statements, payouts, activity log,
         property create)
  1. ∃ s ∈ E(p) with s.type == COMPANY                                         ⇒ ALLOW → L5
  2. otherwise                                                                 ⇒ 403 PERMISSION_DENIED
  Exception — workspace entry (P01, floor U): satisfied by ANY grant in G(user), whatever its type; the
  response is filtered block by block (each block needs its own permission and is computed over S).

SELF (outside the workspace evaluator: /api/partner/profile/**, /api/partner/me/access, /api/me/**)
  authorized on the caller's own identity and account state only (§25.2, §25.3, §25.6).
```

**Effective permission calculation** (what `GET /api/partner/me/access` returns, §25.2): for every partner
permission `p` and every `s ∈ E(p)`, list `p` under `s` — company list for `COMPANY:W`, the property map for
`PROPERTY:id`, the unit map for `UNIT:id`. A permission whose only bundle grants sit below its floor is **not**
listed (a property-scoped MANAGER's bundle contains `partner.finance.statement.view`, but it never appears).

**Field-level permissions.** After ALLOW, the response mapper drops or masks fields whose own permission is
not in `E(field permission)` for the target (§21.2). Fields in the never-to-partner set (§21.3) are dropped for
everyone and are not listed as redacted.

**Admin namespace.** `admin.*` permissions have no scope: allowed iff the permission is in the union of the
caller's active admin profiles. Two admin endpoints are value-dependent: `PATCH /api/admin/places/{id}/status`
needs A46 when the target status is `PUBLISHED` and A15 otherwise (§9.2). Admin responses mask guest identity
and contact unless the caller holds A05 (§21.4).

**L5 business rules** run only after ALLOW and may still refuse: 409 (`LAST_OWNER_REQUIRED`,
`WORKSPACE_CONFLICT`, `CONCURRENT_MODIFICATION` …), 422 (`SCOPE_INVALID`), 403 (`OWNER_PROTECTED`,
`ROLE_NOT_DELEGABLE`, `SELF_MODIFICATION_FORBIDDEN`, `STEP_UP_REQUIRED`).

### 4.6 Gap register — current implementation vs. proposed model

| # | Gap / conflict | Evidence | Resolved by |
|---|---|---|---|
| G1 | Team roles are not enforced outside settings/payout/team; non-owner members get 404 on all other partner endpoints | §2.3 (13 owner-only helpers) | §4.5, §24 B1, phase R3b |
| G2 | Workspace is implicit and single: `findByUserIdAndActiveTrue` returns `Optional`, but the unique key is `(profile,user)`, so two active memberships of one user make the lookup throw (→ 500). A registrant's own profile silently wins over any membership | `be/repository/PartnerTeamMemberRepository.java:13`, `PartnerSettingsService:235-242` | §11.6 WS-1, §28 M-0/M-6 |
| G3 | A partner workspace action changes a **system role**: team add promotes a `USER` to `PARTNER`; removal never reverts it; the promoted account is then refused by the traveller surface (`AppSurface.user` admits only `USER`) | `PartnerSettingsService:167-170`, `fe/app/app_surface.dart:54-58` | §5 R-S2, §14, phase R3a |
| G4 | An `ADMIN` account can be added to a partner team (role kept), mixing platform and tenant powers | `PartnerSettingsService:167` | §5 R-S3, §28 M-6 |
| G5 | No invitation or consent: a member is attached directly (`invitedAt = joinedAt = now`); `404 "User not found: <email>"` enumerates accounts | `PartnerSettingsService:158-179` | §13–§14 |
| G6 | Any `OWNER` member may grant `OWNER`, demote or delete other owners, including the registrant's own OWNER row (harmless only because `resolveAccess` ignores that row); no last-owner rule | `PartnerSettingsService:195-213` | §18–§19, phase R3a |
| G7 | `updateTeamMember` / `removeTeamMember` / `updateSettings` write no audit row; removal is a hard `delete`; the partner log is best-effort and has no actor snapshot | `PartnerSettingsService:195-213,70-86`; `PartnerActivityLogService:42` | §17, §22, §28 M-4 |
| G8 | Every team role reads payout metadata (`getPayoutAccount` has no role check) and the full team list with emails | `PartnerSettingsService:91-96,142-146` | §20, §21 |
| G9 | No property scope: every membership is implicitly company-wide | — | §4.5, §11–§12 |
| G10 | Mixed payloads: `PUT /api/partner/rooms/{id}` writes content **and** `priceFrom`, `originalPrice`, `quantity`, `availableQuantity` (`HotelRoomService.update`/`fill`); calendar `PUT …/{date}` and `POST …/bulk` write inventory counts **and** `stopSell`/`closedArrival`/`closedDeparture` (`RoomInventoryRequest`) | `be/service/HotelRoomService.java:137-149,237-240`; `be/dto/RoomInventoryDto.java:12-21` | §24 B9 field-diff rule |
| G11 | Mixed-sensitivity responses: booking summary carries `guestEmail`; booking detail carries payments, invoice and price breakdown; dashboard carries `revenueToday`/`revenueMonth`; extranet home embeds the finance overview | `be/dto/PartnerBookingDto.java`, `be/dto/PaymentDto.java:16-32`, `PartnerExtranetService:83-106` | §20–§21 field-level rules |
| G12 | Admin is all-or-nothing (181 endpoints) | §2.5 | §7, phase R6 |
| G13 | Owner-or-admin overrides use raw `"ADMIN".equals(...)` and answer 403 (existence leak), unlike the partner 404 convention | §2.5 | §26, phase R7 |
| G14 | `HOTEL_ASSIGN_OWNER` moves a property between companies; with property-scoped grants this would leave stale cross-company access | `PartnerPropertyService:362` | §16 PA-4 |
| G15 | The server menu marks all 13 destinations visible for everyone | `PartnerExtranetService:118-130` | §23 F4 |
| G16 | Frontend hard-codes `teamRole == owner` in six places and parks members in `teamMemberUnsupported` | §2.9 | §23, phase R5 |
| G17 | Unmapped routes answer 500 instead of 404 | `GlobalExceptionHandler:105,181` | §26, phase R7 |
| G18 | `/api/partner/**` admits `ADMIN` while the partner surface refuses it | `SecurityConfig:80`, `app_surface.dart:54` | §31 Q13, phase R7 |
| G19 | New team roles need the system-named CHECK constraint on `partner_team_members.role` replaced; prod `ddl-auto=validate` does **not** validate CHECK constraints and dev/test H2 runs with Flyway off, so a forgotten widening fails only at runtime in production | `be-db/V1__initial_schema.sql:48`; `application.properties:13`; `application-prod.properties:34,41` | §28 M-1 |
| G20 | Payout-change notification goes only to the registrant, and partner notification toggles live in `PartnerSettings`, which MANAGER can edit | `PartnerSettingsService:278-283`; `be/model/PartnerSettings.java` | §18 O-8 mandatory security notifications |
| G21 | `GET /api/partner/team` does not identify the caller's row, so the client cannot learn its own role | `fe/core/partner/partner_state.dart:276-278` | §25.2 `GET /api/partner/me/access` |
| G22 | No admin account management (no endpoint changes `users.role` or `enabled`), so admin profiles need a provisioning path | `ACCOUNT_LIFECYCLE.md` §13 | §7, A02 |
| G23 | `POST /api/partner/profile` creates a company for any caller without an own profile — including an active member of another company | §2.3 (c) | §11.6 WS-2, I21, phase R3a |
| G24 | Conversation authorization and listing use the denormalized `conversations.partner_profile_id`, which a property move does not update | §2.4 | §16 PA-4, §11.2 |
| G25 | Partner booking responses embed traveller-only and payment-link fields (`userId`, `loyaltyPointsRedeemed`, `checkoutUrl`, raw `failureReason`) | §2.10 | §21.3, phase R3b |

---

## 5. Top-level security boundaries

| Boundary | Surface | API tree | Holds | Can never |
|---|---|---|---|---|
| `USER` | traveller app | `/api/me/**`, public reads, user-owned resources | own data; no RBAC layer | reach `/api/partner/**` (403) or `/api/admin/**` (403); hold a partner membership or admin profile; accept a partner invitation |
| `PARTNER` | Partner workspace | `/api/partner/**` | own company **or** ≤ 1 active workspace membership (V1) with grants | reach `/api/admin/**`; act on another company's data; change any system role |
| `ADMIN` | Admin console | `/api/admin/**` | ≥ 1 admin profile | act *as* a partner member (no membership, R-S3); bypass the admin audit trail |

Rules:

- **R-S1** The three system roles, their creation paths and the URL rules of §2.2 are unchanged.
- **R-S2 (Freeze change)** No workspace action changes `users.role`. Team invitation requires the invitee to
  hold a `PARTNER` account (§14). The `USER → PARTNER` promotion in `PartnerSettingsService:167-170` is removed
  in phase **R3a**. (The promotion at Admin approval of a traveller's own application,
  `PartnerProfileService:162-165`, is a platform decision and stays.)
- **R-S3** An `ADMIN` account can never hold a partner membership, and a `PARTNER` account can never hold an
  admin profile. Separation of duties is per account. Existing violations are remediated by M-6 (§28).
- **R-S4** Permissions never travel in the JWT; L2–L5 are resolved per request. Freshness for step-up is
  derived from the existing `exp` claim (§18 O-7) — the JWT format does not change.
- **R-S5** A partner permission can never satisfy an admin check and vice versa (namespaces, §8).
- **R-S6** `USER` remains outside this RBAC: traveller data stays owner-scoped by identity.

---

## 6. Partner workspace roles

Roles are **default bundles** (§10.1). `Existing` = value already in `PartnerTeamRole`; `New` = requires the
enum and CHECK widening of §28 M-1.

| Role | Status | Purpose | Allowed scopes | Assignable by | Bundle size |
|---|---|---|---|---|---|
| `OWNER` | Existing | Legal/commercial owner of the company; full control incl. ownership, security, payout | COMPANY only | OWNER only (P12, step-up) | 54 |
| `MANAGER` | Existing | General manager: runs operations and the below-manager team; no ownership, no bank/payout | COMPANY, PROPERTY | OWNER | 47 |
| `REVENUE` | New | Pricing, inventory, restrictions, promotions, revenue reporting; guest names masked | COMPANY, PROPERTY | OWNER, MANAGER | 17 |
| `RESERVATIONS` | New | Bookings back-office: guest identity and contact, no-shows, guest messaging, emergency stop-sell | COMPANY, PROPERTY | OWNER, MANAGER | 16 |
| `FRONT_DESK` | Existing | Arrivals and departures, vouchers, in-stay guest identity and contact | COMPANY, PROPERTY | OWNER, MANAGER | 16 |
| `FINANCE` | Existing | Statements, payouts, payout account, payment records, reconciliation (guest names visible) | COMPANY only | OWNER | 13 |
| `CONTENT` | New | Property and room descriptions, amenities, media, review replies | COMPANY, PROPERTY | OWNER, MANAGER | 8 |
| `HOUSEKEEPING` | New | Room readiness (domain not built yet — 2 of its 5 permissions are reserved) | PROPERTY (default), UNIT | OWNER, MANAGER | 5 |
| `VIEWER` | Existing | Read-only operational oversight; guest names masked, no guest contact, no financial aggregates | COMPANY, PROPERTY | OWNER, MANAGER | 9 |

Notes:

- `FINANCE` is COMPANY-only because statements, payouts and the payout account are company-level objects
  (`partner_payout_accounts` is unique per profile).
- `HOUSEKEEPING` is the only role that accepts `UNIT` scope in V1. A UNIT-scoped housekeeper enters the
  workspace (P01, floor `U`) and sees the parent property's context (§11.7) without holding property view.
- `OWNER` at `PROPERTY` scope is invalid by definition — ownership is of the company.
- Legacy non-registrant `OWNER` rows are carried as `MANAGER` until the primary owner confirms them (§18 O-9).
- `SUPER_PARTNER` remains **not modelled** (freeze §A); `OWNER` is intra-company and never platform-wide.

---

## 7. Admin profiles

All holders are `ADMIN` accounts. An administrator may hold several profiles; effective permissions are the
union. Admin permissions are platform-wide (no tenant scope in V1; see §30 for regional scope).
`GROWTH_MARKETING` is added in revision 1.1 (§31 Q11) so discount programmes are no longer held by finance.

| Profile | Purpose | Key capabilities | Explicitly excluded |
|---|---|---|---|
| `PLATFORM_OWNER` | Ultimate platform authority | all 46 admin permissions; sole holder of `admin.access.manage`, `admin.place.owner.assign` and `admin.notification.broadcast` | — |
| `PARTNER_OPERATIONS` | Partner onboarding and supply operations | verify/suspend partners, inventory and rates on behalf of partners, owner recovery (reserved, dual control) | moving properties between companies (A16), refunds, payments, catalogue content, admin access |
| `CONTENT_CATALOGUE` | Listing quality and taxonomy | place/hotel/room content, media, categories, amenities, moderation **and** publication, personalization | money, partner verification, locations |
| `BOOKING_SUPPORT` | Customer and booking support | booking view/operate/override, conversations, customer view and wallet view, payment/invoice **read** | refunds, credits, compensation, invoice changes |
| `FINANCE_OPERATIONS` | Money movement and stored value | refunds, payment interventions, invoices, compensation, gift-card **value**, credits, entitlements, partner payouts (reserved) | creating discount programmes, booking status override, partner verification, catalogue |
| `GROWTH_MARKETING` | Discount and loyalty programme design | promotions, coupon definitions, gift-card products, customer programmes, personalization, aggregate analytics | issuing or adjusting stored value, refunds, customer PII, broadcast |
| `TRUST_SAFETY` | Abuse, fraud, policy enforcement | audit log, suspend partners, hide/reject/archive listings, conversations, review moderation, account disable (reserved) | publishing or featuring listings, money, catalogue editing |
| `REVIEW_MODERATION` | Review queue | review view/moderate, place read | everything else |
| `ANALYTICS` | Aggregate reporting | analytics overview and review analytics overview | any row-level data, any PII, any write |
| `LOCATION_CATALOGUE` | Administrative-unit hierarchy | location management, place read | categories, amenities, places |
| `TECH_SUPPORT` | Incident diagnosis and scheduled-job recovery | audit log, booking/payment **read** (guest identity masked), system jobs | every business write |

Rules:

- **AP-1** Only `PLATFORM_OWNER` grants or revokes profiles (A02). Nobody grants a profile to themselves.
- **AP-2** At least one active `PLATFORM_OWNER` must exist (same mechanics as §19).
- **AP-3** Profile changes take effect on the next request and are audited (`ADMIN_PROFILE_GRANT`,
  `ADMIN_PROFILE_REVOKE`).
- **AP-4** Backfill (§28 M-5): every existing `ADMIN` becomes `PLATFORM_OWNER`, so today's behaviour is preserved
  until profiles are deliberately narrowed.
- **AP-5** Tenant-boundary and stored-value actions follow the dual-control principle of §22.6; until dual
  control is enforced, A16 is `PLATFORM_OWNER`-only.
- **AP-6** Guest identity and contact in admin booking/payment responses are masked for any caller without
  A05 `admin.customer.view` (§21.4) — in practice `TECH_SUPPORT` and `PARTNER_OPERATIONS`.

---

## 8. Permission taxonomy

### 8.1 Key grammar

```
<namespace>.<resource>[.<sub-resource>].<action>
namespace  ∈ { partner, admin }
resource   = lower_snake business noun        (property, room, inventory, rate, booking, payout_account …)
action     ∈ { access, view, create, edit, manage, toggle, activate, operate, mark, reply, respond,
               invite, assign, suspend, remove, transfer, verify, moderate, publish, adjust, intervene,
               run, … }
```

Examples: `partner.property.content.edit`, `partner.booking.guest_identity.view`, `admin.place.publish`.

Permission keys are deliberately different from audit action codes (`PROPERTY_CREATED`, `PARTNER_APPROVE`),
which stay `UPPER_SNAKE` verbs describing what happened.

### 8.2 Attributes of every permission

| Attribute | Values |
|---|---|
| Namespace | `partner` · `admin` |
| Class | `R` read · `W` write · `S` sensitive read (PII / money) · `X` security (team, ownership, access, tenant boundary) · `$` financial or stored-value write |
| Scope floor (partner) | `C` satisfied only by a COMPANY grant · `P` COMPANY or PROPERTY grant · `U` any grant type (COMPANY, PROPERTY or UNIT) — see §4.5 |
| Delegation | `D` delegable to any role whose bundle contains it · `O` owner-only, never delegable · `F` delegable only to FINANCE |
| Status | `ACTIVE` — protects an existing endpoint or field · `RESERVED` — capability has no endpoint yet; key reserved so roles can be designed now |

### 8.3 Stability rules

- A key and its identifier (`P01`, `A46` …) are a public contract between backend and frontend. They are never
  renamed, reused or renumbered; a replacement is added and the old key is deprecated with an alias for one
  phase. Identifiers are not an ordering: `P54` and `A46` were added in revision 1.1 and are listed next to
  their domain.
- The frontend ignores unknown keys and treats a missing key as "not granted".
- `RESERVED` keys may appear in bundles but grant nothing until their endpoint exists.

---

## 9. Full permission catalog

**100 permissions: 54 partner (46 active, 8 reserved) + 46 admin (42 active, 4 reserved).**

### 9.1 Partner permissions

| # | Key | Capability | Floor | Class | Del. | Status | Backing endpoints / fields |
|---|---|---|---|---|---|---|---|
| P01 | `partner.workspace.access` | Enter the workspace: home (each block filtered by its own permission), menu, account summary (redacted), workspace settings read, parent context (§11.7) | U | R | D | ACTIVE | `GET /extranet/home`, `/extranet/menu`, `/extranet/account-summary`, `GET /settings` |
| P02 | `partner.business_profile.view` | Read the full business profile (representative, tax code, contact) | C | S | D | ACTIVE | `GET /profile` (after approval) |
| P03 | `partner.business_profile.edit` | Edit and submit the business profile (lifecycle `DRAFT`/`REJECTED`) | C | X | O | ACTIVE | `POST /profile`, `POST /profile/submit` (after approval) |
| P04 | `partner.settings.edit` | Language, timezone and **operational** notification preferences (security notifications are not settings, §18 O-8) | C | W | D | ACTIVE | `PUT /settings` |
| P05 | `partner.activity_log.view` | Read the workspace activity/security trail | C | S | D | ACTIVE | `GET /extranet/activity-logs` |
| P06 | `partner.security_settings.manage` | Workspace security policy (e.g. require MFA, session policy) | C | X | O | RESERVED | — |
| P07 | `partner.team.view` | List members, grants, statuses, emails, pending invitations within the actor's scope | P | S | D | ACTIVE | `GET /team`, `GET /team/invitations` |
| P08 | `partner.team.invite` | Invite, resend or revoke an invitation within the actor's authority | P | X | D | ACTIVE | `POST /team` (legacy), `POST/DELETE /team/invitations…`, `POST /team/invitations/{id}/resend` |
| P09 | `partner.team.role.assign` | Change a member's grants (roles and scopes) | P | X | D | ACTIVE | `PATCH /team/{id}` (role), `PUT /team/{memberId}/grants` |
| P10 | `partner.team.suspend` | Suspend / reactivate a member | P | X | D | ACTIVE | `PATCH /team/{id}` (`active`), `POST /team/{memberId}/suspend`, `/reactivate` |
| P11 | `partner.team.remove` | Revoke a membership (soft) | P | X | D | ACTIVE | `DELETE /team/{id}` |
| P12 | `partner.team.owner.manage` | Grant, confirm or revoke `OWNER` (step-up required) | C | X | O | ACTIVE | team writes that add/remove an `OWNER` grant |
| P13 | `partner.ownership.transfer` | Transfer primary ownership of the company | C | X | O | RESERVED | — |
| P14 | `partner.property.view` | List and read properties in scope | P | R | D | ACTIVE | `GET /hotels`, `GET /hotels/{id}` |
| P15 | `partner.property.create` | Create a property draft (creates new scope) | C | W | D | ACTIVE | `POST /hotels` |
| P16 | `partner.property.content.edit` | Basics, description, contact, location, amenities | P | W | D | ACTIVE | `PUT /hotels/{id}`, `/contact`, `/location`, `/amenities` |
| P17 | `partner.property.policy.edit` | Check-in/out, cancellation, children, pets, smoking, payment methods, star rating | P | W | D | ACTIVE | `PUT /hotels/{id}/policies` |
| P18 | `partner.property.status.toggle` | Operational on/off switch of a property (not publication) | P | W | D | ACTIVE | `PATCH /hotels/{id}/activate`, `/deactivate` |
| P19 | `partner.property.media.manage` | Upload/reorder/cover property and room media | P | W | D | RESERVED | — (media is admin-only today) |
| P20 | `partner.property.publish` | Publish/unpublish own property (Amendment A §3) | P | W | D | RESERVED | — |
| P21 | `partner.room.view` | List and read room types in scope | U | R | D | ACTIVE | `GET /rooms`, `GET /rooms/{roomId}` |
| P22 | `partner.room.create` | Create a room type | P | W | D | RESERVED | — (rooms are created by admin today) |
| P23 | `partner.room.content.edit` | Room name, code, type, description, beds, capacity, size, floor, amenities | P | W | D | ACTIVE | `PUT /rooms/{roomId}` (content fields) |
| P24 | `partner.room.commercial.edit` | `priceFrom`, `originalPrice`, `quantity`, `availableQuantity`, `freeCancellation`, `breakfastIncluded`, `instantConfirmation` | P | W | D | ACTIVE | `PUT /rooms/{roomId}` (commercial fields) |
| P25 | `partner.room.status.toggle` | Make a room type sellable / unsellable | P | W | D | ACTIVE | `PATCH /rooms/{roomId}/activate`, `/deactivate` |
| P26 | `partner.inventory.view` | Read the availability calendar | P | R | D | ACTIVE | `GET /calendar/rooms/{roomId}` |
| P27 | `partner.inventory.allotment.edit` | Daily inventory counts | P | W | D | ACTIVE | `PUT /calendar/rooms/{roomId}/{date}`, `POST …/bulk` (count fields) |
| P28 | `partner.inventory.restriction.edit` | Stop-sell, closed-to-arrival, closed-to-departure | P | W | D | ACTIVE | `PATCH …/{date}/stop-sell`, `/closed-arrival`, `/closed-departure`; flag fields of `PUT …/{date}` / bulk |
| P29 | `partner.rate.view` | Rate plans, occupancy prices, previews, validation dry-run, daily price read | P | R | D | ACTIVE | `GET /rooms/{roomId}/rate-plans`, `/pricing-preview`, `GET /rate-plans/{id}/occupancy-prices`, `/preview`, `POST /rate-plans/{id}/validate`, `GET /calendar/rooms/{roomId}/price` |
| P30 | `partner.rate.edit` | Create/update/duplicate/delete rate plans and occupancy prices; set daily price | P | W | D | ACTIVE | `POST /rooms/{roomId}/rate-plans`, `PUT/DELETE /rate-plans/{id}`, `POST …/duplicate`, `POST/PUT/DELETE` occupancy prices, `PUT /calendar/rooms/{roomId}/price` |
| P31 | `partner.rate.activate` | Make a rate plan sellable / unsellable | P | W | D | ACTIVE | `POST /rate-plans/{id}/activate`, `/deactivate` |
| P32 | `partner.promotion.view` | Read promotions targeting in-scope properties/rooms | P | R | D | ACTIVE | `GET /promotions`, `GET /promotions/{id}` |
| P33 | `partner.promotion.manage` | Create, update, delete promotions (target must be in scope) | P | W | D | ACTIVE | `POST/PUT/DELETE /promotions[/{id}]` |
| P34 | `partner.booking.view` | Booking list and detail: reference, dates, room, occupancy, status, timeline, **per-booking `finalPrice` and currency**, guest name **masked** unless P54; dashboard operational counts | P | R | D | ACTIVE | `GET /bookings`, `GET /bookings/{id}`, `GET /dashboard` |
| P35 | `partner.booking.guest_contact.view` | Guest email (`guestEmail`, `userEmail`) and any future phone | P | S | D | ACTIVE | field-level in booking list/detail |
| P54 | `partner.booking.guest_identity.view` | Unmasked guest name (`guestName`, `userFullName`) wherever a booking, stay, voucher/check-in or conversation response carries it | P | S | D | ACTIVE | field-level in booking list/detail, stay, voucher verify/check-in/out, conversations |
| P36 | `partner.booking.payment.view` | Payment records (method, provider, provider transaction id, amount, status, timestamps), invoice summary, price breakdown (`basePrice`, `ratePlanPrice`, `discountAmount`, `couponCode`, `couponDiscountAmount`, `creditAmountUsed`, `loyaltyDiscountAmount`, `giftCardAmountUsed`). **Never** `checkoutUrl` or raw `failureReason` (§21.3) | P | S | D | ACTIVE | field-level in booking detail |
| P37 | `partner.booking.arrival.operate` | Verify a voucher and check a guest in | P | W | D | ACTIVE | `POST /bookings/voucher/verify`, `POST /bookings/check-in`, `PATCH /bookings/{id}/check-in` |
| P38 | `partner.booking.departure.operate` | Check a guest out; complete a stay | P | W | D | ACTIVE | `POST /bookings/check-out`, `PATCH /bookings/{id}/check-out`, `/complete` |
| P39 | `partner.booking.no_show.mark` | Mark a no-show (has commercial consequence) | P | W | D | ACTIVE | `PATCH /bookings/{id}/no-show` |
| P40 | `partner.booking.stay.view` | In-stay detail (occupancy, schedule, voucher status, check audit) and the guest free-text fields of booking responses: `specialRequest`, `partnerNote`, `cancelReason` | P | S | D | ACTIVE | `GET /stays/{bookingId}`; free-text fields in booking list/detail |
| P41 | `partner.booking.modify` | Amend or cancel a booking on the guest's behalf | P | W | D | RESERVED | — |
| P42 | `partner.conversation.view` | Read guest conversations of in-scope bookings | P | S | D | ACTIVE | `GET /conversations`, `GET /conversations/{id}` |
| P43 | `partner.conversation.respond` | Reply, mark read, close | P | W | D | ACTIVE | `POST /conversations/{id}/messages`, `PATCH …/read`, `PATCH …/close` |
| P44 | `partner.review.view` | Review analytics of an in-scope place (partners have no review list endpoint today) | P | R | D | ACTIVE | `GET /places/{placeId}/reviews/analytics` |
| P45 | `partner.review.reply` | Public reply to a review | P | W | D | ACTIVE | `PUT /reviews/{reviewId}/reply` |
| P46 | `partner.housekeeping.view` | Room readiness board | U | R | D | RESERVED | — |
| P47 | `partner.housekeeping.update` | Set room readiness status | U | W | D | RESERVED | — |
| P48 | `partner.analytics.view` | Operational analytics (overview, occupancy, bookings, rooms, promotions, reviews, messages) — revenue fields need P49 | P | R | D | ACTIVE | `GET /analytics/{overview,occupancy,bookings,rooms,promotions,reviews,messages}` |
| P49 | `partner.finance.revenue.view` | Revenue figures and financial aggregates wherever they appear | P | S | D | ACTIVE | `GET /analytics/revenue`, `GET /finance/overview`, `/finance/revenue`; revenue fields of dashboard, home, analytics |
| P50 | `partner.finance.statement.view` | Settlements, commissions, invoices, refunds | C | S | D | ACTIVE | `GET /finance/settlements`, `/commissions`, `/invoices`, `/refunds` |
| P51 | `partner.finance.payout.view` | Payout history | C | S | F | ACTIVE | `GET /finance/payouts` |
| P52 | `partner.payout_account.view` | Payout account metadata (holder, bank, last 4, method, status) | C | S | F | ACTIVE | `GET /payout-account`; payout block of account summary |
| P53 | `partner.payout_account.manage` | Create/replace the payout account (step-up required, §20 FI-4) | C | $ | F | ACTIVE | `PUT /payout-account` |

(All partner paths are relative to `/api/partner`.)

### 9.2 Admin permissions

| # | Key | Capability | Class | Status | Backing endpoints (relative to `/api/admin`) |
|---|---|---|---|---|---|
| A01 | `admin.console.access` | Enter the console; read non-sensitive reference lists (categories, amenities, locations incl. inactive) | R | ACTIVE | `GET /categories`, `GET /amenities`, `GET /locations` |
| A02 | `admin.access.manage` | View administrators, grant/revoke admin profiles | X | RESERVED | — (§25.4) |
| A03 | `admin.audit_log.view` | Read the admin audit trail | S | ACTIVE | `GET /activity-logs` |
| A04 | `admin.analytics.view` | Platform aggregates only: analytics overview and review analytics overview (no row-level data) | S | ACTIVE | `GET /analytics/overview`, `GET /reviews/analytics/overview` |
| A05 | `admin.customer.view` | Customer profile, loyalty, credits, coupons, membership, recommendations, redemptions; unmasked guest identity in admin booking/payment responses | S | ACTIVE | `GET /users/{id}/profile`, `/users/{userId}/{loyalty,travel-credits,coupons,membership,recommendations}`, `GET /loyalty/redemptions[/{ref}]` |
| A06 | `admin.customer.wallet.view` | A customer's travel wallet items (read-audited, §22.5) | S | ACTIVE | `GET /users/{userId}/travel-wallet` |
| A07 | `admin.customer.account.manage` | Disable/enable an account, end its sessions | X | RESERVED | — |
| A08 | `admin.partner.view` | Partner list, profile, detail, team, settings, activity | S | ACTIVE | `GET /partners`, `/partners/{id}`, `/{id}/detail`, `/{id}/team`, `/{id}/settings`, `/{id}/activity-logs` |
| A09 | `admin.partner.verify` | Approve / reject a submitted partner | X | ACTIVE | `POST /partners/{id}/approve`, `/reject` |
| A10 | `admin.partner.suspend` | Suspend (and future reinstate) a partner | X | ACTIVE | `POST /partners/{id}/suspend` |
| A11 | `admin.partner.ownership.intervene` | Admin-assisted owner recovery/transfer; when built: always dual control (initiator ≠ approver, approver `PLATFORM_OWNER`) plus identity verification (§31 Q18) | X | RESERVED | — |
| A12 | `admin.partner_payout.manage` | Approve/hold partner payouts | $ | RESERVED | — (no payout is executed anywhere today) |
| A13 | `admin.place.view` | Read places, hotels, experience, rooms, inventory, rate plans, media | R | ACTIVE | `GET /places[/{id}]`, `GET /hotels/{placeId}[/experience]`, `GET /hotels/{placeId}/rooms`, `GET /rooms/{id}`, `GET /rooms/{roomId}/inventory`, `GET /rate-plans…`, `GET /places/{placeId}/media` |
| A14 | `admin.place.edit` | Create/update places, metadata, hotel detail, hotel experience | W | ACTIVE | `POST/PUT /places[/{id}]`, `PUT /places/{id}/metadata`, `POST /hotels`, `PUT /hotels/{placeId}[/experience]` |
| A15 | `admin.place.moderate` | Workflow moderation and take-down: status transitions to any **non-public** state (`DRAFT`, `PENDING_REVIEW`, `APPROVED`, `HIDDEN`, `REJECTED`, `ARCHIVED`); `verified` flag | W | ACTIVE | `PATCH /places/{id}/status` (target ≠ `PUBLISHED`), `PATCH /places/{id}/verified` |
| A46 | `admin.place.publish` | Make a listing public or restore it: status transition to `PUBLISHED`; `featured` flag. Re-labels part of the existing status endpoint — no new capability | W | ACTIVE | `PATCH /places/{id}/status` (target = `PUBLISHED`), `PATCH /places/{id}/featured` |
| A16 | `admin.place.owner.assign` | Move a property to a company (tenant boundary change; triggers §16 PA-4). **`PLATFORM_OWNER` only until dual control (§22.6)** | X | ACTIVE | `POST /hotels/{hotelId}/assign-owner` |
| A17 | `admin.room.edit` | Create/update/deactivate rooms | W | ACTIVE | `POST /rooms`, `PUT /rooms/{id}`, `PATCH /rooms/{id}/deactivate` |
| A18 | `admin.inventory.edit` | Room inventory writes | W | ACTIVE | `POST/PUT /rooms/{roomId}/inventory…`, `POST …/bulk` |
| A19 | `admin.rate.edit` | Rate plan and occupancy price writes | W | ACTIVE | `POST /rooms/{roomId}/rate-plans`, `PUT/DELETE /rate-plans/{id}`, activate/deactivate/duplicate/validate, occupancy price writes |
| A20 | `admin.media.manage` | Media create/update/deactivate/cover/reorder | W | ACTIVE | `POST /media`, `PUT /media/{id}`, `PATCH /media/{id}/deactivate`, `/media/cover`, `/media/reorder` |
| A21 | `admin.category.manage` | Category writes | W | ACTIVE | `POST/PUT/PATCH /categories…` |
| A22 | `admin.amenity.manage` | Amenity writes | W | ACTIVE | `POST/PUT/PATCH /amenities…` |
| A23 | `admin.location.manage` | Administrative-unit writes | W | ACTIVE | `POST/PUT/PATCH /locations…` |
| A24 | `admin.booking.view` | Bookings, timelines, inventory reservations (guest identity masked without A05) | S | ACTIVE | `GET /bookings[/{id}[/timeline]]`, `GET /inventory-reservations[/booking/{bookingId}]` |
| A25 | `admin.booking.operate` | Check-in / check-out / complete on a property's behalf | W | ACTIVE | `PATCH /bookings/{id}/check-in`, `/check-out`, `/complete` |
| A26 | `admin.booking.override` | Force a booking status; archive (moves no money — §2.5) | X | ACTIVE | `PATCH /bookings/{id}/status`, `/archive` |
| A27 | `admin.booking.compensate` | Refund a booking to travel credits | $ | ACTIVE | `POST /bookings/{id}/refund-to-credits` |
| A28 | `admin.conversation.view` | Read guest↔partner conversations (read-audited, §22.5) | S | ACTIVE | `GET /conversations[/{id}]` |
| A29 | `admin.conversation.intervene` | Post as admin; archive | W | ACTIVE | `POST /conversations/{id}/messages`, `PATCH …/archive` |
| A30 | `admin.payment.view` | Payments, payment sessions and their events (guest identity masked without A05) | S | ACTIVE | `GET /payments[/{id}]`, `GET /payment-sessions[/{sessionId}[/events]]` |
| A31 | `admin.payment.intervene` | Refund a payment; expire a payment session (dual-control threshold, §22.6) | $ | ACTIVE | `POST /payments/{id}/refund`, `POST /payment-sessions/{sessionId}/expire` |
| A32 | `admin.invoice.view` | Invoices | S | ACTIVE | `GET /invoices[/{id}]` |
| A33 | `admin.invoice.manage` | Invoice status override, cancel | $ | ACTIVE | `PATCH /invoices/{id}/status`, `/cancel` |
| A34 | `admin.review.view` | Individual reviews (row-level, reviewer identity) | S | ACTIVE | `GET /reviews`, `GET /reviews/{id}` |
| A35 | `admin.review.moderate` | Approve/reject/hide reviews | W | ACTIVE | `PATCH /reviews/{id}/moderate` |
| A36 | `admin.promotion.manage` | Platform promotions | $ | ACTIVE | `/promotions` (all 5) |
| A37 | `admin.coupon.manage` | Coupon definitions incl. eligibility preview | $ | ACTIVE | `/coupon-definitions` (all 7) |
| A38 | `admin.gift_card.catalog.manage` | Gift-card products | $ | ACTIVE | `/gift-card-products` (all 7) |
| A39 | `admin.gift_card.value.manage` | Issued gift cards: read (masked code), issue, activate, cancel, adjust, transactions (dual-control threshold) | $ | ACTIVE | `/gift-cards` (all except `process-expirations`) |
| A40 | `admin.customer_program.manage` | Loyalty redemption policies, membership tiers and benefits, referral campaigns | $ | ACTIVE | `/loyalty/redemption-policies…`, `/membership/tiers…`, `/membership/benefits…`, `/referral/campaigns…` |
| A41 | `admin.customer.entitlement.adjust` | Grant points; release/refund a redemption; assign/re-evaluate/clear a membership tier; revoke a customer's coupon (dual-control threshold) | $ | ACTIVE | `POST /users/{userId}/loyalty/grant`, `POST /loyalty/redemptions/{ref}/release`, `/refund`, `POST /users/{userId}/membership/{assign,reevaluate,clear-manual-assignment}`, `POST /users/{userId}/coupons/{couponId}/revoke` |
| A42 | `admin.travel_credit.adjust` | Grant/deduct travel credits (dual-control threshold) | $ | ACTIVE | `POST /users/{userId}/travel-credits/grant`, `/deduct` |
| A43 | `admin.personalization.manage` | Personalization rules; generate recommendations | W | ACTIVE | `/personalization-rules` (all 7), `POST /users/{userId}/recommendations/generate` |
| A44 | `admin.notification.broadcast` | Broadcast to users; list broadcasts | X | ACTIVE | `POST /notifications/broadcast`, `GET /notifications` |
| A45 | `admin.system_job.run` | Run expiry sweeps and reminder deliveries manually (reminder deliveries reach real users; sweeps act only on already-expired items) | W | ACTIVE | `POST /travel-credits/process-expirations`, `/gift-cards/process-expirations`, `/inventory-reservations/process-expirations`, `/payment-sessions/process-expirations`, `/loyalty/redemptions/expire-stale`, `/trip-reminders/deliver-due`, `/trip-reminders/{id}/deliver`, `/travel-wallet/generate-expiry-reminders` |

Coverage check: every one of the 181 admin endpoints and the 90 partner endpoints maps to exactly one primary
permission above, plus field-level permissions where §21 says so. One admin endpoint is value-dependent
(`PATCH /places/{id}/status` → A46 for target `PUBLISHED`, A15 otherwise). Revision 1.1 moved two mappings:
`GET /reviews/analytics/overview` from A34 to A04, and `POST /users/{userId}/coupons/{couponId}/revoke` from
A37 to A41 (a customer-level adjustment, not programme design). Phase R1 turns this into an executable registry
with a test that fails on any unmapped handler (§24 B11).

---

## 10. Role → permission matrix

`✓` granted · `·` not granted · `ᴿ` reserved permission (no endpoint yet).

### 10.1 Partner roles

| # | Permission | OWNER | MANAGER | REVENUE | RESERV. | FRONT_DESK | FINANCE | CONTENT | HOUSEKP. | VIEWER |
|---|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| P01 | workspace.access | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| P02 | business_profile.view | ✓ | ✓ | · | · | · | ✓ | · | · | · |
| P03 | business_profile.edit | ✓ | · | · | · | · | · | · | · | · |
| P04 | settings.edit | ✓ | ✓ | · | · | · | · | · | · | · |
| P05 | activity_log.view | ✓ | ✓ | · | · | · | · | · | · | · |
| P06 | security_settings.manage ᴿ | ✓ | · | · | · | · | · | · | · | · |
| P07 | team.view | ✓ | ✓ | · | · | · | · | · | · | · |
| P08 | team.invite | ✓ | ✓¹ | · | · | · | · | · | · | · |
| P09 | team.role.assign | ✓ | ✓¹ | · | · | · | · | · | · | · |
| P10 | team.suspend | ✓ | ✓¹ | · | · | · | · | · | · | · |
| P11 | team.remove | ✓ | ✓¹ | · | · | · | · | · | · | · |
| P12 | team.owner.manage | ✓ | · | · | · | · | · | · | · | · |
| P13 | ownership.transfer ᴿ | ✓² | · | · | · | · | · | · | · | · |
| P14 | property.view | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| P15 | property.create | ✓ | ✓³ | · | · | · | · | · | · | · |
| P16 | property.content.edit | ✓ | ✓ | · | · | · | · | ✓ | · | · |
| P17 | property.policy.edit | ✓ | ✓ | · | · | · | · | · | · | · |
| P18 | property.status.toggle | ✓ | ✓ | · | · | · | · | · | · | · |
| P19 | property.media.manage ᴿ | ✓ | ✓ | · | · | · | · | ✓ | · | · |
| P20 | property.publish ᴿ | ✓ | ✓ | · | · | · | · | · | · | · |
| P21 | room.view | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| P22 | room.create ᴿ | ✓ | ✓ | · | · | · | · | · | · | · |
| P23 | room.content.edit | ✓ | ✓ | · | · | · | · | ✓ | · | · |
| P24 | room.commercial.edit | ✓ | ✓ | ✓ | · | · | · | · | · | · |
| P25 | room.status.toggle | ✓ | ✓ | ✓ | · | · | · | · | · | · |
| P26 | inventory.view | ✓ | ✓ | ✓ | ✓ | ✓ | · | · | · | ✓ |
| P27 | inventory.allotment.edit | ✓ | ✓ | ✓ | · | · | · | · | · | · |
| P28 | inventory.restriction.edit | ✓ | ✓ | ✓ | ✓ | · | · | · | · | · |
| P29 | rate.view | ✓ | ✓ | ✓ | ✓ | ✓ | · | · | · | ✓ |
| P30 | rate.edit | ✓ | ✓ | ✓ | · | · | · | · | · | · |
| P31 | rate.activate | ✓ | ✓ | ✓ | · | · | · | · | · | · |
| P32 | promotion.view | ✓ | ✓ | ✓ | ✓ | · | · | · | · | ✓ |
| P33 | promotion.manage | ✓ | ✓ | ✓ | · | · | · | · | · | · |
| P34 | booking.view | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | · | · | ✓ |
| P35 | booking.guest_contact.view | ✓ | ✓ | · | ✓ | ✓ | · | · | · | · |
| P54 | booking.guest_identity.view | ✓ | ✓ | · | ✓ | ✓ | ✓ | · | · | · |
| P36 | booking.payment.view | ✓ | ✓ | · | · | · | ✓ | · | · | · |
| P37 | booking.arrival.operate | ✓ | ✓ | · | · | ✓ | · | · | · | · |
| P38 | booking.departure.operate | ✓ | ✓ | · | · | ✓ | · | · | · | · |
| P39 | booking.no_show.mark | ✓ | ✓ | · | ✓ | ✓ | · | · | · | · |
| P40 | booking.stay.view | ✓ | ✓ | · | ✓ | ✓ | · | · | · | · |
| P41 | booking.modify ᴿ | ✓ | ✓ | · | ✓ | · | · | · | · | · |
| P42 | conversation.view | ✓ | ✓ | · | ✓ | ✓ | · | · | · | · |
| P43 | conversation.respond | ✓ | ✓ | · | ✓ | ✓ | · | · | · | · |
| P44 | review.view | ✓ | ✓ | ✓ | ✓ | · | · | ✓ | · | ✓ |
| P45 | review.reply | ✓ | ✓ | · | · | · | · | ✓ | · | · |
| P46 | housekeeping.view ᴿ | ✓ | ✓ | · | · | ✓ | · | · | ✓ | · |
| P47 | housekeeping.update ᴿ | ✓ | ✓ | · | · | ✓ | · | · | ✓ | · |
| P48 | analytics.view | ✓ | ✓ | ✓ | · | · | ✓ | · | · | ✓ |
| P49 | finance.revenue.view | ✓ | ✓ | ✓ | · | · | ✓ | · | · | · |
| P50 | finance.statement.view | ✓ | ✓ | · | · | · | ✓ | · | · | · |
| P51 | finance.payout.view | ✓ | · | · | · | · | ✓ | · | · | · |
| P52 | payout_account.view | ✓ | · | · | · | · | ✓ | · | · | · |
| P53 | payout_account.manage | ✓ | · | · | · | · | ✓ | · | · | · |
| | **Total** | **54** | **47** | **17** | **16** | **16** | **13** | **8** | **5** | **9** |

¹ Subject to the delegation and authority rules of §10.3, and **effective from R4** (§31 Q3): until then
team mutations remain OWNER-only even after R3b enforces the rest of the matrix. ² Primary owner only (§18).
³ Only through a COMPANY-scoped grant (floor `C`) — a property-scoped manager cannot create new scope.

### 10.2 Admin profiles

Columns: **PO** PLATFORM_OWNER · **PT** PARTNER_OPERATIONS · **CC** CONTENT_CATALOGUE · **BS** BOOKING_SUPPORT ·
**FO** FINANCE_OPERATIONS · **GM** GROWTH_MARKETING · **TS** TRUST_SAFETY · **RM** REVIEW_MODERATION ·
**AN** ANALYTICS · **LC** LOCATION_CATALOGUE · **TE** TECH_SUPPORT.

| # | Permission | PO | PT | CC | BS | FO | GM | TS | RM | AN | LC | TE |
|---|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| A01 | console.access | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| A02 | access.manage ᴿ | ✓ | · | · | · | · | · | · | · | · | · | · |
| A03 | audit_log.view | ✓ | · | · | · | · | · | ✓ | · | · | · | ✓ |
| A04 | analytics.view | ✓ | · | · | · | ✓ | ✓ | · | · | ✓ | · | · |
| A05 | customer.view | ✓ | · | · | ✓ | ✓ | · | ✓ | · | · | · | · |
| A06 | customer.wallet.view | ✓ | · | · | ✓ | · | · | ✓ | · | · | · | · |
| A07 | customer.account.manage ᴿ | ✓ | · | · | · | · | · | ✓ | · | · | · | · |
| A08 | partner.view | ✓ | ✓ | · | · | ✓ | · | ✓ | · | · | · | · |
| A09 | partner.verify | ✓ | ✓ | · | · | · | · | · | · | · | · | · |
| A10 | partner.suspend | ✓ | ✓ | · | · | · | · | ✓ | · | · | · | · |
| A11 | partner.ownership.intervene ᴿ | ✓ | ✓⁴ | · | · | · | · | · | · | · | · | · |
| A12 | partner_payout.manage ᴿ | ✓ | · | · | · | ✓ | · | · | · | · | · | · |
| A13 | place.view | ✓ | ✓ | ✓ | ✓ | · | ✓ | ✓ | ✓ | · | ✓ | ✓ |
| A14 | place.edit | ✓ | · | ✓ | · | · | · | · | · | · | · | · |
| A15 | place.moderate | ✓ | · | ✓ | · | · | · | ✓ | · | · | · | · |
| A46 | place.publish | ✓ | · | ✓ | · | · | · | · | · | · | · | · |
| A16 | place.owner.assign | ✓ | · | · | · | · | · | · | · | · | · | · |
| A17 | room.edit | ✓ | · | ✓ | · | · | · | · | · | · | · | · |
| A18 | inventory.edit | ✓ | ✓ | · | · | · | · | · | · | · | · | · |
| A19 | rate.edit | ✓ | ✓ | · | · | · | · | · | · | · | · | · |
| A20 | media.manage | ✓ | · | ✓ | · | · | · | · | · | · | · | · |
| A21 | category.manage | ✓ | · | ✓ | · | · | · | · | · | · | · | · |
| A22 | amenity.manage | ✓ | · | ✓ | · | · | · | · | · | · | · | · |
| A23 | location.manage | ✓ | · | · | · | · | · | · | · | · | ✓ | · |
| A24 | booking.view | ✓ | ✓ | · | ✓ | ✓ | · | ✓ | · | · | · | ✓ |
| A25 | booking.operate | ✓ | · | · | ✓ | · | · | · | · | · | · | · |
| A26 | booking.override | ✓ | · | · | ✓ | · | · | · | · | · | · | · |
| A27 | booking.compensate | ✓ | · | · | · | ✓ | · | · | · | · | · | · |
| A28 | conversation.view | ✓ | · | · | ✓ | · | · | ✓ | · | · | · | · |
| A29 | conversation.intervene | ✓ | · | · | ✓ | · | · | ✓ | · | · | · | · |
| A30 | payment.view | ✓ | · | · | ✓ | ✓ | · | · | · | · | · | ✓ |
| A31 | payment.intervene | ✓ | · | · | · | ✓ | · | · | · | · | · | · |
| A32 | invoice.view | ✓ | · | · | ✓ | ✓ | · | · | · | · | · | · |
| A33 | invoice.manage | ✓ | · | · | · | ✓ | · | · | · | · | · | · |
| A34 | review.view | ✓ | · | · | · | · | · | ✓ | ✓ | · | · | · |
| A35 | review.moderate | ✓ | · | · | · | · | · | ✓ | ✓ | · | · | · |
| A36 | promotion.manage | ✓ | · | · | · | · | ✓ | · | · | · | · | · |
| A37 | coupon.manage | ✓ | · | · | · | · | ✓ | · | · | · | · | · |
| A38 | gift_card.catalog.manage | ✓ | · | · | · | · | ✓ | · | · | · | · | · |
| A39 | gift_card.value.manage | ✓ | · | · | · | ✓ | · | · | · | · | · | · |
| A40 | customer_program.manage | ✓ | · | · | · | · | ✓ | · | · | · | · | · |
| A41 | customer.entitlement.adjust | ✓ | · | · | · | ✓ | · | · | · | · | · | · |
| A42 | travel_credit.adjust | ✓ | · | · | · | ✓ | · | · | · | · | · | · |
| A43 | personalization.manage | ✓ | · | ✓ | · | · | ✓ | · | · | · | · | · |
| A44 | notification.broadcast | ✓ | · | · | · | · | · | · | · | · | · | · |
| A45 | system_job.run | ✓ | · | · | · | · | · | · | · | · | · | ✓ |
| | **Total** | **46** | **9** | **10** | **11** | **14** | **8** | **14** | **4** | **2** | **3** | **6** |

⁴ Reserved; when built it is an *initiator* right only — every use needs a `PLATFORM_OWNER` approval (§22.6).

### 10.3 Delegation and authority (partner)

Two independent checks apply to every team mutation (P08–P12):

1. **Delegation (no escalation).** Every permission in the target grant's role bundle must be in `E(p)` of the
   actor **at a scope that covers the target scope** (§4.5). A grant cannot be wider than the actor's own grant
   (a PROPERTY:123 manager cannot assign COMPANY or PROPERTY:124).
2. **Authority (who may touch whom).**

| Actor ↓ / may manage memberships holding → | OWNER | MANAGER | FINANCE | REVENUE, RESERVATIONS, FRONT_DESK, CONTENT, HOUSEKEEPING, VIEWER |
|---|:-:|:-:|:-:|:-:|
| Primary owner | ✓ (except §18 O-1) | ✓ | ✓ | ✓ |
| OWNER (confirmed co-owner) | ✓ (except primary owner) | ✓ | ✓ | ✓ |
| MANAGER | · | · | · | ✓ within own scope (from R4, §31 Q3) |
| anyone else | · | · | · | · |

A membership with several grants is "held" at its highest-authority role: a MANAGER cannot modify a member who
also holds FINANCE. No one modifies their own grants or status (self-service is limited to "leave", §17).
Every change that adds or removes an `OWNER` grant additionally needs P12 and a fresh step-up (§18 O-7).

### 10.4 Separation-of-duty properties the matrices guarantee

| Property | How |
|---|---|
| No non-owner partner role can both add people and redirect money | `team.*` (MANAGER) and `payout_account.manage` (FINANCE) never meet below OWNER |
| Operational roles receive **no financial aggregates, statements, payout records or payment records** unless explicitly granted | REVENUE holds revenue aggregates only (P49); RESERVATIONS, FRONT_DESK, CONTENT, HOUSEKEEPING and VIEWER hold none of P36, P49–P53. They may see a single booking's `finalPrice` (P34), which the front desk needs to settle a stay; aggregation of those prices is not offered by any endpoint they can call (§20 FI-1) |
| Guest identity and contact are need-to-know | P54 (names) for OWNER, MANAGER, RESERVATIONS, FRONT_DESK, FINANCE; P35 (contact) for OWNER, MANAGER, RESERVATIONS, FRONT_DESK; REVENUE and VIEWER see masked names only |
| No admin profile below PLATFORM_OWNER both overrides a booking and moves money | A26 (BS) vs A27/A31 (FO) |
| Discount design is separated from money movement | A36–A38, A40 (GM) vs A27, A31, A39, A41, A42 (FO) |
| Taking a listing down is separated from publishing it | A15 (TS, CC) vs A46 (CC only below PO) |
| Approving a company and moving a property into a company never meet below PLATFORM_OWNER | A09 (PT) vs A16 (PO only) |
| Partner verification and partner payouts are separated | A09 (PT) vs A12 (FO) |
| Only one profile manages admin access | A02 = PO only |

---

## 11. Scope model

### 11.1 Scope types and containment

| Type | Identifier | Contains |
|---|---|---|
| `COMPANY` | `partner_profiles.id` | every property whose `owner_partner_profile_id` = id, **including properties created later** |
| `PROPERTY` | `places.id` | every `HotelRoom` of that place (via `hotel_details.place_id`) and every resource attached to them |
| `UNIT` | `hotel_rooms.id` | in V1 a **room type**: its inventory, rate plans and (future) housekeeping state. A physical `ROOM` scope is a future addition (§30), not a reinterpretation of `UNIT` |

`COMPANY:c ⊇ PROPERTY:p ⊇ UNIT:u` iff `p.owner = c` and `u.hotelDetail.place = p`. Containment is evaluated
against the **current** database state on every request; `covers` is never upward (§4.5).

### 11.2 Resource → scope resolution (server-side)

| Target | Resolved scope | Path | view(type) |
|---|---|---|---|
| property `{id}` | PROPERTY:id | `places.id` → `owner_partner_profile_id` | P14 |
| room `{roomId}` | UNIT:roomId | room → `hotel_detail` → `place` → owner | P21 |
| calendar `rooms/{roomId}/…` | UNIT:roomId | as room | P26 |
| rate plan `{id}` / occupancy price `{id}` | UNIT of its room | rate plan → room → … | P29 |
| booking `{id}` / booking code | PROPERTY of `booking.hotel` | `bookings.hotel_id` → `places` | P34 |
| stay `{bookingId}` | PROPERTY of the booking | as booking | P34 |
| promotion `{id}` / promotion body target | target `HOTEL`: `targetId` is a **`hotel_details.id`** → `hotel_details.place_id` → PROPERTY; target `ROOM`: `targetId` is a `hotel_rooms.id` → UNIT; target `ALL` stays forbidden for partners | never interpret a `HOTEL` target as a `places.id` | P32 |
| conversation `{id}` | PROPERTY of its booking | `conversations.booking_id` (NOT NULL) → `bookings.hotel_id` → place → **current** owner. The denormalized `conversations.partner_profile_id` is **not** used for authorization (§16 PA-4) | P42 |
| review `{reviewId}`, place review analytics | PROPERTY of the place | review → place | P44 |
| membership `{id}` / invitation `{id}` | the set of its grants (covered only if **all** grants are covered) | grants → scopes | P07 |
| team, settings, payout, finance statements, activity log | COMPANY | the caller's workspace W | — (COMPANY kind) |

A target that does not exist, or resolves to another company, is indistinguishable from a target outside the
caller's scope: 404 (§4.5, §26).

### 11.3 Role → allowed scope types

| | COMPANY | PROPERTY | UNIT |
|---|:-:|:-:|:-:|
| OWNER, FINANCE | ✓ | · | · |
| MANAGER, REVENUE, RESERVATIONS, FRONT_DESK, CONTENT, VIEWER | ✓ | ✓ | · |
| HOUSEKEEPING | · | ✓ (default) | ✓ |

A grant outside this table is rejected at assignment time (422 `SCOPE_INVALID`).

### 11.4 Scope floors (restated from §4.5)

- Floor `C`: only a COMPANY grant contributes to `E(p)` (e.g. `partner.finance.statement.view`,
  `partner.team.owner.manage`, `partner.property.create`). A property-scoped MANAGER therefore receives 403 on
  statements and on `POST /hotels` even though both permissions are in the MANAGER bundle.
- Floor `P`: COMPANY and PROPERTY grants contribute; UNIT grants do not.
- Floor `U`: every grant type contributes — used by `partner.workspace.access` (P01), `partner.room.view`
  (P21) and the reserved housekeeping permissions (P46, P47).
- Team permissions at PROPERTY scope (P07–P11, floor `P`) cover only memberships and invitations **all** of
  whose grants lie inside that property.

### 11.5 Multiple grants

Grants are additive (union). There are no negative grants in V1. A member holding FRONT_DESK@PROPERTY:123 and
HOUSEKEEPING@PROPERTY:124 may check guests in at 123 and (future) update readiness at 124 — never check in at
124 (404: they hold no booking view covering 124).

### 11.6 One workspace per account (V1)

V1 keeps today's API shape (no company id in partner URLs), so every account has at most one workspace.

- **WS-1** An account has **either** its own `PartnerProfile` (any status) **or** non-revoked memberships, never
  both; and it has at most one `ACTIVE` membership. (`partner_profiles.user_id` is already unique.)
- **WS-2 Profile creation.** `POST /api/partner/profile` by a caller with any `ACTIVE` or `SUSPENDED`
  membership → **409 `WORKSPACE_CONFLICT`** (`reason: MEMBERSHIP_EXISTS`); nothing is created. The member must
  leave (§17) first. **Freeze change** to today's onboarding behaviour (G23).
- **WS-3 Invitation acceptance.** Any own profile — `DRAFT`, `SUBMITTED`, `APPROVED`, `REJECTED` or `SUSPENDED` —
  blocks acceptance: 409 `WORKSPACE_CONFLICT` (`reason: OWN_PROFILE_EXISTS`); an `ACTIVE` membership elsewhere
  blocks it too (`reason: MEMBERSHIP_EXISTS`).
- **WS-4 Draft/rejected profiles.** A `DRAFT` or `REJECTED` own profile is still a company for WS-1. V1 has no
  self-service withdrawal (it would need a new `WITHDRAWN` lifecycle state, which this design does not add);
  the invitee accepts with a **different Partner account**. The Partner surface checks pending invitations
  (`GET /api/me/partner-invitations`, §25.3) **before** offering "Create business profile", so an invited user is
  not steered into creating a conflicting draft.
- **WS-5 Reactivation.** Reactivating a suspended membership re-checks WS-1 (409 `WORKSPACE_CONFLICT`).
- **WS-6 Collections** resolve W and then filter by the caller's scope set S (§4.5 COLLECTION).

Multi-company membership is deferred (§31 Q1); it needs an explicit, validated workspace selector.

### 11.7 Parent-context read rule

A member may always read the **minimal context** needed to operate inside a granted scope, without holding the
parent's view permission:

| Grant | Context the member may read |
|---|---|
| any grant | company `{id, businessName, verificationStatus, timezone, defaultLanguage}` |
| `PROPERTY:p`, or `UNIT:u` with `u ∈ p` | property `{id, name, location label (administrative-unit path), active, placeStatus}` |
| `UNIT:u` | room type `{id, roomName, roomCode, propertyId}` |

Context is delivered in the access document (§25.2) and in the responses of endpoints the member may call (e.g.
a room carries its `hotelName`). It never includes contact details, policies, other properties' or rooms' data,
or anything behind a field-level permission. Context is part of P01 and is not a separate permission.

---

## 12. Company / property / room access model

### 12.1 Worked examples (the brief's grants)

Assume company 456 owns properties 123 and 124; property 123 has room types 9001 and 9002; company 789 owns
property 555.

| Grant | Allowed (examples) | Refused (examples) |
|---|---|---|
| `OWNER@COMPANY:456` | everything in 456 incl. team, owners (step-up), payout (step-up); new property 125 automatically | anything in 789 → 404 |
| `MANAGER@COMPANY:456` | all operations on 123 and 124; statements; invite FRONT_DESK@PROPERTY:124 (from R4); edit policies; see guest names and email | `GET /payout-account` → 403; grant OWNER or FINANCE → 403 `ROLE_NOT_DELEGABLE`; modify another MANAGER → 403 `ROLE_NOT_DELEGABLE` |
| `MANAGER@PROPERTY:123` | operations on 123; invite FRONT_DESK@PROPERTY:123 (from R4) | `GET /finance/settlements` → 403 (floor C); `POST /hotels` → 403 (floor C); `GET /hotels/124` → 404 |
| `REVENUE@COMPANY:456` | rates, inventory, restrictions, promotions, room commercial fields on 123/124; revenue aggregates | guest names **masked**, guest email omitted; check-in → 403; changing a room description → 403 (field-diff, B9); statements → 403 |
| `FRONT_DESK@PROPERTY:123` | verify voucher, check in/out bookings of 123; guest name and email of 123's bookings; reply to 123's conversations | any booking of 124 → 404; `PUT /hotels/123/policies` → 403; `GET /finance/revenue` → 403; `POST /hotels` → 403 |
| `HOUSEKEEPING@PROPERTY:123` | enter the workspace; read property 123 and its room types; (future) readiness of 9001/9002 | `GET /bookings` → 403 (collection, no booking view anywhere); `GET /bookings/{a booking at 123}` → **404** (no booking view → existence not revealed); property 124 → 404 |
| `HOUSEKEEPING@UNIT:9001` | enter the workspace (P01, floor U); see property 123's name and room 9001's name (§11.7); read room 9001 | `GET /hotels/123` → 404 (P14 floor P); room 9002 → 404 |

### 12.2 Cross-boundary refusals (invariants made concrete)

| Attempt | Defence | Result |
|---|---|---|
| Member of 456 calls `GET /api/partner/hotels/555` | company of 555 ≠ W | 404 (no existence leak) |
| Member of 456 sends `ownerId`/`partnerProfileId`/`companyId` in a body | ignored; scope comes from the target | unchanged behaviour (Phase C: `PartnerPropertyCrudTest.partnerCannotChangeOwnerOrModerationFlags`) |
| `FRONT_DESK@PROPERTY:123` calls `PATCH /bookings/{b}/check-in` for a booking at 124 | scope miss, no booking view at 124 | 404 |
| Promotion targeting a room of 789 | target resolution through `hotel_details` / `hotel_rooms` | 404 (current behaviour of `validateTargetOwnership`) |
| Invite with `PROPERTY:555` | scope not in company | 422 `SCOPE_INVALID` (no hint that 555 exists) |
| Active member of 456 calls `POST /api/partner/profile` | WS-2 | 409 `WORKSPACE_CONFLICT`, nothing created |
| Property 123 moved 456 → 789 by `HOTEL_ASSIGN_OWNER` | PA-4 revokes 456's grants on 123; conversations authorize through `booking.hotel` | 456's FRONT_DESK@PROPERTY:123 loses bookings **and** conversations of 123 on the next request (404) |

### 12.3 Data model (design sketch — not to be implemented in this task)

```
partner_profiles (existing)            -- COMPANY; user_id = primary owner
partner_team_members (existing, extended)
    id, partner_profile_id, user_id,
    role            -- kept as "primary role" (highest grant) for backward compatibility, §29
    active          -- kept; true iff status = ACTIVE
    status          -- NEW: ACTIVE | SUSPENDED | REVOKED
    status_reason, status_changed_at, status_changed_by        -- NEW
    pending_owner_confirmation                                  -- NEW (§18 O-9)
    version         -- NEW: optimistic locking
    invited_at, joined_at, created_at, updated_at
partner_member_grants (NEW)
    id, team_member_id → partner_team_members, role, scope_type (COMPANY|PROPERTY|UNIT),
    scope_id (null for COMPANY), created_at, created_by
    unique (team_member_id, role, scope_type, scope_id)
partner_invitations (NEW)
    id, partner_profile_id, email (normalised), token_hash (unique), status
    (PENDING|ACCEPTED|DECLINED|REVOKED|EXPIRED), expires_at, resend_count, last_sent_at,
    delivery_status (QUEUED|SENT|FAILED), invited_by, accepted_by, accepted_at, revoked_by, revoked_at,
    created_at
partner_invitation_grants (NEW)        -- same shape as partner_member_grants
partner_activity_logs (existing, extended — §28 M-4)
    + actor_email (snapshot), before_state, after_state, reason
```

### 12.4 Admin data model (design sketch)

```
admin_profile_assignments (NEW)
    id, user_id → users (must have role ADMIN), profile (11 values), granted_by, granted_at,
    revoked_by, revoked_at, reason
    unique active (user_id, profile)   -- SQL Server filtered unique index WHERE revoked_at IS NULL
admin_dual_control_requests (FUTURE, §22.6)
    id, permission, target_type, target_id, payload_digest, amount, currency, requested_by, requested_at,
    approved_by, approved_at, rejected_by, expires_at, status
```

---

## 13. Team invitation workflow

### 13.1 Invite

```
Actor (P08 covering every grant scope) ──POST /api/partner/team/invitations {email, grants[]}──► server
   1. resolve W; require P08 for every grant scope (§4.5); OWNER grants additionally need P12 + step-up
   2. validate grants: role allowed at scope type (§11.3), scope ∈ W (else 422 SCOPE_INVALID),
      delegation + authority (§10.3)
   3. normalise email exactly like Phase A (trim, lowercase Locale.ROOT, ≤ 254)
   4. limits (§31 Q16): ≤ 20 PENDING per company, 60 s cooldown per (company, email) → 429 INVITATION_RATE_LIMITED
   5. EmailSender.isAvailable() == false  ⇒  503 EMAIL_DELIVERY_UNAVAILABLE, nothing is created
   6. one transaction: supersede any PENDING invitation for (company, email) (status REVOKED, reason
      SUPERSEDED); create the invitation with 32 random bytes (SecureRandom), store SHA-256 only,
      expires_at = now + 7 days, delivery_status QUEUED; audit TEAM_MEMBER_INVITED (grants as safe
      scalars, never the token); security notification to all owners (§18 O-8)
   7. after commit: send <PARTNER_APP_URL>/accept-invitation#token=…  (fragment, like Phase A)
        sent   → delivery_status SENT, last_sent_at = now
        failed → delivery_status FAILED; the invitation stays PENDING and can be resent (§13.2)
   8. respond 202 with the SAME body whether or not the email has an account, is a traveller, an admin,
      or a member of another company
```

This resolves the earlier contradiction: availability is checked **before** anything is created (503), and
the message is sent **after** commit, so a delivery failure never rolls back an invitation that the audit
trail already recorded.

### 13.2 Resend

`POST /api/partner/team/invitations/{id}/resend` (P08 with authority over the invitation's grants):

1. Invitation must be `PENDING` (else 409 `INVITATION_NOT_PENDING`).
2. Cooldown 60 s since `last_sent_at` and at most **5** resends (`resend_count`) → 429 `INVITATION_RATE_LIMITED`.
3. `EmailSender.isAvailable()` false → 503, nothing changes.
4. One transaction: **rotate** the token (new random value, new hash — the old link stops working), new
   `expires_at = now + 7 days`, `resend_count + 1`, audit `TEAM_INVITATION_RESENT`.
5. After commit: send; failure leaves the invitation `PENDING` / `FAILED` exactly as in §13.1 step 7.
6. Response 202 with the same uniform body.

### 13.3 Rules

- **IN-1 No enumeration.** No invitation response reveals whether the email belongs to an account, a
  traveller, an `ADMIN`, or a member of another company. (Today: `404 "User not found: <email>"`.)
- **IN-2 No side effects on accounts.** Inviting never creates an account and never changes a system role.
- **IN-3 Already a member.** If the actor's P07 covers an existing membership of that email in W → 409
  `ALREADY_MEMBER`. If the member exists outside the actor's scope (e.g. a property-scoped manager), the
  uniform 202 is returned and nothing is created, so a scoped actor learns nothing about the rest of the team.
- **IN-4 Limits.** 7-day validity, ≤ 20 pending per company, 60 s per-email cooldown, ≤ 5 resends.
- **IN-5 Email availability.** 503 `EMAIL_DELIVERY_UNAVAILABLE` before creation (§13.1 step 5). Production
  currently uses `UnconfiguredEmailSender` (`ACCOUNT_LIFECYCLE.md` §10), so **invitations are unavailable in
  production until a real email provider ships** — a release dependency of R4.
- **IN-6 Revocation.** `DELETE /api/partner/team/invitations/{id}` by a P08 holder with authority over its
  grants; audited `TEAM_INVITATION_REVOKED`.
- **IN-7 Token hygiene.** Reuse the `AuthTokenService` primitives (hashing, single-use conditional update), but
  not the `auth_tokens` table: its `purpose` CHECK allows only `EMAIL_VERIFICATION`/`PASSWORD_RESET`
  (`be-db/V3__account_lifecycle.sql:51`) and it is keyed by an existing user, while an invitee may not have an
  account yet. Invitation tokens are bearer instruments (§21.3).
- **IN-8 Expiry.** Lazy on read plus an optional sweep (`admin.system_job.run`); an expired invitation can no
  longer be resent — a new invitation is created instead.

---

## 14. Accept invitation workflow

The accept and decline endpoints live under `/api/me/**` (`authenticated()` today), so the server — not the
URL rule — decides the outcome and can answer with a precise code.

```
Invitee opens <PARTNER_APP_URL>/accept-invitation#token=… (a public location, like verify-email)
  The page shows the same guidance to everyone, revealing nothing about any account:
    "Join with a Partner account that uses the invited address. A traveller account cannot be used — if the
     invited address is already your traveller account, ask the person who invited you to use another
     (for example, work) address."
  ├─ not signed in → sign in on the Partner surface, or register through POST /api/auth/partner/register
  │                   with the invited email and verify it (Phase A flow), then return to the link
  └─ signed in → POST /api/me/partner-invitations/accept {token}
        1. token: hash match, status PENDING, not expired          else 400 INVITATION_INVALID / INVITATION_EXPIRED
        2. account role == PARTNER, enabled, email verified when gated
                                                                     else 403 PARTNER_ACCOUNT_REQUIRED
        3. account email == invitation email (normalised)          else 403 INVITATION_ACCOUNT_MISMATCH
                                                                         (the invited address is not echoed)
        4. WS-1/WS-3: no own profile of any status, no ACTIVE membership elsewhere
                                                                     else 409 WORKSPACE_CONFLICT (+ reason)
        5. company still APPROVED                                  else 409 WORKSPACE_UNAVAILABLE
        6. re-validate every grant NOW (scope still in company; inviter still holds authority)
                                                                     else 409 INVITATION_STALE
        7. one transaction: consume token (conditional update), create membership ACTIVE + grants,
           audit TEAM_INVITATION_ACCEPTED, security notification to all owners (§18 O-8)
        8. respond with the caller's new access document (§25.2)
```

- **AC-1** Decline: `POST /api/me/partner-invitations/decline {token}` → `DECLINED`, audited
  `TEAM_INVITATION_DECLINED`; no account checks beyond authentication, so anyone holding the link can refuse it.
- **AC-2** Expiry: §13.3 IN-8.
- **AC-3 Traveller accounts (Freeze change, §31 Q2).** A `USER` account cannot accept and is never promoted.
  Because `users.email` is unique, an address that already belongs to a traveller account can never become a
  Partner account; the invitee asks for an invitation to a different address. The inviter is never told why an
  invitation was not accepted (IN-1). Registering a Partner account with an address that is already a traveller
  account receives Phase A's existing `409 EMAIL_ALREADY_REGISTERED` — about the registrant's own address, not
  someone else's, so it is not enumeration by this design.
- **AC-4** An `ADMIN` account cannot accept (R-S3): 403 `PARTNER_ACCOUNT_REQUIRED`.
- **AC-5** `GET /api/me/partner-invitations` (PARTNER accounts only, verified email) lists PENDING invitations
  addressed to the caller's own email — company name, role/scope summary, expiry — so the Partner surface can
  offer them before onboarding (WS-4). It never lists invitations for any other address.
- **AC-6** Existing memberships are not re-invited during migration; their status is set by M-1/M-6 (§28).

---

## 15. Role change workflow

`PUT /api/partner/team/{memberId}/grants {grants[], reason?, version}` (legacy `PATCH /team/{id}` follows the same
rules from R3a):

1. Require P09; when any `OWNER` grant is added or removed, also P12 and a fresh step-up (§18 O-7).
2. Target membership must be in W (else 404) and must not be the caller (403 `SELF_MODIFICATION_FORBIDDEN`).
3. Authority over the target's **current** grants and over the **new** grants (§10.3).
4. Every new grant valid for its scope type and inside the company (422 `SCOPE_INVALID`).
5. An empty grant list is invalid (use suspend or remove).
6. Last-owner check when `OWNER` grants are removed (§19), under the company row lock.
7. Optimistic lock on `version` (409 `CONCURRENT_MODIFICATION` on a stale write).
8. One transaction: replace grants, sync the legacy `role` column to the highest grant, audit
   `TEAM_MEMBER_ROLE_CHANGED` (or `OWNER_GRANTED` / `OWNER_REVOKED`) with before/after as
   `"FRONT_DESK@PROPERTY:123"`-style scalars, mandatory security notification to all owners and the member.
9. Effective on the member's next request — no token change needed (§2.1).

---

## 16. Property assignment workflow

Assigning a member to properties **is** a role change (§15) whose grants carry `PROPERTY:<id>` / `UNIT:<id>`.

- **PA-1** New properties are covered automatically by COMPANY grants only; PROPERTY grants are never
  auto-extended.
- **PA-2** `partner.property.create` has floor `C`, so a property-scoped user cannot mint scope for themselves.
- **PA-3** A PROPERTY-scoped manager can assign only that property (or its units) and only below-manager roles.
- **PA-4 Tenant move.** When an admin moves a property to another company (`POST
  /api/admin/hotels/{hotelId}/assign-owner`, `HOTEL_ASSIGN_OWNER`, A16 — `PLATFORM_OWNER` only), in the **same
  transaction**:
  1. every PROPERTY/UNIT grant and pending invitation grant of the **previous** company that references the
     property or its units is revoked (audit `TEAM_MEMBER_SCOPE_REVOKED` in the previous company's trail);
  2. `conversations.partner_profile_id` of conversations whose booking belongs to the property is re-pointed to
     the new company, so the denormalized column used by the partner list query stays consistent;
  3. authorization never relies on that column anyway: a conversation is resolved through `booking.hotel` to
     the property's **current** owner (§11.2), so even a missed re-point cannot expose the conversation to the
     previous company — it would only hide it from the new one;
  4. historical records keep their historical company: `partner_activity_logs`, `booking_check_in_audits` and
     `booking_check_out_audits` rows written before the move are not rewritten. The previous company's trail
     remains readable by that company (it is its own history); when the new company views a stay, check
     audits written by another company show operation and time, not the other company's staff identity;
  5. the admin trail keeps the existing `HOTEL_ASSIGN_OWNER` row with previous and new company ids.
- **PA-5** Archiving a property or deactivating a room type (admin moderation) leaves grants in place, and every
  operation keeps obeying the lifecycle rules; grants on a deleted room type are cleaned up by the same
  mechanism as PA-4 step 1.

---

## 17. Revoke / suspend workflow

| Action | Endpoint | Permission | Effect | Audit |
|---|---|---|---|---|
| Suspend | `POST /api/partner/team/{id}/suspend {reason}` (legacy: `PATCH /team/{id}` with `active=false`) | P10 + authority | `status = SUSPENDED`; all access ends next request; grants kept | `TEAM_MEMBER_SUSPENDED` |
| Reactivate | `POST /api/partner/team/{id}/reactivate` (legacy: `active=true`) | P10 + authority | back to `ACTIVE` with the same grants, re-checked against §10.3 and WS-1 | `TEAM_MEMBER_REACTIVATED` |
| Remove | `DELETE /api/partner/team/{id} {reason}` | P11 + authority | `status = REVOKED`, grants removed, **row kept** (today: hard delete) | `TEAM_MEMBER_REMOVED` |
| Leave | `POST /api/partner/team/leave` | membership itself | own `REVOKED`; refused for the primary owner and for the last owner | `TEAM_MEMBER_LEFT` |
| Company suspended by admin | existing `POST /api/admin/partners/{id}/suspend` | A10 | memberships untouched; every operational permission denied because the company is not `APPROVED` | existing `PARTNER_SUSPEND` |
| Account disabled | reserved A07 | A07 | filter refuses the account (existing behaviour of `enabled`) | `USER_ACCOUNT_DISABLE` (new admin action) |

- **RV-1** Revocation never changes `users.role`. A `PARTNER` account without membership or profile can only
  reach onboarding (`/api/partner/profile/**`), exactly as today.
- **RV-2** A `REVOKED` membership is never reactivated; the person is re-invited (fresh consent).
- **RV-3** Suspending or removing a member whose grants include OWNER is subject to §18 and §19.
- **RV-4** In-flight requests complete under the authorization they started with; the next request is denied.
- **RV-5** Every row above sends the mandatory security notification of §18 O-8.

---

## 18. Owner protection rules

- **O-1 Primary owner is immutable inside the workspace.** `PartnerProfile.user` holds an implicit
  `OWNER@COMPANY` that no workspace action can revoke, suspend, demote, re-scope or remove — not even another
  OWNER. (This formalises today's `resolveAccess:236-238`.) Changing the primary owner is only possible through
  ownership transfer (O-6) or admin intervention (A11, dual control).
- **O-2 Only OWNER manages OWNER.** Granting, confirming or revoking `OWNER` requires P12, which is owner-only
  and non-delegable (403 `OWNER_PROTECTED` otherwise).
- **O-3 OWNER is COMPANY-scoped only.**
- **O-4 Non-owners never modify an owner's membership** (grants, status, removal) — 403 `OWNER_PROTECTED`.
- **O-5 Non-delegable set.** `P03 business_profile.edit`, `P06 security_settings.manage`,
  `P12 team.owner.manage`, `P13 ownership.transfer` can never be granted to a non-OWNER role, including through
  future custom roles or overrides (§30). `P51–P53` are delegable to FINANCE only.
- **O-6 Ownership transfer (reserved, P13).** Initiated by the primary owner; target must be an existing ACTIVE
  confirmed co-OWNER with a verified PARTNER account; target accepts; step-up on both sides; the old primary
  owner becomes a co-OWNER (not removed). Audited `OWNERSHIP_TRANSFERRED`; when admin-assisted, also
  `PARTNER_OWNERSHIP_INTERVENE` in the admin trail.
- **O-7 Step-up (fresh session).** The JWT is not changed. A token is *fresh* when
  `now − (exp − app.jwt.expiration-ms) ≤ 15 minutes`, i.e. it was issued within the last 15 minutes. A caller
  refreshes it with `POST /api/me/step-up {currentPassword}` (§25.6), which re-checks the password and returns a
  newly issued token exactly like `PUT /api/me/password` does; a sign-in also yields a fresh token. Actions that
  require freshness: P12, P13, P53, P06 (partner) and A02, A11, A16 (admin); a stale token gets 403
  `STEP_UP_REQUIRED`. *Caveat:* lowering `app.jwt.expiration-ms` makes older tokens look fresher by the
  difference, so such a configuration change must be paired with a `tokenVersion` bump or treated as requiring
  step-up until the old maximum lifetime has elapsed.
- **O-8 Mandatory security notifications.** Security events are a separate notification class that is
  **not** stored in or governed by `PartnerSettings`, so no role — including MANAGER through P04 — can disable
  them. Recipients: every ACTIVE owner (primary and confirmed co-owners) and, where applicable, the affected
  member. Channel: in-app always; email additionally once a production email provider exists. Events: owner
  granted/confirmed/revoked; ownership transfer; member invited, invitation accepted/resent/revoked, member role
  or scope changed, suspended, reactivated, removed, left; payout account created or changed; security settings
  changed.
- **O-9 Legacy co-owners (safe rollout).** Non-registrant `OWNER` rows that exist today are migrated as
  `MANAGER@COMPANY` with `pending_owner_confirmation = true` (§28 M-6) — never as OWNER. The primary owner can
  confirm them through P12 (step-up, audited `OWNER_GRANTED`, notification to all owners). No migration ever
  grants owner-management or payout power to an account that does not exercise it today (I24).

---

## 19. Last-owner protection rules

- **LO-1** A company must always have ≥ 1 owner that is `ACTIVE` and whose account is `enabled`. Because of O-1
  the primary owner normally satisfies this; LO rules protect co-owner churn, ownership transfer, admin
  intervention, and a primary-owner account that is disabled. Pending (unconfirmed) co-owners do not count.
- **LO-2** Any operation that would leave zero qualifying owners is refused with **409
  `LAST_OWNER_REQUIRED`**: revoking OWNER, suspending/removing an owner, an owner leaving, transfer completion.
- **LO-3 Concurrency.** The owner count is checked in the same transaction as the mutation, under a pessimistic
  lock on the company row (`partner_profiles`), mirroring the per-account row lock Phase A uses for token
  issuance. Two concurrent revocations of the last two co-owners can therefore never both succeed.
- **LO-4** The primary owner cannot leave (they must transfer first); a co-owner cannot leave if they are the
  last qualifying owner.
- **LO-5** Admin suspension of a company is not an owner removal; LO does not apply to it.
- **LO-6 Company without a reachable owner (§31 Q18).** If the primary owner's account becomes unusable and no
  confirmed co-owner exists: operations continue for existing members; OWNER-only actions (P03, P06, P12, P13,
  P53) are blocked; recovery is admin-assisted (A11 — dual control, identity verification, audit in both
  trails); members can never promote themselves.
- **AP-2 (admin analogue)** At least one active `PLATFORM_OWNER` must exist; the last one cannot be revoked
  (409 `LAST_PLATFORM_OWNER_REQUIRED`).

---

## 20. Financial permission isolation

| Data / action | Partner permission | Partner holders | Admin permission |
|---|---|---|---|
| Single booking total (`finalPrice`, currency) | P34 | OWNER, MANAGER, REVENUE, RESERVATIONS, FRONT_DESK, FINANCE, VIEWER | A24 |
| Revenue and financial aggregates (dashboard, home, analytics, finance overview/revenue) | P49 | OWNER, MANAGER, REVENUE, FINANCE | A04 |
| Statements: settlements, commissions, invoices, refunds | P50 | OWNER, MANAGER, FINANCE | A32 |
| Payout history | P51 | OWNER, FINANCE | (A12 reserved) |
| Payout account metadata | P52 | OWNER, FINANCE | A08 shows status only (`AdminPartnerDetailResponse.payoutStatus`) |
| Payout account change | P53 (step-up) | OWNER, FINANCE | — |
| Payment records and price breakdown on bookings | P36 | OWNER, MANAGER, FINANCE | A30 |
| Payment links and raw provider errors | **never** to partners (§21.3) | — | A30 |
| Refunds, session expiry, invoice changes, credits, gift-card value, entitlements | — (no partner endpoint) | — | A27, A31, A33, A39, A41, A42 (FINANCE_OPERATIONS) |
| Discount programme design | — | — | A36, A37, A38, A40 (GROWTH_MARKETING) |

Rules:

- **FI-1** Operational roles do not receive **financial aggregates, statements, payout records or payment
  records** unless a permission explicitly grants them. Per-booking `finalPrice` is operational data (P34) and
  is the only money figure they see; no endpoint they can call aggregates it.
- **FI-2 Field-level enforcement** in mixed responses (§21.2): the server omits money fields the caller may not
  see; it does not rely on the client to hide them.
- **FI-3** Aggregates are computed **only over the caller's scope set S** (§4.5 COLLECTION). A property-scoped
  REVENUE user's revenue report contains only their properties. Endpoints marked "COMPANY ONLY" in §25.1 accept
  only COMPANY grants.
- **FI-4 Payout account change (§31 Q4).** OWNER and FINANCE may change it (today's `PAYOUT_WRITE_ROLES`) with:
  step-up (§18 O-7); mandatory notification to every owner (§18 O-8); audit with masked before/after
  (`****1234 → ****5678`); and — once payouts exist — a **72-hour hold** before the first payout to a new or
  changed account.
- **FI-5** The full bank account number is still never persisted (existing `lastFour`, `PartnerSettingsService:273`).
- **FI-6** Payout-account notifications are mandatory and go to every owner (O-8, G20).
- **FI-7** Admin: booking override (A26) and money movement (A27/A31) are held by different profiles below
  PLATFORM_OWNER; discount design (GROWTH_MARKETING) is separated from money movement (FINANCE_OPERATIONS).
- **FI-8** Stored-value and refund actions above a threshold require dual control (§22.6).
- **FI-9 Reconciliation** is a FINANCE capability: booking view with guest names (P34 + P54), payment records
  (P36), statements (P50) and payouts (P51), all at COMPANY scope.

---

## 21. Sensitive data permissions

### 21.1 Classification

| Class | Fields (actual names) | Partner | Admin |
|---|---|---|---|
| Guest identity | `guestName` (`PartnerBookingSummaryResponse`), `userFullName` (`BookingResponse`) | P54 (masked otherwise) | A24 with A05 (masked otherwise) |
| Guest contact | `guestEmail`, `userEmail`; any future phone (`PartnerGuestStayDto` already omits contact) | P35 (omitted otherwise) | A05 |
| Guest free text | `specialRequest` (may hold health/accessibility details), `partnerNote` (staff note about the guest), `cancelReason` (may hold personal reasons) | P40 (omitted otherwise) | A24 |
| Per-booking total | `finalPrice`, `currency` | P34 | A24 |
| Price breakdown | `basePrice`, `ratePlanPrice`, `discountAmount`, `couponCode`, `couponDiscountAmount`, `creditAmountUsed`, `loyaltyDiscountAmount`, `giftCardAmountUsed` | P36 | A24 |
| Payment record | `PaymentResponse.provider`, `providerTransactionId`, `paymentMethod`, amount, status, timestamps | P36 | A30 |
| Payment link / provider error | `PaymentResponse.checkoutUrl`, raw `failureReason` | **never** | A30 |
| Traveller account data | `userId`, `loyaltyPointsRedeemed` | **never** | A05 |
| Revenue aggregates | `revenueToday`, `revenueMonth`, finance overview/revenue, analytics revenue | P49 | A04 |
| Bank | `accountHolderName`, `bankName`, `bankAccountLast4` | P52 | — |
| Business identity | `representativeName`, `taxCode`, profile phone/email | P02 | A08 |
| Team PII | member `fullName`, `email` | P07 | A08 |
| Conversations | message bodies | P42 | A28 (read-audited) |
| Audit trails | actor names/emails, descriptions | P05 | A03 |
| Customer stored value | wallet items, credits, loyalty, coupons | — | A05, A06 (read-audited) |
| Bearer instruments | §21.3 | **never readable** | **never readable** |
| Credentials | password hashes, JWTs, secrets | **never exposed** | **never exposed** |

### 21.2 Field-level rules

- **SD-1** One endpoint, one primary permission (§25); sensitive fields inside the response need their own
  permission. A permission-dependent field the caller may not see is either **omitted** or **masked** and is
  listed in a top-level array (§31 Q15):
  `"redacted": [{"field": "guestEmail", "mode": "OMITTED"}, {"field": "guestName", "mode": "MASKED"}]`
  (`field` is a JSON path, e.g. `booking.userEmail`, `payments[].providerTransactionId`).
- **SD-2 Masking format** for names: the first letter of each name part followed by a dot ("T. T. B."). Masking is
  used for guest names (P54); everything else is omitted.
- **SD-3** Fields of the never-to-partner set (§21.3) are dropped for every partner role and are **not** listed
  in `redacted`, because no partner role can ever receive them.
- **SD-4** Endpoints affected in V1: `GET /bookings`, `GET /bookings/{id}`, `GET /stays/{bookingId}`,
  `POST /bookings/voucher/verify`, `POST /bookings/check-in`, `POST /bookings/check-out`, `GET /conversations[/{id}]`,
  `GET /dashboard`, `GET /extranet/home`, `GET /extranet/account-summary`, `GET /analytics/{overview,promotions}`.
- **SD-5** Sensitive reads by partners are not logged per row (volume); denials are observable in application
  logs (§22.4). Admin reads of wallets and conversations are audited (§22.5).

### 21.3 Never-readable data and non-regression rules

| Rule | Data | Today (verified) | Requirement |
|---|---|---|---|
| NR-1 | Payment link `checkoutUrl`, raw provider `failureReason` | returned to partners inside booking detail | never in any partner response; partners may later receive a normalised failure *category* |
| NR-2 | Traveller `userId`, `loyaltyPointsRedeemed` | returned to partners inside booking detail | never in any partner response |
| NR-3 | Gift-card full code | `fullCode` only in the issuance/claim response; every other read, incl. admin, returns `maskedCode` | keep; no read endpoint may ever return `fullCode` |
| NR-4 | Voucher QR payload and signature | `qrPayload` only from `GET /api/me/bookings/{bookingId}/voucher` to the booking's traveller; `PartnerGuestStayDto` excludes QR payload, signature and signing secret | keep; never in any partner or admin response, log or audit row |
| NR-5 | Payment callback token `payment_sessions.callback_token` | in no response DTO | keep; never returned, logged or audited |
| NR-6 | Invitation, verification and reset tokens | only SHA-256 hashes stored; raw tokens only in URL fragments | keep for invitations (§13.3 IN-7) |
| NR-7 | Credentials and JWTs | absent from DTOs; `AdminActivityLogService` refuses credential-shaped text | keep; the same guard applies to the strict partner audit (§22.1 AU-2) |

Each rule gets a test in the phase that touches the response (R3b for NR-1/NR-2, regression tests for NR-3 to
NR-7): the test fails if the field appears in any partner (or admin, for NR-3–NR-5) response body.

### 21.4 Admin masking (§31 Q14)

- Guest identity and contact in `admin.booking.view` and `admin.payment.view` responses are returned unmasked
  only to callers holding A05 `admin.customer.view`; others (notably TECH_SUPPORT and PARTNER_OPERATIONS) get
  masked names and omitted contact, with the same `redacted` array.
- ANALYTICS holds only aggregate endpoints (A01, A04); it never reads individual reviews, bookings or customers.

---

## 22. Audit requirements

### 22.1 Writer semantics

- **AU-1** Security-sensitive partner events (team, grants, owners, invitations, payout, security settings,
  workspace conflicts) are written **in the mutating transaction and fail closed** — the
  `AdminActivityLogService.record` standard (`:83-101`), not the best-effort `PartnerActivityLogService.log`.
- **AU-2** Each row carries: company, actor user id **and actor email snapshot** (or `SYSTEM` for migrations and
  sweeps), action, target type/id, before/after safe scalars (e.g. `MANAGER@COMPANY:456`), reason when supplied,
  timestamp. Same credential guard as the admin trail.
- **AU-3** Append-only: the strict writer's repository exposes no update or delete path (as
  `AdminActivityLogRepository`); the snapshot is never re-resolved on read.
- **AU-4** Visible to OWNER/MANAGER through P05 and to admins through A08 (existing
  `GET /api/admin/partners/{id}/activity-logs`).

### 22.2 Partner event vocabulary (follows the existing `<ENTITY>_<PAST_VERB>` style)

`TEAM_MEMBER_INVITED`, `TEAM_INVITATION_RESENT`, `TEAM_INVITATION_REVOKED`, `TEAM_INVITATION_ACCEPTED`,
`TEAM_INVITATION_DECLINED`, `TEAM_MEMBER_ROLE_CHANGED`, `TEAM_MEMBER_SCOPE_REVOKED`, `TEAM_MEMBER_SUSPENDED`,
`TEAM_MEMBER_REACTIVATED`, `TEAM_MEMBER_REMOVED`, `TEAM_MEMBER_LEFT`, `OWNER_GRANTED`, `OWNER_REVOKED`,
`OWNERSHIP_TRANSFERRED`, `SETTINGS_UPDATED`, `SECURITY_SETTINGS_UPDATED`, `MEMBERSHIP_REMEDIATED` (M-6, actor
`SYSTEM`); existing `PAYOUT_ACCOUNT_UPDATED` gains masked before/after. `TEAM_MEMBER_ADDED` stays readable for
history but is no longer written once invitations ship.

### 22.3 Admin event vocabulary (follows the existing `<ENTITY>_<VERB>` style)

`ADMIN_PROFILE_GRANT`, `ADMIN_PROFILE_REVOKE`, `ADMIN_STEP_UP`, `ADMIN_STEP_UP_FAILED`, `USER_ACCOUNT_DISABLE`,
`USER_ACCOUNT_ENABLE`, `PARTNER_OWNERSHIP_INTERVENE`, `TRAVEL_WALLET_VIEW`, `CONVERSATION_VIEW`,
`DUAL_CONTROL_REQUEST`, `DUAL_CONTROL_APPROVE`, `DUAL_CONTROL_REJECT`. Adding them changes the deliberate set
pinned by `AdminAuditInfrastructureTest` (114 today); that test must be updated **deliberately** in the phase
that adds each action.

### 22.4 Denials

Authorization denials are not business events. They are logged at `WARN` with user id, permission key and
target type (never the target's data), rate-limited, so probing is detectable without filling the audit trail.

### 22.5 Read-access audit for sensitive admin reads

- `GET /api/admin/users/{userId}/travel-wallet` (A06) writes `TRAVEL_WALLET_VIEW` (target `USER`, id = the
  customer).
- `GET /api/admin/conversations/{id}` (A28) writes `CONVERSATION_VIEW` (target `CONVERSATION`); the list
  endpoint writes one row per request with its filters, not one per conversation.
- Rows carry identifiers only, never content. A read-audit write failure fails the read (fail closed), matching
  the admin trail's semantics.
- Recommended next (not mandatory in V1): `CUSTOMER_PROFILE_VIEW` for A05 detail reads.

### 22.6 Dual control (threshold principle and enforcement strategy)

- **Principle.** A dual-controlled action executes only after a second administrator approves it. The approver
  must differ from the requester, hold the same permission or be `PLATFORM_OWNER`, and act within the request's
  validity (24 h). The approval executes the action in the same transaction as its own audit row
  (`DUAL_CONTROL_APPROVE` plus the action's existing audit action).
- **Scope and thresholds.**

| Permission | Action | Dual control |
|---|---|---|
| A16 `admin.place.owner.assign` | move a property between companies | **always** |
| A11 `admin.partner.ownership.intervene` | owner recovery / transfer | **always** (approver `PLATFORM_OWNER`) |
| A31 `admin.payment.intervene` | refund | above a configurable amount per currency |
| A39 `admin.gift_card.value.manage` | issue / adjust value | above a configurable amount per currency |
| A41 `admin.customer.entitlement.adjust` | grant points, refund a redemption, manual tier | above a configurable value |
| A42 `admin.travel_credit.adjust` | grant / deduct credits | above a configurable amount per currency |

- **Enforcement strategy.** Until enforcement ships: A16 is `PLATFORM_OWNER`-only, A11 does not exist
  (reserved), and A31/A39/A41/A42 remain single-actor with their existing audits plus a daily review report of
  above-threshold actions (detective control). Enforcement for A16 and A11 lands with admin profiles (R6);
  thresholds for A31/A39/A41/A42 in hardening (R7). Threshold values are an operational setting (§31).

---

## 23. Frontend authorization / menu visibility rules

- **F1 Backend is authoritative; the client shapes affordances only.** (Existing principle, `app_role.dart`,
  `surface_gate.dart`.)
- **F2 Source of truth.** After workspace load the client calls `GET /api/partner/me/access` (§25.2) and keeps
  the result in `PartnerState` (in memory only — never persisted to browser storage). Admin console: `GET
  /api/admin/me/access`.
- **F3 Checks by permission, never by role name.** `partner.teamRole == PartnerTeamRole.owner` (six sites,
  §2.9) and `isWritableBy` are replaced by `access.can(permission, propertyId?)` over the **effective**
  permissions of the access document. Role names are shown as labels only.
- **F4 Menu.** A destination is shown when the caller holds its permission in the effective permissions at any
  scope; the server menu (`PartnerExtranetService.getMenu`) applies the same rule so both agree:

| Destination (`MenuItem.key`) | Shown with |
|---|---|
| dashboard | P01 (each tile needs its own permission; revenue tiles need P49) |
| hotels | P14, or parent context only (§11.7) for UNIT-scoped members |
| rooms | P21 |
| calendar | P26 |
| pricing | P29 |
| promotions | P32 |
| bookings | P34 |
| messages | P42 |
| analytics | P48 or P49 |
| finance | P49 or P50 or P51 |
| reviews | P44 |
| notifications | P01 (personal notifications, incl. mandatory security notifications) |
| settings | P01 — tabs: Team needs P07, Payout needs P52, Profile needs P02, workspace settings editable with P04 |

- **F5 Actions.** A write control is hidden when the permission is absent at every scope, and disabled with an
  explanation when present at some scopes but not for the selected property.
- **F6 Property switcher** lists the properties of the access document's context (§11.7).
- **F7 Fail closed.** If the access document cannot be loaded, the workspace shows a read-only error state; it
  never falls back to "owner".
- **F8 Refresh.** Reload the access document on workspace load, on any `403 PERMISSION_DENIED`, and on
  explicit refresh; treat a `404` on a previously visible property as "access removed".
- **F9 Unknown keys** in the document are ignored; unknown roles render as `unknown` (existing
  `PartnerTeamRole.unknown`).
- **F10 Team members become first-class.** `PartnerWorkspaceStatus.teamMemberUnsupported` is retired once the
  backend enforces the matrix (R3b) and the frontend reads the access document (R5), not before.
- **F11 Admin console** builds its destinations from admin permissions the same way; `AdminRouteGuard` stays as
  the system-role gate.
- **F12 Phase C editor and Phase D wizard.** They save one section per request (basics, contact, location,
  amenities, policies). With per-section permissions (P16 vs P17) the client pre-checks each section,
  disables sections the caller cannot edit (e.g. the policies step for CONTENT), and on a mixed result reports
  exactly which sections were saved and which were refused — a save is never presented as all-or-nothing.
- **F13 Invitations.** The accept page (§14) shows the generic guidance before sign-in; the onboarding screen
  shows pending invitations (§14 AC-5) before "Create business profile"; a `STEP_UP_REQUIRED` response opens a
  password re-confirmation dialog and retries once.
- **F14 Redaction.** The client renders `redacted` fields as "hidden" (masked or omitted), never as empty data.

---

## 24. Backend authorization rules

- **B1 One authorization kernel.** A single `PartnerAccessService` replaces the 13 `myApprovedProfileOrThrow`
  helpers and `PartnerSettingsService.resolveAccess`; an `AdminAccessService` evaluates admin profiles.
- **B2 First statement of every partner service method** is the evaluator call for its registered endpoint kind
  — `access.requireResource(uid, P, type, id)`, `access.scopeSet(uid, P)` or `access.requireCompany(uid, P)` —
  before reading any business data.
- **B3 Resolution order** exactly as §4.5. Scope is derived from the target id via the repositories of §11.2,
  never from request bodies, query parameters or headers.
- **B4 Company lifecycle gate preserved.** Every operational permission requires the company to be `APPROVED`
  (existing `requireApproved`); onboarding and self endpoints follow their own rules (§25.2, §25.3).
- **B5 Query-level scoping.** Collections and aggregates are filtered in the query by the permitted scope set S,
  not post-filtered in memory, so pagination, counts and sums stay truthful.
- **B6 No role-name checks in business code.** Raw `"ADMIN".equals(user.getRole())` checks (§2.5) are replaced
  by `AccountRole.parse` + admin permissions (phase R7).
- **B7 URL rules stay as defence in depth.** `/api/admin/**` → `ADMIN`, `/api/partner/**` → `PARTNER|ADMIN`
  until R7 (§31 Q13).
- **B8 Admin overrides do not flow through partner endpoints.** An `ADMIN` calling `/api/partner/**` resolves no
  workspace (freeze §B); cross-company power stays under `/api/admin/**`.
- **B9 Field-diff checks for mixed payloads (G10).** `PUT /rooms/{roomId}` requires P23 if any content field
  differs from the stored value and P24 if any commercial field differs; calendar `PUT …/{date}` and
  `POST …/bulk` require P27 if any count differs and P28 if any restriction flag differs. A later phase may split
  the endpoints; the permission keys do not change.
- **B10 Owner/last-owner/delegation checks** run inside the mutating transaction with the company row locked
  (§19 LO-3).
- **B11 Endpoint registry test.** Every `@*Mapping` handler under `controller/Partner*` and `controller/Admin*`
  is registered with its kind, primary permission, resource type, field-level permissions, aggregate marking and
  step-up flag; a test fails on any unregistered handler, so a new endpoint cannot ship unprotected.
- **B12 Negative test matrix.** For each partner endpoint: unauthenticated (401), wrong system role (403),
  other company (404), out-of-scope property (404), in-scope without the resource type's view permission (404),
  in-scope with view but without the action's permission (403), allowed; plus the never-readable fields (§21.3).
- **B13 No caching across requests** of membership/grants beyond the request scope until a cache with
  explicit invalidation is designed; correctness of immediate revocation outranks the saved lookups.
- **B14 Step-up** is checked after ALLOW for registered step-up actions (§18 O-7).
- **B15 Workspace invariant** WS-1…WS-5 is enforced in profile creation, invitation acceptance and membership
  reactivation (§11.6, I21).
- **B16 Mandatory security notifications** are emitted inside the mutating transaction's commit path and do not
  consult `PartnerSettings` (§18 O-8).
- **B17 Dual control** follows §22.6; until enforced, A16 is restricted to `PLATFORM_OWNER` by the profile matrix.

---

## 25. API authorization design

### 25.1 Existing partner endpoints → permission (90 endpoints, paths under `/api/partner`)

`n` = number of endpoints in the row. Kinds per §4.5. "Aggregate" marks every aggregate/report endpoint as
**FILTERABLE BY PROPERTY** (computed over the caller's scope set S; the existing optional `hotelId` filter must
lie inside S) or **COMPANY ONLY** (requires a COMPANY grant).

| Controller | Endpoint(s) | n | Kind (type) | Primary | Field-level / extra | Aggregate |
|---|---|---|---|---|---|---|
| Analytics | `GET /analytics/overview` | 1 | COLLECTION | P48 | revenue fields P49 | FILTERABLE BY PROPERTY |
| | `GET /analytics/revenue` | 1 | COLLECTION | P49 | | FILTERABLE BY PROPERTY |
| | `GET /analytics/{occupancy,bookings,rooms,reviews,messages}` | 5 | COLLECTION | P48 | | FILTERABLE BY PROPERTY |
| | `GET /analytics/promotions` | 1 | COLLECTION | P48 | revenue fields P49 | FILTERABLE BY PROPERTY |
| Booking | `GET /bookings` | 1 | COLLECTION (booking) | P34 | name P54 (masked), email P35, free text P40 | — |
| | `GET /bookings/{id}` | 1 | RESOURCE (booking) | P34 | P54, P35, P40, P36; NR-1/NR-2 fields never | — |
| | `PATCH /bookings/{id}/check-in` | 1 | RESOURCE (booking) | P37 | | — |
| | `PATCH /bookings/{id}/check-out`, `/complete` | 2 | RESOURCE (booking) | P38 | | — |
| | `PATCH /bookings/{id}/no-show` | 1 | RESOURCE (booking) | P39 | | — |
| | `GET /dashboard` | 1 | COLLECTION (booking) | P34 | revenue fields P49 | FILTERABLE BY PROPERTY |
| | `POST /bookings/voucher/verify`, `POST /bookings/check-in` | 2 | RESOURCE (booking by code) | P37 | name P54 | — |
| | `POST /bookings/check-out` | 1 | RESOURCE (booking by code) | P38 | name P54 | — |
| Calendar | `GET /calendar/rooms/{roomId}` | 1 | RESOURCE (calendar) | P26 | | — |
| | `PUT /calendar/rooms/{roomId}/{date}`, `POST …/bulk` | 2 | RESOURCE (calendar) | P27 / P28 | field-diff (B9) | — |
| | `PATCH …/{date}/stop-sell`, `/closed-arrival`, `/closed-departure` | 3 | RESOURCE (calendar) | P28 | | — |
| | `PUT /calendar/rooms/{roomId}/price` | 1 | RESOURCE (rate plan, via room) | P30 | | — |
| | `GET /calendar/rooms/{roomId}/price` | 1 | RESOURCE (rate plan, via room) | P29 | | — |
| Conversation | `GET /conversations` | 1 | COLLECTION (conversation, filtered by `booking.hotel ∈ S`) | P42 | name P54 | — |
| | `GET /conversations/{id}` | 1 | RESOURCE (conversation) | P42 | name P54 | — |
| | `POST /conversations/{id}/messages`, `PATCH …/read`, `PATCH …/close` | 3 | RESOURCE (conversation) | P43 | | — |
| Extranet | `GET /extranet/home` | 1 | COMPANY (workspace entry) | P01 | each block needs its permission; finance block P49 | FILTERABLE BY PROPERTY (every block over S) |
| | `GET /extranet/menu` | 1 | COMPANY (workspace entry) | P01 | filtered per §23 F4 | — |
| | `GET /extranet/account-summary` | 1 | COMPANY (workspace entry) | P01 | payout block P52, team count P07, profile detail P02 | COMPANY ONLY (company-level blocks) |
| | `GET /extranet/activity-logs` | 1 | COMPANY | P05 | | COMPANY ONLY |
| Finance | `GET /finance/overview`, `/finance/revenue` | 2 | COLLECTION | P49 | | FILTERABLE BY PROPERTY |
| | `GET /finance/settlements`, `/commissions`, `/invoices`, `/refunds` | 4 | COMPANY | P50 | | COMPANY ONLY (`hotelId` stays a filter for COMPANY holders) |
| | `GET /finance/payouts` | 1 | COMPANY | P51 | | COMPANY ONLY |
| Hotel | `GET /hotels` | 1 | COLLECTION (property) | P14 | | — |
| | `POST /hotels` | 1 | COMPANY | P15 | | — |
| | `GET /hotels/{id}` | 1 | RESOURCE (property) | P14 | | — |
| | `PUT /hotels/{id}`, `/contact`, `/location`, `/amenities` | 4 | RESOURCE (property) | P16 | | — |
| | `PUT /hotels/{id}/policies` | 1 | RESOURCE (property) | P17 | | — |
| | `PATCH /hotels/{id}/activate`, `/deactivate` | 2 | RESOURCE (property) | P18 | | — |
| Place review analytics | `GET /places/{placeId}/reviews/analytics` | 1 | RESOURCE (review, one property) | P44 | | single property (not a company report) |
| Pricing | `GET /rooms/{roomId}/rate-plans`, `/pricing-preview`; `GET /rate-plans/{id}/occupancy-prices`, `/preview`; `POST /rate-plans/{id}/validate` | 5 | RESOURCE (rate plan) | P29 | | — |
| | `POST /rooms/{roomId}/rate-plans`; `PUT/DELETE /rate-plans/{id}`; `POST /rate-plans/{id}/duplicate`; `POST /rate-plans/{id}/occupancy-prices`; `PUT/DELETE /rate-plan-occupancy-prices/{id}` | 7 | RESOURCE (rate plan) | P30 | | — |
| | `POST /rate-plans/{id}/activate`, `/deactivate` | 2 | RESOURCE (rate plan) | P31 | | — |
| Profile | `POST /profile`, `POST /profile/submit` | 2 | SELF (registrant; WS-2) | — / P03 after approval | | — |
| | `GET /profile` | 1 | SELF (registrant) | — / P02 after approval | | — |
| Promotion | `GET /promotions` | 1 | COLLECTION (promotion) | P32 | | — |
| | `GET /promotions/{id}` | 1 | RESOURCE (promotion) | P32 | | — |
| | `POST /promotions` | 1 | RESOURCE (body target) | P33 | target via `hotel_details`/`hotel_rooms` (§11.2) | — |
| | `PUT/DELETE /promotions/{id}` | 2 | RESOURCE (promotion) | P33 | | — |
| Review | `PUT /reviews/{reviewId}/reply` | 1 | RESOURCE (review) | P45 | | — |
| Room | `GET /rooms` | 1 | COLLECTION (room) | P21 | | — |
| | `GET /rooms/{roomId}` | 1 | RESOURCE (room) | P21 | | — |
| | `PUT /rooms/{roomId}` | 1 | RESOURCE (room) | P23 / P24 | field-diff (B9) | — |
| | `PATCH /rooms/{roomId}/activate`, `/deactivate` | 2 | RESOURCE (room) | P25 | | — |
| Settings | `GET /settings` | 1 | COMPANY (workspace entry) | P01 | | — |
| | `PUT /settings` | 1 | COMPANY | P04 | operational notification toggles only | — |
| | `GET /payout-account` | 1 | COMPANY | P52 | | — |
| | `PUT /payout-account` | 1 | COMPANY | P53 | step-up | — |
| | `GET /team` | 1 | COLLECTION (membership) | P07 | | — |
| | `POST /team` | 1 | COMPANY (legacy) | P08 (+P12 for OWNER) | legacy semantics §29 | — |
| | `PATCH /team/{id}` | 1 | RESOURCE (membership) | P09 (role) / P10 (active) | +P12 and step-up for OWNER changes | — |
| | `DELETE /team/{id}` | 1 | RESOURCE (membership) | P11 | soft revoke | — |
| Stay | `GET /stays/{bookingId}` | 1 | RESOURCE (booking) | P40 | name P54 | — |

### 25.2 Effective access document (new, read-only)

`GET /api/partner/me/access`

**Authorization (kind `SELF`, not P01):**

| Caller | Response |
|---|---|
| not authenticated | 401 (URL rule) |
| `USER` | 403 (URL rule `/api/partner/**`) |
| `ADMIN` | 404 — admins have no workspace (R-S3, B8) |
| `PARTNER` with no own profile and no `ACTIVE`/`SUSPENDED` membership | 404 (newcomer → onboarding, as today) |
| `PARTNER` with an own profile in any status, or an `ACTIVE`/`SUSPENDED` membership | **200** |

It is deliberately **not** gated by P01, by `APPROVED`, or by membership status, so a suspended member or an
owner of an unapproved company still receives an explanation. Permissions are listed only when the membership
is `ACTIVE` (or the caller is the primary owner) **and** the company is `APPROVED`; otherwise they are empty.
`Cache-Control: no-store`.

```json
{
  "workspace": { "companyId": 456, "businessName": "…", "verificationStatus": "APPROVED" },
  "membership": { "id": 12, "status": "ACTIVE", "primaryOwner": false, "pendingOwnerConfirmation": false },
  "grants": [ { "role": "FRONT_DESK", "scopeType": "PROPERTY", "scopeId": 123 } ],
  "permissions": {
    "company": [ "partner.workspace.access" ],
    "properties": { "123": [ "partner.property.view", "partner.booking.view",
                              "partner.booking.guest_identity.view", "partner.booking.arrival.operate" ] },
    "units": {}
  },
  "context": {
    "properties": [ { "id": 123, "name": "…", "locationLabel": "…", "active": true, "placeStatus": "DRAFT" } ],
    "units": []
  },
  "stepUp": { "freshUntil": "2026-10-04T10:15:00Z" }
}
```

`permissions` contains **effective** permissions only (after scope floors, §4.5): a floor-`C` permission never
appears under `properties`, and a floor-`P` permission never appears under `units`.

`GET /api/admin/me/access` → `{ "profiles": [...], "permissions": [...], "stepUp": {...} }` (A01).

### 25.3 New team and invitation endpoints (proposed contract)

| Method & path | Kind | Permission | Phase | Notes |
|---|---|---|---|---|
| `GET /api/partner/team` | COLLECTION (membership) | P07 | R3a (additive) | adds `status`, `grants[]`, `primaryOwner`, `pendingOwnerConfirmation`, `isSelf` |
| `PUT /api/partner/team/{memberId}/grants` | RESOURCE (membership) | P09 (+P12, step-up) | R3a | §15 |
| `POST /api/partner/team/{memberId}/suspend` / `/reactivate` | RESOURCE (membership) | P10 | R3a | §17 |
| `DELETE /api/partner/team/{memberId}` | RESOURCE (membership) | P11 | R3a | soft revoke |
| `POST /api/partner/team/leave` | SELF | membership | R3a | §17 |
| `GET /api/partner/team/invitations` | COLLECTION (invitation) | P07 | R4 | within authority |
| `POST /api/partner/team/invitations` | RESOURCE (invitation; body target: every invited grant) | P08 (+P12, step-up for OWNER) | R4 | §13.1 — 202, uniform body; each invited grant is resolved per §11.2 and P08 must cover its scope (§11.4, PA-3), so no invitation widens the inviter's authority |
| `POST /api/partner/team/invitations/{id}/resend` | RESOURCE (invitation) | P08 | R4 | §13.2 |
| `DELETE /api/partner/team/invitations/{id}` | RESOURCE (invitation) | P08 | R4 | revoke |
| `GET /api/me/partner-invitations` | SELF | authenticated PARTNER, verified email | R4 | §14 AC-5 |
| `POST /api/me/partner-invitations/accept` | SELF | authenticated; PARTNER checked in service | R4 | §14 |
| `POST /api/me/partner-invitations/decline` | SELF | authenticated holder of the token | R4 | §14 AC-1 |
| `POST /api/partner/ownership/transfer` (+ accept) | COMPANY | P13 (step-up) | R8 | reserved |

Team mutations shipped in R3a (grants, suspend/reactivate, remove) are usable only by owners until R4, when
MANAGER's team permissions take effect (§10.1 footnote ¹, §31 Q3).

### 25.4 New admin access endpoints (phase R6)

| Method & path | Permission |
|---|---|
| `GET /api/admin/me/access` | A01 |
| `GET /api/admin/access/admins` | A02 |
| `PUT /api/admin/access/admins/{userId}/profiles` | A02 (+ AP-1, AP-2, step-up) |

### 25.5 Admin endpoints

Mapped in §9.2 ("Backing endpoints"). Enforcement: one permission per handler through the registry of B11
(value-dependent for `PATCH /places/{id}/status`); the URL rule `hasRole("ADMIN")` remains the outer gate.

### 25.6 Step-up endpoint (phase R3a)

`POST /api/me/step-up {currentPassword}` — `authenticated()` today (`/api/me/**`); any system role.

- Correct password → `200 {token, user}`: a newly issued token in the existing format (fresh for 15 minutes,
  §18 O-7). The previous token stays valid until it expires — step-up adds freshness, it does not rotate sessions.
- Wrong password → `400 CURRENT_PASSWORD_INCORRECT` (Phase A code, `fieldErrors: currentPassword`); at most 5
  attempts per 15 minutes per account → `429 STEP_UP_RATE_LIMITED`.
- For `ADMIN` accounts both outcomes are audited (`ADMIN_STEP_UP`, `ADMIN_STEP_UP_FAILED`).

---

## 26. Error semantics: 401 vs 403 vs 404

| # | Situation | Status | `code` |
|---|---|---|---|
| E1 | No token, bad signature, expired, `ver` mismatch, disabled account, unrecognised stored role | **401** | — (existing entry-point body) |
| E2 | Valid session, wrong system role for the URL tree | **403** | — (existing handler body) |
| E3 | `PARTNER` with no workspace (no own profile, no ACTIVE membership) on an operational endpoint | **404** `Partner profile not found` | — (existing) |
| E4 | Company not `APPROVED` (incl. `SUSPENDED`) on an operational endpoint | **403** | `PARTNER_NOT_APPROVED` (new code on the existing response) |
| E5 | RESOURCE: target missing, in another company, or the caller holds no **view(type)** permission covering it | **404**, same body as a missing id | — |
| E6 | RESOURCE: caller holds view(type) covering the target but not the action's permission | **403** | `PERMISSION_DENIED` (+ `permission` key) |
| E7 | COLLECTION or COMPANY endpoint and `E(p)` gives no qualifying scope | **403** | `PERMISSION_DENIED` |
| E8 | COLLECTION filter (e.g. `hotelId`) outside the scope set S | **404** | — |
| E9 | Body references a scope outside the company (grant, invitation) | **422** | `SCOPE_INVALID` (fieldErrors) |
| E10 | Delegation or authority exceeded (§10.3) on a non-owner member | **403** | `ROLE_NOT_DELEGABLE` |
| E11 | Acting on an owner without authority | **403** | `OWNER_PROTECTED` |
| E12 | Modifying own grants/status | **403** | `SELF_MODIFICATION_FORBIDDEN` |
| E13 | Step-up required and the token is not fresh | **403** | `STEP_UP_REQUIRED` |
| E14 | Would leave no owner / no platform owner | **409** | `LAST_OWNER_REQUIRED` / `LAST_PLATFORM_OWNER_REQUIRED` |
| E15 | Stale membership version | **409** | `CONCURRENT_MODIFICATION` |
| E16 | One-workspace conflict (profile creation, acceptance, reactivation) / company unavailable / stale invitation / invitation not pending | **409** | `WORKSPACE_CONFLICT` (+ `reason`) / `WORKSPACE_UNAVAILABLE` / `INVITATION_STALE` / `INVITATION_NOT_PENDING` |
| E17 | Already a member (visible to the actor) | **409** | `ALREADY_MEMBER` |
| E18 | Invitation token unknown/used/revoked / expired | **400** | `INVITATION_INVALID` / `INVITATION_EXPIRED` (mirrors Phase A `TOKEN_INVALID`/`TOKEN_EXPIRED`) |
| E19 | Invitation for another address / account not PARTNER (incl. USER and ADMIN) | **403** | `INVITATION_ACCOUNT_MISMATCH` / `PARTNER_ACCOUNT_REQUIRED` |
| E20 | Invitation or step-up rate limits | **429** | `INVITATION_RATE_LIMITED` / `STEP_UP_RATE_LIMITED` |
| E21 | Email provider unavailable for invitations | **503** | `EMAIL_DELIVERY_UNAVAILABLE` (Phase A code) |
| E22 | Admin lacks an admin permission | **403** | `PERMISSION_DENIED` — admins may know the admin API exists; no existence hiding between admins |
| E23 | Unmapped route | **404** (today: 500 — G17) | — |
| E24 | Legacy `POST /api/partner/team` (R3a until R4 only): the target cannot be attached directly — unknown, traveller, admin or conflicting account, all alike | **422** | `MEMBER_NOT_ADDABLE` |

Principles:

- **401 = who are you?** **403 = I know who you are, and you may not do this to something you are allowed to
  know exists.** **404 = as far as you are concerned, this does not exist.**
- 403 is never used where it would confirm the existence of another tenant's resource, or of a resource type the
  caller has no view permission for (E5 beats E6).
- Existing user-side `checkOwnerOrAdmin` 403s (G13) should become 404 in phase R7; this is a behaviour change
  for travellers' clients and is scheduled, not silent.

---

## 27. Security invariants

| # | Invariant |
|---|---|
| I1 | Exactly three system roles; permissions never change a system role, and no workspace action writes `users.role`. |
| I2 | No permission, membership or scope is ever read from the JWT or the request; all are resolved server-side per request. |
| I3 | Every partner resource is reachable only through its owning company; a caller's company is never the request's choice. |
| I4 | A caller can affect a property only if a grant of theirs covers it; covering is containment over the current database state. |
| I5 | Out-of-scope and foreign resources, and resources of a type the caller cannot view, are indistinguishable from missing ones (404). |
| I6 | No one can grant a permission they do not hold at a covering scope, nor a grant wider than their own. |
| I7 | No one can modify their own grants or status. |
| I8 | Only owners manage owners; the primary owner cannot be removed or demoted from inside the workspace. |
| I9 | A company always has ≥ 1 active, enabled, confirmed owner; the platform always has ≥ 1 active PLATFORM_OWNER. |
| I10 | Non-delegable permissions (P03, P06, P12, P13; A02) can only be held by OWNER / PLATFORM_OWNER, including via future custom roles or overrides. |
| I11 | Financial aggregates, statements, payout records and payment records are never implied by an operational permission; money fields are filtered by the server. |
| I12 | Guest identity, contact and free text are returned only with P54 / P35 / P40 (partner) or the matching admin permission. |
| I13 | Revocation, suspension and company suspension take effect on the next request. |
| I14 | Every security-sensitive mutation is audited in the same transaction and fails closed. |
| I15 | Partner and admin permissions never satisfy each other; an account never holds both a membership and an admin profile. |
| I16 | A property moved between companies leaves no grant of the previous company behind, and its conversations authorize through the property's current owner. |
| I17 | Every handler under `Partner*`/`Admin*` controllers is mapped to exactly one primary permission and one endpoint kind. |
| I18 | `PlaceStatus.PUBLISHED` is still the only public state (`PublicListingVisibility`); no RBAC change alters listing visibility, and no partner publish capability exists until P20 ships. |
| I19 | The client never widens access: unknown permission, unknown role, or a failed access load ⇒ least privilege. |
| I20 | The company `APPROVED` gate precedes every operational permission. |
| I21 | **One workspace per account:** an account never has an own `PartnerProfile` and a non-revoked membership at the same time, and never more than one `ACTIVE` membership — enforced at profile creation (409), invitation acceptance (409), membership reactivation (409), and for legacy data by M-0/M-6. |
| I22 | A `PROPERTY` or `UNIT` grant never satisfies a floor-`C` permission or a COMPANY-kind endpoint; a `UNIT` grant never satisfies a floor-`P` permission. |
| I23 | Bearer instruments and the never-to-partner fields of §21.3 are never readable through any response. |
| I24 | No migration or backfill grants owner-management (P12) or payout (P52, P53) power to an account that does not exercise it today. |
| I25 | Owner security notifications cannot be disabled by any setting or role. |

---

## 28. Migration strategy

Production schema is Flyway-owned on SQL Server (`application-prod.properties:34`, `ddl-auto=validate` at
`:41`); dev/test use H2 with Flyway **off** and `ddl-auto=update` (`application.properties:7,13`). Every step is
additive and forward-only, and each migration gets a static check in the style of
`FlywayMigrationConfigTest.v3AccountLifecycleMigrationIsAdditiveAndSqlServerSafe`, plus a run of the
environment-gated `SqlServerProdChainVerificationTest` (`DB05_SQLSERVER_VERIFY=true`) against a disposable SQL
Server database before release. Step identifiers are stable; **execution order is
M-0 → M-1 → M-2 → M-4 → M-6 → M-3 → M-5**, and Flyway version numbers are assigned in that order at
implementation.

| Step | Phase | Content | Effective-rights change |
|---|---|---|---|
| **M-0** | before R2 (and again before R3a) | **Pre-migration data audit** — read-only report, no writes. Detects: (a) team members whose account role is `ADMIN` (R-S3); (b) accounts violating WS-1 — an own profile **and** an active membership; (c) accounts with more than one `active = true` membership (today a 500); (d) non-registrant `OWNER` rows; (e) inactive rows (`active = false`); (f) members whose account role is not `PARTNER`; (g) approved registrants without their OWNER row. The report is reviewed and signed off before R2 ships | none |
| **M-1** | R2 | `partner_team_members`: add `status`, `status_reason`, `status_changed_at`, `status_changed_by`, `pending_owner_confirmation` (default 0), `version`; backfill `status = ACTIVE` where `active = 1`, `SUSPENDED` (reason `LEGACY_INACTIVE`) where `active = 0`; **drop the system-named role CHECK** (look its name up in `sys.check_constraints` — generated in V1) and re-create it named, with the 9 roles; add the missing OWNER row of approved registrants (rule of `ensureOwnerTeamMember`) | none — legacy rules still read `active` and `role` |
| **M-2** | R2 | `partner_member_grants` + unique key + named CHECKs (`role` 9 values, `scope_type` `COMPANY`/`PROPERTY`/`UNIT`); backfill one `COMPANY` grant per non-revoked membership, mirroring `role` exactly | none — the R1/R2 kernel reproduces today's rules |
| **M-4** | R2 | `partner_activity_logs`: add `actor_email` (snapshot; backfilled from the current `users.email` for existing rows and marked as backfilled in `reason`), `before_state`, `after_state` (500), `reason`; the strict writer requires `actor_email` on every new row and its repository exposes no update/delete | none |
| **M-6** | R3a (same release as owner protections) | **Remediation data step** driven by the signed-off M-0 report (letters refer to the M-0 findings; (e) inactive rows and (g) missing OWNER rows are already handled by M-1), every change written to the strict partner audit as `MEMBERSHIP_REMEDIATED` (actor `SYSTEM`) with a mandatory owner notification: (a) `ADMIN` members → `REVOKED`; (b) WS-1 violators → the membership is `SUSPENDED` (reason `WS1_CONFLICT`; the own company wins, as today); (c) multiple active memberships → all `SUSPENDED` (reason `WS1_CONFLICT`), each owner may reactivate one (WS-5 re-checks); (d) non-registrant `OWNER` grants → `MANAGER@COMPANY` with `pending_owner_confirmation = 1` and `role` synced to `MANAGER` (§18 O-9); (f) non-`PARTNER` members → `SUSPENDED` (reason `ACCOUNT_ROLE`) | **reduction only** (I24): (d) removes legacy team-management power until the primary owner confirms; nothing gains power |
| **M-3** | R4 | `partner_invitations` (incl. `resend_count`, `last_sent_at`, `delivery_status`), `partner_invitation_grants` | none until R4 endpoints ship |
| **M-5** | R6 | `admin_profile_assignments` + filtered unique index (11 profile values); backfill every `ADMIN` user → `PLATFORM_OWNER`, `granted_by = NULL` (system) | none |

Not migrated: `users.role`, the JWT, `places`, `bookings`, any listing or pricing table.
`conversations.partner_profile_id` is only re-pointed at runtime by PA-4, never by a migration.

**CHECK-constraint caution (G19).** `ddl-auto=validate` does not compare CHECK constraints and H2 never runs
these migrations, so the enum widening in M-1/M-2 must ship **in the same release** as the Java enum change and
be verified on SQL Server; otherwise inserting a new role fails only in production.

**Rollout gate.** Partner enforcement (R3b) is enabled only after R3a is live and M-6 has run; the
enforcement switch is part of the R3b release, never of a migration.

---

## 29. Backward compatibility strategy

Behaviour is **not** identical everywhere; what changes, and when, is listed here.

| Area | Guarantee / change |
|---|---|
| JWT, sign-in, system roles, URL rules | unchanged (Q13 tightening only in R7, announced) |
| Registrant (primary owner) on operational endpoints | unchanged in every phase — the registrant holds every permission, so no field is redacted and no check refuses them; owner-level actions (P12, P53) additionally require a fresh token (step-up) from R3a |
| Legacy team mutations (`POST/PATCH/DELETE /api/partner/team…`) | **change in R3a**: (1) no `USER → PARTNER` promotion — targets without a `PARTNER` account are refused with `422 MEMBER_NOT_ADDABLE`, the same code for unknown, traveller, admin and conflicting accounts (residual "eligible Partner exists" signal until R4); (2) `DELETE` becomes a soft revoke (`REVOKED`, row kept); (3) owner protection, last-owner locking, delegation/authority and self-modification rules apply; (4) every mutation is strictly audited and sends mandatory owner notifications; (5) OWNER changes need step-up. **In R4** `POST /team` stops attaching accounts directly and becomes an alias of `POST /team/invitations` (202, uniform body, invitation lifecycle §13–§14); the R4 backend ships together with the R5 team-management UI slice so no client meets the new contract unprepared |
| Legacy co-owners (non-registrant `OWNER` rows) | R3a: carried as MANAGER pending confirmation (§18 O-9) — they lose legacy team management until the primary owner confirms; announced |
| Existing `MANAGER`/`FINANCE`/`FRONT_DESK`/`VIEWER` members | R1–R3a: exactly today's operational rules (settings OWNER/MANAGER, payout OWNER/FINANCE, team OWNER, reads open). R3b deliberately changes them per §10.1 — *gains* (operational access) and *losses* (`VIEWER`/`FRONT_DESK` lose payout-metadata and team-list reads) are listed in that phase's release notes |
| Onboarding (`POST /api/partner/profile`) | R3a: refused with 409 `WORKSPACE_CONFLICT` for callers holding a non-revoked membership (WS-2) — **Freeze change**; unchanged for everyone else |
| Existing team rows | backfilled with status and a `COMPANY` grant of their role (M-1, M-2), remediated by M-6; no re-invitation |
| Response shapes | additive only (`redacted`, `grants`, `status`, `context`); permission-dependent fields are removed only for callers lacking the permission, never for the owner; NR-1/NR-2 fields are removed for **all** partner callers in R3b (announced: `checkoutUrl`, raw `failureReason`, `userId`, `loyaltyPointsRedeemed`) |
| Error bodies | existing status codes preserved; new `code` values are additive; the user-side 403→404 change (R7) and unmapped-route 500→404 (R7) are announced behaviour changes |
| Admins | every current `ADMIN` = `PLATFORM_OWNER` until narrowed (R6); `AdminAuditInfrastructureTest` updated deliberately when new admin actions are added; admin endpoints keep their contracts — A15/A46 only re-label the existing status endpoint |
| AdminActivityLog | unchanged writer and semantics; new actions are additive |
| Frontend | until R5, `PartnerTeamRole` mirrors and owner-only gating stay; R5 replaces them in one change set |
| Phase A | Partner registration, email verification, password reset/change, account status checks, `PublicListingVisibility` — unchanged (step-up reuses the Phase A password check and token issuance) |
| Phase B | Partner account/registration UI and business-profile lifecycle (`DRAFT → SUBMITTED → APPROVED/REJECTED`, `SUSPENDED`) — unchanged; Admin approval still gates every operational permission |
| Phase C | Property CRUD (`POST/PUT /api/partner/hotels…`), DRAFT-only creation, ownership from the authenticated company, owner/moderation spoofing ignored — unchanged for the registrant; per-section permissions apply to members from R3b |
| Phase D | Onboarding wizard as an orchestration layer over Phase C — unchanged for the registrant; for members the wizard follows §23 F12 |
| Publication | unchanged: no partner publish capability (P20 reserved); admin publication remains the existing status endpoint (A46) |

---

## 30. Future extensibility

- **Custom roles.** A company-defined role = a named subset of partner permissions, allowed scope types and a
  creator; subject to I6 (cannot exceed the creator) and I10 (no non-delegable keys). Requires
  `partner_custom_roles`; grants then reference either a built-in or a custom role. Not before R6 (§31 Q19).
- **Per-member overrides.** `partner_member_permission_overrides (team_member_id, permission, scope, effect
  ALLOW|DENY)`; DENY wins; ALLOW still bounded by I6/I10. Not in V1 to keep evaluation explainable.
- **More scope types.** `REGION` (a set of properties) or `BRAND` slot between COMPANY and PROPERTY without
  changing permission keys.
- **Physical rooms.** A `ROOM` scope type below `UNIT` (room type) when physical rooms are modelled; housekeeping
  permissions (P46, P47) already use the `U` floor and would extend to it.
- **Multi-company membership.** A validated workspace selector (path segment or header) and a relaxed WS-1.
- **Admin regional scope.** e.g. `LOCATION_CATALOGUE` limited to an administrative-unit subtree; admin grants
  gain an optional scope column.
- **MFA.** Step-up (O-7) becomes "password or second factor" without changing the protected action list.
- **Dual control** beyond §22.6, and a configurable approver policy.
- **Assisted access.** Time-boxed, audited admin entry into a partner workspace with explicit owner consent —
  explicitly not in V1 (§31 Q17).
- **Notification routing by permission** for operational notifications (booking notifications to holders of
  P34 at the property, payment notifications to P36/P50 holders). Security notifications are already routed to
  all owners (O-8).
- **Self-service withdrawal** of a `DRAFT`/`REJECTED` partner application (needs a `WITHDRAWN` lifecycle state).
- **Partner publication (P20).** When it ships, changing the location of an already-published property
  (part of P16 today) should pass through moderation; decided together with P20, not before.

---

## 31. Open questions — V1 decisions

All twenty questions raised by the initial design are **decided for V1**. "Needed by" names the first phase
(§32) that depends on the decision.

| # | Question | V1 decision | Reason | Needed by |
|---|---|---|---|---|
| Q1 | Should one PARTNER account belong to several companies? | **No.** One workspace per account (WS-1), also enforced at profile creation (WS-2) | Avoids an API change and ambiguous resolution; today's lookup already fails with two memberships | R2 |
| Q2 | May a traveller (`USER`) account be invited / promoted? | **No promotion.** A PARTNER account is required; a traveller's address cannot be reused, so the invitee asks for an invitation to another (work) address; `PARTNER_ACCOUNT_REQUIRED` without enumeration (§14 AC-3) | Workspace actions must not change system roles, and a promoted traveller loses the traveller app | R3a |
| Q3 | Should MANAGER manage the team? | **Yes**, below-manager roles within the manager's scope, only after owner protections exist | Multi-property operations need it; delegation and authority rules prevent escalation | R4 |
| Q4 | May FINANCE change the bank account without owner confirmation? | **Yes**, with step-up, mandatory notification to every owner, and a **72-hour hold** before the first payout to a new account | Keeps today's behaviour while closing the main payout-redirection fraud path | R3a (step-up, notification); payouts (hold) |
| Q5 | Guest names for VIEWER, REVENUE and FINANCE? | **Visible** for OWNER, MANAGER, RESERVATIONS, FRONT_DESK, FINANCE (P54); **masked** for REVENUE and VIEWER | Data minimisation: those two analyse stays, not people; finance reconciles named bookings | R3b |
| Q6 | Is `specialRequest` sensitive? | **Yes** — with `partnerNote` and `cancelReason`, visible only with P40 | Free text may contain health, accessibility or personal information | R3b |
| Q7 | Should CONTENT edit house rules while cancellation terms stay with managers? | **Keep** P17 with OWNER/MANAGER; split the policies endpoint later | Cancellation terms have financial and legal effect on guests | R8 |
| Q8 | Keep HOUSEKEEPING without a housekeeping domain? | **Keep** the role; default scope PROPERTY; UNIT allowed; writes reserved | The enum value must exist before the CHECK migration; harmless while read-only | R2 |
| Q9 | Is `UNIT` a room type or a physical room? | **Room type** in V1; a physical `ROOM` scope is a later, separate scope type | The schema has no physical rooms; inventing them is a schema change | R2 |
| Q10 | Property-scoped FINANCE? | **No** — FINANCE is COMPANY-only | Statements and payouts are company ledgers; a property slice looks complete but is not | — |
| Q11 | Add a growth/marketing admin profile? | **Yes — `GROWTH_MARKETING`** holds promotions, coupon definitions, gift-card products, customer programmes, personalization and aggregate analytics; FINANCE_OPERATIONS keeps money movement | Discount design and money movement must not sit in one profile | R6 |
| Q12 | Dual control, step-up and the fresh-session window? | **Password step-up** (`POST /api/me/step-up`), freshness **15 minutes** derived from `exp`; dual control for A16 and A11 always, and for A31, A39, A41, A42 above thresholds, enforced later (§22.6) | Owner and payout actions need recency without a JWT change | R3a (step-up); R6/R7 (dual control) |
| Q13 | Restrict `/api/partner/**` to `PARTNER` only? | **Yes, in R7** hardening, after the regression run | Removes a dead path admins already fail through; defence in depth with R-S3 | R7 |
| Q14 | PII masking for TECH_SUPPORT and ANALYTICS? | TECH_SUPPORT: **guest identity masked**, contact omitted (any caller without A05). ANALYTICS: **aggregates only** (A01, A04) | Diagnosis and reporting do not need identities; limits insider exposure | R6 |
| Q15 | Redaction format? | **`redacted[]`** list (`field`, `mode` OMITTED/MASKED) plus omitted or masked fields | One DTO per endpoint, explicit semantics, unchanged for owners | R3b |
| Q16 | Invitation lifetime and limits? | **7 days**, **≤ 20** pending per company, **60 s** per-email cooldown, **≤ 5** resends | Limits abuse of the email channel and stale invitations | R4 |
| Q17 | Should admins enter a partner workspace (assisted access)? | **No** in V1 | Large privacy surface; the admin API covers support needs | — |
| Q18 | Company without a reachable owner? | Operations **continue**; OWNER-only actions **blocked**; recovery by admin with **identity verification + audit** (A11, dual control); members **cannot self-promote** | Avoids an outage without creating a self-promotion path | R3a (rules); R8 (A11 endpoint) |
| Q19 | When do custom roles/overrides arrive? | **After R6**, only on demand | Invariants I6/I10 already constrain them; no V1 need | after R6 |
| Q20 | Who receives partner notifications? | **Security notifications: all owners, mandatory** (O-8). Operational notifications: registrant as today, permission-based routing later | Owners must see security events; operational routing is a UX improvement | R3a (security) |

**Remaining non-blocking parameters** (operational settings, not design decisions): dual-control threshold
amounts per currency; the exact security-notification copy; the email provider choice (an R4 release
dependency, §13.3 IN-5).

---

## 32. Recommended implementation phases

Each phase gets its own brief, its own tests and its own commit; nothing is pushed without approval. Phase
identifiers match revision 1.0, except that R3 is split into **R3a** (owner and team safety) and **R3b**
(partner enforcement) so that every owner protection is live **before** any member gains new power.

| Phase | Scope | Schema | Behaviour change | Exit criteria |
|---|---|---|---|---|
| **R0** | This document reviewed and frozen | — | — | approved by product + security |
| **R1** | Authorization kernel: permission enums (100 keys), registry of every partner/admin handler (kind, permission, resource type, field permissions, aggregate marking, step-up flag) with a "no unmapped handler" test, `PartnerAccessService` replacing the 13 helpers + `resolveAccess` with **legacy bundles that reproduce today's rules**, `PARTNER_NOT_APPROVED` code | none | none | full backend suite green; registry covers 90 + 181 handlers |
| **R2** | Schema foundation; M-0 signed off first | M-1, M-2, M-4 | none | SQL Server verification run; existing tests unchanged |
| **R3a** | **Owner and team safety (gate):** owner protection (O-1…O-9), last-owner locking, delegation/authority and self-modification rules, strict transactional partner audit, mandatory owner security notifications, step-up (`POST /api/me/step-up`, freshness), WS-1/WS-2 guard on profile creation, legacy team endpoint semantics (no promotion, soft revoke), `GET /api/partner/team` additive fields and new grant/suspend/leave endpoints; M-6 remediation in the same release | M-6 | yes (§29: legacy team endpoints, legacy co-owners, onboarding conflict) | concurrency test for LO-3; owner-protection and self-modification tests; audit fail-closed tests; notification-cannot-be-disabled test; I24 check on migrated data |
| **R3b** | **Partner enforcement** (enabled only after R3a and M-6): §4.5 evaluator for all 90 endpoints, property/unit scope, query-level filtering and aggregates over S, field-level redaction and masking, NR-1/NR-2 removal, B9 field-diff, `GET /api/partner/me/access`, menu filtering, conversation authorization through `booking.hotel` and PA-4 re-pointing | — | yes (§29 release notes) | B12 negative matrix green for every endpoint family; cross-company, cross-property and resource-type-404 tests; NR tests |
| **R4** | Invitations and team lifecycle: invite/resend/revoke/expire, accept/decline under `/api/me`, pending invitations for the caller, MANAGER team management (Q3), `POST /team` alias; requires a production email provider; ships with the R5 team-management UI slice | M-3 | yes | enumeration tests (IN-1, IN-3); token rotation and single-use tests; WS-3 conflict tests; 503-before-create and failed-send-stays-pending tests |
| **R5** | Frontend: access document, permission-based menu/actions/property switcher with parent context, redaction rendering, team management with scopes, invitation acceptance page and pending-invitation onboarding, step-up dialog, Phase C/D per-section handling (F12), retire `teamMemberUnsupported` | — | yes (UI) | widget tests per role; no client role-name checks remain |
| **R6** | Admin profiles: 11 profiles incl. `GROWTH_MARKETING`, PLATFORM_OWNER backfill, per-handler admin enforcement incl. the A15/A46 value-dependent mapping, admin masking without A05, read-access audit (A06, A28), `GET /api/admin/me/access`, access management endpoints, admin step-up, dual control for A16 and A11 | M-5 | none until profiles are narrowed | `AdminAuditInfrastructureTest` deliberately extended; last-platform-owner test; read-audit tests |
| **R7** | Hardening: user-side 403→404 (G13), unmapped route → 404 (G17), raw role-string checks removed (B6), `/api/partner/**` → `PARTNER` only (Q13), dual-control thresholds for A31, A39, A41, A42 | — | yes (announced) | regression suites green |
| **R8** | Reserved capabilities as their domains ship: publish (P20), media (P19), room create (P22), booking modify (P41), housekeeping (P46–P47), ownership transfer (P13), owner recovery (A11), account management (A07), payouts (A12, incl. the 72-hour hold), security settings (P06), policies split (Q7), custom roles | as needed | per feature | per feature |

Note: R6 does not depend on R3–R5 and may run in parallel with them; narrowing admin power reduces live risk
sooner.

---

## Appendix A — Evidence index (files inspected)

**Backend (`Plan-Your-Trip-backend-v1`)**: `ROLE_UI_PERMISSION_FREEZE.md`, `ACCOUNT_LIFECYCLE.md`,
`CLAUDE_backend.md`; `be/config/SecurityConfig.java`, `AuthUserResolver.java`, `DataInitializer.java` (seed
users, team seed), `ProductionBootstrap.java` (admin bootstrap); `be/security/JwtService.java`,
`JwtAuthenticationFilter.java`, `UserPrincipal.java`, `AuthUser.java`; `be/model/AccountRole.java`, `User.java`,
`PartnerProfile.java`, `PartnerTeamRole.java`, `PartnerTeamMember.java`, `PartnerVerificationStatus.java`,
`PartnerSettings.java`, `PartnerPayoutAccount.java`, `PartnerActivityLog.java`, `AdminActivityLog.java`,
`Place.java`, `PlaceStatus.java`, `HotelRoom.java`, `Booking.java`, `Promotion.java`, `PromotionTargetType.java`,
`Conversation.java`, `AuthTokenPurpose.java`; `be/repository/PartnerTeamMemberRepository.java`,
`PlaceRepository.java`, `ConversationRepository.java`; `be/service/PartnerSettingsService.java`,
`PartnerProfileService.java`, `PartnerActivityLogService.java`, `AdminActivityLogService.java`,
`PartnerExtranetService.java`, `PartnerPropertyService.java`, `PartnerRoomService.java`, `HotelRoomService.java`,
`PartnerPricingService.java`, `PartnerCalendarService.java`, `PartnerPromotionService.java`,
`PartnerBookingService.java`, `PartnerCheckInService.java`, `PartnerCheckOutService.java`,
`PartnerVoucherVerificationService.java`, `PartnerFinanceService.java`, `PartnerAnalyticsService.java`,
`ConversationService.java`, `ReviewService.java`, `BookingService.java` (incl. `adminUpdateStatus`),
`InvoiceService.java`, `InventoryReservationService.java`, `PaymentService.java`, `PaymentGatewayService.java`,
`AuthService.java`, `AccountService.java`, `TripCollaborationService.java`, `be/service/mail/EmailSender.java`,
`UnconfiguredEmailSender.java`, `DevelopmentLogEmailSender.java`; all 15 `Partner*` and 38 `Admin*` controllers
(endpoint inventory, incl. the `hotelId` parameters of `PartnerAnalyticsController` and
`PartnerFinanceController`) and `BookingController` (voucher endpoint); `be/dto/PartnerBookingDto.java`,
`PaymentDto.java`, `BookingDto.java`, `BookingVoucherDto.java`, `GiftCardDto.java`, `PartnerGuestStayDto.java`,
`HotelRoomDto.java`, `RoomInventoryDto.java`, `PartnerCalendarDto.java`, `AdminAnalyticsDto.java`;
`be/exception/ApiException.java`, `GlobalExceptionHandler.java`; `be-db/V1__initial_schema.sql`,
`V2__admin_activity_log.sql`, `V3__account_lifecycle.sql`; `src/main/resources/application.properties`,
`application-prod.properties`; `be-test/PartnerSettingsTest.java`, `PartnerPropertyCrudTest.java` (test names),
`FlywayMigrationConfigTest.java`, `SqlServerProdChainVerificationTest.java` (headers), test inventory (107 test
classes).

**Frontend (`Plan-Your-Trip-integration/frontend`)**: `docs/APP_SURFACES.md`, `docs/PARTNER_PROPERTY_ONBOARDING.md`;
`fe/core/app_role.dart`; `fe/app/app_surface.dart`, `surface_gate.dart`; `fe/core/admin/admin_state.dart`;
`fe/features/admin/admin_routes.dart`; `fe/core/partner/partner_models.dart`, `partner_account_models.dart`,
`partner_state.dart`; `fe/features/partner/partner_navigation.dart`, `partner_module_screen.dart`,
`properties/partner_properties_screen.dart`, `rooms/partner_rooms_screen.dart`,
`rates/partner_rates_screen.dart`, `inventory/partner_inventory_screen.dart`,
`promotions/partner_promotions_screen.dart`, `policies/partner_policies_state.dart`,
`settings/partner_settings_screen.dart`, `settings/partner_account_state.dart`;
`fe/core/network/api_client.dart` (team/payout calls).

---

## Appendix B — Review findings resolution index (revision 1.1)

| Review finding | Resolution | Where |
|---|---|---|
| C1 / F4 — evaluator had no collection/company semantics; 403 leaked existence via unrelated view permissions | Normative evaluator with RESOURCE / COLLECTION / COMPANY / SELF kinds, `E(p)` with floors, never-upward `covers`, resource-type view permissions for 403 vs 404 | §4.5, §11.2, §11.4, §26 E5–E8, I5, I22 |
| E1 — UNIT-scoped housekeeping could not enter the workspace | P01 floor `U`; parent-context read rule | §9.1 P01, §11.7, §12.1 |
| C2 — PARTNER_OPERATIONS held verify + owner assign | A16 `PLATFORM_OWNER` only until dual control; PARTNER_OPERATIONS = 9 | §7, §9.2, §10.2, §22.6 |
| E2 — ANALYTICS read individual reviews | A34 removed from ANALYTICS; review analytics overview mapped to A04 | §9.2, §10.2, §21.4 |
| C5 / E4 / E5 — payment link, raw errors, traveller fields; no bearer class | Never-to-partner set; free-text classification under P40; bearer instruments and NR-1…NR-7 | §9.1 P36/P40, §21.1, §21.3, I23 |
| E3 — "operational roles see no money" was false | Reworded: no aggregates, statements, payout or payment records unless granted; per-booking `finalPrice` is operational | §10.4, §20 FI-1, I11 |
| C4 / D2 — member could create a second company; draft-profile conflict undefined | WS-1…WS-6, 409 `WORKSPACE_CONFLICT` with reasons, I21 | §11.6, §14, §26 E16, §27 |
| D1 — traveller-email dead end | Generic accept-page guidance, `PARTNER_ACCOUNT_REQUIRED`, accept/decline under `/api/me/**` | §14 AC-3/AC-5, §25.3 |
| D3 / D4 — no resend; send-after-commit vs 503 contradiction | Resend with rotation, cooldown, max 5, `TEAM_INVITATION_RESENT`; availability pre-check then post-commit send | §13.1–§13.3 |
| C6 — security notifications could be disabled | Mandatory class outside `PartnerSettings`, to every owner | §18 O-8, §20 FI-6, §24 B16, I25 |
| D10 — fresh session needed a token issue time | Freshness from `exp − lifetime` (15 min) + `POST /api/me/step-up`; no JWT change | §18 O-7, §25.6, §26 E13 |
| D9 / D6 — no data audit; audit lacked actor snapshot | M-0 audit, M-6 remediation; M-4 adds `actor_email`, append-only | §28, §22.1 |
| D7 — property move vs `conversations.partner_profile_id` | Authorization through `booking.hotel`; re-point on move; history preserved | §11.2, §16 PA-4, I16 |
| C3 — protections arrived after enforcement | R3 split into R3a (protections, M-6) and R3b (enforcement); legacy co-owners as MANAGER pending confirmation; I24 | §18 O-9, §28, §32 |
| D5 — compatibility overstated | Explicit list of legacy team endpoint changes and other announced changes | §29 |
| D14 / F2 — access endpoint authorization undefined | SELF kind, not P01; 200 for suspended members; effective permissions after floors | §25.2 |
| F5 — promotion HOTEL target | `hotel_details.id` → place | §2.4, §11.2 |
| F7 — aggregates unmarked | Every aggregate marked FILTERABLE BY PROPERTY or COMPANY ONLY; finance rows added | §25.1 |
| D11 — A15 combined publish with take-down | A15 moderate (non-public states, verified) vs new A46 publish (PUBLISHED, featured) | §9.2, §10.2, §10.4 |
| D12 / E7 — admin sensitive reads unaudited; no dual control | Read audit for A06/A28; dual-control principle and thresholds for A16, A11, A31, A39, A41, A42 | §22.5, §22.6 |
| Q11 / D13 — finance overload | `GROWTH_MARKETING` profile; customer coupon revoke moved to A41 | §7, §9.2, §10.2 |
| D16 — scoped manager learned about other members | Uniform 202 when the existing member is outside the actor's scope | §13.3 IN-3 |
| D15 — admin narrowing could start earlier | Noted: R6 may run in parallel with R3–R5 | §32 note |
| E8 — location change after publication | Deferred to the P20 publication phase | §30 |
| E9 — FRONT_DESK lacks promotion view (optional) | Deliberately unchanged; FRONT_DESK quotes from rate view | §10.1 |
| E10 — system jobs reach real users | Stated in the permission description | §9.2 A45 |
| Q1–Q20 | Locked V1 decisions | §31 |
