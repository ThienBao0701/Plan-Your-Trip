package com.example.planyourtrip.dto;

import java.util.Arrays;
import java.util.stream.Collectors;

/**
 * RBAC R3b — one field a partner response withholds because the caller lacks its field-level permission
 * (RBAC V1.1 §21.2 SD-1). {@code field} is the JSON path, e.g. {@code booking.userEmail}; {@code mode} is
 * {@code MASKED} (guest names, SD-2) or {@code OMITTED} (everything else: the value is null).
 *
 * <p>Never-to-partner fields (§21.3: payment links, provider errors, traveller ids, bearer instruments) are not
 * listed: no partner role can ever receive them, so they are simply absent from partner responses (SD-3).
 */
public record RedactedField(String field, String mode) {

    public static final String MASKED = "MASKED";
    public static final String OMITTED = "OMITTED";

    public static RedactedField masked(String field) { return new RedactedField(field, MASKED); }

    public static RedactedField omitted(String field) { return new RedactedField(field, OMITTED); }

    /**
     * SD-2 — a name masked to the first letter of each part followed by a dot: "Tran Thien Bao" → "T. T. B.".
     * Null stays null.
     */
    public static String maskName(String name) {
        if (name == null || name.isBlank()) return name;
        return Arrays.stream(name.trim().split("\\s+"))
            .map(part -> part.substring(0, 1).toUpperCase() + ".")
            .collect(Collectors.joining(" "));
    }
}
