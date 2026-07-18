// lib/services/chat_service.dart
// Service xử lý WebSocket (STOMP) + REST API cho chat
// Đã cập nhật theo schema mới: dùng conversationId thay roomId

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/app_config.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';
import 'api_client.dart';

class ChatService {
  StompClient? _stompClient;
  bool _connected = false;

  // ── WebSocket URL ──────────────────────────────────────────────────────────
  // Phải khớp context-path /api của backend: ws://host:8080/api/ws
  static String get wsUrl {
    final base = Uri.parse(AppConfig.baseUrl);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    final path = base.path.endsWith('/') ? '${base.path}ws' : '${base.path}/ws';
    return '$wsScheme://${base.host}:${base.port}$path';
  }

  bool get isConnected => _connected;

  /// Kết nối tới WebSocket server
  void connect({
    required String token,
    required void Function(StompFrame) onConnected,
    required void Function(dynamic) onError,
  }) {
    if (_connected && _stompClient != null) {
      // Đã kết nối: chỉ gọi lại callback để subscribe
      onConnected(StompFrame(command: 'CONNECTED', headers: {}));
      return;
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (frame) {
          _connected = true;
          onConnected(frame);
          debugPrint('[ChatService] Connected to WebSocket');
        },
        onDisconnect: (_) {
          _connected = false;
          debugPrint('[ChatService] Disconnected from WebSocket');
        },
        onStompError: (frame) {
          _connected = false;
          onError(frame);
          debugPrint('[ChatService] STOMP error: ${frame.body}');
        },
        onWebSocketError: (error) {
          _connected = false;
          onError(error);
          debugPrint('[ChatService] WebSocket error: $error');
        },
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _stompClient!.activate();
  }

  /// Ngắt kết nối
  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    _connected = false;
  }

  /// Subscribe lắng nghe tin nhắn trong một conversation
  StompUnsubscribe? subscribeToConversation({
    required String conversationId,
    required void Function(ChatMessageModel) onMessage,
  }) {
    return _stompClient?.subscribe(
      destination: '/topic/chat/$conversationId',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          // Bỏ qua event (STAFF_JOINED, CONVERSATION_CLOSED, v.v.)
          if (data.containsKey('event')) return;
          onMessage(ChatMessageModel.fromJson(data));
        }
      },
    );
  }

  /// Subscribe lắng nghe event trong conversation (STAFF_JOINED, CLOSED)
  StompUnsubscribe? subscribeToConversationEvents({
    required String conversationId,
    required void Function(Map<String, dynamic>) onEvent,
  }) {
    return _stompClient?.subscribe(
      destination: '/topic/chat/$conversationId',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          if (data.containsKey('event')) {
            onEvent(data);
          }
        }
      },
    );
  }

  /// Subscribe nhận thông báo mới của Staff (danh sách conversations)
  StompUnsubscribe? subscribeToStaffConversations({
    required void Function(dynamic) onUpdate,
  }) {
    return _stompClient?.subscribe(
      destination: '/topic/staff/conversations',
      callback: (frame) {
        if (frame.body != null) {
          onUpdate(jsonDecode(frame.body!));
        }
      },
    );
  }

  /// Subscribe nhận conversationId sau khi join (dành cho Customer)
  StompUnsubscribe? subscribeToJoin({
    required String customerId,
    required void Function(String conversationId) onJoined,
  }) {
    return _stompClient?.subscribe(
      destination: '/topic/chat/join/$customerId',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          onJoined(data['conversationId'] as String);
        }
      },
    );
  }

  /// Gửi tin nhắn qua REST (lưu DB + broadcast realtime)
  Future<ChatMessageModel> sendMessageRest(ChatMessageModel message) async {
    final response = await ApiClient.instance.dio.post(
      '/chat/messages',
      data: message.toJson(),
    );
    return ChatMessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Gửi tin nhắn qua WebSocket (legacy — ưu tiên dùng sendMessageRest)
  void sendMessage(ChatMessageModel message) {
    _stompClient?.send(
      destination: '/app/chat.send',
      body: jsonEncode(message.toJson()),
    );
  }

  /// Customer join conversation qua WebSocket
  void joinConversation({required String customerId}) {
    _stompClient?.send(
      destination: '/app/chat.join',
      body: jsonEncode({'customerId': customerId}),
    );
  }

  // ── REST API ───────────────────────────────────────────────────────────────

  /// Customer lấy/tạo conversation (REST)
  /// Trả về {conversationId, status}
  Future<Map<String, dynamic>> joinConversationRest() async {
    final response = await ApiClient.instance.dio.post('/chat/conversations/join');
    return response.data as Map<String, dynamic>;
  }

  /// Lấy lịch sử tin nhắn của một conversation
  Future<List<ChatMessageModel>> getChatHistory(String conversationId) async {
    final response = await ApiClient.instance.dio.get('/chat/history/$conversationId');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy danh sách conversations (Staff)
  Future<List<ConversationModel>> getConversations({String? status}) async {
    final params = status != null ? {'status': status} : null;
    final response = await ApiClient.instance.dio.get(
      '/chat/conversations',
      queryParameters: params,
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy conversations của customer đang đăng nhập
  Future<List<ConversationModel>> getMyConversations() async {
    final response = await ApiClient.instance.dio.get('/chat/conversations/my');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Staff nhận conversation
  Future<ConversationModel> assignConversation(String conversationId) async {
    final response = await ApiClient.instance.dio.put(
      '/chat/conversations/$conversationId/assign',
    );
    return ConversationModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Đóng conversation
  Future<ConversationModel> closeConversation(String conversationId) async {
    final response = await ApiClient.instance.dio.put(
      '/chat/conversations/$conversationId/close',
    );
    return ConversationModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Đánh dấu đã đọc
  Future<void> markAsRead(String conversationId) async {
    await ApiClient.instance.dio.post('/chat/conversations/$conversationId/read');
  }
}
