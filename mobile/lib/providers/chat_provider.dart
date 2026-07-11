// lib/providers/chat_provider.dart
// Provider quản lý state chat - cập nhật theo schema Conversation mới

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';
import '../services/chat_service.dart';

// ── Service Provider ───────────────────────────────────────────────────────
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// ── Chat State (Customer) ──────────────────────────────────────────────────
class ChatState {
  final List<ChatMessageModel> messages;
  final bool isConnected;
  final bool isLoading;
  final String? conversationId;
  final String? conversationStatus; // Open | Pending | Closed
  final String? staffName;          // tên staff đang phụ trách
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isConnected = false,
    this.isLoading = false,
    this.conversationId,
    this.conversationStatus,
    this.staffName,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isConnected,
    bool? isLoading,
    String? conversationId,
    String? conversationStatus,
    String? staffName,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages:           messages           ?? this.messages,
      isConnected:        isConnected        ?? this.isConnected,
      isLoading:          isLoading          ?? this.isLoading,
      conversationId:     conversationId     ?? this.conversationId,
      conversationStatus: conversationStatus ?? this.conversationStatus,
      staffName:          staffName          ?? this.staffName,
      error:              clearError ? null  : (error ?? this.error),
    );
  }
}

// ── Chat Notifier (Customer) ───────────────────────────────────────────────
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _service;
  StompUnsubscribe? _msgSub;
  StompUnsubscribe? _eventSub;

  ChatNotifier(this._service) : super(const ChatState());

  /// Kết nối và join conversation (dùng cho Customer)
  Future<void> connectAndJoin({
    required String token,
    required String customerId,
    required String customerName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Lấy conversationId qua REST
      final joinResult = await _service.joinConversationRest();
      final conversationId = joinResult['conversationId'] as String;
      final convStatus     = joinResult['status']         as String? ?? 'Open';

      // 2. Load lịch sử tin nhắn
      final history = await _service.getChatHistory(conversationId);

      state = state.copyWith(
        conversationId:     conversationId,
        conversationStatus: convStatus,
        messages:           history,
        isLoading:          false,
      );

      // 3. Kết nối WebSocket
      _service.connect(
        token: token,
        onConnected: (StompFrame frame) {
          state = state.copyWith(isConnected: true);

          // Subscribe tin nhắn thường
          _msgSub = _service.subscribeToConversation(
            conversationId: conversationId,
            onMessage:      _onMessageReceived,
          );

          // Subscribe events (staff join, closed, v.v.)
          _eventSub = _service.subscribeToConversationEvents(
            conversationId: conversationId,
            onEvent:        _onEvent,
          );
        },
        onError: (e) {
          state = state.copyWith(
            isConnected: false,
            error: 'Kết nối thất bại: $e',
          );
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _onMessageReceived(ChatMessageModel msg) {
    // Tránh duplicate nếu WS echo lại tin nhắn có id trùng
    final exists = state.messages.any((m) => m.id != null && m.id == msg.id);
    if (!exists) {
      state = state.copyWith(messages: [...state.messages, msg]);
    }
  }

  void _onEvent(Map<String, dynamic> event) {
    final type = event['event'] as String?;
    if (type == 'STAFF_JOINED') {
      state = state.copyWith(
        staffName:          event['staffName'] as String? ?? 'Nhân viên',
        conversationStatus: 'Pending',
      );
    } else if (type == 'CONVERSATION_CLOSED') {
      state = state.copyWith(conversationStatus: 'Closed');
    }
  }

  /// Gửi tin nhắn (qua REST để đảm bảo lưu DB)
  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String content,
    String messageType = 'TEXT',
  }) async {
    if (state.conversationId == null) {
      debugPrint('[ChatNotifier] sendMessage: conversationId is null, skip');
      return;
    }

    final msg = ChatMessageModel(
      conversationId: state.conversationId!,
      senderId:       senderId,
      senderName:     senderName,
      content:        content,
      messageType:    messageType,
      sentAt:         DateTime.now(),
    );

    try {
      final saved = await _service.sendMessageRest(msg);
      final exists = state.messages.any((m) => m.id != null && m.id == saved.id);
      if (!exists) {
        state = state.copyWith(messages: [...state.messages, saved], clearError: true);
      }
    } catch (e) {
      state = state.copyWith(error: 'Gửi tin nhắn thất bại: $e');
    }
  }

  @override
  void dispose() {
    _msgSub?.call();
    _eventSub?.call();
    // Không disconnect shared ChatService — staff có thể đang dùng cùng connection
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider.autoDispose<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.read(chatServiceProvider));
});

// ── Staff Conversations State ──────────────────────────────────────────────
class StaffRoomsState {
  final List<ConversationModel> rooms;
  final bool isLoading;
  final String? error;

  const StaffRoomsState({
    this.rooms = const [],
    this.isLoading = false,
    this.error,
  });

  StaffRoomsState copyWith({
    List<ConversationModel>? rooms,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return StaffRoomsState(
      rooms:     rooms     ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      error:     clearError ? null : (error ?? this.error),
    );
  }
}

class StaffRoomsNotifier extends StateNotifier<StaffRoomsState> {
  final ChatService _service;
  StompUnsubscribe? _convSub;

  StaffRoomsNotifier(this._service) : super(const StaffRoomsState());

  Future<void> loadAndSubscribe({required String token}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final conversations = await _service.getConversations();
      state = state.copyWith(rooms: conversations, isLoading: false);

      // Kết nối WS để nhận thông báo realtime
      _service.connect(
        token: token,
        onConnected: (_) {
          _convSub = _service.subscribeToStaffConversations(
            onUpdate: (_) => _refreshConversations(),
          );
        },
        onError: (_) {},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _refreshConversations() async {
    try {
      final conversations = await _service.getConversations();
      if (mounted) state = state.copyWith(rooms: conversations);
    } catch (_) {}
  }

  Future<void> refresh() => _refreshConversations();

  /// Staff nhận một conversation
  Future<void> assignConversation(String conversationId) async {
    try {
      await _service.assignConversation(conversationId);
      await _refreshConversations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Đóng một conversation
  Future<void> closeConversation(String conversationId) async {
    try {
      await _service.closeConversation(conversationId);
      await _refreshConversations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _convSub?.call();
    super.dispose();
  }
}

final staffRoomsProvider =
    StateNotifierProvider.autoDispose<StaffRoomsNotifier, StaffRoomsState>((ref) {
  return StaffRoomsNotifier(ref.read(chatServiceProvider));
});

// ── Staff Chat Detail State (per conversation) ─────────────────────────────
class StaffChatState {
  final List<ChatMessageModel> messages;
  final bool isConnected;
  final bool isLoading;
  final String? conversationStatus;
  final String? error;

  const StaffChatState({
    this.messages = const [],
    this.isConnected = false,
    this.isLoading = true,
    this.conversationStatus,
    this.error,
  });

  StaffChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isConnected,
    bool? isLoading,
    String? conversationStatus,
    String? error,
    bool clearError = false,
  }) {
    return StaffChatState(
      messages:           messages           ?? this.messages,
      isConnected:        isConnected        ?? this.isConnected,
      isLoading:          isLoading          ?? this.isLoading,
      conversationStatus: conversationStatus ?? this.conversationStatus,
      error:              clearError ? null  : (error ?? this.error),
    );
  }
}
