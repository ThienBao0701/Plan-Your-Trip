package com.example.planyourtrip.exception;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.http.*;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;

import java.time.Instant;
import java.util.Set;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    record ErrorBody(String timestamp, int status, String error, String message, String path) {}

    @ExceptionHandler(ApiException.class)
    ResponseEntity<ErrorBody> api(ApiException ex, HttpServletRequest req) {
        return ResponseEntity.status(ex.status()).body(new ErrorBody(
            Instant.now().toString(), ex.status().value(), ex.status().getReasonPhrase(),
            ex.getMessage(), req.getRequestURI()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ErrorBody> validation(MethodArgumentNotValidException ex, HttpServletRequest req) {
        String msg = ex.getBindingResult().getFieldErrors().stream().findFirst()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .orElse("Validation failed");
        return ResponseEntity.badRequest().body(new ErrorBody(
            Instant.now().toString(), 400, "Bad Request", msg, req.getRequestURI()));
    }

    @ExceptionHandler(ConstraintViolationException.class)
    ResponseEntity<ErrorBody> constraintViolation(ConstraintViolationException ex, HttpServletRequest req) {
        String msg = ex.getConstraintViolations().stream().findFirst()
            .map(v -> {
                String path = v.getPropertyPath().toString();
                String param = path.contains(".") ? path.substring(path.lastIndexOf('.') + 1) : path;
                return param + ": " + v.getMessage();
            })
            .orElse("Validation failed");
        return ResponseEntity.badRequest().body(new ErrorBody(
            Instant.now().toString(), 400, "Bad Request", msg, req.getRequestURI()));
    }

    /**
     * Phase 7.19 — {@code CustomerMembership} uses optimistic locking
     * ({@code @Version}), deliberately unlike {@code LoyaltyAccount}/
     * {@code TravelCreditAccount}'s pessimistic {@code SELECT ... FOR UPDATE}
     * (see {@code CustomerMembershipService} class javadoc for the rationale).
     * A lost-update race surfaces here as 409 — the caller can safely retry
     * the same mutation; no automatic retry loop is implemented in this phase.
     */
    @ExceptionHandler(OptimisticLockingFailureException.class)
    ResponseEntity<ErrorBody> optimisticLock(OptimisticLockingFailureException ex, HttpServletRequest req) {
        return ResponseEntity.status(409).body(new ErrorBody(
            Instant.now().toString(), 409, "Conflict",
            "The resource was modified concurrently; please retry", req.getRequestURI()));
    }

    @ExceptionHandler(AccessDeniedException.class)
    ResponseEntity<ErrorBody> forbidden(AccessDeniedException ex, HttpServletRequest req) {
        return ResponseEntity.status(403).body(new ErrorBody(
            Instant.now().toString(), 403, "Forbidden", "Access denied", req.getRequestURI()));
    }

    @ExceptionHandler(NoHandlerFoundException.class)
    ResponseEntity<ErrorBody> notFound(NoHandlerFoundException ex, HttpServletRequest req) {
        return ResponseEntity.status(404).body(new ErrorBody(
            Instant.now().toString(), 404, "Not Found", "Resource not found", req.getRequestURI()));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // H-FIX 2 — Spring request-binding failures.
    //
    // These four are thrown by Spring MVC while binding the request, BEFORE any
    // controller or service code runs. Without explicit handlers they fell through
    // to the catch-all below and surfaced as 500 "Unexpected server error", which
    // made a caller's malformed request indistinguishable from a genuine server
    // fault in logs and alerting. They are pure client errors, so they map to
    // 400/405 and reuse the same uniform ErrorBody as every other response.
    //
    // Deliberately NOT logged at error level: they are caller mistakes, not faults.
    // ─────────────────────────────────────────────────────────────────────────

    /** A required query parameter was absent, e.g. {@code GET /api/partner/rooms} with no {@code hotelId}. */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    ResponseEntity<ErrorBody> missingParameter(MissingServletRequestParameterException ex,
                                                HttpServletRequest req) {
        return ResponseEntity.badRequest().body(new ErrorBody(
            Instant.now().toString(), 400, "Bad Request",
            ex.getParameterName() + ": required parameter is missing", req.getRequestURI()));
    }

    /**
     * A path variable or query parameter could not be converted to the declared type —
     * a non-numeric id, or a malformed {@code LocalDate} such as {@code from=NOTADATE}.
     * The offending value is echoed back because it is the caller's own input.
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    ResponseEntity<ErrorBody> typeMismatch(MethodArgumentTypeMismatchException ex,
                                            HttpServletRequest req) {
        Class<?> required = ex.getRequiredType();
        String expected = required != null ? required.getSimpleName() : "the expected type";
        return ResponseEntity.badRequest().body(new ErrorBody(
            Instant.now().toString(), 400, "Bad Request",
            ex.getName() + ": '" + ex.getValue() + "' is not a valid " + expected,
            req.getRequestURI()));
    }

    /**
     * The request body could not be parsed — malformed JSON, or a value Jackson cannot
     * bind such as an unknown enum constant (e.g. a team role of {@code SUPER_PARTNER}).
     * The parser's own message is not echoed: it can carry type and package internals.
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    ResponseEntity<ErrorBody> unreadableBody(HttpMessageNotReadableException ex,
                                              HttpServletRequest req) {
        return ResponseEntity.badRequest().body(new ErrorBody(
            Instant.now().toString(), 400, "Bad Request",
            "Malformed request body: the JSON could not be parsed, or a field holds an unsupported value",
            req.getRequestURI()));
    }

    /**
     * The route exists but not for this verb (e.g. {@code GET} on the PUT-only
     * {@code /api/partner/reviews/{id}/reply}). RFC 9110 requires {@code Allow} on a 405,
     * so the supported methods are advertised when Spring knows them.
     */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    ResponseEntity<ErrorBody> methodNotAllowed(HttpRequestMethodNotSupportedException ex,
                                                HttpServletRequest req) {
        ResponseEntity.BodyBuilder builder = ResponseEntity.status(405);
        Set<HttpMethod> supported = ex.getSupportedHttpMethods();
        if (supported != null && !supported.isEmpty()) {
            builder.allow(supported.toArray(new HttpMethod[0]));
        }
        return builder.body(new ErrorBody(
            Instant.now().toString(), 405, "Method Not Allowed",
            ex.getMethod() + " is not supported for this endpoint", req.getRequestURI()));
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ErrorBody> generic(Exception ex, HttpServletRequest req) {
        log.error("Unhandled exception at {}: {}", req.getRequestURI(), ex.getMessage(), ex);
        return ResponseEntity.status(500).body(new ErrorBody(
            Instant.now().toString(), 500, "Internal Server Error", "Unexpected server error", req.getRequestURI()));
    }
}
