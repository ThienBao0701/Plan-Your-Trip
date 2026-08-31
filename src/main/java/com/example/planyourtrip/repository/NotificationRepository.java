package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;

public interface NotificationRepository
        extends JpaRepository<Notification, Long>, JpaSpecificationExecutor<Notification> {

    List<Notification> findByRecipientUserIdOrderByCreatedAtDesc(Long userId);

    List<Notification> findByRecipientUserIdAndReadFalseOrderByCreatedAtDesc(Long userId);

    long countByRecipientUserIdAndReadFalse(Long userId);
}
