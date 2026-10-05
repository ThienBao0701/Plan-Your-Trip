-- Flyway V5 — RBAC R2 / M-2: scoped partner grants (RBAC V1.1 §28 M-2, §12.3, §11.3).
--
-- Additive: one new table, its constraints and indexes, one unique key on partner_team_members, and a
-- backfill. No existing row changes.
--
-- partner_member_grants — one role held by one membership at one scope.
--   scope_type   COMPANY | PROPERTY | UNIT (a UNIT is a room type, hotel_rooms, in V1)
--   scope_id     never null: the company id for COMPANY, the place id for PROPERTY, the room id for UNIT.
--                Storing the company id keeps uk_partner_member_grant meaningful on SQL Server and H2
--                alike (the two treat nulls in unique constraints differently).
--   property_id  the place of a PROPERTY or UNIT grant (FK places)
--   unit_id      the room type of a UNIT grant (FK hotel_rooms)
--   partner_profile_id  the membership's company, pinned to it by the composite FK to
--                (partner_team_members.id, partner_profile_id)
--
-- Constraints the database enforces:
--   ck_partner_member_grants_role         the nine V1.1 roles
--   ck_partner_member_grants_scope_type   COMPANY, PROPERTY, UNIT
--   ck_partner_member_grants_scope_id     scope_id > 0
--   ck_partner_member_grants_scope_shape  which columns each scope type uses; COMPANY must be the
--                                         membership's company. The is-not-null tests are required: a
--                                         CHECK passes on unknown, so a bare property_id = scope_id would
--                                         admit a PROPERTY grant without a property.
--   ck_partner_member_grants_role_scope   §11.3: OWNER and FINANCE company-only, HOUSEKEEPING property or
--                                         unit, every other role company or property
--   uk_partner_member_grant               one grant per (membership, role, scope)
--   foreign keys                          to the membership (with its company), the company, the place and
--                                         the room — no grant can point at a missing row
-- Whether a property or room belongs to the company today cannot be a constraint (ownership moves);
-- the application checks it when a grant is written and again whenever a grant is read.
--
-- Backfill: one COMPANY grant per membership that is not revoked, mirroring role exactly. Every legacy
-- role may sit at COMPANY scope. Effective rights: none change — the R1 kernel still decides with the
-- legacy bundles, and nothing reads these grants for a decision before R3b.
--
-- Rollback: additive. Reverting the application leaves the table unused.
--
-- Batches: Flyway's SQL Server parser splits a script only at GO lines, and SQL Server binds column names
-- when it compiles a batch, so a column added in one batch cannot be read or written by DML in the same
-- batch. Every statement below is therefore its own batch.

alter table partner_team_members add constraint uk_partner_team_members_id_company
    unique (id, partner_profile_id);
go

create table partner_member_grants (
    id bigint identity not null,
    created_at datetimeoffset(6) not null,
    created_by bigint,
    partner_profile_id bigint not null,
    property_id bigint,
    scope_id bigint not null,
    team_member_id bigint not null,
    unit_id bigint,
    role nvarchar(20) not null,
    scope_type nvarchar(20) not null,
    primary key (id)
);
go

alter table partner_member_grants add constraint uk_partner_member_grant
    unique (team_member_id, role, scope_type, scope_id);
go

alter table partner_member_grants add constraint ck_partner_member_grants_role
    check (role in ('OWNER','MANAGER','REVENUE','RESERVATIONS','FRONT_DESK','FINANCE','CONTENT','HOUSEKEEPING','VIEWER'));
go

alter table partner_member_grants add constraint ck_partner_member_grants_scope_type
    check (scope_type in ('COMPANY','PROPERTY','UNIT'));
go

alter table partner_member_grants add constraint ck_partner_member_grants_scope_id
    check (scope_id > 0);
go

alter table partner_member_grants add constraint ck_partner_member_grants_scope_shape
    check ((scope_type = 'COMPANY' and scope_id = partner_profile_id and property_id is null and unit_id is null)
        or (scope_type = 'PROPERTY' and property_id is not null and property_id = scope_id and unit_id is null)
        or (scope_type = 'UNIT' and unit_id is not null and unit_id = scope_id and property_id is not null));
go

alter table partner_member_grants add constraint ck_partner_member_grants_role_scope
    check ((role in ('OWNER','FINANCE') and scope_type = 'COMPANY')
        or (role in ('MANAGER','REVENUE','RESERVATIONS','FRONT_DESK','CONTENT','VIEWER')
            and scope_type in ('COMPANY','PROPERTY'))
        or (role = 'HOUSEKEEPING' and scope_type in ('PROPERTY','UNIT')));
go

alter table partner_member_grants add constraint fk_partner_member_grants_member
    foreign key (team_member_id, partner_profile_id) references partner_team_members (id, partner_profile_id);
go

alter table partner_member_grants add constraint fk_partner_member_grants_company
    foreign key (partner_profile_id) references partner_profiles;
go

alter table partner_member_grants add constraint fk_partner_member_grants_property
    foreign key (property_id) references places;
go

alter table partner_member_grants add constraint fk_partner_member_grants_unit
    foreign key (unit_id) references hotel_rooms;
go

-- "Which grants does this company hold?" and "which grants reference this property or room?" (§16 PA-4).
create index idx_partner_member_grants_company on partner_member_grants (partner_profile_id);
go
create index idx_partner_member_grants_property on partner_member_grants (property_id);
go
create index idx_partner_member_grants_unit on partner_member_grants (unit_id);
go

insert into partner_member_grants
       (created_at, created_by, partner_profile_id, property_id, scope_id, team_member_id, unit_id, role, scope_type)
select sysdatetimeoffset(), null, m.partner_profile_id, null, m.partner_profile_id, m.id, null, m.role, 'COMPANY'
  from partner_team_members m
 where m.status <> 'REVOKED';
go
