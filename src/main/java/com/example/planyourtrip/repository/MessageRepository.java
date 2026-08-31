package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface MessageRepository extends JpaRepository<Message, Long> {

    List<Message> findByConversationIdOrderByCreatedAtAsc(Long conversationId);

    Optional<Message> findTopByConversationIdOrderByCreatedAtDesc(Long conversationId);

    long countByConversationIdAndReadByUserFalse(Long conversationId);

    long countByConversationIdAndReadByPartnerFalse(Long conversationId);

    /**
     * D1c — the newest message of each of several conversations in one query.
     *
     * <p>The administrative conversation grid previously called
     * {@link #findTopByConversationIdOrderByCreatedAtDesc} once per row, which made the list cost
     * 1+N selects. Selecting by {@code max(id)} rather than {@code max(createdAt)} is deliberate:
     * messages written in the same transaction can share a {@code createdAt}, and a correlated
     * max-timestamp subquery would then return two rows for one conversation. The identity column
     * is unique and monotonic, so it identifies exactly one newest message per conversation.
     */
    @Query("SELECT m FROM Message m WHERE m.id IN ("
        + "  SELECT MAX(m2.id) FROM Message m2 WHERE m2.conversation.id IN :conversationIds"
        + "  GROUP BY m2.conversation.id)")
    List<Message> findLatestPerConversation(@Param("conversationIds") Collection<Long> conversationIds);

    @Modifying
    @Query("UPDATE Message m SET m.readByUser = true " +
           "WHERE m.conversation.id = :conversationId AND m.readByUser = false")
    int markReadByUser(@Param("conversationId") Long conversationId);

    @Modifying
    @Query("UPDATE Message m SET m.readByPartner = true " +
           "WHERE m.conversation.id = :conversationId AND m.readByPartner = false")
    int markReadByPartner(@Param("conversationId") Long conversationId);
}
