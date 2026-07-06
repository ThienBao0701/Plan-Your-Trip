package com.example.planyourtrip.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "room_inventory",
       uniqueConstraints = @UniqueConstraint(
           name = "uk_room_inventory_date",
           columnNames = {"room_id", "inventory_date"}))
@Getter @Setter
public class RoomInventory {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false)
    private HotelRoom hotelRoom;

    @NotNull
    @Column(name = "inventory_date", nullable = false)
    private LocalDate inventoryDate;

    @Min(0)
    private int totalInventory;

    @Min(0)
    private int availableInventory;

    @Min(0)
    private int blockedInventory;

    @Min(0)
    private int soldInventory;

    @Min(0)
    private int maintenanceInventory;

    private boolean stopSell;

    private boolean closedArrival;

    private boolean closedDeparture;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
