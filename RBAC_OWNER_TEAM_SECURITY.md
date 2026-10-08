# RBAC R3a — owner and team security

The protections that must be live before any partner member gains new power (RBAC V1.1 §10.3, §15, §17–§19,
§22, §25.3, §25.6, §26, §28 M-6, §29, §32). Builds on R1 (`security/rbac`, `PartnerAccessService`) and R2
(`RBAC_MEMBERSHIP_FOUNDATION.md`). Design: `frontend/docs/security/PLAN_YOUR_TRIP_RBAC_PERMISSION_MATRIX_V1.md`.

> R3b (`RBAC_PARTNER_ENFORCEMENT.md`) activates the V1.1 matrix: operational endpoints are now decided by stored
> grants and the §10.1 bundles; the legacy-bundle notes below describe R3a only.
>
> R4 (`RBAC_TEAM_ADMINISTRATION.md`) activates MANAGER's team permissions within §10.3, adds invitations, and turns
> legacy `POST /api/partner/team` into an alias of `POST /api/partner/team/invitations` (202, no direct attachment,
> no `MEMBER_NOT_ADDABLE`). A removed member re-joins through a new membership (V8).

**Still not activated (in R3a):** the V1.1 permission matrix (R3b). Every operational endpoint is still decided with the
R1 legacy bundles: the registrant holds everything; members keep today's settings/payout/team rights. Team
mutations are owner-only until R4 (§31 Q3).

## 1. Owners

| Rule | Implementation |
|---|---|
| O-1 primary owner immutable | the registrant's row cannot be suspended, re-granted, removed or left — 403 `OWNER_PROTECTED`; the registrant themself gets 403 `SELF_MODIFICATION_FORBIDDEN` / `OWNER_PROTECTED` (leave) |
| O-2 only owners manage owners | adding, confirming, revoking, suspending, reactivating or removing an owner needs `team.owner.manage` (P12) — 403 `OWNER_PROTECTED` |
| O-3 owner is company-only | `ck_partner_member_grants_role_scope` (V5) and `PartnerRoleScopes` — 422 `SCOPE_INVALID` |
| O-4 non-owners never touch owners | §10.3 authority check — 403 `OWNER_PROTECTED` |
| O-7 step-up | owner changes (P12) and the payout-account change (P53) need a session issued within 15 minutes — 403 `STEP_UP_REQUIRED`; `POST /api/me/step-up {currentPassword}` returns a fresh token |
| O-8 mandatory notifications | `PartnerSecurityNotifier` — every active owner and the member, in-app, in the mutating transaction; not governed by `PartnerSettings` |
| O-9 legacy co-owners | V7 (M-6 d): `MANAGER@COMPANY` with `pending_owner_confirmation = 1`; the primary owner confirms by granting `OWNER@COMPANY` (P12, step-up, `OWNER_GRANTED`) |

A *confirmed owner* is the registrant, or an ACTIVE member holding `OWNER@COMPANY` who is not pending
confirmation. A pending co-owner holds MANAGER's legacy rights only.

## 2. Last owner (§19)

A company keeps at least one owner that is ACTIVE, confirmed and whose account is enabled (the registrant counts
while their account is enabled). Revoking OWNER, suspending or removing an owner, and an owner leaving are refused
with **409 `LAST_OWNER_REQUIRED`** when they would leave none.

**Concurrency (LO-3).** Every team mutation first takes `SELECT … FOR UPDATE` on the company row
(`PartnerProfileRepository.findByIdForUpdate`), then re-reads the target membership, then counts owners — all in
one transaction. Two concurrent departures of the last two owners serialize; the second sees the first and is
refused (`RbacOwnerTeamSecurityTest.concurrentLastOwnerDeparturesCannotBothSucceed`).

## 3. Team mutations

| Endpoint | Permission | Notes |
|---|---|---|
| `GET /api/partner/team` | P07 | not-revoked members; adds `status`, `grants[{role, scope}]`, `primaryOwner`, `pendingOwnerConfirmation`, `isSelf`, `version` |
| `POST /api/partner/team` (legacy) | P08 (+P12, step-up for OWNER) | attaches an existing **PARTNER** account only; no USER→PARTNER promotion; unknown, traveller, admin, disabled, removed and conflicting accounts all get 422 `MEMBER_NOT_ADDABLE`; an existing member 409 `ALREADY_MEMBER` |
| `PATCH /api/partner/team/{id}` (legacy) | P09 role / P10 active | same rules as below; a role change replaces the company grant and keeps scoped grants |
| `PUT /api/partner/team/{id}/grants` | P09 (+P12, step-up) | `{grants:[{role, scope:"TYPE:id"}], reason?, version}`; empty list 400; stale version 409 `CONCURRENT_MODIFICATION` |
| `POST /api/partner/team/{id}/suspend` | P10 | `{reason?}`; grants kept; access ends on the next request |
| `POST /api/partner/team/{id}/reactivate` | P10 | same grants; WS-1 re-checked (409 `WORKSPACE_CONFLICT`) |
| `DELETE /api/partner/team/{id}` | P11 | **soft revoke**: `REVOKED`, grants removed, row kept; never revived (RV-2) |
| `POST /api/partner/team/leave` | SELF | the caller's own membership (also when suspended); not the primary owner, not the last owner |

Order of checks (`PartnerTeamService.apply`): permission → company lock → target in the company and not revoked
(404) → not self (403 `SELF_MODIFICATION_FORBIDDEN`) → not the primary owner (403 `OWNER_PROTECTED`) → §10.3
authority over current and new grants (403 `OWNER_PROTECTED` / `ROLE_NOT_DELEGABLE`) → every grant valid inside
the company (422 `SCOPE_INVALID`) → P12 and step-up when an owner is involved → version → WS-1 on reactivation →
last owner → apply, audit, notify. A change that changes nothing writes nothing.

**No escalation through scope.** A member's legacy rights come from the roles they hold at **company** scope
(their stored grants), not from the `role` column (which shows the highest grant). A `MANAGER@PROPERTY` grant,
and any grant of REVENUE, RESERVATIONS, CONTENT or HOUSEKEEPING, carries nothing until R3b.

**Delegation (I6).** In R3a only owners hold team permissions, and an owner holds every permission at company
scope, so every grant they make is covered. The §10.3 table is enforced regardless (MANAGER/FINANCE/OWNER
targets need an owner), ready for MANAGER's team permissions in R4.

## 4. Audit (§22)

`PartnerActivityLogService.audit` is the strict writer: same transaction as the mutation, fails closed, actor id
and **email snapshot**, before/after scalars such as `CONTENT@PROPERTY:123,MANAGER@COMPANY:456|ACTIVE`, reason,
and the admin trail's credential guard. The repository exposes only `save` and reads (AU-3).

Events: `TEAM_MEMBER_ADDED`, `TEAM_MEMBER_ROLE_CHANGED`, `OWNER_GRANTED`, `OWNER_REVOKED`,
`TEAM_MEMBER_SUSPENDED`, `TEAM_MEMBER_REACTIVATED`, `TEAM_MEMBER_REMOVED`, `TEAM_MEMBER_LEFT`,
`PAYOUT_ACCOUNT_UPDATED` (masked `none → ****6677`), and `MEMBERSHIP_REMEDIATED` (V7, actor `SYSTEM`).
Refused mutations are logged at WARN with ids only (§22.4). Admin step-up writes `ADMIN_STEP_UP` /
`ADMIN_STEP_UP_FAILED` to the admin trail (116 admin actions now).

## 5. Step-up (§25.6)

`POST /api/me/step-up {currentPassword}` → `200 {token, user}`; the previous token stays valid. Wrong password →
400 `CURRENT_PASSWORD_INCORRECT` (`fieldErrors: currentPassword`); more than 5 attempts per account in 15 minutes →
429 `STEP_UP_RATE_LIMITED`. Freshness is `now − (exp − app.jwt.expiration-ms) ≤ 15 min`; the JWT format is
unchanged (`JwtService`, `TokenSession`, `StepUpPolicy`). The attempt window is in memory — correct for the
single-instance deployment; a scaled-out deployment needs a shared store.

## 6. Migration V7 — M-6 remediation

Run the read-only M-0 audit (`db/audit/R2_M0_partner_membership_audit.sql`) again before shipping and keep the
signed-off report. V7, for memberships other than the registrant's own and not already revoked:

| Finding | Change | Reason |
|---|---|---|
| (a) ADMIN account | `REVOKED`, grants removed | `ADMIN_ACCOUNT` |
| (f) account not PARTNER | ACTIVE → `SUSPENDED` | `ACCOUNT_ROLE` |
| (b) own company + active elsewhere | ACTIVE → `SUSPENDED` | `WS1_CONFLICT` |
| (c) active in more than one company | every one ACTIVE → `SUSPENDED` | `WS1_CONFLICT` |
| (d) legacy co-owner | `OWNER` → `MANAGER@COMPANY`, `pending_owner_confirmation = 1`, status unchanged | `LEGACY_CO_OWNER` |

Each change writes `MEMBERSHIP_REMEDIATED` (actor `SYSTEM`, before/after) and a notification to the primary owner
and the member. `partner_activity_logs.actor_user_id` becomes nullable for these rows (FK kept). Reduction only
(I24). Every statement is its own batch.

**Verification:** run on a disposable SQL Server 2019 LocalDB database over seeded legacy data (V1, V2, a
batch-split copy of V3 — see `RBAC_MEMBERSHIP_FOUNDATION.md` §7 — then V4–V7): every finding was remediated as in
the table, 12 notifications and 6 audit rows were written, the M-0 audit afterwards shows no B, C or D, and the
R2 constraint probes still behave. Not run: Flyway + Hibernate `validate` against SQL Server
(`SqlServerProdChainVerificationTest`, extended for V7) — it needs a TCP-reachable SQL Server.

## 7. Behaviour changes (§29)

- Legacy team add: no promotion; only PARTNER accounts; uniform 422 for everything else; 409 `ALREADY_MEMBER`.
- Legacy delete: soft revoke; a removed member cannot be re-added until R4 invitations (the unique
  `(company, user)` key will then need to admit a new membership next to a revoked one).
- Owner changes and payout-account changes need a fresh session.
- Legacy co-owners lose team management until the primary owner confirms them (after V7).
- Every owner (not only the registrant) receives payout-account and team security notifications.

## 8. Not in R3a

The V1.1 matrix on operational endpoints (R3b), invitations (R4), MANAGER team management (R4), ownership
transfer (R8), security settings (reserved P06), team-management UI, property assignment UI, admin profiles (R6),
dual control, physical rooms.
