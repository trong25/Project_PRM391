// lib/services/discount_code_service.dart

import 'package:dio/dio.dart';
import '../models/discount_code_model.dart';
import 'api_client.dart';

class DiscountCodeService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<DiscountCodeModel>> getActiveDiscountCodes() async {
    // Use the same endpoint as the customer voucher screen. Vouchers created
    // by staff through /discount are stored in and returned from this source.
    final response = await _dio.get('/discount/active');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => DiscountCodeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DiscountCodeModel>> getAllDiscountCodes() async {
    final response = await _dio.get('/discount-codes');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => DiscountCodeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
