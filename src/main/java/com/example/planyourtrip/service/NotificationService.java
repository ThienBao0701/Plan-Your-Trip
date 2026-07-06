package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.NotificationDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.NotificationRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepo;
    private final UserRepository userRepo;

    public NotificationService(NotificationRepository notificationRepo, UserRepository userRepo) {
        this.notificationRepo = notificationRepo;
        this.userRepo = userRepo;
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

    @Transactional(readOnly = true)
    public List<NotificationResponse> adminGetAll() {
        return notificationRepo.findAllByOrderByCreatedAtDesc()
            .stream().map(this::toResponse).toList();
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
