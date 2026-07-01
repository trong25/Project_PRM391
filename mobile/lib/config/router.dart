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
import '../screens/customer/profile_screen.dart';
import '../screens/customer/room/room_list_screen.dart';
import '../screens/customer/room/room_detail_screen.dart';
import '../screens/customer/saved/saved_screen.dart';
import '../screens/customer/booking/booking_screen.dart';
import '../providers/room_provider.dart';
import '../models/room_model.dart';

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
      if (isLoggedIn && isAuthRoute) return _homeForRole(authState.user?.role);

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

      // ── Saved routes ─────────────────────────────────────────────────
      GoRoute(
        path: '/saved',
        name: 'saved',
        builder: (_, __) => const SavedScreen(),
      ),

      // ── Account & Profile routes ─────────────────────────────────────
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),

      // ── Room routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/rooms',
        name: 'rooms',
        builder: (_, state) {
          final typeFilter = state.uri.queryParameters['type'];
          return RoomListScreen(typeFilter: typeFilter);
        },
      ),
      GoRoute(
        path: '/rooms/:id',
        name: 'room-detail',
        builder: (_, state) {
          final id = state.pathParameters['id'] ?? '';
          return RoomDetailScreen(roomId: id);
        },
      ),
      GoRoute(
        path: '/rooms/:id/booking',
        name: 'room-booking',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra;
          if (extra != null) {
            // Room đã được truyền trực tiếp từ màn hình chi tiết
            return BookingScreen(room: extra as RoomModel);
          }
          // Fallback: load room rồi mới mở BookingScreen
          return _RoomBookingLoader(roomId: id);
        },
      ),
    ],
  );

  // Hủy notifier khi provider bị dispose
  ref.onDispose(notifier.dispose);

  return router;
});

String _homeForRole(String? role) {
  if (role == null) return '/home';
  switch (role.toLowerCase()) {
    case AppConfig.roleAdmin:
      return '/admin';
    default:
      return '/home';
  }
}

// ── Helper: load room rồi mở BookingScreen (fallback khi không có extra) ─────
class _RoomBookingLoader extends ConsumerWidget {
  final String roomId;
  const _RoomBookingLoader({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(roomDetailProvider(roomId));

    if (detailState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (detailState.room == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy phòng')),
      );
    }
    return BookingScreen(room: detailState.room!);
  }
}
