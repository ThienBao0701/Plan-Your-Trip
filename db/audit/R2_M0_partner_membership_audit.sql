-- RBAC R2 / M-0 — pre-migration partner membership audit (RBAC V1.1 §28 M-0).
--
-- READ-ONLY. One SELECT, no writes, no temporary objects. Run it against the production database before
-- V4-V6 ship (and again before R3a), keep the output with the release, and have it signed off.
-- It only reads columns that exist since V1, so it runs unchanged before and after V4-V6.
-- The same text runs on SQL Server and on the H2 test database (RbacMembershipSchemaTest).
--
--   sqlcmd -S <server> -d <database> -I -i db/audit/R2_M0_partner_membership_audit.sql
--
-- One row per finding:
--   finding             which check matched (letters as in §28 M-0)
--   user_id             the account concerned
--   partner_profile_id  the company concerned
--   team_member_id      the membership row concerned (empty for G)
--
--   A_ADMIN_MEMBER                  a team member whose account role is ADMIN (R-S3)
--   B_OWN_PROFILE_AND_MEMBERSHIP    an account with its own company and an active membership of another (WS-1)
--   C_MULTIPLE_ACTIVE_MEMBERSHIPS   an account with more than one active membership (the legacy lookup fails)
--   D_NON_REGISTRANT_OWNER          an OWNER row for someone who did not register the company
--   E_INACTIVE_MEMBERSHIP           an inactive row; V4 makes it SUSPENDED (reason LEGACY_INACTIVE)
--   F_ACCOUNT_NOT_PARTNER           a team member whose account role is not PARTNER (or is missing)
--   G_APPROVED_WITHOUT_OWNER_ROW    an approved company whose registrant has no OWNER row; V4 adds the row
--                                   when the registrant has no row at all
--
-- What R2 does with the findings: E and G are handled by V4. A, B, C, D and F change nobody's rights in
-- R2 (the legacy rules still decide); they are remediated by M-6 in R3a. An empty result needs no action.

select 'A_ADMIN_MEMBER' as finding, m.user_id, m.partner_profile_id, m.id as team_member_id
  from partner_team_members m
  join users u on u.id = m.user_id
 where u.role = 'ADMIN'
union all
select 'B_OWN_PROFILE_AND_MEMBERSHIP', m.user_id, m.partner_profile_id, m.id
  from partner_team_members m
  join partner_profiles own on own.user_id = m.user_id
 where cast(m.active as int) = 1
   and own.id <> m.partner_profile_id
union all
select 'C_MULTIPLE_ACTIVE_MEMBERSHIPS', m.user_id, m.partner_profile_id, m.id
  from partner_team_members m
 where cast(m.active as int) = 1
   and (select count(*)
          from partner_team_members other
         where other.user_id = m.user_id
           and cast(other.active as int) = 1) > 1
union all
select 'D_NON_REGISTRANT_OWNER', m.user_id, m.partner_profile_id, m.id
  from partner_team_members m
  join partner_profiles p on p.id = m.partner_profile_id
 where m.role = 'OWNER'
   and p.user_id <> m.user_id
union all
select 'E_INACTIVE_MEMBERSHIP', m.user_id, m.partner_profile_id, m.id
  from partner_team_members m
 where cast(m.active as int) = 0
union all
select 'F_ACCOUNT_NOT_PARTNER', m.user_id, m.partner_profile_id, m.id
  from partner_team_members m
  join users u on u.id = m.user_id
 where u.role is null
    or u.role <> 'PARTNER'
union all
select 'G_APPROVED_WITHOUT_OWNER_ROW', p.user_id, p.id, cast(null as bigint)
  from partner_profiles p
 where p.verification_status = 'APPROVED'
   and not exists (select 1
                     from partner_team_members m
                    where m.partner_profile_id = p.id
                      and m.user_id = p.user_id
                      and m.role = 'OWNER')
 order by finding, user_id, partner_profile_id;
