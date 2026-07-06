package com.example.planyourtrip.dto;
import jakarta.validation.constraints.*; import java.time.LocalTime;
public record TimelineDto(Long id, Long tripId, @Min(1) int dayNumber, @NotNull LocalTime startTime, @NotNull LocalTime endTime, @NotBlank String title, String notes, Long placeId) {}
