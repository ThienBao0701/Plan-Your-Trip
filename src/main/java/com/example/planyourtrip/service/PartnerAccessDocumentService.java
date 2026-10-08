package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerAccessDto.AccessDocument;
import com.example.planyourtrip.dto.PartnerAccessDto.Context;
import com.example.planyourtrip.dto.PartnerAccessDto.Grant;
import com.example.planyourtrip.dto.PartnerAccessDto.Membership;
import com.example.planyourtrip.dto.PartnerAccessDto.Permissions;
import com.example.planyourtrip.dto.PartnerAccessDto.PropertyContext;
import com.example.planyourtrip.dto.PartnerAccessDto.StepUp;
import com.example.planyourtrip.dto.PartnerAccessDto.UnitContext;
import com.example.planyourtrip.dto.PartnerAccessDto.Workspace;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.rbac.EffectivePermissions;
import com.example.planyourtrip.security.rbac.ParentContext;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerAuthorization;
import com.example.planyourtrip.security.rbac.PartnerGrant;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.PartnerRoleBundles;
import com.example.planyourtrip.security.rbac.ScopePath;
import org.hibernate.Hibernate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.TreeMap;

/**
 * RBAC R3b — {@code GET /api/partner/me/access} (RBAC V1.1 §25.2), kind SELF.
 *
 * <p>Deliberately not gated by P01, by {@code APPROVED} or by membership status, so a suspended member or the owner of
 * an unapproved company still receives an explanation. Permissions are listed only when the membership is ACTIVE (or
 * the caller is the primary owner) <em>and</em> the company is APPROVED; otherwise they are empty. A caller with no
 * own company and no ACTIVE/SUSPENDED membership — including an administrator — gets 404 (onboarding).
 */
@Service
public class PartnerAccessDocumentService {

    private final PartnerProfileRepository profiles;
    private final PartnerMembershipService memberships;
    private final PlaceRepository places;
    private final HotelRoomRepository rooms;
    private final StepUpPolicy stepUp;

    public PartnerAccessDocumentService(PartnerProfileRepository profiles, PartnerMembershipService memberships,
                                        PlaceRepository places, HotelRoomRepository rooms, StepUpPolicy stepUp) {
        this.profiles = profiles;
        this.memberships = memberships;
        this.places = places;
        this.rooms = rooms;
        this.stepUp = stepUp;
    }

    @Transactional(readOnly = true)
    public AccessDocument accessOf(Long userId) {
        Optional<PartnerProfile> own = profiles.findByUserId(userId);
        PartnerProfile company;
        PartnerTeamMember membership;
        boolean primary;
        if (own.isPresent()) {
            company = own.get();
            primary = true;
            membership = memberships.membershipsOf(userId).stream()
                .filter(memberships::isPrimaryOwner).findFirst().orElse(null);
        } else {
            List<PartnerTeamMember> candidates = memberships.membershipsOf(userId);
            membership = candidates.stream().filter(m -> m.getStatus() == PartnerMembershipStatus.ACTIVE).findFirst()
                .orElseGet(() -> candidates.size() == 1 ? candidates.get(0) : null);
            if (membership == null) throw new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found");
            company = Hibernate.unproxy(membership.getPartnerProfile(), PartnerProfile.class);
            primary = false;
        }

        boolean effective = company.getVerificationStatus() == PartnerVerificationStatus.APPROVED
            && (primary || membership.getStatus() == PartnerMembershipStatus.ACTIVE);
        List<PartnerGrant> kernelGrants = !effective ? List.of()
            : primary ? List.of(new PartnerGrant(PartnerRoleBundles.of(PartnerTeamRole.OWNER), ScopePath.company(company.getId())))
            : memberships.kernelGrants(membership, PartnerRoleBundles::effective);
        PartnerAccessContext ctx = new PartnerAccessContext(company, userId, primary, kernelGrants);

        List<Grant> grants = new ArrayList<>();
        if (primary) {
            grants.add(new Grant(PartnerTeamRole.OWNER.name(), "COMPANY", company.getId()));
        } else {
            memberships.grantsOf(membership).forEach(g ->
                grants.add(new Grant(g.getRole().name(), g.getScopeType().name(), g.getScopeId())));
        }

        return new AccessDocument(
            new Workspace(company.getId(), company.getBusinessName(), company.getVerificationStatus().name()),
            membership == null ? new Membership(null, PartnerMembershipStatus.ACTIVE.name(), true, false)
                : new Membership(membership.getId(), membership.getStatus().name(), primary,
                    membership.isPendingOwnerConfirmation()),
            grants,
            permissions(PartnerAuthorization.effectivePermissions(ctx)),
            context(company, PartnerAuthorization.parentContext(ctx)),
            new StepUp(stepUp.freshUntil()));
    }

    private static Permissions permissions(EffectivePermissions e) {
        return new Permissions(keys(e.company()), byId(e.properties()), byId(e.units()));
    }

    private static Map<String, List<String>> byId(Map<Long, Set<PartnerPermission>> scoped) {
        Map<String, List<String>> out = new TreeMap<>();
        scoped.forEach((id, set) -> {
            List<String> keys = keys(set);
            if (!keys.isEmpty()) out.put(String.valueOf(id), keys);
        });
        return out;
    }

    /** Permission keys, sorted, without reserved permissions — no endpoint exercises them (§9.1). */
    private static List<String> keys(Set<PartnerPermission> set) {
        return set.stream().filter(p -> !p.reserved()).map(PartnerPermission::key).sorted().toList();
    }

    /** §11.7 — identity only: name, location label, status; room types by name and code. */
    private Context context(PartnerProfile company, ParentContext parent) {
        Map<Long, Place> owned = new LinkedHashMap<>();
        places.findAllByOwnerId(company.getId()).stream()
            .sorted(Comparator.comparing(Place::getId))
            .forEach(place -> owned.put(place.getId(), place));
        List<PropertyContext> properties = new ArrayList<>();
        for (Place place : owned.values()) {
            if (parent.companyWide() || parent.propertyIds().contains(place.getId())) {
                String label = place.getAdministrativeUnit() == null ? null
                    : place.getAdministrativeUnit().getFullPath() != null ? place.getAdministrativeUnit().getFullPath()
                    : place.getAdministrativeUnit().getName();
                properties.add(new PropertyContext(place.getId(), place.getName(), label, place.isActive(),
                    place.getStatus() == null ? null : place.getStatus().name()));
            }
        }
        List<UnitContext> units = new ArrayList<>();
        for (Long unitId : parent.unitIds().stream().sorted().toList()) {
            rooms.findById(unitId)
                .filter(room -> room.getHotelDetail() != null && owned.containsKey(room.getHotelDetail().getPlace().getId()))
                .ifPresent(room -> units.add(new UnitContext(room.getId(), room.getRoomName(), room.getRoomCode(),
                    room.getHotelDetail().getPlace().getId())));
        }
        return new Context(properties, units);
    }
}
