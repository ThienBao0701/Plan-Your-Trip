-- Flyway V4 — RBAC R2 / M-1: partner membership status (RBAC V1.1 §28 M-1, §12.3).
--
-- Additive. V1-V3 are applied and left untouched (forward-only rule). Run the read-only M-0 audit
-- (db/audit/R2_M0_partner_membership_audit.sql) and have it signed off before this migration ships.
--
-- partner_team_members
--   role CHECK                  V1 created it inline, so SQL Server named it itself. It is looked up in
--                               sys.check_constraints, dropped, and re-created as ck_partner_team_members_role
--                               with the nine V1.1 roles. Every existing value (the five legacy roles)
--                               stays valid. The Java enum gained the same four roles in the same release.
--   status                      ACTIVE | SUSPENDED | REVOKED. Rows that are active become ACTIVE; inactive
--                               rows become SUSPENDED with reason LEGACY_INACTIVE. active is kept and must
--                               agree with status (ck_partner_team_members_active_status).
--   status_reason, status_changed_at, status_changed_by
--   pending_owner_confirmation  0 for every row; set only by the R3a remediation (M-6).
--   version                     optimistic locking, 0 for every existing row.
--
-- Missing OWNER rows: an approved company whose registrant has no team row gets one, exactly as
-- PartnerProfileService.ensureOwnerTeamMember creates it on approval.
--
-- Effective rights: none change. The application still reads active and role through the R1 legacy
-- bundles; the new columns are not used for any decision in R2.
--
-- Rollback: additive. Reverting the application leaves the columns unused. The widened role check only
-- admits more values.
--
-- Batches: Flyway's SQL Server parser splits a script only at GO lines, and SQL Server binds column names
-- when it compiles a batch, so a column added in one batch cannot be read or written by DML in the same
-- batch. Every statement below is therefore its own batch.

-- V1's role check has a name SQL Server generated: find it by its column, then drop it.
declare @role_check sysname
declare @drop_role_check nvarchar(400)
select @role_check = cc.name
  from sys.check_constraints cc
  join sys.columns c on c.object_id = cc.parent_object_id and c.column_id = cc.parent_column_id
 where cc.parent_object_id = object_id(N'partner_team_members')
   and c.name = N'role'
if @role_check is not null
begin
    set @drop_role_check = N'alter table partner_team_members drop constraint ' + quotename(@role_check)
    exec sp_executesql @drop_role_check
end
go

alter table partner_team_members add constraint ck_partner_team_members_role
    check (role in ('OWNER','MANAGER','REVENUE','RESERVATIONS','FRONT_DESK','FINANCE','CONTENT','HOUSEKEEPING','VIEWER'));
go

alter table partner_team_members add status nvarchar(20) not null
    constraint df_partner_team_members_status default 'ACTIVE';
go

alter table partner_team_members add status_reason nvarchar(255);
go

alter table partner_team_members add status_changed_at datetimeoffset(6);
go

alter table partner_team_members add status_changed_by bigint;
go

alter table partner_team_members add pending_owner_confirmation bit not null
    constraint df_partner_team_members_pending_owner_confirmation default 0;
go

alter table partner_team_members add version bigint not null
    constraint df_partner_team_members_version default 0;
go

update partner_team_members
   set status = 'SUSPENDED',
       status_reason = 'LEGACY_INACTIVE'
 where active = 0;
go

alter table partner_team_members add constraint ck_partner_team_members_status
    check (status in ('ACTIVE','SUSPENDED','REVOKED'));
go

alter table partner_team_members add constraint ck_partner_team_members_active_status
    check ((cast(active as int) = 1 and status = 'ACTIVE') or (cast(active as int) = 0 and status <> 'ACTIVE'));
go

insert into partner_team_members
       (active, created_at, invited_at, joined_at, partner_profile_id, updated_at, user_id, role,
        status, pending_owner_confirmation, version)
select 1, sysdatetimeoffset(), sysdatetimeoffset(), sysdatetimeoffset(), p.id, sysdatetimeoffset(), p.user_id,
       'OWNER', 'ACTIVE', 0, 0
  from partner_profiles p
 where p.verification_status = 'APPROVED'
   and not exists (select 1
                     from partner_team_members m
                    where m.partner_profile_id = p.id
                      and m.user_id = p.user_id);
go

-- "Which memberships does this account hold, in which state?" (one-workspace checks, §11.6).
create index idx_partner_team_members_user_status on partner_team_members (user_id, status);
go
