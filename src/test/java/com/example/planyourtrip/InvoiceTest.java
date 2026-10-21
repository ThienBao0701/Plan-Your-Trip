package com.example.planyourtrip;

import com.example.planyourtrip.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * InvoiceTest — Phase 5.5.
 * Uses the SUITE-KNG room like NotificationTest; each class keeps its own
 * static day cursor so bookings never collide with other test classes.
 */
@SpringBootTest
@AutoConfigureMockMvc
class InvoiceTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired PaymentRepository paymentRepo;
    @Autowired JdbcTemplate jdbc;

    private String adminToken;
    private String userToken;
    private String partnerToken;
    private Long suiteRoomId;

    private static final LocalDate TODAY = LocalDate.now();
    private static final AtomicInteger dayCursor = new AtomicInteger(40);
    // Privacy fixtures stay separate from the legacy 40+ day windows and inside the 90-day seed.
    private static final AtomicInteger privacyDayCursor = new AtomicInteger(10);

    @BeforeEach
    void setup() throws Exception {
        adminToken   = login("admin@planyourtrip.com",   "admin123456");
        userToken    = login("demo@planyourtrip.com",    "demo123456");
        partnerToken = login("partner@planyourtrip.com", "partner123456");

        Long placeId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        suiteRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "SUITE-KNG".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE INVOICE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void invoice_create_forPaidPayment_returns201() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);

        JsonNode res = createInvoice(bookingId, paymentId);

        assertNotNull(res.get("id"));
        assertTrue(res.get("invoiceNumber").asText().matches("INV-\\d{8}-\\d{6}"));
        assertEquals("ISSUED", res.get("status").asText());
        assertEquals(bookingId, res.get("bookingId").asLong());
        assertEquals(paymentId, res.get("paymentId").asLong());
        assertFalse(res.get("issuedAt").isNull());
    }

    @Test
    void invoice_create_rejectsUnpaidPayment_returns422() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId); // still PENDING

        mvc.perform(post("/api/invoices")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format("{\"bookingId\":%d,\"paymentId\":%d}", bookingId, paymentId)))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void invoice_create_foreignAndMissingPaymentsShareGeneric404WithoutSideEffects() throws Exception {
        Long bookingId = createPrivacyBooking(userToken);
        mockSuccess(createPayment(bookingId));
        String other = registerUser("invoice-payment-owner");
        Long foreignBookingId = createPrivacyBooking(other);
        Long foreignPaymentId = createPayment(other, foreignBookingId);
        mockSuccess(other, foreignPaymentId);
        assertFalse(paymentRepo.existsById(Long.MAX_VALUE));
        var before = invoiceSideEffectSnapshot();

        ObjectNode foreign = invoiceCreationError(bookingId, foreignPaymentId, 404);
        assertEquals(before, invoiceSideEffectSnapshot(), "foreign payment rejection must not mutate state");
        ObjectNode missing = invoiceCreationError(bookingId, Long.MAX_VALUE, 404);
        assertEquals(before, invoiceSideEffectSnapshot(), "missing payment rejection must not mutate state");
        ObjectNode expected = mapper.createObjectNode()
            .put("status", 404).put("error", "Not Found").put("message", "Payment not found");
        assertEquals(expected, foreign);
        assertEquals(foreign, missing);
        foreign.elements().forEachRemaining(value -> {
            if (value.isTextual()) assertFalse(value.asText().contains(foreignPaymentId.toString()));
        });
    }

    @Test
    void invoice_create_ownedPaymentForAnotherBookingRetainsAssociationValidation() throws Exception {
        Long bookingId = createPrivacyBooking(userToken);
        mockSuccess(createPayment(bookingId));
        Long otherBookingId = createPrivacyBooking(userToken);
        Long accessiblePaymentId = createPayment(otherBookingId);
        mockSuccess(accessiblePaymentId);
        // This is an accessible payment, so the existing association error remains useful.
        mvc.perform(get("/api/payments/" + accessiblePaymentId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());
        var before = invoiceSideEffectSnapshot();
        ObjectNode error = invoiceCreationError(bookingId, accessiblePaymentId, 400);
        assertEquals("Payment does not belong to this booking", error.path("message").asText());
        assertEquals(before, invoiceSideEffectSnapshot());
    }

    @Test
    void invoice_create_duplicateRejected_returns422() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        createInvoice(bookingId, paymentId);

        mvc.perform(post("/api/invoices")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format("{\"bookingId\":%d,\"paymentId\":%d}", bookingId, paymentId)))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void invoice_numberFormat_isUniquePerInvoice() throws Exception {
        Long bookingId1 = createBooking();
        Long paymentId1 = createPayment(bookingId1);
        mockSuccess(paymentId1);
        String num1 = createInvoice(bookingId1, paymentId1).get("invoiceNumber").asText();

        Long bookingId2 = createBooking();
        Long paymentId2 = createPayment(bookingId2);
        mockSuccess(paymentId2);
        String num2 = createInvoice(bookingId2, paymentId2).get("invoiceNumber").asText();

        assertNotEquals(num1, num2);
        assertTrue(num1.matches("INV-\\d{8}-\\d{6}"));
        assertTrue(num2.matches("INV-\\d{8}-\\d{6}"));
    }

    @Test
    void invoice_create_unauthenticated_returns401() throws Exception {
        mvc.perform(post("/api/invoices")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":1,\"paymentId\":1}"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // GET INVOICE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void invoice_getOwn_returns200() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        Long invoiceId = createInvoice(bookingId, paymentId).get("id").asLong();

        mvc.perform(get("/api/invoices/" + invoiceId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(invoiceId));
    }

    @Test
    void invoice_getOtherUserMatchesMissingInvoice404() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        Long invoiceId = createInvoice(bookingId, paymentId).get("id").asLong();

        String foreign = mvc.perform(get("/api/invoices/" + invoiceId)
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isNotFound())
            .andReturn().getResponse().getContentAsString();
        String missing = mvc.perform(get("/api/invoices/9999998")
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isNotFound())
            .andReturn().getResponse().getContentAsString();
        assertEquals(mapper.readTree(missing).get("message").asText(),
            mapper.readTree(foreign).get("message").asText());
    }

    @Test
    void invoice_getById_notFound_returns404() throws Exception {
        mvc.perform(get("/api/invoices/9999999")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isNotFound());
    }

    @Test
    void invoice_getByBooking_returns200() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        Long invoiceId = createInvoice(bookingId, paymentId).get("id").asLong();

        mvc.perform(get("/api/bookings/" + bookingId + "/invoice")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(invoiceId));
    }

    @Test
    void invoice_listMine_containsCreatedInvoice() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        Long invoiceId = createInvoice(bookingId, paymentId).get("id").asLong();

        String body = mvc.perform(get("/api/me/invoices")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        boolean found = false;
        for (JsonNode n : arr) {
            if (n.get("id").asLong() == invoiceId) { found = true; break; }
        }
        assertTrue(found, "Newly created invoice must appear in listMine");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN APIS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_listInvoices_returns200() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        createInvoice(bookingId, paymentId);

        String body = mvc.perform(get("/api/admin/invoices")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode envelope = mapper.readTree(body);
        assertTrue(envelope.has("content") && envelope.has("totalElements"),
            "D1a: admin collections return a PageResponse envelope");
        JsonNode arr = envelope.get("content");
        assertTrue(arr.isArray());
        assertTrue(envelope.get("totalElements").asLong() >= 1);
    }

    @Test
    void admin_listInvoices_forbiddenForUser_returns403() throws Exception {
        mvc.perform(get("/api/admin/invoices")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void admin_getInvoice_returns200() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        Long invoiceId = createInvoice(bookingId, paymentId).get("id").asLong();

        mvc.perform(get("/api/admin/invoices/" + invoiceId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(invoiceId));
    }

    @Test
    void admin_updateStatus_setsRequestedStatus() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        Long invoiceId = createInvoice(bookingId, paymentId).get("id").asLong();

        String body = mvc.perform(patch("/api/admin/invoices/" + invoiceId + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"PAID\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("PAID", res.get("status").asText());
        assertFalse(res.get("paidAt").isNull());
    }

    @Test
    void admin_cancelInvoice_setsCancelled_andDoesNotCancelBooking() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        Long invoiceId = createInvoice(bookingId, paymentId).get("id").asLong();

        String body = mvc.perform(patch("/api/admin/invoices/" + invoiceId + "/cancel")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("CANCELLED", res.get("status").asText());
        assertFalse(res.get("cancelledAt").isNull());

        String bookingBody = mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals("CONFIRMED", mapper.readTree(bookingBody).get("status").asText(),
            "Cancelling the invoice must not cancel the booking");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATION INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void invoice_issued_createsNotification() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        createInvoice(bookingId, paymentId);

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        boolean found = false;
        for (JsonNode n : arr) {
            if ("Invoice issued".equals(n.get("title").asText())) { found = true; break; }
        }
        assertTrue(found, "Issuing an invoice must create a notification");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SEED VERIFICATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void seed_invoiceExists() throws Exception {
        String body = mvc.perform(get("/api/admin/invoices")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode envelope = mapper.readTree(body);
        assertTrue(envelope.has("content") && envelope.has("totalElements"),
            "D1a: admin collections return a PageResponse envelope");
        JsonNode arr = envelope.get("content");
        assertTrue(arr.isArray());
        assertTrue(envelope.get("totalElements").asLong() >= 1, "Seeded invoice must exist");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AMOUNT SNAPSHOT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void invoice_amounts_matchBookingAndPaymentSnapshot() throws Exception {
        Long bookingId = createBooking();

        String bookingBody = mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode booking = mapper.readTree(bookingBody);
        double basePrice = booking.get("basePrice").asDouble();
        double discountAmount = booking.get("discountAmount").asDouble();

        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);

        String paymentBody = mvc.perform(get("/api/payments/" + paymentId)
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        double paymentAmount = mapper.readTree(paymentBody).get("amount").asDouble();

        JsonNode invoice = createInvoice(bookingId, paymentId);

        assertEquals(basePrice, invoice.get("subtotal").asDouble(), 0.01);
        assertEquals(discountAmount, invoice.get("discountAmount").asDouble(), 0.01);
        assertEquals(paymentAmount, invoice.get("totalAmount").asDouble(), 0.01);
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

    private Long createBooking() throws Exception {
        return createBooking(userToken, TODAY.plusDays(dayCursor.getAndAdd(3)));
    }

    private Long createPrivacyBooking(String token) throws Exception {
        return createBooking(token, TODAY.plusDays(privacyDayCursor.getAndAdd(3)));
    }

    private Long createBooking(String token, LocalDate ci) throws Exception {
        LocalDate co = ci.plusDays(2);

        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":2,\"children\":0,\"numberOfRooms\":1}",
                    suiteRoomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long createPayment(Long bookingId) throws Exception {
        return createPayment(userToken, bookingId);
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

    private void mockSuccess(Long paymentId) throws Exception {
        mockSuccess(userToken, paymentId);
    }

    private void mockSuccess(String token, Long paymentId) throws Exception {
        mvc.perform(post("/api/payments/" + paymentId + "/mock-success")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
    }

    private String registerUser(String prefix) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of(
                    "fullName", "Invoice Privacy Tester",
                    "email", prefix + "-" + privacyDayCursor.get() + "@test.com",
                    "password", "password123"))))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private ObjectNode invoiceCreationError(Long bookingId, Long paymentId, int expectedStatus) throws Exception {
        String body = mvc.perform(post("/api/invoices")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(Map.of("bookingId", bookingId, "paymentId", paymentId))))
            .andExpect(status().is(expectedStatus))
            .andReturn().getResponse().getContentAsString();
        ObjectNode error = (ObjectNode) mapper.readTree(body);
        assertEquals("/api/invoices", error.path("path").asText());
        assertTrue(error.hasNonNull("timestamp"));
        error.remove(List.of("path", "timestamp"));
        return error;
    }

    private Map<String, List<Map<String, String>>> invoiceSideEffectSnapshot() {
        Map<String, List<Map<String, String>>> snapshot = new LinkedHashMap<>();
        for (String table : List.of("invoices", "bookings", "payments", "admin_activity_logs", "notifications")) {
            snapshot.put(table, jdbc.query("SELECT * FROM " + table + " ORDER BY id", (rs, rowNum) -> {
                Map<String, String> row = new LinkedHashMap<>();
                // Compare column values, including CLOB contents, rather than JDBC object identities.
                for (int column = 1; column <= rs.getMetaData().getColumnCount(); column++) {
                    row.put(rs.getMetaData().getColumnLabel(column), rs.getString(column));
                }
                return row;
            }));
        }
        return snapshot;
    }

    private JsonNode createInvoice(Long bookingId, Long paymentId) throws Exception {
        String body = mvc.perform(post("/api/invoices")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format("{\"bookingId\":%d,\"paymentId\":%d}", bookingId, paymentId)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }
}
