package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.BookingDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

@Service
public class BookingService {

    private final BookingRepository bookingRepo;
    private final HotelRoomRepository roomRepo;
    private final RoomInventoryRepository inventoryRepo;
    private final UserRepository userRepo;
    private final PricingEngineService pricingEngine;
    private final BookingStatusEngineService statusEngine;
    private final PaymentRepository paymentRepo;
    private final NotificationService notificationService;
    private final CustomerCouponService customerCouponService;
    private final TravelCreditService travelCreditService;
    private final LoyaltyService loyaltyService;
    private final LoyaltyRedemptionService loyaltyRedemptionService;
    private final ReferralService referralService;
    private final GiftCardService giftCardService;
    private final InventoryReservationService inventoryReservationService;
    private final RatePlanPricingService ratePlanPricingService;

    private static final Set<BookingStatus> UPCOMING_STATUSES =
        EnumSet.of(BookingStatus.PENDING, BookingStatus.CONFIRMED, BookingStatus.CHECK_IN_READY);

    private static final Set<BookingStatus> ACTIVE_STATUSES =
        EnumSet.of(BookingStatus.CHECKED_IN);

    private static final Set<BookingStatus> HISTORY_STATUSES =
        EnumSet.of(BookingStatus.CHECKED_OUT, BookingStatus.COMPLETED,
                   BookingStatus.CANCELLED, BookingStatus.REFUNDED,
                   BookingStatus.ARCHIVED, BookingStatus.NO_SHOW);

    public BookingService(BookingRepository bookingRepo,
                          HotelRoomRepository roomRepo,
                          RoomInventoryRepository inventoryRepo,
                          UserRepository userRepo,
                          PricingEngineService pricingEngine,
                          BookingStatusEngineService statusEngine,
                          PaymentRepository paymentRepo,
                          NotificationService notificationService,
                          CustomerCouponService customerCouponService,
                          TravelCreditService travelCreditService,
                          LoyaltyService loyaltyService,
                          LoyaltyRedemptionService loyaltyRedemptionService,
                          ReferralService referralService,
                          GiftCardService giftCardService,
                          InventoryReservationService inventoryReservationService,
                          RatePlanPricingService ratePlanPricingService) {
        this.bookingRepo   = bookingRepo;
        this.roomRepo      = roomRepo;
        this.inventoryRepo = inventoryRepo;
        this.userRepo      = userRepo;
        this.pricingEngine = pricingEngine;
        this.statusEngine  = statusEngine;
        this.paymentRepo   = paymentRepo;
        this.notificationService = notificationService;
        this.customerCouponService = customerCouponService;
        this.travelCreditService = travelCreditService;
        this.loyaltyService = loyaltyService;
        this.loyaltyRedemptionService = loyaltyRedemptionService;
        this.referralService = referralService;
        this.giftCardService = giftCardService;
        this.inventoryReservationService = inventoryReservationService;
        this.ratePlanPricingService = ratePlanPricingService;
    }

    // ── Create ────────────────────────────────────────────────────────────────

    @Transactional
    public BookingResponse create(Long userId, BookingRequest req) {
        LocalDate today = LocalDate.now();
        if (req.checkIn().isBefore(today))
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkIn cannot be in the past");
        if (!req.checkOut().isAfter(req.checkIn()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkOut must be after checkIn");

        HotelRoom room = roomRepo.findById(req.roomId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + req.roomId()));
        if (!room.isActive())
            throw new ApiException(HttpStatus.BAD_REQUEST, "Room is not available for booking");

        Place hotel = room.getHotelDetail().getPlace();
        if (hotel.getStatus() != PlaceStatus.PUBLISHED)
            throw new ApiException(HttpStatus.BAD_REQUEST, "Hotel is not published");

        int numRooms = req.numberOfRooms() != null ? req.numberOfRooms() : 1;
        int children = req.children() != null ? req.children() : 0;

        int maxAdultsTotal = room.getMaxAdults() != null ? room.getMaxAdults() * numRooms : numRooms;
        int maxGuestsTotal = room.getMaxGuests() != null ? room.getMaxGuests() * numRooms : numRooms;
        if (req.adults() > maxAdultsTotal)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Adults exceed maximum capacity of " + maxAdultsTotal);
        if ((req.adults() + children) > maxGuestsTotal)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Total guests exceed maximum capacity of " + maxGuestsTotal);

        long nights = ChronoUnit.DAYS.between(req.checkIn(), req.checkOut());
        // Phase 7.28 — pessimistically lock the exact inventory rows BEFORE the availability
        // check so the check + decrement below are atomic against a concurrent booking for the
        // same room/dates. The loser blocks here until the winner commits, then re-reads
        // availability under the lock and is rejected below — overselling is impossible.
        inventoryRepo.lockForUpdate(req.roomId(), req.checkIn(), req.checkOut());
        long availNights = inventoryRepo.countNightsWithSufficientInventory(
            req.roomId(), req.checkIn(), req.checkOut(), numRooms);
        if (availNights < nights)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Insufficient inventory for the selected dates");

        // Phase 7.29/7.30 — resolve the rate plan FIRST, then feed its resolved per-stay subtotal
        // into the pricing engine so the authoritative charged total is built on the SAME plan that
        // is snapshotted onto the booking below (no longer the engine's own cheapest-plan pick).
        // When req.ratePlanId() is supplied it is validated for eligibility here (throws 422 before
        // any inventory mutation); when omitted the best eligible plan is resolved (or none).
        // Inventory is NOT re-checked (availability already confirmed under the Phase 7.28 lock).
        int extraBeds = req.extraBeds() != null ? req.extraBeds() : 0;
        var rateResolution = ratePlanPricingService.resolveForBooking(
            room, req.ratePlanId(), req.checkIn(), req.checkOut(), req.adults(), children, extraBeds);

        // Phase 7.30 — the resolved rate-plan stay subtotal (base nightly + derived adjustment +
        // occupancy/child/extra-bed supplements × nights) becomes the FIRST pricing stage, feeding
        // the unchanged customer-discount chain (ratePlan→promotion→coupon→loyalty→credit→gift card).
        // When no plan is eligible the subtotal is null and pricing falls back to the base room price.
        var pricing = rateResolution
            .map(r -> pricingEngine.calculate(req.roomId(), req.checkIn(), req.checkOut(),
                r.staySubtotal(), r.plan().getRateName()))
            .orElseGet(() -> pricingEngine.calculate(req.roomId(), req.checkIn(), req.checkOut(),
                null, null));

        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        // ── Phase 7.15: coupon + travel credits at checkout ──────────────────
        // Stacking order (documented judgment call): promotion/pricing-engine
        // discount first (already inside pricing.finalPrice()), then the coupon
        // on that amount, then credits against the remainder. Promotions and a
        // coupon stack; at most one coupon per booking (single couponCode field).
        BigDecimal orderAmount = pricing.finalPrice();
        // Phase 7.17 — thread the full checkout context (target hotel/room,
        // stay dates, whether a promotion discount is already baked into
        // orderAmount, and the raw requested credit amount) through to the
        // SAME centralized evaluator used by claim/preview/eligibility, so
        // targeting/stay/date/segment/stacking rules are enforced here too —
        // before any coupon/credit mutation, so a failed booking still burns
        // neither (unchanged 7.15 atomicity guarantee).
        boolean promotionDiscountApplied = pricing.promotionDiscount() != null
            && pricing.promotionDiscount().signum() > 0;
        CustomerCouponService.CheckoutCouponResult couponResult = null;
        if (req.couponCode() != null && !req.couponCode().isBlank()) {
            CustomerCouponService.EligibilityContext ctx = new CustomerCouponService.EligibilityContext(
                hotel.getId(), room.getId(), req.checkIn(), req.checkOut(),
                orderAmount, req.creditAmount(), promotionDiscountApplied);
            couponResult = customerCouponService.validateForCheckout(userId, req.couponCode(), ctx);
        }
        BigDecimal couponDiscount = couponResult != null ? couponResult.discountAmount() : BigDecimal.ZERO;
        BigDecimal remainingAfterCoupon = orderAmount.subtract(couponDiscount);

        BigDecimal creditAmount = null;
        if (req.creditAmount() != null) {
            creditAmount = req.creditAmount().setScale(2, RoundingMode.HALF_UP);
            if (creditAmount.signum() <= 0)
                throw new ApiException(HttpStatus.BAD_REQUEST, "creditAmount must be greater than zero");
            // Rejected (not clamped): the customer asked for an explicit amount,
            // silently redeeming less would be surprising.
            if (creditAmount.compareTo(remainingAfterCoupon) > 0)
                throw new ApiException(HttpStatus.BAD_REQUEST,
                    "creditAmount exceeds the amount payable after discounts ("
                        + remainingAfterCoupon.toPlainString() + ")");
        }

        Booking booking = new Booking();
        booking.setUser(user);
        booking.setHotel(hotel);
        booking.setRoom(room);
        booking.setCheckInDate(req.checkIn());
        booking.setCheckOutDate(req.checkOut());
        booking.setAdults(req.adults());
        booking.setChildren(children);
        booking.setNumberOfRooms(numRooms);
        booking.setStatus(BookingStatus.PENDING);
        booking.setCurrency("VND");
        booking.setBasePrice(pricing.basePrice());
        booking.setRatePlanPrice(pricing.ratePlanPrice());
        booking.setDiscountAmount(pricing.promotionDiscount());
        if (couponResult != null) {
            booking.setCouponCode(couponResult.coupon().getCouponDefinition().getCode());
            booking.setCouponDiscountAmount(couponDiscount);
        }
        if (creditAmount != null) booking.setCreditAmountUsed(creditAmount);
        booking.setFinalPrice(remainingAfterCoupon
            .subtract(creditAmount != null ? creditAmount : BigDecimal.ZERO)
            .max(BigDecimal.ZERO)
            .setScale(2, RoundingMode.HALF_UP));
        booking.setSpecialRequest(req.specialRequest());

        // Phase 7.29 — persist the immutable rate-plan snapshot (point-in-time; later plan
        // edits never mutate this booking). Left null when no plan was resolved.
        if (rateResolution.isPresent()) {
            var r = rateResolution.get();
            var plan = r.plan();
            booking.setSelectedRatePlanId(plan.getId());
            booking.setSelectedRatePlanCode(plan.getCode());
            booking.setSelectedRatePlanName(plan.getRateName());
            booking.setMealPlanType(plan.getMealPlanType());
            booking.setCancellationPolicyType(plan.getCancellationPolicyType());
            booking.setCancellationDeadlineAt(r.cancellationDeadlineAt());
            booking.setRefundable(plan.isRefundable());
            booking.setNightlyRateSnapshot(r.finalNightlyRate());
            booking.setRatePlanAdjustmentSnapshot(r.ratePlanAdjustment());
        }

        booking = bookingRepo.save(booking);
        booking.setBookingCode(generateCode(booking.getId()));
        booking = bookingRepo.save(booking);

        inventoryRepo.decrementInventory(req.roomId(), req.checkIn(), req.checkOut(), numRooms);

        // Phase 7.28 — record the single HELD hold covering the decrement just applied, in
        // THIS transaction (a rolled-back booking leaves neither decrement nor hold). This is
        // a tracking row only — it performs NO inventory math of its own.
        inventoryReservationService.hold(booking);

        // Consume coupon + redeem credits INSIDE this transaction (the booking id
        // now exists for the FK / ledger reference) — any failure from here on
        // (e.g. insufficient credit balance → 409 under the account's pessimistic
        // lock) rolls the whole booking back, so a failed booking never burns a
        // coupon or credits.
        if (couponResult != null)
            customerCouponService.markUsedForBooking(couponResult.coupon(), booking);
        if (creditAmount != null)
            travelCreditService.redeemForBooking(userId, creditAmount, booking.getCurrency(), booking.getId());

        // Phase 7.25 — gift card is the LAST discount source, applied against the
        // payable AFTER travel credits (finalPrice above already reflects promotion,
        // coupon and credits). redeemForBooking clamps to min(balance, payable),
        // writes the REDEMPTION ledger row, reduces booking.finalPrice and records
        // the masked reference — all inside this same transaction, so any failure
        // here (e.g. wrong currency / non-redeemable card) rolls the whole booking
        // back and no gift-card balance is burned.
        if (req.giftCardCode() != null && !req.giftCardCode().isBlank())
            giftCardService.redeemForBooking(userId, req.giftCardCode(), booking);

        return toResponse(booking);
    }

    // ── Read ──────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public BookingResponse getById(Long userId, Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        User requestingUser = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
        if (!booking.getUser().getId().equals(userId) && !"ADMIN".equals(requestingUser.getRole()))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
        return toResponse(booking);
    }

    @Transactional(readOnly = true)
    public List<BookingSummaryResponse> getMyBookings(Long userId) {
        return bookingRepo.findByUserIdOrderByCreatedAtDesc(userId)
            .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public List<UpcomingBookingResponse> getUpcomingBookings(Long userId) {
        return bookingRepo.findByUserIdAndCheckInDateGreaterThanEqualAndStatusInOrderByCheckInDateAsc(
                userId, LocalDate.now(), UPCOMING_STATUSES)
            .stream().map(this::toUpcoming).toList();
    }

    @Transactional(readOnly = true)
    public List<BookingHistoryResponse> getBookingHistory(Long userId) {
        return bookingRepo.findByUserIdAndStatusInOrderByCheckInDateDesc(userId, HISTORY_STATUSES)
            .stream().map(this::toHistory).toList();
    }

    @Transactional(readOnly = true)
    public List<BookingSummaryResponse> getActiveBookings(Long userId) {
        return bookingRepo.findByUserIdAndStatusInOrderByCreatedAtDesc(userId, ACTIVE_STATUSES)
            .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public BookingTimelineResponse getTimeline(Long userId, Long bookingId) {
        Booking b = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        User requestingUser = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
        if (!b.getUser().getId().equals(userId) && !"ADMIN".equals(requestingUser.getRole()))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
        return buildTimeline(b);
    }

    // ── Cancel ────────────────────────────────────────────────────────────────

    @Transactional
    public BookingResponse cancel(Long userId, Long bookingId, String cancelReason) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");

        BookingStatus current = booking.getStatus();
        if (current == BookingStatus.CANCELLED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Booking is already cancelled");

        Set<BookingStatus> nonCancellable = EnumSet.of(
            BookingStatus.CHECKED_IN, BookingStatus.CHECKED_OUT,
            BookingStatus.CHECK_IN_READY, BookingStatus.COMPLETED,
            BookingStatus.ARCHIVED, BookingStatus.REFUNDED, BookingStatus.NO_SHOW);
        if (nonCancellable.contains(current))
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot cancel booking with status: " + current);

        booking.setStatus(BookingStatus.CANCELLED);
        booking.setCancelledAt(Instant.now());
        booking.setLastStatusChangedAt(Instant.now());
        if (cancelReason != null) booking.setCancelReason(cancelReason);

        inventoryRepo.restoreInventory(booking.getRoom().getId(),
            booking.getCheckInDate(), booking.getCheckOutDate(), booking.getNumberOfRooms());

        // Phase 7.28 — mark the hold terminally handled (RELEASED) WITHOUT restoring again:
        // the restoreInventory call above already returned this booking's inventory. Idempotent
        // no-op if the hold was already released/consumed/expired.
        inventoryReservationService.releaseForCancelledBooking(booking.getId());

        releaseCheckoutBenefits(booking);

        Booking saved = bookingRepo.save(booking);

        notificationService.create(userId, NotificationType.BOOKING, Priority.NORMAL,
            "Booking cancelled",
            "Your booking " + saved.getBookingCode() + " has been cancelled.",
            RelatedEntityType.BOOKING, saved.getId());

        return toResponse(saved);
    }

    // ── Admin: list / get ─────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<BookingSummaryResponse> adminGetAll() {
        return bookingRepo.findAllByOrderByCreatedAtDesc()
            .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public BookingResponse adminGetById(Long bookingId) {
        return toResponse(bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId)));
    }

    @Transactional(readOnly = true)
    public List<BookingSummaryResponse> adminSearch(String status, String hotel,
                                                     LocalDate date, String guest,
                                                     String bookingCode) {
        Specification<Booking> spec = Specification
            .where(BookingSpecification.withStatus(status))
            .and(BookingSpecification.withHotel(hotel))
            .and(BookingSpecification.withCheckInDate(date))
            .and(BookingSpecification.withGuest(guest))
            .and(BookingSpecification.withBookingCode(bookingCode));
        return bookingRepo.findAll(spec).stream()
            .sorted(Comparator.comparing(Booking::getCreatedAt).reversed())
            .map(this::toSummary).toList();
    }

    // ── Admin: force-set status (backward compat — no engine validation) ──────

    @Transactional
    public BookingResponse adminUpdateStatus(Long bookingId, BookingStatus newStatus) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));

        BookingStatus old = booking.getStatus();
        Instant now = Instant.now();
        booking.setStatus(newStatus);
        booking.setLastStatusChangedAt(now);

        if (newStatus == BookingStatus.CONFIRMED && old != BookingStatus.CONFIRMED)
            booking.setConfirmedAt(now);
        if (newStatus == BookingStatus.CHECKED_IN && booking.getActualCheckInAt() == null)
            booking.setActualCheckInAt(now);
        if (newStatus == BookingStatus.CHECKED_OUT && booking.getActualCheckOutAt() == null)
            booking.setActualCheckOutAt(now);
        if (newStatus == BookingStatus.COMPLETED && booking.getCompletedAt() == null)
            booking.setCompletedAt(now);
        if (newStatus == BookingStatus.ARCHIVED && booking.getArchivedAt() == null)
            booking.setArchivedAt(now);
        if (newStatus == BookingStatus.CANCELLED && old != BookingStatus.CANCELLED) {
            booking.setCancelledAt(now);
            inventoryRepo.restoreInventory(booking.getRoom().getId(),
                booking.getCheckInDate(), booking.getCheckOutDate(), booking.getNumberOfRooms());
            // Phase 7.28 — same additive hook as cancel(): mark the hold RELEASED without a
            // second restore (the line above already restored). Idempotent.
            inventoryReservationService.releaseForCancelledBooking(booking.getId());
            releaseCheckoutBenefits(booking);
        }

        Booking saved = bookingRepo.save(booking);
        // Phase 7.18 — loyalty points on completion. Idempotent via the deterministic
        // "booking-<id>-loyalty-earn" key, so this can never double-award even if
        // adminComplete (engine-validated path, below) also reaches COMPLETED for
        // the same booking.
        if (newStatus == BookingStatus.COMPLETED) {
            loyaltyService.awardBookingPoints(saved.getUser().getId(), saved.getId(), saved.getFinalPrice());
            // Phase 7.22 — same completion hook, one additional call: referral
            // qualification. No-op unless the booking owner is an invitee still
            // awaiting their qualifying first booking; idempotent via the reward's
            // one-way USED→REWARDED gate, so a repeated COMPLETED never re-rewards.
            referralService.qualifyBookingForReferral(saved.getUser().getId(), saved.getId(), saved.getFinalPrice());
        }
        return toResponse(saved);
    }

    // ── Admin: engine-validated transitions ───────────────────────────────────

    @Transactional
    public BookingResponse adminCheckIn(Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        statusEngine.transition(booking, BookingStatus.CHECKED_IN);
        return toResponse(bookingRepo.save(booking));
    }

    @Transactional
    public BookingResponse adminCheckOut(Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        statusEngine.transition(booking, BookingStatus.CHECKED_OUT);
        return toResponse(bookingRepo.save(booking));
    }

    @Transactional
    public BookingResponse adminComplete(Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        statusEngine.transition(booking, BookingStatus.COMPLETED);
        Booking saved = bookingRepo.save(booking);
        // Phase 7.18 — same idempotent loyalty-points hook as adminUpdateStatus above.
        loyaltyService.awardBookingPoints(saved.getUser().getId(), saved.getId(), saved.getFinalPrice());
        // Phase 7.22 — referral qualification, same completion hook (see adminUpdateStatus).
        referralService.qualifyBookingForReferral(saved.getUser().getId(), saved.getId(), saved.getFinalPrice());
        return toResponse(saved);
    }

    @Transactional
    public BookingResponse adminArchive(Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        statusEngine.transition(booking, BookingStatus.ARCHIVED);
        return toResponse(bookingRepo.save(booking));
    }

    // ── Phase 7.16 — Admin: refund a cancelled booking's payment as credits ──

    /**
     * Phase 7.16 — refund-to-credits: the money actually paid for a booking
     * that was subsequently cancelled comes back to the customer as
     * promotional travel credits (NO real-money custody or gateway refund —
     * ledger only). Admin-triggered, mirroring the manual-trigger convention.
     *
     * <p>Rules (documented judgment calls):
     * <ul>
     *   <li>booking must be CANCELLED — refunding an active booking makes no
     *       sense (422); an already-REFUNDED booking gets its own 422 so the
     *       trigger is safely non-repeatable at the state level, with the
     *       ledger's deterministic idempotencyKey
     *       {@code booking-<id>-refund-credit} as the race-proof backstop;</li>
     *   <li>exactly the PAID payment's amount is refunded (that is the money
     *       that actually changed hands — coupon/credit discounts were never
     *       paid, and credits redeemed at checkout were already restored by the
     *       cancellation REVERSAL, so nothing double-counts);</li>
     *   <li>a payment already cash-refunded via
     *       {@code POST /api/admin/payments/{id}/refund} is no longer PAID, so
     *       refund-to-credits rejects it (422) — one refund path per payment;</li>
     *   <li>everything (ledger row, payment → REFUNDED, booking → REFUNDED)
     *       happens in one transaction: any failure (e.g. account currency
     *       mismatch → 400) leaves no partial state.</li>
     * </ul>
     */
    @Transactional
    public BookingResponse adminRefundToCredits(Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));

        if (booking.getStatus() == BookingStatus.REFUNDED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Booking has already been refunded");
        if (booking.getStatus() != BookingStatus.CANCELLED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Only a CANCELLED booking can be refunded to credits. Current status: "
                    + booking.getStatus());

        Payment paidPayment = paymentRepo.findByBookingIdOrderByCreatedAtDesc(bookingId).stream()
            .filter(p -> p.getStatus() == PaymentStatus.PAID)
            .findFirst()
            .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "No PAID payment exists for this booking — nothing to refund"));
        if (paidPayment.getAmount() == null || paidPayment.getAmount().signum() <= 0)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Payment amount is zero — nothing to refund");

        // Ledger first: the locked, idempotent REFUND_CREDIT grant. Any
        // ApiException from here (e.g. currency mismatch) aborts the whole
        // transaction before/along with the status flips below.
        travelCreditService.refundForBooking(booking.getUser().getId(),
            paidPayment.getAmount(), paidPayment.getCurrency(), bookingId, paidPayment.getId());

        Instant now = Instant.now();
        paidPayment.setStatus(PaymentStatus.REFUNDED);
        paidPayment.setRefundedAt(now);
        paymentRepo.save(paidPayment);

        booking.setStatus(BookingStatus.REFUNDED);
        booking.setLastStatusChangedAt(now);
        Booking saved = bookingRepo.save(booking);

        notificationService.create(saved.getUser().getId(), NotificationType.BOOKING, Priority.NORMAL,
            "Booking refunded",
            "Your booking " + saved.getBookingCode() + " has been refunded as "
                + paidPayment.getAmount().toPlainString() + " " + paidPayment.getCurrency()
                + " in promotional travel credits.",
            RelatedEntityType.BOOKING, saved.getId());

        return toResponse(saved);
    }

    // ── Admin: timeline ───────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public BookingTimelineResponse adminGetTimeline(Long bookingId) {
        Booking b = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        return buildTimeline(b);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * Phase 7.15 — cancellation reversal for both the customer cancel path and
     * the admin force-CANCELLED path. Credits redeemed by the booking come back
     * as a REVERSAL ledger row (idempotencyKey {@code booking-<id>-reversal}, so
     * repeated cancellation can never double-restore); the coupon is released
     * back to AVAILABLE only while still redeemable — see
     * {@link CustomerCouponService#releaseForCancelledBooking}. Ledger-only:
     * refund/payment money flows are untouched.
     */
    private void releaseCheckoutBenefits(Booking booking) {
        if (booking.getCreditAmountUsed() != null && booking.getCreditAmountUsed().signum() > 0)
            travelCreditService.reverseForBooking(booking.getUser().getId(),
                booking.getCreditAmountUsed(), booking.getCurrency(), booking.getId());
        customerCouponService.releaseForCancelledBooking(booking.getId());
        // Phase 7.20 — restore loyalty points for an active redemption on this booking
        // (RESERVED → RELEASED, APPLIED → REFUNDED). Idempotent; no-op when none exists.
        loyaltyRedemptionService.onBookingCancelled(booking.getId());
        // Phase 7.25 — refund any gift-card value redeemed on this booking (restore
        // balance + REFUND ledger row). Idempotent (shares the single refund key with
        // the payment-failure release path); no-op when nothing is (still) redeemed.
        giftCardService.refundForBooking(booking.getId());
    }

    private BookingTimelineResponse buildTimeline(Booking b) {
        List<TimelineEvent> events = new ArrayList<>();
        events.add(new TimelineEvent("CREATED", b.getCreatedAt(), "Booking created"));

        paymentRepo.findByBookingIdOrderByCreatedAtDesc(b.getId()).stream()
            .filter(p -> p.getStatus() == PaymentStatus.PAID && p.getPaidAt() != null)
            .min(Comparator.comparing(Payment::getPaidAt))
            .ifPresent(p -> events.add(new TimelineEvent("PAID", p.getPaidAt(), "Payment completed")));

        if (b.getConfirmedAt() != null)
            events.add(new TimelineEvent("CONFIRMED", b.getConfirmedAt(), "Booking confirmed"));
        if (b.getActualCheckInAt() != null)
            events.add(new TimelineEvent("CHECKED_IN", b.getActualCheckInAt(), "Guest checked in"));
        if (b.getActualCheckOutAt() != null)
            events.add(new TimelineEvent("CHECKED_OUT", b.getActualCheckOutAt(), "Guest checked out"));
        if (b.getCompletedAt() != null)
            events.add(new TimelineEvent("COMPLETED", b.getCompletedAt(), "Reservation completed"));
        if (b.getCancelledAt() != null)
            events.add(new TimelineEvent("CANCELLED", b.getCancelledAt(), "Booking cancelled"));
        if (b.getArchivedAt() != null)
            events.add(new TimelineEvent("ARCHIVED", b.getArchivedAt(), "Reservation archived"));

        events.sort(Comparator.comparing(TimelineEvent::occurredAt));
        return new BookingTimelineResponse(b.getId(), b.getBookingCode(), events);
    }

    private String generateCode(Long id) {
        return "PYT-" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
            + "-" + String.format("%06d", id);
    }

    BookingResponse toResponse(Booking b) {
        int nights = (int) ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate());
        return new BookingResponse(
            b.getId(),
            b.getBookingCode(),
            b.getUser().getId(), b.getUser().getFullName(), b.getUser().getEmail(),
            b.getHotel().getId(), b.getHotel().getName(),
            b.getRoom().getId(), b.getRoom().getRoomName(), b.getRoom().getRoomCode(),
            b.getCheckInDate(), b.getCheckOutDate(),
            nights, b.getAdults(), b.getChildren(), b.getNumberOfRooms(),
            b.getStatus().name(),
            b.getCurrency(),
            b.getBasePrice(), b.getRatePlanPrice(),
            b.getDiscountAmount(), b.getFinalPrice(),
            b.getSpecialRequest(), b.getPartnerNote(),
            b.getCreatedAt(), b.getUpdatedAt(),
            b.getConfirmedAt(), b.getCancelledAt(),
            b.getActualCheckInAt(), b.getActualCheckOutAt(),
            b.getCompletedAt(), b.getArchivedAt(),
            b.getLastStatusChangedAt(), b.getCancelReason(),
            b.getCouponCode(), b.getCouponDiscountAmount(), b.getCreditAmountUsed(),
            b.getLoyaltyDiscountAmount(), b.getLoyaltyPointsRedeemed(),
            b.getGiftCardAmountUsed(), b.getGiftCardReference(),
            b.getSelectedRatePlanId(), b.getSelectedRatePlanCode(), b.getSelectedRatePlanName(),
            b.getMealPlanType() != null ? b.getMealPlanType().name() : null,
            b.getCancellationPolicyType() != null ? b.getCancellationPolicyType().name() : null,
            b.getCancellationDeadlineAt(), b.getRefundable(),
            b.getNightlyRateSnapshot(), b.getRatePlanAdjustmentSnapshot()
        );
    }

    BookingSummaryResponse toSummary(Booking b) {
        int nights = (int) ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate());
        return new BookingSummaryResponse(
            b.getId(),
            b.getBookingCode(),
            b.getHotel().getId(), b.getHotel().getName(),
            b.getRoom().getId(), b.getRoom().getRoomName(),
            b.getCheckInDate(), b.getCheckOutDate(),
            nights,
            b.getStatus().name(),
            b.getFinalPrice(), b.getCurrency(),
            b.getCreatedAt()
        );
    }

    private UpcomingBookingResponse toUpcoming(Booking b) {
        int nights = (int) ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate());
        return new UpcomingBookingResponse(
            b.getId(), b.getBookingCode(),
            b.getHotel().getName(), b.getRoom().getRoomName(),
            b.getCheckInDate(), b.getCheckOutDate(),
            nights, b.getStatus().name(),
            b.getFinalPrice(), b.getCurrency()
        );
    }

    private BookingHistoryResponse toHistory(Booking b) {
        int nights = (int) ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate());
        return new BookingHistoryResponse(
            b.getId(), b.getBookingCode(),
            b.getHotel().getName(), b.getRoom().getRoomName(),
            b.getCheckInDate(), b.getCheckOutDate(),
            nights, b.getStatus().name(),
            b.getFinalPrice(), b.getCurrency(),
            b.getCreatedAt(), b.getConfirmedAt()
        );
    }
}
