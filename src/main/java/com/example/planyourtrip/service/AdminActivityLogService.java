package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.AdminActivityLogDto.AdminActivityLogResponse;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.AdminActivityLog;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.regex.Pattern;

/**
 * D1a — the single, centralised writer and reader for the administrative audit trail.
 *
 * <h2>Transaction semantics (D1a-7)</h2>
 *
 * {@link #record} uses the default {@code REQUIRED} propagation and is intended to be called
 * <em>from inside</em> the service method performing the mutation. It therefore joins that
 * method's transaction, which gives both halves of the guarantee:
 * <ul>
 *   <li>the mutation rolls back → the audit row rolls back with it, so no audit can describe an
 *       action that did not happen;</li>
 *   <li>the audit insert fails → the exception propagates and the mutation rolls back too, so no
 *       action can happen without being recorded.</li>
 * </ul>
 *
 * <p>This is a deliberate departure from {@link PartnerActivityLogService#log}, which swallows
 * failures and no-ops. That defensiveness is reasonable for a log retrofitted into partner flows
 * where losing an entry is preferable to breaking the flow; it is <em>not</em> acceptable for an
 * administrative trail, where a silently missing entry is precisely the failure mode this phase
 * exists to remove. Nothing here is asynchronous: an {@code @Async} or after-commit write would
 * reintroduce "action succeeded, audit lost" and cannot be made atomic.
 *
 * <h2>Sensitive-data policy (D1a-6, D1a-20)</h2>
 *
 * {@link #record} rejects any text that matches {@link #FORBIDDEN} — a defence-in-depth guard so a
 * future caller cannot casually pass a token, password, secret or raw card/account number into the
 * trail. Callers are expected to pass identifiers and short scalar states, never serialised
 * entities or request bodies.
 */
@Service
public class AdminActivityLogService {

    /** Actor label used when no human performed the action (scheduled and batch operations). */
    public static final String SYSTEM_ACTOR = "SYSTEM";

    /**
     * Defence-in-depth: text that looks like a credential is refused outright rather than stored.
     * This is not a substitute for callers passing safe values — it is a backstop that turns a
     * mistake into a loud failure instead of a silent leak into permanent storage.
     */
    private static final Pattern FORBIDDEN = Pattern.compile(
        "(?i)(password|passwd|secret|bearer\\s|eyJ[A-Za-z0-9_-]{10,}|api[_-]?key|private[_-]?key"
            + "|cvv|iban|swift|\\b\\d{13,19}\\b)");

    private final AdminActivityLogRepository logRepo;
    private final UserRepository userRepo;

    public AdminActivityLogService(AdminActivityLogRepository logRepo, UserRepository userRepo) {
        this.logRepo = logRepo;
        this.userRepo = userRepo;
    }

    /**
     * Records one administrative action. Call this from within the mutating service method so the
     * write shares that method's transaction.
     *
     * @param actorUserId the acting admin, or {@code null} for a system/batch action
     * @param action      stable verb, e.g. {@code PARTNER_APPROVE}
     * @param targetType  stable target class, e.g. {@code PARTNER_PROFILE}
     * @param targetId    affected row id
     * @param description short, safe summary
     * @param beforeState safe scalar state before, or {@code null}
     * @param afterState  safe scalar state after, or {@code null}
     */
    @Transactional
    public void record(Long actorUserId, String action, String targetType, Long targetId,
                        String description, String beforeState, String afterState) {
        if (action == null || action.isBlank()) {
            throw new IllegalArgumentException("Admin audit requires an action");
        }
        reject(description); reject(beforeState); reject(afterState);

        AdminActivityLog entry = new AdminActivityLog();
        entry.setActorUserId(actorUserId);
        entry.setActorEmail(resolveActorEmail(actorUserId));
        entry.setAction(action);
        entry.setTargetType(targetType);
        entry.setTargetId(targetId);
        entry.setDescription(truncate(description, 4000));
        entry.setBeforeState(truncate(beforeState, 500));
        entry.setAfterState(truncate(afterState, 500));
        logRepo.save(entry);
    }

    /** Convenience for actions with no meaningful before/after pair. */
    @Transactional
    public void record(Long actorUserId, String action, String targetType, Long targetId,
                        String description) {
        record(actorUserId, action, targetType, targetId, description, null, null);
    }

    /** Batch/scheduled action performed by no human — see {@link #SYSTEM_ACTOR}. */
    @Transactional
    public void recordSystem(String action, String targetType, Long targetId, String description) {
        record(null, action, targetType, targetId, description, null, null);
    }

    /**
     * Newest-first, database-side paginated read. Every filter is optional. Ordering is fixed in the
     * query and is not client-controllable, so the trail has no sort-injection surface.
     */
    @Transactional(readOnly = true)
    public PageResponse<AdminActivityLogResponse> search(Long actorUserId, String action,
                                                          String targetType, Long targetId,
                                                          Instant from, Instant to,
                                                          Integer page, Integer size) {
        if (from != null && to != null && from.isAfter(to)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "from must not be after to");
        }
        Pageable pageable = PageRequest.of(safePage(page), safeSize(size));
        return PageResponse.of(
            logRepo.search(actorUserId, blankToNull(action), blankToNull(targetType), targetId,
                           from, to, pageable)
                .map(this::toResponse));
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    /**
     * Snapshots the actor's email. Resolution failure is not fatal — the action still happened and
     * must still be recorded — so an unresolvable id degrades to a stable marker rather than
     * aborting the mutation, while {@code actorUserId} preserves the identity either way.
     */
    private String resolveActorEmail(Long actorUserId) {
        if (actorUserId == null) return SYSTEM_ACTOR;
        return userRepo.findById(actorUserId)
            .map(u -> u.getEmail() == null || u.getEmail().isBlank() ? "user:" + actorUserId : u.getEmail())
            .orElse("user:" + actorUserId);
    }

    /**
     * D3H - renders a number for a {@code beforeState}/{@code afterState} string so a legitimate
     * value can never be mistaken for a credential by {@link #FORBIDDEN}.
     *
     * <p>The money columns in this schema are {@code precision = 15, scale = 2}, so a price or an
     * amount may legally carry a thirteen-digit integer part. Written straight into a state string
     * that run matches {@code \b\d{13,19}\b}, {@link #reject} throws, and - because the audit
     * write shares the caller's transaction - the perfectly valid pricing change being audited
     * rolls back with it. The guard is correct and is not being weakened; the caller is simply
     * given a way to pass a value it cannot trip. Every realistic amount is returned unchanged;
     * only an absurd one degrades to a magnitude marker, which still tells a reviewer what
     * happened.
     */
    static String safeNumber(Object value) {
        if (value == null) return "-";
        String s = value instanceof java.math.BigDecimal bd ? bd.toPlainString() : String.valueOf(value);
        for (String run : s.split("\\D+")) {
            if (run.length() >= 13) return "(out-of-range)";
        }
        return s;
    }

    private static void reject(String value) {
        if (value != null && FORBIDDEN.matcher(value).find()) {
            throw new IllegalArgumentException(
                "Refusing to write credential-shaped text into the admin audit trail");
        }
    }

    private static String truncate(String s, int max) {
        if (s == null) return null;
        return s.length() <= max ? s : s.substring(0, max);
    }

    private static String blankToNull(String s) {
        return s == null || s.isBlank() ? null : s;
    }

    /** Clamped rather than rejected, so a malformed page never becomes a 500 (see D0/I findings). */
    private static int safePage(Integer page) { return page == null || page < 0 ? 0 : page; }

    private static int safeSize(Integer size) {
        if (size == null || size < 1) return 20;
        return Math.min(size, 200);
    }

    private AdminActivityLogResponse toResponse(AdminActivityLog l) {
        return new AdminActivityLogResponse(
            l.getId(), l.getActorUserId(), l.getActorEmail(), l.getAction(),
            l.getTargetType(), l.getTargetId(), l.getDescription(),
            l.getBeforeState(), l.getAfterState(), l.getCreatedAt());
    }
}
