// lib/models/chat_message_model.dart
// Model cho tin nhắn trong Conversation (schema mới)

class ChatMessageModel {
  final int? id;

  /// ID của Conversation (thay roomId cũ)
  final String conversationId;

  final String senderId;
  final String senderName;

  /// Người nhận (optional)
  final String? receiverId;

  final String content;

  /// TEXT, IMAGE, FILE, SYSTEM
  final String messageType;

  /// URL ảnh/file đính kèm
  final String? attachmentUrl;

  /// Thời gian gửi (thay timestamp cũ)
  final DateTime? sentAt;

  /// Đã đọc hay chưa
  final bool isRead;

  const ChatMessageModel({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.receiverId,
    required this.content,
    this.messageType = 'TEXT',
    this.attachmentUrl,
    this.sentAt,
    this.isRead = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id:             json['id'] as int?,
      conversationId: json['conversationId'] as String? ?? '',
      senderId:       json['senderId']       as String? ?? '',
      senderName:     json['senderName']     as String? ?? '',
      receiverId:     json['receiverId']     as String?,
      content:        json['content']        as String? ?? '',
      messageType:    json['messageType']    as String? ?? 'TEXT',
      attachmentUrl:  json['attachmentUrl']  as String?,
      sentAt:         json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString())
          : null,
      isRead:         (json['isRead'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'conversationId': conversationId,
    'senderId':       senderId,
    'senderName':     senderName,
    if (receiverId != null) 'receiverId': receiverId,
    'content':        content,
    'messageType':    messageType,
    if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
    if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
    'isRead':         isRead,
  };
}
