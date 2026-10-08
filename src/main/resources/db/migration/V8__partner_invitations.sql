-- Flyway V8 — RBAC R4 / M-3: partner invitations and re-addable memberships (RBAC V1.1 §13, §14, §17 RV-2,
-- §28 M-3).
--
-- Additive. V1-V7 are applied and left untouched (forward-only rule).
--
-- partner_team_members
--   revocation_key      0 while the membership is ACTIVE or SUSPENDED; the row's own id once it is REVOKED
--                       (ck_partner_team_members_revocation_key). Existing revoked rows are backfilled.
--   uk_partner_team_member_profile_user (V1, unique (partner_profile_id, user_id)) is replaced by
--   uk_partner_team_members_live, unique (partner_profile_id, user_id, revocation_key): at most one live
--   (non-revoked) membership per company and account, while revoked rows stay as history. A removed member can
--   then join again through a NEW membership row (fresh consent, RV-2) — a revoked row is never revived. The same
--   key works on SQL Server and on H2 (no filtered index: H2 has none, and SQL Server treats NULLs in a unique
--   constraint as equal, which a nullable key column would turn into a "one revoked row per company" limit).
--
-- partner_invitations (M-3)
--   One invitation of an email address to a company, carrying the grants it will create on acceptance.
--   token_hash          lowercase hex SHA-256 of the one-time token; the token itself is never stored.
--   status              PENDING | ACCEPTED | DECLINED | REVOKED | EXPIRED (status_reason e.g. SUPERSEDED).
--   delivery_status     QUEUED | SENT | FAILED — the outcome of the latest send, which happens after commit.
--   resend_count, last_sent_at   the §31 Q16 limits (≤ 5 resends, 60 s cooldown).
--   closed_key          0 while PENDING, the row's own id once closed: unique (partner_profile_id, email,
--                       closed_key) allows one PENDING invitation per company and address (a new one supersedes).
-- partner_invitation_grants (M-3)
--   The grants of an invitation, with the same role, scope-type and role/scope CHECKs as partner_member_grants.
--
-- Effective rights: none change. No row is written to the new tables, no membership changes status.
--
-- Rollback: the application of R3b ignores the new column and tables. Re-creating the V1 unique key would fail
-- once a member has been re-added (two rows for one company and account), which is the point of R4.
--
-- Batches: Flyway's SQL Server parser splits a script only at GO lines, and SQL Server binds column names when it
-- compiles a batch, so a column added in one batch cannot be read or written by DML in the same batch. Every
-- statement below is therefore its own batch.

alter table partner_team_members add revocation_key bigint not null
    constraint df_partner_team_members_revocation_key default 0;
go

update partner_team_members
   set revocation_key = id
 where status = 'REVOKED';
go

alter table partner_team_members drop constraint uk_partner_team_member_profile_user;
go

alter table partner_team_members add constraint uk_partner_team_members_live
    unique (partner_profile_id, user_id, revocation_key);
go

alter table partner_team_members add constraint ck_partner_team_members_revocation_key
    check ((status = 'REVOKED' and revocation_key > 0) or (status <> 'REVOKED' and revocation_key = 0));
go

create table partner_invitations (
    id bigint identity not null,
    partner_profile_id bigint not null,
    email nvarchar(254) not null,
    token_hash nvarchar(64) not null,
    status nvarchar(20) not null,
    status_reason nvarchar(100),
    delivery_status nvarchar(20) not null,
    expires_at datetimeoffset(6) not null,
    resend_count int not null,
    last_sent_at datetimeoffset(6),
    invited_by bigint not null,
    responded_by bigint,
    responded_at datetimeoffset(6),
    accepted_member_id bigint,
    closed_key bigint not null,
    created_at datetimeoffset(6) not null,
    updated_at datetimeoffset(6),
    version bigint not null,
    primary key (id)
);
go

alter table partner_invitations add constraint uk_partner_invitations_token_hash unique (token_hash);
go

alter table partner_invitations add constraint uk_partner_invitations_pending
    unique (partner_profile_id, email, closed_key);
go

alter table partner_invitations add constraint ck_partner_invitations_status
    check (status in ('PENDING','ACCEPTED','DECLINED','REVOKED','EXPIRED'));
go

alter table partner_invitations add constraint ck_partner_invitations_delivery_status
    check (delivery_status in ('QUEUED','SENT','FAILED'));
go

alter table partner_invitations add constraint ck_partner_invitations_resend_count
    check (resend_count between 0 and 5);
go

alter table partner_invitations add constraint ck_partner_invitations_closed_key
    check ((status = 'PENDING' and closed_key = 0) or (status <> 'PENDING' and closed_key > 0));
go

alter table partner_invitations add constraint fk_partner_invitations_company
    foreign key (partner_profile_id) references partner_profiles;
go

alter table partner_invitations add constraint fk_partner_invitations_invited_by
    foreign key (invited_by) references users;
go

alter table partner_invitations add constraint fk_partner_invitations_responded_by
    foreign key (responded_by) references users;
go

alter table partner_invitations add constraint fk_partner_invitations_member
    foreign key (accepted_member_id) references partner_team_members;
go

-- "Which invitations does this company have, and how many are pending?" (§13.1 step 4, §25.3).
create index idx_partner_invitations_company_status on partner_invitations (partner_profile_id, status);
go

-- "Which invitations are addressed to me?" (§14 AC-5).
create index idx_partner_invitations_email_status on partner_invitations (email, status);
go

create table partner_invitation_grants (
    id bigint identity not null,
    invitation_id bigint not null,
    role nvarchar(20) not null,
    scope_type nvarchar(20) not null,
    scope_id bigint not null,
    primary key (id)
);
go

alter table partner_invitation_grants add constraint uk_partner_invitation_grant
    unique (invitation_id, role, scope_type, scope_id);
go

alter table partner_invitation_grants add constraint ck_partner_invitation_grants_role
    check (role in ('OWNER','MANAGER','REVENUE','RESERVATIONS','FRONT_DESK','FINANCE','CONTENT','HOUSEKEEPING','VIEWER'));
go

alter table partner_invitation_grants add constraint ck_partner_invitation_grants_scope_type
    check (scope_type in ('COMPANY','PROPERTY','UNIT'));
go

alter table partner_invitation_grants add constraint ck_partner_invitation_grants_scope_id
    check (scope_id > 0);
go

alter table partner_invitation_grants add constraint ck_partner_invitation_grants_role_scope
    check ((role in ('OWNER','FINANCE') and scope_type = 'COMPANY')
        or (role in ('MANAGER','REVENUE','RESERVATIONS','FRONT_DESK','CONTENT','VIEWER')
            and scope_type in ('COMPANY','PROPERTY'))
        or (role = 'HOUSEKEEPING' and scope_type in ('PROPERTY','UNIT')));
go

alter table partner_invitation_grants add constraint fk_partner_invitation_grants_invitation
    foreign key (invitation_id) references partner_invitations;
go

-- "Which pending invitations reference this property or room?" (§16 PA-4).
create index idx_partner_invitation_grants_scope on partner_invitation_grants (scope_type, scope_id);
go
