// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

// ── Service provider ──────────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Auth state ────────────────────────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool       isLoading;
  final String?    error;
  final bool       isInitialized;

  const AuthState({
    this.user,
    this.isLoading    = false,
    this.error,
    this.isInitialized = false,
  });

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    UserModel? user,
    bool?      isLoading,
    String?    error,
    bool?      isInitialized,
    bool       clearUser  = false,
    bool       clearError = false,
  }) {
    return AuthState(
      user:          clearUser  ? null  : (user ?? this.user),
      isLoading:     isLoading  ?? this.isLoading,
      error:         clearError ? null  : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final user = await _service.getCurrentUser();
    state = AuthState(user: user, isInitialized: true);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _service.login(email, password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String roleId = AppConfig.roleCustomerId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        roleId: roleId,
      );
      state = state.copyWith(isLoading: false, isInitialized: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), isInitialized: true);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _service.logout();
    state = const AuthState(isInitialized: true);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

// ── Reset password state ──────────────────────────────────────────────────────
class ResetState {
  final bool    isLoading;
  final String? error;
  final String? success;

  const ResetState({this.isLoading = false, this.error, this.success});

  ResetState copyWith({bool? isLoading, String? error, String? success,
    bool clearError = false, bool clearSuccess = false}) {
    return ResetState(
      isLoading: isLoading ?? this.isLoading,
      error:     clearError   ? null : (error   ?? this.error),
      success:   clearSuccess ? null : (success ?? this.success),
    );
  }
}

class ResetNotifier extends StateNotifier<ResetState> {
  final AuthService _service;
  ResetNotifier(this._service) : super(const ResetState());

  Future<bool> requestReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _service.requestPasswordReset(email);
      state = state.copyWith(
        isLoading: false,
        success: 'Link đặt lại mật khẩu đã được gửi đến email của bạn',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.resetPassword(
        token: token, password: password, confirmPassword: confirmPassword,
      );
      state = state.copyWith(
        isLoading: false,
        success: 'Đặt lại mật khẩu thành công!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final resetProvider = StateNotifierProvider<ResetNotifier, ResetState>((ref) {
  return ResetNotifier(ref.read(authServiceProvider));
});