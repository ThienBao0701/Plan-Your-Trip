package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TravelWalletItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TravelWalletItemRepository extends JpaRepository<TravelWalletItem, Long> {

    List<TravelWalletItem> findByUserIdOrderByCreatedAtDesc(Long userId);

    Optional<TravelWalletItem> findByIdAndUserId(Long id, Long userId);

    Optional<TravelWalletItem> findByUserIdAndTripPlanDocumentId(Long userId, Long tripPlanDocumentId);

    Optional<TravelWalletItem> findByUserIdAndBookingId(Long userId, Long bookingId);

    Optional<TravelWalletItem> findByUserIdAndInvoiceId(Long userId, Long invoiceId);
}
