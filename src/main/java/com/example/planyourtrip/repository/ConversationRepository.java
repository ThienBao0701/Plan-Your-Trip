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
     * D1c — the administrative grid renders each row's booking code, and {@code booking} is a lazy
     * {@code @ManyToOne}, so without a graph every page costs one extra select per row. The graph
     * is applied to the content query only; Spring Data runs the count query separately and
     * unaffected, and {@code booking} is a to-one association so no in-memory paging is triggered.
     */
    @Override
    @EntityGraph(attributePaths = {"booking"})
    Page<Conversation> findAll(Specification<Conversation> spec, Pageable pageable);
}
