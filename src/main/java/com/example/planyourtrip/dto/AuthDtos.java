package com.example.planyourtrip.dto;

import jakarta.validation.constraints.*;

public class AuthDtos {
    public record RegisterRequest(
        @NotBlank String fullName,
        @Email @NotBlank String email,
        @Size(min = 8) String password
    ) {}

    public record LoginRequest(
        @Email @NotBlank String email,
        @NotBlank String password
    ) {}

    public record UserDto(Long id, String fullName, String email, String role) {}

    public record AuthResponse(String token, UserDto user) {}
}
