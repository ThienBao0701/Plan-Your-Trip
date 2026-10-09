package com.example.planyourtrip.model;

import com.example.planyourtrip.security.rbac.AdminProfile;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Check;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;

/**
 * RBAC R6 / M-5 — one admin profile held by one {@code ADMIN} account (RBAC V1.1 §7, §28 M-5).
 *
 * <p>An assignment is active while {@link #revokedAt} is null. {@link #revocationKey} is 0 while it is active and
 * the row's own id once it is revoked, so {@code uk_admin_profile_assignments_live} — unique
 * (user_id, profile, revocation_key) — allows at most one active assignment of a profile per account while
 * revoked rows stay as history. This is the M-5 "filtered unique index" expressed the way V8 does it, so the
 * same guarantee holds on SQL Server and on H2 (which has no filtered index).
 *
 * <p>{@link #grantedBy} is null for the M-5 backfill and the production bootstrap (a system grant).
 */
@Entity
@Table(name = "admin_profile_assignments",
       uniqueConstraints = @UniqueConstraint(name = "uk_admin_profile_assignments_live",
                                             columnNames = {"user_id", "profile", "revocation_key"}),
       indexes = @Index(name = "idx_admin_profile_assignments_profile", columnList = "profile, revocation_key"))
@Check(name = "ck_admin_profile_assignments_profile", constraints = AdminProfile.CHECK)
@Check(name = "ck_admin_profile_assignments_revocation",
       constraints = AdminProfileAssignment.REVOCATION_CHECK)
@Getter @Setter
public class AdminProfileAssignment {

    public static final String REVOCATION_CHECK =
        "(revoked_at is null and revocation_key = 0) or (revoked_at is not null and revocation_key > 0)";

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private AdminProfile profile;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "granted_by")
    private User grantedBy;

    @Column(name = "granted_at", nullable = false, updatable = false)
    private Instant grantedAt;

    @Setter(AccessLevel.NONE)
    @Column(name = "revoked_at")
    private Instant revokedAt;

    @Setter(AccessLevel.NONE)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "revoked_by")
    private User revokedBy;

    @Setter(AccessLevel.NONE)
    @ColumnDefault("0")
    @Column(name = "revocation_key", nullable = false)
    private long revocationKey;

    @Version
    @Column(nullable = false)
    private Long version;

    /**
     * A system grant ({@code grantedBy} null): the M-5 backfill's shape, used by the production bootstrap and the
     * development seed for the first administrator, who must be a {@code PLATFORM_OWNER} (AP-2, AP-4).
     */
    public static AdminProfileAssignment systemGrant(User user, AdminProfile profile, Instant at) {
        AdminProfileAssignment grant = new AdminProfileAssignment();
        grant.setUser(user);
        grant.setProfile(profile);
        grant.setGrantedAt(at);
        return grant;
    }

    public boolean isActive() {
        return revokedAt == null;
    }

    /** Ends a stored, active assignment; the row stays as history. */
    public void revoke(User by, Instant at) {
        if (!isActive()) throw new IllegalStateException("The assignment is already revoked");
        if (id == null) throw new IllegalStateException("Only a stored assignment can be revoked");
        revokedAt = at;
        revokedBy = by;
        revocationKey = id;
    }
}
