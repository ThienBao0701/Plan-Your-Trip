-- Flyway V9 — RBAC R6 / M-5: admin profile assignments (RBAC V1.1 §7, §10.2, §28 M-5).
--
-- Additive. V1-V8 are applied and left untouched (forward-only rule).
--
-- admin_profile_assignments
--   One admin profile held by one ADMIN account; an administrator may hold several, and the effective admin
--   permissions are the union of their bundles (§7). profile is one of the 11 profiles of §7
--   (ck_admin_profile_assignments_profile).
--   granted_by          the PLATFORM_OWNER who granted it; NULL for a system grant (this backfill, the
--                       production bootstrap).
--   revoked_at, revoked_by   set when the profile is revoked; the row stays as history (AP-3).
--   revocation_key      0 while the assignment is active, the row's own id once it is revoked
--                       (ck_admin_profile_assignments_revocation). unique (user_id, profile, revocation_key)
--                       (uk_admin_profile_assignments_live) allows at most one active assignment of a profile per
--                       account. This is M-5's "filtered unique index" written the way V8 writes
--                       uk_partner_team_members_live, so the same guarantee holds on SQL Server and on H2.
--
-- Backfill (AP-4): every existing ADMIN account becomes PLATFORM_OWNER (granted_by NULL), so every
-- administrator keeps exactly today's access until profiles are deliberately narrowed.
--
-- Effective rights: none change. R1 gave every ADMIN every admin permission; after the backfill every ADMIN
-- holds PLATFORM_OWNER, which is every admin permission.
--
-- Rollback: the application of R5 ignores the table. Dropping it loses only the assignment history.
--
-- Batches: Flyway's SQL Server parser splits a script only at GO lines, and SQL Server binds column names when it
-- compiles a batch, so every statement below is its own batch.

create table admin_profile_assignments (
    id bigint identity not null,
    user_id bigint not null,
    profile nvarchar(40) not null,
    granted_by bigint,
    granted_at datetimeoffset(6) not null,
    revoked_at datetimeoffset(6),
    revoked_by bigint,
    revocation_key bigint not null
        constraint df_admin_profile_assignments_revocation_key default 0,
    version bigint not null,
    primary key (id)
);
go

alter table admin_profile_assignments add constraint uk_admin_profile_assignments_live
    unique (user_id, profile, revocation_key);
go

alter table admin_profile_assignments add constraint ck_admin_profile_assignments_profile
    check (profile in ('PLATFORM_OWNER','PARTNER_OPERATIONS','CONTENT_CATALOGUE','BOOKING_SUPPORT','FINANCE_OPERATIONS','GROWTH_MARKETING','TRUST_SAFETY','REVIEW_MODERATION','ANALYTICS','LOCATION_CATALOGUE','TECH_SUPPORT'));
go

alter table admin_profile_assignments add constraint ck_admin_profile_assignments_revocation
    check ((revoked_at is null and revocation_key = 0) or (revoked_at is not null and revocation_key > 0));
go

alter table admin_profile_assignments add constraint fk_admin_profile_assignments_user
    foreign key (user_id) references users;
go

alter table admin_profile_assignments add constraint fk_admin_profile_assignments_granted_by
    foreign key (granted_by) references users;
go

alter table admin_profile_assignments add constraint fk_admin_profile_assignments_revoked_by
    foreign key (revoked_by) references users;
go

-- "Who holds PLATFORM_OWNER now?" — the AP-2 last-platform-owner check (§19, §26 E14).
create index idx_admin_profile_assignments_profile on admin_profile_assignments (profile, revocation_key);
go

-- AP-4 backfill: every existing ADMIN account becomes PLATFORM_OWNER, a system grant.
insert into admin_profile_assignments (user_id, profile, granted_by, granted_at, revoked_at, revoked_by,
                                       revocation_key, version)
select id, 'PLATFORM_OWNER', null, sysdatetimeoffset(), null, null, 0, 0
  from users
 where role = 'ADMIN';
go
