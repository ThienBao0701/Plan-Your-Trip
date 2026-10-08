package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.PartnerInvitationGrant;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/** RBAC R4 — the grants of partner invitations. */
public interface PartnerInvitationGrantRepository extends JpaRepository<PartnerInvitationGrant, Long> {

    List<PartnerInvitationGrant> findByInvitationIdOrderByIdAsc(Long invitationId);
}
