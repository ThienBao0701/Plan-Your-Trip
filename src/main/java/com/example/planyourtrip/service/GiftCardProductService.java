package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.GiftCardDto.GiftCardProductRequest;
import com.example.planyourtrip.dto.GiftCardDto.GiftCardProductResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.GiftCardProduct;
import com.example.planyourtrip.repository.GiftCardProductRepository;
import com.example.planyourtrip.repository.GiftCardRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * Admin CRUD over {@link GiftCardProduct}. Mirrors {@code CouponDefinitionService}'s
 * conventions: 409 on duplicate code, 400 on invalid rules, 404 on unknown id.
 * Codes are normalized to trimmed upper-case on every write so uniqueness and
 * issuance lookup are case-insensitive.
 */
@Service
@Transactional(readOnly = true)
public class GiftCardProductService {

    private final GiftCardProductRepository productRepo;
    private final GiftCardRepository giftCardRepo;
    private final AdminActivityLogService adminAudit;

    public GiftCardProductService(GiftCardProductRepository productRepo, GiftCardRepository giftCardRepo,
                                   AdminActivityLogService adminAudit) {
        this.productRepo = productRepo;
        this.giftCardRepo = giftCardRepo;
        this.adminAudit = adminAudit;
    }

    public List<GiftCardProductResponse> getAll() {
        return productRepo.findAllByOrderByCreatedAtDesc().stream().map(this::toResponse).toList();
    }

    public GiftCardProductResponse getById(Long id) {
        return toResponse(productOrThrow(id));
    }

    /** Used by {@code DataInitializer}'s idempotent seed check — case-insensitive. */
    public boolean existsByCode(String code) {
        return productRepo.existsByProductCodeIgnoreCase(normalizeCode(code));
    }

    @Transactional
    public GiftCardProductResponse create(GiftCardProductRequest req) {
        String code = normalizeCode(req.productCode());
        validate(req);
        if (productRepo.existsByProductCodeIgnoreCase(code))
            throw new ApiException(HttpStatus.CONFLICT, "Gift card product code already exists: " + code);

        GiftCardProduct product = new GiftCardProduct();
        fill(product, req, code);
        return toResponse(productRepo.save(product));
    }

    /**
     * D3H - the audited administrative create. It is a wrapper rather than an audit call inside
     * {@link #create} because {@code DataInitializer} seeds the catalogue through that method at
     * startup; recording there would write a boot-time row into the administrative trail on every
     * fresh database, describing an action no operator performed. The remaining writes below are
     * reached only from {@code AdminGiftCardProductController}, so they audit inline and take the
     * actor first, exactly like {@link #delete}.
     *
     * <p>State strings carry scalars and dates only - never the operator-supplied productCode,
     * name, description or currency (D1c-NEW-1). Amounts go through {@code num()} because a
     * precision-15 amount can legitimately reach thirteen digits.
     */
    @Transactional
    public GiftCardProductResponse adminCreate(Long adminUserId, GiftCardProductRequest req) {
        GiftCardProductResponse created = create(req);
        adminAudit.record(adminUserId, "GIFT_CARD_PRODUCT_CREATE", "GIFT_CARD_PRODUCT", created.id(),
            "Admin created gift card product " + created.id(), null, summarise(created));
        return created;
    }

    @Transactional
    public GiftCardProductResponse update(Long adminUserId, Long id, GiftCardProductRequest req) {
        GiftCardProduct product = productOrThrow(id);
        String before = summarise(toResponse(product));
        String code = normalizeCode(req.productCode());
        validate(req);
        if (!code.equalsIgnoreCase(product.getProductCode()) && productRepo.existsByProductCodeIgnoreCase(code))
            throw new ApiException(HttpStatus.CONFLICT, "Gift card product code already exists: " + code);

        fill(product, req, code);
        GiftCardProductResponse saved = toResponse(productRepo.save(product));
        adminAudit.record(adminUserId, "GIFT_CARD_PRODUCT_UPDATE", "GIFT_CARD_PRODUCT", id,
            "Admin updated gift card product " + id, before, summarise(saved));
        return saved;
    }

    @Transactional
    public GiftCardProductResponse activate(Long adminUserId, Long id) {
        GiftCardProduct product = productOrThrow(id);
        String before = summarise(toResponse(product));
        product.setActive(true);
        GiftCardProductResponse saved = toResponse(productRepo.save(product));
        adminAudit.record(adminUserId, "GIFT_CARD_PRODUCT_ACTIVATE", "GIFT_CARD_PRODUCT", id,
            "Admin activated gift card product " + id, before, summarise(saved));
        return saved;
    }

    @Transactional
    public GiftCardProductResponse deactivate(Long adminUserId, Long id) {
        GiftCardProduct product = productOrThrow(id);
        String before = summarise(toResponse(product));
        product.setActive(false);
        GiftCardProductResponse saved = toResponse(productRepo.save(product));
        adminAudit.record(adminUserId, "GIFT_CARD_PRODUCT_DEACTIVATE", "GIFT_CARD_PRODUCT", id,
            "Admin deactivated gift card product " + id, before, summarise(saved));
        return saved;
    }

    private static String summarise(GiftCardProductResponse p) {
        return "active:" + p.active()
            + " fixed:" + num(p.fixedAmount())
            + " min:" + num(p.minimumAmount())
            + " max:" + num(p.maximumAmount())
            + " customAmount:" + p.customAmountAllowed()
            + " validDays:" + num(p.validDaysAfterActivation())
            + " window:" + p.validFrom() + ".." + p.validUntil();
    }

    private static String num(Object value) {
        return AdminActivityLogService.safeNumber(value);
    }

    /** A product referenced by any issued gift card cannot be deleted — deactivate it instead. */
    @Transactional
    public void delete(Long adminUserId, Long id) {
        GiftCardProduct product = productOrThrow(id);
        if (giftCardRepo.existsByProductId(id))
            throw new ApiException(HttpStatus.CONFLICT,
                "Cannot delete a gift card product that has issued gift cards — deactivate it instead");
        boolean wasActive = product.isActive();
        productRepo.delete(product);
        // D1c - a delete leaves nothing behind to inspect afterwards, which is precisely why it is
        // the category of change an audit trail exists for. The row records the product id and a
        // scalar state, never the operator-supplied product code: free text handed to the audit
        // guard can trip its card-number rule and roll the deletion back (see D1c-NEW-1).
        adminAudit.record(adminUserId, "GIFT_CARD_PRODUCT_DELETE", "GIFT_CARD_PRODUCT", id,
            "Admin deleted gift card product " + id, "active:" + wasActive, null);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    static String normalizeCode(String raw) {
        return raw == null ? null : raw.trim().toUpperCase(Locale.ROOT);
    }

    GiftCardProduct productOrThrow(Long id) {
        return productRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Gift card product not found: " + id));
    }

    /** Package-private — reused by {@code GiftCardService} to look up a product by code for issuance. */
    GiftCardProduct productByCodeOrThrow(String rawCode) {
        String code = normalizeCode(rawCode);
        return productRepo.findByProductCodeIgnoreCase(code)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Gift card product not found: " + code));
    }

    private void validate(GiftCardProductRequest req) {
        // Bean validation already covers: productCode/name/currency required,
        // fixedAmount/minimumAmount/maximumAmount > 0 when present.
        if (req.minimumAmount() != null && req.maximumAmount() != null
                && req.maximumAmount().compareTo(req.minimumAmount()) < 0)
            throw new ApiException(HttpStatus.BAD_REQUEST, "maximumAmount must be >= minimumAmount");

        if (req.fixedAmount() != null && req.minimumAmount() != null && req.maximumAmount() != null
                && (req.fixedAmount().compareTo(req.minimumAmount()) < 0
                    || req.fixedAmount().compareTo(req.maximumAmount()) > 0))
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "fixedAmount must be within the minimumAmount/maximumAmount range");

        boolean customAllowed = req.customAmountAllowed() != null && req.customAmountAllowed();
        if (!customAllowed && req.fixedAmount() == null)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "fixedAmount is required when customAmountAllowed is false");

        if (req.validFrom() != null && req.validUntil() != null && req.validFrom().isAfter(req.validUntil()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "validFrom must be on or before validUntil");
    }

    private void fill(GiftCardProduct product, GiftCardProductRequest req, String normalizedCode) {
        product.setProductCode(normalizedCode);
        product.setName(req.name());
        product.setDescription(req.description());
        product.setCurrency(req.currency().trim().toUpperCase(Locale.ROOT));
        product.setFixedAmount(req.fixedAmount());
        product.setMinimumAmount(req.minimumAmount());
        product.setMaximumAmount(req.maximumAmount());
        product.setCustomAmountAllowed(req.customAmountAllowed() != null && req.customAmountAllowed());
        product.setValidDaysAfterActivation(req.validDaysAfterActivation());
        if (req.active() != null) product.setActive(req.active());
        product.setValidFrom(req.validFrom());
        product.setValidUntil(req.validUntil());
    }

    GiftCardProductResponse toResponse(GiftCardProduct p) {
        return new GiftCardProductResponse(
            p.getId(), p.getProductCode(), p.getName(), p.getDescription(), p.getCurrency(),
            p.getFixedAmount(), p.getMinimumAmount(), p.getMaximumAmount(), p.isCustomAmountAllowed(),
            p.getValidDaysAfterActivation(), p.isActive(), p.getValidFrom(), p.getValidUntil(),
            p.getCreatedAt(), p.getUpdatedAt(), p.getVersion()
        );
    }
}
