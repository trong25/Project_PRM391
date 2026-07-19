package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.dto.room.RoomDto;
import genZ.PRM391GenZ.service.CloudinaryService;
import genZ.PRM391GenZ.service.RoomService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomService roomService;
    private final CloudinaryService cloudinaryService;

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

    @PostMapping("/upload-image")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<String>> uploadRoomImage(@RequestParam("file") MultipartFile file) {
        String imageUrl = cloudinaryService.uploadRoomImage(file);
        return ResponseEntity.ok(ApiResponse.success("Upload ảnh phòng thành công", imageUrl));
    }

    @PostMapping("/upload-images")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<String>>> uploadRoomImages(@RequestParam("files") MultipartFile[] files) {
        List<String> imageUrls = cloudinaryService.uploadRoomImages(files);
        return ResponseEntity.ok(ApiResponse.success("Upload ảnh phòng thành công", imageUrls));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<RoomDto>> updateRoom(
            @PathVariable String id, @Valid @RequestBody RoomDto dto) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật phòng thành công", roomService.updateRoom(id, dto)));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<RoomDto>> updateRoomStatus(
            @PathVariable String id, @RequestParam String status) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật trạng thái phòng thành công", roomService.updateRoomStatus(id, status)));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteRoom(@PathVariable String id) {
        roomService.deleteRoom(id);
        return ResponseEntity.ok(ApiResponse.success("Xóa phòng thành công"));
    }
}
