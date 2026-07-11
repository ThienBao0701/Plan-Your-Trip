package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.CustomerRecommendation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * Ownership-scoped access to {@link CustomerRecommendation} snapshots. A single
 * user's active set is bounded (capped at generation time), so list/summary
 * endpoints fetch the user's rows once and filter/paginate in-memory rather than
 * issuing a complex multi-join query.
 */
public interface CustomerRecommendationRepository extends JpaRepository<CustomerRecommendation, Long> {

    List<CustomerRecommendation> findByUserId(Long userId);

    Optional<CustomerRecommendation> findByIdAndUserId(Long id, Long userId);

    /**
     * Deletes only the "active + unengaged" snapshots for a user — rows the user
     * has never dismissed, clicked or converted. Clicked/converted/dismissed
     * history is preserved across regeneration.
     */
    @Modifying
    @Query("""
        delete from CustomerRecommendation r
        where r.user.id = :userId
          and r.dismissedAt is null
          and r.clickedAt is null
          and r.convertedAt is null
        """)
    int deleteUnengagedForUser(@Param("userId") Long userId);

    /**
     * Detaches snapshots from a rule about to be deleted — recommendation history
     * is preserved (nullable {@code sourceRule}), no FK violation on rule delete.
     */
    @Modifying
    @Query("update CustomerRecommendation r set r.sourceRule = null where r.sourceRule.id = :ruleId")
    int clearSourceRule(@Param("ruleId") Long ruleId);
}
