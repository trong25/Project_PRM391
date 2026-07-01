package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.dto.room.RoomDto;
import genZ.PRM391GenZ.service.RoomService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomService roomService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<RoomDto>>> getAllRooms() {
        return ResponseEntity.ok(
                ApiResponse.success("Danh sách phòng", roomService.getAllRooms())
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RoomDto>> getRoomById(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success("Thông tin phòng", roomService.getRoomById(id)));
    }

    @GetMapping("/hotel/{hotelId}")
    public ResponseEntity<ApiResponse<List<RoomDto>>> getRoomsByHotel(@PathVariable String hotelId) {
        return ResponseEntity.ok(ApiResponse.success("Phòng theo khách sạn", roomService.getRoomsByHotel(hotelId)));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<RoomDto>> createRoom(@Valid @RequestBody RoomDto dto) {
        return ResponseEntity.ok(ApiResponse.success("Tạo phòng thành công", roomService.createRoom(dto)));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<RoomDto>> updateRoom(
            @PathVariable String id, @Valid @RequestBody RoomDto dto) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật phòng thành công", roomService.updateRoom(id, dto)));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteRoom(@PathVariable String id) {
        roomService.deleteRoom(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa phòng thành công"));
    }
}
