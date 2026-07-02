// lib/services/room_service.dart

import 'package:dio/dio.dart';
import '../models/room_model.dart';
import 'api_client.dart';

class RoomService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<RoomModel>> getAllRooms() async {
    final response = await _dio.get('/rooms');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RoomModel> getRoomById(String id) async {
    final response = await _dio.get('/rooms/$id');
    return RoomModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<RoomModel>> getAvailableRooms() async {
    final response = await _dio.get('/rooms/available');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
