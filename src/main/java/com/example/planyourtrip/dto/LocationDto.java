package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.UnitType;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;

public class LocationDto {

    /**
     * D14 — request bounds, enforced by {@code @Valid} before any service code runs.
     *
     * <p>{@link #NAME_MAX} is 80, not the 255 the column allows, because {@code fullPath} is derived
     * from names: the D13 hierarchy is at most three deep, so the longest derived path is
     * {@code 3 * 80 + 2 * " > ".length() = 246}, which fits the existing 255-character column. A
     * longer name could make an otherwise legal create, rename or descendant cascade fail at the
     * database as a 500.
     */
    public static final int NAME_MAX = 80;
    public static final int CODE_MAX = 32;
    public static final int SLUG_MAX = 100;
    public static final int OLD_NAME_MAX = 255;

    public record LocationResponse(
        Long id,
        Long parentId,
        String code,
        String name,
        String slug,
        String type,
        Integer level,
        String oldName,
        String fullPath,
        Double latitude,
        Double longitude,
        Integer sortOrder,
        boolean active,
        Instant createdAt,
        Instant updatedAt
    ) {}

    /**
     * Create and full-replace update body.
     *
     * <p>{@code fullPath} is accepted for wire compatibility and ignored — the server derives it from
     * the hierarchy — so it carries no size bound here. Coordinates are optional and independent (no
     * pairing rule), but a present value must be a finite number inside the geographic range:
     * {@code @DecimalMin}/{@code @DecimalMax} refuse {@code NaN} and both infinities as well as
     * out-of-range values. {@code code} stays optional; the service stores a blank one as
     * {@code null}.
     */
    public record LocationRequest(
        Long parentId,
        @Size(max = CODE_MAX) String code,
        @NotBlank @Size(max = NAME_MAX) String name,
        @Size(max = SLUG_MAX) String slug,
        @NotNull UnitType type,
        Integer level,
        @Size(max = OLD_NAME_MAX) String oldName,
        String fullPath,
        @DecimalMin("-90") @DecimalMax("90") Double latitude,
        @DecimalMin("-180") @DecimalMax("180") Double longitude,
        Integer sortOrder
    ) {}
}
