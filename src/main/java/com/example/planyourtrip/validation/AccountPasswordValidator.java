package com.example.planyourtrip.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.nio.charset.StandardCharsets;

/** Enforces {@link AccountPassword}. Reports one specific reason; never echoes the value. */
public class AccountPasswordValidator implements ConstraintValidator<AccountPassword, String> {

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        String reason = null;
        if (value == null || value.isEmpty()) {
            reason = "is required";
        } else if (value.codePointCount(0, value.length()) < AccountPassword.MIN_CHARACTERS) {
            reason = "must be at least " + AccountPassword.MIN_CHARACTERS + " characters";
        } else if (exceedsMaxBytes(value)) {
            reason = "must be at most " + AccountPassword.MAX_BYTES + " bytes";
        }
        if (reason == null) return true;
        context.disableDefaultConstraintViolation();
        context.buildConstraintViolationWithTemplate(reason).addConstraintViolation();
        return false;
    }

    /** True when {@code value} is longer than BCrypt can hash. Null is not "too long". */
    public static boolean exceedsMaxBytes(String value) {
        return value != null && value.getBytes(StandardCharsets.UTF_8).length > AccountPassword.MAX_BYTES;
    }
}
