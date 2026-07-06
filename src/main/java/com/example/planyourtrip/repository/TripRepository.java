package com.example.planyourtrip.repository;
import com.example.planyourtrip.model.Trip; import org.springframework.data.jpa.repository.JpaRepository; import java.util.*;
public interface TripRepository extends JpaRepository<Trip,Long>{
List<Trip> findByOwnerId(Long ownerId); Optional<Trip> findByIdAndOwnerId(Long id, Long ownerId);


}
