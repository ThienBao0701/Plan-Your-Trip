package com.example.planyourtrip.service;

import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import com.example.planyourtrip.exception.ApiException;

/** Central policy for sandbox-only payment operations. */
@Component
public class PaymentRuntimePolicy {

    private final Environment environment;
    private final boolean simulationEnabled;

    public PaymentRuntimePolicy(Environment environment,
                                 @Value("${app.payments.simulation.enabled:false}") boolean simulationEnabled) {
        this.environment = environment;
        this.simulationEnabled = simulationEnabled;
    }

    public boolean isProductionLike() {
        return environment.acceptsProfiles(Profiles.of("prod", "production", "staging"));
    }

    public boolean simulationAllowed() {
        return simulationEnabled && !isProductionLike();
    }

    public void requireSimulationAllowed() {
        if (!simulationAllowed()) {
            throw new ApiException(HttpStatus.FORBIDDEN, "PAYMENT_SIMULATION_DISABLED",
                "Payment simulation is unavailable in this environment");
        }
    }

    public ApiException providerUnavailable() {
        return new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "PAYMENT_PROVIDER_UNAVAILABLE",
            "No live payment provider is currently configured");
    }
}
