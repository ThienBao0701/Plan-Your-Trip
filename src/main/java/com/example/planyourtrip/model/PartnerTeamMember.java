package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;

/**
 * A user's membership of one partner company (RBAC V1.1 §12.3).
 *
 * <p>{@link #status} is the membership state; the legacy {@link #active} flag is kept and is always
 * {@code true} exactly when the status is {@code ACTIVE} — both setters keep them in step, and the
 * {@code ck_partner_team_members_active_status} constraint refuses any row where they disagree.
 * {@link #role} is kept as the membership's primary role for backward compatibility; the scoped grants
 * live in {@link PartnerMemberGrant}.
 *
 * <p>The CHECK expressions below are the production constraints of {@code V4__partner_membership_status} and
 * {@code V8__partner_invitations} (Flyway, SQL Server). They are repeated here so the H2 schema that tests and local
 * development build from the entities refuses the same rows production refuses.
 *
 * <p>RBAC R4 — {@link #revocationKey} is 0 while the membership is live and the row's id once it is revoked, and
 * {@code uk_partner_team_members_live} is unique over (company, account, revocation key): one live membership per
 * company and account, revoked rows kept as history, and a removed member re-joins through a new row (RV-2).
 */
@Entity
@Table(name = "partner_team_members",
       indexes = {
           @Index(name = "idx_partner_team_members_profile_id", columnList = "partner_profile_id"),
           @Index(name = "idx_partner_team_members_user_id", columnList = "user_id"),
           @Index(name = "idx_partner_team_members_user_status", columnList = "user_id, status")
       },
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_partner_team_members_live",
                             columnNames = {"partner_profile_id", "user_id", "revocation_key"}),
           @UniqueConstraint(name = "uk_partner_team_members_id_company", columnNames = {"id", "partner_profile_id"})
       })
@Check(name = "ck_partner_team_members_status", constraints = PartnerTeamMember.STATUS_CHECK)
@Check(name = "ck_partner_team_members_active_status", constraints = PartnerTeamMember.ACTIVE_STATUS_CHECK)
@Check(name = "ck_partner_team_members_revocation_key", constraints = PartnerTeamMember.REVOCATION_KEY_CHECK)
@Getter @Setter
public class PartnerTeamMember {

    public static final String STATUS_CHECK = "status in ('ACTIVE','SUSPENDED','REVOKED')";
    public static final String ACTIVE_STATUS_CHECK =
        "(cast(active as int) = 1 and status = 'ACTIVE') or (cast(active as int) = 0 and status <> 'ACTIVE')";

    public static final String REVOCATION_KEY_CHECK =
        "(status = 'REVOKED' and revocation_key > 0) or (status <> 'REVOKED' and revocation_key = 0)";

    /** Reason recorded by V4 for memberships that were already inactive before membership states existed. */
    public static final String LEGACY_INACTIVE = "LEGACY_INACTIVE";

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "partner_profile_id", nullable = false)
    private PartnerProfile partnerProfile;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PartnerTeamRole role;

    @Setter(AccessLevel.NONE)
    @Column(nullable = false)
    private boolean active = true;

    @Setter(AccessLevel.NONE)
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PartnerMembershipStatus status = PartnerMembershipStatus.ACTIVE;

    private String statusReason;

    private Instant statusChangedAt;

    /** The user who last changed the status, or null for a migration or system change. */
    private Long statusChangedBy;

    /** Set by the R3a remediation for a legacy co-owner awaiting the primary owner's confirmation (§18 O-9). */
    @Column(nullable = false)
    private boolean pendingOwnerConfirmation;

    @Version
    @Column(nullable = false)
    private Long version;

    /** RBAC R4 — 0 while live; the row's own id once revoked (see the class comment). Set by {@link #changeStatus}. */
    @Setter(AccessLevel.NONE)
    @ColumnDefault("0")
    @Column(name = "revocation_key", nullable = false)
    private long revocationKey;

    private Instant invitedAt;

    private Instant joinedAt;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    /**
     * Legacy switch used by the existing team endpoints: {@code true} makes the membership {@code ACTIVE};
     * {@code false} suspends an active one. A revoked membership is never revived through this flag.
     */
    public void setActive(boolean active) {
        setActive(active, null);
    }

    /** As {@link #setActive(boolean)}, recording who made the change. */
    public void setActive(boolean active, Long changedBy) {
        if (status == PartnerMembershipStatus.REVOKED) {
            if (active) throw new IllegalStateException("A revoked membership cannot be reactivated");
            return;
        }
        changeStatus(active ? PartnerMembershipStatus.ACTIVE : PartnerMembershipStatus.SUSPENDED, null, changedBy);
    }

    /** Moves the membership to {@code status}, recording why and by whom; keeps {@code active} in step. */
    public void changeStatus(PartnerMembershipStatus newStatus, String reason, Long changedBy) {
        if (newStatus == null) throw new IllegalArgumentException("A membership needs a status");
        if (status == PartnerMembershipStatus.REVOKED && newStatus != PartnerMembershipStatus.REVOKED) {
            throw new IllegalStateException("A revoked membership cannot be reactivated");
        }
        if (newStatus == PartnerMembershipStatus.REVOKED && status != PartnerMembershipStatus.REVOKED) {
            if (id == null) throw new IllegalStateException("Only a stored membership can be revoked");
            revocationKey = id;
        }
        if (newStatus != status) {
            status = newStatus;
            statusReason = reason;
            statusChangedBy = changedBy;
            statusChangedAt = Instant.now();
        }
        active = newStatus == PartnerMembershipStatus.ACTIVE;
    }

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
