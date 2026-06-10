// lib/services/auth_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final _dio     = ApiClient.instance.dio;
  final _storage = const FlutterSecureStorage();

  // ─── Login ────────────────────────────────────────────────────────────

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email':    email,
        'password': password,
      });

      final data = response.data['data'];
      final user = UserModel.fromJson(data, data['token']);

      // Persist JWT + user info securely
      await _storage.write(key: AppConfig.tokenKey, value: user.token);
      await _storage.write(key: AppConfig.userKey,  value: jsonEncode(user.toJson()));

      return user;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Even if server call fails, clear local storage
    } finally {
      await _storage.delete(key: AppConfig.tokenKey);
      await _storage.delete(key: AppConfig.userKey);
    }
  }

  // ─── Request Reset ────────────────────────────────────────────────────

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post('/auth/request-reset', data: {'email': email});
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Verify Token ─────────────────────────────────────────────────────

  Future<String> verifyResetToken(String token) async {
    try {
      final response = await _dio.get(
        '/auth/verify-token',
        queryParameters: {'token': token},
      );
      return response.data['data'] as String; // returns email
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Reset Password ───────────────────────────────────────────────────

  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'token':           token,
        'password':        password,
        'confirmPassword': confirmPassword,
      });
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Get Current User from storage ────────────────────────────────────

  Future<UserModel?> getCurrentUser() async {
    final userJson = await _storage.read(key: AppConfig.userKey);
    if (userJson == null) return null;
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(map, map['token'] ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConfig.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // ─── Error helper ─────────────────────────────────────────────────────

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'] as String;
    }
    return 'Lỗi kết nối. Vui lòng thử lại.';
  }
}