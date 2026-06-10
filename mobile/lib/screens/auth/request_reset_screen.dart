// lib/screens/auth/request_reset_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class RequestResetScreen extends ConsumerStatefulWidget {
  const RequestResetScreen({super.key});

  @override
  ConsumerState<RequestResetScreen> createState() => _RequestResetScreenState();
}

class _RequestResetScreenState extends ConsumerState<RequestResetScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(resetProvider.notifier).requestReset(_emailCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final resetState = ref.watch(resetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.lock_reset, size: 64, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Đặt lại mật khẩu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhập email của bạn và chúng tôi sẽ gửi link đặt lại mật khẩu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGray, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Success message
            if (resetState.success != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resetState.success!,
                        style: const TextStyle(color: AppTheme.success),
                      ),
                    ),
                  ],
                ),
              ),

            // Error message
            if (resetState.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Text(
                  resetState.error!,
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return 'Email không hợp lệ';
                      }
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
                      child: const Text('Gửi link đặt lại'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Quay lại đăng nhập',
                      style: TextStyle(color: AppTheme.primary),
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