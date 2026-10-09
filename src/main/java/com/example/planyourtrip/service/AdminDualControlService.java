package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.AdminDualControlDto.DualControlApprovalResponse;
import com.example.planyourtrip.dto.AdminDualControlDto.DualControlRequestResponse;
import com.example.planyourtrip.dto.AdminDualControlDto.OwnerAssignmentProposal;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PartnerHotelDto.AssignOwnerRequest;
import com.example.planyourtrip.dto.PartnerHotelDto.PartnerHotelResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.AdminDualControlRequest;
import com.example.planyourtrip.model.DualControlStatus;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdminDualControlRequestRepository;
import com.example.planyourtrip.repository.AdminProfileAssignmentRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.rbac.AdminPermission;
import com.example.planyourtrip.security.rbac.AdminProfile;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.criteria.Predicate;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

/**
 * RBAC R6 — dual control for A16 {@code admin.place.owner.assign}: moving a property to another company happens only
 * after a second administrator approves it (RBAC V1.1 §22.6, AP-5).
 *
 * <p><b>Lifecycle.</b> {@code POST /api/admin/hotels/{id}/assign-owner} submits a {@code PENDING} request valid for
 * 24 hours. A different eligible administrator approves it — the move runs then, in the approval's transaction — or
 * rejects it with a reason; the requester may cancel it. A request past its 24 hours is {@code EXPIRED}; one whose
 * target or requester changed is {@code STALE}. Every state but {@code PENDING} is terminal.
 *
 * <p><b>Eligibility.</b> Requester and approver must both be enabled {@code ADMIN} accounts holding A16 — only
 * {@code PLATFORM_OWNER} does — so the workflow needs two of them; there is no break-glass path. The endpoint rules
 * require A16 for every operation and a session fresh within 15 minutes to submit and to approve (step-up). The
 * approval rechecks both accounts under the A16 holders' row locks, the ones profile changes take.
 *
 * <p><b>Execution.</b> The approval executes the stored payload only — never the approver's request — after
 * re-reading the place under a row lock and checking that its owner is still the one the requester saw, that the
 * proposed company may still own properties and that the payload digest matches. The move, the request's
 * {@code APPROVED} state, {@code HOTEL_ASSIGN_OWNER} and {@code DUAL_CONTROL_APPROVE} commit together or not at all.
 *
 * <p><b>Expiry and stale state are persisted.</b> A decision attempt that finds the request expired or stale commits
 * that terminal state and its audit row first, then answers 409; the answer is thrown after the transaction, so it
 * cannot roll the transition back. Reading never writes: a reader sees an overdue request as {@code EXPIRED} (the
 * project's lazy-expiry pattern, as for partner invitations).
 *
 * <p><b>Locks.</b> Always in one order: the request row, then the place row, then the A16 holders' assignment rows
 * (in id order). Profile changes take only the last; nothing takes them in another order, so no cycle can form.
 * Competing decisions on one request serialize on its row lock and only the first finds it pending.
 */
@Service
public class AdminDualControlService {

    public static final String SELF_APPROVAL_FORBIDDEN = "SELF_APPROVAL_FORBIDDEN";
    public static final String DUAL_CONTROL_NOT_PENDING = "DUAL_CONTROL_NOT_PENDING";
    public static final String DUAL_CONTROL_EXPIRED = "DUAL_CONTROL_EXPIRED";
    public static final String DUAL_CONTROL_STALE = "DUAL_CONTROL_STALE";
    public static final String DUAL_CONTROL_PENDING_EXISTS = "DUAL_CONTROL_PENDING_EXISTS";

    /** §22.6: a request is valid for 24 hours. */
    public static final Duration VALIDITY = Duration.ofHours(24);

    static final String OWNER_ASSIGN = AdminPermission.PLACE_OWNER_ASSIGN.key();
    static final String TARGET_PLACE = "PLACE";

    /** Machine reasons recorded on a stale request ({@code decision_reason}) and in its audit row. */
    static final String STALE_PLACE_MISSING = "PLACE_MISSING";
    static final String STALE_OWNER_CHANGED = "OWNER_CHANGED";
    static final String STALE_PROPOSED_OWNER_MISSING = "PROPOSED_OWNER_MISSING";
    static final String STALE_PROPOSED_OWNER_NOT_APPROVED = "PROPOSED_OWNER_NOT_APPROVED";
    static final String STALE_REQUESTER_NOT_ELIGIBLE = "REQUESTER_NOT_ELIGIBLE";
    static final String STALE_PAYLOAD_MISMATCH = "PAYLOAD_DIGEST_MISMATCH";

    private static final Set<String> SORT_FIELDS = Set.of("requestedAt", "expiresAt");

    private final AdminDualControlRequestRepository requests;
    private final PlaceRepository places;
    private final PartnerProfileRepository partnerProfiles;
    private final UserRepository users;
    private final AdminProfileAssignmentRepository assignments;
    private final PartnerPropertyService properties;
    private final AdminActivityLogService audit;
    private final ObjectMapper mapper;
    private final Clock clock;
    private final TransactionTemplate tx;

    public AdminDualControlService(AdminDualControlRequestRepository requests, PlaceRepository places,
                                   PartnerProfileRepository partnerProfiles, UserRepository users,
                                   AdminProfileAssignmentRepository assignments, PartnerPropertyService properties,
                                   AdminActivityLogService audit, ObjectMapper mapper, Clock clock,
                                   PlatformTransactionManager transactionManager) {
        this.requests = requests;
        this.places = places;
        this.partnerProfiles = partnerProfiles;
        this.users = users;
        this.assignments = assignments;
        this.properties = properties;
        this.audit = audit;
        this.mapper = mapper;
        this.clock = clock;
        this.tx = new TransactionTemplate(transactionManager);
    }

    // ── Submit ───────────────────────────────────────────────────────────────

    /**
     * {@code POST /api/admin/hotels/{hotelId}/assign-owner}: validates the move as the direct endpoint always did
     * (404 unknown hotel or company, 422 unapproved company) and stores it as a pending request. A second open
     * request for the same place is 409 {@code DUAL_CONTROL_PENDING_EXISTS}, also when two submissions race (the
     * live unique key refuses the second).
     */
    public DualControlRequestResponse submit(Long requesterId, Long hotelId, AssignOwnerRequest req) {
        String reason = cleanReason(req.reason());
        try {
            return tx.execute(status -> doSubmit(requesterId, hotelId, req.partnerProfileId(), reason));
        } catch (DataIntegrityViolationException raced) {
            throw pendingExists();
        }
    }

    private DualControlRequestResponse doSubmit(Long requesterId, Long hotelId, Long partnerProfileId, String reason) {
        if (!holdsOwnerAssign(requesterId)) throw denied();
        Place place = properties.requireHotel(hotelId);
        PartnerProfile proposed = properties.requireAssignableOwner(partnerProfileId);
        Instant now = clock.instant();

        Optional<AdminDualControlRequest> open = requests.findOpen(OWNER_ASSIGN, TARGET_PLACE, place.getId());
        if (open.isPresent()) {
            if (open.get().isOpenAt(now)) throw pendingExists();
            // an overdue request still holds the live key: close it as expired before taking the key
            AdminDualControlRequest overdue = requests.lockById(open.get().getId()).orElseThrow();
            if (overdue.isOpenAt(now)) throw pendingExists();
            if (overdue.getStatus() == DualControlStatus.PENDING) {
                expire(overdue, now);
                requests.saveAndFlush(overdue);
            }
        }

        Long expectedOwner = place.getOwner() == null ? null : place.getOwner().getId();
        String payload = payload(place.getId(), proposed.getId(), expectedOwner);

        AdminDualControlRequest request = new AdminDualControlRequest();
        request.setPermission(OWNER_ASSIGN);
        request.setTargetType(TARGET_PLACE);
        request.setTargetId(place.getId());
        request.setPayload(payload);
        request.setPayloadDigest(digest(payload));
        request.setRequestedBy(users.getReferenceById(requesterId));
        request.setRequestedAt(now);
        request.setExpiresAt(now.plus(VALIDITY));
        request.setReason(reason);
        AdminDualControlRequest saved = requests.saveAndFlush(request);

        audit.record(requesterId, "DUAL_CONTROL_REQUEST", "DUAL_CONTROL_REQUEST", saved.getId(),
            "Requested moving hotel " + place.getId() + " to partner profile " + proposed.getId()
                + " (current owner " + ownerLabel(expectedOwner) + ")" + (reason == null ? "" : ": " + reason),
            null, DualControlStatus.PENDING.name());
        return view(saved, requesterId, now);
    }

    // ── Approve ──────────────────────────────────────────────────────────────

    /** {@code POST …/{id}/approve}: executes the stored move, or persists why it can no longer run and answers 409. */
    public DualControlApprovalResponse approve(Long approverId, Long requestId) {
        Decision decision = tx.execute(status -> doApprove(approverId, requestId));
        return decision.result(DualControlApprovalResponse::new);
    }

    private Decision doApprove(Long approverId, Long requestId) {
        AdminDualControlRequest request = lockPending(requestId);
        if (request.getRequestedBy().getId().equals(approverId)) throw selfApproval();
        Instant now = clock.instant();
        if (!request.isOpenAt(now)) return expiredDecision(request, approverId, now);

        Optional<Place> place = places.lockById(request.getTargetId());
        Set<Long> eligible = lockOwnerAssignHolders();
        if (!eligible.contains(approverId)) throw denied();

        String stale = staleReason(request, place, eligible);
        if (stale != null) {
            request.markStale(now, stale);
            requests.saveAndFlush(request);
            audit.record(approverId, "DUAL_CONTROL_STALE", "DUAL_CONTROL_REQUEST", request.getId(),
                "Request " + request.getId() + " can no longer run as reviewed: " + stale,
                DualControlStatus.PENDING.name(), DualControlStatus.STALE.name());
            return Decision.conflict(view(request, approverId, now),
                new ApiException(HttpStatus.CONFLICT, DUAL_CONTROL_STALE,
                    "The property or the request changed after it was submitted (" + stale + ")"));
        }

        JsonNode payload = readPayload(request);
        PartnerProfile proposed = partnerProfiles.findById(payload.get("proposedOwnerProfileId").asLong())
            .orElseThrow();
        PartnerHotelResponse result = properties.executeOwnerAssignment(approverId, place.orElseThrow(), proposed);

        request.approve(users.getReferenceById(approverId), now);
        requests.saveAndFlush(request);
        audit.record(approverId, "DUAL_CONTROL_APPROVE", "DUAL_CONTROL_REQUEST", request.getId(),
            "Approved request " + request.getId() + " of administrator " + request.getRequestedBy().getId()
                + ": hotel " + request.getTargetId() + " moved to partner profile " + proposed.getId(),
            DualControlStatus.PENDING.name(), DualControlStatus.APPROVED.name());
        return Decision.done(view(request, approverId, now), result);
    }

    /** Why the stored move can no longer run as reviewed, or null when it can. Reads only locked or stored state. */
    private String staleReason(AdminDualControlRequest request, Optional<Place> place, Set<Long> eligible) {
        if (!eligible.contains(request.getRequestedBy().getId())) return STALE_REQUESTER_NOT_ELIGIBLE;
        if (!digest(request.getPayload()).equals(request.getPayloadDigest())) return STALE_PAYLOAD_MISMATCH;
        JsonNode payload = readPayload(request);
        if (place.isEmpty() || payload.get("placeId").asLong() != place.get().getId()) return STALE_PLACE_MISSING;
        Long expected = payload.get("expectedOwnerProfileId").isNull()
            ? null : payload.get("expectedOwnerProfileId").asLong();
        Long current = place.get().getOwner() == null ? null : place.get().getOwner().getId();
        if (!Objects.equals(expected, current)) return STALE_OWNER_CHANGED;
        Optional<PartnerProfile> proposed = partnerProfiles.findById(payload.get("proposedOwnerProfileId").asLong());
        if (proposed.isEmpty()) return STALE_PROPOSED_OWNER_MISSING;
        if (!PartnerPropertyService.canOwnProperties(proposed.get())) return STALE_PROPOSED_OWNER_NOT_APPROVED;
        return null;
    }

    // ── Reject / cancel ──────────────────────────────────────────────────────

    /** {@code POST …/{id}/reject}: a different eligible administrator refuses the request, with a reason. */
    public DualControlRequestResponse reject(Long rejecterId, Long requestId, String rawReason) {
        String reason = cleanReason(rawReason);
        if (reason == null) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", "reason", "A reason is required");
        }
        Decision decision = tx.execute(status -> {
            AdminDualControlRequest request = lockPending(requestId);
            if (request.getRequestedBy().getId().equals(rejecterId)) throw selfApproval();
            Instant now = clock.instant();
            if (!request.isOpenAt(now)) return expiredDecision(request, rejecterId, now);
            if (!lockOwnerAssignHolders().contains(rejecterId)) throw denied();

            request.reject(users.getReferenceById(rejecterId), now, reason);
            requests.saveAndFlush(request);
            audit.record(rejecterId, "DUAL_CONTROL_REJECT", "DUAL_CONTROL_REQUEST", request.getId(),
                "Rejected request " + request.getId() + " of administrator " + request.getRequestedBy().getId()
                    + ": " + reason,
                DualControlStatus.PENDING.name(), DualControlStatus.REJECTED.name());
            return Decision.done(view(request, rejecterId, now), null);
        });
        return decision.result((view, result) -> view);
    }

    /** {@code POST …/{id}/cancel}: only the requester withdraws their own pending request. */
    public DualControlRequestResponse cancel(Long requesterId, Long requestId) {
        Decision decision = tx.execute(status -> {
            AdminDualControlRequest request = lockPending(requestId);
            if (!request.getRequestedBy().getId().equals(requesterId)) {
                throw new ApiException(HttpStatus.FORBIDDEN, PartnerAccessService.PERMISSION_DENIED,
                    "Only the requester can cancel a request");
            }
            Instant now = clock.instant();
            if (!request.isOpenAt(now)) return expiredDecision(request, requesterId, now);

            request.cancel(now);
            requests.saveAndFlush(request);
            audit.record(requesterId, "DUAL_CONTROL_CANCEL", "DUAL_CONTROL_REQUEST", request.getId(),
                "Cancelled own request " + request.getId(),
                DualControlStatus.PENDING.name(), DualControlStatus.CANCELLED.name());
            return Decision.done(view(request, requesterId, now), null);
        });
        return decision.result((view, result) -> view);
    }

    // ── Read ─────────────────────────────────────────────────────────────────

    /** The request queue, newest first; {@code status} filters by the state a reader sees (overdue = EXPIRED). */
    @Transactional(readOnly = true)
    public PageResponse<DualControlRequestResponse> list(Long callerId, DualControlStatus status, Integer page,
                                                         Integer size, String sort) {
        Instant now = clock.instant();
        Pageable pageable = AdminPaging.of(page, size, sort, SORT_FIELDS, "requestedAt");
        return PageResponse.of(requests.findAll(statusAt(status, now), pageable).map(r -> view(r, callerId, now)));
    }

    @Transactional(readOnly = true)
    public DualControlRequestResponse get(Long callerId, Long requestId) {
        return view(requests.findById(requestId).orElseThrow(AdminDualControlService::notFound), callerId,
            clock.instant());
    }

    private static Specification<AdminDualControlRequest> statusAt(DualControlStatus status, Instant now) {
        return (root, query, cb) -> {
            if (status == null) return cb.conjunction();
            Predicate pending = cb.equal(root.get("status"), DualControlStatus.PENDING);
            Predicate overdue = cb.lessThanOrEqualTo(root.get("expiresAt"), now);
            return switch (status) {
                case PENDING -> cb.and(pending, cb.not(overdue));
                case EXPIRED -> cb.or(cb.equal(root.get("status"), DualControlStatus.EXPIRED), cb.and(pending, overdue));
                default -> cb.equal(root.get("status"), status);
            };
        };
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    /** The request, row-locked; 404 when unknown, 409 {@code DUAL_CONTROL_NOT_PENDING} once closed. */
    private AdminDualControlRequest lockPending(Long requestId) {
        AdminDualControlRequest request = requests.lockById(requestId).orElseThrow(AdminDualControlService::notFound);
        if (request.getStatus() != DualControlStatus.PENDING) {
            throw new ApiException(HttpStatus.CONFLICT, DUAL_CONTROL_NOT_PENDING,
                "This request is already " + request.getStatus().name().toLowerCase());
        }
        return request;
    }

    private Decision expiredDecision(AdminDualControlRequest request, Long callerId, Instant now) {
        expire(request, now);
        requests.saveAndFlush(request);
        return Decision.conflict(view(request, callerId, now),
            new ApiException(HttpStatus.CONFLICT, DUAL_CONTROL_EXPIRED, "This request expired before a decision"));
    }

    /** Persists the expiry of an overdue pending request; a system event, recorded with no actor. */
    private void expire(AdminDualControlRequest request, Instant now) {
        request.expire(now);
        audit.recordSystem("DUAL_CONTROL_EXPIRE", "DUAL_CONTROL_REQUEST", request.getId(),
            "Request " + request.getId() + " of administrator " + request.getRequestedBy().getId()
                + " expired at " + request.getExpiresAt() + " without a decision");
    }

    /**
     * The ids of the enabled {@code ADMIN} accounts holding A16 now, their assignment rows locked until the
     * transaction ends (profiles in declaration order, rows in id order) so no grant or revoke can interleave.
     */
    private Set<Long> lockOwnerAssignHolders() {
        Set<Long> holders = new HashSet<>();
        for (AdminProfile profile : AdminProfile.values()) {
            if (!profile.permissions().contains(AdminPermission.PLACE_OWNER_ASSIGN)) continue;
            assignments.lockActiveHoldersOf(profile).forEach(a -> holders.add(a.getUser().getId()));
        }
        return holders;
    }

    private boolean holdsOwnerAssign(Long userId) {
        Optional<User> user = users.findById(userId);
        return user.isPresent() && user.get().isEnabled() && "ADMIN".equals(user.get().getRole())
            && AdminProfile.permissionsOf(assignments.findActiveProfiles(userId))
                .contains(AdminPermission.PLACE_OWNER_ASSIGN);
    }

    private String payload(Long placeId, Long proposedOwnerProfileId, Long expectedOwnerProfileId) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("placeId", placeId);
        payload.put("proposedOwnerProfileId", proposedOwnerProfileId);
        payload.put("expectedOwnerProfileId", expectedOwnerProfileId);
        try {
            return mapper.writeValueAsString(payload);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Cannot serialise a dual-control payload", e);
        }
    }

    private JsonNode readPayload(AdminDualControlRequest request) {
        try {
            return mapper.readTree(request.getPayload());
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Stored dual-control payload " + request.getId() + " is unreadable", e);
        }
    }

    static String digest(String payload) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                .digest(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    private DualControlRequestResponse view(AdminDualControlRequest r, Long callerId, Instant now) {
        JsonNode payload = readPayload(r);
        Long placeId = payload.get("placeId").asLong();
        Long expected = payload.get("expectedOwnerProfileId").isNull()
            ? null : payload.get("expectedOwnerProfileId").asLong();
        Long proposed = payload.get("proposedOwnerProfileId").asLong();
        OwnerAssignmentProposal proposal = new OwnerAssignmentProposal(
            placeId, places.findById(placeId).map(Place::getName).orElse(null),
            expected, expected == null ? null : businessName(expected),
            proposed, businessName(proposed));
        User requester = r.getRequestedBy();
        User decider = r.getApprovedBy() != null ? r.getApprovedBy() : r.getRejectedBy();
        return new DualControlRequestResponse(r.getId(), r.getPermission(), r.getTargetType(), r.getTargetId(),
            proposal, r.statusAt(now).name(), requester.getId(), requester.getFullName(), r.getRequestedAt(),
            r.getExpiresAt(), r.getReason(), decider == null ? null : decider.getId(), r.getDecidedAt(),
            r.getDecisionReason(), requester.getId().equals(callerId));
    }

    private String businessName(Long partnerProfileId) {
        return partnerProfiles.findById(partnerProfileId).map(PartnerProfile::getBusinessName).orElse(null);
    }

    private static String ownerLabel(Long ownerId) {
        return ownerId == null ? "none" : "partner profile " + ownerId;
    }

    private static String cleanReason(String reason) {
        String trimmed = reason == null || reason.isBlank() ? null : reason.trim();
        if (trimmed != null && AdminActivityLogService.looksLikeCredential(trimmed)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", "reason",
                "The reason must not contain credentials");
        }
        return trimmed;
    }

    private static ApiException denied() {
        return new ApiException(HttpStatus.FORBIDDEN, PartnerAccessService.PERMISSION_DENIED, "Access denied");
    }

    private static ApiException selfApproval() {
        return new ApiException(HttpStatus.FORBIDDEN, SELF_APPROVAL_FORBIDDEN,
            "A different administrator must decide this request");
    }

    private static ApiException pendingExists() {
        return new ApiException(HttpStatus.CONFLICT, DUAL_CONTROL_PENDING_EXISTS,
            "This property already has a pending owner-assignment request");
    }

    private static ApiException notFound() {
        return new ApiException(HttpStatus.NOT_FOUND, "Dual-control request not found");
    }

    /**
     * What a decision transaction committed: the request as it now is, the executed action's result, or a conflict
     * to answer only after the commit (expiry, stale), so the persisted transition and its audit survive the 409.
     */
    private record Decision(DualControlRequestResponse view, PartnerHotelResponse result, ApiException afterCommit) {
        static Decision done(DualControlRequestResponse view, PartnerHotelResponse result) {
            return new Decision(view, result, null);
        }

        static Decision conflict(DualControlRequestResponse view, ApiException afterCommit) {
            return new Decision(view, null, afterCommit);
        }

        <T> T result(java.util.function.BiFunction<DualControlRequestResponse, PartnerHotelResponse, T> success) {
            if (afterCommit != null) throw afterCommit;
            return success.apply(view, result);
        }
    }
}
