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

    private String adminToken;
    private String userToken;
    private String partnerToken;
    private Long suiteRoomId;

    private static final LocalDate TODAY = LocalDate.now();
    private static final AtomicInteger dayCursor = new AtomicInteger(40);

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
    void invoice_getOtherUser_returns403() throws Exception {
        Long bookingId = createBooking();
        Long paymentId = createPayment(bookingId);
        mockSuccess(paymentId);
        Long invoiceId = createInvoice(bookingId, paymentId).get("id").asLong();

        mvc.perform(get("/api/invoices/" + invoiceId)
                .header("Authorization", "Bearer " + partnerToken))
            .andExpect(status().isForbidden());
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

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 1);
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

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 1, "Seeded invoice must exist");
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
        LocalDate ci = TODAY.plusDays(dayCursor.getAndAdd(3));
        LocalDate co = ci.plusDays(2);

        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":2,\"children\":0,\"numberOfRooms\":1}",
                    suiteRoomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long createPayment(Long bookingId) throws Exception {
        String body = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private void mockSuccess(Long paymentId) throws Exception {
        mvc.perform(post("/api/payments/" + paymentId + "/mock-success")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());
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
