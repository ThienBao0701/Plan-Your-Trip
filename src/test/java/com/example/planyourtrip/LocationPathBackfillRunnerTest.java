package com.example.planyourtrip;

import com.example.planyourtrip.config.LocationPathBackfill;
import com.example.planyourtrip.config.LocationPathBackfill.BackfillResult;
import com.example.planyourtrip.config.LocationPathBackfillRunner;
import com.example.planyourtrip.model.AdministrativeUnit;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * D12 — the opt-in half of the backfill's execution model.
 *
 * <p>{@code LocationHierarchyContractTest} proves the default: with no property set, the runner bean
 * does not exist and nothing walks the location table at start. This class proves the other half —
 * that the documented switch actually turns it on — by booting a context with
 * {@code app.location.path-backfill.enabled=true}, which is exactly what an operator does with
 * {@code LOCATION_PATH_BACKFILL_ENABLED=true} for one start.
 *
 * <p>Its own context, because {@code @SpringBootTest} properties are per-class and the point is a
 * differently-configured application.
 */
@SpringBootTest(properties = "app.location.path-backfill.enabled=true")
class LocationPathBackfillRunnerTest {

    @Autowired ApplicationContext ctx;
    @Autowired LocationPathBackfill backfill;
    @Autowired AdministrativeUnitRepository locationRepo;

    @Test
    void theRunnerExistsOnlyWhenTheFlagAsksForIt() {
        assertEquals(1, ctx.getBeanNamesForType(LocationPathBackfillRunner.class).length,
            "the documented property must be all it takes to enable the one-shot pass");
    }

    @Test
    void theStartupPassLeftTheSeededTreeConsistent() {
        // The runner has already executed by the time this test body runs, so a fresh pass must
        // find nothing left to do — which is both the idempotence guarantee and evidence that the
        // startup pass did its work rather than being skipped.
        BackfillResult result = backfill.backfill();
        assertTrue(result.inspected() > 0, "the seeded tree must be reachable from its root");
        assertEquals(0, result.changed(),
            "the pass that ran at startup already corrected anything that needed it");
        assertEquals(result.inspected(), result.unchanged());
        assertTrue(result.unreachable().isEmpty(),
            "no seeded location is orphaned: " + result.unreachable());
    }

    @Test
    void everyReachablePathAgreesWithTheHierarchy() {
        for (AdministrativeUnit u : locationRepo.findAll()) {
            String path = u.getFullPath();
            if (path == null) continue;
            AdministrativeUnit parent = u.getParent();
            String expected = parent == null
                ? u.getName().trim()
                : parent.getFullPath() + " > " + u.getName().trim();
            // Only assert for rows whose parent itself has a path — an unreachable legacy row is
            // reported by the backfill, never rewritten, and is not this assertion's business.
            if (parent != null && parent.getFullPath() == null) continue;
            assertEquals(expected, path,
                "location " + u.getId() + " disagrees with its own ancestry");
        }
        assertFalse(locationRepo.findAll().isEmpty());
        assertEquals(List.of(), backfill.backfill().unreachable());
    }
}
