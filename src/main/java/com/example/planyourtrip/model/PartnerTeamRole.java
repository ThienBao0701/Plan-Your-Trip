package com.example.planyourtrip.model;

/**
 * The nine partner workspace roles of RBAC V1.1 §6, in the design's order. A role is a default permission
 * bundle; it is never a system role and never crosses company boundaries.
 *
 * <p>{@code REVENUE}, {@code RESERVATIONS}, {@code CONTENT} and {@code HOUSEKEEPING} were added in R2
 * together with the widened {@code ck_partner_team_members_role} constraint (V4), as §28 requires. They
 * can be stored but carry no runtime capability yet, and the legacy team endpoints do not assign them.
 */
public enum PartnerTeamRole {
    OWNER,
    MANAGER,
    REVENUE,
    RESERVATIONS,
    FRONT_DESK,
    FINANCE,
    CONTENT,
    HOUSEKEEPING,
    VIEWER
}
