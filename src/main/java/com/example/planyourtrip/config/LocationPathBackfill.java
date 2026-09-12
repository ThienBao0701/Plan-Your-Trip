package com.example.planyourtrip.config;

import com.example.planyourtrip.model.AdministrativeUnit;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.service.LocationService;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * D12 — one-time correction of stored {@code AdministrativeUnit.fullPath} values.
 *
 * <h2>Why this exists</h2>
 *
 * Until D12 the admin API stored {@code fullPath} exactly as a caller sent it and never recomputed
 * it — not for a renamed node, and not for any descendant of a moved one. {@code LocationService}
 * now derives the value from the live hierarchy on every write, but rows written before that change
 * can still carry whatever they were given. That matters because the string is not internal: it
 * rides in {@code PlaceDto.LocationRef} on every place response, and the traveller app parses it
 * into the place's province, which is in turn a match key in its hotel-destination and saved-place
 * searches.
 *
 * <h2>How it runs — explicitly, and off by default</h2>
 *
 * This class is <b>only the operation</b>. It holds no schedule, no trigger and no startup hook, so
 * simply having it on the classpath costs nothing: a full-table walk is not attached to every
 * application boot.
 *
 * <p>Running it is opt-in and disabled everywhere unless asked for:
 *
 * <pre>
 *   app.location.path-backfill.enabled=${LOCATION_PATH_BACKFILL_ENABLED:false}
 * </pre>
 *
 * <p>{@link LocationPathBackfillRunner} exists only while that property is {@code true} — the bean
 * is not created at all otherwise — and calls {@link #runOnce()} exactly once during that start. To
 * correct a database, set {@code LOCATION_PATH_BACKFILL_ENABLED=true}, start the application once,
 * read the summary it logs, and unset it again. There is no scheduled task and no recurring job, and
 * production default behaviour is <b>disabled</b>.
 *
 * <p>Nothing about ordering matters. On a fresh database there is nothing to correct — the seeder
 * writes paths with exactly the rule in {@link LocationService#joinPath} — and on an existing one
 * there is no seeding to race with.
 *
 * <h2>Guarantees</h2>
 *
 * <ul>
 *   <li><b>Deterministic</b> — a node's path is a pure function of its ancestors' names.</li>
 *   <li><b>Idempotent</b> — a row is written only when its derived path differs from the stored
 *       one, so a second run reports zero changes and issues zero writes.</li>
 *   <li><b>Cycle-safe</b> — the walk is breadth-first from the roots with a visited set and a hard
 *       depth bound, so malformed legacy data cannot make it loop.</li>
 *   <li><b>Never invents</b> — a row that cannot be reached from any root (an orphan, or a node
 *       inside a cycle) is <b>left exactly as it is</b>, counted, and named in a {@code WARN}. It is
 *       reported rather than guessed at, and rather than aborting application start over data that
 *       predates the guard now preventing it.</li>
 * </ul>
 */
@Component
public class LocationPathBackfill {

    private static final Logger log = LoggerFactory.getLogger(LocationPathBackfill.class);

    /** Mirrors {@code LocationService}'s own bound — the second, independent stop on any walk. */
    private static final int MAX_TREE_DEPTH = 64;

    /** How many unreachable ids to name in the warning before truncating. */
    private static final int MAX_REPORTED_UNREACHABLE = 20;

    private final AdministrativeUnitRepository repo;

    public LocationPathBackfill(AdministrativeUnitRepository repo) {
        this.repo = repo;
    }

    /**
     * Outcome of one pass. Returned rather than only logged so a test can assert the numbers
     * instead of scraping output.
     *
     * @param inspected    rows reachable from a root and therefore evaluated
     * @param changed      rows whose stored path disagreed with the hierarchy and were rewritten
     * @param unchanged    rows already correct
     * @param unreachable  rows not reachable from any root — orphaned or inside a cycle; untouched
     */
    public record BackfillResult(int inspected, int changed, int unchanged,
                                 List<Long> unreachable) {

        /** True when nothing needed correcting and nothing was malformed. */
        public boolean isClean() {
            return changed == 0 && unreachable.isEmpty();
        }
    }

    /**
     * Runs one pass and logs what it did.
     *
     * <p>The single entry point an operator's opt-in start goes through, and the only place the
     * summary is written. Returns the same result a direct caller gets, so nothing is hidden behind
     * the logging.
     */
    public BackfillResult runOnce() {
        BackfillResult result = backfill();
        if (result.inspected() == 0 && result.unreachable().isEmpty()) {
            log.info("D12: location path backfill found no locations — nothing to do.");
            return result;
        }
        log.info("D12: location path backfill inspected {} location(s): {} corrected, {} already "
                + "correct.", result.inspected(), result.changed(), result.unchanged());
        if (!result.unreachable().isEmpty()) {
            List<Long> shown = result.unreachable().size() > MAX_REPORTED_UNREACHABLE
                ? result.unreachable().subList(0, MAX_REPORTED_UNREACHABLE)
                : result.unreachable();
            log.warn("D12: {} location(s) are not reachable from any root and were left untouched "
                    + "— they are orphaned or part of a parent cycle, and their paths cannot be "
                    + "derived. Ids (first {}): {}",
                result.unreachable().size(), shown.size(), shown);
        }
        return result;
    }

    /**
     * Recomputes every reachable location's path from the live hierarchy and persists the rows that
     * were wrong.
     *
     * <p>Reads the table once and walks it in memory: a whole-table read is acceptable for a
     * one-time pass, it keeps the walk to a single query, and it is the only way to tell an
     * unreachable row from an absent one.
     */
    @Transactional
    public BackfillResult backfill() {
        List<AdministrativeUnit> all = repo.findAll();
        if (all.isEmpty()) return new BackfillResult(0, 0, 0, List.of());

        Map<Long, List<AdministrativeUnit>> childrenByParent = new HashMap<>();
        Deque<AdministrativeUnit> queue = new ArrayDeque<>();
        for (AdministrativeUnit u : all) {
            AdministrativeUnit parent = u.getParent();
            if (parent == null) {
                queue.add(u);
            } else {
                // A lazy proxy answers its own identifier without being initialised.
                childrenByParent.computeIfAbsent(parent.getId(), k -> new ArrayList<>()).add(u);
            }
        }

        Set<Long> visited = new LinkedHashSet<>();
        // Each node's freshly derived path, keyed by id. Breadth-first order guarantees a parent is
        // in here before any of its children is read, and reading from this map rather than from
        // the parent entity keeps the derivation independent of when the ORM happens to flush.
        Map<Long, String> derivedById = new HashMap<>();
        int changed = 0;
        int unchanged = 0;

        for (int depth = 0; depth < MAX_TREE_DEPTH && !queue.isEmpty(); depth++) {
            int levelSize = queue.size();
            for (int i = 0; i < levelSize; i++) {
                AdministrativeUnit node = queue.poll();
                if (node == null || node.getId() == null) continue;
                // Guards a cycle that somehow reaches back into an already-visited node.
                if (!visited.add(node.getId())) continue;

                AdministrativeUnit parent = node.getParent();
                String parentPath =
                    parent == null ? null : derivedById.get(parent.getId());
                String derived = LocationService.joinPath(parentPath, node.getName());
                derivedById.put(node.getId(), derived);

                if (!derived.equals(node.getFullPath())) {
                    node.setFullPath(derived);
                    repo.save(node);
                    changed++;
                } else {
                    unchanged++;
                }

                // Children are queued after the parent's path is final, so each level derives from
                // an already-corrected ancestor.
                queue.addAll(childrenByParent.getOrDefault(node.getId(), List.of()));
            }
        }

        List<Long> unreachable = new ArrayList<>();
        for (AdministrativeUnit u : all) {
            if (u.getId() != null && !visited.contains(u.getId())) unreachable.add(u.getId());
        }

        return new BackfillResult(visited.size(), changed, unchanged, List.copyOf(unreachable));
    }
}
