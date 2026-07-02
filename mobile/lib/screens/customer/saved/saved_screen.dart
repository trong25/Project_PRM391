// lib/screens/customer/saved/saved_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../models/room_model.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/saved_rooms_provider.dart';
import '../../../widgets/app_bottom_nav_bar.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedRoomsProvider);
    final roomState = ref.watch(roomListProvider);

    // Nếu danh sách phòng chưa tải, gọi load
    if (!roomState.isLoading && roomState.rooms.isEmpty && roomState.error == null) {
      Future.microtask(() => ref.read(roomListProvider.notifier).loadRooms());
    }

    final savedRooms = roomState.rooms
        .where((r) => savedIds.contains(r.roomId ?? ''))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              size: 18, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Phòng đã lưu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: roomState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            )
          : savedRooms.isEmpty
              ? _buildEmpty(context, savedIds.isEmpty)
              : _buildList(context, ref, savedRooms),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildEmpty(BuildContext context, bool nothingSaved) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child:
                const Icon(Icons.bookmark_border, size: 72, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có phòng nào được lưu',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn vào icon bookmark trên trang phòng\nđể lưu phòng yêu thích',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.push('/rooms'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Khám phá phòng',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<RoomModel> rooms) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (context, index) =>
          _buildSavedCard(context, ref, rooms[index]),
    );
  }

  Widget _buildSavedCard(
      BuildContext context, WidgetRef ref, RoomModel room) {
    final price = room.typeRoom?.pricePerHour;
    final priceText = price != null ? '${_formatVND(price)}k/h' : 'Liên hệ';
    final typeName = room.typeRoom?.typeRoom ?? '';
    final hotelName = room.hotel?.name ?? '';

    return GestureDetector(
      onTap: () => context.push('/rooms/${room.roomId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ảnh / placeholder
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF0E8FF), Color(0xFFE0D0F8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: room.imageUrl != null && room.imageUrl!.isNotEmpty
                    ? Image.network(room.imageUrl!, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(Icons.bedroom_parent_outlined,
                            size: 36, color: Color(0xFFCFB3F0)),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.nameRoom ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (typeName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(typeName,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textGray)),
                      ),
                    if (hotelName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(hotelName,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    const SizedBox(height: 6),
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppTheme.primaryGradient.createShader(b),
                      child: Text(
                        priceText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Remove bookmark
            IconButton(
              icon: const Icon(Icons.bookmark,
                  color: AppTheme.primary, size: 22),
              onPressed: () {
                if (room.roomId != null) {
                  ref.read(savedRoomsProvider.notifier).toggle(room.roomId!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatVND(double price) {
    // 96000 → "96.000" but for card display show as "96k"
    return (price / 1000).toStringAsFixed(0);
  }
}
