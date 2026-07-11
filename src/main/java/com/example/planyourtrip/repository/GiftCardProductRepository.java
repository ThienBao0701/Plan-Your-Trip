package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.GiftCardProduct;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GiftCardProductRepository extends JpaRepository<GiftCardProduct, Long> {

    Optional<GiftCardProduct> findByProductCodeIgnoreCase(String productCode);

    boolean existsByProductCodeIgnoreCase(String productCode);

    List<GiftCardProduct> findAllByOrderByCreatedAtDesc();
}
