// lib/services/room_api_service.dart

import 'package:dio/dio.dart';
import '../models/room_model.dart';
import 'api_client.dart';

class RoomApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<RoomModel>> getAllRooms() async {
    try {
      final response = await _dio.get('/rooms');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => RoomModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load rooms: $e');
    }
  }

  Future<List<RoomModel>> getRoomsByHotel(String hotelId) async {
    try {
      final response = await _dio.get('/rooms/hotel/$hotelId');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => RoomModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load rooms: $e');
    }
  }

  Future<RoomModel> createRoom(RoomModel room) async {
    try {
      final response = await _dio.post('/rooms', data: room.toJson());
      if (response.data['success'] == true) {
        return RoomModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  Future<RoomModel> updateRoom(String id, RoomModel room) async {
    try {
      final response = await _dio.put('/rooms/$id', data: room.toJson());
      if (response.data['success'] == true) {
        return RoomModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  Future<void> deleteRoom(String id) async {
    try {
      await _dio.delete('/rooms/$id');
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }

  // Lấy danh mục
  Future<List<HotelModel>> getHotels() async {
    try {
      final response = await _dio.get('/hotels');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => HotelModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<TypeRoomModel>> getTypeRooms() async {
    try {
      final response = await _dio.get('/type-rooms');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => TypeRoomModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
