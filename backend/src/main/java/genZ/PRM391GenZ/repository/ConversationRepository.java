package genZ.PRM391GenZ.repository;

import genZ.PRM391GenZ.entity.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, String> {

    // Tìm conversation theo customerId (mỗi customer có thể có nhiều conversation)
    List<Conversation> findByCustomerIdOrderByLastMessageAtDesc(String customerId);

    // Tìm conversation Open/Pending của một customer
    Optional<Conversation> findFirstByCustomerIdAndStatusOrderByCreatedAtDesc(
            String customerId, String status);

    // Lấy tất cả conversation, sắp theo tin nhắn mới nhất (cho Staff)
    List<Conversation> findAllByOrderByLastMessageAtDesc();

    // Lấy conversation theo status (Open, Pending, Closed)
    List<Conversation> findByStatusOrderByLastMessageAtDesc(String status);

    // Lấy conversation theo staffId
    List<Conversation> findByStaffIdOrderByLastMessageAtDesc(String staffId);

    // Đếm tin nhắn chưa đọc trong một conversation (gửi bởi customer)
    @Query("SELECT COUNT(m) FROM ChatMessage m WHERE m.conversationId = :convId AND m.isRead = false AND m.senderId != :staffId")
    long countUnreadForStaff(@Param("convId") String conversationId, @Param("staffId") String staffId);

    // Đếm tin nhắn chưa đọc gửi bởi staff (dành cho customer)
    @Query("SELECT COUNT(m) FROM ChatMessage m WHERE m.conversationId = :convId AND m.isRead = false AND m.senderId != :customerId")
    long countUnreadForCustomer(@Param("convId") String conversationId, @Param("customerId") String customerId);
}
