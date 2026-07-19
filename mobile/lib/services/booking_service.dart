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

  /// Lấy toàn bộ danh sách booking (Staff/Admin)
  Future<List<BookingModel>> getAllBookings() async {
    final response = await _dio.get('/bookings');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Cập nhật trạng thái booking
  Future<BookingModel> updateBookingStatus(int id, String status) async {
    final response = await _dio.put(
      '/bookings/$id/status',
      queryParameters: {'status': status},
    );
    return BookingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  /// Xóa booking
  Future<void> deleteBooking(int id) async {
    await _dio.delete('/bookings/$id');
  }

  /// Khách hàng hủy booking chưa thanh toán của chính mình
  Future<void> cancelCustomerBooking(int id) async {
    await _dio.delete('/bookings/customer/$id');
  }

  /// Cập nhật thông tin booking
  Future<BookingModel> updateBooking(int id, BookingModel booking) async {
    final response = await _dio.put('/bookings/$id', data: booking.toJson());
    return BookingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}
