package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.MediaAsset;
import com.example.planyourtrip.model.MediaOwnerType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface MediaAssetRepository extends JpaRepository<MediaAsset, Long> {

    List<MediaAsset> findByOwnerTypeAndOwnerIdAndActiveTrueOrderBySortOrderAsc(
            MediaOwnerType ownerType, Long ownerId);

    List<MediaAsset> findByOwnerTypeAndOwnerIdOrderBySortOrderAsc(
            MediaOwnerType ownerType, Long ownerId);

    Optional<MediaAsset> findByIdAndActiveTrue(Long id);

    long countByOwnerTypeAndOwnerIdAndCoverTrue(MediaOwnerType ownerType, Long ownerId);

    boolean existsByOwnerTypeAndOwnerIdAndId(MediaOwnerType ownerType, Long ownerId, Long id);

    boolean existsByOwnerTypeAndOwnerId(MediaOwnerType ownerType, Long ownerId);

    @Modifying
    @Query("UPDATE MediaAsset m SET m.cover = false WHERE m.ownerType = :ownerType AND m.ownerId = :ownerId AND m.cover = true")
    void clearCoverByOwner(MediaOwnerType ownerType, Long ownerId);
}
