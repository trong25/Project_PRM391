import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../models/room_model.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/staff_bottom_nav_bar.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(revenueOverviewProvider);
    final roomListState = ref.watch(roomListProvider);

    // Calculate free rooms
    final int emptyRoomsCount = roomListState.rooms
        .where((r) => r.status?.toLowerCase() == 'trống')
        .length;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const StaffBottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(revenueOverviewProvider);
            ref.read(roomListProvider.notifier).loadRooms();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // Balance Spacer
                    Image.asset(
                      'assets/images/logo.png',
                      height: 48,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.movie, size: 48, color: AppTheme.primary),
                    ),
                    IconButton(
                      tooltip: 'Đăng xuất',
                      icon: const Icon(Icons.logout, color: AppTheme.textGray),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Brand Title (Gradient)
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                  child: const Text(
                    'Genz Cinema Hotel',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Staff only',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),

                // Card: Doanh thu ngày
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: const Text(
                        'Doanh thu ngày',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                GradientBorderContainer(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      revenueAsync.when(
                        data: (overview) => Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                              .format(overview.total.day),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const Text(
                          '0 đ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SimpleBarChart(),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Cards: Phòng trống & Tin nhắn
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: const Text(
                                'Phòng trống',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          GradientBorderContainer(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                emptyRoomsCount.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: const Text(
                                'Tin nhắn',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          GradientBorderContainer(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: const Center(
                              child: Text(
                                '03',
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                
                // Room Status List Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: const Text(
                        'Quản lý trạng thái phòng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Grid/List of all rooms
                roomListState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : roomListState.error != null
                        ? Center(child: Text('Lỗi tải phòng: ${roomListState.error}'))
                        : roomListState.rooms.isEmpty
                            ? const Center(child: Text('Không có phòng nào'))
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.4,
                                ),
                                itemCount: roomListState.rooms.length,
                                itemBuilder: (context, index) {
                                  final room = roomListState.rooms[index];
                                  final status = room.status ?? 'Trống';
                                  
                                  Color statusColor = Colors.grey;
                                  if (status.toLowerCase() == 'trống') statusColor = Colors.green.shade600;
                                  if (status.toLowerCase() == 'đang thuê') statusColor = Colors.orange.shade700;
                                  if (status.toLowerCase() == 'dọn dẹp') statusColor = Colors.blue.shade600;
                                  if (status.toLowerCase() == 'bảo trì') statusColor = Colors.red.shade600;

                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Phòng ${room.nameRoom ?? room.roomId}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            tooltip: 'Nhấn để đổi trạng thái',
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.1),
                                                border: Border.all(color: statusColor),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    status,
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.arrow_drop_down, size: 16, color: statusColor),
                                                ],
                                              ),
                                            ),
                                            onSelected: (newStatus) async {
                                              try {
                                                await ref.read(roomServiceProvider).updateRoomStatus(room.roomId, newStatus);
                                                ref.read(roomListProvider.notifier).loadRooms();
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Đã cập nhật phòng ${room.roomId} sang "$newStatus"')),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Lỗi cập nhật: $e')),
                                                  );
                                                }
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(value: 'Trống', child: Text('Trống')),
                                              const PopupMenuItem(value: 'Đang thuê', child: Text('Đang thuê')),
                                              const PopupMenuItem(value: 'Dọn dẹp', child: Text('Dọn dẹp')),
                                              const PopupMenuItem(value: 'Bảo trì', child: Text('Bảo trì')),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;

  const GradientBorderContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.borderWidth = 1.5,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Y Axis
          Container(
            width: 1.5,
            height: double.infinity,
            color: Colors.black45,
          ),
          const SizedBox(width: 8),
          // Bars area
          Expanded(
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                // X Axis
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 1.5,
                    color: Colors.black45,
                  ),
                ),
                // The Bars
                Positioned.fill(
                  bottom: 1.5, // Just above X axis
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(40),
                      _buildBar(55),
                      _buildBar(75),
                      _buildBar(45),
                      _buildBar(0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightPercentage) {
    return Expanded(
      child: FractionallySizedBox(
        heightFactor: heightPercentage / 100,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
      ),
    );
  }
}
