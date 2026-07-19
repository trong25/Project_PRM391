package genZ.PRM391GenZ.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

/**
 * DTO đại diện cho một tin nhắn trong Conversation.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatMessageDTO {

    private Long id;

    // FK tới Conversation (thay roomId cũ)
    private String conversationId;

    private String senderId;
    private String senderName;

    // Người nhận (optional)
    private String receiverId;

    private String content;

    // Loại tin nhắn: TEXT, IMAGE, FILE, SYSTEM
    private String messageType;

    // URL ảnh/file đính kèm (null nếu là text)
    private String attachmentUrl;

    // Thời gian gửi (ISO string)
    private String sentAt;

    // Đã đọc hay chưa - @JsonProperty để Jackson serialize đúng là "isRead" thay vì "read"
    @JsonProperty("isRead")
    private boolean isRead;
}
