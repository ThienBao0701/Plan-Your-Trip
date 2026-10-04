package com.example.planyourtrip.security.rbac;

import com.example.planyourtrip.model.PartnerProfile;

import java.util.List;

/**
 * The caller's resolved partner workspace for one request (§4.5 {@code W(user)} and {@code G(user)}): the
 * company, who is asking, whether they registered it, and the grants they hold in it.
 *
 * <p>Built only by {@code PartnerAccessService} from stored data; nothing in it comes from the request.
 */
public record PartnerAccessContext(PartnerProfile profile, Long userId, boolean registrant,
                                   List<PartnerGrant> grants) {

    public PartnerAccessContext {
        if (profile == null || profile.getId() == null)
            throw new IllegalArgumentException("A workspace needs a stored company");
        grants = grants == null ? List.of() : List.copyOf(grants);
    }

    /** {@code partner_profiles.id} of the workspace. */
    public Long companyId() {
        return profile.getId();
    }
}
