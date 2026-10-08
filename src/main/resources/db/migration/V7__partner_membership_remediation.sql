-- Flyway V7 — RBAC R3a / M-6: membership remediation (RBAC V1.1 §28 M-6, §18 O-9, §11.6, I24).
--
-- Ships in the same release as the owner protections of R3a. Run the read-only M-0 audit
-- (db/audit/R2_M0_partner_membership_audit.sql) again first and keep the signed-off report with the release:
-- the letters below are its findings. (e) inactive rows and (g) missing OWNER rows were handled by V4.
--
-- Mapping, applied in this order to memberships that are not the registrant's own row (the own company always
-- wins, O-1) and not already revoked:
--   (a) the account is ADMIN                                    -> REVOKED,   reason ADMIN_ACCOUNT, grants removed
--   (f) the account is not PARTNER (USER, unknown, missing)     -> SUSPENDED, reason ACCOUNT_ROLE   (ACTIVE rows)
--   (b) the account has its own company and is ACTIVE elsewhere -> SUSPENDED, reason WS1_CONFLICT   (ACTIVE rows)
--   (c) the account is ACTIVE in more than one other company    -> every one SUSPENDED, reason WS1_CONFLICT;
--       each owner may reactivate one (WS-5 re-checks)
--   (d) the membership holds OWNER (legacy co-owner)            -> MANAGER@COMPANY with
--       pending_owner_confirmation = 1 and role MANAGER; the primary owner confirms through P12 (step-up,
--       OWNER_GRANTED). Status is unchanged.
--
-- Reduction only (I24): nothing here grants anything. (d) removes legacy team management, owner management and
-- payout power until the primary owner confirms; a pending co-owner keeps exactly MANAGER's legacy rights.
--
-- Every change writes one strict partner audit row MEMBERSHIP_REMEDIATED with actor SYSTEM (actor_user_id null,
-- actor_email SYSTEM), before/after and the reason, and a mandatory security notification to the company's
-- primary owner and to the member (O-8). partner_activity_logs.actor_user_id becomes nullable for those rows.
--
-- Batches: every statement is its own batch (Flyway's SQL Server parser splits only at GO; SQL Server binds
-- columns per batch). Within each step the audit and notification inserts run before the update, with the same
-- predicate, so they describe exactly the rows the update changes.

alter table partner_activity_logs alter column actor_user_id bigint null;
go

-- (a) administrator accounts ------------------------------------------------------------------------------

insert into partner_activity_logs
       (actor_user_id, actor_email, created_at, entity_id, partner_profile_id, action, description, entity_type,
        before_state, after_state, reason)
select null, 'SYSTEM', sysdatetimeoffset(), m.id, m.partner_profile_id, 'MEMBERSHIP_REMEDIATED',
       'Membership revoked: administrator accounts cannot be team members (M-6 a)', 'TEAM_MEMBER',
       concat(m.role, '|', m.status), concat(m.role, '|REVOKED'), 'ADMIN_ACCOUNT'
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
  join users u on u.id = m.user_id
 where p.user_id <> m.user_id and m.status <> 'REVOKED' and u.role = 'ADMIN';
go

insert into notifications
       (is_read, created_at, recipient_user_id, related_entity_id, notification_type, priority, related_entity_type,
        title, message)
select 0, sysdatetimeoffset(), r.recipient, m.partner_profile_id, 'PARTNER', 'HIGH', 'PARTNER',
       'Team membership remediated',
       concat('The membership of ', u.email, ' was revoked: administrator accounts cannot be team members.')
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
  join users u on u.id = m.user_id
  cross apply (values (p.user_id), (m.user_id)) r(recipient)
 where p.user_id <> m.user_id and m.status <> 'REVOKED' and u.role = 'ADMIN';
go

delete g
  from partner_member_grants g
  join partner_team_members m on m.id = g.team_member_id
  join partner_profiles p on p.id = m.partner_profile_id
  join users u on u.id = m.user_id
 where p.user_id <> m.user_id and m.status <> 'REVOKED' and u.role = 'ADMIN';
go

update m
   set status = 'REVOKED', active = 0, status_reason = 'ADMIN_ACCOUNT', status_changed_at = sysdatetimeoffset(),
       status_changed_by = null, version = m.version + 1
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
  join users u on u.id = m.user_id
 where p.user_id <> m.user_id and m.status <> 'REVOKED' and u.role = 'ADMIN';
go

-- (f) accounts that are not PARTNER ------------------------------------------------------------------------

insert into partner_activity_logs
       (actor_user_id, actor_email, created_at, entity_id, partner_profile_id, action, description, entity_type,
        before_state, after_state, reason)
select null, 'SYSTEM', sysdatetimeoffset(), m.id, m.partner_profile_id, 'MEMBERSHIP_REMEDIATED',
       'Membership suspended: the account is not a Partner account (M-6 f)', 'TEAM_MEMBER',
       concat(m.role, '|ACTIVE'), concat(m.role, '|SUSPENDED'), 'ACCOUNT_ROLE'
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
  join users u on u.id = m.user_id
 where p.user_id <> m.user_id and m.status = 'ACTIVE' and (u.role is null or u.role <> 'PARTNER');
go

insert into notifications
       (is_read, created_at, recipient_user_id, related_entity_id, notification_type, priority, related_entity_type,
        title, message)
select 0, sysdatetimeoffset(), r.recipient, m.partner_profile_id, 'PARTNER', 'HIGH', 'PARTNER',
       'Team membership remediated',
       concat('The membership of ', u.email, ' was suspended: the account is not a Partner account.')
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
  join users u on u.id = m.user_id
  cross apply (values (p.user_id), (m.user_id)) r(recipient)
 where p.user_id <> m.user_id and m.status = 'ACTIVE' and (u.role is null or u.role <> 'PARTNER');
go

update m
   set status = 'SUSPENDED', active = 0, status_reason = 'ACCOUNT_ROLE', status_changed_at = sysdatetimeoffset(),
       status_changed_by = null, version = m.version + 1
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
  join users u on u.id = m.user_id
 where p.user_id <> m.user_id and m.status = 'ACTIVE' and (u.role is null or u.role <> 'PARTNER');
go

-- (b) own company and an active membership elsewhere -------------------------------------------------------

insert into partner_activity_logs
       (actor_user_id, actor_email, created_at, entity_id, partner_profile_id, action, description, entity_type,
        before_state, after_state, reason)
select null, 'SYSTEM', sysdatetimeoffset(), m.id, m.partner_profile_id, 'MEMBERSHIP_REMEDIATED',
       'Membership suspended: the account has its own company (M-6 b)', 'TEAM_MEMBER',
       concat(m.role, '|ACTIVE'), concat(m.role, '|SUSPENDED'), 'WS1_CONFLICT'
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
 where p.user_id <> m.user_id and m.status = 'ACTIVE'
   and exists (select 1 from partner_profiles own where own.user_id = m.user_id);
go

insert into notifications
       (is_read, created_at, recipient_user_id, related_entity_id, notification_type, priority, related_entity_type,
        title, message)
select 0, sysdatetimeoffset(), r.recipient, m.partner_profile_id, 'PARTNER', 'HIGH', 'PARTNER',
       'Team membership remediated',
       concat('The membership of ', u.email, ' was suspended: the account belongs to another company.')
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
  join users u on u.id = m.user_id
  cross apply (values (p.user_id), (m.user_id)) r(recipient)
 where p.user_id <> m.user_id and m.status = 'ACTIVE'
   and exists (select 1 from partner_profiles own where own.user_id = m.user_id);
go

update m
   set status = 'SUSPENDED', active = 0, status_reason = 'WS1_CONFLICT', status_changed_at = sysdatetimeoffset(),
       status_changed_by = null, version = m.version + 1
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
 where p.user_id <> m.user_id and m.status = 'ACTIVE'
   and exists (select 1 from partner_profiles own where own.user_id = m.user_id);
go

-- (c) more than one active membership ----------------------------------------------------------------------

insert into partner_activity_logs
       (actor_user_id, actor_email, created_at, entity_id, partner_profile_id, action, description, entity_type,
        before_state, after_state, reason)
select null, 'SYSTEM', sysdatetimeoffset(), m.id, m.partner_profile_id, 'MEMBERSHIP_REMEDIATED',
       'Membership suspended: the account is active in more than one company (M-6 c)', 'TEAM_MEMBER',
       concat(m.role, '|ACTIVE'), concat(m.role, '|SUSPENDED'), 'WS1_CONFLICT'
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
 where p.user_id <> m.user_id and m.status = 'ACTIVE'
   and (select count(*)
          from partner_team_members o
          join partner_profiles op on op.id = o.partner_profile_id
         where o.user_id = m.user_id and o.status = 'ACTIVE' and op.user_id <> o.user_id) > 1;
go

insert into notifications
       (is_read, created_at, recipient_user_id, related_entity_id, notification_type, priority, related_entity_type,
        title, message)
select 0, sysdatetimeoffset(), r.recipient, m.partner_profile_id, 'PARTNER', 'HIGH', 'PARTNER',
       'Team membership remediated',
       concat('The membership of ', u.email, ' was suspended: the account is active in more than one company.')
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
  join users u on u.id = m.user_id
  cross apply (values (p.user_id), (m.user_id)) r(recipient)
 where p.user_id <> m.user_id and m.status = 'ACTIVE'
   and (select count(*)
          from partner_team_members o
          join partner_profiles op on op.id = o.partner_profile_id
         where o.user_id = m.user_id and o.status = 'ACTIVE' and op.user_id <> o.user_id) > 1;
go

update m
   set status = 'SUSPENDED', active = 0, status_reason = 'WS1_CONFLICT', status_changed_at = sysdatetimeoffset(),
       status_changed_by = null, version = m.version + 1
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
 where p.user_id <> m.user_id and m.status = 'ACTIVE'
   and (select count(*)
          from partner_team_members o
          join partner_profiles op on op.id = o.partner_profile_id
         where o.user_id = m.user_id and o.status = 'ACTIVE' and op.user_id <> o.user_id) > 1;
go

-- (d) legacy co-owners -> MANAGER pending owner confirmation -----------------------------------------------

insert into partner_activity_logs
       (actor_user_id, actor_email, created_at, entity_id, partner_profile_id, action, description, entity_type,
        before_state, after_state, reason)
select null, 'SYSTEM', sysdatetimeoffset(), m.id, m.partner_profile_id, 'MEMBERSHIP_REMEDIATED',
       'Legacy co-owner carried as MANAGER pending the primary owner''s confirmation (M-6 d)', 'TEAM_MEMBER',
       concat('OWNER@COMPANY:', m.partner_profile_id, '|', m.status),
       concat('MANAGER@COMPANY:', m.partner_profile_id, '|', m.status, '|PENDING_OWNER_CONFIRMATION'),
       'LEGACY_CO_OWNER'
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
 where p.user_id <> m.user_id and m.status <> 'REVOKED'
   and (m.role = 'OWNER'
        or exists (select 1 from partner_member_grants g
                    where g.team_member_id = m.id and g.role = 'OWNER' and g.scope_type = 'COMPANY'));
go

insert into notifications
       (is_read, created_at, recipient_user_id, related_entity_id, notification_type, priority, related_entity_type,
        title, message)
select 0, sysdatetimeoffset(), r.recipient, m.partner_profile_id, 'PARTNER', 'HIGH', 'PARTNER',
       'Co-owner pending confirmation',
       concat(u.email, ' now has MANAGER access until the primary owner confirms them as an owner.')
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
  join users u on u.id = m.user_id
  cross apply (values (p.user_id), (m.user_id)) r(recipient)
 where p.user_id <> m.user_id and m.status <> 'REVOKED'
   and (m.role = 'OWNER'
        or exists (select 1 from partner_member_grants g
                    where g.team_member_id = m.id and g.role = 'OWNER' and g.scope_type = 'COMPANY'));
go

update m
   set role = 'MANAGER', pending_owner_confirmation = 1, version = m.version + 1
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
 where p.user_id <> m.user_id and m.status <> 'REVOKED'
   and (m.role = 'OWNER'
        or exists (select 1 from partner_member_grants g
                    where g.team_member_id = m.id and g.role = 'OWNER' and g.scope_type = 'COMPANY'));
go

delete g
  from partner_member_grants g
  join partner_team_members m on m.id = g.team_member_id
 where m.pending_owner_confirmation = 1 and g.role = 'OWNER';
go

insert into partner_member_grants
       (created_at, created_by, partner_profile_id, property_id, scope_id, team_member_id, unit_id, role, scope_type)
select sysdatetimeoffset(), null, m.partner_profile_id, null, m.partner_profile_id, m.id, null, 'MANAGER', 'COMPANY'
  from partner_team_members m
 where m.pending_owner_confirmation = 1 and m.status <> 'REVOKED'
   and not exists (select 1 from partner_member_grants g
                    where g.team_member_id = m.id and g.role = 'MANAGER' and g.scope_type = 'COMPANY');
go
