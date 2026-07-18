package genZ.PRM391GenZ.dto;

import lombok.*;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatRoomDTO {

    private String roomId;
    private String customerId;
    private String customerName;
    private String lastMessage;
    private String lastMessageTime;
    private int unreadCount;
}
