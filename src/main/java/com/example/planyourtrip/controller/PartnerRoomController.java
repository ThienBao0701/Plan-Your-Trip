package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.HotelRoomDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerRoomService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/partner/rooms")
@Tag(name = "Partner - Rooms", description = "Approved partners manage rooms for hotels they own")
@SecurityRequirement(name = "bearerAuth")
public class PartnerRoomController {

    private final PartnerRoomService service;

    public PartnerRoomController(PartnerRoomService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List my rooms for one of my hotels")
    public List<HotelRoomResponse> getMyRooms(@AuthUser Long uid, @RequestParam Long hotelId) {
        return service.getMyRooms(uid, hotelId);
    }

    @GetMapping("/{roomId}")
    @Operation(summary = "Get room detail")
    public HotelRoomResponse getRoom(@AuthUser Long uid, @PathVariable Long roomId) {
        return service.getRoom(uid, roomId);
    }

    @PutMapping("/{roomId}")
    @Operation(summary = "Update room information")
    public HotelRoomResponse updateRoom(@AuthUser Long uid, @PathVariable Long roomId,
                                         @Valid @RequestBody HotelRoomRequest req) {
        return service.updateRoomInformation(uid, roomId, req);
    }

    @PatchMapping("/{roomId}/activate")
    @Operation(summary = "Activate my room")
    public HotelRoomResponse activate(@AuthUser Long uid, @PathVariable Long roomId) {
        return service.activate(uid, roomId);
    }

    @PatchMapping("/{roomId}/deactivate")
    @Operation(summary = "Deactivate my room")
    public HotelRoomResponse deactivate(@AuthUser Long uid, @PathVariable Long roomId) {
        return service.deactivate(uid, roomId);
    }
}
