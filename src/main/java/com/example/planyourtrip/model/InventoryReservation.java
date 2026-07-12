package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.time.LocalDate;

/**
 * Phase 7.28 — Inventory Lock &amp; Room Hold.
 *
 * <p>A temporary hold on room inventory for a booking whose payment has not yet completed.
 * This is a NEW, SEPARATE table that is a TRACKING/EXPIRY layer over the EXISTING
 * {@code room_inventory} math — it is NOT a second inventory engine. The actual
 * decrement/restore is still performed exclusively by
 * {@code RoomInventoryRepository.decrementInventory}/{@code restoreInventory}; one
 * reservation row records which booking/room/dates/rooms-count a decrement covers and
 * carries the {@link #status} + {@link #expiresAt} lifecycle so the hold can be consumed
 * (payment success), released (failure/cancel) or expired (timeout).
 *
 * <p>Exactly ONE reservation exists per booking (enforced by the unique constraint on
 * {@code booking_id}) — creating a booking creates its single hold in the SAME transaction
 * as the decrement. Every state transition runs under a pessimistic write lock
 * ({@code InventoryReservationRepository#findByBookingIdForUpdate}), the same discipline as
 * {@code PaymentSession}/{@code GiftCard}, so concurrent settlement/cancel/expiry triggers
 * on the same booking serialize instead of racing.
 */
@Entity
@Table(name = "inventory_reservations",
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_inventory_reservation_booking", columnNames = "booking_id")
       },
       indexes = {
           @Index(name = "idx_inventory_reservation_status", columnList = "status"),
           @Index(name = "idx_inventory_reservation_expires_at", columnList = "expires_at")
       })
@Getter @Setter
public class InventoryReservation {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "booking_id", nullable = false, updatable = false)
    private Booking booking;

    /** The room this hold covers — recorded so a release can call {@code restoreInventory}. */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false, updatable = false)
    private HotelRoom room;

    @Column(name = "check_in_date", nullable = false, updatable = false)
    private LocalDate checkInDate;

    @Column(name = "check_out_date", nullable = false, updatable = false)
    private LocalDate checkOutDate;

    @Column(name = "number_of_rooms", nullable = false, updatable = false)
    private int numberOfRooms;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private InventoryReservationStatus status = InventoryReservationStatus.HELD;

    /** When the hold auto-expires if payment has not completed by then. */
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    private Instant consumedAt;

    private Instant releasedAt;

    private Instant expiredAt;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @Version
    private Long version;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
