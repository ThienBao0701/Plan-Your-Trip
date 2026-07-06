package com.example.planyourtrip.repository;
import com.example.planyourtrip.model.TimelineItem; import org.springframework.data.jpa.repository.JpaRepository; import java.util.*;
public interface TimelineItemRepository extends JpaRepository<TimelineItem,Long>{

List<TimelineItem> findByTripOwnerIdAndTripId(Long ownerId, Long tripId); Optional<TimelineItem> findByIdAndTripOwnerId(Long id, Long ownerId);

}
