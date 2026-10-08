package com.example.planyourtrip.model;

import com.example.planyourtrip.security.rbac.ScopeRef;
import com.example.planyourtrip.security.rbac.ScopeType;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Check;

/**
 * RBAC R4 — one grant an invitation will create on acceptance (RBAC V1.1 §13.1, §28 M-3): a role at a scope
 * written {@code TYPE:id}. The database refuses the same role/scope combinations as for member grants (§11.3);
 * whether the scope belongs to the company is checked by the server at creation and again at acceptance.
 */
@Entity
@Table(name = "partner_invitation_grants",
       uniqueConstraints = @UniqueConstraint(name = "uk_partner_invitation_grant",
           columnNames = {"invitation_id", "role", "scope_type", "scope_id"}),
       indexes = @Index(name = "idx_partner_invitation_grants_scope", columnList = "scope_type, scope_id"))
@Check(name = "ck_partner_invitation_grants_role", constraints = PartnerMemberGrant.ROLE_CHECK)
@Check(name = "ck_partner_invitation_grants_scope_type", constraints = PartnerMemberGrant.SCOPE_TYPE_CHECK)
@Check(name = "ck_partner_invitation_grants_scope_id", constraints = PartnerMemberGrant.SCOPE_ID_CHECK)
@Check(name = "ck_partner_invitation_grants_role_scope", constraints = PartnerMemberGrant.ROLE_SCOPE_CHECK)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PartnerInvitationGrant {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "invitation_id", nullable = false)
    private PartnerInvitation invitation;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PartnerTeamRole role;

    @Enumerated(EnumType.STRING)
    @Column(name = "scope_type", nullable = false, length = 20)
    private ScopeType scopeType;

    @Column(name = "scope_id", nullable = false)
    private Long scopeId;

    public PartnerInvitationGrant(PartnerInvitation invitation, PartnerTeamRole role, ScopeRef scope) {
        this.invitation = invitation;
        this.role = role;
        this.scopeType = scope.type();
        this.scopeId = scope.id();
    }

    public ScopeRef scope() {
        return new ScopeRef(scopeType, scopeId);
    }
}
