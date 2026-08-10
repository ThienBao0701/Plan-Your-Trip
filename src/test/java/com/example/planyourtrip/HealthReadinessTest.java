package com.example.planyourtrip;

import com.example.planyourtrip.controller.HealthController;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * DB-06 — verifies the DB-backed readiness probe on {@link HealthController}. The controller is
 * constructed directly with a mocked {@link JdbcTemplate} (no Spring context, no real database) so both
 * the reachable and unreachable branches are exercised deterministically. Mockito ships with
 * spring-boot-starter-test.
 */
class HealthReadinessTest {

    @Test
    void readyReturns200UpWhenDatabaseReachable() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        when(jdbc.queryForObject(eq("SELECT 1"), eq(Integer.class))).thenReturn(1);

        ResponseEntity<Map<String, String>> res = new HealthController(jdbc).ready();

        assertEquals(HttpStatus.OK, res.getStatusCode());
        assertEquals("UP", res.getBody().get("status"));
        assertEquals("UP", res.getBody().get("db"));
    }

    @Test
    void readyReturns503DownWhenDatabaseUnreachable() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        when(jdbc.queryForObject(eq("SELECT 1"), eq(Integer.class)))
                .thenThrow(new DataAccessResourceFailureException("db down"));

        ResponseEntity<Map<String, String>> res = new HealthController(jdbc).ready();

        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, res.getStatusCode());
        assertEquals("DOWN", res.getBody().get("status"));
        assertEquals("DOWN", res.getBody().get("db"));
    }

    @Test
    void livenessStaysStaticUp() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        Map<String, String> body = new HealthController(jdbc).health();
        assertEquals("UP", body.get("status"));
        assertEquals("Plan Your Trip Backend", body.get("app"));
    }
}
