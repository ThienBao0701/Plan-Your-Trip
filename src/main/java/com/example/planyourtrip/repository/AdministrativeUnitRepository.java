package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.AdministrativeUnit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface AdministrativeUnitRepository extends JpaRepository<AdministrativeUnit, Long> {

    List<AdministrativeUnit> findByParentIsNull();

    List<AdministrativeUnit> findByParentId(Long parentId);

    /**
     * D12 — one query per tree level instead of one per node.
     *
     * <p>Used by the cycle guard, the descendant path cascade and the backfill, all of which walk
     * the tree downwards breadth-first. Fetching a whole level at a time keeps those walks at
     * O(depth) queries rather than O(nodes).
     */
    List<AdministrativeUnit> findByParentIdIn(Collection<Long> parentIds);

    Optional<AdministrativeUnit> findBySlug(String slug);

    Optional<AdministrativeUnit> findByCode(String code);

    boolean existsBySlug(String slug);

    boolean existsByCode(String code);

    @Query("SELECT a FROM AdministrativeUnit a WHERE " +
           "LOWER(a.name) LIKE LOWER(CONCAT('%', :kw, '%')) OR " +
           "a.nameNormalized LIKE CONCAT('%', :nkw, '%') OR " +
           "LOWER(a.slug) LIKE LOWER(CONCAT('%', :kw, '%')) OR " +
           "(a.oldName IS NOT NULL AND LOWER(a.oldName) LIKE LOWER(CONCAT('%', :kw, '%')))")
    List<AdministrativeUnit> search(@Param("kw") String keyword, @Param("nkw") String normalizedKeyword);
}
