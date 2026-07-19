// lib/widgets/app_bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class AppBottomNavBar extends ConsumerWidget {
  // currentIndex: 0=Trang chủ, 1=Đã lưu, 2=Lịch sử, 3=Đặt chỗ, 4=Tài khoản
  final int currentIndex;

  const AppBottomNavBar({super.key, required this.currentIndex});

  static const _items = [
    {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Trang chủ'},
    {'icon': Icons.bookmark_border, 'activeIcon': Icons.bookmark, 'label': 'Đã lưu'},
    {'icon': Icons.history_outlined, 'activeIcon': Icons.history, 'label': 'Lịch sử'},
    {'icon': Icons.work_outline, 'activeIcon': Icons.work, 'label': 'Đặt chỗ'},
    {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Tài khoản'},
  ];

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    if (index == 4) {
      _showAccountSheet(context, ref);
      return;
    }
    if (index == currentIndex) return;
    final routes = ['/home', '/saved', '/history', '/rooms'];
    context.push(routes[index]);
  }

  void _showAccountSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final bool isLoggedIn = user != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              if (!isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.login, color: AppTheme.primary),
                  title: const Text('Đăng nhập'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/login');
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.person, color: AppTheme.primary),
                  title: const Text('Tài khoản'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppTheme.primaryDark),
                  title: const Text('Đăng xuất'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            children: List.generate(_items.length, (index) {
              final bool isSelected = index == currentIndex;
              final item = _items[index];

              return Expanded(
                child: InkWell(
                  onTap: () => _onTap(context, ref, index),
                  child: isSelected
                      ? ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.primaryGradient.createShader(bounds),
                          child: _navItemContent(
                            icon: item['activeIcon'] as IconData,
                            label: item['label'] as String,
                            color: Colors.white,
                          ),
                        )
                      : _navItemContent(
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

  Widget _navItemContent({
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
