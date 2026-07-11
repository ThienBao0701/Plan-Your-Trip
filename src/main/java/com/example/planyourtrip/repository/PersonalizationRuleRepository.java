package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PersonalizationRule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * Admin CRUD over {@link PersonalizationRule} plus the "rules in force now"
 * selector used at generation time.
 */
public interface PersonalizationRuleRepository extends JpaRepository<PersonalizationRule, Long> {

    Optional<PersonalizationRule> findByRuleCodeIgnoreCase(String ruleCode);

    boolean existsByRuleCodeIgnoreCase(String ruleCode);

    List<PersonalizationRule> findAllByOrderByPriorityDescIdAsc();

    /**
     * Active rules whose validity window contains {@code at}: active,
     * validFrom null-or-&le;at, validUntil null-or-&ge;at. Highest priority first.
     */
    @Query("""
        select r from PersonalizationRule r
        where r.active = true
          and (r.validFrom is null or r.validFrom <= :at)
          and (r.validUntil is null or r.validUntil >= :at)
        order by r.priority desc, r.id asc
        """)
    List<PersonalizationRule> findApplicable(@Param("at") Instant at);
}
