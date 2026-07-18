// lib/models/chat_room_model.dart
// Model cho Conversation (phiên chat giữa Customer và Staff)
// Đổi tên class thành ConversationModel để khớp với schema mới,
// giữ nguyên tên file để không phá import ở các nơi khác.

class ConversationModel {
  final String conversationId;
  final String customerId;
  final String customerName;

  /// Staff đang phụ trách (null = chưa ai nhận)
  final String? staffId;
  final String? staffName;

  /// Open | Pending | Closed
  final String status;

  final DateTime? createdAt;
  final DateTime? lastMessageAt;

  /// Số tin nhắn chưa đọc (tính theo user hiện tại)
  final int unreadCount;

  /// Preview tin nhắn cuối
  final String lastMessagePreview;

  const ConversationModel({
    required this.conversationId,
    required this.customerId,
    required this.customerName,
    this.staffId,
    this.staffName,
    this.status = 'Open',
    this.createdAt,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.lastMessagePreview = '',
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversationId:     json['conversationId']     as String? ?? '',
      customerId:         json['customerId']          as String? ?? '',
      customerName:       json['customerName']        as String? ?? 'Khách hàng',
      staffId:            json['staffId']             as String?,
      staffName:          json['staffName']           as String?,
      status:             json['status']              as String? ?? 'Open',
      createdAt:          json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      lastMessageAt:      json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      unreadCount:        (json['unreadCount'] as int?) ?? 0,
      lastMessagePreview: json['lastMessagePreview']  as String? ?? '',
    );
  }

  // Getter tiện lợi: chưa có staff phụ trách
  bool get isUnassigned => staffId == null || staffId!.isEmpty;

  // Getter tiện lợi: conversation đang mở (chưa đóng)
  bool get isActive => status != 'Closed';
}

/// Backward-compat alias (nếu còn code cũ dùng ChatRoomModel)
typedef ChatRoomModel = ConversationModel;
