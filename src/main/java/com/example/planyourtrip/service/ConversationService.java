package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.ConversationDto.*;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.ConversationRepository;
import com.example.planyourtrip.repository.MessageRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.UserRepository;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class ConversationService {

    private final ConversationRepository conversationRepo;
    private final MessageRepository messageRepo;
    private final BookingRepository bookingRepo;
    private final UserRepository userRepo;
    private final PartnerProfileRepository partnerProfileRepo;
    private final NotificationService notificationService;
    private final AdminActivityLogService adminAudit;

    public ConversationService(ConversationRepository conversationRepo,
                                MessageRepository messageRepo,
                                BookingRepository bookingRepo,
                                UserRepository userRepo,
                                PartnerProfileRepository partnerProfileRepo,
                                NotificationService notificationService,
                                AdminActivityLogService adminAudit) {
        this.conversationRepo = conversationRepo;
        this.messageRepo = messageRepo;
        this.bookingRepo = bookingRepo;
        this.userRepo = userRepo;
        this.partnerProfileRepo = partnerProfileRepo;
        this.notificationService = notificationService;
        this.adminAudit = adminAudit;
    }

    // ── Create ───────────────────────────────────────────────────────────────

    @Transactional
    public ConversationResponse createConversation(Long userId, ConversationRequest req) {
        Booking booking = bookingRepo.findById(req.bookingId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + req.bookingId()));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");

        PartnerProfile owner = booking.getHotel().getOwner();
        if (owner == null)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "This hotel has no assigned partner to message");

        Conversation existing = conversationRepo
            .findByBookingIdAndStatusIn(booking.getId(), EnumSet.of(ConversationStatus.OPEN, ConversationStatus.CLOSED))
            .stream().findFirst().orElse(null);
        if (existing != null) return toResponse(existing);

        Conversation conv = new Conversation();
        conv.setBooking(booking);
        conv.setUser(booking.getUser());
        conv.setPartnerProfile(owner);
        conv.setSubject(req.subject());
        conv.setStatus(ConversationStatus.OPEN);
        return toResponse(conversationRepo.save(conv));
    }

    // ── Read: user ───────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<ConversationSummaryResponse> getMyConversations(Long userId) {
        return conversationRepo.findByUserIdOrderByLastMessageAtDesc(userId)
            .stream().map(this::toSummaryForUser).toList();
    }

    @Transactional(readOnly = true)
    public ConversationResponse getConversationForUser(Long userId, Long id) {
        return toResponse(ownedByUserOrThrow(id, userId));
    }

    // ── Read: partner ────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<ConversationSummaryResponse> getPartnerConversations(Long userId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        return conversationRepo.findByPartnerProfileIdOrderByLastMessageAtDesc(profile.getId())
            .stream().map(this::toSummaryForPartner).toList();
    }

    @Transactional(readOnly = true)
    public ConversationResponse getConversationForPartner(Long userId, Long id) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        return toResponse(ownedByPartnerOrThrow(id, profile.getId()));
    }

    // ── Read: admin ──────────────────────────────────────────────────────────

    /** Entity properties an administrator may sort the conversation grid by (D1c allowlist). */
    private static final Set<String> CONVERSATION_SORT_FIELDS =
        Set.of("lastMessageAt", "createdAt", "updatedAt", "status", "id");

    /**
     * D1c — administrative conversation search, paged in the database.
     *
     * <p>Two defects are fixed together here, and they had to be: paging alone would not have made
     * this endpoint safe. The previous implementation read every conversation, then for each row
     * issued a separate query for its newest message <em>and</em> dereferenced a lazy
     * {@code booking}, so the response cost {@code 1 + 2N} queries over an unbounded {@code N}.
     * The page is now bounded, the booking is fetched with the page by an entity graph, and the
     * preview messages are loaded for the whole page in a single query.
     */
    @Transactional(readOnly = true)
    public PageResponse<ConversationSummaryResponse> adminSearchPaged(
            ConversationStatus status, Long userId, Long partnerProfileId, Long bookingId,
            Integer page, Integer size, String sort) {

        Pageable pageable = AdminPaging.of(page, size, sort, CONVERSATION_SORT_FIELDS, "lastMessageAt");

        Specification<Conversation> spec = (root, query, cb) -> {
            List<Predicate> p = new ArrayList<>();
            if (status != null) p.add(cb.equal(root.get("status"), status));
            if (userId != null) p.add(cb.equal(root.get("user").get("id"), userId));
            if (partnerProfileId != null) p.add(cb.equal(root.get("partnerProfile").get("id"), partnerProfileId));
            if (bookingId != null) p.add(cb.equal(root.get("booking").get("id"), bookingId));
            return p.isEmpty() ? cb.conjunction() : cb.and(p.toArray(new Predicate[0]));
        };

        Page<Conversation> result = conversationRepo.findAll(spec, pageable);
        Map<Long, Message> latest = latestMessagesFor(result.getContent());
        return PageResponse.of(result.map(c -> toSummary(c, 0L, latest.get(c.getId()))));
    }

    /**
     * Newest message per conversation for one page, in a single query. Returns an empty map for an
     * empty page rather than issuing an {@code IN ()} the database would reject.
     */
    private Map<Long, Message> latestMessagesFor(List<Conversation> conversations) {
        if (conversations.isEmpty()) return Map.of();
        List<Long> ids = conversations.stream().map(Conversation::getId).toList();
        Map<Long, Message> byConversation = new HashMap<>();
        for (Message m : messageRepo.findLatestPerConversation(ids)) {
            byConversation.put(m.getConversation().getId(), m);
        }
        return byConversation;
    }

    @Transactional(readOnly = true)
    public ConversationResponse adminGetById(Long id) {
        return toResponse(conversationOrThrow(id));
    }

    // ── Messages ─────────────────────────────────────────────────────────────

    @Transactional
    public MessageResponse sendUserMessage(Long userId, Long conversationId, MessageRequest req) {
        Conversation conv = ownedByUserOrThrow(conversationId, userId);
        return sendMessage(conv, userId, MessageSenderRole.USER, req.body());
    }

    @Transactional
    public MessageResponse sendPartnerMessage(Long userId, Long conversationId, MessageRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Conversation conv = ownedByPartnerOrThrow(conversationId, profile.getId());
        return sendMessage(conv, userId, MessageSenderRole.PARTNER, req.body());
    }

    @Transactional
    public MessageResponse sendAdminMessage(Long adminUserId, Long conversationId, MessageRequest req) {
        Conversation conv = conversationOrThrow(conversationId);
        MessageResponse sent = sendMessage(conv, adminUserId, MessageSenderRole.ADMIN, req.body());
        // D1c - an administrator writing into a customer's thread speaks as the platform, and both
        // the customer and the partner see it. The message id is the target so the row can be
        // followed back to the text; the body itself is never copied into the trail.
        adminAudit.record(adminUserId, "CONVERSATION_ADMIN_MESSAGE", "MESSAGE", sent.id(),
            "Admin sent a message in conversation " + conv.getId(), null, null);
        return sent;
    }

    // ── Read status ──────────────────────────────────────────────────────────

    @Transactional
    public ConversationResponse markReadByUser(Long userId, Long conversationId) {
        Conversation conv = ownedByUserOrThrow(conversationId, userId);
        messageRepo.markReadByUser(conv.getId());
        return toResponse(conv);
    }

    @Transactional
    public ConversationResponse markReadByPartner(Long userId, Long conversationId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Conversation conv = ownedByPartnerOrThrow(conversationId, profile.getId());
        messageRepo.markReadByPartner(conv.getId());
        return toResponse(conv);
    }

    // ── Close / archive ──────────────────────────────────────────────────────

    @Transactional
    public ConversationResponse closeByUser(Long userId, Long conversationId) {
        Conversation conv = ownedByUserOrThrow(conversationId, userId);
        conv.setStatus(ConversationStatus.CLOSED);
        return toResponse(conversationRepo.save(conv));
    }

    @Transactional
    public ConversationResponse closeByPartner(Long userId, Long conversationId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Conversation conv = ownedByPartnerOrThrow(conversationId, profile.getId());
        conv.setStatus(ConversationStatus.CLOSED);
        return toResponse(conversationRepo.save(conv));
    }

    @Transactional
    public ConversationResponse archiveByAdmin(Long adminUserId, Long conversationId) {
        Conversation conv = conversationOrThrow(conversationId);
        ConversationStatus before = conv.getStatus();
        conv.setStatus(ConversationStatus.ARCHIVED);
        Conversation saved = conversationRepo.save(conv);
        // D1c - archiving closes a customer's channel to a partner and blocks further messages.
        // Message bodies are never copied into the trail.
        adminAudit.record(adminUserId, "CONVERSATION_ARCHIVE", "CONVERSATION", saved.getId(),
            "Admin archived conversation " + saved.getId(),
            before == null ? null : before.name(), saved.getStatus().name());
        return toResponse(saved);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private MessageResponse sendMessage(Conversation conv, Long senderUserId, MessageSenderRole role, String body) {
        if (conv.getStatus() == ConversationStatus.ARCHIVED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot send a message to an archived conversation");

        User sender = userRepo.findById(senderUserId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        Message msg = new Message();
        msg.setConversation(conv);
        msg.setSenderUser(sender);
        msg.setSenderRole(role);
        msg.setBody(body);
        msg.setReadByUser(role == MessageSenderRole.USER);
        msg.setReadByPartner(role == MessageSenderRole.PARTNER);
        Message saved = messageRepo.save(msg);

        if (conv.getStatus() == ConversationStatus.CLOSED) conv.setStatus(ConversationStatus.OPEN);
        conv.setLastMessageAt(saved.getCreatedAt());
        conversationRepo.save(conv);

        notifyOnMessage(conv, role);
        return toMessageResponse(saved);
    }

    private void notifyOnMessage(Conversation conv, MessageSenderRole senderRole) {
        String bookingCode = conv.getBooking().getBookingCode();
        switch (senderRole) {
            case USER -> notifyPartner(conv, "New message from guest",
                "You have a new message on booking " + bookingCode + ".");
            case PARTNER -> notifyUser(conv, "New message from host",
                "You have a new message on booking " + bookingCode + ".");
            case ADMIN -> {
                notifyUser(conv, "New message from support",
                    "You have a new message on booking " + bookingCode + ".");
                notifyPartner(conv, "New message from support",
                    "You have a new message on booking " + bookingCode + ".");
            }
            case SYSTEM -> { /* no recipient notification for system-authored messages */ }
        }
    }

    private void notifyPartner(Conversation conv, String title, String message) {
        notificationService.create(conv.getPartnerProfile().getUser().getId(),
            NotificationType.MESSAGE, Priority.NORMAL, title, message,
            RelatedEntityType.MESSAGE, conv.getId());
    }

    private void notifyUser(Conversation conv, String title, String message) {
        notificationService.create(conv.getUser().getId(),
            NotificationType.MESSAGE, Priority.NORMAL, title, message,
            RelatedEntityType.MESSAGE, conv.getId());
    }

    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfileRepo.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

    private Conversation conversationOrThrow(Long id) {
        return conversationRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Conversation not found: " + id));
    }

    private Conversation ownedByUserOrThrow(Long id, Long userId) {
        Conversation conv = conversationOrThrow(id);
        if (!conv.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
        return conv;
    }

    private Conversation ownedByPartnerOrThrow(Long id, Long partnerProfileId) {
        Conversation conv = conversationOrThrow(id);
        if (!conv.getPartnerProfile().getId().equals(partnerProfileId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Conversation not found: " + id);
        return conv;
    }

    private ConversationResponse toResponse(Conversation c) {
        List<MessageResponse> messages = messageRepo.findByConversationIdOrderByCreatedAtAsc(c.getId())
            .stream().map(this::toMessageResponse).toList();
        return new ConversationResponse(
            c.getId(), c.getBooking().getId(), c.getBooking().getBookingCode(),
            c.getUser().getId(), c.getUser().getFullName(),
            c.getPartnerProfile().getId(), c.getPartnerProfile().getBusinessName(),
            c.getStatus().name(), c.getSubject(), c.getLastMessageAt(),
            c.getCreatedAt(), c.getUpdatedAt(), messages
        );
    }

    private MessageResponse toMessageResponse(Message m) {
        return new MessageResponse(
            m.getId(), m.getConversation().getId(),
            m.getSenderUser().getId(), m.getSenderUser().getFullName(),
            m.getSenderRole().name(), m.getBody(),
            m.isReadByUser(), m.isReadByPartner(), m.getCreatedAt()
        );
    }

    private ConversationSummaryResponse toSummaryForUser(Conversation c) {
        return toSummary(c, messageRepo.countByConversationIdAndReadByUserFalse(c.getId()));
    }

    private ConversationSummaryResponse toSummaryForPartner(Conversation c) {
        return toSummary(c, messageRepo.countByConversationIdAndReadByPartnerFalse(c.getId()));
    }

    private ConversationSummaryResponse toSummary(Conversation c, long unreadCount) {
        return toSummary(c, unreadCount,
            messageRepo.findTopByConversationIdOrderByCreatedAtDesc(c.getId()).orElse(null));
    }

    /**
     * Overload used by the paged administrative grid, where the newest message of every row on the
     * page has already been loaded in one query. {@code last} may be {@code null} for a
     * conversation that has no messages yet — the same value the per-row lookup would return.
     */
    private ConversationSummaryResponse toSummary(Conversation c, long unreadCount, Message last) {
        return new ConversationSummaryResponse(
            c.getId(), c.getBooking().getId(), c.getBooking().getBookingCode(),
            c.getSubject(), c.getStatus().name(), c.getLastMessageAt(),
            last != null ? last.getBody() : null,
            unreadCount, c.getCreatedAt()
        );
    }
}
