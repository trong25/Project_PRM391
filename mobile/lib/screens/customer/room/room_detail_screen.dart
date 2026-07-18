// lib/screens/customer/room/room_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../models/room_model.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/saved_rooms_provider.dart';
import '../../../widgets/app_bottom_nav_bar.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _imageController = PageController();

  final List<Map<String, dynamic>> _mockReviews = [
    {
      'userName': 'Nguyễn Văn Minh',
      'rating': 5,
      'comment':
          'Phòng rất đẹp, máy chiếu sắc nét, âm thanh cực hay. Không gian riêng tư, lý tưởng cho buổi xem phim lãng mạn. Nhân viên phục vụ nhiệt tình!',
      'date': '20/06/2025',
    },
    {
      'userName': 'Trần Thị Hương',
      'rating': 5,
      'comment':
          'Trải nghiệm tuyệt vời! Combo 2 giờ giá hợp lý mà chất lượng không thua gì rạp lớn. Điều hòa mát, ghế sofa êm, chắc chắn quay lại.',
      'date': '15/06/2025',
    },
    {
      'userName': 'Lê Hoàng Nam',
      'rating': 4,
      'comment':
          'Phòng sạch sẽ, setup đẹp. Máy chiếu tốt, nhìn chung rất đáng tiền. Phù hợp cho nhóm bạn 3-4 người xem phim cuối tuần.',
      'date': '10/06/2025',
    },
    {
      'userName': 'Phạm Thu Trang',
      'rating': 5,
      'comment':
          'Đặt phòng để tổ chức sinh nhật bí mật cho người yêu, nhân viên hỗ trợ chu đáo. Không gian ấm cúng, thích hợp cho các dịp đặc biệt.',
      'date': '05/06/2025',
    },
    {
      'userName': 'Bùi Anh Khoa',
      'rating': 4,
      'comment':
          'Âm thanh vòm rất đỉnh, cảm giác như đang xem tại rạp chuẩn. Netflix load nhanh, không bị giật lag. Chỉ tiếc là bãi giữ xe hơi chật.',
      'date': '01/06/2025',
    },
  ];

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  String _formatVND(double price) {
    final n = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) buf.write('.');
      buf.write(n[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(roomDetailProvider(widget.roomId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: detailState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            )
          : detailState.error != null
              ? _buildError(detailState.error!)
              : detailState.room == null
                  ? const SizedBox.shrink()
                  : _buildContent(detailState.room!),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (detailState.room != null && !detailState.isLoading)
            _buildBookButton(context),
          const AppBottomNavBar(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildContent(RoomModel room) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildImageCarousel(room)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPriceAndStatus(room),
                const SizedBox(height: 10),
                _buildRoomTitle(room),
                const SizedBox(height: 14),
                _buildAmenities(room),
                const SizedBox(height: 16),
                _buildRatingHeader(),
                const SizedBox(height: 12),
                ..._mockReviews.map(_buildReviewCard),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Image carousel ────────────────────────────────────────────────────────────
  Widget _buildImageCarousel(RoomModel room) {
    final List<String> images = room.imageUrls.isNotEmpty
        ? room.imageUrls
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList()
        : [
            if (room.imageUrl != null && room.imageUrl!.trim().isNotEmpty)
              room.imageUrl!.trim(),
          ];
    final int count = images.isEmpty ? 1 : images.length;
    final currentIndex =
        _currentImageIndex >= count ? count - 1 : _currentImageIndex;

    final savedIds = ref.watch(savedRoomsProvider);
    final isSaved = savedIds.contains(room.roomId ?? '');

    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imageController,
            itemCount: count,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, index) {
              if (images.isEmpty) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF0E8FF), Color(0xFFE0D0F8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.bedroom_parent_outlined,
                        size: 64, color: Color(0xFFCFB3F0)),
                  ),
                );
              }
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF0E8FF),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 48, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
          // Nút back
          Positioned(
            top: 44,
            left: 12,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    size: 20, color: AppTheme.textPrimary),
              ),
            ),
          ),
          // Nút save (kết nối với savedRoomsProvider)
          Positioned(
            top: 44,
            right: 12,
            child: GestureDetector(
              onTap: () {
                if (room.roomId != null) {
                  ref.read(savedRoomsProvider.notifier).toggle(room.roomId!);
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                  color: isSaved ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          // Dots indicator
          if (images.length > 1) ...[
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${currentIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == currentIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == currentIndex
                          ? AppTheme.primary
                          : Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Price & status ─────────────────────────────────────────────────────────
  Widget _buildPriceAndStatus(RoomModel room) {
    final isAvailable = room.status?.toLowerCase() == 'trống' ||
        room.status?.toLowerCase() == 'available';
    final price = room.typeRoom?.pricePerHour;
    final priceText = price != null ? '${_formatVND(price)} vnd' : 'Liên hệ';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(color: AppTheme.textPrimary),
            children: [
              TextSpan(
                text: priceText,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: '/giờ',
                style: TextStyle(fontSize: 14, color: AppTheme.textGray),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isAvailable
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFCE4EC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            room.status ?? 'N/A',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAvailable
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828),
            ),
          ),
        ),
      ],
    );
  }

  // ── Room title ─────────────────────────────────────────────────────────────
  Widget _buildRoomTitle(RoomModel room) {
    final typeName = room.typeRoom?.typeRoom ?? '';
    final address = room.hotel?.address ?? room.hotel?.name ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.nameRoom ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        if (typeName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            typeName,
            style: const TextStyle(fontSize: 13, color: AppTheme.textGray),
          ),
        ],
        if (address.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              ShaderMask(
                shaderCallback: (b) =>
                    AppTheme.primaryGradient.createShader(b),
                child: const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Amenities ──────────────────────────────────────────────────────────────
  Widget _buildAmenities(RoomModel room) {
    final typeId = room.typeRoom?.typeRoomId?.toUpperCase() ?? '';
    final amenities = typeId == 'KING'
        ? [
            {'icon': Icons.weekend_outlined, 'label': 'Sofa'},
            {'icon': Icons.ac_unit, 'label': 'Điều hòa'},
            {'icon': Icons.movie_outlined, 'label': 'Máy chiếu'},
            {'icon': Icons.computer_outlined, 'label': 'PC Couple'},
          ]
        : [
            {'icon': Icons.weekend_outlined, 'label': 'Sofa'},
            {'icon': Icons.ac_unit, 'label': 'Điều hòa'},
            {'icon': Icons.movie_outlined, 'label': 'Máy chiếu'},
            {'icon': Icons.sports_esports_outlined, 'label': 'Board Game'},
          ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: amenities
          .map(
            (a) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Icon(a['icon'] as IconData,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: 4),
                Text(
                  a['label'] as String,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textPrimary),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  // ── Rating header ──────────────────────────────────────────────────────────
  Widget _buildRatingHeader() {
    final avg = _mockReviews
            .map((r) => r['rating'] as int)
            .reduce((a, b) => a + b) /
        _mockReviews.length;

    return Row(
      children: [
        Text(
          avg.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.star, color: Color(0xFFFFC107), size: 20),
        const SizedBox(width: 6),
        Text(
          'Đánh giá (${_mockReviews.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Review card ────────────────────────────────────────────────────────────
  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3E5F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF3E5F5),
                child: ShaderMask(
                  shaderCallback: (b) =>
                      AppTheme.primaryGradient.createShader(b),
                  child: const Icon(Icons.person,
                      size: 20, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      review['date'] as String,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textGray),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < (review['rating'] as int)
                        ? Icons.star
                        : Icons.star_border,
                    color: const Color(0xFFFFC107),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'] as String,
            style: const TextStyle(fontSize: 13, color: AppTheme.textGray),
          ),
        ],
      ),
    );
  }

  // ── Book button ────────────────────────────────────────────────────────────
  Widget _buildBookButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              final room = ref.read(roomDetailProvider(widget.roomId)).room;
              if (room != null) {
                context.push('/rooms/${room.roomId}/booking', extra: room);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Đặt phòng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Không thể tải thông tin phòng',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref
                .read(roomDetailProvider(widget.roomId).notifier)
                .loadRoom(widget.roomId),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
