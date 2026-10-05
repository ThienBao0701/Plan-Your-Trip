package com.example.planyourtrip.model;

import com.example.planyourtrip.security.rbac.ScopeType;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Check;

import java.time.Instant;

/**
 * One role held by a membership at one scope — a grant of RBAC V1.1 §4.2 and §12.3.
 *
 * <p>Scope is stored explicitly:
 * <ul>
 *   <li>{@code COMPANY} — {@code scope_id} is the membership's company ({@code partner_profiles.id});
 *       {@code property_id} and {@code unit_id} are empty;</li>
 *   <li>{@code PROPERTY} — {@code scope_id} = {@code property_id}, a {@code places.id};</li>
 *   <li>{@code UNIT} — {@code scope_id} = {@code unit_id}, a {@code hotel_rooms.id} (a room type in V1), with
 *       {@code property_id} its place.</li>
 * </ul>
 * {@code scope_id} is never null: the company id is stored for company grants, so the uniqueness of
 * {@code (team_member_id, role, scope_type, scope_id)} behaves identically on SQL Server and H2 (the two
 * treat nulls in unique constraints differently).
 *
 * <p>What the database guarantees (V5): the scope's shape, which roles may sit at which scope type
 * (§11.3), foreign keys to the property and room, and — through a composite foreign key — that the grant
 * belongs to its membership's company. What only the server can guarantee, because ownership changes over
 * time, is that the property or room belongs to that company <em>now</em>; {@code PartnerMembershipService}
 * checks it when a grant is written and again whenever a grant is read.
 *
 * <p>A grant is immutable: changing a role or scope replaces the grant.
 */
@Entity
@Table(name = "partner_member_grants",
       uniqueConstraints = @UniqueConstraint(name = "uk_partner_member_grant",
           columnNames = {"team_member_id", "role", "scope_type", "scope_id"}),
       indexes = {
           @Index(name = "idx_partner_member_grants_company", columnList = "partner_profile_id"),
           @Index(name = "idx_partner_member_grants_property", columnList = "property_id"),
           @Index(name = "idx_partner_member_grants_unit", columnList = "unit_id")
       })
@Check(name = "ck_partner_member_grants_role", constraints = PartnerMemberGrant.ROLE_CHECK)
@Check(name = "ck_partner_member_grants_scope_type", constraints = PartnerMemberGrant.SCOPE_TYPE_CHECK)
@Check(name = "ck_partner_member_grants_scope_id", constraints = PartnerMemberGrant.SCOPE_ID_CHECK)
@Check(name = "ck_partner_member_grants_scope_shape", constraints = PartnerMemberGrant.SCOPE_SHAPE_CHECK)
@Check(name = "ck_partner_member_grants_role_scope", constraints = PartnerMemberGrant.ROLE_SCOPE_CHECK)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PartnerMemberGrant {

    public static final String ROLE_VALUES =
        "'OWNER','MANAGER','REVENUE','RESERVATIONS','FRONT_DESK','FINANCE','CONTENT','HOUSEKEEPING','VIEWER'";
    public static final String ROLE_CHECK = "role in (" + ROLE_VALUES + ")";
    public static final String SCOPE_TYPE_CHECK = "scope_type in ('COMPANY','PROPERTY','UNIT')";
    public static final String SCOPE_ID_CHECK = "scope_id > 0";
    /**
     * Which columns each scope type uses. The explicit {@code is not null} tests matter: a CHECK passes when
     * its expression is unknown, so {@code property_id = scope_id} alone would admit a missing property.
     */
    public static final String SCOPE_SHAPE_CHECK =
        "(scope_type = 'COMPANY' and scope_id = partner_profile_id and property_id is null and unit_id is null)"
        + " or (scope_type = 'PROPERTY' and property_id is not null and property_id = scope_id and unit_id is null)"
        + " or (scope_type = 'UNIT' and unit_id is not null and unit_id = scope_id and property_id is not null)";
    /** RBAC V1.1 §11.3: OWNER and FINANCE company-only; HOUSEKEEPING property or unit; the rest company or property. */
    public static final String ROLE_SCOPE_CHECK =
        "(role in ('OWNER','FINANCE') and scope_type = 'COMPANY')"
        + " or (role in ('MANAGER','REVENUE','RESERVATIONS','FRONT_DESK','CONTENT','VIEWER')"
        + " and scope_type in ('COMPANY','PROPERTY'))"
        + " or (role = 'HOUSEKEEPING' and scope_type in ('PROPERTY','UNIT'))";

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "team_member_id", nullable = false)
    private PartnerTeamMember teamMember;

    /** The membership's company, repeated so the database can pin the grant to it (composite FK in V5). */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "partner_profile_id", nullable = false)
    private PartnerProfile partnerProfile;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PartnerTeamRole role;

    @Enumerated(EnumType.STRING)
    @Column(name = "scope_type", nullable = false, length = 20)
    private ScopeType scopeType;

    @Column(name = "scope_id", nullable = false)
    private Long scopeId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "property_id")
    private Place property;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unit_id")
    private HotelRoom unit;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    /** Who created the grant, or null for a migration or system backfill. */
    @Column(name = "created_by")
    private Long createdBy;

    /** A grant over the membership's whole company. */
    public static PartnerMemberGrant company(PartnerTeamMember member, PartnerTeamRole role, Long createdBy) {
        PartnerMemberGrant grant = base(member, role, ScopeType.COMPANY, createdBy);
        grant.scopeId = member.getPartnerProfile().getId();
        return grant;
    }

    /** A grant over one property. The caller has verified the property belongs to the membership's company. */
    public static PartnerMemberGrant property(PartnerTeamMember member, PartnerTeamRole role, Place property,
                                              Long createdBy) {
        PartnerMemberGrant grant = base(member, role, ScopeType.PROPERTY, createdBy);
        grant.property = property;
        grant.scopeId = property.getId();
        return grant;
    }

    /** A grant over one room type, recorded with its property. The caller has verified both. */
    public static PartnerMemberGrant unit(PartnerTeamMember member, PartnerTeamRole role, Place property,
                                          HotelRoom unit, Long createdBy) {
        PartnerMemberGrant grant = base(member, role, ScopeType.UNIT, createdBy);
        grant.property = property;
        grant.unit = unit;
        grant.scopeId = unit.getId();
        return grant;
    }

    private static PartnerMemberGrant base(PartnerTeamMember member, PartnerTeamRole role, ScopeType type,
                                           Long createdBy) {
        if (member == null || member.getPartnerProfile() == null || role == null) {
            throw new IllegalArgumentException("A grant needs a membership with a company, and a role");
        }
        PartnerMemberGrant grant = new PartnerMemberGrant();
        grant.teamMember = member;
        grant.partnerProfile = member.getPartnerProfile();
        grant.role = role;
        grant.scopeType = type;
        grant.createdBy = createdBy;
        return grant;
    }

    /**
     * Mirrors the composite foreign key of V5 for databases built from the entities (H2): a grant can only
     * belong to its own membership's company.
     */
    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
        Long memberCompany = teamMember.getPartnerProfile().getId();
        if (memberCompany == null || !memberCompany.equals(partnerProfile.getId())) {
            throw new IllegalStateException("A grant must belong to its membership's company");
        }
    }
}
