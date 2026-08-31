package com.example.planyourtrip.service;

import com.example.planyourtrip.exception.ApiException;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;

import java.util.Set;

/**
 * D1a — builds a safe {@link Pageable} for the administrative collection endpoints.
 *
 * <p>Centralised for three reasons the audit in D0 made concrete:
 *
 * <ul>
 *   <li><b>No sort injection.</b> The client never supplies a sort expression that reaches the
 *       repository. A caller supplies a <em>name</em>, which must appear in an explicit allowlist
 *       owned by the calling service; anything else is a 400. Raw strings are never concatenated
 *       into a query or passed through to {@code Sort.by} unchecked.</li>
 *   <li><b>No unbounded reads.</b> {@code size} is clamped to {@link #MAX_SIZE}, so an admin cannot
 *       ask for the whole table in one request — the exact failure mode D0-2 identified.</li>
 *   <li><b>No accidental 500s.</b> A negative page or a zero size is clamped rather than passed to
 *       {@code PageRequest.of}, which throws {@code IllegalArgumentException} and surfaces as a 500.
 *       That is the {@code page&lt;0 / size&lt;1} defect found in H-FIX live verification, and this
 *       helper ensures the new endpoints never reproduce it.</li>
 * </ul>
 */
public final class AdminPaging {

    /** Default page size when the caller supplies none. */
    public static final int DEFAULT_SIZE = 20;

    /** Hard ceiling; a larger request is clamped, not rejected. */
    public static final int MAX_SIZE = 200;

    private AdminPaging() {}

    /**
     * @param sort    {@code "field"} or {@code "field,asc"} / {@code "field,desc"}; {@code null}
     *                selects {@code defaultField} descending
     * @param allowed the entity property names this endpoint permits sorting by
     */
    public static Pageable of(Integer page, Integer size, String sort,
                               Set<String> allowed, String defaultField) {
        return PageRequest.of(safePage(page), safeSize(size), safeSort(sort, allowed, defaultField));
    }

    public static int safePage(Integer page) {
        return page == null || page < 0 ? 0 : page;
    }

    public static int safeSize(Integer size) {
        if (size == null || size < 1) return DEFAULT_SIZE;
        return Math.min(size, MAX_SIZE);
    }

    /**
     * Resolves a client sort request against an allowlist. The returned {@link Sort} is built only
     * from a value that was present in {@code allowed}, so no client-controlled text ever reaches
     * the persistence layer.
     *
     * <p><b>Every sort is made total by appending {@code id} as a tiebreaker.</b> That is not a
     * cosmetic detail: sorting only by a non-unique column leaves rows that share a value in a
     * database-defined, query-to-query arbitrary order, so paging through a grid can show the same
     * row twice and skip another entirely. Seeded bookings created in one transaction share a
     * {@code createdAt} and reproduce this immediately. A unique final key makes the ordering total
     * and therefore makes pagination stable.
     */
    public static Sort safeSort(String sort, Set<String> allowed, String defaultField) {
        Sort.Direction direction = Sort.Direction.DESC;
        String field = defaultField;

        if (sort != null && !sort.isBlank()) {
            String[] parts = sort.split(",", 2);
            field = parts[0].trim();
            if (!allowed.contains(field)) {
                throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Unsupported sort field '" + field + "'. Allowed: " + String.join(", ", allowed));
            }
            if (parts.length == 2 && !parts[1].isBlank()) {
                String dir = parts[1].trim();
                if (dir.equalsIgnoreCase("asc")) direction = Sort.Direction.ASC;
                else if (dir.equalsIgnoreCase("desc")) direction = Sort.Direction.DESC;
                else throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Unsupported sort direction '" + dir + "'. Use 'asc' or 'desc'.");
            }
        }

        Sort primary = Sort.by(direction, field);
        return "id".equals(field) ? primary : primary.and(Sort.by(Sort.Direction.DESC, "id"));
    }
}
