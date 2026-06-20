// lib/config/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/request_reset_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/admin/admin_dashboard.dart';

// ── Listenable bridge: Riverpod → GoRouter ────────────────────────────────────
// GoRouter cần một ChangeNotifier để biết khi nào chạy lại redirect.
// Class này lắng nghe authProvider và notify GoRouter khi state thay đổi,
// nhưng KHÔNG rebuild routerProvider → GoRouter không bị tạo lại.
class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
  AuthState get authState => _ref.read(authProvider);
}

// ── Router provider ───────────────────────────────────────────────────────────
// Dùng ref.read (không phải ref.watch) → Provider này chỉ chạy 1 lần duy nhất
// → GoRouter không bao giờ bị tạo lại → initialLocation không reset.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifierListenable(ref);

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier, // GoRouter tự gọi lại redirect khi auth thay đổi
    redirect: (context, state) {
      final isResetWithToken =
          state.matchedLocation.startsWith('/reset-password') &&
              (state.uri.queryParameters['token']?.isNotEmpty ?? false);
      if (isResetWithToken) return null;

      final authState = notifier.authState;
      if (!authState.isInitialized) return null;

      final isLoggedIn = authState.isLoggedIn;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/request-reset') ||
          state.matchedLocation.startsWith('/reset-password');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return _homeForRole(authState.user?.roleId);

      return null;
    },
    routes: [
      // ── Auth routes ──────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/request-reset',
        name: 'request-reset',
        builder: (_, __) => const RequestResetScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),

      // ── App routes ────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, __) => const AdminDashboard(),
      ),
    ],
  );

  // Hủy notifier khi provider bị dispose
  ref.onDispose(notifier.dispose);

  return router;
});

String _homeForRole(String? roleId) {
  if (roleId == null) return '/home';
  switch (roleId.toUpperCase()) {
    case AppConfig.roleAdmin:
      return '/admin';
    case AppConfig.roleStaff:
      return '/home';
    default:
      return '/home';
  }
}