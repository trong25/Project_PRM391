package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ApiResponse;
import genZ.PRM391GenZ.entity.Booking;
import genZ.PRM391GenZ.repository.BookingRepository;
import genZ.PRM391GenZ.repository.RoomRepository;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/webhook/sepay")
@RequiredArgsConstructor
public class SepayWebhookController {

    private final BookingRepository bookingRepository;
    private final RoomRepository roomRepository;

    @Data
    @com.fasterxml.jackson.annotation.JsonIgnoreProperties(ignoreUnknown = true)
    public static class SepayWebhookPayload {
        private Long id;
        private String gateway;
        private String transactionDate;
        private String accountNumber;
        private String transferType;
        private Double transferAmount;
        private String content;
        private String referenceCode;
    }

    @PostMapping
    @Transactional
    public ResponseEntity<ApiResponse<String>> handleSepayWebhook(@RequestBody SepayWebhookPayload payload) {
        System.out.println("PRM391_SEPAY_WEBHOOK: Received payload: " + payload);
        if (payload == null || payload.getContent() == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Payload hoặc nội dung chuyển khoản không hợp lệ"));
        }

        String content = payload.getContent().trim();
        // Trích xuất số ID đơn đặt phòng từ nội dung chuyển tiền (ví dụ: "GENZ 12" -> lấy ra 12)
        Pattern pattern = Pattern.compile("\\b(\\d+)\\b");
        Matcher matcher = pattern.matcher(content);
        Integer bookingId = null;
        while (matcher.find()) {
            try {
                bookingId = Integer.parseInt(matcher.group(1));
            } catch (NumberFormatException e) {
                // Bỏ qua nếu số quá lớn
            }
        }

        if (bookingId == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Không tìm thấy mã đặt phòng trong nội dung chuyển khoản"));
        }

        final Integer finalBookingId = bookingId;
        return bookingRepository.findById(finalBookingId).map(booking -> {
            // Sau khi thanh toán online: chuyển sang chờ nhận phòng nhưng không
            // làm lùi trạng thái nếu webhook được gửi lại sau khi khách đã check-in.
            if ("Chờ xác nhận".equals(booking.getStatus())
                    || "Chưa thanh toán".equals(booking.getStatus())) {
                booking.setStatus("Chờ nhận phòng");
            }
            if (booking.getPaidAt() == null) {
                booking.setPaidAt(LocalDateTime.now());
            }

            // Đánh dấu booking đã thanh toán online để nhân viên không thu tiền lần nữa khi trả phòng
            String existingNote = booking.getNote() != null ? booking.getNote() : "";
            if (!existingNote.contains("[PREPAID_ONLINE]")) {
                booking.setNote(existingNote.isEmpty() ? "[PREPAID_ONLINE]" : existingNote + " [PREPAID_ONLINE]");
            }

            bookingRepository.save(booking);
            System.out.println("PRM391_SEPAY_WEBHOOK: Booking #" + finalBookingId + " updated to 'Chờ nhận phòng' + PREPAID_ONLINE");
            return ResponseEntity.ok(ApiResponse.<String>success("Xử lý thanh toán thành công cho booking #" + finalBookingId));
        }).orElse(ResponseEntity.badRequest().body(ApiResponse.error("Không tìm thấy booking #" + finalBookingId)));
    }
}
