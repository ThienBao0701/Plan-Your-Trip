package com.example.planyourtrip.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.*;

/**
 * Phase A — the password policy for every password the application stores: required, at least
 * {@link #MIN_CHARACTERS} characters, and at most {@link #MAX_BYTES} bytes of UTF-8.
 *
 * <p>The byte ceiling is BCrypt's: the bundled {@code BCryptPasswordEncoder} throws for longer input,
 * which used to surface as a 500. The limit is in bytes rather than characters because a Vietnamese or
 * emoji password reaches 72 bytes well before 72 characters.
 */
@Documented
@Constraint(validatedBy = AccountPasswordValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER, ElementType.RECORD_COMPONENT})
@Retention(RetentionPolicy.RUNTIME)
public @interface AccountPassword {

    int MIN_CHARACTERS = 8;
    int MAX_BYTES = 72;

    String message() default "is not a valid password";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
