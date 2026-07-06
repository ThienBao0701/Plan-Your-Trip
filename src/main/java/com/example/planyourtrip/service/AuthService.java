package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.AuthDtos.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final JwtService jwt;

    public AuthService(UserRepository users, PasswordEncoder encoder, JwtService jwt) {
        this.users = users;
        this.encoder = encoder;
        this.jwt = jwt;
    }

    @Transactional
    public AuthResponse register(RegisterRequest r) {
        if (users.existsByEmail(r.email().toLowerCase()))
            throw new ApiException(HttpStatus.CONFLICT, "Email already registered");
        User u = new User();
        u.setFullName(r.fullName());
        u.setEmail(r.email().toLowerCase());
        u.setPasswordHash(encoder.encode(r.password()));
        users.save(u);
        return toAuthResponse(u);
    }

    public AuthResponse login(LoginRequest r) {
        User u = users.findByEmail(r.email().toLowerCase())
            .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Invalid email or password"));
        if (!encoder.matches(r.password(), u.getPasswordHash()))
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Invalid email or password");
        return toAuthResponse(u);
    }

    private AuthResponse toAuthResponse(User u) {
        String token = jwt.createToken(u.getId(), u.getEmail());
        return new AuthResponse(token, new UserDto(u.getId(), u.getFullName(), u.getEmail(), u.getRole()));
    }
}
