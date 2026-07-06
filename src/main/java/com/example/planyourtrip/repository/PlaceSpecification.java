package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.model.PlaceTag;
import com.example.planyourtrip.util.SlugUtils;
import org.springframework.data.jpa.domain.Specification;

public final class PlaceSpecification {

    private PlaceSpecification() {}

    public static Specification<Place> withStatus(PlaceStatus status) {
        if (status == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("status"), status);
    }

    public static Specification<Place> withKeyword(String q) {
        if (q == null || q.isBlank()) return Specification.where(null);
        String normalized = SlugUtils.normalize(q.trim());
        String normLike = "%" + normalized + "%";
        String rawLike = "%" + q.trim().toLowerCase() + "%";
        return (root, query, cb) -> {
            // Subquery for tags avoids JOIN duplicates while still matching tag text
            var tagSub = query.subquery(Long.class);
            var tagRoot = tagSub.from(PlaceTag.class);
            tagSub.select(tagRoot.get("place").get("id"))
                  .where(cb.like(tagRoot.get("tagNormalized"), normLike));
            return cb.or(
                cb.like(root.get("nameNormalized"), normLike),
                cb.like(cb.lower(root.get("slug")), rawLike),
                cb.like(cb.lower(root.get("address")), rawLike),
                cb.like(cb.lower(root.get("shortDescription")), rawLike),
                cb.like(cb.lower(root.get("description")), rawLike),
                root.get("id").in(tagSub)
            );
        };
    }

    public static Specification<Place> withCategoryId(Long categoryId) {
        if (categoryId == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("category").get("id"), categoryId);
    }

    public static Specification<Place> withCategorySlug(String slug) {
        if (slug == null || slug.isBlank()) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("category").get("slug"), slug);
    }

    public static Specification<Place> withSubcategoryId(Long subcategoryId) {
        if (subcategoryId == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("subcategory").get("id"), subcategoryId);
    }

    public static Specification<Place> withLocationId(Long locationId) {
        if (locationId == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("administrativeUnit").get("id"), locationId);
    }

    public static Specification<Place> withMinRating(Double minRating) {
        if (minRating == null) return Specification.where(null);
        return (root, query, cb) -> cb.greaterThanOrEqualTo(root.get("ratingAvg"), minRating);
    }

    public static Specification<Place> withMaxPriceLevel(Integer maxPriceLevel) {
        if (maxPriceLevel == null) return Specification.where(null);
        return (root, query, cb) -> cb.lessThanOrEqualTo(root.get("priceLevel"), maxPriceLevel);
    }

    public static Specification<Place> withFeatured(Boolean featured) {
        if (featured == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("featured"), featured);
    }

    public static Specification<Place> withVerified(Boolean verified) {
        if (verified == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("verified"), verified);
    }
}
