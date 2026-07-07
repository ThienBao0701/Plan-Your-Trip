package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Conversation;
import com.example.planyourtrip.model.ConversationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface ConversationRepository extends JpaRepository<Conversation, Long> {

    List<Conversation> findByUserIdOrderByLastMessageAtDesc(Long userId);

    List<Conversation> findByPartnerProfileIdOrderByLastMessageAtDesc(Long partnerProfileId);

    List<Conversation> findByBookingIdAndStatusIn(Long bookingId, Collection<ConversationStatus> statuses);

    List<Conversation> findAllByOrderByLastMessageAtDesc();
}
