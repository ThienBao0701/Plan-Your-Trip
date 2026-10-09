package com.example.planyourtrip.validation;

import com.example.planyourtrip.service.AdminActivityLogService;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

/** Validates {@link NoCredentialText}: null and ordinary text pass; text the audit guards would refuse does not. */
public class NoCredentialTextValidator implements ConstraintValidator<NoCredentialText, String> {

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        return !AdminActivityLogService.looksLikeCredential(value);
    }
}
