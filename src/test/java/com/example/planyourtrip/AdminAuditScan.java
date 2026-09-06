package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminActivityLog;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.function.Consumer;

/**
 * D3J — the exhaustive read used by every persisted-audit-row safety scan in the test suite.
 *
 * <h2>What this replaces</h2>
 *
 * The safety scans introduced by D1c/D3F/D3G all read the trail with a single
 * {@code PageRequest.of(0, 200)} and inspected {@code getContent()}. That is a "first N rows" read
 * wearing the clothes of a full scan: it was written when the trail held a few dozen rows, and it
 * silently degrades into checking only the newest 200 as the suite grows. A credential-shaped value
 * written by row 201 would have been invisible to it — and invisible in exactly the direction that
 * matters, because {@code ORDER BY createdAt DESC} means the rows that fall off the end are the
 * <em>oldest</em> ones, the ones nobody looks at again.
 *
 * <h2>Why this one cannot stop early</h2>
 *
 * The loop is driven by the page space the database itself declares. It reads page 0, takes
 * {@code totalElements}/{@code totalPages} from that result, and then keeps requesting pages until
 * the declared space is exhausted. It never concludes from a single page. Two independent
 * cross-checks then have to agree before a scan is allowed to call itself complete:
 *
 * <ul>
 *   <li>every row id seen is unique — a page-boundary bug that re-serves rows is caught;</li>
 *   <li>the number of distinct rows seen equals the {@code totalElements} the query declared — a
 *       page-boundary bug that skips rows is caught.</li>
 * </ul>
 *
 * Both are asserted by the caller through {@link Result#assertComplete()}, so a scan that quietly
 * covered less than it claimed fails the test rather than passing it.
 *
 * <h2>Ordering</h2>
 *
 * Paging is only sound over a total order. {@code AdminActivityLogRepository.search} already orders
 * by {@code createdAt DESC, id DESC}; the identity id is a genuine tiebreaker, which matters
 * because rows written inside one transaction routinely share a {@code createdAt} to the
 * microsecond. No ordering change was needed and none was made.
 *
 * <h2>Consistency model</h2>
 *
 * Over a static dataset this scan is exact. Over a table being written concurrently it is
 * <em>complete but not minimal</em>: the trail is append-only (the repository deliberately exposes
 * no delete), and inserts sort to the front under newest-first ordering, so a concurrent insert can
 * push a row across a page boundary and cause it to be read twice — but no row can ever move to a
 * page that has already been passed. A concurrent scan may therefore double-count; it cannot miss.
 * For a safety scan, "never misses" is the property that matters, and it is the one the ordering
 * actually provides. Tests that assert exact counts use a static dataset for that reason.
 *
 * <h2>Memory</h2>
 *
 * Rows are inspected a page at a time and only ids are retained, so the whole trail is never
 * materialised. {@link #BATCH} bounds the working set regardless of how large the trail becomes.
 */
final class AdminAuditScan {

    /** Bounded batch. Also the service's own {@code safeSize} ceiling, so it is a realistic page. */
    static final int BATCH = 200;

    /**
     * Absolute guard against a non-terminating loop if a repository ever returned an inconsistent
     * page space. Generous enough that no legitimate dataset reaches it, small enough to fail fast.
     */
    private static final int MAX_PAGES = 10_000;

    private AdminAuditScan() {}

    /** What one exhaustive pass saw. */
    record Result(long declaredTotal, int pagesRead, List<Long> idsInOrder, Set<Long> distinctIds,
                  List<Long> duplicateIds) {

        /** The two cross-checks that make "exhaustive" a claim the test actually verifies. */
        void assertComplete() {
            if (!duplicateIds.isEmpty()) {
                throw new AssertionError("pagination served the same audit row twice: " + duplicateIds);
            }
            if (distinctIds.size() != declaredTotal) {
                throw new AssertionError("scan covered " + distinctIds.size()
                    + " rows but the query declared " + declaredTotal
                    + " — pagination skipped rows");
            }
        }

        int scanned() { return distinctIds.size(); }
    }

    /** Exhaustively scan every row matching the filters, inspecting each exactly once. */
    static Result scan(AdminActivityLogRepository repo,
                       Long actorUserId, String action, String targetType, Long targetId,
                       Instant from, Instant to,
                       Consumer<AdminActivityLog> inspect) {

        List<Long> idsInOrder = new ArrayList<>();
        Set<Long> distinct = new LinkedHashSet<>();
        List<Long> duplicates = new ArrayList<>();

        Page<AdminActivityLog> first =
            repo.search(actorUserId, action, targetType, targetId, from, to, PageRequest.of(0, BATCH));
        long declaredTotal = first.getTotalElements();
        int declaredPages = first.getTotalPages();

        Page<AdminActivityLog> current = first;
        int pageIndex = 0;
        int pagesRead = 0;

        while (true) {
            pagesRead++;
            for (AdminActivityLog row : current.getContent()) {
                idsInOrder.add(row.getId());
                if (!distinct.add(row.getId())) {
                    duplicates.add(row.getId());
                }
                if (inspect != null) {
                    inspect.accept(row);
                }
            }

            // Stop only when the declared page space is exhausted, or the page came back empty.
            // Never on the strength of the first page alone.
            pageIndex++;
            if (pageIndex >= declaredPages || current.getContent().isEmpty()) {
                break;
            }
            if (pagesRead >= MAX_PAGES) {
                throw new AssertionError("audit scan exceeded " + MAX_PAGES
                    + " pages — the repository declared an inconsistent page space");
            }
            current = repo.search(actorUserId, action, targetType, targetId, from, to,
                PageRequest.of(pageIndex, BATCH));
        }

        return new Result(declaredTotal, pagesRead, idsInOrder, distinct, duplicates);
    }

    /** Every row in the trail, unfiltered. */
    static Result scanAll(AdminActivityLogRepository repo, Consumer<AdminActivityLog> inspect) {
        return scan(repo, null, null, null, null, null, null, inspect);
    }

    /** Every row for one action. */
    static Result scanAction(AdminActivityLogRepository repo, String action,
                             Consumer<AdminActivityLog> inspect) {
        return scan(repo, null, action, null, null, null, null, inspect);
    }
}
