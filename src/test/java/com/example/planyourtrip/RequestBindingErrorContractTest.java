package com.example.planyourtrip;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * H-FIX 2 — Spring request-binding failures must be client errors, not accidental 500s.
 *
 * <p>H showed that a malformed date, a missing required parameter, an unparseable body and a wrong
 * HTTP verb all fell through {@code GlobalExceptionHandler}'s catch-all and were reported as
 * {@code 500 "Unexpected server error"}. That made a caller's mistake indistinguishable from a real
 * fault in logs and alerting. Each now maps to 400 or 405 while keeping the uniform error body.
 *
 * <p>The last two tests are the guard that matters most: this change must not have flattened genuine
 * business errors into 400s.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RequestBindingErrorContractTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    private String partnerToken;

    @BeforeEach
    void setup() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"partner@planyourtrip.com\",\"password\":\"partner123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        partnerToken = mapper.readTree(body).get("token").asText();
    }

    private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder auth(
            org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder b) {
        return b.header("Authorization", "Bearer " + partnerToken);
    }

    /** C3's symptom: {@code hotelId} is a required @RequestParam. Was 500, must be 400. */
    @Test
    void missingRequiredQueryParameter_returns400() throws Exception {
        mvc.perform(auth(get("/api/partner/rooms")))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400))
            .andExpect(jsonPath("$.error").value("Bad Request"))
            .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("hotelId")))
            .andExpect(jsonPath("$.path").exists())
            .andExpect(jsonPath("$.timestamp").exists());
    }

    /** C4/C11's symptom: an unparseable LocalDate. Was 500, must be 400. */
    @Test
    void malformedDateQueryParameter_returns400() throws Exception {
        mvc.perform(auth(get("/api/partner/finance/revenue").param("from", "NOTADATE")))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400))
            .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("from")));
    }

    /** C8's symptom, on a different endpoint and parameter. */
    @Test
    void malformedBookingFilterDate_returns400() throws Exception {
        mvc.perform(auth(get("/api/partner/bookings").param("checkInFrom", "13-45-99")))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    /** A non-numeric path variable where a Long is declared. Was 500, must be 400. */
    @Test
    void nonNumericPathVariable_returns400() throws Exception {
        mvc.perform(auth(get("/api/partner/hotels/abc")))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void malformedJsonBody_returns400() throws Exception {
        mvc.perform(auth(post("/api/partner/bookings/voucher/verify"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{ this is not json "))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400))
            .andExpect(jsonPath("$.message").value(
                org.hamcrest.Matchers.containsString("Malformed request body")));
    }

    /** An unknown enum constant in the body — H's SUPER_PARTNER probe. Was 500, must be 400. */
    @Test
    void unknownEnumInJsonBody_returns400() throws Exception {
        mvc.perform(auth(post("/api/partner/team"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"demo@planyourtrip.com\",\"role\":\"SUPER_PARTNER\"}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    /** The route exists but only for PUT. Was 500, must be 405 with an Allow header. */
    @Test
    void wrongHttpVerb_returns405WithAllowHeader() throws Exception {
        mvc.perform(auth(get("/api/partner/reviews/1/reply")))
            .andExpect(status().isMethodNotAllowed())
            .andExpect(header().exists("Allow"))
            .andExpect(jsonPath("$.status").value(405))
            .andExpect(jsonPath("$.error").value("Method Not Allowed"));
    }

    @Test
    void wrongHttpVerbOnSettings_returns405() throws Exception {
        mvc.perform(auth(delete("/api/partner/settings")))
            .andExpect(status().isMethodNotAllowed())
            .andExpect(jsonPath("$.status").value(405));
    }

    // ─── Regression guards: real business errors keep their own status ────────

    @Test
    void genuineNotFound_stillReturns404() throws Exception {
        mvc.perform(auth(get("/api/partner/hotels/999999")))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    void genuineValidationError_stillReturns400WithFieldMessage() throws Exception {
        mvc.perform(auth(put("/api/partner/reviews/1/reply"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"content\":\"   \"}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.message").value(
                org.hamcrest.Matchers.containsString("content")));
    }

    @Test
    void unauthenticatedRequest_stillReturns401() throws Exception {
        mvc.perform(get("/api/partner/hotels"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.status").value(401));
    }

    @Test
    void forbiddenRole_stillReturns403() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"demo@planyourtrip.com\",\"password\":\"demo123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        String userToken = mapper.readTree(body).get("token").asText();

        mvc.perform(get("/api/partner/hotels").header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.status").value(403));
    }
}
