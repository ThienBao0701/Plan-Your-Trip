package com.example.planyourtrip.security;

import com.example.planyourtrip.model.AccountRole;
import com.example.planyourtrip.repository.UserRepository;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * Authenticates a request from its bearer token against the account's <em>current</em> state.
 *
 * <p>Phase A — a signed, unexpired token is not enough. The account is loaded on every request and the
 * request is authenticated only when all of these hold:
 * <ul>
 *   <li>the account still exists and is {@code enabled} (S1);</li>
 *   <li>the token's {@code ver} equals the account's {@code tokenVersion}, so a token issued before a
 *       credential change no longer works (S3);</li>
 *   <li>the stored role is exactly USER, PARTNER or ADMIN (S4) — anything else grants no authority
 *       at all rather than {@code ROLE_<whatever>}.</li>
 * </ul>
 * A token that fails any check leaves the request anonymous; protected endpoints then answer with the
 * standard 401 from {@code SecurityConfig}.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final JwtService jwt;
    private final UserRepository users;

    public JwtAuthenticationFilter(JwtService jwt, UserRepository users) {
        this.jwt = jwt;
        this.users = users;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String header = req.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            jwt.parse(header.substring(7)).ifPresent(claims -> users.findById(claims.userId())
               .filter(u -> u.isEnabled() && u.getTokenVersion() == claims.tokenVersion())
               .ifPresent(u -> AccountRole.parse(u.getRole()).ifPresent(role -> {
                   var authorities = List.of(new SimpleGrantedAuthority("ROLE_" + role.name()));
                   var principal = new UserPrincipal(u.getId(), u.getEmail(), u.getPasswordHash(), authorities);
                   var authentication = new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
                   // RBAC R3a §18 O-7 — when this session's token was issued, for the step-up freshness check.
                   authentication.setDetails(new TokenSession(claims.issuedAt()));
                   SecurityContextHolder.getContext().setAuthentication(authentication);
               })));
        }
        chain.doFilter(req, res);
    }
}
