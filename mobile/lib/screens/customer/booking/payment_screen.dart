// lib/screens/customer/booking/payment_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/app_theme.dart';
import '../../../services/booking_service.dart';
import '../../../providers/booking_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int bookingId;
  final double totalAmount;
  final String roomId;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.totalAmount,
    required this.roomId,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isPaid = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _startPolling() async {
    while (!_isDisposed && !_isPaid) {
      try {
        final latest = await ref.read(bookingServiceProvider).getBookingById(widget.bookingId);
        debugPrint('PAYMENT_POLLING: Booking #${widget.bookingId} status: "${latest.status}"');
        if (latest.status != null &&
            (latest.status!.toLowerCase() == 'chờ nhận phòng' ||
             latest.status!.toLowerCase() == 'đã thanh toán')) {
          if (_isDisposed) return;
          setState(() => _isPaid = true);
          await Future.delayed(const Duration(milliseconds: 1800));
          if (mounted && !_isDisposed) {
            context.go('/rooms');
          }
          break;
        }
      } catch (e) {
        debugPrint('PAYMENT_POLLING_ERROR: $e');
      }
      await Future.delayed(const Duration(seconds: 4));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    if (_isPaid) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F3FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'THANH TOÁN THÀNH CÔNG!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Đơn đặt phòng #${widget.bookingId} đã được\nxác nhận thanh toán qua ngân hàng.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textGray),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đang chuyển về trang chủ...',
                style: TextStyle(fontSize: 13, color: AppTheme.textGray),
              ),
            ],
          ),
        ),
      );
    }

    final qrUrl =
        'https://img.vietqr.io/image/TPB-00001041606-print.png'
        '?amount=${widget.totalAmount.toInt()}'
        '&addInfo=GENZ%20${widget.bookingId}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text('Thanh toán đặt phòng'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/rooms'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header booking info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDE7FF)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Đặt phòng thành công!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Mã đặt phòng: #${widget.bookingId}', style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phòng:', style: TextStyle(color: AppTheme.textGray)),
                      Text(widget.roomId, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(color: AppTheme.textGray)),
                      Text(
                        fmt.format(widget.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // QR section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDE7FF)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'QUÉT MÃ QR ĐỂ THANH TOÁN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textGray,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mở app ngân hàng và quét mã bên dưới',
                    style: TextStyle(fontSize: 12, color: AppTheme.textGray),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEDE7FF), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.network(
                      qrUrl,
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          width: 220,
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (ctx, err, _) => const SizedBox(
                        width: 220,
                        height: 80,
                        child: Center(child: Text('Không tải được mã QR', style: TextStyle(color: Colors.red))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text('Nội dung chuyển khoản bắt buộc:', style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
                        const SizedBox(height: 4),
                        Text(
                          'GENZ ${widget.bookingId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Auto-checking indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDE7FF)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Đang chờ xác nhận thanh toán tự động...',
                      style: TextStyle(fontSize: 13, color: AppTheme.textGray),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Skip button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.go('/rooms'),
                child: const Text('Thanh toán sau (về trang chủ)', style: TextStyle(color: AppTheme.textGray)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
