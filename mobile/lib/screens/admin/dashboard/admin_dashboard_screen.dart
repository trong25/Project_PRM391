import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/dashboard_revenue_model.dart';
import '../../../providers/dashboard_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(revenueOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Giám đốc'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(revenueOverviewProvider),
          ),
        ],
      ),
      body: revenueAsync.when(
        data: (overview) => RefreshIndicator(
          onRefresh: () async => ref.refresh(revenueOverviewProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TotalRevenueCard(revenue: overview.total),
              const SizedBox(height: 16),
              if (overview.hotels.isEmpty)
                const _EmptyState()
              else
                _HotelRevenueCarousel(
                  hotels: overview.hotels,
                  onHotelTap: (hotel) => _showRevenueDetail(context, hotel),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(revenueOverviewProvider),
        ),
      ),
    );
  }
}

class _HotelRevenueCarousel extends StatefulWidget {
  final List<HotelRevenue> hotels;
  final ValueChanged<HotelRevenue> onHotelTap;

  const _HotelRevenueCarousel({
    required this.hotels,
    required this.onHotelTap,
  });

  @override
  State<_HotelRevenueCarousel> createState() => _HotelRevenueCarouselState();
}

class _HotelRevenueCarouselState extends State<_HotelRevenueCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.hotels.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      _goTo((_currentPage + 1) % widget.hotels.length);
    });
  }

  void _goTo(int page) {
    final target = (page + widget.hotels.length) % widget.hotels.length;
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
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
                        color: Color(0xFF6D28D9),
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
                          color: Color(0xFF64748B),
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
                    controller: _controller,
                    itemCount: widget.hotels.length,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                      _startTimer();
                    },
                    itemBuilder: (context, index) {
                      final hotel = widget.hotels[index];
                      return _HotelRevenueCard(
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
                        onPressed: () => _goTo(_currentPage - 1),
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
                                  ? const Color(0xFF6D28D9)
                                  : const Color(0xFFD1D5DB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Chi nhánh tiếp theo',
                        onPressed: () => _goTo(_currentPage + 1),
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

class _TotalRevenueCard extends StatelessWidget {
  final RevenueBreakdown revenue;

  const _TotalRevenueCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payments, color: Color(0xFF0F766E)),
                SizedBox(width: 8),
                Text(
                  'Tổng doanh thu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _RevenueGrid(revenue: revenue),
          ],
        ),
      ),
    );
  }
}

class _HotelRevenueCard extends StatelessWidget {
  final HotelRevenue hotel;
  final VoidCallback onTap;

  const _HotelRevenueCard({
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Xem chi tiết',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6D28D9),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.arrow_outward,
                  color: Color(0xFF6D28D9),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 14),
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
        final isNarrow = constraints.maxWidth < 520;
        final children = [
          _RevenueTile(label: 'Hôm nay', value: revenue.day),
          _RevenueTile(label: 'Tháng này', value: revenue.month),
          _RevenueTile(label: 'Năm nay', value: revenue.year),
        ];

        if (isNarrow) {
          return Column(
            children: children
                .map((child) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: child,
                    ))
                .toList(),
          );
        }

        return Row(
          children: children
              .map((child) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: child,
                    ),
                  ))
              .toList(),
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
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(
            _formatCurrency(value),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: Text('Chưa có chi nhánh để hiển thị doanh thu')),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Không tải được doanh thu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              hotel.hotelId,
              style: const TextStyle(color: Color(0xFF64748B)),
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
