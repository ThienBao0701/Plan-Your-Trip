package com.example.planyourtrip;

import com.example.planyourtrip.config.PaymentProviderProperties;
import com.example.planyourtrip.repository.*;
import com.example.planyourtrip.service.gateway.HmacSignatureVerifier;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase 7.27 — Real Payment Provider Integration.
 *
 * <p>Drives the four real provider adapters (VNPay, PayOS, Stripe, MoMo) end-to-end through
 * their SIGNED webhook receivers and verifies the bridge into the EXISTING {@code Payment}
 * settlement flow:
 * <ul>
 *   <li>a valid signed success webhook → session CAPTURED → real {@code Payment} PAID +
 *       booking CONFIRMED (proving {@code PaymentService.mockSuccess} fired);</li>
 *   <li>duplicate webhook delivery is an idempotent no-op (one PAID payment, one CAPTURED
 *       event);</li>
 *   <li>a failure webhook → session FAILED → real {@code Payment} FAILED (proving
 *       {@code PaymentService.mockFail} fired);</li>
 *   <li>an invalid signature is rejected and leaves the session untouched;</li>
 *   <li>provider isolation — a payload for one provider cannot drive another provider's
 *       session;</li>
 *   <li>cancellation / expiry bridge to the failure settlement;</li>
 *   <li>rollback — a settlement that throws rolls the whole session transition back.</li>
 * </ul>
 *
 * All signatures are computed with the SAME {@link HmacSignatureVerifier} the adapters use,
 * so verification is exercised for real; only the outbound checkout-API call is mocked.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PaymentProviderIntegrationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PaymentProviderProperties props;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private String userToken;
    private String adminToken;
    private Long roomId;

    private static final LocalDate TODAY = LocalDate.now();

    @BeforeEach
    void setup() throws Exception {
        userToken  = login("demo@planyourtrip.com",  "demo123456");
        adminToken = login("admin@planyourtrip.com", "admin123456");

        Long placeId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        roomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "SUITE-KNG".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SUCCESS — each provider's signed webhook settles the real Payment
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void vnpay_signedWebhookSuccess_capturesSession_andSettlesPaymentPaid() throws Exception {
        Long bookingId = createBooking(40);
        String sessionId = createSession(bookingId, "VNPAY");

        JsonNode ack = postWebhook("vnpay", vnpayBody(sessionId, "00"), null, null);
        assertTrue(ack.get("processed").asBoolean());
        assertEquals("CAPTURED", ack.get("status").asText());

        assertPaymentSettled(bookingId, "PAID", "VNPAY");
        assertBookingStatus(bookingId, "CONFIRMED");
    }

    @Test
    void stripe_signedWebhookSuccess_settlesPaymentPaid() throws Exception {
        Long bookingId = createBooking(43);
        String sessionId = createSession(bookingId, "STRIPE");

        String body = mapper.writeValueAsString(orderedMap(
            "sessionId", sessionId, "status", "succeeded", "reference", "pi_TEST_1"));
        String ts = "1700000000";
        String sig = HmacSignatureVerifier.hmacHex(HmacSignatureVerifier.HMAC_SHA256,
            props.getStripe().getWebhookSecret(), ts + "." + body);
        String header = "t=" + ts + ",v1=" + sig;

        JsonNode ack = postWebhook("stripe", body, header, null);
        assertTrue(ack.get("processed").asBoolean());
        assertEquals("CAPTURED", ack.get("status").asText());

        assertPaymentSettled(bookingId, "PAID", "STRIPE");
        assertBookingStatus(bookingId, "CONFIRMED");
    }

    @Test
    void payos_signedWebhookSuccess_settlesPaymentPaid() throws Exception {
        Long bookingId = createBooking(46);
        String sessionId = createSession(bookingId, "PAYOS");

        JsonNode ack = postWebhook("payos", payosBody(sessionId, "00"), null, null);
        assertTrue(ack.get("processed").asBoolean());
        assertEquals("CAPTURED", ack.get("status").asText());

        assertPaymentSettled(bookingId, "PAID", "PAYOS");
        assertBookingStatus(bookingId, "CONFIRMED");
    }

    @Test
    void momo_signedWebhookSuccess_settlesPaymentPaid() throws Exception {
        Long bookingId = createBooking(49);
        String sessionId = createSession(bookingId, "MOMO");

        JsonNode ack = postWebhook("momo", momoBody(sessionId, "0"), null, null);
        assertTrue(ack.get("processed").asBoolean());
        assertEquals("CAPTURED", ack.get("status").asText());

        assertPaymentSettled(bookingId, "PAID", "MOMO");
        assertBookingStatus(bookingId, "CONFIRMED");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // IDEMPOTENCY — duplicate webhook delivery is a safe no-op
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void webhook_duplicateDelivery_isIdempotent_oneePaymentOneCapturedEvent() throws Exception {
        Long bookingId = createBooking(52);
        String sessionId = createSession(bookingId, "VNPAY");
        String body = vnpayBody(sessionId, "00");

        JsonNode first = postWebhook("vnpay", body, null, null);
        assertTrue(first.get("processed").asBoolean());
        JsonNode second = postWebhook("vnpay", body, null, null);
        assertFalse(second.get("processed").asBoolean(), "redelivery must be a no-op");
        assertEquals("CAPTURED", second.get("status").asText());

        // Exactly one PAID payment for the booking.
        JsonNode payments = getJson("/api/bookings/" + bookingId + "/payments", userToken);
        int paid = 0;
        for (JsonNode p : payments) if ("PAID".equals(p.get("status").asText())) paid++;
        assertEquals(1, paid, "duplicate webhook must not create a second PAID payment");

        // Exactly one CAPTURED lifecycle event.
        JsonNode events = getJson("/api/admin/payment-sessions/" + sessionId + "/events", adminToken);
        int captured = 0;
        for (JsonNode e : events) if ("CAPTURED".equals(e.get("eventType").asText())) captured++;
        assertEquals(1, captured, "duplicate webhook must not create a second CAPTURED event");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // FAILURE — signed failure webhook bridges to the real failure settlement
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void webhook_failureOutcome_marksSessionFailed_andSettlesPaymentFailed() throws Exception {
        Long bookingId = createBooking(55);
        String sessionId = createSession(bookingId, "VNPAY");

        JsonNode ack = postWebhook("vnpay", vnpayBody(sessionId, "24"), null, null); // 24 = customer cancelled
        assertTrue(ack.get("processed").asBoolean());
        assertEquals("FAILED", ack.get("status").asText());

        assertPaymentSettled(bookingId, "FAILED", "VNPAY");
        assertBookingStatus(bookingId, "PENDING"); // failure leaves the booking unconfirmed
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // INVALID SIGNATURE — rejected, session untouched
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void webhook_invalidSignature_returns400_sessionStaysPending_noPayment() throws Exception {
        Long bookingId = createBooking(58);
        String sessionId = createSession(bookingId, "VNPAY");

        // Valid body but a tampered signature.
        Map<String, String> fields = vnpayFields(sessionId, "00");
        fields.put("vnp_SecureHash", "deadbeefdeadbeef");
        String body = mapper.writeValueAsString(fields);

        mvc.perform(post("/api/webhooks/payments/vnpay")
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isBadRequest());

        assertSessionStatus(sessionId, "PENDING");
        JsonNode payments = getJson("/api/bookings/" + bookingId + "/payments", userToken);
        assertEquals(0, payments.size(), "an unverified webhook must not create a payment");
    }

    @Test
    void webhook_stripeMissingHeader_returns400() throws Exception {
        Long bookingId = createBooking(61);
        String sessionId = createSession(bookingId, "STRIPE");
        String body = mapper.writeValueAsString(orderedMap(
            "sessionId", sessionId, "status", "succeeded", "reference", "pi_X"));
        // No Stripe-Signature header at all.
        mvc.perform(post("/api/webhooks/payments/stripe")
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isBadRequest());
        assertSessionStatus(sessionId, "PENDING");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PROVIDER ISOLATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void webhook_providerIsolation_validMomoPayloadCannotDriveVnpaySession() throws Exception {
        Long bookingId = createBooking(64);
        String sessionId = createSession(bookingId, "VNPAY");

        // A perfectly MoMo-signed payload targeting a VNPAY session must be rejected: the
        // MoMo gateway verifies its own signature, but the session belongs to VNPAY.
        mvc.perform(post("/api/webhooks/payments/momo")
                .contentType(MediaType.APPLICATION_JSON).content(momoBody(sessionId, "0")))
            .andExpect(status().isBadRequest());

        assertSessionStatus(sessionId, "PENDING");
    }

    @Test
    void webhook_providerIsolation_vnpaySecretDoesNotValidateOnStripe() throws Exception {
        Long bookingId = createBooking(67);
        String sessionId = createSession(bookingId, "STRIPE");
        // Sign the Stripe body with the VNPay secret → Stripe adapter must reject it.
        String body = mapper.writeValueAsString(orderedMap(
            "sessionId", sessionId, "status", "succeeded", "reference", "pi_X"));
        String ts = "1700000000";
        String wrongSig = HmacSignatureVerifier.hmacHex(HmacSignatureVerifier.HMAC_SHA256,
            props.getVnpay().getWebhookSecret(), ts + "." + body);
        mvc.perform(post("/api/webhooks/payments/stripe")
                .header("Stripe-Signature", "t=" + ts + ",v1=" + wrongSig)
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isBadRequest());
        assertSessionStatus(sessionId, "PENDING");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CANCEL / EXPIRE bridge to failure settlement
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownerCancel_settlesFailure_createsFailedPayment() throws Exception {
        Long bookingId = createBooking(70);
        String sessionId = createSession(bookingId, "MOCK");

        mvc.perform(post("/api/payment-sessions/" + sessionId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("CANCELLED"));

        assertPaymentSettled(bookingId, "FAILED", "MOCK");
    }

    @Test
    void adminExpire_settlesFailure_createsFailedPayment() throws Exception {
        Long bookingId = createBooking(73);
        String sessionId = createSession(bookingId, "MOCK");

        mvc.perform(post("/api/admin/payment-sessions/" + sessionId + "/expire")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("EXPIRED"));

        assertPaymentSettled(bookingId, "FAILED", "MOCK");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MANUAL CAPTURE path also bridges (simulation callback → owner capture → settle)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownerCapture_afterSimulationCallback_settlesRealPaymentPaid() throws Exception {
        Long bookingId = createBooking(76);
        JsonNode created = createSessionJson(bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();
        String callbackToken = created.get("callbackToken").asText();

        // Authorize via the Phase-7.26 token-gated simulation callback.
        mvc.perform(post("/api/payment-sessions/" + sessionId + "/callback")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"callbackToken\":\"" + callbackToken + "\",\"outcome\":\"AUTHORIZED\"}"))
            .andExpect(status().isOk());

        // Owner capture → CAPTURED → bridge to real settlement.
        mvc.perform(post("/api/payment-sessions/" + sessionId + "/capture")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("CAPTURED"));

        assertPaymentSettled(bookingId, "PAID", "MOCK");
        assertBookingStatus(bookingId, "CONFIRMED");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ROLLBACK — a settlement that throws rolls the session transition back atomically
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void rollback_settlementFailure_rollsBackCaptureTransition() throws Exception {
        Long bookingId = createBooking(79);
        JsonNode created = createSessionJson(bookingId, "MOCK");
        String sessionId = created.get("sessionId").asText();
        String callbackToken = created.get("callbackToken").asText();

        // Authorize (no settlement yet — authorize does not bridge).
        mvc.perform(post("/api/payment-sessions/" + sessionId + "/callback")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"callbackToken\":\"" + callbackToken + "\",\"outcome\":\"AUTHORIZED\"}"))
            .andExpect(status().isOk());

        // Cancel the BOOKING so the real PaymentService.createPayment will reject settlement.
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        // Capture now drives CAPTURED then bridges → createPayment throws 422 → whole
        // transaction rolls back.
        mvc.perform(post("/api/payment-sessions/" + sessionId + "/capture")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isUnprocessableEntity());

        // Session was NOT captured, no CAPTURED event, no payment row survived.
        assertSessionStatus(sessionId, "AUTHORIZED");
        JsonNode events = getJson("/api/admin/payment-sessions/" + sessionId + "/events", adminToken);
        for (JsonNode e : events)
            assertNotEquals("CAPTURED", e.get("eventType").asText(), "CAPTURED event must have rolled back");
        JsonNode payments = getJson("/api/bookings/" + bookingId + "/payments", userToken);
        assertEquals(0, payments.size(), "no payment row may survive a rolled-back settlement");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UNKNOWN PROVIDER
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void webhook_unknownProvider_returns400() throws Exception {
        mvc.perform(post("/api/webhooks/payments/not-a-provider")
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SIGNED-PAYLOAD BUILDERS (mirror each adapter's real algorithm)
    // ═══════════════════════════════════════════════════════════════════════════

    private Map<String, String> vnpayFields(String sessionId, String responseCode) {
        Map<String, String> f = new LinkedHashMap<>();
        f.put("vnp_TxnRef", sessionId);
        f.put("vnp_ResponseCode", responseCode);
        f.put("vnp_TransactionNo", "VNP-" + sessionId);
        f.put("vnp_Amount", "1000000");
        return f;
    }

    private String vnpayBody(String sessionId, String responseCode) throws Exception {
        Map<String, String> f = vnpayFields(sessionId, responseCode);
        String canonical = HmacSignatureVerifier.sortedFormEncoded(f);
        String sig = HmacSignatureVerifier.hmacHex(HmacSignatureVerifier.HMAC_SHA512,
            props.getVnpay().getWebhookSecret(), canonical);
        f.put("vnp_SecureHash", sig);
        return mapper.writeValueAsString(f);
    }

    private String payosBody(String sessionId, String code) throws Exception {
        Map<String, String> data = new LinkedHashMap<>();
        data.put("sessionId", sessionId);
        data.put("code", code);
        data.put("reference", "PAYOS-" + sessionId);
        data.put("amount", "1000000");
        String canonical = HmacSignatureVerifier.sortedFormEncoded(data);
        String sig = HmacSignatureVerifier.hmacHex(HmacSignatureVerifier.HMAC_SHA256,
            props.getPayos().getWebhookSecret(), canonical);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("data", data);
        body.put("signature", sig);
        return mapper.writeValueAsString(body);
    }

    private String momoBody(String sessionId, String resultCode) throws Exception {
        Map<String, String> f = new LinkedHashMap<>();
        f.put("accessKey", "test-access-key");
        f.put("amount", "1000000");
        f.put("extraData", "");
        f.put("message", "ok");
        f.put("orderId", sessionId);
        f.put("orderInfo", "booking");
        f.put("orderType", "momo_wallet");
        f.put("partnerCode", "MOMOTEST");
        f.put("payType", "qr");
        f.put("requestId", "req-" + sessionId);
        f.put("responseTime", "1700000000000");
        f.put("resultCode", resultCode);
        f.put("transId", "MOMO-" + sessionId);
        String raw = "accessKey=" + f.get("accessKey")
            + "&amount=" + f.get("amount")
            + "&extraData=" + f.get("extraData")
            + "&message=" + f.get("message")
            + "&orderId=" + f.get("orderId")
            + "&orderInfo=" + f.get("orderInfo")
            + "&orderType=" + f.get("orderType")
            + "&partnerCode=" + f.get("partnerCode")
            + "&payType=" + f.get("payType")
            + "&requestId=" + f.get("requestId")
            + "&responseTime=" + f.get("responseTime")
            + "&resultCode=" + f.get("resultCode")
            + "&transId=" + f.get("transId");
        String sig = HmacSignatureVerifier.hmacHex(HmacSignatureVerifier.HMAC_SHA256,
            props.getMomo().getWebhookSecret(), raw);
        f.put("signature", sig);
        return mapper.writeValueAsString(f);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private JsonNode postWebhook(String provider, String body, String stripeHeader, String xSignature)
            throws Exception {
        var req = post("/api/webhooks/payments/" + provider)
            .contentType(MediaType.APPLICATION_JSON).content(body);
        if (stripeHeader != null) req = req.header("Stripe-Signature", stripeHeader);
        if (xSignature != null) req = req.header("X-Signature", xSignature);
        String res = mvc.perform(req).andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(res);
    }

    private void assertPaymentSettled(Long bookingId, String status, String provider) throws Exception {
        JsonNode payments = getJson("/api/bookings/" + bookingId + "/payments", userToken);
        boolean found = false;
        for (JsonNode p : payments) {
            if (status.equals(p.get("status").asText())) {
                found = true;
                assertEquals(provider, p.get("provider").asText(),
                    "settled payment should record the session's provider");
            }
        }
        assertTrue(found, "expected a " + status + " payment for booking " + bookingId);
    }

    private void assertBookingStatus(Long bookingId, String status) throws Exception {
        JsonNode b = getJson("/api/bookings/" + bookingId, userToken);
        assertEquals(status, b.get("status").asText());
    }

    private void assertSessionStatus(String sessionId, String status) throws Exception {
        JsonNode s = getJson("/api/payment-sessions/" + sessionId, userToken);
        assertEquals(status, s.get("status").asText());
    }

    private JsonNode getJson(String url, String token) throws Exception {
        String res = mvc.perform(get(url).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(res);
    }

    private String createSession(Long bookingId, String provider) throws Exception {
        return createSessionJson(bookingId, provider).get("sessionId").asText();
    }

    private JsonNode createSessionJson(Long bookingId, String provider) throws Exception {
        String body = mvc.perform(post("/api/payment-sessions")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"provider\":\"" + provider + "\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private Long createBooking(int startDayOffset) throws Exception {
        LocalDate ci = TODAY.plusDays(startDayOffset);
        LocalDate co = ci.plusDays(2);
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":1,\"children\":0,\"numberOfRooms\":1}",
                    roomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private static Map<String, String> orderedMap(String... kv) {
        Map<String, String> m = new LinkedHashMap<>();
        for (int i = 0; i + 1 < kv.length; i += 2) m.put(kv[i], kv[i + 1]);
        return m;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }
}
