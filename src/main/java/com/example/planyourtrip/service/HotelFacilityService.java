package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.HotelExperienceDto.FacilityRequest;
import com.example.planyourtrip.dto.HotelExperienceDto.FacilityResponse;
import com.example.planyourtrip.model.HotelDetail;
import com.example.planyourtrip.model.HotelFacility;
import com.example.planyourtrip.repository.HotelFacilityRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class HotelFacilityService {

    private final HotelFacilityRepository repo;

    public HotelFacilityService(HotelFacilityRepository repo) {
        this.repo = repo;
    }

    public List<FacilityResponse> getByHotelDetail(Long hotelDetailId) {
        return repo.findAllByHotelDetailIdOrderBySortOrderAsc(hotelDetailId)
            .stream().map(this::toResponse).toList();
    }

    @Transactional
    public List<FacilityResponse> replaceAll(HotelDetail detail, List<FacilityRequest> requests) {
        repo.deleteAllByHotelDetailId(detail.getId());
        if (requests == null || requests.isEmpty()) return List.of();
        int order = 0;
        for (FacilityRequest req : requests) {
            HotelFacility f = new HotelFacility();
            f.setHotelDetail(detail);
            f.setFacilityName(req.facilityName());
            f.setFacilityGroup(req.facilityGroup());
            f.setIcon(req.icon());
            f.setSortOrder(req.sortOrder() > 0 ? req.sortOrder() : ++order);
            repo.save(f);
        }
        return getByHotelDetail(detail.getId());
    }

    FacilityResponse toResponse(HotelFacility f) {
        return new FacilityResponse(
            f.getId(), f.getFacilityName(), f.getFacilityGroup(), f.getIcon(), f.getSortOrder()
        );
    }
}
