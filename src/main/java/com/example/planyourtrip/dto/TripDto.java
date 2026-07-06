package com.example.planyourtrip.dto;
import jakarta.validation.constraints.*; import java.time.LocalDate;
public record TripDto(Long id, @NotBlank String title, @NotBlank String destination, String imageUrl, @NotNull LocalDate startDate, @NotNull LocalDate endDate, @Min(1) int travelers, @DecimalMin("0.0") double budget) {}
