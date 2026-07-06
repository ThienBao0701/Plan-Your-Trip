package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.RatePlanDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.RatePlan;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.RatePlanRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class RatePlanService {

    private final RatePlanRepository ratePlanRepo;
    private final HotelRoomRepository roomRepo;

    public RatePlanService(RatePlanRepository ratePlanRepo, HotelRoomRepository roomRepo) {
        this.ratePlanRepo = ratePlanRepo;
        this.roomRepo     = roomRepo;
    }

    public List<RatePlanResponse> getByRoom(Long roomId) {
        roomOrThrow(roomId);
        return ratePlanRepo.findByHotelRoomIdOrderByStartDateAsc(roomId)
            .stream().map(this::toResponse).toList();
    }

    public RatePlanResponse getById(Long id) {
        return toResponse(planOrThrow(id));
    }

    @Transactional
    public RatePlanResponse create(Long roomId, RatePlanRequest req) {
        HotelRoom room = roomOrThrow(roomId);
        validateDates(req.startDate(), req.endDate());
        RatePlan plan = new RatePlan();
        plan.setHotelRoom(room);
        fill(plan, req);
        return toResponse(ratePlanRepo.save(plan));
    }

    @Transactional
    public RatePlanResponse update(Long id, RatePlanRequest req) {
        RatePlan plan = planOrThrow(id);
        validateDates(req.startDate(), req.endDate());
        fill(plan, req);
        return toResponse(ratePlanRepo.save(plan));
    }

    @Transactional
    public void delete(Long id) {
        planOrThrow(id);
        ratePlanRepo.deleteById(id);
    }

    RatePlanResponse toResponse(RatePlan plan) {
        return new RatePlanResponse(
            plan.getId(),
            plan.getHotelRoom().getId(),
            plan.getRateName(),
            plan.getRateType(),
            plan.getPricePerNight(),
            plan.getStartDate(),
            plan.getEndDate(),
            plan.isActive(),
            plan.getCreatedAt(),
            plan.getUpdatedAt()
        );
    }

    private void fill(RatePlan plan, RatePlanRequest req) {
        plan.setRateName(req.rateName());
        plan.setRateType(req.rateType());
        plan.setPricePerNight(req.pricePerNight());
        plan.setStartDate(req.startDate());
        plan.setEndDate(req.endDate());
        if (req.active() != null) plan.setActive(req.active());
    }

    private void validateDates(LocalDate start, LocalDate end) {
        if (!end.isAfter(start)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "endDate must be after startDate");
        }
    }

    private HotelRoom roomOrThrow(Long roomId) {
        return roomRepo.findById(roomId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId));
    }

    private RatePlan planOrThrow(Long id) {
        return ratePlanRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Rate plan not found: " + id));
    }
}
