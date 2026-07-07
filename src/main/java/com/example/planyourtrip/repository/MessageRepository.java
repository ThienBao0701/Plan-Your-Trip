package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MessageRepository extends JpaRepository<Message, Long> {

    List<Message> findByConversationIdOrderByCreatedAtAsc(Long conversationId);

    Optional<Message> findTopByConversationIdOrderByCreatedAtDesc(Long conversationId);

    long countByConversationIdAndReadByUserFalse(Long conversationId);

    long countByConversationIdAndReadByPartnerFalse(Long conversationId);

    @Modifying
    @Query("UPDATE Message m SET m.readByUser = true " +
           "WHERE m.conversation.id = :conversationId AND m.readByUser = false")
    int markReadByUser(@Param("conversationId") Long conversationId);

    @Modifying
    @Query("UPDATE Message m SET m.readByPartner = true " +
           "WHERE m.conversation.id = :conversationId AND m.readByPartner = false")
    int markReadByPartner(@Param("conversationId") Long conversationId);
}
