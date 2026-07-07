package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.ConversationDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.ConversationRepository;
import com.example.planyourtrip.repository.MessageRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;
import java.util.List;

@Service
public class ConversationService {

    private final ConversationRepository conversationRepo;
    private final MessageRepository messageRepo;
    private final BookingRepository bookingRepo;
    private final UserRepository userRepo;
    private final PartnerProfileRepository partnerProfileRepo;
    private final NotificationService notificationService;

    public ConversationService(ConversationRepository conversationRepo,
                                MessageRepository messageRepo,
                                BookingRepository bookingRepo,
                                UserRepository userRepo,
                                PartnerProfileRepository partnerProfileRepo,
                                NotificationService notificationService) {
        this.conversationRepo = conversationRepo;
        this.messageRepo = messageRepo;
        this.bookingRepo = bookingRepo;
        this.userRepo = userRepo;
        this.partnerProfileRepo = partnerProfileRepo;
        this.notificationService = notificationService;
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

    @Transactional(readOnly = true)
    public List<ConversationSummaryResponse> adminGetAll() {
        return conversationRepo.findAllByOrderByLastMessageAtDesc()
            .stream().map(this::toSummaryForAdmin).toList();
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
        return sendMessage(conv, adminUserId, MessageSenderRole.ADMIN, req.body());
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
    public ConversationResponse archiveByAdmin(Long conversationId) {
        Conversation conv = conversationOrThrow(conversationId);
        conv.setStatus(ConversationStatus.ARCHIVED);
        return toResponse(conversationRepo.save(conv));
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

    private ConversationSummaryResponse toSummaryForAdmin(Conversation c) {
        return toSummary(c, 0L);
    }

    private ConversationSummaryResponse toSummary(Conversation c, long unreadCount) {
        Message last = messageRepo.findTopByConversationIdOrderByCreatedAtDesc(c.getId()).orElse(null);
        return new ConversationSummaryResponse(
            c.getId(), c.getBooking().getId(), c.getBooking().getBookingCode(),
            c.getSubject(), c.getStatus().name(), c.getLastMessageAt(),
            last != null ? last.getBody() : null,
            unreadCount, c.getCreatedAt()
        );
    }
}
