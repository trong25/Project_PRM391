// lib/config/app_config.dart

import 'package:flutter/foundation.dart';

class AppConfig {
  // ── API ─────────────────────────────────────────────────────────────
  // For Android emulator: use 10.0.2.2 instead of localhost
  // For physical device: use your machine's local IP e.g. 192.168.1.x
  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) return 'http://localhost:8080/api';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080/api';
      default:
        return 'http://localhost:8080/api';
    }
  }

  // ── JWT ──────────────────────────────────────────────────────────────
  static const String tokenKey    = 'jwt_token';
  static const String userKey     = 'current_user';

  // ── Roles (must match RoleName in DB) ────────────────────────────────
  static const String roleAdmin           = 'ADMIN';
  static const String roleStaff           = 'STAFF';
  static const String roleCustomer        = 'CUSTOMER';

  // ── Role IDs (must match roleId in Role table) ────────────────────────
  static const String roleCustomerId      = 'CUSTOMER';

  // ── App ───────────────────────────────────────────────────────────────
  static const String appName = 'GenzCinema Hotel';
}
