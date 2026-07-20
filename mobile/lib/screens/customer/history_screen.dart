import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const _paidStatus = 'Đã thanh toán';
  static const _unpaidStatus = 'Chưa thanh toán';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập lại')),
      );
    }

    final bookingsAsync = ref.watch(customerBookingsProvider(user.userId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Lịch sử đặt phòng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.invalidate(customerBookingsProvider(user.userId)),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {
              ref.invalidate(customerBookingsProvider(user.userId));
              await ref.read(customerBookingsProvider(user.userId).future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: bookings.length,
              itemBuilder: (context, index) => _BookingHistoryCard(
                booking: bookings[index],
                onRebook: () => context.push('/rooms/${bookings[index].roomId}/booking'),
                onCancel: () => _confirmCancel(context, ref, user.userId, bookings[index]),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    String userId,
    BookingModel booking,
  ) async {
    final bookingId = booking.bookingId;
    if (bookingId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hủy đặt phòng?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Booking chưa thanh toán sẽ được xóa khỏi lịch sử của bạn.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hủy đặt phòng'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(bookingServiceProvider).cancelCustomerBooking(bookingId);
      ref.invalidate(customerBookingsProvider(userId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đặt phòng')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể hủy đặt phòng. Vui lòng thử lại!'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}

class _BookingHistoryCard extends StatelessWidget {
  const _BookingHistoryCard({
    required this.booking,
    required this.onRebook,
    required this.onCancel,
  });

  final BookingModel booking;
  final VoidCallback onRebook;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final room = booking.room;
    final status = booking.status ?? 'Chưa xác định';
    final isPaid = status == HistoryScreen._paidStatus;
    final isUnpaid = status == HistoryScreen._unpaidStatus;
    final typeName = booking.typeBooking?.typeName ?? room?.typeRoomName ?? '';
    final roomName = room?.nameRoom.isNotEmpty == true ? room!.nameRoom : booking.roomId;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFF0E8FF),
                  child: room?.imageUrl?.isNotEmpty == true
                      ? Image.network(
                          room!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.bedroom_parent_outlined,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                        )
                      : const Icon(
                          Icons.bedroom_parent_outlined,
                          color: AppTheme.primary,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (typeName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        typeName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _StatusChip(status: status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.login_rounded,
            label: 'Nhận phòng',
            value: _formatDateTime(booking.checkIn),
          ),
          if (booking.checkOut != null)
            _InfoRow(
              icon: Icons.logout_rounded,
              label: 'Trả phòng',
              value: _formatDateTime(booking.checkOut!),
            ),
          _InfoRow(
            icon: Icons.payments_outlined,
            label: 'Tổng tiền',
            value: _formatVND(booking.totalPrice ?? 0),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: isPaid
                ? _GradientButton(label: 'Đặt lại', onPressed: onRebook)
                : OutlinedButton(
                    onPressed: isUnpaid ? onCancel : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(
                        color: isUnpaid ? AppTheme.error : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hủy đặt phòng',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute - $day/$month/${value.year}';
  }

  static String _formatVND(double amount) {
    final raw = amount.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
      buffer.write(raw[i]);
    }
    return '${buffer.toString()} đ';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textGray),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status == HistoryScreen._paidStatus;
    final color = isPaid ? const Color(0xFF16A34A) : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Icon(
                Icons.history_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có lịch sử đặt phòng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Các phòng bạn đặt sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textGray),
            ),
            const SizedBox(height: 22),
            _GradientButton(
              label: 'Đặt phòng ngay',
              onPressed: () => context.push('/rooms'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải lịch sử đặt phòng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
