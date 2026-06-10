// lib/screens/auth/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _passwordCtrl   = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  bool  _obscurePass    = true;
  bool  _obscureConfirm = true;
  bool  _isVerifying    = true;
  String? _tokenError;
  String? _email;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    try {
      final email = await AuthService().verifyResetToken(widget.token);
      setState(() { _email = email; _isVerifying = false; });
    } catch (e) {
      setState(() { _tokenError = e.toString(); _isVerifying = false; });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(resetProvider.notifier).resetPassword(
      token:           widget.token,
      password:        _passwordCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resetState = ref.watch(resetProvider);

    if (_isVerifying) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_tokenError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                const SizedBox(height: 16),
                Text(_tokenError!, textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.error)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/request-reset'),
                  child: const Text('Yêu cầu link mới'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lại mật khẩu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.lock_open, size: 56, color: AppTheme.primary),
            const SizedBox(height: 12),
            if (_email != null)
              Text(
                'Đặt lại mật khẩu cho: $_email',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textGray, fontSize: 13),
              ),
            const SizedBox(height: 24),

            if (resetState.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(resetState.error!,
                    style: const TextStyle(color: AppTheme.error)),
              ),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // New password
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                      if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm password
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                      if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: resetState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: _onSubmit,
                      child: const Text('Xác nhận đặt lại'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}