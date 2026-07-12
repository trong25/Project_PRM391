import 'package:dio/dio.dart';
import 'api_client.dart';

class DiscountService {
  final Dio _dio = ApiClient.instance.dio;

  ///=========================
  /// STAFF
  ///=========================

  /// Lấy tất cả voucher
  Future<List<dynamic>> getDiscounts() async {
    try {
      final response = await _dio.get('/discount');
      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data.toString() ?? "Không lấy được danh sách voucher");
    }
  }

  ///=========================
  /// CUSTOMER
  ///=========================

  /// Chỉ lấy voucher Active
  Future<List<dynamic>> getActiveDiscounts() async {
    try {
      final response = await _dio.get('/discount/active');
      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data.toString() ?? "Không lấy được voucher");
    }
  }

  ///=========================
  /// CREATE
  ///=========================

  Future<void> createDiscount(Map<String, dynamic> voucher) async {
    try {
      await _dio.post(
        '/discount',
        data: voucher,
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data.toString() ?? "Thêm voucher thất bại");
    }
  }

  ///=========================
  /// UPDATE
  ///=========================

  Future<void> updateDiscount(
      int id,
      Map<String, dynamic> voucher,
      ) async {
    try {
      await _dio.put(
        '/discount/$id',
        data: voucher,
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data.toString() ?? "Cập nhật voucher thất bại");
    }
  }

  ///=========================
  /// DELETE
  ///=========================

  Future<void> deleteDiscount(int id) async {
    try {
      await _dio.delete('/discount/$id');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data.toString() ?? "Xóa voucher thất bại");
    }
  }

  ///=========================
  /// GET BY ID
  ///=========================

  Future<Map<String, dynamic>> getDiscountById(int id) async {
    try {
      final response = await _dio.get('/discount/$id');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data.toString() ?? "Không lấy được voucher");
    }
  }
}