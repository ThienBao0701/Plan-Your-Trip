package com.example.planyourtrip.controller;

import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/health")
public class HealthController {

    private final JdbcTemplate jdbc;

    public HealthController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** Liveness — UP whenever the process can serve requests. No dependency checks (unchanged shape). */
    @GetMapping
    public Map<String, String> health() {
        return Map.of("status", "UP", "app", "Plan Your Trip Backend");
    }

    /**
     * DB-06 — readiness. Executes a trivial {@code SELECT 1} so an orchestrator gets a REAL signal:
     * HTTP 200 {@code {"status":"UP","db":"UP"}} only when the database is reachable, otherwise HTTP 503
     * {@code {"status":"DOWN","db":"DOWN"}}. Works on both H2 (dev/test) and SQL Server (prod) and pulls
     * in NO Spring Boot Actuator dependency. Distinct from liveness above so a transient DB outage marks
     * the instance not-ready without killing it.
     */
    @GetMapping("/ready")
    public ResponseEntity<Map<String, String>> ready() {
        try {
            jdbc.queryForObject("SELECT 1", Integer.class);
            return ResponseEntity.ok(Map.of("status", "UP", "db", "UP"));
        } catch (DataAccessException e) {
            return ResponseEntity.status(503).body(Map.of("status", "DOWN", "db", "DOWN"));
        }
    }
}
