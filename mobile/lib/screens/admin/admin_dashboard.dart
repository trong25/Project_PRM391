// lib/screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, ${user?.fullName ?? 'Admin'}',
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Quản lý hệ thống GenzCinema Hotel',
              style: TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: 'Phòng', value: '--', icon: Icons.hotel,
                  color: AppTheme.primary,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'Booking', value: '--', icon: Icons.book_online,
                  color: const Color(0xFF10B981),
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'Người dùng', value: '--', icon: Icons.people_outline,
                  color: const Color(0xFFF59E0B),
                )),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Quản lý',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _MenuTile(icon: Icons.hotel,        label: 'Quản lý phòng',       onTap: () {}),
            _MenuTile(icon: Icons.book_online,  label: 'Quản lý booking',     onTap: () {}),
            _MenuTile(icon: Icons.people,       label: 'Quản lý người dùng',  onTap: () {}),
            _MenuTile(icon: Icons.price_change, label: 'Cấu hình giá',        onTap: () {}),
            _MenuTile(icon: Icons.analytics,    label: 'Báo cáo doanh thu',   onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String    label;
  final String    value;
  final IconData  icon;
  final Color     color;

  const _StatCard({
    required this.label, required this.value,
    required this.icon,  required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color,
            )),
            Text(label, style: const TextStyle(
              fontSize: 11, color: AppTheme.textGray,
            )),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textGray),
        onTap: onTap,
      ),
    );
  }
}