package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "trip_plan_expenses",
       indexes = {
           @Index(name = "idx_trip_plan_expenses_trip_plan_id", columnList = "trip_plan_id"),
           @Index(name = "idx_trip_plan_expenses_trip_plan_day_id", columnList = "trip_plan_day_id"),
           @Index(name = "idx_trip_plan_expenses_trip_plan_item_id", columnList = "trip_plan_item_id")
       })
@Getter @Setter
public class TripPlanExpense {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_plan_id", nullable = false)
    private TripPlan tripPlan;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_plan_day_id")
    private TripPlanDay tripDay;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_plan_item_id")
    private TripPlanItem tripItem;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "paid_by_user_id", nullable = false)
    private User paidByUser;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TripPlanExpenseCategory category;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    private String currency;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(nullable = false)
    private LocalDate expenseDate;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
