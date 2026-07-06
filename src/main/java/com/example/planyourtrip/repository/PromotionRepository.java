package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Promotion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface PromotionRepository extends JpaRepository<Promotion, Long> {

    Optional<Promotion> findByCode(String code);

    boolean existsByCode(String code);

    @Query("SELECT p FROM Promotion p WHERE p.active = true " +
           "AND p.startDate <= :checkIn " +
           "AND p.endDate >= :lastNight " +
           "ORDER BY p.priority DESC")
    List<Promotion> findActiveForDateRange(@Param("checkIn") LocalDate checkIn,
                                            @Param("lastNight") LocalDate lastNight);
}
