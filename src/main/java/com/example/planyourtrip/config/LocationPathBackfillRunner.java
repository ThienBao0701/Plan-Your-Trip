package com.example.planyourtrip.config;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * D12 — the explicit, opt-in trigger for {@link LocationPathBackfill}.
 *
 * <h2>Why the trigger is a separate bean</h2>
 *
 * The backfill itself is an ordinary component with no schedule and no lifecycle hook, so it costs
 * nothing to have around. This class is the only thing that ever starts it automatically, and it
 * <b>does not exist unless it is asked for</b>:
 *
 * <pre>
 *   app.location.path-backfill.enabled=true      # env: LOCATION_PATH_BACKFILL_ENABLED=true
 * </pre>
 *
 * <p>{@code matchIfMissing = false} is the important half: with the property absent, unset, or any
 * value other than {@code true}, Spring never creates this bean, so no full-table location walk is
 * attached to application start. That is the default in every environment, production included.
 *
 * <h2>How to run it once</h2>
 *
 * <ol>
 *   <li>set {@code LOCATION_PATH_BACKFILL_ENABLED=true};</li>
 *   <li>start the application once and read the {@code D12: location path backfill inspected …}
 *       summary, plus any {@code WARN} naming locations that could not be derived;</li>
 *   <li>unset the variable.</li>
 * </ol>
 *
 * <p>Leaving it on is harmless but pointless — the pass is idempotent, so every subsequent start
 * would read the table and write nothing. There is deliberately no scheduled task and no recurring
 * job: this is a correction to run when a database needs it, not a permanent part of booting.
 */
@Component
@ConditionalOnProperty(
    name = "app.location.path-backfill.enabled",
    havingValue = "true",
    matchIfMissing = false)
public class LocationPathBackfillRunner implements ApplicationRunner {

    private final LocationPathBackfill backfill;

    public LocationPathBackfillRunner(LocationPathBackfill backfill) {
        this.backfill = backfill;
    }

    @Override
    public void run(ApplicationArguments args) {
        backfill.runOnce();
    }
}
