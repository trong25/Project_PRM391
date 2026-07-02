// lib/providers/room_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────
final roomServiceProvider = Provider<RoomService>((_) => RoomService());

// ── State: danh sách phòng ────────────────────────────────────────────────────
class RoomListState {
  final List<RoomModel> rooms;
  final bool isLoading;
  final String? error;

  const RoomListState({
    this.rooms = const [],
    this.isLoading = false,
    this.error,
  });

  RoomListState copyWith({
    List<RoomModel>? rooms,
    bool? isLoading,
    String? error,
  }) =>
      RoomListState(
        rooms: rooms ?? this.rooms,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class RoomListNotifier extends StateNotifier<RoomListState> {
  RoomListNotifier(this._service) : super(const RoomListState(isLoading: true)) {
    loadRooms();
  }

  final RoomService _service;

  Future<void> loadRooms() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rooms = await _service.getAllRooms();
      state = state.copyWith(rooms: rooms, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Lọc theo loại phòng
  void filterByType(String? typeRoomId) {
    // TODO: gọi API hoặc filter local
  }
}

final roomListProvider =
    StateNotifierProvider<RoomListNotifier, RoomListState>((ref) {
  return RoomListNotifier(ref.read(roomServiceProvider));
});

// ── State: chi tiết phòng ─────────────────────────────────────────────────────
class RoomDetailState {
  final RoomModel? room;
  final bool isLoading;
  final String? error;

  const RoomDetailState({this.room, this.isLoading = false, this.error});

  RoomDetailState copyWith({
    RoomModel? room,
    bool? isLoading,
    String? error,
  }) =>
      RoomDetailState(
        room: room ?? this.room,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class RoomDetailNotifier extends StateNotifier<RoomDetailState> {
  RoomDetailNotifier(this._service) : super(const RoomDetailState());

  final RoomService _service;

  Future<void> loadRoom(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final room = await _service.getRoomById(id);
      state = state.copyWith(room: room, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final roomDetailProvider =
    StateNotifierProvider.family<RoomDetailNotifier, RoomDetailState, String>(
        (ref, roomId) {
  final notifier = RoomDetailNotifier(ref.read(roomServiceProvider));
  // Auto-load khi provider được tạo
  Future.microtask(() => notifier.loadRoom(roomId));
  return notifier;
});
