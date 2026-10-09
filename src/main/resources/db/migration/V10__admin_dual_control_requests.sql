-- Flyway V10 — RBAC R6: dual-control requests for A16 (RBAC V1.1 §22.6, §12.4 admin_dual_control_requests).
--
-- Additive. V1-V9 are applied and left untouched (forward-only rule). No existing row is written.
--
-- admin_dual_control_requests
--   One dual-controlled administrative action. In R6 the only one is A16 admin.place.owner.assign (moving a
--   property to another company); A11 arrives with its endpoint in R8 and the threshold actions A31/A39/A41/A42 in
--   R7, which is why permission and target_type are CHECKed to today's single value and widened by a later
--   migration (ck_admin_dual_control_requests_permission, ck_admin_dual_control_requests_target_type).
--   payload             the exact action as JSON (place, proposed company, expected current company). Written once;
--                       approval executes it from this row, never from the approver's request body.
--   payload_digest      SHA-256 of payload, a consistency check (not a substitute for immutability).
--   amount, currency    reserved by the §12.4 sketch for the R7 threshold actions; NULL for A16.
--   status              PENDING, then exactly one terminal state (ck_admin_dual_control_requests_status).
--   expires_at          requested_at + 24 hours (§22.6).
--   approved_by/_at, rejected_by, decided_at, decision_reason   the decision
--                       (ck_admin_dual_control_requests_decision).
--   live_key            0 while PENDING, the row's own id once closed (ck_admin_dual_control_requests_live).
--                       unique (permission, target_type, target_id, live_key) (uk_admin_dual_control_requests_live)
--                       allows at most one open request per action and target, written the way V8 and V9 write
--                       their live keys so the guarantee holds on SQL Server and on H2 (no filtered index).
--
-- Rollback: an application without dual control ignores the table; dropping it loses only the request history
-- (the decisions are also in admin_activity_logs).
--
-- Batches: Flyway's SQL Server parser splits a script only at GO lines, and SQL Server binds column names when it
-- compiles a batch, so every statement below is its own batch.

create table admin_dual_control_requests (
    id bigint identity not null,
    permission nvarchar(80) not null,
    target_type nvarchar(40) not null,
    target_id bigint not null,
    payload nvarchar(1000) not null,
    payload_digest nvarchar(64) not null,
    amount numeric(19,2),
    currency nvarchar(3),
    requested_by bigint not null,
    requested_at datetimeoffset(6) not null,
    reason nvarchar(500),
    status nvarchar(20) not null,
    expires_at datetimeoffset(6) not null,
    approved_by bigint,
    approved_at datetimeoffset(6),
    rejected_by bigint,
    decided_at datetimeoffset(6),
    decision_reason nvarchar(500),
    live_key bigint not null
        constraint df_admin_dual_control_requests_live_key default 0,
    version bigint not null,
    primary key (id)
);
go

alter table admin_dual_control_requests add constraint uk_admin_dual_control_requests_live
    unique (permission, target_type, target_id, live_key);
go

alter table admin_dual_control_requests add constraint ck_admin_dual_control_requests_permission
    check (permission in ('admin.place.owner.assign'));
go

alter table admin_dual_control_requests add constraint ck_admin_dual_control_requests_target_type
    check (target_type in ('PLACE'));
go

alter table admin_dual_control_requests add constraint ck_admin_dual_control_requests_status
    check (status in ('PENDING','APPROVED','REJECTED','CANCELLED','EXPIRED','STALE'));
go

alter table admin_dual_control_requests add constraint ck_admin_dual_control_requests_live
    check ((status = 'PENDING' and live_key = 0) or (status <> 'PENDING' and live_key > 0));
go

alter table admin_dual_control_requests add constraint ck_admin_dual_control_requests_decision
    check ((status = 'PENDING' or decided_at is not null) and (status <> 'APPROVED' or (approved_by is not null and approved_at is not null)) and (status <> 'REJECTED' or rejected_by is not null));
go

alter table admin_dual_control_requests add constraint fk_admin_dual_control_requests_requested_by
    foreign key (requested_by) references users;
go

alter table admin_dual_control_requests add constraint fk_admin_dual_control_requests_approved_by
    foreign key (approved_by) references users;
go

alter table admin_dual_control_requests add constraint fk_admin_dual_control_requests_rejected_by
    foreign key (rejected_by) references users;
go

-- The request queue: "what is pending, newest first?" (GET /api/admin/dual-control/requests).
create index idx_admin_dual_control_requests_status on admin_dual_control_requests (status, requested_at);
go
