package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.PlaceStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface PlaceRepository extends JpaRepository<Place, Long>, JpaSpecificationExecutor<Place> {

    @EntityGraph(attributePaths = {"category", "subcategory", "administrativeUnit"})
    @Query("SELECT p FROM Place p WHERE p.status = :status")
    List<Place> findByStatus(@Param("status") PlaceStatus status);

    @EntityGraph(attributePaths = {"category", "subcategory", "administrativeUnit"})
    @Query("SELECT p FROM Place p")
    List<Place> findAllWithDetails();

    @EntityGraph(attributePaths = {"category", "subcategory", "administrativeUnit"})
    @Query("SELECT p FROM Place p WHERE p.id = :id AND p.status = :status")
    Optional<Place> findByIdAndStatus(@Param("id") Long id, @Param("status") PlaceStatus status);

    @EntityGraph(attributePaths = {"category", "subcategory", "administrativeUnit"})
    @Query("SELECT p FROM Place p WHERE p.slug = :slug AND p.status = :status")
    Optional<Place> findBySlugAndStatus(@Param("slug") String slug, @Param("status") PlaceStatus status);

    @EntityGraph(attributePaths = {"category", "subcategory", "administrativeUnit"})
    Page<Place> findAll(Specification<Place> spec, Pageable pageable);

    Optional<Place> findBySlug(String slug);

    boolean existsBySlug(String slug);

    boolean existsBySlugAndIdNot(String slug, Long id);

    List<Place> findByCategoryId(Long categoryId);

    List<Place> findByAdministrativeUnitId(Long administrativeUnitId);

    List<Place> findAllByOwnerId(Long ownerId);

    Optional<Place> findByIdAndOwnerId(Long id, Long ownerId);

    long countByOwnerId(Long ownerId);
}
