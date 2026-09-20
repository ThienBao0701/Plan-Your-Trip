package com.example.planyourtrip.config;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import org.springframework.validation.annotation.Validated;

import java.time.Duration;

/**
 * Phase A — account lifecycle settings ({@code app.auth.*}). Values live in
 * {@code application.properties} (overridable by environment); nothing here is a secret.
 */
@Component
@ConfigurationProperties(prefix = "app.auth")
@Validated
@Getter
@Setter
public class AuthProperties {

    /** How long an email verification link stays usable. */
    @NotNull
    private Duration verificationTokenTtl;

    /** How long a password reset link stays usable. */
    @NotNull
    private Duration passwordResetTokenTtl;

    /** Minimum gap between two tokens of the same purpose for one account. */
    @NotNull
    private Duration tokenIssueCooldown;

    /** The Partner terms version recorded when a Partner accepts the terms at registration. */
    @NotBlank
    private String partnerTermsVersion;

    /**
     * Public origin of each application surface, used only to build the links placed in account
     * emails. Chosen by the account's role — never by anything the client sends.
     */
    @NotBlank
    private String userAppUrl;

    @NotBlank
    private String partnerAppUrl;

    @NotBlank
    private String adminAppUrl;
}
