// lib/screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/dashboard_revenue_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/admin_bottom_navigation.dart';
import 'admin_palette.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final revenueAsync = ref.watch(revenueOverviewProvider);

    return Scaffold(
      backgroundColor: AdminPalette.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AdminPalette.gradient4),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(
        currentTab: AdminNavTab.home,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(revenueOverviewProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Xin chào, ${user?.fullName ?? 'Admin'}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Quản lý hệ thống GenzCinema Hotel',
              style: TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 20),
            _DashboardRevenueSection(
              revenueAsync: revenueAsync,
              onRetry: () => ref.invalidate(revenueOverviewProvider),
              onOpenRevenue: () => context.go('/admin/revenue'),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Phòng',
                    value: '--',
                    icon: Icons.hotel,
                    gradient: AdminPalette.gradient5,
                    foregroundColor: AdminPalette.navy,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Booking',
                    value: '--',
                    icon: Icons.book_online,
                    gradient: AdminPalette.gradient2,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Người dùng',
                    value: '--',
                    icon: Icons.people_outline,
                    gradient: AdminPalette.gradient3,
                    foregroundColor: AdminPalette.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Quản lý',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.analytics,
              label: 'Báo cáo doanh thu',
              onTap: () => context.go('/admin/revenue'),
            ),
            _MenuTile(
              icon: Icons.hotel,
              label: 'Quản lý phòng',
              onTap: () => context.go('/admin/rooms'),
            ),
            _MenuTile(
              icon: Icons.book_online,
              label: 'Quản lý booking',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              ),
            ),
            _MenuTile(
              icon: Icons.people,
              label: 'Quản lý người dùng',
              onTap: () => context.go('/admin/account'),
            ),
            _MenuTile(
              icon: Icons.price_change,
              label: 'Cấu hình giá',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardRevenueSection extends StatelessWidget {
  final AsyncValue<RevenueOverview> revenueAsync;
  final VoidCallback onRetry;
  final VoidCallback onOpenRevenue;

  const _DashboardRevenueSection({
    required this.revenueAsync,
    required this.onRetry,
    required this.onOpenRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return revenueAsync.when(
      data: (overview) => _RevenueSnapshotCard(
        overview: overview,
        onOpenRevenue: onOpenRevenue,
      ),
      loading: () => const _RevenueLoadingCard(),
      error: (error, stackTrace) => _RevenueErrorCard(
        message: error.toString(),
        onRetry: onRetry,
      ),
    );
  }
}

class _RevenueSnapshotCard extends StatelessWidget {
  final RevenueOverview overview;
  final VoidCallback onOpenRevenue;

  const _RevenueSnapshotCard({
    required this.overview,
    required this.onOpenRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final topHotels = _topHotelsByMonth(overview.hotels).take(3).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: AdminPalette.revenueSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D0EE)),
        boxShadow: const [BoxShadow(color: Color(0x1430204F), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E0F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: AdminPalette.revenueText,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doanh thu tháng này',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tổng quan nhanh toàn hệ thống',
                        style: TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Xem báo cáo',
                  onPressed: onOpenRevenue,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                _formatCurrency(overview.total.month),
                style: const TextStyle(
                  color: AdminPalette.revenueText,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 560;
                final chips = [
                  _MiniRevenueChip(
                    label: 'Hôm nay',
                    value: overview.total.day,
                    icon: Icons.today_outlined,
                  ),
                  _MiniRevenueChip(
                    label: '7 ngày',
                    value: overview.total.week,
                    icon: Icons.date_range_outlined,
                  ),
                  _MiniRevenueChip(
                    label: 'Tháng trước',
                    value: overview.total.lastMonth,
                    icon: Icons.history_outlined,
                  ),
                  _MiniRevenueChip(
                    label: 'Năm nay',
                    value: overview.total.year,
                    icon: Icons.query_stats_outlined,
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    children: [
                      for (var index = 0; index < chips.length; index++) ...[
                        chips[index],
                        if (index < chips.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  );
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final chip in chips)
                      SizedBox(
                        width: (constraints.maxWidth - 10) / 2,
                        child: chip,
                      ),
                  ],
                );
              },
            ),
            if (topHotels.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Text(
                'Chi nhánh nổi bật',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < topHotels.length; index++)
                _TopHotelRow(rank: index + 1, hotel: topHotels[index]),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniRevenueChip extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _MiniRevenueChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatCompactCurrency(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHotelRow extends StatelessWidget {
  final int rank;
  final HotelRevenue hotel;

  const _TopHotelRow({
    required this.rank,
    required this.hotel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  rank == 1 ? const Color(0xFFFFF7ED) : const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank == 1 ? const Color(0xFFEA580C) : AppTheme.textGray,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hotel.hotelName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatCompactCurrency(hotel.revenue.month),
            style: const TextStyle(
              color: Color(0xFF0F766E),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueLoadingCard extends StatelessWidget {
  const _RevenueLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 12),
            Text('Đang tải doanh thu...'),
          ],
        ),
      ),
    );
  }
}

class _RevenueErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RevenueErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.error),
                SizedBox(width: 8),
                Text(
                  'Không tải được doanh thu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final Color foregroundColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x189462FF), blurRadius: 12, offset: Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: foregroundColor, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: foregroundColor,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: foregroundColor.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.textGray,
        ),
        onTap: onTap,
      ),
    );
  }
}

List<HotelRevenue> _topHotelsByMonth(List<HotelRevenue> hotels) {
  return [...hotels]
    ..sort((a, b) => b.revenue.month.compareTo(a.revenue.month));
}

String _formatCurrency(double value) {
  return NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(value);
}

String _formatCompactCurrency(double value) {
  final formatter = NumberFormat.compactCurrency(
    locale: 'vi_VN',
    symbol: 'VNĐ',
    decimalDigits: 1,
  );
  return formatter.format(value);
}
