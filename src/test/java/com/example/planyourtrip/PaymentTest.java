package com.example.planyourtrip;

import com.example.planyourtrip.repository.*;
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

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class PaymentTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired BookingRepository bookingRepo;
    @Autowired PaymentRepository paymentRepo;

    private String adminToken;
    private String userToken;
    private String partnerToken;
    private Long stdTwinRoomId;

    // PaymentTest uses day offsets 45–89 (BookingTest uses 5–44).
    // Seed confirmed booking occupies days 60–61; use DLX-KING for those to avoid clash.
    private static final LocalDate TODAY = LocalDate.now();

    @BeforeEach
    void setup() throws Exception {
        adminToken   = login("admin@planyourtrip.com",   "admin123456");
        userToken    = login("demo@planyourtrip.com",    "demo123456");
        partnerToken = login("partner@planyourtrip.com", "partner123456");

        Long placeId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        stdTwinRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE PAYMENT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void payment_create_success_returns201() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(45), TODAY.plusDays(47), 2);

        String body = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertNotNull(res.get("id"));
        assertNotNull(res.get("paymentCode"));
        assertTrue(res.get("paymentCode").asText().startsWith("PAY-"));
        assertEquals("PENDING", res.get("status").asText());
        assertEquals("MOCK",    res.get("paymentMethod").asText());
        assertEquals("VND",     res.get("currency").asText());
        assertEquals(bookingId, res.get("bookingId").asLong());
        assertTrue(res.get("amount").asDouble() > 0);
    }

    @Test
    void payment_create_rejectsOtherUserBooking_returns403() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(47), TODAY.plusDays(49), 1);

        // Partner tries to pay for user's booking
        mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + partnerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void payment_create_rejectsCancelledBooking_returns422() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(49), TODAY.plusDays(51), 1);

        // Cancel the booking
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        // Try to pay
        mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void payment_amount_equalsBookingFinalPrice() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(51), TODAY.plusDays(53), 2);

        // Get the booking's finalPrice
        String bookingBody = mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        double finalPrice = mapper.readTree(bookingBody).get("finalPrice").asDouble();

        // Create payment
        String payBody = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        double payAmount = mapper.readTree(payBody).get("amount").asDouble();
        assertEquals(finalPrice, payAmount, 0.01, "Payment amount must equal booking finalPrice");
    }

    @Test
    void payment_duplicatePaid_returns422() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(53), TODAY.plusDays(55), 1);
        Long payId     = createPayment(userToken, bookingId);

        // Mark as PAID
        mvc.perform(post("/api/payments/" + payId + "/mock-success")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        // Try to create another payment for same booking
        mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void payment_create_unauthenticated_returns401() throws Exception {
        mvc.perform(post("/api/payments")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":1,\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MOCK SUCCESS / FAIL
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void payment_mockSuccess_sets_PAID() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(55), TODAY.plusDays(57), 2);
        Long payId     = createPayment(userToken, bookingId);

        String body = mvc.perform(post("/api/payments/" + payId + "/mock-success")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"providerTransactionId\":\"TXN-TEST-001\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("PAID",         res.get("status").asText());
        assertFalse(res.get("paidAt").isNull());
        assertEquals("TXN-TEST-001", res.get("providerTransactionId").asText());
    }

    @Test
    void payment_mockSuccess_confirmsBooking() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(57), TODAY.plusDays(59), 1);
        Long payId     = createPayment(userToken, bookingId);

        mvc.perform(post("/api/payments/" + payId + "/mock-success")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        // Verify booking is now CONFIRMED
        String bookingBody = mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode booking = mapper.readTree(bookingBody);
        assertEquals("CONFIRMED", booking.get("status").asText());
        assertFalse(booking.get("confirmedAt").isNull());
    }

    @Test
    void payment_mockFail_sets_FAILED_bookingRemainsPENDING() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(62), TODAY.plusDays(64), 1);
        Long payId     = createPayment(userToken, bookingId);

        String body = mvc.perform(post("/api/payments/" + payId + "/mock-fail")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"failureReason\":\"Insufficient funds\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("FAILED",              res.get("status").asText());
        assertFalse(res.get("failedAt").isNull());
        assertEquals("Insufficient funds",  res.get("failureReason").asText());

        // Booking remains PENDING
        String bookingBody = mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals("PENDING", mapper.readTree(bookingBody).get("status").asText());
    }

    @Test
    void payment_mockSuccess_alreadyPaid_returns422() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(64), TODAY.plusDays(66), 1);
        Long payId     = createPayment(userToken, bookingId);

        // First success
        mvc.perform(post("/api/payments/" + payId + "/mock-success")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        // Second success on same payment
        mvc.perform(post("/api/payments/" + payId + "/mock-success")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void payment_mockSuccess_adminCanConfirm() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(66), TODAY.plusDays(68), 1);
        Long payId     = createPayment(userToken, bookingId);

        // Admin triggers success
        mvc.perform(post("/api/payments/" + payId + "/mock-success")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // GET PAYMENT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void payment_getOwn_returns200() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(68), TODAY.plusDays(70), 1);
        Long payId     = createPayment(userToken, bookingId);

        String body = mvc.perform(get("/api/payments/" + payId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals(payId, mapper.readTree(body).get("id").asLong());
    }

    @Test
    void payment_userCannotGetOtherPayment_returns403() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(70), TODAY.plusDays(72), 1);
        Long payId     = createPayment(userToken, bookingId);

        // Partner tries to get user's payment
        mvc.perform(get("/api/payments/" + payId)
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void payment_getById_notFound_returns404() throws Exception {
        mvc.perform(get("/api/payments/9999999")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isNotFound());
    }

    @Test
    void payment_adminCanGetAnyPayment_returns200() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(72), TODAY.plusDays(74), 1);
        Long payId     = createPayment(userToken, bookingId);

        mvc.perform(get("/api/payments/" + payId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LIST PAYMENTS BY BOOKING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void payment_listByBooking_returns200() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(74), TODAY.plusDays(76), 1);
        createPayment(userToken, bookingId);

        String body = mvc.perform(get("/api/bookings/" + bookingId + "/payments")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 1);
        assertEquals(bookingId, arr.get(0).get("bookingId").asLong());
    }

    @Test
    void payment_listByBooking_otherUser_returns403() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(76), TODAY.plusDays(78), 1);

        mvc.perform(get("/api/bookings/" + bookingId + "/payments")
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PAYMENT CODE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void payment_code_hasCorrectFormat() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(78), TODAY.plusDays(80), 1);

        String body = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        String code = mapper.readTree(body).get("paymentCode").asText();
        assertTrue(code.matches("PAY-\\d{8}-\\d{6}"),
            "paymentCode must match PAY-YYYYMMDD-NNNNNN but was: " + code);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN APIS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_listPayments_returns200() throws Exception {
        String body = mvc.perform(get("/api/admin/payments")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        // Seeded PAID payment exists
        assertTrue(arr.size() >= 1);
    }

    @Test
    void admin_listPayments_forbiddenForUser_returns403() throws Exception {
        mvc.perform(get("/api/admin/payments")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void admin_getPaymentById_returns200() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(80), TODAY.plusDays(82), 1);
        Long payId     = createPayment(userToken, bookingId);

        String body = mvc.perform(get("/api/admin/payments/" + payId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(payId, res.get("id").asLong());
        assertNotNull(res.get("paymentCode"));
        assertNotNull(res.get("bookingCode"));
    }

    @Test
    void admin_refund_sets_REFUNDED() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(82), TODAY.plusDays(84), 1);
        Long payId     = createPayment(userToken, bookingId);

        // Mark as PAID first
        mvc.perform(post("/api/payments/" + payId + "/mock-success")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        // Admin refunds
        String body = mvc.perform(post("/api/admin/payments/" + payId + "/refund")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"Customer requested refund\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("REFUNDED",                  res.get("status").asText());
        assertFalse(res.get("refundedAt").isNull());
        assertEquals("Customer requested refund", res.get("failureReason").asText());
    }

    @Test
    void admin_refund_requiresAdmin_returns403() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(84), TODAY.plusDays(86), 1);
        Long payId     = createPayment(userToken, bookingId);

        mvc.perform(post("/api/payments/" + payId + "/mock-success")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        // User tries to refund → admin endpoint returns 403
        mvc.perform(post("/api/admin/payments/" + payId + "/refund")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"Self refund\"}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void admin_refund_notPaid_returns422() throws Exception {
        Long bookingId = createBooking(userToken, stdTwinRoomId, TODAY.plusDays(86), TODAY.plusDays(88), 1);
        Long payId     = createPayment(userToken, bookingId);

        // Payment is still PENDING — cannot refund
        mvc.perform(post("/api/admin/payments/" + payId + "/refund")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void admin_getPaymentById_notFound_returns404() throws Exception {
        mvc.perform(get("/api/admin/payments/9999999")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SEED VERIFICATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void seed_paidPaymentExists_forConfirmedBooking() throws Exception {
        String body = mvc.perform(get("/api/admin/payments")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        boolean hasPaid = false;
        for (JsonNode p : arr) {
            if ("PAID".equals(p.get("status").asText())) { hasPaid = true; break; }
        }
        assertTrue(hasPaid, "Seeded PAID payment must exist");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private Long createBooking(String token, Long roomId, LocalDate ci, LocalDate co, int adults)
            throws Exception {
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":%d,\"children\":0,\"numberOfRooms\":1}",
                    roomId, ci, co, adults)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long createPayment(String token, Long bookingId) throws Exception {
        String body = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }
}
