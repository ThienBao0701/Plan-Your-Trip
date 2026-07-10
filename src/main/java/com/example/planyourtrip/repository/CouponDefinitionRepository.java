package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.CouponDefinition;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CouponDefinitionRepository extends JpaRepository<CouponDefinition, Long> {

    /** Case-insensitive claim-by-code lookup (codes are stored upper-case, input may be any case). */
    Optional<CouponDefinition> findByCodeIgnoreCase(String code);

    /** Case-insensitive uniqueness check for admin create/update. */
    boolean existsByCodeIgnoreCase(String code);
}
