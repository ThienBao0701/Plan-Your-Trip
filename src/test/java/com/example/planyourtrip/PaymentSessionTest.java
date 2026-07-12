package com.example.planyourtrip;

import com.example.planyourtrip.model.CallbackOutcome;
import com.example.planyourtrip.model.PaymentProvider;
import com.example.planyourtrip.model.PaymentSession;
import com.example.planyourtrip.repository.*;
import com.example.planyourtrip.service.gateway.PaymentGateway;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase 7.26 — Payment Gateway Foundation.
 *
 * <p>Exercises the {@code PaymentSession} lifecycle end-to-end through the API. Also
 * registers an in-test-only fake {@link PaymentGateway} for the (previously unwired)
 * {@link PaymentProvider#PAYOS} provider to prove the abstraction accepts a brand-new
 * provider WITHOUT any change to {@code PaymentGatewayService}/{@code BookingService}/
 * {@code PaymentService} source.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PaymentSessionTest {

    static final String FAKE_PAYOS_URL_PREFIX = "https://fake-payos.test/pay/";

    /** A trivial second gateway registered ONLY for this test's context (see class javadoc). */
    @TestConfiguration
    static class FakeGatewayConfig {
        @Bean
        PaymentGateway fakePayosGateway() {
            return new PaymentGateway() {
                @Override public PaymentProvider provider() { return PaymentProvider.PAYOS; }
                @Override public String createCheckoutUrl(PaymentSession session) {
                    return FAKE_PAYOS_URL_PREFIX + session.getSessionId();
                }
                @Override public CallbackVerification verifyCallback(PaymentSession session, GatewayCallback cb) {
                    if (cb == null || cb.callbackToken() == null
                            || !session.getCallbackToken().equals(cb.callbackToken()))
                        return new CallbackVerification(false, null, null);
                    return new CallbackVerification(true, cb.outcome(),
                        cb.providerReference() != null ? cb.providerReference() : "PAYOS-" + session.getSessionId());
                }
                @Override public void capture(PaymentSession session) { /* no-op fake */ }
                @Override public void cancel(PaymentSession session) { /* no-op fake */ }
            };
        }
    }

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private String adminToken;
    private String userToken;
    private String partnerToken;
    private Long roomId;

    // Inventory is seeded only for days 0–89. This suite books SUITE-KNG (which other
    // suites barely touch, so its 18/night inventory has ample headroom) on distinct
    // 2-night windows inside that range — each test passes its own start-day offset.
    private static final LocalDate TODAY = LocalDate.now();

    @BeforeEach
    void setup() throws Exception {
        adminToken   = login("admin@planyourtrip.com",   "admin123456");
        userToken    = login("demo@planyourtrip.com",    "demo123456");
        partnerToken = login("partner@planyourtrip.com", "partner123456");

        Long placeId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        roomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "SUITE-KNG".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void session_create_returns201_pendingWithCheckoutUrl() throws Exception {
        Long bookingId = createBooking(userToken, 3);
        JsonNode res = createSession(userToken, bookingId, "MOCK");

        assertNotNull(res.get("id"));
        assertTrue(res.get("sessionId").asText().startsWith("PS-"));
        assertEquals("MOCK", res.get("provider").asText());
        assertEquals("PENDING", res.get("status").asText());
        assertEquals(bookingId, res.get("bookingId").asLong());
        assertTrue(res.get("checkoutUrl").asText().startsWith("https://mock-gateway"));
        assertFalse(res.get("callbackToken").asText().isBlank());
        assertTrue(res.get("amount").asDouble() > 0);
    }

    @Test
    void session_create_rejectsOtherUsersBooking_returns403() throws Exception {
        Long bookingId = createBooking(userToken, 5);
        mvc.perform(post("/api/payment-sessions")
                .header("Authorization", "Bearer " + partnerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"provider\":\"MOCK\"}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void session_create_unregisteredProvider_returns400() throws Exception {
        Long bookingId = createBooking(userToken, 7);
        // VNPAY exists in the enum but has no registered gateway in this phase.
        mvc.perform(post("/api/payment-sessions")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"provider\":\"VNPAY\"}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void session_create_unauthenticated_returns401() throws Exception {
        mvc.perform(post("/api/payment-sessions")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":1,\"provider\":\"MOCK\"}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // BOOKING LINKAGE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void session_referencesItsBooking() throws Exception {
        Long bookingId = createBooking(userToken, 9);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();

        JsonNode fetched = mapper.readTree(mvc.perform(get("/api/payment-sessions/" + sessionId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());

        assertEquals(bookingId, fetched.get("bookingId").asLong());
        assertFalse(fetched.get("bookingCode").asText().isBlank());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTHORIZE / CAPTURE / FAIL / CANCEL / EXPIRE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void session_callbackAuthorize_setsAuthorized() throws Exception {
        Long bookingId = createBooking(userToken, 11);
        JsonNode created = createSession(userToken, bookingId, "MOCK");

        JsonNode res = callback(created, CallbackOutcome.AUTHORIZED, "TXN-AUTH-1");
        assertEquals("AUTHORIZED", res.get("status").asText());
        assertEquals("TXN-AUTH-1", res.get("providerReference").asText());
    }

    @Test
    void session_capture_afterAuthorize_setsCaptured() throws Exception {
        Long bookingId = createBooking(userToken, 13);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        callback(created, CallbackOutcome.AUTHORIZED, null);

        String sessionId = created.get("sessionId").asText();
        JsonNode res = mapper.readTree(mvc.perform(post("/api/payment-sessions/" + sessionId + "/capture")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals("CAPTURED", res.get("status").asText());
    }

    @Test
    void session_capture_beforeAuthorize_returns422() throws Exception {
        Long bookingId = createBooking(userToken, 15);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();
        // Still PENDING — cannot capture.
        mvc.perform(post("/api/payment-sessions/" + sessionId + "/capture")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void session_callbackFail_setsFailed() throws Exception {
        Long bookingId = createBooking(userToken, 17);
        JsonNode created = createSession(userToken, bookingId, "MOCK");

        JsonNode res = callback(created, CallbackOutcome.FAILED, null);
        assertEquals("FAILED", res.get("status").asText());
    }

    @Test
    void session_cancel_setsCancelled() throws Exception {
        Long bookingId = createBooking(userToken, 19);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();

        JsonNode res = mapper.readTree(mvc.perform(post("/api/payment-sessions/" + sessionId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals("CANCELLED", res.get("status").asText());
    }

    @Test
    void session_expire_setsExpired() throws Exception {
        Long bookingId = createBooking(userToken, 21);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();

        // Admin force-expire (simulates a provider timeout).
        JsonNode res = mapper.readTree(mvc.perform(post("/api/admin/payment-sessions/" + sessionId + "/expire")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals("EXPIRED", res.get("status").asText());
    }

    @Test
    void session_captureAfterCancel_returns422() throws Exception {
        Long bookingId = createBooking(userToken, 23);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();

        mvc.perform(post("/api/payment-sessions/" + sessionId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());
        // Terminal → cannot capture.
        mvc.perform(post("/api/payment-sessions/" + sessionId + "/capture")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // IDEMPOTENCY + SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void session_duplicateCallback_isIdempotentNoOp() throws Exception {
        Long bookingId = createBooking(userToken, 25);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();

        JsonNode first = callback(created, CallbackOutcome.AUTHORIZED, "TXN-DUP");
        assertEquals("AUTHORIZED", first.get("status").asText());
        JsonNode second = callback(created, CallbackOutcome.AUTHORIZED, "TXN-DUP");
        assertEquals("AUTHORIZED", second.get("status").asText());

        // Exactly one AUTHORIZED lifecycle event was recorded — no duplicate transition.
        JsonNode events = mapper.readTree(mvc.perform(get("/api/payment-sessions/" + sessionId + "/events")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        int authorizedEvents = 0;
        for (JsonNode e : events) if ("AUTHORIZED".equals(e.get("eventType").asText())) authorizedEvents++;
        assertEquals(1, authorizedEvents, "duplicate callback must not create a second AUTHORIZED event");
    }

    @Test
    void session_invalidCallbackToken_returns403() throws Exception {
        Long bookingId = createBooking(userToken, 27);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();

        mvc.perform(post("/api/payment-sessions/" + sessionId + "/callback")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"callbackToken\":\"WRONG-TOKEN\",\"outcome\":\"AUTHORIZED\"}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void session_callbackOnTerminal_isNoOp() throws Exception {
        Long bookingId = createBooking(userToken, 29);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        callback(created, CallbackOutcome.FAILED, null); // terminal now

        // A late AUTHORIZED callback on a FAILED session is a safe no-op — stays FAILED.
        JsonNode res = callback(created, CallbackOutcome.AUTHORIZED, "LATE");
        assertEquals("FAILED", res.get("status").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PROVIDER ABSTRACTION + FUTURE PROVIDER COMPATIBILITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void providerAbstraction_selectsCorrectGatewayWithoutBranching() throws Exception {
        Long mockBooking = createBooking(userToken, 31);
        Long payosBooking = createBooking(userToken, 33);

        JsonNode mockSession = createSession(userToken, mockBooking, "MOCK");
        JsonNode payosSession = createSession(userToken, payosBooking, "PAYOS");

        // Correct implementation selected purely by provider key — different checkout URLs.
        assertTrue(mockSession.get("checkoutUrl").asText().startsWith("https://mock-gateway"));
        assertTrue(payosSession.get("checkoutUrl").asText().startsWith(FAKE_PAYOS_URL_PREFIX));
    }

    @Test
    void futureProvider_worksWithoutServiceChange_fullLifecycle() throws Exception {
        Long bookingId = createBooking(userToken, 35);
        // PAYOS is only wired via the in-test fake gateway — the service source is untouched.
        JsonNode created = createSession(userToken, bookingId, "PAYOS");
        assertEquals("PAYOS", created.get("provider").asText());
        assertEquals("PENDING", created.get("status").asText());

        JsonNode authorized = callback(created, CallbackOutcome.AUTHORIZED, null);
        assertEquals("AUTHORIZED", authorized.get("status").asText());

        String sessionId = created.get("sessionId").asText();
        JsonNode captured = mapper.readTree(mvc.perform(post("/api/payment-sessions/" + sessionId + "/capture")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals("CAPTURED", captured.get("status").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_listSessions_returns200_userForbidden() throws Exception {
        Long bookingId = createBooking(userToken, 37);
        createSession(userToken, bookingId, "MOCK");

        mvc.perform(get("/api/admin/payment-sessions")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());

        mvc.perform(get("/api/admin/payment-sessions")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void admin_processExpirations_returns200() throws Exception {
        String body = mvc.perform(post("/api/admin/payment-sessions/process-expirations")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(mapper.readTree(body).get("expiredCount").asInt() >= 0);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private JsonNode createSession(String token, Long bookingId, String provider) throws Exception {
        String body = mvc.perform(post("/api/payment-sessions")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"provider\":\"" + provider + "\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode callback(JsonNode createdSession, CallbackOutcome outcome, String providerReference)
            throws Exception {
        String sessionId = createdSession.get("sessionId").asText();
        String token = createdSession.get("callbackToken").asText();
        String refJson = providerReference != null ? ",\"providerReference\":\"" + providerReference + "\"" : "";
        String body = mvc.perform(post("/api/payment-sessions/" + sessionId + "/callback")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"callbackToken\":\"" + token + "\",\"outcome\":\"" + outcome.name() + "\"" + refJson + "}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    /** Books a distinct 2-night window inside the seeded 0–89 day inventory range. */
    private Long createBooking(String token, int startDayOffset) throws Exception {
        LocalDate ci = TODAY.plusDays(startDayOffset);
        LocalDate co = ci.plusDays(2);
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":1,\"children\":0,\"numberOfRooms\":1}",
                    roomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }
}
