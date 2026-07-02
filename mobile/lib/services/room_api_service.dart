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
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không tải được danh sách phòng'));
    } catch (e) {
      throw Exception('Không tải được danh sách phòng: $e');
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
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không tải được phòng theo chi nhánh'));
    } catch (e) {
      throw Exception('Không tải được phòng theo chi nhánh: $e');
    }
  }

  Future<RoomModel> createRoom(RoomModel room) async {
    try {
      final response = await _dio.post('/rooms', data: room.toJson());
      if (response.data['success'] == true) {
        return RoomModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không tạo được phòng'));
    } catch (e) {
      throw Exception('Không tạo được phòng: $e');
    }
  }

  Future<RoomModel> updateRoom(String id, RoomModel room) async {
    try {
      final response = await _dio.put('/rooms/$id', data: room.toJson());
      if (response.data['success'] == true) {
        return RoomModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không cập nhật được phòng'));
    } catch (e) {
      throw Exception('Không cập nhật được phòng: $e');
    }
  }

  Future<void> deleteRoom(String id) async {
    try {
      await _dio.delete('/rooms/$id');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không xóa được phòng'));
    } catch (e) {
      throw Exception('Không xóa được phòng: $e');
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

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallback;
  }
}
