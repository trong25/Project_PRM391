import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';

class StaffBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const StaffBottomNavBar({super.key, required this.currentIndex});

  static const _items = [
    {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Trang chủ'},
    {'icon': Icons.meeting_room_outlined, 'activeIcon': Icons.meeting_room, 'label': 'Phòng'},
    {'icon': Icons.credit_card_outlined, 'activeIcon': Icons.credit_card, 'label': 'Voucher'},
    {'icon': Icons.business_center_outlined, 'activeIcon': Icons.business_center, 'label': 'Đặt chỗ'},
    {'icon': Icons.chat_bubble_outline, 'activeIcon': Icons.chat_bubble, 'label': 'Feedback'},
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (index == 0) {
      context.go('/staff');
    } else if (index == 1) {
      context.go('/staff/rooms');
    } else if (index == 3) {
      context.go('/staff/bookings');
    } else if (index == 4) {
      context.go('/staff-feedback');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tính năng đang phát triển (Staff Only)'),
          duration: Duration(seconds: 1),
        ),
      );
    }
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
                  onTap: () => _onTap(context, index),
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
