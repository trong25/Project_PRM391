package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    // Lấy toàn bộ tin nhắn của một conversation, sắp theo thời gian gửi
    List<ChatMessage> findByConversationIdOrderBySentAtAsc(String conversationId);

    // Đánh dấu tất cả tin nhắn trong conversation là đã đọc (loại trừ tin của chính user đó)
    @Modifying
    @Transactional
    @Query("UPDATE ChatMessage m SET m.isRead = true WHERE m.conversationId = :convId AND m.senderId != :userId")
    int markAllAsRead(@Param("convId") String conversationId, @Param("userId") String userId);

    // Đếm tin nhắn chưa đọc trong conversation gửi bởi người khác
    @Query("SELECT COUNT(m) FROM ChatMessage m WHERE m.conversationId = :convId AND m.isRead = false AND m.senderId != :userId")
    long countUnread(@Param("convId") String conversationId, @Param("userId") String userId);
}

