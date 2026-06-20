package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.TypeRoom;
import genZ.PRM391GenZ.repository.TypeRoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/type-rooms")
@RequiredArgsConstructor
public class TypeRoomController {

    private final TypeRoomRepository typeRoomRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<TypeRoom>>> getAllTypeRooms() {
        return ResponseEntity.ok(ApiResponse.success("Danh sách loại phòng", typeRoomRepository.findAll()));
    }
}
