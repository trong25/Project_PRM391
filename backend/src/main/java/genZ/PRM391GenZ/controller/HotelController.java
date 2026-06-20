package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Hotel;
import genZ.PRM391GenZ.repository.HotelRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/hotels")
@RequiredArgsConstructor
public class HotelController {

    private final HotelRepository hotelRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Hotel>>> getAllHotels() {
        return ResponseEntity.ok(ApiResponse.success("Danh sách khách sạn", hotelRepository.findAll()));
    }
}
