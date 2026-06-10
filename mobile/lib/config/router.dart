// lib/config/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/request_reset_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/admin/admin_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Wait for auth init
      if (!authState.isInitialized) return null;

      final isLoggedIn    = authState.isLoggedIn;
      final isAuthRoute   = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/request-reset') ||
          state.matchedLocation.startsWith('/reset-password');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn  &&  isAuthRoute) return _homeForRole(authState.user?.role);

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
});

String _homeForRole(String? role) {
  if (role == null) return '/home';
  switch (role.toLowerCase()) {
    case AppConfig.roleAdmin:   return '/admin';
    default:                    return '/home';
  }
}