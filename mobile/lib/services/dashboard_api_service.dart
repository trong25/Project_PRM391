// lib/services/dashboard_api_service.dart

import 'package:dio/dio.dart';

import '../models/dashboard_revenue_model.dart';
import 'api_client.dart';

class DashboardApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<RevenueOverview> getRevenueOverview() async {
    try {
      final response = await _dio.get('/dashboard/revenue/overview');
      if (response.data['success'] == true) {
        return RevenueOverview.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw Exception(response.data['message'] ?? 'Không tải được doanh thu');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Bạn không có quyền xem doanh thu. Vui lòng đăng nhập bằng tài khoản admin.');
      }

      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }
      throw Exception(e.message ?? 'Không tải được doanh thu');
    } catch (e) {
      throw Exception('Failed to load revenue overview: $e');
    }
  }

  Future<double> getTotalRevenue(String timeFrame) async {
    try {
      final response = await _dio.get(
        '/dashboard/revenue/total',
        queryParameters: {'timeFrame': timeFrame},
      );
      if (response.data['success'] == true) {
        return (response.data['data']['revenue'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      throw Exception('Failed to load total revenue: $e');
    }
  }

  Future<double> getHotelRevenue(String hotelId, String timeFrame) async {
    try {
      final response = await _dio.get(
        '/dashboard/revenue/hotel/$hotelId',
        queryParameters: {'timeFrame': timeFrame},
      );
      if (response.data['success'] == true) {
        return (response.data['data']['revenue'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      throw Exception('Failed to load hotel revenue: $e');
    }
  }
}
