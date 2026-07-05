// lib/screens/staff/staff_room_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/room_model.dart';
import '../../providers/room_provider.dart';
import 'widgets/staff_bottom_nav_bar.dart';

class StaffRoomManagementScreen extends ConsumerStatefulWidget {
  const StaffRoomManagementScreen({super.key});

  @override
  ConsumerState<StaffRoomManagementScreen> createState() =>
      _StaffRoomManagementScreenState();
}

class _StaffRoomManagementScreenState
    extends ConsumerState<StaffRoomManagementScreen> {
  String _searchText = '';
  String _selectedFilter = 'Tất cả'; // Tất cả, Trống, Đang thuê, Dọn dẹp, Bảo trì

  final List<String> _filters = [
    'Tất cả',
    'Trống',
    'Đang thuê',
    'Dọn dẹp',
    'Bảo trì',
  ];

  @override
  Widget build(BuildContext context) {
    final roomListState = ref.watch(roomListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Quản lý trạng thái phòng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(roomListProvider.notifier).loadRooms(),
          ),
        ],
      ),
      bottomNavigationBar: const StaffBottomNavBar(currentIndex: 0),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo tên phòng hoặc mã phòng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toLowerCase();
                });
              },
            ),
          ),

          // Filters Tab/Chip Bar
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                    selectedColor: AppTheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.textGray,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Room List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.read(roomListProvider.notifier).loadRooms(),
              child: roomListState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : roomListState.error != null
                      ? Center(child: Text('Lỗi tải danh sách phòng: ${roomListState.error}'))
                      : _buildRoomList(roomListState.rooms),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(List<RoomModel> rooms) {
    // Filter list
    final filteredRooms = rooms.where((room) {
      final name = (room.nameRoom ?? '').toLowerCase();
      final id = room.roomId.toLowerCase();
      final isSearchMatch = name.contains(_searchText) || id.contains(_searchText);

      bool isFilterMatch = true;
      if (_selectedFilter != 'Tất cả') {
        isFilterMatch = (room.status ?? '').toLowerCase() == _selectedFilter.toLowerCase();
      }

      return isSearchMatch && isFilterMatch;
    }).toList();

    if (filteredRooms.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'Không tìm thấy phòng nào',
              style: TextStyle(color: AppTheme.textGray),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredRooms.length,
      itemBuilder: (context, index) {
        final room = filteredRooms[index];
        return _buildRoomCard(room);
      },
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final status = room.status ?? 'Trống';
    
    Color statusColor = Colors.grey;
    if (status.toLowerCase() == 'trống') statusColor = Colors.green.shade600;
    if (status.toLowerCase() == 'đang thuê') statusColor = Colors.orange.shade700;
    if (status.toLowerCase() == 'dọn dẹp') statusColor = Colors.blue.shade600;
    if (status.toLowerCase() == 'bảo trì') statusColor = Colors.red.shade600;

    final priceStr = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
        .format(room.typeRoom?.pricePerHour ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRoomDetails(room),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Room Type Indicator
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.meeting_room_outlined,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Room Stats info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng ${room.nameRoom ?? room.roomId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Loại: ${room.typeRoomName ?? 'Chưa xác định'}',
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đơn giá: $priceStr / giờ',
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Dropdown selector
              PopupMenuButton<String>(
                tooltip: 'Đổi trạng thái phòng nhanh',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
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
                onSelected: (newStatus) => _updateRoomStatus(room.roomId, newStatus),
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
      ),
    );
  }

  Future<void> _updateRoomStatus(String roomId, String status) async {
    try {
      await ref.read(roomServiceProvider).updateRoomStatus(roomId, status);
      ref.read(roomListProvider.notifier).loadRooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật phòng $roomId sang "$status"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật trạng thái phòng: $e')),
        );
      }
    }
  }

  void _showRoomDetails(RoomModel room) {
    showDialog(
      context: context,
      builder: (ctx) {
        final status = room.status ?? 'Trống';
        Color statusColor = Colors.grey;
        if (status.toLowerCase() == 'trống') statusColor = Colors.green.shade600;
        if (status.toLowerCase() == 'đang thuê') statusColor = Colors.orange.shade700;
        if (status.toLowerCase() == 'dọn dẹp') statusColor = Colors.blue.shade600;
        if (status.toLowerCase() == 'bảo trì') statusColor = Colors.red.shade600;

        final priceStr = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
            .format(room.typeRoom?.pricePerHour ?? 0);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chi tiết phòng ${room.nameRoom ?? room.roomId}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Status Chip Row
              Row(
                children: [
                  const Text('Trạng thái hiện tại: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Details
              _buildDialogDetailRow('Mã Phòng', room.roomId),
              _buildDialogDetailRow('Loại Phòng', room.typeRoomName ?? 'Chưa xác định'),
              _buildDialogDetailRow('Đơn giá theo giờ', '$priceStr / giờ'),
              
              const SizedBox(height: 20),
              const Text(
                'Thay đổi trạng thái phòng:',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),

              // Quick Action Status Buttons inside Dialog
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Trống', 'Đang thuê', 'Dọn dẹp', 'Bảo trì'].map((s) {
                  final bool isCurrent = s.toLowerCase() == status.toLowerCase();
                  Color btnColor = Colors.grey;
                  if (s == 'Trống') btnColor = Colors.green;
                  if (s == 'Đang thuê') btnColor = Colors.orange;
                  if (s == 'Dọn dẹp') btnColor = Colors.blue;
                  if (s == 'Bảo trì') btnColor = Colors.red;

                  return ChoiceChip(
                    label: Text(s),
                    selected: isCurrent,
                    selectedColor: btnColor.withOpacity(0.2),
                    onSelected: (selected) {
                      if (selected && !isCurrent) {
                        Navigator.pop(ctx); // Close dialog
                        _updateRoomStatus(room.roomId, s);
                      }
                    },
                    labelStyle: TextStyle(
                      color: isCurrent ? btnColor : AppTheme.textGray,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppTheme.textGray, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
