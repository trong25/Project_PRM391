// lib/services/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // ── Request interceptor: attach JWT token ────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConfig.tokenKey);
        // Public endpoints that do NOT require a JWT token
        const publicPaths = [
          '/auth/login',
          '/auth/register',
          '/auth/request-reset',
          '/auth/verify-token',
          '/auth/reset-password',
        ];
        final isPublicEndpoint = publicPaths.any((p) => options.path.startsWith(p));
        final cleanToken = token?.trim().replaceAll(RegExp(r'[\r\n]'), '');
        if (!isPublicEndpoint && cleanToken != null && cleanToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $cleanToken';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token expired → clear and signal re-login
          await _storage.delete(key: AppConfig.tokenKey);
          await _storage.delete(key: AppConfig.userKey);
        }
        return handler.next(e);
      },
    ));
  }

  static ApiClient get instance => _instance ??= ApiClient._();

  Dio get dio => _dio;
}
