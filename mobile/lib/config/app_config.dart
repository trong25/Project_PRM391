// lib/config/app_config.dart

class AppConfig {
  // ── API ─────────────────────────────────────────────────────────────
  // For Android emulator: use 10.0.2.2 instead of localhost
  // For physical device: use your machine's local IP e.g. 192.168.1.x
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // ── JWT ──────────────────────────────────────────────────────────────
  static const String tokenKey    = 'jwt_token';
  static const String userKey     = 'current_user';

  // ── Roles (must match RoleName in DB) ────────────────────────────────
  static const String roleAdmin           = 'admin';
  static const String roleStudent         = 'học sinh';
  static const String roleTeacher         = 'giáo viên';
  static const String roleSale            = 'nhân viên sale';
  static const String roleTrainingManager = 'quản lý đào tạo';
  static const String roleCustomer        = 'customer';

  // ── App ───────────────────────────────────────────────────────────────
  static const String appName = 'GenzCinema Hotel';
}