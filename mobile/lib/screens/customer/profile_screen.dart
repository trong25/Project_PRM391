// lib/screens/customer/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final int _currentIndex = 3; // Index mặc định cho tab Tài khoản

  void _onComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang được phát triển')),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == 3) {
      return;
    }
    if (index == 0) {
      // Chuyển về Home
      context.go('/home');
      return;
    }
    _onComingSoon(context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.25),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            _initials(user?.fullName),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.fullName ?? '—',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.role ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader(title: 'Thông tin tài khoản'),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _InfoRow(icon: Icons.person_outline, label: 'Họ và tên', value: user?.fullName ?? '—'),
                      const Divider(height: 1, indent: 48),
                      _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '—'),
                      const Divider(height: 1, indent: 48),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Số điện thoại',
                        value: user?.phone != null && user!.phone.isNotEmpty ? user.phone : '—',
                      ),
                      const Divider(height: 1, indent: 48),
                      _InfoRow(icon: Icons.badge_outlined, label: 'Vai trò', value: user?.role ?? '—'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    children: [
                      _ActionRow(
                        icon: Icons.edit_outlined,
                        label: 'Chỉnh sửa hồ sơ',
                        onTap: () => _showEditProfileDialog(context, ref, user),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Bảo mật'),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _ActionRow(
                        icon: Icons.lock_outline,
                        label: 'Đổi mật khẩu',
                        onTap: () => _showChangePasswordDialog(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(title: 'Tài khoản'),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _ActionRow(
                        icon: Icons.logout,
                        label: 'Đăng xuất',
                        labelColor: AppTheme.error,
                        iconColor: AppTheme.error,
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      AppConfig.appName,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [Icon(Icons.logout, color: AppTheme.error), SizedBox(width: 8), Text('Đăng xuất')],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _ChangePasswordDialog(),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _EditProfileDialog(
          initialFullName: user?.fullName ?? '',
          initialEmail: user?.email ?? '',
          initialPhone: user?.phone ?? '',
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Trang chủ'},
      {'icon': Icons.bookmark_border, 'activeIcon': Icons.bookmark, 'label': 'Đã lưu'},
      {'icon': Icons.work_outline, 'activeIcon': Icons.work, 'label': 'Đặt chỗ'},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Tài khoản'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(items.length, (index) {
              final bool isSelected = index == _currentIndex;
              final item = items[index];

              return Expanded(
                child: InkWell(
                  onTap: () => _onBottomNavTap(index),
                  child: isSelected
                      ? ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: _buildNavItemContent(
                      icon: item['activeIcon'] as IconData,
                      label: item['label'] as String,
                      color: Colors.white,
                    ),
                  )
                      : _buildNavItemContent(
                    icon: item['icon'] as IconData,
                    label: item['label'] as String,
                    color: AppTheme.textGray,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemContent({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// _EditProfileDialog
class _EditProfileDialog extends ConsumerStatefulWidget {
  final String initialFullName;
  final String initialEmail;
  final String initialPhone;

  const _EditProfileDialog({
    required this.initialFullName,
    required this.initialEmail,
    required this.initialPhone,
  });

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  final _formKey      = GlobalKey<FormState>();
  late final _nameCtrl  = TextEditingController(text: widget.initialFullName);
  late final _emailCtrl = TextEditingController(text: widget.initialEmail);
  late final _phoneCtrl = TextEditingController(text: widget.initialPhone);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(updateProfileProvider.notifier)
        .updateProfile(
      fullName: _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      phone:    _phoneCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ref.read(updateProfileProvider.notifier).reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Cập nhật hồ sơ thành công!'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final upState = ref.watch(updateProfileProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chỉnh sửa hồ sơ',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text('Cập nhật thông tin cá nhân', style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: upState.isLoading
                        ? null
                        : () {
                      ref.read(updateProfileProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (upState.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(upState.error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                    ],
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailCtrl,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRegex.hasMatch(v.trim())) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneCtrl,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.phone,
                      onFieldSubmitted: (_) => _onSubmit(),
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                        final phoneRegex = RegExp(r'^[0-9]{9,11}$');
                        if (!phoneRegex.hasMatch(v.trim())) return 'Số điện thoại không hợp lệ (9–11 chữ số)';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: upState.isLoading
                          ? null
                          : () {
                        ref.read(updateProfileProvider.notifier).reset();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: upState.isLoading
                          ? Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                        ),
                      )
                          : DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton(
                          onPressed: _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Lưu thay đổi',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// _ChangePasswordDialog
class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey     = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(changePasswordProvider.notifier)
        .changePassword(
      currentPassword: _currentCtrl.text,
      newPassword:     _newCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ref.read(changePasswordProvider.notifier).reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Đổi mật khẩu thành công!'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cpState = ref.watch(changePasswordProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đổi mật khẩu',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text('Nhập thông tương để cập nhật', style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: cpState.isLoading
                        ? null
                        : () {
                      ref.read(changePasswordProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (cpState.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(cpState.error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                    ],
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _PasswordField(
                      controller: _currentCtrl,
                      label: 'Mật khẩu hiện tại',
                      obscure: _obscureCurrent,
                      onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu hiện tại';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _PasswordField(
                      controller: _newCtrl,
                      label: 'Mật khẩu mới',
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                        if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                        if (v == _currentCtrl.text) return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _PasswordField(
                      controller: _confirmCtrl,
                      label: 'Xác nhận mật khẩu mới',
                      obscure: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      onSubmitted: (_) => _onSubmit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu mới';
                        if (v != _newCtrl.text) return 'Mật khẩu xác nhận không khớp';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: cpState.isLoading
                          ? null
                          : () {
                        ref.read(changePasswordProvider.notifier).reset();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: cpState.isLoading
                          ? Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                        ),
                      )
                          : DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ElevatedButton(
                          onPressed: _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Xác nhận',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Widgets

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textGray,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGray)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final Color? iconColor;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: (labelColor ?? AppTheme.textGray).withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction ?? TextInputAction.next,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}