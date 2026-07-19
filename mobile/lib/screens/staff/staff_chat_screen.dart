// lib/screens/staff/staff_chat_screen.dart
// Màn hình chat chi tiết cho Nhân viên — dùng Conversation mới

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/chat_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';

class StaffChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String customerName;
  final String initialStatus;

  const StaffChatScreen({
    super.key,
    required this.conversationId,
    required this.customerName,
    this.initialStatus = 'Open',
  });

  @override
  ConsumerState<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends ConsumerState<StaffChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final ChatService _chatService;
  final List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  String _status = '';
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _chatService = ref.read(chatServiceProvider);
    _init();
  }

  Future<void> _init() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    try {
      // Load lịch sử tin nhắn
      final history = await _chatService.getChatHistory(widget.conversationId);
      // Đánh dấu đã đọc
      await _chatService.markAsRead(widget.conversationId);

      if (mounted) {
        setState(() {
          _messages.addAll(history);
          _isLoading = false;
        });
        _scrollToBottom();
      }

      // Kết nối WebSocket
      _chatService.connect(
        token: user.token,
        onConnected: (frame) {
          // Subscribe tin nhắn thường
          _chatService.subscribeToConversation(
            conversationId: widget.conversationId,
            onMessage: (msg) {
              if (mounted) {
                final exists = _messages.any((m) => m.id != null && m.id == msg.id);
                if (!exists) {
                  setState(() => _messages.add(msg));
                  _scrollToBottom();
                }
              }
            },
          );

          // Subscribe events
          _chatService.subscribeToConversationEvents(
            conversationId: widget.conversationId,
            onEvent: (event) {
              if (!mounted) return;
              final type = event['event'] as String?;
              if (type == 'CONVERSATION_CLOSED') {
                setState(() => _status = 'Closed');
              }
            },
          );
        },
        onError: (_) {
          // Connection error - không cần track state _isConnected riêng
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    final msg = ChatMessageModel(
      conversationId: widget.conversationId,
      senderId:       user.userId,
      senderName:     user.fullName,
      content:        text,
      messageType:    'TEXT',
      sentAt:         DateTime.now(),
    );

    _textController.clear();

    try {
      final saved = await _chatService.sendMessageRest(msg);
      if (mounted) {
        final exists = _messages.any((m) => m.id != null && m.id == saved.id);
        if (!exists) {
          setState(() => _messages.add(saved));
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi tin nhắn thất bại: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _assignSelf() async {
    if (_isAssigning) return;
    setState(() => _isAssigning = true);
    try {
      final updated = await _chatService.assignConversation(widget.conversationId);
      if (!mounted) return;
      // Dùng status trả về từ server để đảm bảo UI cập nhật đúng
      setState(() {
        _status = updated.status.isNotEmpty ? updated.status : 'Pending';
        _isAssigning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã nhận cuộc trò chuyện này.'),
          backgroundColor: Colors.green,
        ),
      );
      // Làm mới danh sách conversations của staff
      ref.read(staffRoomsProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAssigning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _status == 'Open';

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          // Action bar (Nhận)
          if (isOpen) _buildActionBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (_status) {
      case 'Open':    statusColor = Colors.orange;       statusText = 'Chờ tiếp nhận'; break;
      case 'Pending': statusColor = Colors.greenAccent;  statusText = 'Đang xử lý';    break;
      case 'Closed':  statusColor = Colors.grey;         statusText = 'Đã đóng';       break;
      default:        statusColor = Colors.grey;         statusText = _status;
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Text(
                  widget.customerName.isNotEmpty
                      ? widget.customerName[0].toUpperCase()
                      : 'K',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Chưa có nhân viên tiếp nhận',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isAssigning ? null : _assignSelf,
            icon: _isAssigning
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.pan_tool_alt, size: 16),
            label: const Text('Nhận', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMessageList() {
    final user = ref.read(authProvider).user;
    String? lastDateLabel;

    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có tin nhắn nào trong cuộc trò chuyện này.',
          style: TextStyle(color: AppTheme.textGray),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.senderId == user?.userId;

        if (msg.messageType == 'SYSTEM') {
          return _buildSystemMessage(msg.content);
        }

        final dateLabel = msg.sentAt != null
            ? DateFormat('EEE d/M', 'vi').format(msg.sentAt!)
            : null;
        final showDateLabel = dateLabel != null && dateLabel != lastDateLabel;
        if (showDateLabel) lastDateLabel = dateLabel;

        return Column(
          children: [
            if (showDateLabel) _buildDateLabel(msg.sentAt!),
            _buildBubble(msg, isMe),
          ],
        );
      },
    );
  }

  Widget _buildSystemMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildDateLabel(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        DateFormat('EEE d/M HH:mm', 'vi').format(dt),
        style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
      ),
    );
  }

  Widget _buildBubble(ChatMessageModel msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.surface,
              child: Text(
                widget.customerName.isNotEmpty
                    ? widget.customerName[0].toUpperCase()
                    : 'K',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppTheme.primaryGradient : null,
                    color: isMe ? null : const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                if (msg.sentAt != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(msg.sentAt!),
                        style: const TextStyle(color: AppTheme.textGray, fontSize: 10),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: msg.isRead ? AppTheme.primary : AppTheme.textGray,
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: const TextStyle(color: AppTheme.textGray),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
