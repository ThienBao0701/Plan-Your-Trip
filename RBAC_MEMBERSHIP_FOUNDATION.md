# RBAC R2 — membership and scope foundation

The persistent data the V1.1 permission matrix will be enforced on: membership states, scoped grants, and
the one-company-per-account rule. The design is
`frontend/docs/security/PLAN_YOUR_TRIP_RBAC_PERMISSION_MATRIX_V1.md` (rev 1.1, §11, §12.3, §28, §32); the
authorization kernel it feeds is R1 (`security/rbac`, `PartnerAccessService`).

> R3a (`RBAC_OWNER_TEAM_SECURITY.md`) supersedes the legacy team endpoint notes below: no USER→PARTNER
> promotion, soft revoke instead of delete, owner protection, step-up and member rights read from company grants.

**R2 changes nobody's rights.** Every request is still decided by the R1 kernel with the legacy bundles
(`LegacyPartnerBundles`): the registrant holds every partner permission over their own company, and a team
member keeps exactly today's settings, payout and team rights. The grants written in R2 mirror the legacy
roles and are read by no request path; the matrix enforcement phase (R3b) switches to them.

## 1. The model

```
users ──1:1── partner_profiles                     company = PartnerProfile, user_id = registrant
                   │
                   ├──< places.owner_partner_profile_id      property = Place, tenant = Place.owner
                   │        └──< hotel_details ──< hotel_rooms  unit = HotelRoom (a room type, Q9)
                   │
                   └──< partner_team_members               membership of one user in one company
                            │  role      primary role, kept for the legacy endpoints
                            │  status    ACTIVE | SUSPENDED | REVOKED   (active ⇔ status = ACTIVE)
                            │  status_reason, status_changed_at, status_changed_by
                            │  pending_owner_confirmation  (set by R3a only)
                            │  version   optimistic locking
                            │
                            └──< partner_member_grants      one role at one scope
                                     role, scope_type COMPANY | PROPERTY | UNIT, scope_id,
                                     property_id → places, unit_id → hotel_rooms,
                                     partner_profile_id = the membership's company
```

No company entity, no copy of ownership: a grant names a place or room type, and which company that belongs
to is read from `Place.owner` every time (`PartnerResourceTargetResolver`). `Place.ownerUser` is never an
authorization source.

### Scope storage

| scope_type | scope_id | property_id | unit_id |
|---|---|---|---|
| `COMPANY` | the membership's company id | — | — |
| `PROPERTY` | the place id | = scope_id | — |
| `UNIT` | the room type id | its place | = scope_id |

`scope_id` is never null. The design sketch (§12.3) leaves it null for `COMPANY`; storing the company id
instead keeps `uk_partner_member_grant (team_member_id, role, scope_type, scope_id)` identical on SQL Server
and H2, which treat nulls in unique constraints differently. "All properties" is the `COMPANY` scope, never a
fake property id (`scope_id > 0`).

### Roles and the scopes they may hold (§11.3)

| Role | COMPANY | PROPERTY | UNIT | Legacy capability in R2 |
|---|---|---|---|---|
| OWNER | ✓ | | | today's owner team/settings/payout rights |
| MANAGER | ✓ | ✓ | | settings edit |
| REVENUE | ✓ | ✓ | | none — stored only |
| RESERVATIONS | ✓ | ✓ | | none — stored only |
| FRONT_DESK | ✓ | ✓ | | reads only |
| FINANCE | ✓ | | | payout metadata |
| CONTENT | ✓ | ✓ | | none — stored only |
| HOUSEKEEPING | | ✓ | ✓ | none — stored only |
| VIEWER | ✓ | ✓ | | reads only |

`PartnerRoleScopes` holds this table for the server and `ck_partner_member_grants_role_scope` for the
database. The four roles added in R2 cannot be assigned through the legacy team endpoints (`400
VALIDATION_FAILED`, field `role`) until R3b gives them their V1.1 bundles. No permission key was added.

## 2. What guarantees what

| Invariant | Database (V5, production) | Server |
|---|---|---|
| A grant's shape matches its scope type | `ck_partner_member_grants_scope_shape` | factories in `PartnerMemberGrant` |
| A role sits only at its allowed scope types | `ck_partner_member_grants_role_scope` | `PartnerRoleScopes` |
| No unknown role or scope type; no id ≤ 0 | `ck_…_role`, `ck_…_scope_type`, `ck_…_scope_id` | `ScopeRef` (fail-closed parse) |
| A grant belongs to its membership's company | composite FK `fk_partner_member_grants_member` → `(partner_team_members.id, partner_profile_id)` | factories; `@PrePersist` guard |
| A grant names an existing place / room type | `fk_partner_member_grants_property`, `fk_…_unit` | — |
| One grant per membership, role and scope | `uk_partner_member_grant` | `grant()` is idempotent |
| A membership cannot be deleted under its grants | FK | `deleteGrants` before the legacy delete |
| A property grant points into the company **today** | — (ownership moves) | `grant()` refuses, `resolveGrants()` drops |
| A unit grant's room type is in its recorded property | — (no place column on rooms) | `grant()` derives it; `resolveGrants()` drops a mismatch |
| `active` and `status` agree | `ck_partner_team_members_active_status` | entity setters |

Current ownership cannot be a constraint without copying `Place.owner` into the grant, which the design
forbids; the server checks it when a grant is written (`422 SCOPE_INVALID`, field `scope`, same answer for
another company's id and a missing id) and again whenever a grant is read — a grant whose place moved to
another company, or lost its owner, resolves to nothing. A grant is never widened: a unit grant is never read
as its property, a property grant never as its company (§4.5 `covers`).

Each named CHECK is declared twice, verbatim: in the migration (production) and on the entity with
Hibernate `@Check` (the H2 schema tests and local development build from entities). `RbacMembershipMigrationTest`
fails if the two texts ever differ. A CHECK passes when its expression is unknown, so every comparison of a
nullable column in the shape check has its own `is not null` test.

## 3. One company per Partner account (§11.6, Q1)

| Situation | Answer |
|---|---|
| A user with a non-revoked membership of another company calls `POST /api/partner/profile` to create a company (WS-2) | `409 WORKSPACE_CONFLICT`, `reason: MEMBERSHIP_EXISTS`; nothing created |
| The legacy `POST /api/partner/team` targets a user with their own company, or an active member of another company (WS-1) | `422 MEMBER_NOT_ADDABLE`, one uniform message |
| Reactivating a suspended member who is active elsewhere or has their own company (WS-5) | `409 WORKSPACE_CONFLICT` with its `reason` |
| A user holds two active memberships (legacy data) | `activeTeamMembership` refuses to choose (fail closed) |

The registrant's own OWNER row is their company, never "a membership elsewhere". `reason` is a new optional
field of the error body, present only on `WORKSPACE_CONFLICT`; every other error keeps its exact shape.

This is the one intentional behaviour change of R2: the design schedules the WS-2 guard for R3a, and the R2
brief pulled it forward. The edge cases above (adding a conflicting account, reactivating into a conflict)
are refused for the same reason. Everything else on the legacy team endpoints — including the `USER →
PARTNER` promotion and the hard delete — is unchanged until R3a.

## 4. Migrations

All three are additive and forward-only; V1–V3 are untouched. Flyway's SQL Server parser splits a script
only at `GO`, and SQL Server binds column names when it compiles a batch, so every statement of V4–V6 is its
own batch.

### V4 `partner_membership_status` (M-1)

| Existing row | After V4 |
|---|---|
| `active = 1` | `status = ACTIVE` |
| `active = 0` | `status = SUSPENDED`, `status_reason = LEGACY_INACTIVE` (`active` stays 0) |
| every row | `role` unchanged, `pending_owner_confirmation = 0`, `version = 0` |
| approved company whose registrant has no row | an `OWNER`/`ACTIVE` row is added (rule of `ensureOwnerTeamMember`) |

V1's role CHECK was created inline, so SQL Server named it; V4 finds it through `sys.check_constraints` by
its column and replaces it with `ck_partner_team_members_role` holding the nine roles. No row is deleted and no
role is rewritten: a legacy co-owner keeps `OWNER` (R3a carries them as MANAGER pending confirmation, §18 O-9).

### V5 `partner_member_grants` (M-2)

Creates the table and its constraints (§2), and backfills one `COMPANY` grant per membership that is not
revoked, mirroring its role exactly (`created_by` null = migration). Because the backfill mirrors the legacy
role, and the kernel still reads the legacy bundle, nobody gains anything.

### V6 `partner_activity_log_states` (M-4)

Adds `actor_email` (a snapshot, backfilled from the current `users.email` and marked so in `reason`, then
NOT NULL), `before_state`, `after_state` and `reason`. `PartnerActivityLogService` writes `actor_email` on every
new entry, and `PartnerActivityLogRepository` exposes only `save` and reads (append-only, AU-3).

## 5. M-0 — audit before shipping

`db/audit/R2_M0_partner_membership_audit.sql` is one read-only `SELECT` (it also runs on H2 —
`RbacMembershipSchemaTest`). Run it against production before V4–V6, keep the output with the release and
have it signed off:

```
sqlcmd -S <server> -d <database> -I -i db/audit/R2_M0_partner_membership_audit.sql
```

| Finding | R2 | Remediation |
|---|---|---|
| A — ADMIN account as team member | no change | M-6 (R3a): REVOKED |
| B — own company and an active membership elsewhere | no change | M-6: SUSPENDED `WS1_CONFLICT` |
| C — more than one active membership | no change (the kernel refuses to choose) | M-6: all SUSPENDED, owners may reactivate one |
| D — non-registrant OWNER | no change | M-6: MANAGER pending owner confirmation |
| E — inactive membership | V4: SUSPENDED `LEGACY_INACTIVE` | done |
| F — member account not PARTNER | no change | M-6: SUSPENDED `ACCOUNT_ROLE` |
| G — approved company without its OWNER row | V4 adds the row | done |

## 6. Verification

| What | How | Status |
|---|---|---|
| Behaviour, scopes, containment, invariants, compatibility | `RbacMembershipFoundationTest` (HTTP + services, H2) | in the suite |
| Constraints enforced by the entity-built schema; M-0 audit portable | `RbacMembershipSchemaTest` (H2) | in the suite |
| Migration texts, batches as Flyway splits them, entity = migration, additivity, V1–V3 unchanged | `RbacMembershipMigrationTest` (static, Flyway's SQL Server parser) | in the suite |
| V4–V6 on SQL Server through Flyway + Hibernate `validate` | `SqlServerProdChainVerificationTest` (`DB05_SQLSERVER_VERIFY=true`), extended for V4–V6 | **not run** — needs a TCP-reachable SQL Server |

During R2 the migrations were also executed, outside the suite, on a disposable SQL Server 2019 LocalDB
database: V1, V2, V3 (see §7), seeded legacy rows, the M-0 audit, then V4, V5 and V6 byte-for-byte, each in
one transaction as Flyway runs them. The backfills produced the mapping above, the audit returned every
seeded finding, and 29 forbidden rows (every role/scope combination outside §11.3, every malformed shape,
missing references, a grant in another company than its membership, duplicates, an `active`/`status`
mismatch, a log entry without `actor_email`, a hard delete under grants) were refused by the intended
constraint while the 6 legitimate ones were accepted. Hibernate's own SQL Server DDL for the R2 entities,
generated offline, has the same column types as V4–V6. Hibernate `validate` itself could not be run there:
LocalDB accepts only named-pipe connections and the JDBC driver needs TCP.

## 7. Known findings

- **V3 does not run on SQL Server as committed.** Without `GO`, Flyway sends V3 as one batch; it adds
  `users.email_verified_at` and updates it in the same batch, and SQL Server refuses the batch at compile time
  (`Msg 207 Invalid column name 'email_verified_at'`, reproduced on SQL Server 2019 LocalDB). Because SQL
  Server DDL is transactional, V3 cannot have been applied anywhere, so splitting it into batches would not
  invalidate any recorded checksum — but V1–V3 are frozen, so the fix needs its own approved change. Until
  then no production deployment can reach V4–V6.
- Design nit: §11.6 WS-1 reads "own profile or non-revoked memberships, never both", which the registrant's
  own OWNER row would violate; R2 reads it as memberships of *other* companies.

## 8. Not in R2

Invitations and their delivery, acceptance UI, team-management UI, owner transfer, owner protection (R3a),
dual control, the V1.1 matrix on the operational partner endpoints (R3b), admin profiles (R6), custom roles,
physical rooms (a UNIT is a room type), property assignment UI, and every new endpoint.
