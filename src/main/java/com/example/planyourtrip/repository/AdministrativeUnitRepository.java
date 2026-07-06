package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.AdministrativeUnit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface AdministrativeUnitRepository extends JpaRepository<AdministrativeUnit, Long> {

    List<AdministrativeUnit> findByParentIsNull();

    List<AdministrativeUnit> findByParentId(Long parentId);

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
