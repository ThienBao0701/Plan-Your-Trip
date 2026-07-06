package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CategoryRepository extends JpaRepository<Category, Long> {

    List<Category> findByParentIsNull();

    List<Category> findByParentId(Long parentId);

    Optional<Category> findBySlug(String slug);

    boolean existsBySlug(String slug);
}
