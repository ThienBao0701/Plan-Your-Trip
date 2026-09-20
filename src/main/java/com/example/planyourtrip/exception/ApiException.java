package com.example.planyourtrip.exception;
import org.springframework.http.HttpStatus;
public class ApiException extends RuntimeException {
    private final HttpStatus status;
    /** Optional stable machine-readable reason, e.g. {@code EMAIL_NOT_VERIFIED}; null for most errors. */
    private final String code;
    /** Optional request field the error belongs to; null when it is not about one field. */
    private final String field;

    public ApiException(HttpStatus status, String message) { this(status, null, null, message); }

    /** Phase A — an error clients can branch on by {@code code} instead of parsing the message. */
    public ApiException(HttpStatus status, String code, String message) { this(status, code, null, message); }

    /** Phase A — an error about one request field, reported in {@code fieldErrors}. */
    public ApiException(HttpStatus status, String code, String field, String message) {
        super(message);
        this.status = status;
        this.code = code;
        this.field = field;
    }

    public HttpStatus status() { return status; }
    public String code() { return code; }
    public String field() { return field; }
}
