package com.example.planyourtrip.security.rbac;

/**
 * The three partner scope types of RBAC V1.1 §11, ordered from widest to narrowest.
 *
 * <p>A {@link PartnerPermission}'s <em>floor</em> is also a {@code ScopeType}: the narrowest kind of grant
 * that may satisfy it. Floor {@code COMPANY} is satisfied only by a company grant, floor {@code PROPERTY}
 * by a company or property grant, floor {@code UNIT} by any grant (§4.5, §11.4). In V1 a {@code UNIT} is a
 * room type ({@code HotelRoom}); physical rooms do not exist in the schema.
 */
public enum ScopeType {
    COMPANY,
    PROPERTY,
    UNIT;

    /** Whether a grant of type {@code grantType} may satisfy a permission whose floor is this type. */
    public boolean admits(ScopeType grantType) {
        return grantType != null && grantType.ordinal() <= ordinal();
    }
}
