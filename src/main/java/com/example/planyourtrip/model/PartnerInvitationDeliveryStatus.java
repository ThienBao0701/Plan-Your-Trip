package com.example.planyourtrip.model;

/**
 * RBAC R4 — the outcome of the latest invitation email (RBAC V1.1 §13.1 step 7). The email is sent after the
 * invitation commits: {@code QUEUED} until then, {@code SENT} or {@code FAILED} afterwards. A failed delivery
 * leaves the invitation {@code PENDING}, to be resent.
 */
public enum PartnerInvitationDeliveryStatus {
    QUEUED,
    SENT,
    FAILED
}
