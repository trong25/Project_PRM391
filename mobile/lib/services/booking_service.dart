// lib/services/booking_service.dart

import 'package:dio/dio.dart';
import '../models/booking_model.dart';
import 'api_client.dart';

class BookingService {
  final Dio _dio = ApiClient.instance.dio;

  /// Tạo booking mới
  Future<BookingModel> createBooking(BookingModel booking) async {
    final response = await _dio.post('/bookings', data: booking.toJson());
    return BookingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Lấy danh sách booking theo userId
  Future<List<BookingModel>> getBookingsByUser(String userId) async {
    final response = await _dio.get('/bookings/user/$userId');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy chi tiết 1 booking
  Future<BookingModel> getBookingById(int id) async {
    final response = await _dio.get('/bookings/$id');
    return BookingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
