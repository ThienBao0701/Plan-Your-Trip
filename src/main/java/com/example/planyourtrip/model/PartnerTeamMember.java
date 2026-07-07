package com.example.planyourtrip.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "partner_team_members",
       indexes = {
           @Index(name = "idx_partner_team_members_profile_id", columnList = "partner_profile_id"),
           @Index(name = "idx_partner_team_members_user_id", columnList = "user_id")
       },
       uniqueConstraints = {
           @UniqueConstraint(name = "uk_partner_team_member_profile_user", columnNames = {"partner_profile_id", "user_id"})
       })
@Getter @Setter
public class PartnerTeamMember {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "partner_profile_id", nullable = false)
    private PartnerProfile partnerProfile;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PartnerTeamRole role;

    @Column(nullable = false)
    private boolean active = true;

    private Instant invitedAt;

    private Instant joinedAt;

    @Column(updatable = false)
    private Instant createdAt;

    private Instant updatedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = Instant.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = Instant.now(); }
}
