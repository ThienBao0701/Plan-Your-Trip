package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerInvitation;
import com.example.planyourtrip.model.PartnerInvitationStatus;
import com.example.planyourtrip.model.PartnerInvitationDeliveryStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/** RBAC R4 — partner invitations (RBAC V1.1 §13, §14). */
public interface PartnerInvitationRepository extends JpaRepository<PartnerInvitation, Long> {

    Optional<PartnerInvitation> findByTokenHash(String tokenHash);

    List<PartnerInvitation> findByPartnerProfileIdOrderByCreatedAtDescIdDesc(Long partnerProfileId);

    /** The pending invitation of an address to a company — at most one (uk_partner_invitations_pending). */
    Optional<PartnerInvitation> findByPartnerProfileIdAndEmailAndStatus(Long partnerProfileId, String email,
                                                                        PartnerInvitationStatus status);

    /** The latest invitation of an address to a company, in any state — for the per-address cooldown. */
    Optional<PartnerInvitation> findFirstByPartnerProfileIdAndEmailOrderByCreatedAtDescIdDesc(Long partnerProfileId,
                                                                                              String email);

    /** Pending invitations that can still be accepted — the §31 Q16 limit counts these. */
    @Query("select count(i) from PartnerInvitation i where i.partnerProfile.id = :companyId "
        + "and i.status = com.example.planyourtrip.model.PartnerInvitationStatus.PENDING and i.expiresAt > :now")
    long countOpen(@Param("companyId") Long companyId, @Param("now") Instant now);

    /** Pending, unexpired invitations addressed to {@code email} (§14 AC-5). */
    @Query("select i from PartnerInvitation i where i.email = :email "
        + "and i.status = com.example.planyourtrip.model.PartnerInvitationStatus.PENDING and i.expiresAt > :now "
        + "order by i.createdAt desc, i.id desc")
    List<PartnerInvitation> findOpenFor(@Param("email") String email, @Param("now") Instant now);

    /** Pending invitations of the company with a grant on the property or one of its room types (§16 PA-4). */
    @Query("select distinct i from PartnerInvitation i, PartnerInvitationGrant g "
        + "where g.invitation = i and i.partnerProfile.id = :companyId "
        + "and i.status = com.example.planyourtrip.model.PartnerInvitationStatus.PENDING "
        + "and ((g.scopeType = com.example.planyourtrip.security.rbac.ScopeType.PROPERTY and g.scopeId = :propertyId) "
        + "  or (g.scopeType = com.example.planyourtrip.security.rbac.ScopeType.UNIT and g.scopeId in :unitIds))")
    List<PartnerInvitation> findPendingReferencing(@Param("companyId") Long companyId,
                                                   @Param("propertyId") Long propertyId,
                                                   @Param("unitIds") Collection<Long> unitIds);

    /**
     * Records the outcome of a send, only while the invitation still carries the token that was sent (a concurrent
     * resend rotated it otherwise). A conditional bulk update: it never conflicts with a concurrent versioned write.
     */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update PartnerInvitation i set i.deliveryStatus = :status where i.id = :id and i.tokenHash = :hash")
    int recordDelivery(@Param("id") Long id, @Param("hash") String tokenHash,
                       @Param("status") PartnerInvitationDeliveryStatus status);
}
