// lib/screens/customer/feedback_chat_screen.dart
// Màn hình chat cho Khách hàng — kết nối với Conversation mới

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/chat_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class FeedbackChatScreen extends ConsumerStatefulWidget {
  const FeedbackChatScreen({super.key});

  @override
  ConsumerState<FeedbackChatScreen> createState() => _FeedbackChatScreenState();
}

class _FeedbackChatScreenState extends ConsumerState<FeedbackChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    await ref.read(chatProvider.notifier).connectAndJoin(
      token:        user.token,
      customerId:   user.userId,
      customerName: user.fullName,
    );
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

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    final chatState = ref.read(chatProvider);
    if (chatState.conversationStatus == 'Closed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuộc trò chuyện đã đóng. Không thể gửi thêm tin nhắn.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (chatState.conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm được cuộc hội thoại. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(chatProvider.notifier).sendMessage(
      senderId:   user.userId,
      senderName: user.fullName,
      content:    text,
    );

    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    if (chatState.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, chatState),
          // Status banner (nếu có staff phụ trách hoặc đã đóng)
          if (chatState.conversationStatus == 'Closed')
            _buildStatusBanner(
              'Cuộc trò chuyện đã kết thúc',
              Colors.grey.shade700,
              Icons.lock_outline,
            )
          else if (chatState.conversationStatus == 'Pending' && chatState.staffName != null)
            _buildStatusBanner(
              '${chatState.staffName} đang hỗ trợ bạn',
              AppTheme.primary,
              Icons.support_agent,
            ),
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(chatState.messages, chatState),
          ),
          if (chatState.conversationStatus != 'Closed') _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, ChatState chatState) {
    final isClosed = chatState.conversationStatus == 'Closed';
    final hasPending = chatState.conversationStatus == 'Pending';

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
                child: Icon(
                  hasPending ? Icons.support_agent : Icons.headset_mic_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dịch vụ khách hàng',
                      style: TextStyle(
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
                            color: isClosed
                                ? Colors.grey
                                : (chatState.isConnected ? Colors.greenAccent : Colors.orange),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isClosed
                              ? 'Đã đóng'
                              : (chatState.isConnected ? 'Đang kết nối' : 'Đang kết nối...'),
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

  Widget _buildStatusBanner(String text, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Message List ────────────────────────────────────────────────────────────
  Widget _buildMessageList(List<ChatMessageModel> messages, ChatState chatState) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Gửi tin nhắn để bắt đầu!\nChúng tôi sẽ phản hồi sớm nhất có thể.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGray, height: 1.5),
            ),
          ],
        ),
      );
    }

    final user = ref.read(authProvider).user;
    String? lastDateLabel;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isMe = msg.senderId == user?.userId;
        final dateLabel = msg.sentAt != null
            ? DateFormat('EEEE d/M', 'vi').format(msg.sentAt!)
            : null;
        final showDateLabel = dateLabel != null && dateLabel != lastDateLabel;
        if (showDateLabel) lastDateLabel = dateLabel;

        // SYSTEM message (ví dụ staff joined)
        if (msg.messageType == 'SYSTEM') {
          return _buildSystemMessage(msg.content);
        }

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
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
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
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.surface,
              child: Icon(Icons.support_agent, size: 18, color: AppTheme.primary),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (msg.sentAt != null)
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

  // ── Input Bar ───────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    final chatState = ref.watch(chatProvider);
    final hasConversation = chatState.conversationId != null;
    final canSend = hasConversation && chatState.conversationStatus != 'Closed';

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
                enabled: canSend,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: canSend ? 'Nhập tin nhắn...' : 'Đang tải cuộc hội thoại...',
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
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: canSend ? _sendMessage : null,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: canSend ? AppTheme.primaryGradient : null,
                  color: canSend ? null : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: canSend ? Colors.white : Colors.grey.shade500,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
