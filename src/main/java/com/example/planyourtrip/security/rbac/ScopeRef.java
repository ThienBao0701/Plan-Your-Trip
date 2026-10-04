package com.example.planyourtrip.security.rbac;

import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The stored or wire form of a grant's scope — {@code COMPANY:456}, {@code PROPERTY:123}, {@code UNIT:9001}
 * (§12.3 {@code scope_type} + {@code scope_id}). It names a scope but proves nothing: it becomes a usable
 * {@link ScopePath} only after the server has resolved it against the company that holds the grant
 * ({@code PartnerResourceTargetResolver#resolveGrantScope}), which refuses ids of another company.
 */
public record ScopeRef(ScopeType type, long id) {

    private static final Pattern FORMAT = Pattern.compile("(COMPANY|PROPERTY|UNIT):([1-9][0-9]{0,18})");

    public ScopeRef {
        if (type == null) throw new IllegalArgumentException("A scope needs a type");
        if (id <= 0) throw new IllegalArgumentException("A scope id must be positive");
    }

    /**
     * The scope written exactly as {@code TYPE:id}, or empty. Matching is exact and case-sensitive: no
     * whitespace, no lower case, no sign, no leading zero, no unknown type — a malformed scope is no scope
     * (fail closed).
     */
    public static Optional<ScopeRef> parse(String raw) {
        if (raw == null) return Optional.empty();
        Matcher m = FORMAT.matcher(raw);
        if (!m.matches()) return Optional.empty();
        try {
            return Optional.of(new ScopeRef(ScopeType.valueOf(m.group(1)), Long.parseLong(m.group(2))));
        } catch (NumberFormatException overflow) {
            return Optional.empty();
        }
    }

    @Override
    public String toString() {
        return type.name() + ":" + id;
    }
}
