package com.example.planyourtrip.service;

import com.example.planyourtrip.security.rbac.AdminEndpointRule;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.StringJoiner;

/**
 * RBAC R6 — read-access audit for sensitive admin reads (RBAC V1.1 §22.5).
 *
 * <ul>
 *   <li>{@code GET /api/admin/users/{userId}/travel-wallet} (A06) writes {@code TRAVEL_WALLET_VIEW}, target the
 *       customer;</li>
 *   <li>{@code GET /api/admin/conversations/{id}} (A28) writes {@code CONVERSATION_VIEW}, target the conversation;
 *       the list endpoint writes one {@code CONVERSATION_VIEW} row per request carrying its filters, not one per
 *       conversation.</li>
 * </ul>
 * Rows carry identifiers only, never content. The row is written before the read runs and through the strict
 * admin trail, so a failed write fails the read (fail closed). A registry rule marked {@code readAudit} without a
 * writer here is refused the same way.
 */
@Service
public class AdminReadAuditService {

    static final String TRAVEL_WALLET = "/api/admin/users/{userId}/travel-wallet";
    static final String CONVERSATIONS = "/api/admin/conversations";
    static final String CONVERSATION = "/api/admin/conversations/{id}";

    /** The conversation list filters, all identifiers or an enum; anything else is never written. */
    private static final String[] CONVERSATION_FILTERS = {"status", "userId", "partnerProfileId", "bookingId"};

    private final AdminActivityLogService audit;

    public AdminReadAuditService(AdminActivityLogService audit) {
        this.audit = audit;
    }

    /**
     * Writes the audit row of one sensitive read before it runs.
     *
     * @param pathVariables the matched URI template variables
     * @param parameters    the request parameters
     */
    public void recordRead(AdminEndpointRule rule, Long actorUserId, Map<String, String> pathVariables,
                           Map<String, String[]> parameters) {
        switch (rule.pattern()) {
            case TRAVEL_WALLET -> audit.record(actorUserId, "TRAVEL_WALLET_VIEW", "USER",
                idOf(pathVariables, "userId"), "Viewed a customer's travel wallet");
            case CONVERSATIONS, CONVERSATION -> recordConversationView(actorUserId,
                CONVERSATION.equals(rule.pattern()) ? idOf(pathVariables, "id") : null, parameters);
            default -> throw new IllegalStateException("No read-audit writer for " + rule.key());
        }
    }

    private void recordConversationView(Long actorUserId, Long conversationId, Map<String, String[]> parameters) {
        String description = conversationId != null ? "Viewed a conversation"
            : "Listed conversations" + filters(parameters);
        audit.record(actorUserId, "CONVERSATION_VIEW", "CONVERSATION", conversationId, description);
    }

    /** " (status=OPEN, userId=12)" for the whitelisted filters whose values are an id or an enum name. */
    private static String filters(Map<String, String[]> parameters) {
        StringJoiner joined = new StringJoiner(", ", " (", ")").setEmptyValue("");
        for (String name : CONVERSATION_FILTERS) {
            String[] values = parameters == null ? null : parameters.get(name);
            if (values == null || values.length == 0 || values[0] == null) continue;
            String value = values[0].trim();
            // ids up to 12 digits: the audit trail refuses 13-19 digit numbers as card-number shaped
            if (value.matches("[0-9]{1,12}|[A-Z_]{1,40}")) joined.add(name + "=" + value);
        }
        return joined.toString();
    }

    private static Long idOf(Map<String, String> pathVariables, String name) {
        String raw = pathVariables == null ? null : pathVariables.get(name);
        if (raw == null || !raw.matches("[0-9]{1,19}")) return null;
        try {
            return Long.valueOf(raw);
        } catch (NumberFormatException overflow) {
            return null;
        }
    }
}
