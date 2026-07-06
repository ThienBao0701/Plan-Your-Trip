package com.example.planyourtrip.security;

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
            jwt.parseUserId(header.substring(7))
               .flatMap(users::findById)
               .ifPresent(u -> {
                   var authorities = List.of(new SimpleGrantedAuthority("ROLE_" + u.getRole()));
                   var principal = new UserPrincipal(u.getId(), u.getEmail(), u.getPasswordHash(), authorities);
                   SecurityContextHolder.getContext().setAuthentication(
                       new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));
               });
        }
        chain.doFilter(req, res);
    }
}
