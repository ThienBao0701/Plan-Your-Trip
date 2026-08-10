package com.example.planyourtrip.config;

import com.example.planyourtrip.security.JwtAuthenticationFilter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.*;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.http.HttpMethod;
import org.springframework.web.cors.*;

import java.time.Instant;
import java.util.*;

@Configuration
public class SecurityConfig {

    @Bean
    PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(); }

    @Bean
    AuthenticationManager authenticationManager(AuthenticationConfiguration c) throws Exception {
        return c.getAuthenticationManager();
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, JwtAuthenticationFilter jwt,
                                            Environment env) throws Exception {
        // DB-06 — API docs (springdoc) and the H2 console are dev/test surfaces only. springdoc is
        // additionally disabled in application-prod.properties; here we ALSO refuse to permitAll their
        // paths under the prod profile (defense-in-depth) so they can never be publicly reachable in
        // production even if a docs bean were re-enabled by mistake.
        boolean prod = env.acceptsProfiles(Profiles.of("prod"));
        return http
            .csrf(csrf -> csrf.disable())
            .cors(c -> {})
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> {
                a.requestMatchers(
                    "/api/auth/**",
                    // /api/health (liveness) + /api/health/ready (DB-06 readiness) — both public.
                    "/api/health/**",
                    // Phase 7.27 — real provider webhooks are unauthenticated but
                    // signature-verified inside PaymentGatewayService.processWebhook.
                    "/api/webhooks/payments/**"
                ).permitAll();
                if (!prod) {
                    a.requestMatchers(
                        "/swagger-ui/**",
                        "/swagger-ui.html",
                        "/v3/api-docs/**",
                        "/h2-console/**"
                    ).permitAll();
                }
                a.requestMatchers(HttpMethod.GET,
                    "/api/locations/**",
                    "/api/categories/**",
                    "/api/amenities/**",
                    "/api/places",
                    "/api/places/**",
                    "/api/rooms/*/pricing",
                    // Phase 7.29 — public rate-plan listing / pricing preview / cancellation preview
                    "/api/rooms/*/rate-plans",
                    "/api/rooms/*/rate-plans/**",
                    "/api/trips/public/**"
                ).permitAll();
                // Phase 7.32 — public canonical pricing quote (POST body). Read-only; same
                // public visibility as the legacy GET /api/rooms/{roomId}/pricing endpoint.
                a.requestMatchers(HttpMethod.POST, "/api/rooms/*/pricing/quote").permitAll();
                a.requestMatchers("/api/admin/**").hasRole("ADMIN");
                a.requestMatchers("/api/partner/profile/**").authenticated();
                a.requestMatchers("/api/partner/**").hasAnyRole("PARTNER", "ADMIN");
                a.anyRequest().authenticated();
            })
            .headers(h -> h.frameOptions(f -> f.sameOrigin()))
            .exceptionHandling(e -> e
                .authenticationEntryPoint((req, res, ex) -> {
                    res.setStatus(401);
                    res.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    res.getWriter().write(jsonError(401, "Unauthorized", "Authentication required", req.getRequestURI()));
                })
                .accessDeniedHandler((req, res, ex) -> {
                    res.setStatus(403);
                    res.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    res.getWriter().write(jsonError(403, "Forbidden", "Access denied", req.getRequestURI()));
                })
            )
            .addFilterBefore(jwt, UsernamePasswordAuthenticationFilter.class)
            .build();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource(
            @Value("${app.cors.allowed-origin-patterns:http://localhost:*,http://127.0.0.1:*}") String patterns) {
        CorsConfiguration c = new CorsConfiguration();
        c.setAllowedOriginPatterns(Arrays.asList(patterns.split(",")));
        c.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        c.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With"));
        c.setExposedHeaders(List.of("Authorization"));
        c.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource s = new UrlBasedCorsConfigurationSource();
        s.registerCorsConfiguration("/**", c);
        return s;
    }

    private String jsonError(int status, String error, String message, String path) {
        return String.format(
            "{\"timestamp\":\"%s\",\"status\":%d,\"error\":\"%s\",\"message\":\"%s\",\"path\":\"%s\"}",
            Instant.now(), status, error, message, path);
    }
}
