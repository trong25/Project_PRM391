// lib/screens/customer/room/room_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../models/room_model.dart';
import '../../../providers/room_provider.dart';
import '../../../widgets/app_bottom_nav_bar.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  final String? typeFilter;
  const RoomListScreen({super.key, this.typeFilter});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ── Filter state ───────────────────────────────────────────────────────────
  String? _selectedTypeId;   // 'QUEEN' | 'KING' | null
  String? _selectedHotelId;  // hotelId | null
  String? _selectedPriceRange; // 'low' | 'high' | null

  @override
  void initState() {
    super.initState();
    _selectedTypeId = widget.typeFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roomListProvider.notifier).loadRooms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────
  List<RoomModel> _filterRooms(List<RoomModel> rooms) {
    var result = rooms;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((r) =>
          r.nameRoom.toLowerCase().contains(q) ||
          (r.typeRoom?.typeRoom.toLowerCase().contains(q) ?? false) ||
          (r.hotel?.address.toLowerCase().contains(q) ?? false) ||
          (r.hotel?.name.toLowerCase().contains(q) ?? false)).toList();
    }

    if (_selectedTypeId != null) {
      result = result
          .where((r) => r.typeRoom?.typeRoomId == _selectedTypeId)
          .toList();
    }

    if (_selectedHotelId != null) {
      result =
          result.where((r) => r.hotel?.hotelId == _selectedHotelId).toList();
    }

    if (_selectedPriceRange != null) {
      result = result.where((r) {
        final price = r.typeRoom?.pricePerHour ?? 0;
        return _selectedPriceRange == 'low' ? price < 100000 : price >= 100000;
      }).toList();
    }

    return result;
  }

  bool get _hasActiveFilter =>
      _selectedTypeId != null ||
      _selectedHotelId != null ||
      _selectedPriceRange != null;

  void _clearAllFilters() {
    setState(() {
      _selectedTypeId = null;
      _selectedHotelId = null;
      _selectedPriceRange = null;
    });
  }

  // ── Filter bottom sheets ───────────────────────────────────────────────────
  void _showBranchFilter(List<RoomModel> rooms) {
    final hotels = <String, String>{};
    for (final r in rooms) {
      if (r.hotel != null) hotels[r.hotel!.hotelId] = r.hotel!.name;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        title: 'Chi nhánh',
        options: [
          const _FilterOption(value: null, label: 'Tất cả chi nhánh'),
          ...hotels.entries.map((e) => _FilterOption(value: e.key, label: e.value)),
        ],
        selected: _selectedHotelId,
        onSelect: (v) => setState(() => _selectedHotelId = v),
      ),
    );
  }

  void _showTypeFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        title: 'Loại phòng',
        options: const [
          _FilterOption(value: null, label: 'Tất cả'),
          _FilterOption(value: 'QUEEN', label: 'Phòng Queen  •  96k/h'),
          _FilterOption(value: 'KING', label: 'Phòng King  •  106k/h'),
        ],
        selected: _selectedTypeId,
        onSelect: (v) => setState(() => _selectedTypeId = v),
      ),
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        title: 'Mức giá',
        options: const [
          _FilterOption(value: null, label: 'Tất cả mức giá'),
          _FilterOption(value: 'low', label: 'Dưới 100k/h  (Phòng Queen)'),
          _FilterOption(value: 'high', label: 'Từ 100k/h  (Phòng King)'),
        ],
        selected: _selectedPriceRange,
        onSelect: (v) => setState(() => _selectedPriceRange = v),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomListProvider);
    final filtered = _filterRooms(roomState.rooms);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilterRow(roomState.rooms),
            if (_hasActiveFilter) _buildActiveFilterBar(),
            Expanded(
              child: roomState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppTheme.primary)))
                  : roomState.error != null
                      ? _buildError(roomState.error!)
                      : filtered.isEmpty
                          ? _buildEmpty()
                          : _buildRoomGrid(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon:
                Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(List<RoomModel> allRooms) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _filterChip(
            label: 'Chi nhánh',
            active: _selectedHotelId != null,
            onTap: () => _showBranchFilter(allRooms),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Loại phòng',
            active: _selectedTypeId != null,
            onTap: _showTypeFilter,
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Mức giá',
            active: _selectedPriceRange != null,
            onTap: _showPriceFilter,
          ),
          const Spacer(),
          GestureDetector(
            onTap: _hasActiveFilter ? _clearAllFilters : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: _hasActiveFilter ? AppTheme.primaryGradient : null,
                color: _hasActiveFilter ? null : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _hasActiveFilter ? Icons.filter_alt : Icons.tune,
                color: _hasActiveFilter ? Colors.white : Colors.grey.shade500,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: active ? AppTheme.primaryGradient : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? Colors.transparent : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: active ? Colors.white : AppTheme.textPrimary,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal)),
            const SizedBox(width: 4),
            Icon(
              active ? Icons.check : Icons.keyboard_arrow_down,
              size: 14,
              color: active ? Colors.white : AppTheme.textGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterBar() {
    final parts = <String>[];
    if (_selectedTypeId != null)
      parts.add(_selectedTypeId == 'QUEEN' ? 'Queen' : 'King');
    if (_selectedHotelId != null) parts.add('1 chi nhánh');
    if (_selectedPriceRange != null)
      parts.add(_selectedPriceRange == 'low' ? '< 100k/h' : '≥ 100k/h');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text('Đang lọc: ${parts.join(' · ')}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ),
          GestureDetector(
            onTap: _clearAllFilters,
            child: const Text('Xóa tất cả',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomGrid(List<RoomModel> rooms) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) => _buildRoomCard(context, rooms[index]),
    );
  }

  Widget _buildRoomImage(String? imageUrl) {
    const radius = BorderRadius.vertical(top: Radius.circular(12));
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (_, child, prog) {
            if (prog == null) return child;
            return Container(
              decoration: const BoxDecoration(
                  borderRadius: radius, color: Color(0xFFF8E8FF)),
              child: Center(
                child: CircularProgressIndicator(
                  value: prog.expectedTotalBytes != null
                      ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(radius),
        ),
      );
    }
    return _buildImagePlaceholder(radius);
  }

  Widget _buildImagePlaceholder(BorderRadius radius) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: [Color(0xFFF8E8FF), Color(0xFFEDD5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: const Icon(Icons.bedroom_parent_outlined,
              size: 40, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    final typeLabel = room.typeRoom?.typeRoom ?? 'Phòng';
    final address = room.hotel?.address ?? room.hotel?.name ?? 'N/A';
    final price = room.typeRoom?.pricePerHour;
    final priceText =
        price != null ? '${(price / 1000).toStringAsFixed(0)}k/h' : '';

    return GestureDetector(
      onTap: () => context.push('/rooms/${room.roomId}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3E5F5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildRoomImage(room.imageUrl)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${room.nameRoom} - $typeLabel',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: Text(priceText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 10, color: AppTheme.textGray),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(address,
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Không thể tải danh sách phòng',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(roomListProvider.notifier).loadRooms(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilter
                ? 'Không có phòng nào phù hợp'
                : 'Không tìm thấy phòng nào',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          if (_hasActiveFilter) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text('Xóa bộ lọc',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Reusable filter bottom sheet ───────────────────────────────────────────────
class _FilterOption {
  final String? value;
  final String label;
  const _FilterOption({required this.value, required this.label});
}

class _FilterSheet extends StatefulWidget {
  final String title;
  final List<_FilterOption> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _FilterSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            // Scrollable options list
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.options.map((opt) => _buildOption(opt)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Fixed apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSelect(_current);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Áp dụng',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(_FilterOption opt) {
    final isSelected = _current == opt.value;
    return InkWell(
      onTap: () => setState(() => _current = opt.value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(opt.label,
                  style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal)),
            ),
            if (isSelected)
              ShaderMask(
                shaderCallback: (b) =>
                    AppTheme.primaryGradient.createShader(b),
                child: const Icon(Icons.check_circle,
                    color: Colors.white, size: 20),
              )
            else
              Icon(Icons.circle_outlined,
                  color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}
