// lib/services/dashboard_api_service.dart

import 'package:dio/dio.dart';
import 'api_client.dart';

class DashboardApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<double> getTotalRevenue(String timeFrame) async {
    try {
      final response = await _dio.get('/dashboard/revenue/total', queryParameters: {'timeFrame': timeFrame});
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
      final response = await _dio.get('/dashboard/revenue/hotel/$hotelId', queryParameters: {'timeFrame': timeFrame});
      if (response.data['success'] == true) {
        return (response.data['data']['revenue'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      throw Exception('Failed to load hotel revenue: $e');
    }
  }
}
