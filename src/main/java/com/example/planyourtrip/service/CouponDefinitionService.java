package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.CouponDto.CouponDefinitionRequest;
import com.example.planyourtrip.dto.CouponDto.CouponDefinitionResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.CouponDefinition;
import com.example.planyourtrip.model.CouponTargetType;
import com.example.planyourtrip.model.CustomerSegment;
import com.example.planyourtrip.repository.CouponDefinitionRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Admin CRUD over {@link CouponDefinition}. Mirrors {@code PromotionService}'s
 * conventions: 409 on duplicate code, 400 on invalid dates, 404 on unknown id.
 * Codes are normalized to trimmed upper-case on every write so uniqueness and
 * claim lookup are case-insensitive.
 *
 * <p>Note one deliberate deviation from {@code PromotionService#validateDates}
 * (which requires end strictly after start): the 7.14 spec allows a single-day
 * coupon, so {@code validFrom == validUntil} is accepted here.
 *
 * <p>Phase 7.17 — Coupon Targeting &amp; Advanced Eligibility: admin create/update
 * now also validates the target configuration ({@link CouponTargetType}) and the
 * new stay/date-window fields. Deliberate deviation from {@code Promotion}'s
 * HOTEL targeting (which resolves {@code targetId} against a {@code HotelDetail}
 * id via {@code room.getHotelDetail().getId()} in {@code PricingEngineService}):
 * here HOTEL {@code targetId} resolves against a {@code Place} id instead,
 * matching the "hotelId" convention used everywhere else in this codebase
 * (e.g. {@code PartnerAnalyticsService#resolveHotelScope}, admin hotel
 * endpoints) and matching what a {@code Booking} actually carries
 * ({@code Booking#hotel} is a {@code Place} FK, not a {@code HotelDetail} FK).
 */
@Service
@Transactional(readOnly = true)
public class CouponDefinitionService {

    private final CouponDefinitionRepository couponRepo;
    private final PlaceRepository placeRepo;
    private final HotelRoomRepository hotelRoomRepo;

    public CouponDefinitionService(CouponDefinitionRepository couponRepo,
                                    PlaceRepository placeRepo,
                                    HotelRoomRepository hotelRoomRepo) {
        this.couponRepo = couponRepo;
        this.placeRepo = placeRepo;
        this.hotelRoomRepo = hotelRoomRepo;
    }

    public List<CouponDefinitionResponse> getAll() {
        return couponRepo.findAll().stream().map(this::toResponse).toList();
    }

    public CouponDefinitionResponse getById(Long id) {
        return toResponse(definitionOrThrow(id));
    }

    @Transactional
    public CouponDefinitionResponse create(CouponDefinitionRequest req) {
        String code = normalizeCode(req.code());
        validate(req);
        if (couponRepo.existsByCodeIgnoreCase(code))
            throw new ApiException(HttpStatus.CONFLICT, "Coupon code already exists: " + code);

        CouponDefinition def = new CouponDefinition();
        fill(def, req, code);
        if (req.active() == null) def.setActive(true);
        return toResponse(couponRepo.save(def));
    }

    @Transactional
    public CouponDefinitionResponse update(Long id, CouponDefinitionRequest req) {
        CouponDefinition def = definitionOrThrow(id);
        String code = normalizeCode(req.code());
        validate(req);
        if (!code.equalsIgnoreCase(def.getCode()) && couponRepo.existsByCodeIgnoreCase(code))
            throw new ApiException(HttpStatus.CONFLICT, "Coupon code already exists: " + code);

        fill(def, req, code);
        return toResponse(couponRepo.save(def));
    }

    @Transactional
    public CouponDefinitionResponse activate(Long id) {
        CouponDefinition def = definitionOrThrow(id);
        def.setActive(true);
        return toResponse(couponRepo.save(def));
    }

    @Transactional
    public CouponDefinitionResponse deactivate(Long id) {
        CouponDefinition def = definitionOrThrow(id);
        def.setActive(false);
        return toResponse(couponRepo.save(def));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /** Package-private — reused as-is by {@code CustomerCouponService} so claim lookup normalizes identically. */
    static String normalizeCode(String raw) {
        return raw == null ? null : raw.trim().toUpperCase(Locale.ROOT);
    }

    CouponDefinition definitionOrThrow(Long id) {
        return couponRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Coupon definition not found: " + id));
    }

    private void validate(CouponDefinitionRequest req) {
        // Bean validation on the DTO already covers: code/name required,
        // discountValue > 0, maxDiscountAmount/minimumSpend >= 0 when present,
        // totalUsageLimit/usageLimitPerUser >= 1 when present, dates required,
        // minimumStayNights >= 1 when present.
        if (req.validUntil().isBefore(req.validFrom()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "validFrom must be on or before validUntil");
        if (req.bookingDateFrom() != null && req.bookingDateTo() != null
                && req.bookingDateFrom().isAfter(req.bookingDateTo()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "bookingDateFrom must be on or before bookingDateTo");

        CouponTargetType targetType = req.targetType() != null ? req.targetType() : CouponTargetType.ALL;
        switch (targetType) {
            case HOTEL -> {
                if (req.targetId() == null)
                    throw new ApiException(HttpStatus.BAD_REQUEST,
                        "targetId is required when targetType is HOTEL");
                if (!placeRepo.existsById(req.targetId()))
                    throw new ApiException(HttpStatus.NOT_FOUND, "Hotel not found: " + req.targetId());
            }
            case ROOM -> {
                if (req.targetId() == null)
                    throw new ApiException(HttpStatus.BAD_REQUEST,
                        "targetId is required when targetType is ROOM");
                if (!hotelRoomRepo.existsById(req.targetId()))
                    throw new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + req.targetId());
            }
            case PLACE_TYPE -> {
                if (req.placeType() == null || req.placeType().isBlank())
                    throw new ApiException(HttpStatus.BAD_REQUEST,
                        "placeType is required when targetType is PLACE_TYPE");
            }
            default -> { /* ALL — no target required */ }
        }
    }

    private void fill(CouponDefinition def, CouponDefinitionRequest req, String normalizedCode) {
        def.setCode(normalizedCode);
        def.setName(req.name());
        def.setDescription(req.description());
        def.setDiscountType(req.discountType());
        def.setDiscountValue(req.discountValue());
        def.setMaxDiscountAmount(req.maxDiscountAmount());
        def.setMinimumSpend(req.minimumSpend());
        def.setValidFrom(req.validFrom());
        def.setValidUntil(req.validUntil());
        def.setTotalUsageLimit(req.totalUsageLimit());
        def.setUsageLimitPerUser(req.usageLimitPerUser() != null ? req.usageLimitPerUser() : 1);
        if (req.active() != null) def.setActive(req.active());
        // currentUsageCount is never client-settable.

        // ── Phase 7.17 — targeting & advanced eligibility ──────────────────
        def.setTargetType(req.targetType() != null ? req.targetType() : CouponTargetType.ALL);
        def.setTargetId(req.targetId());
        def.setPlaceType(req.placeType());
        def.setMinimumStayNights(req.minimumStayNights());
        def.setBookingDateFrom(req.bookingDateFrom());
        def.setBookingDateTo(req.bookingDateTo());
        def.setCustomerSegment(req.customerSegment() != null ? req.customerSegment() : CustomerSegment.ALL_USERS);
        if (req.firstBookingOnly() != null) def.setFirstBookingOnly(req.firstBookingOnly());
        if (req.combinableWithPromotions() != null) def.setCombinableWithPromotions(req.combinableWithPromotions());
        if (req.combinableWithTravelCredits() != null)
            def.setCombinableWithTravelCredits(req.combinableWithTravelCredits());

        // ── Phase 7.21 — minimumTier gating (additive, always a plain pass-through:
        // null means "no requirement", same convention as targetId/placeType/minimumStayNights) ──
        def.setMinimumTier(req.minimumTier());
    }

    /** Package-private — reused as-is by {@code CustomerCouponService} so both map the exact same shape. */
    CouponDefinitionResponse toResponse(CouponDefinition d) {
        return new CouponDefinitionResponse(
            d.getId(), d.getCode(), d.getName(), d.getDescription(),
            d.getDiscountType(), d.getDiscountValue(), d.getMaxDiscountAmount(), d.getMinimumSpend(),
            d.getValidFrom(), d.getValidUntil(), d.isActive(),
            d.getTotalUsageLimit(), d.getUsageLimitPerUser(), d.getCurrentUsageCount(),
            d.getTargetType(), d.getTargetId(), d.getPlaceType(),
            d.getMinimumStayNights(), d.getBookingDateFrom(), d.getBookingDateTo(),
            d.getCustomerSegment(), d.isFirstBookingOnly(),
            d.isCombinableWithPromotions(), d.isCombinableWithTravelCredits(),
            d.getMinimumTier(),
            d.getCreatedAt(), d.getUpdatedAt()
        );
    }
}
