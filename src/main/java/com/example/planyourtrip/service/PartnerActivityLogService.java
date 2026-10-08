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
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerPermission;
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
        // RBAC V1.1 §22.1 AU-2 — the actor's email as it is now, kept even if the account changes later.
        entry.setActorEmail(actor.getEmail());
        entry.setAction(action);
        entry.setEntityType(entityType);
        entry.setEntityId(entityId);
        entry.setDescription(description);
        logRepo.save(entry);
    }

    /**
     * RBAC R3a — the strict writer for security-sensitive partner events: team, grants, owners and the
     * payout account (RBAC V1.1 §22.1 AU-1…AU-3).
     *
     * <p>Unlike {@link #log}, nothing is swallowed. It joins the mutating transaction ({@code REQUIRED}): the
     * mutation rolls back → the row rolls back; the row cannot be written → the exception propagates and the
     * mutation rolls back. Each row carries the actor's id <em>and</em> email as they are now (a snapshot,
     * never re-resolved), before/after as short safe scalars such as {@code MANAGER@COMPANY:456}, and the
     * reason when one was given. Text that looks like a credential is refused, with the admin trail's guard.
     *
     * <p>Deliberately not named {@code record}: that name is the administrative trail's, whose inventory
     * test reads every {@code .record(} call site in the source.
     *
     * @param actorUserId the acting user; never null here — system rows are written only by migration M-6
     */
    @Transactional
    public void audit(Long partnerProfileId, Long actorUserId, String action, String entityType, Long entityId,
                      String description, String beforeState, String afterState, String reason) {
        if (partnerProfileId == null || actorUserId == null || action == null || action.isBlank()) {
            throw new IllegalArgumentException("A partner security audit row needs a company, an actor and an action");
        }
        guard(description); guard(beforeState); guard(afterState); guard(reason);
        PartnerProfile profile = partnerProfileRepo.findById(partnerProfileId)
            .orElseThrow(() -> new IllegalStateException("Audited company not found: " + partnerProfileId));
        User actor = userRepo.findById(actorUserId)
            .orElseThrow(() -> new IllegalStateException("Audited actor not found: " + actorUserId));

        PartnerActivityLog entry = new PartnerActivityLog();
        entry.setPartnerProfile(profile);
        entry.setActorUser(actor);
        entry.setActorEmail(actor.getEmail() == null || actor.getEmail().isBlank()
            ? "user:" + actorUserId : actor.getEmail());
        entry.setAction(action);
        entry.setEntityType(entityType);
        entry.setEntityId(entityId);
        entry.setDescription(truncate(description, 4000));
        entry.setBeforeState(truncate(beforeState, 500));
        entry.setAfterState(truncate(afterState, 500));
        entry.setReason(truncate(reason, 500));
        logRepo.save(entry);
    }

    @Transactional(readOnly = true)
    public List<PartnerActivityLogResponse> listMine(Long userId) {
        // RBAC R3b — COMPANY P05 (AU-4): owners and company-level managers; the company is the caller's workspace
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        partnerAccess.requireCompanyPermission(access, PartnerPermission.ACTIVITY_LOG_VIEW, null);
        return logRepo.findByPartnerProfileIdOrderByCreatedAtDesc(access.companyId())
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

    private static void guard(String value) {
        if (value != null && AdminActivityLogService.FORBIDDEN.matcher(value).find()) {
            throw new IllegalArgumentException("Partner audit text must not contain credential-like content");
        }
    }

    private static String truncate(String value, int max) {
        return value == null || value.length() <= max ? value : value.substring(0, max);
    }

    private PartnerActivityLogResponse toResponse(PartnerActivityLog l) {
        User actor = l.getActorUser();
        return new PartnerActivityLogResponse(
            l.getId(), l.getPartnerProfile().getId(),
            actor == null ? null : actor.getId(), actor == null ? l.getActorEmail() : actor.getFullName(),
            l.getAction(), l.getEntityType(), l.getEntityId(), l.getDescription(),
            l.getCreatedAt()
        );
    }
}
