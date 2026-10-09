package com.example.planyourtrip.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

/**
 * RBAC R4 hardening — free text that will be written to the strict audit trail (a suspension, removal, grant change
 * or invitation revocation reason) must not look like credential material: the same pattern the audit guards refuse
 * ({@code AdminActivityLogService.looksLikeCredential}).
 *
 * <p>Checking it at the request boundary turns what would be a failed audit write — the mutation rolled back, the
 * client answered 500 — into the structured 400 {@code VALIDATION_FAILED} with a {@code fieldErrors} entry, before
 * any lock is taken or anything changes. The audit guards stay as the fail-closed backstop. The check is
 * deliberately conservative (a reason that merely mentions "password" is refused too): telling harmless wording from
 * a real secret is not reliable, and the caller can simply rephrase. The rejected value is never echoed or logged.
 */
@Documented
@Constraint(validatedBy = NoCredentialTextValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER, ElementType.RECORD_COMPONENT})
@Retention(RetentionPolicy.RUNTIME)
public @interface NoCredentialText {

    String message() default "must not contain passwords, secrets, keys, tokens or card or account numbers";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
