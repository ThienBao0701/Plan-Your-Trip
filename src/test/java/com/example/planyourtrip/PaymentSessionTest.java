package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminActivityLog;
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
import org.springframework.data.domain.PageRequest;
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
 * registers an in-test-only fake {@link PaymentGateway} for the (still-unwired)
 * {@link PaymentProvider#GOOGLE_PAY} provider to prove the abstraction accepts a brand-new
 * provider WITHOUT any change to {@code PaymentGatewayService}/{@code BookingService}/
 * {@code PaymentService} source. (Phase 7.27 gave VNPAY/PAYOS/STRIPE/MOMO real gateways, so
 * this test picks a provider that still has none.)
 */
@SpringBootTest
@AutoConfigureMockMvc
class PaymentSessionTest {

    static final String FAKE_FUTURE_URL_PREFIX = "https://fake-future-provider.test/pay/";

    /** A trivial second gateway registered ONLY for this test's context (see class javadoc). */
    @TestConfiguration
    static class FakeGatewayConfig {
        @Bean
        PaymentGateway fakeFutureGateway() {
            return new PaymentGateway() {
                @Override public PaymentProvider provider() { return PaymentProvider.GOOGLE_PAY; }
                @Override public String createCheckoutUrl(PaymentSession session) {
                    return FAKE_FUTURE_URL_PREFIX + session.getSessionId();
                }
                @Override public CallbackVerification verifyCallback(PaymentSession session, GatewayCallback cb) {
                    if (cb == null || cb.callbackToken() == null
                            || !session.getCallbackToken().equals(cb.callbackToken()))
                        return new CallbackVerification(false, null, null);
                    return new CallbackVerification(true, cb.outcome(),
                        cb.providerReference() != null ? cb.providerReference() : "GPAY-" + session.getSessionId());
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
    // D1d — the admin force-expire is audited; these read the trail back.
    @Autowired AdminActivityLogRepository auditRepo;
    @Autowired UserRepository userRepo;

    private String adminToken;
    private String userToken;
    private String partnerToken;
    private Long roomId;
    private Long adminUserId;

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
        adminUserId = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow().getId();
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
        // Phase 7.27: VNPAY/PAYOS/STRIPE/MOMO now have real registered gateways, so this
        // test uses APPLE_PAY — an enum value that still has no registered gateway.
        mvc.perform(post("/api/payment-sessions")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"provider\":\"APPLE_PAY\"}"))
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
        Long futureBooking = createBooking(userToken, 33);

        JsonNode mockSession = createSession(userToken, mockBooking, "MOCK");
        JsonNode futureSession = createSession(userToken, futureBooking, "GOOGLE_PAY");

        // Correct implementation selected purely by provider key — different checkout URLs.
        assertTrue(mockSession.get("checkoutUrl").asText().startsWith("https://mock-gateway"));
        assertTrue(futureSession.get("checkoutUrl").asText().startsWith(FAKE_FUTURE_URL_PREFIX));
    }

    @Test
    void futureProvider_worksWithoutServiceChange_fullLifecycle() throws Exception {
        Long bookingId = createBooking(userToken, 35);
        // GOOGLE_PAY is only wired via the in-test fake gateway — the service source is untouched.
        JsonNode created = createSession(userToken, bookingId, "GOOGLE_PAY");
        assertEquals("GOOGLE_PAY", created.get("provider").asText());
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
    // D1d — ADMIN FORCE-EXPIRE IS AUDITED
    //
    // Day offsets 82–89 sit at the tail of the seeded 0–89 inventory range, clear of the
    // 3–39 windows this suite already uses and the 40–81 windows PaymentProviderIntegrationTest
    // uses. Every test below builds its own booking and session; none mutates seeded data.
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminExpire_writesOneAuditRow_withActorActionTargetAndTransition() throws Exception {
        Long bookingId = createBooking(userToken, 82);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();
        long sessionRowId = created.get("id").asLong();
        String statusBefore = created.get("status").asText();

        long before = auditCount("PAYMENT_SESSION_EXPIRE");

        JsonNode res = mapper.readTree(mvc.perform(
                post("/api/admin/payment-sessions/" + sessionId + "/expire")
                    .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals("EXPIRED", res.get("status").asText());

        assertEquals(before + 1, auditCount("PAYMENT_SESSION_EXPIRE"),
            "one force-expire must write exactly one audit row");

        AdminActivityLog entry = latestAudit("PAYMENT_SESSION_EXPIRE");
        assertNotNull(entry);
        assertEquals(adminUserId, entry.getActorUserId(), "actor is the acting administrator");
        assertEquals("admin@planyourtrip.com", entry.getActorEmail(), "actor email snapshotted");
        assertEquals("PAYMENT_SESSION", entry.getTargetType());
        assertEquals(sessionRowId, entry.getTargetId(), "target is the session row id");
        assertEquals(statusBefore, entry.getBeforeState(), "records the status it moved from");
        assertEquals("EXPIRED", entry.getAfterState());
        assertNotNull(entry.getCreatedAt(), "timestamp captured");
        assertTrue(entry.getDescription().contains(String.valueOf(bookingId)),
            "the booking id is the safe correlating identifier");
    }

    /**
     * A payment session carries three pieces of material that must never reach the trail: the
     * callback token (a bearer credential), the checkout URL and the provider reference. The
     * public sessionId is excluded too — it is a random 32-hex handle, and free text of that
     * shape can contain a 13-19 digit run that the audit service's card-number backstop rejects,
     * which would abort the transaction and make the session unexpirable.
     */
    @Test
    void adminExpire_auditCarriesNoSessionSecretsOrHandles() throws Exception {
        Long bookingId = createBooking(userToken, 84);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();
        String callbackToken = created.get("callbackToken").asText();
        String checkoutUrl = created.get("checkoutUrl").asText();

        mvc.perform(post("/api/admin/payment-sessions/" + sessionId + "/expire")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());

        AdminActivityLog entry = latestAudit("PAYMENT_SESSION_EXPIRE");
        for (String field : new String[]{entry.getDescription(), entry.getBeforeState(),
                                          entry.getAfterState()}) {
            if (field == null) continue;
            assertFalse(field.contains(callbackToken), "callback token must never be recorded");
            assertFalse(field.contains(checkoutUrl), "checkout URL must never be recorded");
            assertFalse(field.contains(sessionId), "the session handle must not be recorded");
        }
    }

    /**
     * Business failure and audit are one transaction. A session already in a terminal
     * non-expired state is rejected, the exception rolls the transaction back, and no row is
     * left behind describing an expiry that did not happen.
     */
    @Test
    void adminExpire_terminalSession_returns422_andWritesNoAudit() throws Exception {
        Long bookingId = createBooking(userToken, 86);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();

        mvc.perform(post("/api/payment-sessions/" + sessionId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        long before = auditCount("PAYMENT_SESSION_EXPIRE");
        mvc.perform(post("/api/admin/payment-sessions/" + sessionId + "/expire")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isUnprocessableEntity());

        assertEquals(before, auditCount("PAYMENT_SESSION_EXPIRE"),
            "a rejected expire must leave no audit row");
    }

    /**
     * Repeating the call is a no-op on an already-EXPIRED session: the service returns the
     * current state unchanged. Nothing changed, so nothing is recorded — the same rule D1c
     * applied to gift-card activation and loyalty release. This test pins the existing service
     * semantics; it does not introduce a new idempotency rule.
     */
    @Test
    void adminExpire_repeated_isIdempotentAndWritesNoSecondRow() throws Exception {
        Long bookingId = createBooking(userToken, 88);
        JsonNode created = createSession(userToken, bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();

        long before = auditCount("PAYMENT_SESSION_EXPIRE");

        mvc.perform(post("/api/admin/payment-sessions/" + sessionId + "/expire")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
        assertEquals(before + 1, auditCount("PAYMENT_SESSION_EXPIRE"));

        JsonNode replay = mapper.readTree(mvc.perform(
                post("/api/admin/payment-sessions/" + sessionId + "/expire")
                    .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals("EXPIRED", replay.get("status").asText(), "replay returns the current state");

        assertEquals(before + 1, auditCount("PAYMENT_SESSION_EXPIRE"),
            "an idempotent replay must not add a second row");
    }

    @Test
    void adminExpire_unknownSession_returns404_andWritesNoAudit() throws Exception {
        long before = auditCount("PAYMENT_SESSION_EXPIRE");
        mvc.perform(post("/api/admin/payment-sessions/PS-does-not-exist/expire")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound());
        assertEquals(before, auditCount("PAYMENT_SESSION_EXPIRE"));
    }

    @Test
    void adminExpire_isAdminOnly() throws Exception {
        String path = "/api/admin/payment-sessions/PS-any/expire";
        mvc.perform(post(path)).andExpect(status().isUnauthorized());
        mvc.perform(post(path).header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
        mvc.perform(post(path).header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isForbidden());
    }

    private long auditCount(String action) {
        return auditRepo.search(null, action, null, null, null, null, PageRequest.of(0, 1))
            .getTotalElements();
    }

    private AdminActivityLog latestAudit(String action) {
        var page = auditRepo.search(null, action, null, null, null, null, PageRequest.of(0, 1));
        return page.isEmpty() ? null : page.getContent().get(0);
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
