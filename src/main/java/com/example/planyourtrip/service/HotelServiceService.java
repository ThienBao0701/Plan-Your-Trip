package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.HotelExperienceDto.ServiceRequest;
import com.example.planyourtrip.dto.HotelExperienceDto.ServiceResponse;
import com.example.planyourtrip.model.HotelDetail;
import com.example.planyourtrip.model.HotelService;
import com.example.planyourtrip.repository.HotelServiceRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class HotelServiceService {

    private final HotelServiceRepository repo;

    public HotelServiceService(HotelServiceRepository repo) {
        this.repo = repo;
    }

    public List<ServiceResponse> getByHotelDetail(Long hotelDetailId) {
        return repo.findAllByHotelDetailId(hotelDetailId)
            .stream().map(this::toResponse).toList();
    }

    @Transactional
    public List<ServiceResponse> replaceAll(HotelDetail detail, List<ServiceRequest> requests) {
        repo.deleteAllByHotelDetailId(detail.getId());
        if (requests == null || requests.isEmpty()) return List.of();
        for (ServiceRequest req : requests) {
            HotelService s = new HotelService();
            s.setHotelDetail(detail);
            s.setServiceName(req.serviceName());
            s.setIcon(req.icon());
            s.setAvailable(req.available());
            repo.save(s);
        }
        return getByHotelDetail(detail.getId());
    }

    ServiceResponse toResponse(HotelService s) {
        return new ServiceResponse(s.getId(), s.getServiceName(), s.getIcon(), s.isAvailable());
    }
}
