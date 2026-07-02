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
      await _clearLocalSession();

      final response = await _dio.post('/auth/login', data: {
        'email':    email,
        'password': password,
      });

      final data = response.data['data'];
      final token = data['token'] as String? ?? '';
      if (token.isEmpty) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Server không trả về token đăng nhập.',
        );
      }
      final user = UserModel.fromJson(data, token);

      // Persist JWT + user info securely
      await _storage.write(key: AppConfig.tokenKey, value: user.token);
      await _storage.write(key: AppConfig.userKey,  value: jsonEncode(user.toJson()));

      return user;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String roleId,
  }) async {
    try {
      await _dio.post('/auth/register', data: {
        'fullName': fullName,
        'email':    email,
        'phone':    phone,
        'password': password,
        'roleId':   roleId,
      });
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
      await _clearLocalSession();
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

  // ─── Change Password (authenticated) ─────────────────────────────────

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.put('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword':     newPassword,
        'confirmPassword': confirmPassword,
      });
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Update Profile ───────────────────────────────────────────────────

  Future<UserModel> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String token,
  }) async {
    try {
      final response = await _dio.put('/auth/profile', data: {
        'fullName': fullName,
        'email':    email,
        'phone':    phone,
      });

      final data = response.data['data'];
      final updatedUser = UserModel.fromJson(data, token);

      // Persist updated user info
      await _storage.write(key: AppConfig.userKey, value: jsonEncode(updatedUser.toJson()));

      return updatedUser;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Get Current User from storage ────────────────────────────────────

  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.read(key: AppConfig.tokenKey);
    if (token == null || token.isEmpty) return null;

    final userJson = await _storage.read(key: AppConfig.userKey);
    if (userJson == null) return null;
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      final claims = _decodeJwtClaims(token);
      final tokenEmail = claims?['sub'] as String? ?? '';
      final tokenRoleId = claims?['roleId'] as String? ?? '';
      final storedEmail = map['email'] as String? ?? '';
      final storedRoleId = map['roleId'] as String? ?? '';

      if (claims == null ||
          tokenEmail.toLowerCase() != storedEmail.toLowerCase() ||
          tokenRoleId.toUpperCase() != storedRoleId.toUpperCase()) {
        await _clearLocalSession();
        return null;
      }

      return UserModel.fromJson(map, token);
    } catch (_) {
      await _clearLocalSession();
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConfig.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // ─── Error helper ─────────────────────────────────────────────────────

  Future<void> _clearLocalSession() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.userKey);
  }

  Map<String, dynamic>? _decodeJwtClaims(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'] as String;
    }
    return 'Lỗi kết nối. Vui lòng thử lại.';
  }
}
