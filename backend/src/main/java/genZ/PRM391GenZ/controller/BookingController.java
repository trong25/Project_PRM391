package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Booking;
import genZ.PRM391GenZ.repository.BookingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/bookings")
@RequiredArgsConstructor
public class BookingController {

    private static final String PENDING_APPROVAL = "Chờ xác nhận";
    private static final String WAITING_CHECK_IN = "Chờ nhận phòng";
    private static final String STAYING = "Đang ở";
    private static final String WAITING_PAYMENT = "Chờ thanh toán";
    private static final String PAID = "Đã thanh toán";
    private static final String CANCELLED = "Đã hủy";

    // "Chưa thanh toán" được giữ để các booking cũ vẫn có thể tiếp tục quy trình.
    private static final Map<String, Set<String>> ALLOWED_TRANSITIONS = Map.of(
            PENDING_APPROVAL, Set.of(WAITING_CHECK_IN, CANCELLED),
            WAITING_CHECK_IN, Set.of(STAYING, CANCELLED),
            "Chưa thanh toán", Set.of(STAYING, CANCELLED),
            STAYING, Set.of(WAITING_PAYMENT),
            WAITING_PAYMENT, Set.of(PAID)
    );

    private final BookingRepository bookingRepository;
    private final genZ.PRM391GenZ.repository.RoomRepository roomRepository;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
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
        // Trạng thái khởi tạo do server quyết định, không tin giá trị client gửi lên.
        booking.setStatus(PENDING_APPROVAL);
        Booking saved = bookingRepository.save(booking);
        return ResponseEntity.ok(ApiResponse.success("Đặt phòng thành công", saved));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<Booking>> updateStatus(
            @PathVariable Integer id, @RequestParam String status) {
        return bookingRepository.findById(id).map(b -> {
            Set<String> allowedStatuses = ALLOWED_TRANSITIONS.getOrDefault(b.getStatus(), Set.of());
            if (!allowedStatuses.contains(status)) {
                return ResponseEntity.status(HttpStatus.CONFLICT).body(
                        ApiResponse.<Booking>error(
                                "Không thể chuyển booking từ '" + b.getStatus() + "' sang '" + status + "'"
                        )
                );
            }

            b.setStatus(status);
            
            // Tự động đồng bộ trạng thái phòng tương ứng
            if (b.getRoom() != null) {
                genZ.PRM391GenZ.entity.Room room = b.getRoom();
                if (STAYING.equals(status)) {
                    room.setStatus("Đang thuê");
                    roomRepository.save(room);
                } else if (WAITING_PAYMENT.equals(status) || PAID.equals(status)) {
                    room.setStatus("Dọn dẹp");
                    roomRepository.save(room);
                } else if (CANCELLED.equals(status)) {
                    room.setStatus("Trống");
                    roomRepository.save(room);
                }
            }

            Booking updated = bookingRepository.save(b);
            return ResponseEntity.ok(ApiResponse.success("Cập nhật trạng thái", updated));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<Void>> deleteBooking(@PathVariable Integer id) {
        return bookingRepository.findById(id).map(b -> {
            bookingRepository.delete(b);
            return ResponseEntity.ok(ApiResponse.<Void>success("Xóa booking thành công", null));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<Booking>> updateBooking(
            @PathVariable Integer id, @RequestBody Booking booking) {
        return bookingRepository.findById(id).map(existing -> {
            if (booking.getRoom() != null) {
                existing.setRoom(booking.getRoom());
            }
            if (booking.getUser() != null) {
                existing.setUser(booking.getUser());
            }
            if (booking.getTypeBooking() != null) {
                existing.setTypeBooking(booking.getTypeBooking());
            }
            existing.setCheckIn(booking.getCheckIn());
            existing.setCheckOut(booking.getCheckOut());
            existing.setTotalPrice(booking.getTotalPrice());
            existing.setVoucherCode(booking.getVoucherCode());
            existing.setDiscountAmount(booking.getDiscountAmount());
            existing.setNote(booking.getNote());
            
            Booking saved = bookingRepository.save(existing);
            return ResponseEntity.ok(ApiResponse.success("Cập nhật booking thành công", saved));
        }).orElse(ResponseEntity.notFound().build());
    }
}
