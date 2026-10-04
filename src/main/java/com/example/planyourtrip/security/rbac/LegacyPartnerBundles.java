package com.example.planyourtrip.security.rbac;

import com.example.planyourtrip.model.PartnerTeamRole;

import java.util.EnumSet;
import java.util.Set;

import static com.example.planyourtrip.security.rbac.PartnerPermission.PAYOUT_ACCOUNT_MANAGE;
import static com.example.planyourtrip.security.rbac.PartnerPermission.PAYOUT_ACCOUNT_VIEW;
import static com.example.planyourtrip.security.rbac.PartnerPermission.SETTINGS_EDIT;
import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_INVITE;
import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_OWNER_MANAGE;
import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_REMOVE;
import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_ROLE_ASSIGN;
import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_SUSPEND;
import static com.example.planyourtrip.security.rbac.PartnerPermission.TEAM_VIEW;
import static com.example.planyourtrip.security.rbac.PartnerPermission.WORKSPACE_ACCESS;

/**
 * The R1 bundles, which reproduce today's partner authorization exactly (RBAC V1.1 §32 R1, §29). They are
 * not the V1.1 role bundles of §10.1: those take effect only when R3b enforces the matrix.
 *
 * <ul>
 *   <li>The registrant of an approved company holds every partner permission — today they may use every
 *       partner endpoint of their own company.</li>
 *   <li>A team member holds only what {@code PartnerSettingsService} allowed before R1: reading settings,
 *       the payout account and the team; {@code MANAGER} and the member {@code OWNER} may also edit settings
 *       ({@code SETTINGS_WRITE_ROLES}); {@code FINANCE} and the member {@code OWNER} may change the payout
 *       account ({@code PAYOUT_WRITE_ROLES}); only an {@code OWNER} manages the team ({@code requireOwner}).
 *       Members never reach operational endpoints in R1 — those still resolve the registrant's company only.</li>
 *   <li>An unknown (null) role holds nothing.</li>
 * </ul>
 */
public final class LegacyPartnerBundles {

    private LegacyPartnerBundles() {}

    private static final Set<PartnerPermission> MEMBER_READS =
        Set.copyOf(EnumSet.of(WORKSPACE_ACCESS, TEAM_VIEW, PAYOUT_ACCOUNT_VIEW));

    /** Every partner permission: the registrant's power over their own approved company. */
    public static Set<PartnerPermission> registrant() {
        return Set.copyOf(EnumSet.allOf(PartnerPermission.class));
    }

    /** What a team member with {@code role} could do before R1. */
    public static Set<PartnerPermission> member(PartnerTeamRole role) {
        if (role == null) return Set.of();
        EnumSet<PartnerPermission> bundle = EnumSet.copyOf(MEMBER_READS);
        switch (role) {
            case OWNER -> bundle.addAll(EnumSet.of(SETTINGS_EDIT, PAYOUT_ACCOUNT_MANAGE, TEAM_INVITE,
                TEAM_ROLE_ASSIGN, TEAM_SUSPEND, TEAM_REMOVE, TEAM_OWNER_MANAGE));
            case MANAGER -> bundle.add(SETTINGS_EDIT);
            case FINANCE -> bundle.add(PAYOUT_ACCOUNT_MANAGE);
            case FRONT_DESK, VIEWER -> { }
        }
        return Set.copyOf(bundle);
    }
}
