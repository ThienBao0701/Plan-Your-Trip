# RBAC R4 — team administration, invitations and membership lifecycle

R4 completes partner team management. It covers the following parts of RBAC V1.1:
- §10.3 (delegation and authority);
- §13 and §14 (invitations);
- §15–§19 (role changes, the membership lifecycle, owner and last-owner protection);
- §22 (audit);
- §25.3 (endpoints);
- §28 M-3 (schema);
- §29 (compatibility);
- §31 Q3 and Q16 (managers manage the team; invitation limits).

It builds on R1–R3b. The design document is `frontend/docs/security/PLAN_YOUR_TRIP_RBAC_PERMISSION_MATRIX_V1.md`. Related documents:
- `RBAC_MEMBERSHIP_FOUNDATION.md`
- `RBAC_OWNER_TEAM_SECURITY.md`
- `RBAC_PARTNER_ENFORCEMENT.md`

**Release dependency (IN-5).** Production still uses `UnconfiguredEmailSender`. Until a real email provider ships, every invitation create and resend there answers **503 `EMAIL_DELIVERY_UNAVAILABLE`**, and nothing is created.

Verification so far was local only: H2, MockMvc, and the Flyway SQL Server parser for V8. V8 has not yet run against SQL Server. The environment-gated `SqlServerProdChainVerificationTest` gained the R4 checks, and must be run before release.

## 1. Who may manage whom (§10.3)

All team decisions go through the `PartnerTeamAuthority` component. It uses the R1/R3b kernel (`PartnerAuthorization`) and never a role-name shortcut. Team mutations (`PartnerTeamService`) and invitations (`PartnerInvitationService`) share it.

| Check | Rule | Refusal |
|---|---|---|
| Permission | The endpoint's team permission (P08 invite, P09 role, P10 suspend/reactivate, P11 remove) must be held somewhere in the workspace. MANAGER holds P07–P11 since R4. FINANCE, VIEWER and the operational roles hold none. | 403 `PERMISSION_DENIED` |
| Visibility | The caller's team view (P07) must cover **every** grant of the target membership or invitation. A company-wide view sees everyone. A property-scoped manager sees only members whose grants are all inside their properties, and never the primary owner. | 404, the same answer as a missing id |
| Self | Nobody modifies their own membership. Leaving is the only self-service action. | 403 `SELF_MODIFICATION_FORBIDDEN` |
| Primary owner | Immutable inside the workspace (O-1). | 403 `OWNER_PROTECTED` |
| Authority | Only an owner manages a membership or grant involving OWNER (including a co-owner pending confirmation), MANAGER or FINANCE. A membership is held at its highest role. | 403 `OWNER_PROTECTED` (owners) / `ROLE_NOT_DELEGABLE` (MANAGER, FINANCE) |
| Coverage | The action permission must cover every current grant of the target. | 403 `ROLE_NOT_DELEGABLE` |
| Scope validity | Every new grant must be legal for its scope type (§11.3: OWNER and FINANCE company-only; HOUSEKEEPING property or unit), and the scope must resolve inside the company from stored data. A client-supplied company, property or unit is never trusted. | 422 `SCOPE_INVALID` |
| Delegation (I6) | Every permission the new grant would carry at its scope type (role bundle cut by floors) must be held by the caller at a covering scope. So a `PROPERTY:1` manager cannot assign `COMPANY`, `PROPERTY:2`, or a unit of property 2. A reactivation re-checks the retained grants the same way. | 403 `ROLE_NOT_DELEGABLE` |
| Owner management | Adding, confirming, revoking, suspending, reactivating, removing or inviting an owner needs P12 (confirmed owners only) and a session issued within 15 minutes (O-7). | 403 `OWNER_PROTECTED` / `STEP_UP_REQUIRED` |
| Version | `PUT /team/{id}/grants` carries the version the client read. Every applied change bumps it. | 409 `CONCURRENT_MODIFICATION` |
| Workspace | Reactivation re-checks one workspace per account (WS-5). | 409 `WORKSPACE_CONFLICT` |
| Last owner | At least one ACTIVE, enabled, confirmed owner must remain. This is counted under the company row lock (LO-3). | 409 `LAST_OWNER_REQUIRED` |

**MANAGER, in summary:**
- A manager manages REVENUE, RESERVATIONS, FRONT_DESK, CONTENT, HOUSEKEEPING and VIEWER, within their own scope.
- A manager never manages OWNER, MANAGER or FINANCE. A legacy co-owner still pending confirmation (§18 O-9) holds MANAGER's rights and the same limits.
- **FINANCE** is company-wide but holds no team permission: it can neither list, invite nor change members (§10.4).

## 2. Invitations (§13, §14)

### Endpoints

| Method & path | Rule | Answer |
|---|---|---|
| `GET /api/partner/team/invitations` | COLLECTION (INVITATION) P07 | The invitations the caller's team view fully covers. Status is `PENDING`, `ACCEPTED`, `DECLINED`, `REVOKED` or `EXPIRED`; an expired pending invitation shows as `EXPIRED`. Also returns `deliveryStatus`, `resendCount`, `lastSentAt` and `expiresAt`. |
| `POST /api/partner/team/invitations` `{email, grants:[{role, scope}]}` | RESOURCE (INVITATION, body target) P08 covering every grant scope; P12 + step-up for OWNER | 202, uniform body `{status: "REQUESTED", message}` |
| `POST /api/partner/team/invitations/{id}/resend` | RESOURCE (INVITATION) P08 | 202, uniform body |
| `DELETE /api/partner/team/invitations/{id}` `{reason?}` | RESOURCE (INVITATION) P08 | 204 |
| `GET /api/me/partner-invitations` | `/api/me/**`; the service requires a PARTNER account, enabled and verified | The caller's own open invitations: company, role/scope summary, expiry |
| `POST /api/me/partner-invitations/accept` `{token}` | `/api/me/**`; checked in the service | 200, the caller's new access document (§25.2), `Cache-Control: no-store` |
| `POST /api/me/partner-invitations/decline` `{token}` | Any authenticated holder of the link (AC-1) | 204 |

The design table marks `POST /team/invitations` as COMPANY. Its normative step §13.1(1), "P08 for every grant scope", and §16 PA-3 let a property-scoped manager invite to their own property. The registry therefore records it like the promotion endpoint's body target: RESOURCE, authorized against the invited grants.

### Rules

**Create:** the following steps run in one transaction, under the company row lock:
1. Permission, authority and delegation (§1). Each grant must be valid inside the company (422).
2. The address is normalised like every account email.
3. If a live membership of that address is visible to the caller, the answer is 409 `ALREADY_MEMBER`.
4. If the existing membership, or a pending invitation to that address, is **not** visible to the caller, the answer is the uniform 202 and nothing is created (IN-3).
5. Limits: at most **20** pending, unexpired invitations per company, and **60 s** between two invitations to one address. Otherwise 429 `INVITATION_RATE_LIMITED`.
6. `EmailSender.isAvailable()` false gives **503 `EMAIL_DELIVERY_UNAVAILABLE`**, and nothing is written.
7. A pending invitation to the same address is superseded: it is closed as `REVOKED`, reason `SUPERSEDED` (or `EXPIRED` if it had expired), and audited.
8. The new invitation stores only the SHA-256 of a 32-byte `SecureRandom` token. It expires after **7 days** and its delivery status starts as `QUEUED`.
9. The strict audit row `TEAM_MEMBER_INVITED` is written, and every owner gets the mandatory notification.
10. **After commit**, `<partner app>/accept-invitation#token=…` is sent. The token is in the fragment, never in a query string.
    - Success: delivery `SENT`.
    - Failure: delivery `FAILED`. The invitation stays `PENDING` and can be resent; the client is not told the email went out.

**Resend:**
- The invitation must still be pending and unexpired, else 409 `INVITATION_NOT_PENDING`. An expired invitation is never resent; a new one is created instead.
- 60 s cooldown since the last send, and at most **5** resends (429). The 503 check comes before any change.
- The token is **rotated**: the previous link stops working at once. Expiry restarts at 7 days.
- Audited as `TEAM_INVITATION_RESENT`, with an owner notification.

**Revoke:**
- Needs authority over the invitation's grants.
- Only a `PENDING` invitation can be revoked.
- Audited as `TEAM_INVITATION_REVOKED` with the given reason, with an owner notification.

**Accept** (§14): one transaction, in this order:
1. **Token.** The token is looked up by hash. It must be pending and unexpired: 400 `INVITATION_INVALID` (unknown, used, revoked or superseded) or 400 `INVITATION_EXPIRED`.
2. **Account.** It must be a PARTNER account, enabled, with its email verified when verification applies. Otherwise 403 `PARTNER_ACCOUNT_REQUIRED`: travellers (`USER`) and admins are never promoted (AC-3, AC-4).
3. **Address.** The account email must equal the invited address, else 403 `INVITATION_ACCOUNT_MISMATCH`. The invited address is not echoed back.
4. **Lock and re-read.** The company row is locked and the invitation re-read. A concurrent acceptance, resend or revocation that already applied gives 400 `INVITATION_INVALID`.
5. **Workspace (WS-3).** An own company of **any** status, a live membership in this company, or an ACTIVE membership elsewhere gives 409 `WORKSPACE_CONFLICT`, with reason `OWN_PROFILE_EXISTS` or `MEMBERSHIP_EXISTS`. The invitation stays pending.
6. **Company.** The company must be `APPROVED`, else 409 `WORKSPACE_UNAVAILABLE`.
7. **Grants.** Every grant must still lie inside the company, and the inviter must still hold the authority and delegation they needed. Otherwise 409 `INVITATION_STALE`. This happens for example when the inviter was suspended or demoted, or a scope moved.
8. **Membership.** A **new** ACTIVE membership is created with exactly the invited grants (`PartnerMembershipService.createMembership`). The token is consumed.
9. **Audit and notification.** Audited as `TEAM_INVITATION_ACCEPTED`, plus `OWNER_GRANTED` for an owner invitation. Every owner and the new member get the mandatory notification.

**Decline** closes the invitation as `DECLINED`, audited as `TEAM_INVITATION_DECLINED`.

**Token hygiene:**
- The token never appears in a response, the database, the audit trail or a service log.
- The development sender (`DevelopmentLogEmailSender`, never active under `prod`) prints account links by design, Phase A's agreed local mechanism; that now includes invitation links.
- Audit text never contains the invited address. The strict writer's credential guard would otherwise refuse ordinary addresses, such as `secretary@…`.

**PA-4.** When an admin moves a property to another company, the previous company's pending invitations with a grant on the property, or on one of its room types, are revoked with reason `PROPERTY_MOVED`. This happens in the same transaction and is audited in that company's trail.

## 3. Membership lifecycle and re-adding a removed member

| State change | Effect |
|---|---|
| Suspend | `SUSPENDED`. Grants are kept; access ends on the next request. Audited as `TEAM_MEMBER_SUSPENDED`, with notification. |
| Reactivate | `ACTIVE` with the same grants, re-checked against §10.3, delegation and WS-1. Audited as `TEAM_MEMBER_REACTIVATED`, with notification. |
| Remove | **Soft revoke.** `REVOKED`, grants deleted, the row kept as history and hidden from the team list. Any later mutation of it is 404. Audited as `TEAM_MEMBER_REMOVED`, with notification. |
| Leave | Self-service only. Refused for the primary owner and the last qualifying owner. Audited as `TEAM_MEMBER_LEFT`, with notification. |

**Re-adding (RV-2): a revoked membership is never revived.** The person is invited again, and accepting creates a **new** membership row.

V8 makes this safe at the database level:
- `partner_team_members.revocation_key` is `0` while the membership is live, and the row's own `id` once it is revoked. `ck_partner_team_members_revocation_key` enforces this, and `PartnerTeamMember.changeStatus` sets it.
- V1's unique key `(partner_profile_id, user_id)` is replaced by `uk_partner_team_members_live`, unique over `(partner_profile_id, user_id, revocation_key)`.
- As a result there is at most one live membership per company and account, revoked rows stay as history, and a re-add is a new row with key 0.

This works identically on SQL Server and H2. A filtered index (`WHERE status <> 'REVOKED'`) does not exist in H2. A nullable key column would not work either: SQL Server treats NULLs in a unique constraint as equal.

`PartnerTeamMemberRepository.findByPartnerProfileIdAndUserId` now returns the **live** row only. `findByPartnerProfileIdAndUserIdOrderByIdAsc` returns every row, history included.

## 4. Audit and notifications

**Audit (§22).** Every security mutation writes one strict partner audit row in the mutating transaction (`PartnerActivityLogService.audit`). The row:
- fails closed: if it cannot be written, the change rolls back;
- is append-only;
- carries the actor id, an actor email snapshot, the target, before/after values such as `FRONT_DESK@PROPERTY:12|ACTIVE`, and the reason.

The R4 events are:
- `TEAM_MEMBER_INVITED`
- `TEAM_INVITATION_RESENT`
- `TEAM_INVITATION_REVOKED` (also used for supersession and PA-4)
- `TEAM_INVITATION_ACCEPTED`
- `TEAM_INVITATION_DECLINED`

The R3a events continue unchanged:
- `TEAM_MEMBER_ROLE_CHANGED`
- `OWNER_GRANTED`
- `OWNER_REVOKED`
- `TEAM_MEMBER_SUSPENDED`
- `TEAM_MEMBER_REACTIVATED`
- `TEAM_MEMBER_REMOVED`
- `TEAM_MEMBER_LEFT`

`TEAM_MEMBER_ADDED` is no longer written (§22.2).

**Notifications (§18 O-8).** Security notifications are mandatory and independent of `PartnerSettings`. They go to every ACTIVE owner and, where there is one, the affected member. The events are: invited, resent, revoked, accepted, role or grants changed, suspended, reactivated, removed, left. No notification carries a token.

## 5. Concurrency

Every invitation write and every team mutation follows the same order:
1. lock the company row (`findByIdForUpdate`);
2. re-read the target;
3. re-check owners, limits and status under the lock.

Grant replacement additionally uses the optimistic `version`. The post-commit delivery outcome is recorded with a conditional update keyed on the token hash, so it never conflicts with a concurrent resend.

The following races are covered by tests:
- double acceptance;
- invitations racing the 20-pending limit;
- concurrent resends;
- stale grant writes;
- duplicate or opposing suspend and reactivate;
- a removal racing a re-join;
- two co-owners removing each other.

## 6. Compatibility (§29)

| Legacy endpoint | R3a | R4 |
|---|---|---|
| `POST /api/partner/team` `{email, role, active}` | Attached an existing PARTNER account (201), or 422 `MEMBER_NOT_ADDABLE` | **Alias of `POST /team/invitations`** with `role@COMPANY:<company>`: 202 with the uniform body, the invitation lifecycle, no direct attachment. `active` is ignored. |
| `PATCH /api/partner/team/{id}` | Owner-only; the five legacy roles | Delegated (§1). Any role legal at company scope; HOUSEKEEPING@COMPANY gets 422 `SCOPE_INVALID`. |
| `PUT /team/{id}/grants`, suspend, reactivate, `DELETE /team/{id}` | Owner-only | Delegated (§1). Same codes. |
| `POST /team/leave` | Self | Unchanged |

Response shapes:
- `POST /api/partner/team` no longer returns a membership.
- Everything else is additive.

The frontend is unchanged in this phase. The design ships the R4 backend together with the R5 team-management UI slice.

## 7. Migration

`V8__partner_invitations` (§28 M-3) does the following:
- adds `revocation_key` and backfills revoked rows;
- swaps V1's unique key for `uk_partner_team_members_live`;
- adds `ck_partner_team_members_revocation_key`;
- creates `partner_invitations` and `partner_invitation_grants`, with named CHECKs mirroring the entities and member grants, unique keys on the token hash and on one pending invitation per company and address, foreign keys and indexes.

Every statement runs in its own `GO` batch. V1–V7 are untouched, and `RbacInvitationMigrationTest` pins V4–V7 by SHA-256.

Rollback: R3b code ignores the new column and tables. Re-creating V1's key fails once a member has been re-added.

## 8. Tests

**`RbacTeamInvitationTest`** covers:
- the lifecycle;
- limits and cooldowns;
- token rotation, single use, hash-only storage, and no leakage into responses, logs or the audit trail;
- 503 before create, and a failed send staying pending;
- no enumeration and no promotion;
- WS-3;
- stale and unavailable invitations;
- owner invitations and step-up;
- PA-4;
- audit fail-closed;
- the invitation races.

**`RbacTeamAdministrationTest`** covers:
- the §10.3 matrix for OWNER, MANAGER (company and property scope), FINANCE and VIEWER;
- self-modification;
- no widening from property to company, from property to another property, or from a unit to another property;
- cross-company 404;
- reactivation delegation;
- owner, last-owner and step-up protection;
- mandatory notifications;
- re-adding through a new membership;
- the database-enforced single live membership;
- leave;
- the team races.

**`RbacInvitationMigrationTest`** covers V8 statically. **`support/TeamMemberSeeder`** gives other suites a member exactly as acceptance creates it.
