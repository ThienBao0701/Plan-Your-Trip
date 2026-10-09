package com.example.planyourtrip.support;

import com.example.planyourtrip.model.AdminProfileAssignment;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdminProfileAssignmentRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.rbac.AdminProfile;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.Instant;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

/**
 * Test fixture — moves a property to a company the only way RBAC R6 allows: an A16 dual-control request submitted by
 * one platform owner and approved by a second (RBAC V1.1 §22.6).
 *
 * <p>Tests whose subject is not dual control (partner fixtures, PA-4) use {@link #assignOwner}: the caller's token
 * submits, and a second platform owner this fixture creates once per application context approves with a freshly
 * issued (step-up fresh) token. The workflow itself is covered by {@code AdminDualControlTest}.
 */
@Component
public class DualControlTestSupport {

    private static final String APPROVER_PASSWORD = "Dual-control-approver-Pw1";

    private final UserRepository users;
    private final AdminProfileAssignmentRepository assignments;
    private final PasswordEncoder encoder;
    private final ObjectMapper mapper;
    private String approverEmail;

    public DualControlTestSupport(UserRepository users, AdminProfileAssignmentRepository assignments,
                                  PasswordEncoder encoder, ObjectMapper mapper) {
        this.users = users;
        this.assignments = assignments;
        this.encoder = encoder;
        this.mapper = mapper;
    }

    /**
     * Submits {@code POST /api/admin/hotels/{hotelId}/assign-owner} as {@code requesterToken} and approves it as a
     * second platform owner. Returns the executed move's property ({@code result} of the approval).
     */
    public JsonNode assignOwner(MockMvc mvc, String requesterToken, Long hotelId, Long partnerProfileId)
            throws Exception {
        MvcResult submitted = mvc.perform(post("/api/admin/hotels/" + hotelId + "/assign-owner")
                .header("Authorization", "Bearer " + requesterToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"partnerProfileId\":" + partnerProfileId + "}"))
            .andReturn();
        expect(202, submitted);
        long requestId = mapper.readTree(submitted.getResponse().getContentAsString()).get("id").asLong();
        MvcResult approved = mvc.perform(post("/api/admin/dual-control/requests/" + requestId + "/approve")
                .header("Authorization", "Bearer " + approverToken(mvc)))
            .andReturn();
        expect(200, approved);
        return mapper.readTree(approved.getResponse().getContentAsString()).get("result");
    }

    /** A second, enabled {@code PLATFORM_OWNER}, signed in now (so the token is step-up fresh). */
    public synchronized String approverToken(MockMvc mvc) throws Exception {
        if (approverEmail == null || users.findByEmail(approverEmail).isEmpty()) {
            User u = new User();
            u.setFullName("Dual Control Approver");
            u.setEmail("dual-control-approver-" + UUID.randomUUID().toString().substring(0, 8) + "@test.com");
            u.setPasswordHash(encoder.encode(APPROVER_PASSWORD));
            u.setRole("ADMIN");
            u.setEmailVerifiedAt(Instant.now());
            users.save(u);
            assignments.save(AdminProfileAssignment.systemGrant(u, AdminProfile.PLATFORM_OWNER, Instant.now()));
            approverEmail = u.getEmail();
        }
        MvcResult login = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + approverEmail + "\",\"password\":\"" + APPROVER_PASSWORD + "\"}"))
            .andReturn();
        expect(200, login);
        return mapper.readTree(login.getResponse().getContentAsString()).get("token").asText();
    }

    private static void expect(int status, MvcResult result) throws Exception {
        if (result.getResponse().getStatus() != status) {
            throw new AssertionError(result.getRequest().getMethod() + " " + result.getRequest().getRequestURI()
                + " -> " + result.getResponse().getStatus() + " " + result.getResponse().getContentAsString());
        }
    }
}
