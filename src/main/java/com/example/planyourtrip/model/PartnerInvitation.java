package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;

/**
 * RBAC R4 — an invitation of one email address to one partner company (RBAC V1.1 §13, §14, §28 M-3).
 *
 * <p>The one-time token is a bearer instrument (§21.3): only its SHA-256 hash is stored, it is never returned by
 * any endpoint, and a resend rotates it — the old link stops working at once. The invitation's grants
 * ({@link PartnerInvitationGrant}) are validated when the invitation is created and again when it is accepted.
 *
 * <p>{@link #closedKey} is 0 while the invitation is {@code PENDING} and the row's id once it is closed, so
 * {@code uk_partner_invitations_pending} allows one pending invitation per company and address. The CHECK
 * expressions repeat {@code V8__partner_invitations} so the H2 schema refuses what production refuses.
 */
@Entity
@Table(name = "partner_invitations",
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_partner_invitations_token_hash", columnNames = "token_hash"),
           @UniqueConstraint(name = "uk_partner_invitations_pending",
                             columnNames = {"partner_profile_id", "email", "closed_key"})
       },
       indexes = {
           @Index(name = "idx_partner_invitations_company_status", columnList = "partner_profile_id, status"),
           @Index(name = "idx_partner_invitations_email_status", columnList = "email, status")
       })
@Check(name = "ck_partner_invitations_status", constraints = PartnerInvitation.STATUS_CHECK)
@Check(name = "ck_partner_invitations_delivery_status", constraints = PartnerInvitation.DELIVERY_STATUS_CHECK)
@Check(name = "ck_partner_invitations_resend_count", constraints = PartnerInvitation.RESEND_COUNT_CHECK)
@Check(name = "ck_partner_invitations_closed_key", constraints = PartnerInvitation.CLOSED_KEY_CHECK)
@Getter @Setter
public class PartnerInvitation {

    public static final String STATUS_CHECK = "status in ('PENDING','ACCEPTED','DECLINED','REVOKED','EXPIRED')";
    public static final String DELIVERY_STATUS_CHECK = "delivery_status in ('QUEUED','SENT','FAILED')";
    public static final String RESEND_COUNT_CHECK = "resend_count between 0 and 5";
    public static final String CLOSED_KEY_CHECK =
        "(status = 'PENDING' and closed_key = 0) or (status <> 'PENDING' and closed_key > 0)";

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "partner_profile_id", nullable = false)
    private PartnerProfile partnerProfile;

    /** The invited address, normalised like every account email (trim, lower case). */
    @Column(nullable = false, length = 254)
    private String email;

    /** Lowercase hex SHA-256 of the current token. */
    @Column(name = "token_hash", nullable = false, length = 64)
    private String tokenHash;

    @Setter(AccessLevel.NONE)
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PartnerInvitationStatus status = PartnerInvitationStatus.PENDING;

    @Setter(AccessLevel.NONE)
    @Column(name = "status_reason", length = 100)
    private String statusReason;

    @Enumerated(EnumType.STRING)
    @Column(name = "delivery_status", nullable = false, length = 20)
    private PartnerInvitationDeliveryStatus deliveryStatus = PartnerInvitationDeliveryStatus.QUEUED;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "resend_count", nullable = false)
    private int resendCount;

    /** When the current token was last handed to the email sender (creation or resend). */
    @Column(name = "last_sent_at")
    private Instant lastSentAt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "invited_by", nullable = false)
    private User invitedBy;

    /** Who accepted or declined it. */
    @Setter(AccessLevel.NONE)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "responded_by")
    private User respondedBy;

    @Setter(AccessLevel.NONE)
    @Column(name = "responded_at")
    private Instant respondedAt;

    @Setter(AccessLevel.NONE)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "accepted_member_id")
    private PartnerTeamMember acceptedMember;

    @Setter(AccessLevel.NONE)
    @ColumnDefault("0")
    @Column(name = "closed_key", nullable = false)
    private long closedKey;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @Version
    @Column(nullable = false)
    private Long version;

    /** Whether the invitation can still be accepted at {@code now}. */
    public boolean isOpenAt(Instant now) {
        return status == PartnerInvitationStatus.PENDING && expiresAt.isAfter(now);
    }

    /** Closes a pending invitation as revoked, declined or expired. Accepting goes through {@link #accept}. */
    public void close(PartnerInvitationStatus newStatus, String reason, User by, Instant at) {
        if (newStatus == PartnerInvitationStatus.PENDING || newStatus == PartnerInvitationStatus.ACCEPTED)
            throw new IllegalArgumentException("Use accept() to accept an invitation");
        requirePending();
        status = newStatus;
        statusReason = reason;
        if (newStatus == PartnerInvitationStatus.DECLINED) {
            respondedBy = by;
            respondedAt = at;
        }
        closedKey = id;
    }

    /** Marks the invitation consumed by {@code member}. */
    public void accept(User by, PartnerTeamMember member, Instant at) {
        requirePending();
        status = PartnerInvitationStatus.ACCEPTED;
        respondedBy = by;
        respondedAt = at;
        acceptedMember = member;
        closedKey = id;
    }

    private void requirePending() {
        if (status != PartnerInvitationStatus.PENDING) throw new IllegalStateException("The invitation is closed");
        if (id == null) throw new IllegalStateException("Only a stored invitation can be closed");
    }

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = Instant.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
