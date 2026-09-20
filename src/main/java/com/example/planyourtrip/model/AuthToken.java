package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

/**
 * Phase A — a one-time, expiring token sent to an account's email address (verification, password
 * reset).
 *
 * <p>Only the SHA-256 hash of the token is stored; the raw value exists in the outgoing message and
 * nowhere else, so a copy of this table cannot be replayed. {@code consumedAt} is set when the token
 * is used <em>and</em> when a newer token of the same purpose supersedes it — either way it can
 * never be used again.
 */
@Entity
@Table(name = "auth_tokens",
       indexes = {
           @Index(name = "uk_auth_tokens_token_hash", columnList = "token_hash", unique = true),
           @Index(name = "idx_auth_tokens_user_purpose", columnList = "user_id, purpose")
       })
@Getter @Setter
public class AuthToken {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private AuthTokenPurpose purpose;

    /** Lowercase hex SHA-256 of the raw token. */
    @Column(name = "token_hash", nullable = false, length = 64)
    private String tokenHash;

    @Column(nullable = false)
    private Instant expiresAt;

    private Instant consumedAt;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;
}
