package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Hotel;
import genZ.PRM391GenZ.repository.HotelRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Locale;

@RestController
@RequestMapping("/hotels")
@RequiredArgsConstructor
public class HotelController {

    private static final String HOTEL_NAME_PREFIX = "GenZ Cinema";

    private final HotelRepository hotelRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Hotel>>> getAllHotels() {
        return ResponseEntity.ok(ApiResponse.success("Danh sách khách sạn", hotelRepository.findAll()));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Hotel>> createHotel(@RequestBody Hotel request) {
        if (request.getName() == null || request.getName().isBlank()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Vui lòng nhập tên chi nhánh"));
        }

        Hotel hotel = Hotel.builder()
                .hotelId(nextHotelId())
                .name(normalizeHotelName(request.getName()))
                .address(request.getAddress() == null ? null : request.getAddress().trim())
                .phone(request.getPhone() == null ? null : request.getPhone().trim())
                .countRoom(0)
                .build();

        return ResponseEntity.ok(ApiResponse.success("Tạo chi nhánh thành công", hotelRepository.save(hotel)));
    }

    private String nextHotelId() {
        int nextNumber = hotelRepository.findAll().stream()
                .map(Hotel::getHotelId)
                .filter(id -> id != null && id.toUpperCase(Locale.ROOT).startsWith("HOTEL"))
                .map(id -> id.substring(5))
                .mapToInt(value -> {
                    try {
                        return Integer.parseInt(value);
                    } catch (NumberFormatException ignored) {
                        return 0;
                    }
                })
                .max()
                .orElse(0) + 1;

        return String.format("HOTEL%03d", nextNumber);
    }

    private String normalizeHotelName(String name) {
        String trimmedName = name.trim();
        if (trimmedName.toLowerCase(Locale.ROOT).startsWith(HOTEL_NAME_PREFIX.toLowerCase(Locale.ROOT))) {
            return trimmedName;
        }
        return HOTEL_NAME_PREFIX + " " + trimmedName;
    }
}
