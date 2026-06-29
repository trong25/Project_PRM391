// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

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

  void _onTapAccount(BuildContext context) {
    final user = ref.read(authProvider).user;
    final bool isLoggedIn = user != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              if (!isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.login, color: AppTheme.primary),
                  title: const Text('Đăng nhập'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/login');
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.person, color: AppTheme.primary),
                  title: const Text('Tài khoản'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/account');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppTheme.primaryDark),
                  title: const Text('Đăng xuất'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _onBottomNavTap(int index) {
    if (index == 3) {
      // Tài khoản
      _onTapAccount(context);
      return;
    }
    if (index == 0) {
      setState(() => _currentIndex = 0);
      return;
    }
    // Đã lưu, Đặt chỗ: để chờ
    _onComingSoon(context);
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
              _buildSectionHeader('Combo HOT', context),
              const SizedBox(height: 12),
              _buildComboHot(context),
              const SizedBox(height: 24),
              _buildSectionHeader('Đặc biệt', context),
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
      bottomNavigationBar: _buildBottomNavBar(),
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

  Widget _buildSectionHeader(String title, BuildContext context) {
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
                  onTap: () => _onComingSoon(context),
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
    return GestureDetector(
      onTap: () => _onComingSoon(context),
      child: Container(
        width: double.infinity,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Text(
          'Các Hạng Phòng',
          style: TextStyle(color: AppTheme.textPrimary),
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

  Widget _buildBottomNavBar() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Trang chủ'},
      {'icon': Icons.bookmark_border, 'activeIcon': Icons.bookmark, 'label': 'Đã lưu'},
      {'icon': Icons.work_outline, 'activeIcon': Icons.work, 'label': 'Đặt chỗ'},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Tài khoản'},
    ];

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
            children: List.generate(items.length, (index) {
              final bool isSelected = index == _currentIndex;
              final item = items[index];

              return Expanded(
                child: InkWell(
                  onTap: () => _onBottomNavTap(index),
                  child: isSelected
                      ? ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: _buildNavItemContent(
                      icon: item['activeIcon'] as IconData,
                      label: item['label'] as String,
                      color: Colors.white,
                    ),
                  )
                      : _buildNavItemContent(
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

  Widget _buildNavItemContent({
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