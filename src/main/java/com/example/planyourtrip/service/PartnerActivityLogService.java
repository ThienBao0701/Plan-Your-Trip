package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PartnerExtranetDto.PartnerActivityLogResponse;
import com.example.planyourtrip.model.PartnerActivityLog;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.PartnerActivityLogRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
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
    private final PartnerAccessService partnerAccess;

    public PartnerActivityLogService(PartnerActivityLogRepository logRepo,
                                      PartnerProfileRepository partnerProfileRepo,
                                      UserRepository userRepo,
                                      PartnerAccessService partnerAccess) {
        this.logRepo = logRepo;
        this.partnerProfileRepo = partnerProfileRepo;
        this.userRepo = userRepo;
        this.partnerAccess = partnerAccess;
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
        PartnerProfile profile = partnerAccess.requireRegistrantWorkspace(userId).profile();
        return logRepo.findByPartnerProfileIdOrderByCreatedAtDesc(profile.getId())
            .stream().map(this::toResponse).toList();
    }

    /**
     * D1c - one partner's trail, paged in the database.
     *
     * <p>This log is append-only and unbounded in time: an active property writes entries for
     * every rate, inventory and booking action, so the previous whole-trail read grew without
     * limit for exactly the partners an administrator most needs to inspect. Ordering is fixed
     * newest-first in the query and is not client-controllable, matching the administrative audit
     * trail's own read contract.
     */
    @Transactional(readOnly = true)
    public PageResponse<PartnerActivityLogResponse> adminListByPartnerPaged(
            Long partnerProfileId, Integer page, Integer size) {
        Pageable pageable = PageRequest.of(AdminPaging.safePage(page), AdminPaging.safeSize(size));
        return PageResponse.of(
            logRepo.findByPartnerProfileIdOrderByCreatedAtDescIdDesc(partnerProfileId, pageable)
                .map(this::toResponse));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private PartnerActivityLogResponse toResponse(PartnerActivityLog l) {
        return new PartnerActivityLogResponse(
            l.getId(), l.getPartnerProfile().getId(),
            l.getActorUser().getId(), l.getActorUser().getFullName(),
            l.getAction(), l.getEntityType(), l.getEntityId(), l.getDescription(),
            l.getCreatedAt()
        );
    }
}
