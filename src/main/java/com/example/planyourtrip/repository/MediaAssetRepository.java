package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.MediaAsset;
import com.example.planyourtrip.model.MediaOwnerType;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface MediaAssetRepository extends JpaRepository<MediaAsset, Long> {

    List<MediaAsset> findByOwnerTypeAndOwnerIdAndActiveTrueOrderBySortOrderAsc(
            MediaOwnerType ownerType, Long ownerId);

    // Phase 7.45 — deterministic ordering (sortOrder, then id) for a single owner's active media.
    List<MediaAsset> findByOwnerTypeAndOwnerIdAndActiveTrueOrderBySortOrderAscIdAsc(
            MediaOwnerType ownerType, Long ownerId);

    // Phase 7.45 — batch load of active media for many owners (avoids N+1 in list responses).
    List<MediaAsset> findByOwnerTypeAndOwnerIdInAndActiveTrueOrderBySortOrderAscIdAsc(
            MediaOwnerType ownerType, Collection<Long> ownerIds);

    List<MediaAsset> findByOwnerTypeAndOwnerIdOrderBySortOrderAsc(
            MediaOwnerType ownerType, Long ownerId);

    Optional<MediaAsset> findByIdAndActiveTrue(Long id);

    long countByOwnerTypeAndOwnerIdAndCoverTrue(MediaOwnerType ownerType, Long ownerId);

    boolean existsByOwnerTypeAndOwnerIdAndId(MediaOwnerType ownerType, Long ownerId, Long id);

    boolean existsByOwnerTypeAndOwnerId(MediaOwnerType ownerType, Long ownerId);

    @Modifying
    @Query("UPDATE MediaAsset m SET m.cover = false WHERE m.ownerType = :ownerType AND m.ownerId = :ownerId AND m.cover = true")
    void clearCoverByOwner(MediaOwnerType ownerType, Long ownerId);

    /**
     * D3M — locks one owner's gallery for the duration of a cover change.
     *
     * <p>The "at most one cover" rule was procedural only: {@link #clearCoverByOwner}
     * followed by a set. Two concurrent {@code setCover} calls on the same gallery each
     * cleared a snapshot the other had not yet written to, and both then set their own
     * row — leaving two covers, with no unique constraint to catch it. {@code MediaAsset}
     * has no {@code @Version}, and optimistic locking would not have helped anyway: the
     * race is across two <em>different</em> rows, each of which is written exactly once.
     *
     * <p>Serialising on the owner's rows is the same pessimistic strategy the project
     * already uses for room inventory and payment sessions, and it is portable across
     * H2 and SQL Server (a filtered unique index would not be).
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select m from MediaAsset m where m.ownerType = :ownerType and m.ownerId = :ownerId")
    List<MediaAsset> lockGalleryForUpdate(MediaOwnerType ownerType, Long ownerId);
}
