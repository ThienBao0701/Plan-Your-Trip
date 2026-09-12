package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.NotificationDto.*;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.NotificationRepository;
import com.example.planyourtrip.repository.UserRepository;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepo;
    private final UserRepository userRepo;
    private final AdminActivityLogService adminAudit;

    public NotificationService(NotificationRepository notificationRepo, UserRepository userRepo,
                                AdminActivityLogService adminAudit) {
        this.notificationRepo = notificationRepo;
        this.userRepo = userRepo;
        this.adminAudit = adminAudit;
    }

    @Transactional
    public NotificationResponse create(Long recipientUserId, NotificationType type, Priority priority,
                                        String title, String message,
                                        RelatedEntityType relatedEntityType, Long relatedEntityId) {
        User recipient = userRepo.findById(recipientUserId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + recipientUserId));

        Notification n = new Notification();
        n.setRecipientUser(recipient);
        n.setTitle(title);
        n.setMessage(message);
        n.setNotificationType(type);
        n.setPriority(priority != null ? priority : Priority.NORMAL);
        n.setRelatedEntityType(relatedEntityType);
        n.setRelatedEntityId(relatedEntityId);

        return toResponse(dispatch(notificationRepo.save(n)));
    }

    @Transactional
    public NotificationResponse createSystem(Long recipientUserId, String title, String message) {
        return create(recipientUserId, NotificationType.SYSTEM, Priority.NORMAL, title, message, null, null);
    }

    /**
     * D9 — the same write as {@link #create}, but in a transaction of its own.
     *
     * <p>Exists for <b>secondary</b> notifications: ones whose failure must never undo the business
     * operation that triggered them. {@link #create} is {@code REQUIRED} and therefore joins its
     * caller, which is correct for a notification the caller considers part of its own unit of work
     * — but it means a failure inside it marks the caller's transaction rollback-only, and catching
     * the exception upstream does <em>not</em> clear that flag: the caller's commit would then fail
     * with {@code UnexpectedRollbackException}. Suspending the caller's transaction is the only way
     * a caller can genuinely carry on.
     *
     * <p>The caller is still responsible for catching and logging: {@code REQUIRES_NEW} isolates the
     * rollback, it does not stop the exception propagating.
     *
     * <p><b>Trade-off, deliberately accepted:</b> because this commits independently, a notification
     * written here survives even if the caller's own transaction later rolls back. Callers must
     * therefore invoke it as late as possible, once the operation is otherwise complete.
     *
     * <p>Nothing else changes: same entity, same server-generated {@code createdAt}, same
     * {@code dispatch} extension point. This is not a second notification path — it is the same one
     * with a different transaction boundary.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public NotificationResponse createInNewTransaction(
            Long recipientUserId, NotificationType type, Priority priority,
            String title, String message,
            RelatedEntityType relatedEntityType, Long relatedEntityId) {
        // Self-invocation is intentional: this method is the proxied entry point that opens the new
        // transaction, so the delegate simply runs inside it.
        return create(recipientUserId, type, priority, title, message,
            relatedEntityType, relatedEntityId);
    }

    @Transactional
    public NotificationResponse markRead(Long userId, Long notificationId) {
        Notification n = ownedNotificationOrThrow(userId, notificationId);
        if (!n.isRead()) {
            n.setRead(true);
            n.setReadAt(Instant.now());
            n = notificationRepo.save(n);
        }
        return toResponse(n);
    }

    @Transactional
    public int markAllRead(Long userId) {
        List<Notification> unread = notificationRepo.findByRecipientUserIdAndReadFalseOrderByCreatedAtDesc(userId);
        Instant now = Instant.now();
        for (Notification n : unread) {
            n.setRead(true);
            n.setReadAt(now);
        }
        notificationRepo.saveAll(unread);
        return unread.size();
    }

    @Transactional
    public void delete(Long userId, Long notificationId) {
        Notification n = ownedNotificationOrThrow(userId, notificationId);
        notificationRepo.delete(n);
    }

    @Transactional(readOnly = true)
    public List<NotificationSummaryResponse> getMine(Long userId) {
        return notificationRepo.findByRecipientUserIdOrderByCreatedAtDesc(userId)
            .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public List<NotificationSummaryResponse> getUnread(Long userId) {
        return notificationRepo.findByRecipientUserIdAndReadFalseOrderByCreatedAtDesc(userId)
            .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public long countUnread(Long userId) {
        return notificationRepo.countByRecipientUserIdAndReadFalse(userId);
    }

    /**
     * D1c - the audited entry point for a human administrator broadcasting to every enabled user.
     *
     * <p>It delegates rather than recording inside {@link #adminBroadcast(BroadcastRequest)},
     * because {@code PromotionService} broadcasts through that method when a promotion is
     * published. Auditing the shared body would file automatic promotional fan-out as a deliberate
     * administrative broadcast.
     */
    @Transactional
    public int adminBroadcast(Long adminUserId, BroadcastRequest req) {
        int recipients = adminBroadcast(req);
        // The title is not recorded and the body never is: both are free text. The recipient count
        // is the fact that matters for accountability, and it is a safe scalar.
        adminAudit.record(adminUserId, "NOTIFICATION_BROADCAST", "NOTIFICATION", null,
            "Admin broadcast a notification to " + recipients + " recipients",
            null, "recipients:" + recipients);
        return recipients;
    }

    @Transactional
    public int adminBroadcast(BroadcastRequest req) {
        NotificationType type = req.notificationType() != null ? req.notificationType() : NotificationType.ADMIN;
        Priority priority = req.priority() != null ? req.priority() : Priority.NORMAL;

        List<User> recipients = userRepo.findAll().stream().filter(User::isEnabled).toList();
        for (User u : recipients) {
            Notification n = new Notification();
            n.setRecipientUser(u);
            n.setTitle(req.title());
            n.setMessage(req.message());
            n.setNotificationType(type);
            n.setPriority(priority);
            n.setRelatedEntityType(req.relatedEntityType());
            n.setRelatedEntityId(req.relatedEntityId());
            dispatch(notificationRepo.save(n));
        }
        return recipients.size();
    }

    /**
     * Entity properties an administrator may sort the notification grid by (D1c allowlist).
     * {@code message} and {@code title} are deliberately absent: sorting a grid by a free-text
     * body is not a useful operation and would force a scan over the widest columns in the table.
     */
    private static final Set<String> NOTIFICATION_SORT_FIELDS =
        Set.of("createdAt", "readAt", "priority", "notificationType", "read", "id");

    /**
     * D1c — administrative notification search, paged in the database.
     *
     * <p>This replaces an unbounded {@code findAll} that materialised every notification ever sent
     * into one response. Notifications are the fastest-growing table in the product: a single
     * broadcast writes one row per recipient, so the previous contract degraded in direct
     * proportion to the user base and had no upper bound at all.
     */
    @Transactional(readOnly = true)
    public PageResponse<NotificationResponse> adminSearchPaged(
            Long recipientUserId, NotificationType type, Priority priority, Boolean read,
            RelatedEntityType relatedEntityType, Long relatedEntityId,
            Instant from, Instant to, Integer page, Integer size, String sort) {

        if (from != null && to != null && from.isAfter(to)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "from must not be after to");
        }
        Pageable pageable = AdminPaging.of(page, size, sort, NOTIFICATION_SORT_FIELDS, "createdAt");

        Specification<Notification> spec = (root, query, cb) -> {
            List<Predicate> p = new ArrayList<>();
            if (recipientUserId != null) p.add(cb.equal(root.get("recipientUser").get("id"), recipientUserId));
            if (type != null) p.add(cb.equal(root.get("notificationType"), type));
            if (priority != null) p.add(cb.equal(root.get("priority"), priority));
            if (read != null) p.add(cb.equal(root.get("read"), read));
            if (relatedEntityType != null) p.add(cb.equal(root.get("relatedEntityType"), relatedEntityType));
            if (relatedEntityId != null) p.add(cb.equal(root.get("relatedEntityId"), relatedEntityId));
            if (from != null) p.add(cb.greaterThanOrEqualTo(root.get("createdAt"), from));
            if (to != null) p.add(cb.lessThanOrEqualTo(root.get("createdAt"), to));
            return p.isEmpty() ? cb.conjunction() : cb.and(p.toArray(new Predicate[0]));
        };

        return PageResponse.of(notificationRepo.findAll(spec, pageable).map(this::toResponse));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    // Extension point: in-app persistence above is the source of truth; future
    // channels (Email, Firebase Push, SMS, WebSocket) fan out from here without
    // touching any call site above.
    private Notification dispatch(Notification n) {
        return n;
    }

    private Notification ownedNotificationOrThrow(Long userId, Long notificationId) {
        Notification n = notificationRepo.findById(notificationId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Notification not found: " + notificationId));
        if (!n.getRecipientUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
        return n;
    }

    private NotificationResponse toResponse(Notification n) {
        return new NotificationResponse(
            n.getId(), n.getTitle(), n.getMessage(),
            n.getNotificationType(), n.getPriority(),
            n.getRelatedEntityType(), n.getRelatedEntityId(),
            n.isRead(), n.getReadAt(), n.getCreatedAt()
        );
    }

    private NotificationSummaryResponse toSummary(Notification n) {
        return new NotificationSummaryResponse(
            n.getId(), n.getTitle(), n.getMessage(),
            n.getNotificationType(), n.getPriority(),
            n.isRead(), n.getCreatedAt()
        );
    }
}
