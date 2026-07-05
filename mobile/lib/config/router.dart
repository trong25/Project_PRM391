// lib/config/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../models/room_model.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/dashboard/admin_dashboard_screen.dart';
import '../screens/admin/room/room_management_screen.dart';
import '../screens/admin/user/user_management_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/request_reset_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/customer/booking/booking_screen.dart';
import '../screens/customer/profile_screen.dart';
import '../screens/customer/room/room_detail_screen.dart';
import '../screens/customer/room/room_list_screen.dart';
import '../screens/customer/saved/saved_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/staff/staff_dashboard_screen.dart';
import '../screens/staff/staff_room_management_screen.dart';
import '../screens/staff/staff_booking_management_screen.dart';

class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  AuthState get authState => _ref.read(authProvider);
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifierListenable(ref);

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
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
      if (isLoggedIn && isAuthRoute) {
        return _homeForRole(authState.user?.roleId ?? authState.user?.role);
      }
      if (isLoggedIn && (state.matchedLocation == '/home' || state.matchedLocation == '/')) {
        final role = authState.user?.roleId ?? authState.user?.role;
        if (_isAdminRole(role)) return '/admin';
        if (_isStaffRole(role)) return '/staff';
      }
      if (isLoggedIn &&
          state.matchedLocation.startsWith('/admin') &&
          !_isAdminRole(authState.user?.roleId ?? authState.user?.role)) {
        return '/home';
      }
      if (isLoggedIn &&
          state.matchedLocation.startsWith('/staff') &&
          !_isStaffRole(authState.user?.roleId ?? authState.user?.role)) {
        return '/home';
      }

      return null;
    },
    routes: [
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
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
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
      GoRoute(
        path: '/saved',
        name: 'saved',
        builder: (_, __) => const SavedScreen(),
      ),
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
          if (extra is RoomModel) return BookingScreen(room: extra);
          return _RoomBookingLoader(roomId: id);
        },
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, __) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/revenue',
        name: 'admin-revenue',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/rooms',
        name: 'admin-rooms',
        builder: (_, __) => const RoomManagementScreen(),
      ),
      GoRoute(
        path: '/admin/account',
        name: 'admin-account',
        builder: (_, __) => const UserManagementScreen(),
      ),
      GoRoute(
        path: '/staff',
        name: 'staff',
        builder: (_, __) => const StaffRoomManagementScreen(),
      ),
      GoRoute(
        path: '/staff/bookings',
        name: 'staff-bookings',
        builder: (_, __) => const StaffBookingManagementScreen(),
      ),
    ],
  );

  ref.onDispose(notifier.dispose);
  return router;
});

String _homeForRole(String? roleId) {
  final role = roleId?.toUpperCase();
  if (role == AppConfig.roleAdmin) return '/admin';
  if (role == AppConfig.roleStaff) return '/staff';
  return '/home';
}

bool _isAdminRole(String? roleId) {
  return roleId?.toUpperCase() == AppConfig.roleAdmin;
}

bool _isStaffRole(String? roleId) {
  return roleId?.toUpperCase() == AppConfig.roleStaff;
}

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
