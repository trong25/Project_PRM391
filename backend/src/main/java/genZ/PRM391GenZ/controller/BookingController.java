package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Booking;
import genZ.PRM391GenZ.repository.BookingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/bookings")
@RequiredArgsConstructor
public class BookingController {

    private final BookingRepository bookingRepository;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<List<Booking>>> getAllBookings() {
        return ResponseEntity.ok(
                ApiResponse.success("Danh sách booking", bookingRepository.findAll())
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Booking>> getBookingById(@PathVariable Integer id) {
        return bookingRepository.findById(id)
                .map(b -> ResponseEntity.ok(ApiResponse.success("Thông tin booking", b)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<Booking>>> getBookingsByUser(@PathVariable String userId) {
        List<Booking> bookings = bookingRepository.findByUser_UserId(userId);
        return ResponseEntity.ok(ApiResponse.success("Booking của người dùng", bookings));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Booking>> createBooking(@RequestBody Booking booking) {
        Booking saved = bookingRepository.save(booking);
        return ResponseEntity.ok(ApiResponse.success("Đặt phòng thành công", saved));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Booking>> updateStatus(
            @PathVariable Integer id, @RequestParam String status) {
        return bookingRepository.findById(id).map(b -> {
            b.setStatus(status);
            Booking updated = bookingRepository.save(b);
            return ResponseEntity.ok(ApiResponse.success("Cập nhật trạng thái", updated));
        }).orElse(ResponseEntity.notFound().build());
    }
}
