package com.example.planyourtrip.service;

/**
 * D3J — test-scope access to the package-private audit text/number helpers.
 *
 * <p>{@code AdminActivityLogService.safeNumber} (D3H) and {@code safeText} (D3I) are deliberately
 * package-private: they are an internal detail of how a caller keeps a legitimate value from
 * tripping the credential guard, not part of the service's API. The boundary tests for them live in
 * {@code com.example.planyourtrip}, so this bridge sits in the service package and forwards. It
 * exists so the tests can reach the helpers without widening production visibility.
 */
public final class AuditHelperBridge {

    private AuditHelperBridge() {}

    public static String safeNumber(Object value) {
        return AdminActivityLogService.safeNumber(value);
    }

    public static String safeText(String value, int max) {
        return AdminActivityLogService.safeText(value, max);
    }
}
