package genZ.PRM391GenZ.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entity ánh xạ bảng Conversation trong schema mới.
 * Quản lý phiên chat giữa Customer và Staff.
 */
@Entity
@Table(name = "Conversation")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Conversation {

    @Id
    @Column(name = "ConversationId", length = 50)
    private String conversationId;

    // ID của khách hàng (FK → User)
    @Column(name = "CustomerId", nullable = false, length = 50)
    private String customerId;

    // ID của staff đang phụ trách (NULL = chưa ai nhận)
    @Column(name = "StaffId", length = 50)
    private String staffId;

    // Gắn hội thoại với 1 booking cụ thể (optional)
    @Column(name = "BookingId")
    private Integer bookingId;

    // Trạng thái: Open, Pending, Closed
    @Column(name = "Status", length = 50, columnDefinition = "NVARCHAR(50)")
    @Builder.Default
    private String status = "Open";

    // Thời gian tạo phiên
    @Column(name = "CreatedAt")
    private LocalDateTime createdAt;

    // Thời gian tin nhắn cuối
    @Column(name = "LastMessageAt")
    private LocalDateTime lastMessageAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
