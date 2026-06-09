// lib/config/app_config.dart

class AppConfig {
  // ── API ─────────────────────────────────────────────────────────────
  // For Android emulator: use 10.0.2.2 instead of localhost
  // For physical device: use your machine's local IP e.g. 192.168.1.x
  static const String baseUrl = 'http://localhost:8080/api';

  // ── JWT ──────────────────────────────────────────────────────────────
  static const String tokenKey    = 'jwt_token';
  static const String userKey     = 'current_user';

  // ── Roles (must match RoleName in DB) ────────────────────────────────
  static const String roleAdmin           = 'ADMIN';
  static const String roleStaff           = 'STAFF';
  static const String roleCustomer        = 'CUSTOMER';

  // ── App ───────────────────────────────────────────────────────────────
  static const String appName = 'GenzCinema Hotel';
}
