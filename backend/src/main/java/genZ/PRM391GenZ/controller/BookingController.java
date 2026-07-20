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

        Booking saved = bookingRepository.save(booking);
        return ResponseEntity.ok(ApiResponse.success("Đặt phòng thành công", saved));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<Booking>> updateStatus(
            @PathVariable Integer id, @RequestParam String status) {
        return bookingRepository.findById(id).map(b -> {
            b.setStatus(status);

            // Tự động đồng bộ trạng thái phòng tương ứng
            if (b.getRoom() != null) {
                genZ.PRM391GenZ.entity.Room room = b.getRoom();
                if ("Đang ở".equals(status)) {
                    room.setStatus("Đang thuê");
                    roomRepository.save(room);
                } else if ("Đã thanh toán".equals(status)) {
                    room.setStatus("Dọn dẹp");
                    roomRepository.save(room);
                } else if ("Đã hủy".equals(status)) {
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
}