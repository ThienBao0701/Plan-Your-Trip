package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.AuthToken;
import com.example.planyourtrip.model.AuthTokenPurpose;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;

public interface AuthTokenRepository extends JpaRepository<AuthToken, Long> {

    Optional<AuthToken> findByTokenHash(String tokenHash);

    /** The most recently issued token of {@code purpose} for the account — drives the issuance cooldown. */
    Optional<AuthToken> findFirstByUserIdAndPurposeOrderByCreatedAtDescIdDesc(Long userId, AuthTokenPurpose purpose);

    /** Retires every still-usable token of {@code purpose} for the account. */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("UPDATE AuthToken t SET t.consumedAt = :now "
         + "WHERE t.user.id = :userId AND t.purpose = :purpose AND t.consumedAt IS NULL")
    int retireActive(@Param("userId") Long userId, @Param("purpose") AuthTokenPurpose purpose,
                     @Param("now") Instant now);

    /**
     * Consumes one token only if nobody has yet. Returns 1 for the single caller that wins; a replayed
     * or concurrently consumed token returns 0. This is the replay guard, so it must stay conditional.
     */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("UPDATE AuthToken t SET t.consumedAt = :now WHERE t.id = :id AND t.consumedAt IS NULL")
    int consumeIfUnused(@Param("id") Long id, @Param("now") Instant now);

    long countByUserIdAndPurpose(Long userId, AuthTokenPurpose purpose);
}
