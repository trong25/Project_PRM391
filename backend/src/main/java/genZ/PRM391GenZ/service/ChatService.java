package genZ.PRM391GenZ.service;

import genZ.PRM391GenZ.dto.ChatMessageDTO;
import genZ.PRM391GenZ.dto.ConversationDTO;
import genZ.PRM391GenZ.entity.ChatMessage;
import genZ.PRM391GenZ.entity.Conversation;
import genZ.PRM391GenZ.repository.ChatMessageRepository;
import genZ.PRM391GenZ.repository.ConversationRepository;
import genZ.PRM391GenZ.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatMessageRepository messageRepository;
    private final ConversationRepository conversationRepository;
    private final UserRepository userRepository;

    // ─────────────────────────────────────────────────────────────────────────
    // Conversation Management
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Lấy hoặc tạo mới Conversation cho customer.
     * Nếu customer đã có conversation Open/Pending thì trả về cái đó.
     * Nếu không tạo conversation mới.
     */
    @Transactional
    public Conversation getOrCreateConversation(String customerId) {
        // Ưu tiên lấy conversation đang Open
        return conversationRepository
                .findFirstByCustomerIdAndStatusOrderByCreatedAtDesc(customerId, "Open")
                .orElseGet(() -> {
                    // Thử lấy Pending
                    return conversationRepository
                            .findFirstByCustomerIdAndStatusOrderByCreatedAtDesc(customerId, "Pending")
                            .orElseGet(() -> {
                                // Tạo mới
                                Conversation newConv = Conversation.builder()
                                        .conversationId("CONV_" + UUID.randomUUID().toString().replace("-", "").substring(0, 20))
                                        .customerId(customerId)
                                        .status("Open")
                                        .createdAt(LocalDateTime.now())
                                        .build();
                                return conversationRepository.save(newConv);
                            });
                });
    }

    /**
     * Staff nhận một conversation (assign).
     */
    @Transactional
    public ConversationDTO assignStaff(String conversationId, String staffId) {
        Conversation conv = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new RuntimeException("Conversation không tồn tại: " + conversationId));
        conv.setStaffId(staffId);
        conv.setStatus("Pending");
        conversationRepository.save(conv);
        return toConversationDTO(conv, staffId);
    }

    /**
     * Đóng một conversation.
     */
    @Transactional
    public ConversationDTO closeConversation(String conversationId) {
        Conversation conv = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new RuntimeException("Conversation không tồn tại: " + conversationId));
        conv.setStatus("Closed");
        conversationRepository.save(conv);
        return toConversationDTO(conv, conv.getStaffId());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Message
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Lưu tin nhắn vào DB và cập nhật lastMessageAt trên Conversation.
     */
    @Transactional
    public ChatMessageDTO saveMessage(ChatMessageDTO dto) {
        ChatMessage message = ChatMessage.builder()
                .conversationId(dto.getConversationId())
                .senderId(dto.getSenderId())
                .senderName(dto.getSenderName())
                .receiverId(dto.getReceiverId())
                .content(dto.getContent())
                .messageType(dto.getMessageType() != null ? dto.getMessageType() : "TEXT")
                .attachmentUrl(dto.getAttachmentUrl())
                .sentAt(LocalDateTime.now())
                .isRead(false)
                .build();

        ChatMessage saved = messageRepository.save(message);

        // Cập nhật lastMessageAt trên Conversation
        conversationRepository.findById(dto.getConversationId()).ifPresent(conv -> {
            conv.setLastMessageAt(saved.getSentAt());
            conversationRepository.save(conv);
        });

        return toMessageDTO(saved);
    }

    /**
     * Lấy lịch sử tin nhắn của một conversation.
     */
    public List<ChatMessageDTO> getHistory(String conversationId) {
        return messageRepository.findByConversationIdOrderBySentAtAsc(conversationId)
                .stream()
                .map(this::toMessageDTO)
                .collect(Collectors.toList());
    }

    /**
     * Đánh dấu đã đọc tất cả tin nhắn trong conversation (của người khác gửi).
     */
    @Transactional
    public void markAsRead(String conversationId, String userId) {
        messageRepository.markAllAsRead(conversationId, userId);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Queries for UI
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Lấy tất cả conversations (cho Staff dashboard).
     * Tính unreadCount theo staffId (nếu staffId null thì tính 0).
     */
    public List<ConversationDTO> getAllConversations(String staffId) {
        return conversationRepository.findAllByOrderByLastMessageAtDesc()
                .stream()
                .map(c -> toConversationDTO(c, staffId))
                .collect(Collectors.toList());
    }

    /**
     * Lấy conversations theo status.
     */
    public List<ConversationDTO> getConversationsByStatus(String status, String staffId) {
        return conversationRepository.findByStatusOrderByLastMessageAtDesc(status)
                .stream()
                .map(c -> toConversationDTO(c, staffId))
                .collect(Collectors.toList());
    }

    /**
     * Lấy conversation của một customer cụ thể.
     */
    public List<ConversationDTO> getConversationsForCustomer(String customerId) {
        return conversationRepository.findByCustomerIdOrderByLastMessageAtDesc(customerId)
                .stream()
                .map(c -> toConversationDTO(c, customerId))
                .collect(Collectors.toList());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Mapping Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private ChatMessageDTO toMessageDTO(ChatMessage msg) {
        return ChatMessageDTO.builder()
                .id(msg.getId())
                .conversationId(msg.getConversationId())
                .senderId(msg.getSenderId())
                .senderName(msg.getSenderName())
                .receiverId(msg.getReceiverId())
                .content(msg.getContent())
                .messageType(msg.getMessageType())
                .attachmentUrl(msg.getAttachmentUrl())
                .sentAt(msg.getSentAt() != null ? msg.getSentAt().toString() : null)
                .isRead(msg.isRead())
                .build();
    }

    private ConversationDTO toConversationDTO(Conversation conv, String currentUserId) {
        // Lấy tên customer
        String customerName = userRepository.findById(conv.getCustomerId())
                .map(u -> u.getFullName())
                .orElse("Khách hàng");

        // Lấy tên staff (nếu có)
        String staffName = null;
        if (conv.getStaffId() != null) {
            staffName = userRepository.findById(conv.getStaffId())
                    .map(u -> u.getFullName())
                    .orElse("Nhân viên");
        }

        // Lấy tin nhắn cuối để preview
        List<ChatMessage> messages = messageRepository
                .findByConversationIdOrderBySentAtAsc(conv.getConversationId());
        String lastPreview = messages.isEmpty() ? "" : messages.get(messages.size() - 1).getContent();

        // Đếm unread
        long unread = 0;
        if (currentUserId != null && !currentUserId.isBlank()) {
            unread = messageRepository.countUnread(conv.getConversationId(), currentUserId);
        }

        return ConversationDTO.builder()
                .conversationId(conv.getConversationId())
                .customerId(conv.getCustomerId())
                .customerName(customerName)
                .staffId(conv.getStaffId())
                .staffName(staffName)
                .status(conv.getStatus())
                .createdAt(conv.getCreatedAt() != null ? conv.getCreatedAt().toString() : null)
                .lastMessageAt(conv.getLastMessageAt() != null ? conv.getLastMessageAt().toString() : null)
                .unreadCount(unread)
                .lastMessagePreview(lastPreview)
                .build();
    }
}
