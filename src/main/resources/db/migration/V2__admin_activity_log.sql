-- Flyway V2 — Administrative audit trail (D1a).
--
-- Additive only: creates one new table and its indexes. Touches no existing table, column,
-- constraint or row, so it cannot destroy or migrate existing data. V1 is already applied and is
-- left untouched, per the forward-only rule stated in V1's header and DEPLOYMENT.md §19.
--
-- Column types follow the V1 conventions exactly (SQL Server dialect, NVARCHAR for Unicode,
-- DATETIMEOFFSET(6) for instants) so Hibernate's prod-profile ddl-auto=validate accepts the schema.
-- The entity declares `description` as columnDefinition="TEXT"; as in V1 that long-text column is
-- emitted here as NVARCHAR(MAX) rather than the deprecated, non-Unicode SQL Server TEXT type.
--
-- actor_user_id is intentionally NOT a foreign key to users. An audit trail must stay truthful and
-- readable after the actor row changes or is removed; a FK would couple immutable history to a
-- mutable row and could cascade it away. The actor's email is snapshotted in actor_email instead.
--
-- Rollback: this migration is additive, so reverting the application code needs no schema change --
-- the table simply stops being written. Flyway is forward-only; to remove the table deliberately,
-- ship a V3 that drops it (and accept the permanent loss of the audit history).

create table admin_activity_logs (
    id bigint identity not null,
    actor_user_id bigint,
    created_at datetimeoffset(6),
    target_id bigint,
    action nvarchar(80) not null,
    actor_email nvarchar(255) not null,
    target_type nvarchar(60),
    after_state nvarchar(500),
    before_state nvarchar(500),
    description nvarchar(max),
    primary key (id)
);

-- Supports the default newest-first listing and the created_at range filter.
create index idx_admin_activity_logs_created_at on admin_activity_logs (created_at);
-- "What did this administrator do?"
create index idx_admin_activity_logs_actor on admin_activity_logs (actor_user_id);
-- "Who performed this kind of action?"
create index idx_admin_activity_logs_action on admin_activity_logs (action);
-- "What happened to this specific entity?" — composite, matching the (targetType, targetId) filter.
create index idx_admin_activity_logs_target on admin_activity_logs (target_type, target_id);
