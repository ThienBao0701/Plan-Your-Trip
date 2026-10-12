package com.example.planyourtrip;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.service.PaymentRuntimePolicy;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

import static org.junit.jupiter.api.Assertions.*;

class PaymentRuntimePolicyTest {

    @Test
    void productionLikeProfilesCannotEnableSimulationEvenWithAnExplicitTrueSetting() {
        for (String profile : new String[]{"prod", "production", "staging"}) {
            MockEnvironment environment = new MockEnvironment();
            environment.setActiveProfiles(profile);
            PaymentRuntimePolicy policy = new PaymentRuntimePolicy(environment, true);

            assertFalse(policy.simulationAllowed(), profile);
            assertThrows(ApiException.class, policy::requireSimulationAllowed, profile);
        }
    }
}
