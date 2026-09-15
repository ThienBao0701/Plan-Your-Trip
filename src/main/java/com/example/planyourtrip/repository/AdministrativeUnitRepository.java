package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.AdministrativeUnit;
import org.springframework.data.domain.Pageable;
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

    /**
     * D14 — the escape character every search pattern is built with.
     *
     * <p>{@code !} rather than a backslash, which databases and string literals disagree about. The
     * service escapes keywords with exactly this character ({@code LocationService#escapeLike}), and
     * every {@code LIKE} in {@link #search} declares it.
     */
    char LIKE_ESCAPE = '!';

    /**
     * Public keyword search over name, accent-free name, slug and former name — substring matching,
     * unchanged in what it searches.
     *
     * <p>D14: {@code :kw} and {@code :nkw} arrive already escaped, so {@code %}, {@code _} and
     * {@code [} are literal; the accent-free predicate is skipped when {@code :nkw} is empty, so it
     * can never become {@code LIKE '%%'}; rows are ordered {@code name, id}; and the caller bounds the
     * row count with {@code page}. The return type is a {@code List}, so no count query runs.
     */
    @Query("SELECT a FROM AdministrativeUnit a WHERE " +
           "LOWER(a.name) LIKE LOWER(CONCAT('%', :kw, '%')) ESCAPE '" + LIKE_ESCAPE + "' OR " +
           "(:nkw <> '' AND a.nameNormalized LIKE CONCAT('%', :nkw, '%') ESCAPE '" + LIKE_ESCAPE + "') OR " +
           "LOWER(a.slug) LIKE LOWER(CONCAT('%', :kw, '%')) ESCAPE '" + LIKE_ESCAPE + "' OR " +
           "(a.oldName IS NOT NULL AND LOWER(a.oldName) LIKE LOWER(CONCAT('%', :kw, '%')) ESCAPE '"
               + LIKE_ESCAPE + "') " +
           "ORDER BY a.name ASC, a.id ASC")
    List<AdministrativeUnit> search(@Param("kw") String keyword, @Param("nkw") String normalizedKeyword,
                                    Pageable page);
}
