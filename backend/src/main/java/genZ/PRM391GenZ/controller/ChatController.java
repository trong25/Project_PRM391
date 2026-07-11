package genZ.PRM391GenZ.controller;

import genZ.PRM391GenZ.dto.ChatMessageDTO;
import genZ.PRM391GenZ.dto.ConversationDTO;
import genZ.PRM391GenZ.entity.Conversation;
import genZ.PRM391GenZ.repository.UserRepository;
import genZ.PRM391GenZ.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class ChatController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatService chatService;
    private final UserRepository userRepository;

    /**
     * Chuyển email (từ authentication.getName()) sang UserId thực.
     * Spring Security dùng email làm principal name, nhưng CustomerId/StaffId trong DB là UserId.
     */
    private String resolveUserId(String email) {
        return userRepository.findByEmail(email)
                .map(u -> u.getUserId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user với email: " + email));
    }

    // ── REST Endpoints ─────────────────────────────────────────────────────────

    /**
     * Gửi tin nhắn qua REST (đảm bảo lưu DB + broadcast realtime).
     * POST /api/chat/messages
     */
    @PostMapping("/chat/messages")
    public ResponseEntity<ChatMessageDTO> sendMessage(@RequestBody ChatMessageDTO messageDTO) {
        ChatMessageDTO saved = chatService.saveMessage(messageDTO);

        messagingTemplate.convertAndSend(
                "/topic/chat/" + saved.getConversationId(),
                saved
        );
        messagingTemplate.convertAndSend("/topic/staff/conversations", saved);

        return ResponseEntity.ok(saved);
    }

    /**
     * Lấy lịch sử tin nhắn của một conversation.
     * GET /api/chat/history/{conversationId}
     */
    @GetMapping("/chat/history/{conversationId}")
    public ResponseEntity<List<ChatMessageDTO>> getHistory(@PathVariable String conversationId) {
        return ResponseEntity.ok(chatService.getHistory(conversationId));
    }

    /**
     * Lấy tất cả conversations (Staff dashboard).
     * GET /api/chat/conversations?status=Open
     */
    @GetMapping("/chat/conversations")
    public ResponseEntity<List<ConversationDTO>> getAllConversations(
            @RequestParam(required = false) String status,
            Authentication authentication) {
        String staffId = resolveUserId(authentication.getName());
        if (status != null && !status.isBlank()) {
            return ResponseEntity.ok(chatService.getConversationsByStatus(status, staffId));
        }
        return ResponseEntity.ok(chatService.getAllConversations(staffId));
    }

    /**
     * Lấy danh sách conversations của customer đang đăng nhập.
     * GET /api/chat/conversations/my
     */
    @GetMapping("/chat/conversations/my")
    public ResponseEntity<List<ConversationDTO>> getMyConversations(Authentication authentication) {
        String customerId = resolveUserId(authentication.getName());
        return ResponseEntity.ok(chatService.getConversationsForCustomer(customerId));
    }

    /**
     * Customer tạo/lấy conversation (REST).
     * POST /api/chat/conversations/join
     */
    @PostMapping("/chat/conversations/join")
    public ResponseEntity<Map<String, String>> joinConversation(Authentication authentication) {
        String customerId = resolveUserId(authentication.getName());
        Conversation conv = chatService.getOrCreateConversation(customerId);
        return ResponseEntity.ok(Map.of(
                "conversationId", conv.getConversationId(),
                "status", conv.getStatus()
        ));
    }

    /**
     * Staff nhận một conversation.
     * PUT /api/chat/conversations/{conversationId}/assign
     */
    @PutMapping("/chat/conversations/{conversationId}/assign")
    public ResponseEntity<ConversationDTO> assignConversation(
            @PathVariable String conversationId,
            Authentication authentication) {
        String staffId = resolveUserId(authentication.getName());
        ConversationDTO result = chatService.assignStaff(conversationId, staffId);

        // Notify client trong conversation về việc staff vừa tham gia
        messagingTemplate.convertAndSend(
                "/topic/chat/" + conversationId,
                Map.of("event", "STAFF_JOINED", "conversationId", conversationId,
                        "staffId", staffId, "staffName", result.getStaffName() != null ? result.getStaffName() : "Nhân viên")
        );

        return ResponseEntity.ok(result);
    }

    /**
     * Đóng một conversation.
     * PUT /api/chat/conversations/{conversationId}/close
     */
    @PutMapping("/chat/conversations/{conversationId}/close")
    public ResponseEntity<ConversationDTO> closeConversation(@PathVariable String conversationId) {
        ConversationDTO result = chatService.closeConversation(conversationId);

        // Notify tất cả client trong conversation
        messagingTemplate.convertAndSend(
                "/topic/chat/" + conversationId,
                Map.of("event", "CONVERSATION_CLOSED", "conversationId", conversationId)
        );

        return ResponseEntity.ok(result);
    }

    /**
     * Đánh dấu đã đọc tin nhắn trong conversation.
     * POST /api/chat/conversations/{conversationId}/read
     */
    @PostMapping("/chat/conversations/{conversationId}/read")
    public ResponseEntity<Void> markAsRead(
            @PathVariable String conversationId,
            Authentication authentication) {
        String userId = resolveUserId(authentication.getName());
        chatService.markAsRead(conversationId, userId);
        return ResponseEntity.ok().build();
    }
}
