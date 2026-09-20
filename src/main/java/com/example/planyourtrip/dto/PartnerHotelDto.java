package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.PlaceDto.AmenityRef;
import com.example.planyourtrip.dto.PlaceDto.CategoryRef;
import com.example.planyourtrip.dto.PlaceDto.LocationRef;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.time.LocalTime;
import java.util.List;

public class PartnerHotelDto {

    // Phase C — request bounds, matching the columns the values land in
    // (`places`, `hotel_details` in V1__initial_schema.sql). A value longer than its
    // column would otherwise fail at the database as a 500 instead of a 400.
    public static final int NAME_MAX = 255;
    public static final int ADDRESS_MAX = 255;
    public static final int SHORT_DESCRIPTION_MAX = 500;
    public static final int CONTACT_MAX = 255;
    public static final int POLICY_MAX = 500;
    public static final int LONG_POLICY_MAX = 1000;
    /** `hotel_languages.language` / `hotel_payment_methods.payment_method`. */
    public static final int LIST_ENTRY_MAX = 255;
    /** How many languages or payment methods one property may declare. */
    public static final int LIST_SIZE_MAX = 50;
    /** How many amenities one property may link. The seeded catalogue has 64. */
    public static final int AMENITIES_MAX = 100;

    public record PartnerHotelSummaryResponse(
        Long id,
        String name,
        String slug,
        String shortDescription,
        String address,
        boolean active,
        boolean featured,
        boolean verified,
        double ratingAvg,
        int reviewCount,
        String status,
        // Phase C — the classification and place the partner chose, so the list can
        // show what a property is and where it is without a detail request each.
        CategoryRef category,
        CategoryRef subcategory,
        LocationRef administrativeUnit,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record PartnerHotelResponse(
        Long id,
        String name,
        String slug,
        String shortDescription,
        String description,
        String address,
        Double latitude,
        Double longitude,
        String phone,
        String email,
        String website,
        String facebook,
        String instagram,
        LocalTime checkIn,
        LocalTime checkOut,
        String childrenPolicy,
        String petPolicy,
        String smokingPolicy,
        boolean active,
        boolean featured,
        boolean verified,
        double ratingAvg,
        int reviewCount,
        String status,
        Long ownerProfileId,
        String ownerBusinessName,
        // ── Phase C ──────────────────────────────────────────────────────────
        CategoryRef category,
        CategoryRef subcategory,
        LocationRef administrativeUnit,
        /** Null when the property has no {@code HotelDetail} row yet. */
        Integer starRating,
        String cancellationPolicy,
        Boolean freeCancellation,
        String paymentPolicy,
        Boolean prepaymentRequired,
        Boolean parkingAvailable,
        Boolean parkingFree,
        String parkingDescription,
        Boolean wifiAvailable,
        Boolean wifiFree,
        String internetDescription,
        List<String> languages,
        List<String> paymentMethods,
        List<AmenityRef> amenities,
        Instant createdAt,
        Instant updatedAt
    ) {}

    /**
     * Phase C — everything one property needs to exist, in one request.
     *
     * <p>There is deliberately no {@code status}, {@code slug}, {@code ownerProfileId},
     * {@code createdBy}, {@code featured} or {@code verified} field: the status is always
     * {@code DRAFT}, the slug is derived from the name, the owner and author come from the
     * authenticated principal, and the moderation flags belong to an administrator. A caller that
     * sends them anyway changes nothing, because they are not part of this contract.
     *
     * <p>{@code starRating} is required because {@code hotel_details.star_rating} is
     * {@code not null check (star_rating between 1 and 5)} — there is no value that means "not
     * classified". It is what the partner declares about their own property, never a verified
     * classification, and nothing here invents one on their behalf.
     */
    public record PartnerHotelCreateRequest(
        @NotBlank @Size(max = NAME_MAX) String name,
        @Size(max = SHORT_DESCRIPTION_MAX) String shortDescription,
        String description,
        @NotNull Long categoryId,
        Long subcategoryId,
        @NotNull Long administrativeUnitId,
        @NotBlank @Size(max = ADDRESS_MAX) String address,
        @DecimalMin("-90") @DecimalMax("90") Double latitude,
        @DecimalMin("-180") @DecimalMax("180") Double longitude,
        @Size(max = CONTACT_MAX) String phone,
        @Email @Size(max = CONTACT_MAX) String email,
        @Size(max = CONTACT_MAX) String website,
        @NotNull @Min(1) @Max(5) Integer starRating,
        @NotNull LocalTime checkIn,
        @NotNull LocalTime checkOut,
        @Size(max = POLICY_MAX) String childrenPolicy,
        @Size(max = POLICY_MAX) String petPolicy,
        @Size(max = POLICY_MAX) String smokingPolicy,
        @Size(max = LONG_POLICY_MAX) String cancellationPolicy,
        Boolean freeCancellation,
        Boolean parkingAvailable,
        Boolean parkingFree,
        @Size(max = POLICY_MAX) String parkingDescription,
        Boolean wifiAvailable,
        Boolean wifiFree,
        @Size(max = POLICY_MAX) String internetDescription,
        @Size(max = LIST_SIZE_MAX) List<@Size(max = LIST_ENTRY_MAX) String> languages,
        @Size(max = LIST_SIZE_MAX) List<@Size(max = LIST_ENTRY_MAX) String> paymentMethods,
        @Size(max = AMENITIES_MAX) List<Long> amenityIds
    ) {}

    /**
     * Basic information, plus — Phase C — the optional classification.
     *
     * <p>{@code categoryId} and {@code subcategoryId} are optional so every existing caller keeps
     * its exact behaviour: <b>omitting {@code categoryId} leaves the classification untouched</b>.
     * Sending it replaces the classification wholesale, and {@code subcategoryId} then means
     * literally what it says — a value sets the subcategory, {@code null} clears it.
     */
    public record PartnerHotelUpdateRequest(
        @NotBlank @Size(max = NAME_MAX) String name,
        @Size(max = SHORT_DESCRIPTION_MAX) String shortDescription,
        String description,
        @NotBlank String slug,
        Long categoryId,
        Long subcategoryId
    ) {}

    public record PartnerContactRequest(
        @Size(max = CONTACT_MAX) String phone,
        @Email @Size(max = CONTACT_MAX) String email,
        @Size(max = CONTACT_MAX) String website,
        @Size(max = CONTACT_MAX) String facebook,
        @Size(max = CONTACT_MAX) String instagram
    ) {}

    /**
     * Check-in/out and the property's policies.
     *
     * <p>The three original policy strings keep their existing wholesale-replace behaviour: what is
     * sent is stored, and {@code null} clears them.
     *
     * <p>Every field Phase C added is different on purpose — <b>{@code null} leaves the stored value
     * alone</b>. An older client that does not know about cancellation, parking, Wi-Fi, languages or
     * payment methods therefore cannot erase them by saving the policies it does know about. An
     * empty list is an explicit value and does clear the list it is sent for.
     */
    public record PartnerPolicyRequest(
        @NotNull LocalTime checkIn,
        @NotNull LocalTime checkOut,
        @Size(max = POLICY_MAX) String childrenPolicy,
        @Size(max = POLICY_MAX) String petPolicy,
        @Size(max = POLICY_MAX) String smokingPolicy,
        @Min(1) @Max(5) Integer starRating,
        @Size(max = LONG_POLICY_MAX) String cancellationPolicy,
        Boolean freeCancellation,
        Boolean parkingAvailable,
        Boolean parkingFree,
        @Size(max = POLICY_MAX) String parkingDescription,
        Boolean wifiAvailable,
        Boolean wifiFree,
        @Size(max = POLICY_MAX) String internetDescription,
        @Size(max = LIST_SIZE_MAX) List<@Size(max = LIST_ENTRY_MAX) String> languages,
        @Size(max = LIST_SIZE_MAX) List<@Size(max = LIST_ENTRY_MAX) String> paymentMethods
    ) {}

    /**
     * Coordinates and address, plus — Phase C — the optional administrative unit.
     *
     * <p>{@code administrativeUnitId} is optional for the same reason as the classification above:
     * {@code null} leaves the property where it is.
     */
    public record PartnerLocationRequest(
        @DecimalMin("-90") @DecimalMax("90") Double latitude,
        @DecimalMin("-180") @DecimalMax("180") Double longitude,
        @NotBlank @Size(max = ADDRESS_MAX) String address,
        Long administrativeUnitId
    ) {}

    /** Phase C — the property's amenity set, replaced wholesale by what is sent. */
    public record PartnerAmenitiesRequest(
        @NotNull @Size(max = AMENITIES_MAX) List<Long> amenityIds
    ) {}

    public record AssignOwnerRequest(
        @NotNull Long partnerProfileId
    ) {}
}
