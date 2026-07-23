package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.SavedCollection;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SavedCollectionRepository extends JpaRepository<SavedCollection, Long> {

    List<SavedCollection> findByOwnerIdOrderBySortOrderAscCreatedAtAsc(Long ownerId);

    /** Owner-scoped lookup — the basis for the uniform 404 on a foreign/unknown collection. */
    Optional<SavedCollection> findByIdAndOwnerId(Long id, Long ownerId);

    long countByOwnerId(Long ownerId);
}
