// lib/providers/room_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';
import '../models/category_models.dart';
import '../services/room_api_service.dart';

final roomApiProvider = Provider<RoomApiService>((ref) => RoomApiService());

final roomsProvider = FutureProvider.family<List<RoomModel>, String?>((ref, hotelId) async {
  final api = ref.watch(roomApiProvider);
  if (hotelId != null && hotelId.isNotEmpty) {
    return api.getRoomsByHotel(hotelId);
  }
  return api.getAllRooms();
});

final hotelsProvider = FutureProvider<List<HotelModel>>((ref) async {
  final api = ref.watch(roomApiProvider);
  return api.getHotels();
});

final typeRoomsProvider = FutureProvider<List<TypeRoomModel>>((ref) async {
  final api = ref.watch(roomApiProvider);
  return api.getTypeRooms();
});
