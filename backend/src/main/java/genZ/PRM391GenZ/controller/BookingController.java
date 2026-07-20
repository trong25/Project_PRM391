package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Booking;
import genZ.PRM391GenZ.repository.BookingRepository;
import genZ.PRM391GenZ.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.time.LocalDateTime;

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
            // Luồng mới: trả phòng và thanh toán trong cùng một thao tác.
            // WAITING_PAYMENT được giữ để tương thích với client/booking cũ.
            STAYING, Set.of(WAITING_PAYMENT, PAID),
            WAITING_PAYMENT, Set.of(PAID)
    );

    private final BookingRepository bookingRepository;
    private final genZ.PRM391GenZ.repository.RoomRepository roomRepository;
    private final UserRepository userRepository;

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
        List<Booking> bookings = bookingRepository.findByUser_UserIdOrderByBookingIdDesc(userId);
        return ResponseEntity.ok(ApiResponse.success("Booking của người dùng", bookings));
    }

    @GetMapping("/room/{roomId}/busy-slots")
    public ResponseEntity<ApiResponse<List<Booking>>> getBusySlots(@PathVariable String roomId) {
        List<Booking> bookings = bookingRepository.findByRoom_RoomId(roomId);
        List<Booking> active = bookings.stream()
                .filter(b -> !"Đã hủy".equalsIgnoreCase(b.getStatus()))
                .toList();
        return ResponseEntity.ok(ApiResponse.success("Lịch bận của phòng", active));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Booking>> createBooking(@RequestBody Booking booking) {
        if (booking.getRoom() == null || booking.getRoom().getRoomId() == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Phòng không hợp lệ"));
        }
        
        genZ.PRM391GenZ.entity.Room room = roomRepository.findById(booking.getRoom().getRoomId())
                .orElseThrow(() -> new RuntimeException("Room not found"));
                
        String status = room.getStatus();
        if (status == null || (!"Trống".equalsIgnoreCase(status) && !"available".equalsIgnoreCase(status))) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Lỗi: Phòng hiện tại không còn trống để đặt!"));
        }

        String overlapError = checkOverlap(booking);
        if (overlapError != null) {
            return ResponseEntity.badRequest().body(ApiResponse.error(overlapError));
        }

        // Trạng thái khởi tạo do backend quyết định, không tin giá trị client gửi lên.
        booking.setStatus(PENDING_APPROVAL);
        populateGuestInfo(booking);
        Booking saved = bookingRepository.save(booking);
        return ResponseEntity.ok(ApiResponse.success("Đặt phòng thành công", saved));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<Booking>> updateStatus(
            @PathVariable Integer id, @RequestParam String status) {
        return bookingRepository.findById(id).map(b -> {
            if (status.equals(b.getStatus())) {
                return ResponseEntity.ok(ApiResponse.success("Trạng thái booking không thay đổi", b));
            }

            Set<String> allowedStatuses = ALLOWED_TRANSITIONS.getOrDefault(b.getStatus(), Set.of());
            if (!allowedStatuses.contains(status)) {
                return ResponseEntity.status(HttpStatus.CONFLICT).body(
                        ApiResponse.<Booking>error(
                                "Không thể chuyển booking từ '" + b.getStatus() + "' sang '" + status + "'"
                        )
                );
            }

            b.setStatus(status);
            if (PAID.equals(status)) {
                b.setPaidAt(LocalDateTime.now());
            }
            syncRoomStatus(b, status);

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

    @DeleteMapping("/customer/{id}")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<Void>> cancelCustomerBooking(
            @PathVariable Integer id,
            Authentication authentication) {
        Booking booking = bookingRepository.findById(id).orElse(null);
        if (booking == null) {
            return ResponseEntity.notFound().build();
        }

        String currentEmail = authentication != null ? authentication.getName() : null;
        String bookingEmail = booking.getUser() != null ? booking.getUser().getEmail() : null;
        if (currentEmail == null || bookingEmail == null || !currentEmail.equalsIgnoreCase(bookingEmail)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(ApiResponse.error("Không có quyền hủy booking này"));
        }

        Set<String> cancellableStatuses = Set.of(
                PENDING_APPROVAL,
                WAITING_CHECK_IN,
                "Chưa thanh toán"
        );
        if (!cancellableStatuses.contains(booking.getStatus())) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("Chỉ có thể hủy booking đang chờ xác nhận hoặc chờ nhận phòng"));
        }

        // Giữ lại lịch sử booking để đối soát, chỉ chuyển trạng thái sang đã hủy.
        booking.setStatus(CANCELLED);
        syncRoomStatus(booking, CANCELLED);
        bookingRepository.save(booking);
        return ResponseEntity.ok(ApiResponse.success("Hủy booking thành công", null));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<Booking>> updateBooking(
            @PathVariable Integer id, @RequestBody Booking booking) {
        return bookingRepository.findById(id).map(existing -> {
            // Set fields to temporary object to check overlap
            Booking temp = new Booking();
            temp.setBookingId(id);
            temp.setRoom(booking.getRoom() != null ? booking.getRoom() : existing.getRoom());
            temp.setCheckIn(booking.getCheckIn() != null ? booking.getCheckIn() : existing.getCheckIn());
            temp.setCheckOut(booking.getCheckOut() != null ? booking.getCheckOut() : existing.getCheckOut());
            temp.setStatus(existing.getStatus());

            String overlapError = checkOverlap(temp);
            if (overlapError != null) {
                return ResponseEntity.badRequest().body(ApiResponse.<Booking>error(overlapError));
            }

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
            if (booking.getGuestName() != null) {
                existing.setGuestName(booking.getGuestName());
            }
            if (booking.getGuestPhone() != null) {
                existing.setGuestPhone(booking.getGuestPhone());
            }
            
            Booking saved = bookingRepository.save(existing);
            return ResponseEntity.ok(ApiResponse.success("Cập nhật booking thành công", saved));
        }).orElse(ResponseEntity.notFound().build());
    }

    private String checkOverlap(Booking booking) {
        if (booking.getRoom() == null || booking.getRoom().getRoomId() == null) {
            return null;
        }
        
        List<Booking> existingBookings = bookingRepository.findByRoom_RoomId(booking.getRoom().getRoomId());
        java.time.LocalDateTime newStart = booking.getCheckIn();
        java.time.LocalDateTime newEnd = booking.getCheckOut();
        if (newStart == null) return null;
        if (newEnd == null) {
            newEnd = newStart.plusHours(2);
        }
        
        java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
        
        for (Booking existing : existingBookings) {
            // Skip the same booking when updating
            if (booking.getBookingId() != null && booking.getBookingId().equals(existing.getBookingId())) {
                continue;
            }
            // Skip canceled bookings
            if ("Đã hủy".equalsIgnoreCase(existing.getStatus())) {
                continue;
            }
            
            java.time.LocalDateTime existStart = existing.getCheckIn();
            java.time.LocalDateTime existEnd = existing.getCheckOut();
            if (existEnd == null) {
                existEnd = existStart.plusHours(2);
            }
            
            if (newStart.isBefore(existEnd) && existStart.isBefore(newEnd)) {
                return "Phòng này đã có người đặt trong khoảng thời gian từ " + existStart.format(formatter) + " đến " + existEnd.format(formatter) + "!";
            }
        }
        return null;
    }

    private void syncRoomStatus(Booking booking, String bookingStatus) {
        if (booking.getRoom() == null) {
            return;
        }

        genZ.PRM391GenZ.entity.Room room = booking.getRoom();
        if (STAYING.equals(bookingStatus)) {
            room.setStatus("Đang thuê");
        } else if (WAITING_PAYMENT.equals(bookingStatus) || PAID.equals(bookingStatus)) {
            room.setStatus("Dọn dẹp");
        } else if (CANCELLED.equals(bookingStatus)) {
            room.setStatus("Trống");
        } else {
            return;
        }
        roomRepository.save(room);
    }

    private void populateGuestInfo(Booking booking) {
        if (booking.getUser() == null || booking.getUser().getUserId() == null) {
            return;
        }

        userRepository.findById(booking.getUser().getUserId()).ifPresent(user -> {
            booking.setUser(user);
            if (booking.getGuestName() == null || booking.getGuestName().isBlank()) {
                booking.setGuestName(user.getFullName());
            }
            if (booking.getGuestPhone() == null || booking.getGuestPhone().isBlank()) {
                booking.setGuestPhone(user.getPhone());
            }
        });
    }
}
