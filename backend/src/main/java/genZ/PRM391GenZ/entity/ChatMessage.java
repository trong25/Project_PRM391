package genZ.PRM391GenZ.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * Entity ánh xạ bảng ChatMessage (schema mới).
 * Lưu từng tin nhắn trong một Conversation.
 */
@Entity
@Table(name = "ChatMessage")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // FK → Conversation (ConversationId)
    @Column(name = "ConversationId", nullable = false, length = 50)
    private String conversationId;

    // ID người gửi (FK → User)
    @Column(name = "sender_id", nullable = false, length = 50)
    private String senderId;

    // Tên hiển thị của người gửi
    @Column(name = "sender_name", columnDefinition = "NVARCHAR(255)")
    private String senderName;

    // ID người nhận (optional, giữ lại để tương thích)
    @Column(name = "receiver_id", length = 50)
    private String receiverId;

    // Nội dung tin nhắn
    @Column(name = "content", nullable = false, columnDefinition = "NVARCHAR(MAX)")
    private String content;

    // Loại tin nhắn: TEXT, IMAGE, FILE, SYSTEM
    @Column(name = "message_type", length = 20)
    @Builder.Default
    private String messageType = "TEXT";

    // URL ảnh/file đính kèm
    @Column(name = "attachment_url", columnDefinition = "VARCHAR(MAX)")
    private String attachmentUrl;

    // Thời điểm gửi (DATETIME2)
    @Column(name = "sent_at", nullable = false)
    private LocalDateTime sentAt;

    // Đã đọc hay chưa
    @Column(name = "is_read", nullable = false)
    @Builder.Default
    private boolean isRead = false;

    @PrePersist
    protected void onCreate() {
        if (sentAt == null) {
            sentAt = LocalDateTime.now();
        }
    }
}
