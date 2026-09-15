package com.example.planyourtrip.dto;

import jakarta.validation.constraints.NotNull;

/**
 * Body of {@code PATCH /api/admin/amenities/{id}/status}, {@code /categories/{id}/status} and
 * {@code /locations/{id}/status}.
 *
 * <p>D14 — {@code active} is a {@link Boolean} with {@code @NotNull}, validated by {@code @Valid} at
 * all three controllers. It used to be a primitive {@code boolean}, so a body with the key missing,
 * misspelled or {@code null} bound silently to {@code false} and deactivated the row. Each of those is
 * now a 400. The project-wide convention of ignoring unknown JSON keys is unchanged, which is why a
 * misspelled key is refused as "active is missing" rather than as an unknown property.
 */
public record StatusRequest(@NotNull Boolean active) {}
