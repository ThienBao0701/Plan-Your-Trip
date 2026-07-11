package com.example.planyourtrip.exception;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.http.*;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.NoHandlerFoundException;

import java.time.Instant;

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

    @ExceptionHandler(Exception.class)
    ResponseEntity<ErrorBody> generic(Exception ex, HttpServletRequest req) {
        log.error("Unhandled exception at {}: {}", req.getRequestURI(), ex.getMessage(), ex);
        return ResponseEntity.status(500).body(new ErrorBody(
            Instant.now().toString(), 500, "Internal Server Error", "Unexpected server error", req.getRequestURI()));
    }
}
