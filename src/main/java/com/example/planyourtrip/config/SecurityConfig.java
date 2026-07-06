package com.example.planyourtrip.config;

import com.example.planyourtrip.security.JwtAuthenticationFilter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.*;
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
    SecurityFilterChain securityFilterChain(HttpSecurity http, JwtAuthenticationFilter jwt) throws Exception {
        return http
            .csrf(csrf -> csrf.disable())
            .cors(c -> {})
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a
                .requestMatchers(
                    "/api/auth/**",
                    "/api/health",
                    "/swagger-ui/**",
                    "/swagger-ui.html",
                    "/v3/api-docs/**",
                    "/h2-console/**"
                ).permitAll()
                .requestMatchers(HttpMethod.GET,
                    "/api/locations/**",
                    "/api/categories/**",
                    "/api/amenities/**",
                    "/api/places",
                    "/api/places/**",
                    "/api/rooms/*/pricing"
                ).permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .requestMatchers("/api/partner/**").hasAnyRole("PARTNER", "ADMIN")
                .anyRequest().authenticated()
            )
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
