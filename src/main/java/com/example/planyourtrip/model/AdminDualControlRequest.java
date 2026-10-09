package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * RBAC R6 — one dual-controlled administrative action awaiting, or past, a second administrator's decision
 * (RBAC V1.1 §22.6, §12.4 {@code admin_dual_control_requests}).
 *
 * <p>The action is described by {@link #payload}, written once at submission and never updated (every column of the
 * proposal is {@code updatable = false}); approval executes exactly that payload, read back from this row, never
 * from the approver's request. {@link #payloadDigest} is its SHA-256, a consistency check only.
 *
 * <p>{@link #liveKey} is 0 while the request is {@code PENDING} and the row's own id once it is closed, so
 * {@code uk_admin_dual_control_requests_live} — unique (permission, target_type, target_id, live_key) — allows at
 * most one open request per action and target while closed requests stay as history. This is the V8/V9 live-key
 * pattern, which holds the same way on SQL Server and on H2.
 *
 * <p>{@code amount} and {@code currency} are part of the §12.4 sketch for the threshold actions of R7 (A31, A39,
 * A41, A42); A16 leaves them null.
 */
@Entity
@Table(name = "admin_dual_control_requests",
       uniqueConstraints = @UniqueConstraint(name = "uk_admin_dual_control_requests_live",
                                             columnNames = {"permission", "target_type", "target_id", "live_key"}),
       indexes = @Index(name = "idx_admin_dual_control_requests_status", columnList = "status, requested_at"))
@Check(name = "ck_admin_dual_control_requests_permission", constraints = AdminDualControlRequest.PERMISSION_CHECK)
@Check(name = "ck_admin_dual_control_requests_target_type", constraints = AdminDualControlRequest.TARGET_TYPE_CHECK)
@Check(name = "ck_admin_dual_control_requests_status", constraints = DualControlStatus.CHECK)
@Check(name = "ck_admin_dual_control_requests_live", constraints = AdminDualControlRequest.LIVE_CHECK)
@Check(name = "ck_admin_dual_control_requests_decision", constraints = AdminDualControlRequest.DECISION_CHECK)
@Getter @Setter
public class AdminDualControlRequest {

    /** The only dual-controlled action of R6: A16 {@code admin.place.owner.assign}. */
    public static final String PERMISSION_CHECK = "permission in ('admin.place.owner.assign')";
    public static final String TARGET_TYPE_CHECK = "target_type in ('PLACE')";
    public static final String LIVE_CHECK =
        "(status = 'PENDING' and live_key = 0) or (status <> 'PENDING' and live_key > 0)";
    /** A decided request names its decider and time; an approval its approver, a rejection its rejecter. */
    public static final String DECISION_CHECK = "(status = 'PENDING' or decided_at is not null) "
        + "and (status <> 'APPROVED' or (approved_by is not null and approved_at is not null)) "
        + "and (status <> 'REJECTED' or rejected_by is not null)";

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** The admin permission key of the action (A16). */
    @Column(nullable = false, length = 80, updatable = false)
    private String permission;

    @Column(name = "target_type", nullable = false, length = 40, updatable = false)
    private String targetType;

    @Column(name = "target_id", nullable = false, updatable = false)
    private Long targetId;

    /** The exact action, as JSON: what the approver reviews and what approval executes. */
    @Column(nullable = false, length = 1000, updatable = false)
    private String payload;

    @Column(name = "payload_digest", nullable = false, length = 64, updatable = false)
    private String payloadDigest;

    @Column(precision = 19, scale = 2, updatable = false)
    private BigDecimal amount;

    @Column(length = 3, updatable = false)
    private String currency;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "requested_by", nullable = false, updatable = false)
    private User requestedBy;

    @Column(name = "requested_at", nullable = false, updatable = false)
    private Instant requestedAt;

    /** The requester's optional, credential-free reason. */
    @Column(length = 500, updatable = false)
    private String reason;

    @Setter(AccessLevel.NONE)
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DualControlStatus status = DualControlStatus.PENDING;

    @Column(name = "expires_at", nullable = false, updatable = false)
    private Instant expiresAt;

    @Setter(AccessLevel.NONE)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    private User approvedBy;

    @Setter(AccessLevel.NONE)
    @Column(name = "approved_at")
    private Instant approvedAt;

    @Setter(AccessLevel.NONE)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "rejected_by")
    private User rejectedBy;

    /** When the request left {@code PENDING}, whichever way. */
    @Setter(AccessLevel.NONE)
    @Column(name = "decided_at")
    private Instant decidedAt;

    /** The rejection reason, or the machine reason of an expiry or a stale request. */
    @Setter(AccessLevel.NONE)
    @Column(name = "decision_reason", length = 500)
    private String decisionReason;

    @Setter(AccessLevel.NONE)
    @ColumnDefault("0")
    @Column(name = "live_key", nullable = false)
    private long liveKey;

    @Version
    @Column(nullable = false)
    private Long version;

    /** Pending, and still inside its 24 hours at {@code now}. */
    public boolean isOpenAt(Instant now) {
        return status == DualControlStatus.PENDING && expiresAt.isAfter(now);
    }

    /** The state a reader sees: a pending request past its expiry reads as expired before anyone persists it. */
    public DualControlStatus statusAt(Instant now) {
        return status == DualControlStatus.PENDING && !expiresAt.isAfter(now) ? DualControlStatus.EXPIRED : status;
    }

    public void approve(User approver, Instant at) {
        close(DualControlStatus.APPROVED, at, null);
        this.approvedBy = approver;
        this.approvedAt = at;
    }

    public void reject(User rejecter, Instant at, String reason) {
        close(DualControlStatus.REJECTED, at, reason);
        this.rejectedBy = rejecter;
    }

    public void cancel(Instant at) {
        close(DualControlStatus.CANCELLED, at, null);
    }

    public void expire(Instant at) {
        close(DualControlStatus.EXPIRED, at, null);
    }

    public void markStale(Instant at, String reason) {
        close(DualControlStatus.STALE, at, reason);
    }

    private void close(DualControlStatus to, Instant at, String reason) {
        if (status != DualControlStatus.PENDING) {
            throw new IllegalStateException("Dual-control request " + id + " is already " + status);
        }
        this.status = to;
        this.decidedAt = at;
        this.decisionReason = reason;
        this.liveKey = id;
    }
}
