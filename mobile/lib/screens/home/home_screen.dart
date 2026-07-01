// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_bottom_nav_bar.dart';

import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Kỹ thuật "giả vô hạn": itemCount rất lớn, luôn lấy index % banners.length
  // để hiển thị đúng ảnh. Nhờ vậy PageView không cần nhảy (jump) về trang đầu
  // khi hết danh sách, tránh hiện tượng giật khi tự động chuyển hoặc vuốt liên tục.
  static const int _kInfiniteMultiplier = 10000;
  late final int _initialPage;
  late final PageController _bannerController;
  Timer? _bannerTimer;

  final List<String> comboImages = [
    'assets/images/Banner_combo_day.PNG',
    'assets/images/Banner_combo_night.PNG',
    'assets/images/Banner_combo_2h.PNG',
    'assets/images/Banner_combo_4h.PNG',
  ];
  late final int _comboInitialPage;
  final ScrollController _comboScrollController = ScrollController();
  double _comboCardWidth = 160; // sẽ được tính lại đúng theo màn hình khi build
  static const double _comboSpacing = 12;
  Timer? _comboTimer;

  @override
  void initState() {
    super.initState();
    // Căn initialPage là một số lớn, chia hết theo banners.length,
    // để index % banners.length == 0 ngay từ đầu (hiển thị đúng ảnh đầu tiên).
    final int totalItems = banners.length * _kInfiniteMultiplier;
    _initialPage = (totalItems ~/ 2) - ((totalItems ~/ 2) % banners.length);
    _bannerController = PageController(initialPage: _initialPage);

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      _bannerController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });

    final int comboTotalItems = comboImages.length * _kInfiniteMultiplier;
    _comboInitialPage = comboTotalItems ~/ 2; // chỉ dùng để tính tổng item, giữ tương thích

    _comboTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_comboScrollController.hasClients) return;
      final double target =
          _comboScrollController.offset + _comboCardWidth + _comboSpacing;
      _comboScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _comboTimer?.cancel();
    _comboScrollController.dispose();
    super.dispose();
  }

  void _onComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng đang được phát triển')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 16),
              _buildBanner(),
              const SizedBox(height: 16),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildSectionHeader('Combo HOT', context,
                  onViewMore: () => context.push('/rooms')),
              const SizedBox(height: 12),
              _buildComboHot(context),
              const SizedBox(height: 24),
              _buildSectionHeader('Đặc biệt', context,
                  onViewMore: () => context.push('/rooms')),
              const SizedBox(height: 12),
              _buildRoomTypesCard(context),
              const SizedBox(height: 12),
              _buildPlaceholderCard(context),
              const SizedBox(height: 12),
              _buildPlaceholderCard(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 40),
        Image.asset(
          'assets/images/logo.png',
          height: 48,
        ),
        IconButton(
          onPressed: () => _onComingSoon(context),
          icon: const Icon(Icons.notifications_none, size: 28, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  final List<String> banners = [
    'assets/images/Banner_01.png',
    'assets/images/Banner_combo_day.PNG',
    'assets/images/Banner_combo_night.PNG',
    'assets/images/Banner_combo_2h.PNG',
    'assets/images/Banner_combo_4h.PNG',
  ];

  Widget _buildBanner() {
    return SizedBox(
      height: 167,
      child: PageView.builder(
        controller: _bannerController,
        itemCount: banners.length * _kInfiniteMultiplier, // "giả vô hạn"
        itemBuilder: (context, index) {
          final int realIndex = index % banners.length;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.asset(
              banners[realIndex],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final items = [
      {'icon': Icons.credit_card, 'label': 'Voucher'},
      {'icon': Icons.inventory_2_outlined, 'label': 'Lịch sử'},
      {'icon': Icons.chat_bubble_outline, 'label': 'Feedback'},
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => _onComingSoon(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Icon(
                        item['icon'] as IconData,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontSize: 13,
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

  Widget _buildSectionHeader(String title, BuildContext context, {VoidCallback? onViewMore}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        if (onViewMore != null)
          GestureDetector(
            onTap: onViewMore,
            child: const Text(
              'Xem thêm',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildComboHot(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Hiển thị khoảng 2.3 banner trong khung nhìn (giống Figma: thấy đủ
        // banner thứ 2 và hé một phần banner thứ 3) -> cảm giác đang "trượt".
        const double visibleCount = 2.3;
        _comboCardWidth =
            (constraints.maxWidth - _comboSpacing * (visibleCount - 1)) /
                visibleCount;

        return SizedBox(
          height: 100,
          child: ListView.builder(
            controller: _comboScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: comboImages.length * _kInfiniteMultiplier, // giả vô hạn
            itemBuilder: (context, index) {
              final int realIndex = index % comboImages.length;
              return Padding(
                padding: EdgeInsets.only(right: _comboSpacing),
                child: GestureDetector(
                  onTap: () => context.push('/rooms'),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      comboImages[realIndex],
                      width: _comboCardWidth,
                      height: 100,
                      fit: BoxFit.cover,
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
        Expanded(child: _buildTypeCard(context, 'QUEEN', 'Phòng Queen', '96k/h',
            Icons.movie_outlined, 'Máy chiếu')),
        const SizedBox(width: 12),
        Expanded(child: _buildTypeCard(context, 'KING', 'Phòng King', '106k/h',
            Icons.tv_outlined, 'Máy chiếu + PC Couple')),
      ],
    );
  }

  Widget _buildTypeCard(BuildContext context, String typeId, String name,
      String price, IconData icon, String feature) {
    return GestureDetector(
      onTap: () => context.push('/rooms?type=$typeId'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            ShaderMask(
              shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
              child: Text(price,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
            const SizedBox(height: 4),
            Text(feature,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}
