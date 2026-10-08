package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Conversation;
import com.example.planyourtrip.model.ConversationStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.domain.Specification;

import java.util.Collection;
import java.util.List;

public interface ConversationRepository
        extends JpaRepository<Conversation, Long>, JpaSpecificationExecutor<Conversation> {

    List<Conversation> findByUserIdOrderByLastMessageAtDesc(Long userId);

    List<Conversation> findByPartnerProfileIdOrderByLastMessageAtDesc(Long partnerProfileId);

    List<Conversation> findByBookingIdAndStatusIn(Long bookingId, Collection<ConversationStatus> statuses);

    /**
     * RBAC R3b — a partner's conversations are those of bookings at properties in the caller's scope set,
     * resolved through {@code booking.hotel} (§11.2). The denormalized {@code partner_profile_id} is not used
     * for authorization (§16 PA-4).
     */
    List<Conversation> findByBookingHotelIdInOrderByLastMessageAtDesc(Collection<Long> hotelIds);

    /** RBAC R3b §16 PA-4 — the conversations of one property, re-pointed when the property changes company. */
    List<Conversation> findByBookingHotelId(Long hotelId);

    /**
     * D1c — the administrative grid renders each row's booking code, and {@code booking} is a lazy
     * {@code @ManyToOne}, so without a graph every page costs one extra select per row. The graph
     * is applied to the content query only; Spring Data runs the count query separately and
     * unaffected, and {@code booking} is a to-one association so no in-memory paging is triggered.
     */
    @Override
    @EntityGraph(attributePaths = {"booking"})
    Page<Conversation> findAll(Specification<Conversation> spec, Pageable pageable);
}
