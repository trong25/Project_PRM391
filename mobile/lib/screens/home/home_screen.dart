// lib/screens/home/home_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  static const int _kInfiniteMultiplier = 10000;
  static const double _comboSpacing = 12;

  final List<String> _banners = const [
    'assets/images/Banner_01.png',
    'assets/images/Banner_combo_day.PNG',
    'assets/images/Banner_combo_night.PNG',
    'assets/images/Banner_combo_2h.PNG',
    'assets/images/Banner_combo_4h.PNG',
  ];

  final List<String> _comboImages = const [
    'assets/images/Banner_combo_day.PNG',
    'assets/images/Banner_combo_night.PNG',
    'assets/images/Banner_combo_2h.PNG',
    'assets/images/Banner_combo_4h.PNG',
  ];

  late final PageController _bannerController;
  final ScrollController _comboScrollController = ScrollController();
  Timer? _bannerTimer;
  Timer? _comboTimer;
  double _comboCardWidth = 160;
  int _currentBannerIndex = 0;

  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    final totalItems = _banners.length * _kInfiniteMultiplier;
    final initialPage =
        (totalItems ~/ 2) - ((totalItems ~/ 2) % _banners.length);
    _bannerController = PageController(initialPage: initialPage);

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      _bannerController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });

    _bannerController.addListener(() {
      if (!mounted) return;
      final page = _bannerController.page ?? 0;
      final newIndex = page.round() % _banners.length;
      if (newIndex != _currentBannerIndex) {
        setState(() => _currentBannerIndex = newIndex);
      }
    });

    _comboTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_comboScrollController.hasClients) return;
      final target =
          _comboScrollController.offset + _comboCardWidth + _comboSpacing;
      _comboScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _comboTimer?.cancel();
    _comboScrollController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _onComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Chức năng đang được phát triển'),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0ECFF),
      body: Stack(
        children: [
          // Animated background blobs
          _buildBackgroundBlobs(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        _buildGreetingCard(context),
                        const SizedBox(height: 20),
                        _buildBanner(),
                        const SizedBox(height: 20),
                        _buildQuickActions(context),
                        const SizedBox(height: 28),
                        _buildSectionHeader(
                          'Combo HOT',
                          onViewMore: () => context.push('/rooms'),
                        ),
                        const SizedBox(height: 14),
                        _buildComboHot(context),
                        const SizedBox(height: 28),
                        _buildSectionHeader(
                          'Loại phòng',
                          onViewMore: () => context.push('/rooms'),
                        ),
                        const SizedBox(height: 14),
                        _buildRoomTypesCard(context),
                        const SizedBox(height: 14),
                        _buildPlaceholderCard(context),
                        const SizedBox(height: 14),
                        _buildPlaceholderCard(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildBackgroundBlobs() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: -60 + _floatAnim.value,
              right: -60,
              child: _blob(200, AppTheme.primary.withOpacity(0.12)),
            ),
            Positioned(
              top: 200 - _floatAnim.value,
              left: -80,
              child: _blob(180, AppTheme.primaryDark.withOpacity(0.08)),
            ),
            Positioned(
              bottom: 300 + _floatAnim.value,
              right: -40,
              child: _blob(140, AppTheme.primary.withOpacity(0.07)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo_transparent.png',
            height: 32,
            errorBuilder: (_, __, ___) => const Text(
              'LOGO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        // Notification button
        _AnimatedIconButton(
          onTap: () => _onComingSoon(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: AppTheme.textPrimary,
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6565),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingCard(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final name = user?.fullName ?? 'bạn';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Chào buổi sáng'
        : hour < 18
            ? 'Chào buổi chiều'
            : 'Chào buổi tối';
    final emoji = hour < 12
        ? '☀️'
        : hour < 18
            ? '🌤️'
            : '🌙';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9462FF), Color(0xFFBB85FF), Color(0xFFFF6565)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting $emoji',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name.split(' ').last,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Đặt phòng ngay thôi!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Column(
      children: [
        SizedBox(
          height: 178,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _banners.length * _kInfiniteMultiplier,
            itemBuilder: (context, index) {
              final realIndex = index % _banners.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.asset(
                  _banners[realIndex],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final isActive = i == _currentBannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: isActive ? AppTheme.primaryGradient : null,
                color: isActive ? null : Colors.grey.shade300,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final user = ref.read(authProvider).user;

    final isStaff =
        (user?.roleId?.toUpperCase() == AppConfig.roleStaff) ||
            (user?.role?.toUpperCase() == AppConfig.roleStaff);

    final items = [
      {
        'icon': Icons.confirmation_number_outlined,
        'label': 'Voucher',
        'gradient': const LinearGradient(
          colors: [Color(0xFF9462FF), Color(0xFFB87BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'onTap': () {
          context.push('/customer-voucher');
        },
      },
      {
        'icon': Icons.history_rounded,
        'label': 'Lịch sử',
        'gradient': const LinearGradient(
          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        'onTap': () {
          _onComingSoon(context);
        },

        'onTap': () => context.push('/history'),

      },
      {
        'icon': Icons.chat_bubble_rounded,
        'label': 'Feedback',
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF6565), Color(0xFFFF8F8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'onTap': () {
          if (isStaff) {
            context.push('/staff-feedback');
          } else {
            context.push('/customer-chat');
          }
        },
      },
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _AnimatedIconButton(
              onTap: item['onTap'] as VoidCallback,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: item['gradient'] as LinearGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (item['gradient'] as LinearGradient)
                                .colors
                                .first
                                .withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewMore}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        if (onViewMore != null)
          GestureDetector(
            onTap: onViewMore,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Xem thêm',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildComboHot(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const visibleCount = 2.3;
        _comboCardWidth =
            (constraints.maxWidth - _comboSpacing * (visibleCount - 1)) /
                visibleCount;

        return SizedBox(
          height: 108,
          child: ListView.builder(
            controller: _comboScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _comboImages.length * _kInfiniteMultiplier,
            itemBuilder: (context, index) {
              final realIndex = index % _comboImages.length;
              return Padding(
                padding: const EdgeInsets.only(right: _comboSpacing),
                child: _AnimatedIconButton(
                  onTap: () => context.push('/rooms'),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        _comboImages[realIndex],
                        width: _comboCardWidth,
                        height: 108,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRoomTypesCard(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            context,
            'QUEEN',
            'Phòng Queen',
            '96k/h',
            Icons.movie_outlined,
            'Máy chiếu',
            const LinearGradient(
              colors: [Color(0xFF9462FF), Color(0xFFBB85FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildTypeCard(
            context,
            'KING',
            'Phòng King',
            '106k/h',
            Icons.tv_outlined,
            'Máy chiếu + PC Couple',
            const LinearGradient(
              colors: [Color(0xFFFF6565), Color(0xFFFF9F9F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(
    BuildContext context,
    String typeId,
    String name,
    String price,
    IconData icon,
    String feature,
    LinearGradient gradient,
  ) {
    return _AnimatedIconButton(
      onTap: () => context.push('/rooms?type=$typeId'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              child: Text(
                price,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              feature,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _onComingSoon(context),
      child: Container(
        width: double.infinity,
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                color: AppTheme.primary.withOpacity(0.4), size: 20),
            const SizedBox(width: 8),
            Text(
              'Sắp ra mắt...',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primary.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated press effect for interactive widgets
class _AnimatedIconButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedIconButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      onTapCancel: () => _controller.forward(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
  }
}
