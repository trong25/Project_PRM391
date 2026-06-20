// lib/screens/admin/admin_dashboard.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/dashboard_revenue_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'room/room_management_screen.dart';
import 'user/user_management_screen.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final revenueAsync = ref.watch(revenueOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
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
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Phòng',
                    value: '--',
                    icon: Icons.hotel,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Booking',
                    value: '--',
                    icon: Icons.book_online,
                    color: Color(0xFF10B981),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Người dùng',
                    value: '--',
                    icon: Icons.people_outline,
                    color: Color(0xFFF59E0B),
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
            _MenuTile(
              icon: Icons.hotel,
              label: 'Quản lý phòng',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoomManagementScreen()),
              ),
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManagementScreen()),
              ),
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

  const _DashboardRevenueSection({
    required this.revenueAsync,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return revenueAsync.when(
      data: (overview) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RevenueSummaryCard(
            title: 'Tổng doanh thu',
            icon: Icons.payments,
            revenue: overview.total,
          ),
          const SizedBox(height: 12),
          if (overview.hotels.isEmpty)
            const _RevenueEmptyCard()
          else
            _BranchRevenueCarousel(
              hotels: overview.hotels,
              onHotelTap: (hotel) => _showRevenueDetail(context, hotel),
            ),
        ],
      ),
      loading: () => const _RevenueLoadingCard(),
      error: (error, stackTrace) => _RevenueErrorCard(
        message: error.toString(),
        onRetry: onRetry,
      ),
    );
  }
}

class _BranchRevenueCarousel extends StatefulWidget {
  final List<HotelRevenue> hotels;
  final ValueChanged<HotelRevenue> onHotelTap;

  const _BranchRevenueCarousel({
    required this.hotels,
    required this.onHotelTap,
  });

  @override
  State<_BranchRevenueCarousel> createState() => _BranchRevenueCarouselState();
}

class _BranchRevenueCarouselState extends State<_BranchRevenueCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  @override
  void didUpdateWidget(covariant _BranchRevenueCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.hotels.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
    if (oldWidget.hotels.length != widget.hotels.length) {
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (widget.hotels.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % widget.hotels.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _goToPage(int page) {
    final target = (page + widget.hotels.length) % widget.hotels.length;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: AppTheme.primaryDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Doanh thu chi nhánh',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentPage + 1}/${widget.hotels.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                SizedBox(
                  height: isNarrow ? 320 : 118,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.hotels.length,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                      _startAutoSlide();
                    },
                    itemBuilder: (context, index) {
                      final hotel = widget.hotels[index];
                      return _BranchRevenueCard(
                        hotel: hotel,
                        onTap: () => widget.onHotelTap(hotel),
                      );
                    },
                  ),
                ),
                if (widget.hotels.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Chi nhánh trước',
                        onPressed: () => _goToPage(_currentPage - 1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          widget.hotels.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: index == _currentPage ? 22 : 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: index == _currentPage
                                  ? AppTheme.primaryDark
                                  : const Color(0xFFD1D5DB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Chi nhánh tiếp theo',
                        onPressed: () => _goToPage(_currentPage + 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final RevenueBreakdown revenue;

  const _RevenueSummaryCard({
    required this.title,
    required this.icon,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0F766E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _RevenueGrid(revenue: revenue),
          ],
        ),
      ),
    );
  }
}

class _BranchRevenueCard extends StatelessWidget {
  final HotelRevenue hotel;
  final VoidCallback onTap;

  const _BranchRevenueCard({
    required this.hotel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hotel.hotelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Xem chi tiết',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.arrow_outward,
                  color: AppTheme.primaryDark,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RevenueGrid(revenue: hotel.revenue),
          ],
        ),
      ),
    );
  }
}

class _RevenueGrid extends StatelessWidget {
  final RevenueBreakdown revenue;

  const _RevenueGrid({required this.revenue});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;
        final tiles = [
          _RevenueTile(label: 'Hôm nay', value: revenue.day),
          _RevenueTile(label: 'Tháng này', value: revenue.month),
          _RevenueTile(label: 'Năm nay', value: revenue.year),
        ];

        if (isNarrow) {
          return Column(
            children: tiles
                .map(
                  (tile) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: tile,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            for (var index = 0; index < tiles.length; index++) ...[
              Expanded(child: tiles[index]),
              if (index < tiles.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _RevenueTile extends StatelessWidget {
  final String label;
  final double value;

  const _RevenueTile({
    required this.label,
    required this.value,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
          ),
          const SizedBox(height: 6),
          Text(
            _formatCurrency(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F766E),
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

class _RevenueEmptyCard extends StatelessWidget {
  const _RevenueEmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Chưa có chi nhánh để hiển thị doanh thu',
          style: TextStyle(color: AppTheme.textGray),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
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
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textGray,
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

void _showRevenueDetail(BuildContext context, HotelRevenue hotel) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hotel.hotelName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hotel.hotelId,
              style: const TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Doanh thu hôm nay', value: hotel.revenue.day),
            _DetailRow(
                label: 'Doanh thu tháng này', value: hotel.revenue.month),
            _DetailRow(label: 'Doanh thu năm nay', value: hotel.revenue.year),
          ],
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final double value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Text(
            _formatCurrency(value),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  return NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(value);
}
