package com.example.planyourtrip.model;

/**
 * RBAC R6 — the life of a dual-control request (RBAC V1.1 §22.6). Every state except {@link #PENDING} is terminal:
 * a closed request is never reopened and never executed.
 */
public enum DualControlStatus {
    /** Submitted, waiting for a second administrator; valid for 24 hours. */
    PENDING,
    /** Approved by a different eligible administrator; the action ran in the approval's transaction. */
    APPROVED,
    /** Refused by a different eligible administrator, with a reason. */
    REJECTED,
    /** Withdrawn by the requester while pending. */
    CANCELLED,
    /** Its 24 hours ran out before anyone decided. */
    EXPIRED,
    /** The target or the requester changed after submission, so the stored action can no longer run as reviewed. */
    STALE;

    /** The SQL Server / H2 CHECK on {@code admin_dual_control_requests.status}. */
    public static final String CHECK =
        "status in ('PENDING','APPROVED','REJECTED','CANCELLED','EXPIRED','STALE')";
}
