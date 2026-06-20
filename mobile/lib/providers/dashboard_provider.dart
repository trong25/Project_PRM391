// lib/providers/dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_revenue_model.dart';
import '../services/dashboard_api_service.dart';

final dashboardApiProvider = Provider<DashboardApiService>((ref) => DashboardApiService());

final revenueOverviewProvider = FutureProvider<RevenueOverview>((ref) async {
  final api = ref.watch(dashboardApiProvider);
  return api.getRevenueOverview();
});

// Tham số truyền vào dạng: (hotelId, timeFrame). Nếu hotelId = 'all', lấy tổng.
final revenueProvider = FutureProvider.family<double, Map<String, String>>((ref, params) async {
  final api = ref.watch(dashboardApiProvider);
  final hotelId = params['hotelId'];
  final timeFrame = params['timeFrame'] ?? 'month';
  
  if (hotelId == null || hotelId == 'all') {
    return api.getTotalRevenue(timeFrame);
  } else {
    return api.getHotelRevenue(hotelId, timeFrame);
  }
});
