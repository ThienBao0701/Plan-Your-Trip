package com.example.planyourtrip.exception;
import org.springframework.http.HttpStatus;
public class ApiException extends RuntimeException {
    private final HttpStatus status;
    /** Optional stable machine-readable reason, e.g. {@code EMAIL_NOT_VERIFIED}; null for most errors. */
    private final String code;
    /** Optional request field the error belongs to; null when it is not about one field. */
    private final String field;
    /** Optional sub-reason of {@code code}, e.g. {@code MEMBERSHIP_EXISTS} for {@code WORKSPACE_CONFLICT}. */
    private final String reason;

    public ApiException(HttpStatus status, String message) { this(status, null, null, message); }

    /** Phase A — an error clients can branch on by {@code code} instead of parsing the message. */
    public ApiException(HttpStatus status, String code, String message) { this(status, code, null, message); }

    /** Phase A — an error about one request field, reported in {@code fieldErrors}. */
    public ApiException(HttpStatus status, String code, String field, String message) {
        this(status, code, field, message, null);
    }

    /** RBAC R2 — an error whose {@code code} also carries why, e.g. 409 {@code WORKSPACE_CONFLICT} (E16). */
    public ApiException(HttpStatus status, String code, String field, String message, String reason) {
        super(message);
        this.status = status;
        this.code = code;
        this.field = field;
        this.reason = reason;
    }

    public HttpStatus status() { return status; }
    public String code() { return code; }
    public String field() { return field; }
    public String reason() { return reason; }
}
