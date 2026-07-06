package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomRequest;
import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomResponse;
import com.example.planyourtrip.service.HotelRoomService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Admin - Rooms")
@SecurityRequirement(name = "bearerAuth")
public class AdminRoomController {

    private final HotelRoomService service;

    public AdminRoomController(HotelRoomService service) {
        this.service = service;
    }

    @GetMapping("/api/admin/hotels/{placeId}/rooms")
    public List<HotelRoomResponse> listByHotel(@PathVariable Long placeId) {
        return service.getByPlaceId(placeId, false);
    }

    @PostMapping("/api/admin/rooms")
    @ResponseStatus(HttpStatus.CREATED)
    public HotelRoomResponse create(@Valid @RequestBody HotelRoomRequest req) {
        return service.create(req);
    }

    @GetMapping("/api/admin/rooms/{id}")
    public HotelRoomResponse getById(@PathVariable Long id) {
        return service.getById(id);
    }

    @PutMapping("/api/admin/rooms/{id}")
    public HotelRoomResponse update(@PathVariable Long id,
                                    @Valid @RequestBody HotelRoomRequest req) {
        return service.update(id, req);
    }

    @PatchMapping("/api/admin/rooms/{id}/deactivate")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deactivate(@PathVariable Long id) {
        service.deactivate(id);
    }
}
