package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerExtranetDto.PartnerActivityLogResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PartnerActivityLog;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.PartnerActivityLogRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Records and lists partner-side activity ("who did what, on which entity, when").
 * {@link #log} is intentionally defensive (no-ops rather than throwing) so a logging
 * call embedded in an existing write flow can never itself break that flow.
 */
@Service
public class PartnerActivityLogService {

    private final PartnerActivityLogRepository logRepo;
    private final PartnerProfileRepository partnerProfileRepo;
    private final UserRepository userRepo;

    public PartnerActivityLogService(PartnerActivityLogRepository logRepo,
                                      PartnerProfileRepository partnerProfileRepo,
                                      UserRepository userRepo) {
        this.logRepo = logRepo;
        this.partnerProfileRepo = partnerProfileRepo;
        this.userRepo = userRepo;
    }

    @Transactional
    public void log(Long partnerProfileId, Long actorUserId, String action,
                     String entityType, Long entityId, String description) {
        if (partnerProfileId == null || actorUserId == null) return;
        PartnerProfile profile = partnerProfileRepo.findById(partnerProfileId).orElse(null);
        if (profile == null) return;
        User actor = userRepo.findById(actorUserId).orElse(null);
        if (actor == null) return;

        PartnerActivityLog entry = new PartnerActivityLog();
        entry.setPartnerProfile(profile);
        entry.setActorUser(actor);
        entry.setAction(action);
        entry.setEntityType(entityType);
        entry.setEntityId(entityId);
        entry.setDescription(description);
        logRepo.save(entry);
    }

    @Transactional(readOnly = true)
    public List<PartnerActivityLogResponse> listMine(Long userId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        return logRepo.findByPartnerProfileIdOrderByCreatedAtDesc(profile.getId())
            .stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<PartnerActivityLogResponse> adminListByPartner(Long partnerProfileId) {
        return logRepo.findByPartnerProfileIdOrderByCreatedAtDesc(partnerProfileId)
            .stream().map(this::toResponse).toList();
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfileRepo.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

    private PartnerActivityLogResponse toResponse(PartnerActivityLog l) {
        return new PartnerActivityLogResponse(
            l.getId(), l.getPartnerProfile().getId(),
            l.getActorUser().getId(), l.getActorUser().getFullName(),
            l.getAction(), l.getEntityType(), l.getEntityId(), l.getDescription(),
            l.getCreatedAt()
        );
    }
}
