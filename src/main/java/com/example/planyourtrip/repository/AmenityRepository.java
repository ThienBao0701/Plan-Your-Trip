package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Amenity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AmenityRepository extends JpaRepository<Amenity, Long> {

    List<Amenity> findByGroupName(String groupName);

    boolean existsBySlug(String slug);

    java.util.Optional<Amenity> findBySlug(String slug);
}
