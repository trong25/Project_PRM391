package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ChatMessageDTO;
import genZ.PRM391GenZ.entity.Conversation;
import genZ.PRM391GenZ.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.util.Map;

/**
 * WebSocket/STOMP handlers phải dùng @Controller (không dùng @RestController).
 */
@Controller
@RequiredArgsConstructor
public class ChatWebSocketController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatService chatService;

    @MessageMapping("/chat.send")
    public void sendMessage(@Payload ChatMessageDTO messageDTO) {
        ChatMessageDTO saved = chatService.saveMessage(messageDTO);

        messagingTemplate.convertAndSend(
                "/topic/chat/" + saved.getConversationId(),
                saved
        );

        messagingTemplate.convertAndSend("/topic/staff/conversations", saved);
    }

    @MessageMapping("/chat.join")
    public void joinChat(@Payload Map<String, String> payload) {
        String customerId = payload.get("customerId");

        Conversation conv = chatService.getOrCreateConversation(customerId);

        messagingTemplate.convertAndSend(
                "/topic/chat/join/" + customerId,
                Map.of("conversationId", conv.getConversationId(), "status", conv.getStatus())
        );

        messagingTemplate.convertAndSend(
                "/topic/staff/conversations",
                Map.of("event", "NEW_CUSTOMER", "customerId", customerId,
                        "conversationId", conv.getConversationId())
        );
    }
}
