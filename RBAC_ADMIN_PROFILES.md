# RBAC R6 — admin profiles

R6 narrows the admin console from "every `ADMIN` can do everything" to the 11 admin profiles of RBAC V1.1. It covers:
- §7 (profiles and the rules AP-1…AP-6);
- §9.2 and §10.2 (the admin permission catalogue and the profile bundles);
- §21.4 (admin masking);
- §22.3–§22.6 (audit, denial logging, read-access audit, dual control for A16 — §6);
- §25.4–§25.5 (access endpoints, value-dependent mapping);
- §26 (error codes);
- §28 M-5 (schema and backfill) and the §12.4 dual-control table (V10).

The design document is `frontend/docs/security/PLAN_YOUR_TRIP_RBAC_PERMISSION_MATRIX_V1.md`; it stays the source of truth and is not edited by R6. R6 builds on the R1 kernel (`AdminPermission`, `AdminEndpointRules`, `EndpointAuthorizationInterceptor`). Related: `RBAC_PARTNER_ENFORCEMENT.md` (R1/R3b), `RBAC_TEAM_ADMINISTRATION.md` (R4).

**Release prerequisite.** `V9__admin_profile_assignments` and `V10__admin_dual_control_requests` passed the gated `SqlServerProdChainVerificationTest` on disposable SQL Server 2022 databases only (`DEPLOYMENT.md` §20). The Compose stack, staging and production were not exercised.

## 1. Model

| Rule | Implementation |
|---|---|
| A system `ADMIN` is not an admin permission | `AdminAccessService` returns the union of the caller's **active** profile bundles. `ROLE_ADMIN` without a profile holds nothing: every `/api/admin/**` handler, including `GET /me/access`, answers 403 `PERMISSION_DENIED`. |
| Deny by default | No profile, an unknown profile name or a non-admin principal → empty permission set. `AdminProfile.fromName` accepts the 11 exact names only. A reserved key (A07, A11, A12) maps to no handler and grants nothing. |
| Bundles | `AdminProfile` transcribes §10.2: PO 46, PT 9, CC 10, BS 11, FO 14, GM 8, TS 14, RM 4, AN 2, LC 3, TE 6. A02, A16 and A44 are held by `PLATFORM_OWNER` only. No new role or profile was added. |
| Per handler | The 189 admin handlers (181 + 3 access + 5 dual-control endpoints of R6) each name their permission in `AdminEndpointRules`. An unregistered handler is refused (fail closed). |
| Value-dependent (§25.5) | `PATCH /places/{id}/status`: `PUBLISHED` needs A46 `admin.place.publish`; every other status needs A15 `admin.place.moderate` (`AdminPlaceController`). |
| Effect | Profiles are read from the database on every request; a grant or revoke applies to the target's next request (AP-3). Tokens carry no profiles. |

## 2. Endpoints (§25.4)

| Endpoint | Permission | Notes |
|---|---|---|
| `GET /api/admin/me/access` | A01 | The caller's profiles, active permission keys (reserved keys omitted) and `stepUp.freshUntil`. 403 when the caller holds no profile. |
| `GET /api/admin/access/admins` | A02 | Every `ADMIN` account with its active profiles; `self` marks the caller. |
| `PUT /api/admin/access/admins/{userId}/profiles` | A02 + step-up | Replaces the target's profile set. Body: `{"profiles": [...], "reason": "..."}` (≤ 11 profiles, reason ≤ 500 and credential-free). |

`PUT …/profiles` checks, in order:
1. body validity (unknown or duplicate profile, credential-looking reason → 400 `VALIDATION_FAILED`);
2. self (→ 403 `SELF_MODIFICATION_FORBIDDEN`, AP-1);
3. target is an `ADMIN` (otherwise 404, the same answer as a missing id);
4. under a pessimistic lock on every active `PLATFORM_OWNER` row of enabled admins, the caller must still be one (→ 403 `PERMISSION_DENIED`), and at least one must remain afterwards (→ 409 `LAST_PLATFORM_OWNER_REQUIRED`, AP-2).

The lock makes two owners who revoke each other at the same moment serialize: one wins, the other is refused because they are no longer an owner. Rule 4's 409 is defensive — with AP-1 and the self rule the caller always remains an owner — and is kept so a future path cannot remove the last one.

Revoked rows are kept as history (`revoked_at`, `revoked_by`).

## 3. Masking (§21.4, AP-6)

Admin booking detail and every admin booking write that returns a `BookingResponse` mask guest identity unless the caller holds A05 `admin.customer.view`: `userFullName` becomes initials, `userEmail` is omitted, and `redacted` lists both (`MASKED`, `OMITTED`). A05 holders receive `redacted: null`. The admin booking list and admin payment responses carry no guest identity.

The admin booking list's `guest` filter is a substring match on the guest's name and email. Its rows and `totalElements` would answer "does this guest's identity contain X?", and repeated probes would rebuild the masked identity. A non-blank `guest` therefore needs A05 too (I12, §21.4): without it the request is refused with 403 `PERMISSION_DENIED` before any query runs, with the same body whether or not anything would match, and the value is never echoed. A blank `guest` is no filter, and the list without it is unchanged for every A24 holder. The console never sends `guest`.

## 4. Audit and logging (§22.3–§22.5)

| Event | Action | Content |
|---|---|---|
| Profile granted | `ADMIN_PROFILE_GRANT` | target user, profile in `afterState`, optional reason |
| Profile revoked | `ADMIN_PROFILE_REVOKE` | target user, profile in `beforeState`, optional reason |
| Travel wallet read | `TRAVEL_WALLET_VIEW` | target user id only |
| Conversation list or detail read | `CONVERSATION_VIEW` | conversation id (detail) or whitelisted filters (`status`, `userId`, `partnerProfileId`, `bookingId`; validated values only) |

Read-access rows are written by the interceptor **before** the read runs; if the audit write fails, the read fails (fail closed). Free-text query parameters are never recorded. A refused admin request is logged at WARN with the user id, the permission keys and the route, at most once a minute per user and route; denials are not audit rows. No token, password or request body is logged.

## 5. Step-up (§25.6)

Rules flagged `stepUp` require a session issued within 15 minutes (`StepUpPolicy`), otherwise 403 `STEP_UP_REQUIRED`. The check runs after the permission check. Clients re-authenticate through the existing `POST /api/me/step-up`, whose admin outcomes were already audited (`ADMIN_STEP_UP`, `ADMIN_STEP_UP_FAILED`) since R3a. Flagged in R6: `PUT /access/admins/{userId}/profiles` (new), `POST /hotels/{hotelId}/assign-owner` (A16 submission; the flag already existed in the registry but was not enforced before R6) and `POST /dual-control/requests/{id}/approve` (new). So the requester's session is fresh when they submit and the approver's when they approve; freshness comes from the token's issue time, never from the client.

## 6. Dual control for A16 (§22.6, AP-5)

Moving a property to another company (A16 `admin.place.owner.assign`) now takes two platform owners. A11 `admin.partner.ownership.intervene` stays reserved until its endpoint ships in R8 (§31 Q18). The threshold actions A31, A39, A41 and A42 stay single-actor until R7.

**Endpoints.** Every one needs A16, which only `PLATFORM_OWNER` holds, so any other administrator (and any partner) gets 403 and cannot even read the queue.

| Endpoint | Who | Result |
|---|---|---|
| `POST /api/admin/hotels/{hotelId}/assign-owner` `{partnerProfileId, reason?}` | requester, fresh session | **202** with the pending request (id, status, `expiresAt`). Nothing moves. 404 unknown hotel or company, 422 unapproved company, 409 `DUAL_CONTROL_PENDING_EXISTS`. |
| `GET /api/admin/dual-control/requests?status=&page=&size=&sort=` | any A16 holder | the queue, newest first; `sort` is `requestedAt` or `expiresAt` |
| `GET /api/admin/dual-control/requests/{id}` | any A16 holder | the request, with its immutable proposal (place, expected current owner, proposed owner) |
| `POST …/{id}/approve` (body ignored) | a different A16 holder, fresh session | 200 `{request, result}`; the move runs in this transaction |
| `POST …/{id}/reject` `{reason}` | a different A16 holder | 200, `REJECTED` |
| `POST …/{id}/cancel` | the requester only | 200, `CANCELLED` |

**States.** `PENDING` → `APPROVED` | `REJECTED` | `CANCELLED` | `EXPIRED` | `STALE`. All five are terminal: a closed request is never reopened or executed (409 `DUAL_CONTROL_NOT_PENDING`).

**Rules.**
1. **Self.** Nobody approves or rejects their own request: 403 `SELF_APPROVAL_FORBIDDEN`. The requester can only cancel it; nobody else can (403 `PERMISSION_DENIED`).
2. **Validity.** A request is valid for 24 hours. Reads show an overdue request as `EXPIRED` and never write (the partner-invitation lazy-expiry pattern). The next approve, reject, cancel or new submission for the same place persists `EXPIRED` with `DUAL_CONTROL_EXPIRE` (system actor) and commits that before answering 409 `DUAL_CONTROL_EXPIRED`. An expired request therefore never blocks a new one.
3. **Execution-time checks.** The approval locks the request row, then the place row, then every active A16 holder's assignment row (the locks profile changes take). Under those locks:
   - the approver must still be an enabled A16 holder (403 otherwise; nothing changes);
   - the requester must still be one (`REQUESTER_NOT_ELIGIBLE`);
   - the payload must match its digest (`PAYLOAD_DIGEST_MISMATCH`);
   - the place must exist with the owner the requester saw (`PLACE_MISSING`, `OWNER_CHANGED`);
   - the proposed company must exist and be approved (`PROPOSED_OWNER_MISSING`, `PROPOSED_OWNER_NOT_APPROVED`).

   Any failed check except the approver's persists `STALE`, the reason and `DUAL_CONTROL_STALE`, commits, then answers 409 `DUAL_CONTROL_STALE`.
4. **Immutable proposal.** The payload is written once (every proposal column is `updatable = false`). The approval executes it from the stored row, never from the approver's request body. The digest is a consistency check, not the protection.
5. **Atomicity.** The move (with §16 PA-4), `HOTEL_ASSIGN_OWNER`, the owner's notification, the `APPROVED` state and `DUAL_CONTROL_APPROVE` commit together. If any part fails, all of it rolls back and the request stays `PENDING`.
6. **One open request** per action and place, by the live unique key. Two racing submissions give one 202 and one 409 `DUAL_CONTROL_PENDING_EXISTS`.
7. **Concurrency.** Competing decisions serialize on the request row lock. Locks are always taken in the order request, place, holders (in id order), and profile changes take only the holders' locks, so no cycle can form.

**Audit** (`target_type` `DUAL_CONTROL_REQUEST`, before/after = state; ids only, no tokens or contact data):

| Action | Actor | When |
|---|---|---|
| `DUAL_CONTROL_REQUEST` | requester | submitted |
| `DUAL_CONTROL_APPROVE` | approver | approved and executed (with `HOTEL_ASSIGN_OWNER`, actor = approver) |
| `DUAL_CONTROL_REJECT` | rejecter | rejected; the description carries the reason |
| `DUAL_CONTROL_CANCEL` | requester | cancelled |
| `DUAL_CONTROL_EXPIRE` | system (no actor) | expiry persisted |
| `DUAL_CONTROL_STALE` | the approver who found it | stale persisted; the description carries the machine reason |

**Operational consequence.** A16 needs **at least two enabled platform owners**. With one, a request can be submitted but never approved, and it expires. There is no break-glass path. AP-2 only guarantees one platform owner, so keep a second before relying on A16.

**Console.** The admin console has no assign-owner or approval screen (the D3B catalogue freeze kept assign-owner out of scope), so dual control is API-only in R6. A queue screen is a later product decision.

## 7. Schema (M-5 `V9__admin_profile_assignments`, `V10__admin_dual_control_requests`)

`admin_profile_assignments`: `user_id`, `profile`, `granted_by`, `granted_at`, `revoked_at`, `revoked_by`, `revocation_key`, `version`.
- `ck_admin_profile_assignments_profile` — exactly the 11 profile names.
- `ck_admin_profile_assignments_revocation` — active rows have `revocation_key = 0`, revoked rows a positive key (the row id).
- `uk_admin_profile_assignments_live (user_id, profile, revocation_key)` — at most one active row per profile, while history accumulates. This is V8's live-key pattern; a filtered index is avoided for H2/SQL Server parity.
- Foreign keys to `users` for the holder, granter and revoker; index `(profile, revocation_key)`.
- **Backfill (AP-4):** every existing `ADMIN` (enabled or not) receives `PLATFORM_OWNER` as a system grant (`granted_by` null). Nothing changes for today's administrators until a platform owner narrows them.

`admin_dual_control_requests` (V10, §12.4 sketch plus what the workflow needs): `permission`, `target_type`, `target_id`, `payload`, `payload_digest`, `amount`, `currency` (reserved for R7; null for A16), `requested_by`, `requested_at`, `reason`, `status`, `expires_at`, `approved_by`, `approved_at`, `rejected_by`, `decided_at`, `decision_reason`, `live_key`, `version`.
- `ck_admin_dual_control_requests_permission` / `_target_type` — A16 / `PLACE` only (widened by a later migration).
- `ck_admin_dual_control_requests_status` — the six states.
- `ck_admin_dual_control_requests_live` — `PENDING` with `live_key = 0`, closed with a positive key.
- `ck_admin_dual_control_requests_decision` — a closed request has `decided_at`; an approved one an approver and time; a rejected one a rejecter.
- `uk_admin_dual_control_requests_live (permission, target_type, target_id, live_key)`; foreign keys for requester, approver and rejecter; index `(status, requested_at)`. V10 writes no row.

Every statement is its own `GO` batch. V1–V8 are unchanged; V9 is pinned by `RbacDualControlMigrationTest`. New administrators: `ProductionBootstrap` (prod) and `DataInitializer` (non-prod) grant `PLATFORM_OWNER` to the admin they create; an `ADMIN` created any other way holds nothing until granted.

## 8. Tests

- `RbacAdminProfilesTest` — bundles; deny by default; the per-profile probe table; union; A15/A46; masking; the `guest` filter is no identity oracle without A05; read audit; grant/revoke and next-request effect; PO-only management; self; validation; step-up for profile changes and for assign-owner; concurrent mutual revocation.
- `RbacAdminProfileMigrationTest` — V8 pinned; V9 is additive with its backfill; the SQL checks match the entity.
- `AdminDualControlTest` — submission needs A16, a fresh session and an active account; 202 moves nothing; one execution with its audits; no self-decision; other profiles and partners can neither decide nor read; stale step-up; a requester who lost A16 or was disabled; reject vs cancel; expiry persisted and audited; stale owner or company; the approver's body ignored and a tampered payload caught; duplicate and racing submissions; racing approvals; approval racing cancellation; a failed move rolls back the approval and its audits.
- `RbacDualControlMigrationTest` — V9 pinned; V10 additive, one statement per batch; the SQL checks match the entity.
- `SqlServerProdChainVerificationTest#rbacR6AdminProfileMigrationAppliedWithItsConstraints` / `#rbacR6DualControlMigrationAppliedWithItsConstraints` — gated; V9 and V10 history, checks, unique keys, foreign keys, every `ADMIN` a `PLATFORM_OWNER`.
- Test fixtures that need a property moved use `support/DualControlTestSupport` (submit, then approve as a second platform owner).
