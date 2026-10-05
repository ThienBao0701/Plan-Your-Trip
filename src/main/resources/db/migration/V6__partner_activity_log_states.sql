-- Flyway V6 — RBAC R2 / M-4: partner activity log snapshots (RBAC V1.1 §28 M-4, §22.1 AU-2).
--
-- partner_activity_logs
--   actor_email   the actor's email when the row was written — a snapshot, never re-resolved, so the trail
--                 stays truthful if the account changes. Existing rows are backfilled from the current
--                 users.email (or user:<id> when the account no longer exists) and marked in reason.
--                 NOT NULL once backfilled; the application writes it on every new row.
--   before_state, after_state   short, safe scalar summaries of a change (500 characters)
--   reason        why the change was made, when a reason was given
--
-- The application's repository for this table no longer exposes update or delete (append-only, AU-3).
-- Effective rights: none change.
--
-- Rollback: additive apart from the NOT NULL on actor_email, which the application always satisfies.
--
-- Batches: Flyway's SQL Server parser splits a script only at GO lines, and SQL Server binds column names
-- when it compiles a batch, so a column added in one batch cannot be read or written by DML in the same
-- batch. Every statement below is therefore its own batch.

alter table partner_activity_logs add actor_email nvarchar(255);
go

alter table partner_activity_logs add before_state nvarchar(500);
go

alter table partner_activity_logs add after_state nvarchar(500);
go

alter table partner_activity_logs add reason nvarchar(500);
go

update l
   set actor_email = coalesce(u.email, concat('user:', l.actor_user_id)),
       reason = 'actor_email backfilled from users.email by V6'
  from partner_activity_logs l
  left join users u on u.id = l.actor_user_id
 where l.actor_email is null;
go

alter table partner_activity_logs alter column actor_email nvarchar(255) not null;
go
