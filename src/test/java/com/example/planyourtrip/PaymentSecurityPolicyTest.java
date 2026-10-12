package com.example.planyourtrip;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.model.Payment;
import com.example.planyourtrip.model.PaymentMethod;
import com.example.planyourtrip.model.PaymentProvider;
import com.example.planyourtrip.model.PaymentSession;
import com.example.planyourtrip.model.PaymentSessionStatus;
import com.example.planyourtrip.model.PaymentStatus;
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

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Verifies the fail-closed payment policy with simulation explicitly disabled. */
@SpringBootTest(properties = "app.payments.simulation.enabled=false")
@AutoConfigureMockMvc
class PaymentSecurityPolicyTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired BookingRepository bookingRepo;
    @Autowired PaymentRepository paymentRepo;
    @Autowired PaymentSessionRepository sessionRepo;
    @Autowired PaymentSessionEventRepository eventRepo;
    @Autowired NotificationRepository notificationRepo;
    @Autowired UserRepository userRepo;
    @Autowired AdminActivityLogRepository auditRepo;

    private static final AtomicInteger DAY_OFFSET = new AtomicInteger(25);
    private String userToken;
    private Long roomId;
    private Long userId;

    @BeforeEach
    void setup() throws Exception {
        userToken = login("demo@planyourtrip.com", "demo123456");
        userId = userRepo.findByEmail("demo@planyourtrip.com").orElseThrow().getId();
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        roomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "SUITE-KNG".equals(r.getRoomCode())).findFirst().orElseThrow().getId();
    }

    @Test
    void disabledSimulationRejectsBothLegacySettlementRoutesWithoutSideEffects() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPendingPayment(bookingId);
        long notificationsBefore = notificationRepo.findByRecipientUserIdOrderByCreatedAtDesc(userId).size();
        long successfulAuditsBefore = successfulSettlementAuditCount(bookingId, paymentId);

        for (String route : new String[]{"mock-success", "mock-fail"}) {
            mvc.perform(post("/api/payments/" + paymentId + "/" + route)
                    .header("Authorization", "Bearer " + userToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("PAYMENT_SIMULATION_DISABLED"));
        }

        assertEquals("PENDING", paymentRepo.findById(paymentId).orElseThrow().getStatus().name());
        assertEquals(BookingStatus.PENDING, bookingRepo.findById(bookingId).orElseThrow().getStatus());
        assertEquals(notificationsBefore,
            notificationRepo.findByRecipientUserIdOrderByCreatedAtDesc(userId).size());
        assertEquals(successfulAuditsBefore, successfulSettlementAuditCount(bookingId, paymentId),
            "rejected mock settlement must not emit payment settlement or booking confirmation audits");
    }

    @Test
    void disabledSimulationRejectsValidSessionCallbackWithoutSideEffects() throws Exception {
        Long bookingId = createBooking();
        PaymentSession session = createSession(bookingId, PaymentProvider.MOCK, "callback-fixture-secret");
        long eventCount = eventRepo.count();
        long notificationsBefore = notificationRepo.findByRecipientUserIdOrderByCreatedAtDesc(userId).size();
        long successfulAuditsBefore = successfulSettlementAuditCount(bookingId, null);

        mvc.perform(post("/api/payment-sessions/" + session.getSessionId() + "/callback")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"callbackToken\":\"callback-fixture-secret\",\"outcome\":\"AUTHORIZED\"}"))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("PAYMENT_SIMULATION_DISABLED"));

        assertEquals(PaymentSessionStatus.PENDING,
            sessionRepo.findBySessionId(session.getSessionId()).orElseThrow().getStatus());
        assertEquals(eventCount, eventRepo.count());
        assertEquals(BookingStatus.PENDING, bookingRepo.findById(bookingId).orElseThrow().getStatus());
        assertTrue(paymentRepo.findByBookingIdOrderByCreatedAtDesc(bookingId).isEmpty());
        assertEquals(notificationsBefore,
            notificationRepo.findByRecipientUserIdOrderByCreatedAtDesc(userId).size());
        assertEquals(successfulAuditsBefore, successfulSettlementAuditCount(bookingId, null),
            "rejected callback must not emit payment settlement or booking confirmation audits");
    }

    @Test
    void placeholderVnpaySecretCannotSettleThroughWebhook() throws Exception {
        Long bookingId = createBooking();
        PaymentSession session = createSession(bookingId, PaymentProvider.VNPAY, "webhook-fixture-secret");

        Map<String, String> fields = new LinkedHashMap<>();
        fields.put("vnp_TxnRef", session.getSessionId());
        fields.put("vnp_ResponseCode", "00");
        fields.put("vnp_TransactionNo", "KNOWN-PLACEHOLDER-SECRET-ATTEMPT");
        String canonical = HmacSignatureVerifier.sortedFormEncoded(
            fields, "vnp_SecureHash", "vnp_SecureHashType");
        fields.put("vnp_SecureHash", HmacSignatureVerifier.hmacHex(
            HmacSignatureVerifier.HMAC_SHA512, "vnpay-test-secret-not-real", canonical));
        String body = mapper.writeValueAsString(fields);
        long eventCount = eventRepo.count();

        mvc.perform(post("/api/webhooks/payments/vnpay")
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isServiceUnavailable())
            .andExpect(jsonPath("$.code").value("PAYMENT_PROVIDER_UNAVAILABLE"));

        assertEquals(PaymentSessionStatus.PENDING,
            sessionRepo.findBySessionId(session.getSessionId()).orElseThrow().getStatus());
        assertEquals(eventCount, eventRepo.count());
        assertEquals(BookingStatus.PENDING, bookingRepo.findById(bookingId).orElseThrow().getStatus());
        assertTrue(paymentRepo.findByBookingIdOrderByCreatedAtDesc(bookingId).isEmpty());
    }

    @Test
    void unconfiguredMockAdapterIsUnavailableWhenSimulationIsDisabled() throws Exception {
        Long bookingId = createBooking();
        long sessionsBefore = sessionRepo.count();

        mvc.perform(post("/api/payment-sessions")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"provider\":\"MOCK\"}"))
            .andExpect(status().isServiceUnavailable())
            .andExpect(jsonPath("$.code").value("PAYMENT_PROVIDER_UNAVAILABLE"));

        assertEquals(sessionsBefore, sessionRepo.count());
        assertEquals(BookingStatus.PENDING, bookingRepo.findById(bookingId).orElseThrow().getStatus());
    }

    @Test
    void legacyPaymentCreationIsUnavailableWhenSimulationIsDisabled() throws Exception {
        Long bookingId = createBooking();
        long paymentsBefore = paymentRepo.count();

        mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isServiceUnavailable())
            .andExpect(jsonPath("$.code").value("PAYMENT_PROVIDER_UNAVAILABLE"));

        assertEquals(paymentsBefore, paymentRepo.count());
        assertEquals(BookingStatus.PENDING, bookingRepo.findById(bookingId).orElseThrow().getStatus());
    }

    private Long createBooking() throws Exception {
        LocalDate checkIn = LocalDate.now().plusDays(DAY_OFFSET.getAndIncrement());
        LocalDate checkOut = checkIn.plusDays(2);
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":1,\"children\":0,\"numberOfRooms\":1}",
                    roomId, checkIn, checkOut)))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long createPendingPayment(Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId).orElseThrow();
        Payment payment = new Payment();
        payment.setBooking(booking);
        payment.setPaymentMethod(PaymentMethod.MOCK);
        payment.setProvider(PaymentProvider.MOCK);
        payment.setStatus(PaymentStatus.PENDING);
        payment.setAmount(booking.getFinalPrice());
        payment.setCurrency(booking.getCurrency());
        return paymentRepo.save(payment).getId();
    }

    private PaymentSession createSession(Long bookingId, PaymentProvider provider, String token) {
        Booking booking = bookingRepo.findById(bookingId).orElseThrow();
        PaymentSession session = new PaymentSession();
        session.setSessionId("PS-" + java.util.UUID.randomUUID().toString().replace("-", ""));
        session.setProvider(provider);
        session.setBooking(booking);
        session.setAmount(booking.getFinalPrice() == null ? BigDecimal.ZERO : booking.getFinalPrice());
        session.setCurrency(booking.getCurrency());
        session.setStatus(PaymentSessionStatus.PENDING);
        session.setExpiresAt(Instant.now().plusSeconds(1800));
        session.setCallbackToken(token);
        return sessionRepo.save(session);
    }

    private long successfulSettlementAuditCount(Long bookingId, Long paymentId) {
        long count = 0;
        for (String action : new String[]{"PAYMENT_SUCCESS", "PAYMENT_SETTLEMENT", "PAYMENT_SETTLED",
                "PAYMENT_SESSION_SETTLED", "BOOKING_CONFIRMATION", "BOOKING_CONFIRMED"}) {
            if (paymentId != null) {
                count += auditRepo.search(null, action, "PAYMENT", paymentId, null, null,
                    org.springframework.data.domain.PageRequest.of(0, 1)).getTotalElements();
            }
            count += auditRepo.search(null, action, "BOOKING", bookingId, null, null,
                org.springframework.data.domain.PageRequest.of(0, 1)).getTotalElements();
        }
        return count;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }
}
