package genZ.PRM391GenZ.dto;

import lombok.*;

/**
 * DTO đại diện cho một phiên chat (Conversation).
 * Trả về cho cả Customer và Staff.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConversationDTO {

    private String conversationId;

    // Thông tin khách hàng
    private String customerId;
    private String customerName;

    // Thông tin staff (null nếu chưa ai nhận)
    private String staffId;
    private String staffName;

    // Trạng thái: Open, Pending, Closed
    private String status;

    // Thời gian tạo và tin nhắn cuối
    private String createdAt;
    private String lastMessageAt;

    // Số tin nhắn chưa đọc (tính real-time theo user đang đăng nhập)
    private long unreadCount;

    // Tin nhắn preview (tin nhắn cuối, optional)
    private String lastMessagePreview;
}
