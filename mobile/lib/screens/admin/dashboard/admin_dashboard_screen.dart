import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/app_theme.dart';
import '../../../models/dashboard_revenue_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../widgets/admin_bottom_navigation.dart';

enum _RevenuePeriod {
  day('Hôm nay', 'Doanh thu hôm nay'),
  week('7 ngày', 'Doanh thu 7 ngày gần đây'),
  month('Tháng này', 'Doanh thu tháng này'),
  lastMonth('Tháng trước', 'Doanh thu tháng trước'),
  year('Năm nay', 'Doanh thu năm nay');

  const _RevenuePeriod(this.label, this.detailLabel);

  final String label;
  final String detailLabel;
}

enum _TrendView {
  days('Ngày trong tháng', Icons.calendar_view_month_outlined),
  months('Tháng trong năm', Icons.bar_chart),
  years('3 năm gần nhất', Icons.stacked_line_chart);

  const _TrendView(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  _RevenuePeriod _period = _RevenuePeriod.month;
  _TrendView _trendView = _TrendView.months;

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(revenueOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doanh thu'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(revenueOverviewProvider),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(
        currentTab: AdminNavTab.revenue,
      ),
      body: revenueAsync.when(
        data: (overview) => RefreshIndicator(
          onRefresh: () async => ref.refresh(revenueOverviewProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PeriodSelector(
                selected: _period,
                onChanged: (period) => setState(() => _period = period),
              ),
              const SizedBox(height: 12),
              _TotalRevenueHero(
                period: _period,
                revenue: _valueForPeriod(overview.total, _period),
                breakdown: overview.total,
              ),
              const SizedBox(height: 16),
              _RevenueTrendPanel(
                trends: overview.trends,
                selected: _trendView,
                onChanged: (view) => setState(() => _trendView = view),
              ),
              const SizedBox(height: 16),
              if (overview.hotels.isEmpty)
                const _EmptyState()
              else ...[
                _BranchLeaderboard(
                  hotels: _sortHotelsByPeriod(overview.hotels, _period),
                  period: _period,
                  totalRevenue: _valueForPeriod(overview.total, _period),
                  onHotelTap: (hotel) => _showRevenueDetail(context, hotel),
                ),
                const SizedBox(height: 16),
                _RevenueDistribution(
                  hotels: _sortHotelsByPeriod(overview.hotels, _period),
                  period: _period,
                ),
              ],
            ],
          ),
        ),
        loading: () => const _LoadingState(),
        error: (err, stack) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(revenueOverviewProvider),
        ),
      ),
    );
  }
}

class _RevenueTrendPanel extends StatelessWidget {
  final RevenueTrends trends;
  final _TrendView selected;
  final ValueChanged<_TrendView> onChanged;

  const _RevenueTrendPanel({
    required this.trends,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final points = _pointsForTrend(trends, selected);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.insights_outlined,
              title: 'Xu hướng doanh thu',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final view in _TrendView.values)
                  ChoiceChip(
                    label: Text(view.label),
                    avatar: Icon(view.icon, size: 18),
                    selected: selected == view,
                    showCheckmark: false,
                    onSelected: (_) => onChanged(view),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (points.isEmpty)
              const _TrendEmptyState()
            else
              _RevenueTrendBars(points: points),
          ],
        ),
      ),
    );
  }
}

class _RevenueTrendBars extends StatelessWidget {
  final List<RevenuePoint> points;

  const _RevenueTrendBars({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxRevenue = points.fold<double>(
        0, (max, point) => point.value > max ? point.value : max);

    return Column(
      children: [
        for (var index = 0; index < points.length; index++) ...[
          _RevenueTrendRow(
            point: points[index],
            maxRevenue: maxRevenue,
          ),
          if (index < points.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RevenueTrendRow extends StatelessWidget {
  final RevenuePoint point;
  final double maxRevenue;

  const _RevenueTrendRow({
    required this.point,
    required this.maxRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final ratio =
        maxRevenue <= 0 ? 0.0 : (point.value / maxRevenue).clamp(0, 1);

    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(
            point.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.toDouble(),
              minHeight: 12,
              backgroundColor: const Color(0xFFE5E7EB),
              color: AppTheme.primaryDark,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 92,
          child: Text(
            _formatCompactCurrency(point.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF0F766E),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendEmptyState extends StatelessWidget {
  const _TrendEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'Chưa có dữ liệu xu hướng',
          style: TextStyle(color: AppTheme.textGray),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final _RevenuePeriod selected;
  final ValueChanged<_RevenuePeriod> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final period in _RevenuePeriod.values)
              ChoiceChip(
                label: Text(period.label),
                avatar: Icon(_iconForPeriod(period), size: 18),
                selected: selected == period,
                showCheckmark: false,
                onSelected: (_) => onChanged(period),
              ),
          ],
        ),
      ),
    );
  }
}

class _TotalRevenueHero extends StatelessWidget {
  final _RevenuePeriod period;
  final double revenue;
  final RevenueBreakdown breakdown;

  const _TotalRevenueHero({
    required this.period,
    required this.revenue,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng doanh thu',
                        style: TextStyle(
                          color: AppTheme.textGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        period.label,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                _formatCurrency(revenue),
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _BreakdownChips(revenue: breakdown, selected: period),
          ],
        ),
      ),
    );
  }
}

class _BreakdownChips extends StatelessWidget {
  final RevenueBreakdown revenue;
  final _RevenuePeriod selected;

  const _BreakdownChips({
    required this.revenue,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chips = _RevenuePeriod.values
            .map(
              (period) => _BreakdownChip(
                label: period.label,
                value: _valueForPeriod(revenue, period),
                isSelected: period == selected,
              ),
            )
            .toList();

        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              for (var index = 0; index < chips.length; index++) ...[
                chips[index],
                if (index < chips.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < chips.length; index++) ...[
              Expanded(child: chips[index]),
              if (index < chips.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  final String label;
  final double value;
  final bool isSelected;

  const _BreakdownChip({
    required this.label,
    required this.value,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE6F7F2) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFF99D8C8) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0F766E) : AppTheme.textGray,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatCompactCurrency(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchLeaderboard extends StatelessWidget {
  final List<HotelRevenue> hotels;
  final _RevenuePeriod period;
  final double totalRevenue;
  final ValueChanged<HotelRevenue> onHotelTap;

  const _BranchLeaderboard({
    required this.hotels,
    required this.period,
    required this.totalRevenue,
    required this.onHotelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.leaderboard_outlined,
              title: 'Xếp hạng chi nhánh',
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < hotels.length; index++)
              _BranchRankTile(
                rank: index + 1,
                hotel: hotels[index],
                period: period,
                totalRevenue: totalRevenue,
                onTap: () => onHotelTap(hotels[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class _BranchRankTile extends StatelessWidget {
  final int rank;
  final HotelRevenue hotel;
  final _RevenuePeriod period;
  final double totalRevenue;
  final VoidCallback onTap;

  const _BranchRankTile({
    required this.rank,
    required this.hotel,
    required this.period,
    required this.totalRevenue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final revenue = _valueForPeriod(hotel.revenue, period);
    final ratio =
        totalRevenue <= 0 ? 0.0 : (revenue / totalRevenue).clamp(0, 1);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: 12),
            Expanded(
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
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatCompactCurrency(revenue),
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: ratio.toDouble(),
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: rank == 1
                          ? const Color(0xFF0F766E)
                          : AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop ? const Color(0xFFFFF7ED) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: isTop ? const Color(0xFFEA580C) : AppTheme.textGray,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RevenueDistribution extends StatelessWidget {
  final List<HotelRevenue> hotels;
  final _RevenuePeriod period;

  const _RevenueDistribution({
    required this.hotels,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final maxRevenue = hotels
        .map((hotel) => _valueForPeriod(hotel.revenue, period))
        .fold<double>(0, (max, value) => value > max ? value : max);
    final visibleHotels = hotels.take(6).toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.bar_chart,
              title: 'So sánh doanh thu',
            ),
            const SizedBox(height: 14),
            for (final hotel in visibleHotels) ...[
              _DistributionBar(
                hotel: hotel,
                period: period,
                maxRevenue: maxRevenue,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final HotelRevenue hotel;
  final _RevenuePeriod period;
  final double maxRevenue;

  const _DistributionBar({
    required this.hotel,
    required this.period,
    required this.maxRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final revenue = _valueForPeriod(hotel.revenue, period);
    final ratio = maxRevenue <= 0 ? 0.0 : (revenue / maxRevenue).clamp(0, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                hotel.hotelName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatCompactCurrency(revenue),
              style: const TextStyle(
                color: AppTheme.textGray,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio.toDouble(),
            minHeight: 10,
            backgroundColor: const Color(0xFFE5E7EB),
            color: AppTheme.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryDark, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, color: AppTheme.textGray, size: 38),
            SizedBox(height: 10),
            Text(
              'Chưa có chi nhánh để hiển thị doanh thu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
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
            const Icon(Icons.error_outline, size: 42, color: AppTheme.error),
            const SizedBox(height: 12),
            const Text(
              'Không tải được doanh thu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textGray),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              hotel.hotelId,
              style: const TextStyle(color: AppTheme.textGray),
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Doanh thu hôm nay', value: hotel.revenue.day),
            _DetailRow(label: 'Doanh thu 7 ngày', value: hotel.revenue.week),
            _DetailRow(
              label: 'Doanh thu tháng này',
              value: hotel.revenue.month,
            ),
            _DetailRow(
              label: 'Doanh thu tháng trước',
              value: hotel.revenue.lastMonth,
            ),
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

List<HotelRevenue> _sortHotelsByPeriod(
  List<HotelRevenue> hotels,
  _RevenuePeriod period,
) {
  return [...hotels]..sort(
      (a, b) => _valueForPeriod(b.revenue, period)
          .compareTo(_valueForPeriod(a.revenue, period)),
    );
}

List<RevenuePoint> _pointsForTrend(
  RevenueTrends trends,
  _TrendView selected,
) {
  return switch (selected) {
    _TrendView.days => trends.daysInMonth,
    _TrendView.months => trends.monthsInYear,
    _TrendView.years => trends.years,
  };
}

double _valueForPeriod(RevenueBreakdown revenue, _RevenuePeriod period) {
  return switch (period) {
    _RevenuePeriod.day => revenue.day,
    _RevenuePeriod.week => revenue.week,
    _RevenuePeriod.month => revenue.month,
    _RevenuePeriod.lastMonth => revenue.lastMonth,
    _RevenuePeriod.year => revenue.year,
  };
}

IconData _iconForPeriod(_RevenuePeriod period) {
  return switch (period) {
    _RevenuePeriod.day => Icons.today_outlined,
    _RevenuePeriod.week => Icons.date_range_outlined,
    _RevenuePeriod.month => Icons.calendar_month_outlined,
    _RevenuePeriod.lastMonth => Icons.history_outlined,
    _RevenuePeriod.year => Icons.query_stats_outlined,
  };
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
