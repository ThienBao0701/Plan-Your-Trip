package com.example.planyourtrip.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;

@Entity
@Table(name = "users", indexes = @Index(name = "idx_users_email", columnList = "email", unique = true))
@Getter @Setter
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    private String fullName;

    @Email @NotBlank
    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    /** Stored as text; read it through {@link AccountRole#parse}, which fails closed. */
    private String role = "USER";

    /** Account switch. Checked at sign-in and on every authenticated request. */
    private boolean enabled = true;

    /**
     * Phase A — when the account proved control of its email address, or null. Accounts that existed
     * before V3 were backfilled as verified by the migration.
     */
    private Instant emailVerifiedAt;

    /**
     * Phase A — true only for accounts whose sign-in is gated on email verification. Partner
     * self-registration sets it; traveller registration, seeding, bootstrap and the Admin approval of
     * a traveller's partner application leave it false.
     */
    @Column(nullable = false)
    private boolean emailVerificationRequired;

    /**
     * Phase A — session version. Every JWT carries the value it was issued with, and a request whose
     * token version differs is not authenticated. Incremented when the credentials change.
     */
    @Column(nullable = false)
    private int tokenVersion;

    /** Phase A — when the Partner terms were explicitly accepted, and which version. */
    private Instant termsAcceptedAt;

    @Column(length = 32)
    private String termsVersion;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
