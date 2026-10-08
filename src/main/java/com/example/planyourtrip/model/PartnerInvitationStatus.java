package com.example.planyourtrip.model;

/** RBAC R4 — the life of a partner invitation (RBAC V1.1 §13, §14). Only {@code PENDING} can change. */
public enum PartnerInvitationStatus {
    PENDING,
    ACCEPTED,
    DECLINED,
    REVOKED,
    EXPIRED
}
