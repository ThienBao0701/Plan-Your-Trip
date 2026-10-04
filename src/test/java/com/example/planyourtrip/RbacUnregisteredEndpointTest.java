package com.example.planyourtrip;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * R1 — the endpoint registry is enforced at runtime, not only by a test (RBAC V1.1 §24 B11, I17). A handler
 * that exists under {@code /api/partner} or {@code /api/admin} but is missing from the registry is refused
 * with 403 before it runs, even for a caller whose system role the URL rule admits.
 *
 * <p>The probe controller below exists only in this test's application context.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Import(RbacUnregisteredEndpointTest.UnregisteredProbe.class)
class RbacUnregisteredEndpointTest {

    @RestController
    static class UnregisteredProbe {
        @GetMapping("/api/partner/rbac-probe")
        Map<String, String> partner() { return Map.of("reached", "partner"); }

        @GetMapping("/api/admin/rbac-probe")
        Map<String, String> admin() { return Map.of("reached", "admin"); }

        @GetMapping("/api/rbac-probe")
        Map<String, String> outside() { return Map.of("reached", "outside"); }
    }

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    @Test
    void anUnregisteredPartnerHandlerIsRefusedForAPartner() throws Exception {
        mvc.perform(get("/api/partner/rbac-probe").header("Authorization", "Bearer " + login("partner@planyourtrip.com", "partner123456")))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("PERMISSION_DENIED"))
            .andExpect(jsonPath("$.reached").doesNotExist());
    }

    @Test
    void anUnregisteredAdminHandlerIsRefusedForAnAdmin() throws Exception {
        mvc.perform(get("/api/admin/rbac-probe").header("Authorization", "Bearer " + login("admin@planyourtrip.com", "admin123456")))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("PERMISSION_DENIED"))
            .andExpect(jsonPath("$.reached").doesNotExist());
    }

    @Test
    void handlersOutsideThePartnerAndAdminTreesAreNotAffected() throws Exception {
        mvc.perform(get("/api/rbac-probe").header("Authorization", "Bearer " + login("demo@planyourtrip.com", "demo123456")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.reached").value("outside"));
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }
}
