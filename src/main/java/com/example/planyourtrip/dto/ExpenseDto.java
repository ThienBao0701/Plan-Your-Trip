package com.example.planyourtrip.dto;
import jakarta.validation.constraints.*; import java.time.LocalDate;
public record ExpenseDto(Long id, Long tripId, @NotBlank String title, @NotBlank String category, @DecimalMin("0.0") double amount, @NotNull LocalDate date) {}
