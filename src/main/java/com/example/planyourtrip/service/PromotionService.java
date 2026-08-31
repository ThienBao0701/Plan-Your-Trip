package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.NotificationDto.BroadcastRequest;
import com.example.planyourtrip.dto.PromotionDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.NotificationType;
import com.example.planyourtrip.model.Priority;
import com.example.planyourtrip.model.Promotion;
import com.example.planyourtrip.model.PromotionTargetType;
import com.example.planyourtrip.model.RelatedEntityType;
import com.example.planyourtrip.repository.PromotionRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class PromotionService {

    private final PromotionRepository promotionRepo;
    private final NotificationService notificationService;
    private final AdminActivityLogService adminAudit;

    public PromotionService(PromotionRepository promotionRepo, NotificationService notificationService,
                            AdminActivityLogService adminAudit) {
        this.promotionRepo = promotionRepo;
        this.notificationService = notificationService;
        this.adminAudit = adminAudit;
    }

    public List<PromotionResponse> getAll() {
        return promotionRepo.findAll().stream().map(this::toResponse).toList();
    }

    public PromotionResponse getById(Long id) {
        return toResponse(promotionOrThrow(id));
    }

    @Transactional
    public PromotionResponse create(PromotionRequest req) {
        validateDates(req.startDate(), req.endDate());
        if (req.code() != null && !req.code().isBlank()
                && promotionRepo.existsByCode(req.code())) {
            throw new ApiException(HttpStatus.CONFLICT,
                "Promotion code already exists: " + req.code());
        }
        Promotion p = new Promotion();
        fill(p, req);
        Promotion saved = promotionRepo.save(p);

        notificationService.adminBroadcast(new BroadcastRequest(
            "New promotion: " + saved.getName(),
            "Check out our new promotion: " + saved.getName() + "!",
            NotificationType.PROMOTION, Priority.LOW,
            RelatedEntityType.PROMOTION, saved.getId()));

        return toResponse(saved);
    }

    @Transactional
    public PromotionResponse update(Long id, PromotionRequest req) {
        Promotion p = promotionOrThrow(id);
        validateDates(req.startDate(), req.endDate());
        if (req.code() != null && !req.code().isBlank()
                && !req.code().equals(p.getCode())
                && promotionRepo.existsByCode(req.code())) {
            throw new ApiException(HttpStatus.CONFLICT,
                "Promotion code already exists: " + req.code());
        }
        fill(p, req);
        return toResponse(promotionRepo.save(p));
    }

    /**
     * D1c - the audited administrative delete. It is a separate entry point rather than an audit
     * call inside {@link #delete(Long)} because {@code PartnerPromotionService} deletes a
     * partner's own promotion through that method; recording there would file partner activity in
     * the administrative trail.
     */
    @Transactional
    public void adminDelete(Long adminUserId, Long id) {
        Promotion promotion = promotionOrThrow(id);
        boolean wasActive = promotion.isActive();
        promotionRepo.deleteById(id);
        // Scalar state only - see the note on GiftCardProductService.delete (D1c-NEW-1).
        adminAudit.record(adminUserId, "PROMOTION_DELETE", "PROMOTION", id,
            "Admin deleted promotion " + id, "active:" + wasActive, null);
    }

    @Transactional
    public void delete(Long id) {
        promotionOrThrow(id);
        promotionRepo.deleteById(id);
    }

    PromotionResponse toResponse(Promotion p) {
        return new PromotionResponse(
            p.getId(),
            p.getName(),
            p.getCode(),
            p.getDescription(),
            p.isActive(),
            p.getStartDate(),
            p.getEndDate(),
            p.getPromotionType(),
            p.getDiscountType(),
            p.getDiscountValue(),
            p.getMaxDiscountAmount(),
            p.getMinimumStay(),
            p.getMinimumSpend(),
            p.isStackable(),
            p.getPriority(),
            p.getTargetType(),
            p.getTargetId(),
            p.getCreatedAt(),
            p.getUpdatedAt()
        );
    }

    private void fill(Promotion p, PromotionRequest req) {
        p.setName(req.name());
        p.setCode(req.code() != null && req.code().isBlank() ? null : req.code());
        p.setDescription(req.description());
        p.setPromotionType(req.promotionType());
        p.setDiscountType(req.discountType());
        p.setDiscountValue(req.discountValue());
        p.setMaxDiscountAmount(req.maxDiscountAmount());
        p.setMinimumStay(req.minimumStay());
        p.setMinimumSpend(req.minimumSpend());
        p.setStackable(req.stackable());
        p.setPriority(req.priority());
        p.setStartDate(req.startDate());
        p.setEndDate(req.endDate());
        p.setTargetType(req.targetType() != null ? req.targetType() : PromotionTargetType.ALL);
        p.setTargetId(req.targetId());
        if (req.active() != null) p.setActive(req.active());
    }

    private void validateDates(java.time.LocalDate start, java.time.LocalDate end) {
        if (!end.isAfter(start)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "endDate must be after startDate");
        }
    }

    private Promotion promotionOrThrow(Long id) {
        return promotionRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Promotion not found: " + id));
    }
}
