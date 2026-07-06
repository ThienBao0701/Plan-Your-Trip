package com.example.planyourtrip.repository;
import com.example.planyourtrip.model.Expense; import org.springframework.data.jpa.repository.JpaRepository; import java.util.*;
public interface ExpenseRepository extends JpaRepository<Expense,Long>{


List<Expense> findByTripOwnerIdAndTripId(Long ownerId, Long tripId); Optional<Expense> findByIdAndTripOwnerId(Long id, Long ownerId);
}
