-- Flyway V3 — Account lifecycle foundation (Phase A).
--
-- Additive only. V1 and V2 are already applied and are left untouched (forward-only rule, V1 header
-- and DEPLOYMENT.md). No property, room, rate or inventory table is touched.
--
-- Column types follow the V1 conventions (SQL Server dialect, NVARCHAR, DATETIMEOFFSET(6) for
-- instants, BIT for booleans) so the prod profile's ddl-auto=validate accepts the schema.
--
-- users
--   email_verified_at            when the account proved control of its email address
--   email_verification_required  sign-in is gated on verification (Partner self-registration only)
--   token_version                session version carried in every JWT; bumped on credential change
--   terms_accepted_at            when the Partner terms were explicitly accepted
--   terms_version                which Partner terms version was accepted
--
-- Existing accounts: every row present when this migration runs was created before verification
-- existed, so it is marked verified — deterministically, with its own created_at (or the migration
-- time when created_at is null). No existing account becomes gated: email_verification_required
-- defaults to 0 and token_version to 0, which matches tokens issued before V3 (they carry no
-- version and are read as 0). Nothing else about an existing account changes — not its role, not
-- its enabled flag, not any partner profile.
--
-- auth_tokens
--   Stores only the SHA-256 hash of each one-time token, never the token itself.
--
-- Rollback: additive. Reverting the application leaves the columns and table unused. Flyway is
-- forward-only; removing them deliberately requires a later migration.

alter table users add email_verified_at datetimeoffset(6);

alter table users add email_verification_required bit not null
    constraint df_users_email_verification_required default 0;

alter table users add token_version int not null
    constraint df_users_token_version default 0;

alter table users add terms_accepted_at datetimeoffset(6);

alter table users add terms_version nvarchar(32);

-- Batches (DB-07): Flyway's SQL Server parser splits a script only at GO lines, and SQL Server binds
-- column names when it compiles a batch, so the backfill below must run in a later batch than the
-- ALTERs that add its column (otherwise Msg 207). This separator is the only change made to V3, under
-- an approved exception: no evidence shows the original V3 applied on any SQL Server, and the fixed V1-V8
-- chain was verified on a disposable SQL Server 2022 database only (RBAC_MEMBERSHIP_FOUNDATION.md §7).
go

update users
   set email_verified_at = coalesce(created_at, sysdatetimeoffset())
 where email_verified_at is null;

create table auth_tokens (
    id bigint identity not null,
    consumed_at datetimeoffset(6),
    created_at datetimeoffset(6) not null,
    expires_at datetimeoffset(6) not null,
    user_id bigint not null,
    purpose nvarchar(40) not null check (purpose in ('EMAIL_VERIFICATION','PASSWORD_RESET')),
    token_hash nvarchar(64) not null,
    primary key (id)
);

alter table auth_tokens add constraint uk_auth_tokens_token_hash unique (token_hash);

-- Supersede-previous and issuance-cooldown lookups are always by (user, purpose).
create index idx_auth_tokens_user_purpose on auth_tokens (user_id, purpose);

alter table auth_tokens add constraint fk_auth_tokens_user foreign key (user_id) references users;
