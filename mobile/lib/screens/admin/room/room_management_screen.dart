// lib/screens/admin/room/room_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_models.dart';
import '../../../models/room_model.dart';
import '../../../providers/room_provider.dart';
import '../widgets/admin_bottom_navigation.dart';
import 'room_form_screen.dart';

enum _RoomStatusFilter {
  all('Tất cả'),
  available('Trống'),
  occupied('Đang thuê'),
  maintenance('Bảo trì');

  final String label;
  const _RoomStatusFilter(this.label);
}

class RoomManagementScreen extends ConsumerStatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  ConsumerState<RoomManagementScreen> createState() =>
      _RoomManagementScreenState();
}

class _RoomManagementScreenState extends ConsumerState<RoomManagementScreen> {
  String _query = '';
  _RoomStatusFilter _filter = _RoomStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final hotelsAsync = ref.watch(hotelsProvider);
    final roomsAsync = ref.watch(roomsProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Phòng')),
      bottomNavigationBar: const AdminBottomNavigation(
        currentTab: AdminNavTab.rooms,
      ),
      body: hotelsAsync.when(
        data: (hotels) => roomsAsync.when(
          data: (rooms) {
            final branches = _buildBranchSummaries(hotels, rooms);
            final visibleBranches = branches
                .where((branch) => _matchesBranch(branch, _query, _filter))
                .toList();

            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  ref.refresh(hotelsProvider.future),
                  ref.refresh(roomsProvider(null).future),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _RoomHeader(
                    totalRooms: rooms.length,
                    availableRooms: rooms.where(_isAvailableRoom).length,
                    occupiedRooms: rooms.where(_isOccupiedRoom).length,
                    maintenanceRooms: rooms.where(_isMaintenanceRoom).length,
                  ),
                  const SizedBox(height: 16),
                  _RoomFilters(
                    hintText: 'Tìm chi nhánh hoặc phòng',
                    query: _query,
                    filter: _filter,
                    onQueryChanged: (value) => setState(() => _query = value),
                    onFilterChanged: (value) =>
                        setState(() => _filter = value),
                  ),
                  const SizedBox(height: 16),
                  if (branches.isEmpty)
                    const _EmptyState(message: 'Không có dữ liệu chi nhánh')
                  else if (visibleBranches.isEmpty)
                    const _EmptyState(message: 'Không tìm thấy chi nhánh phù hợp')
                  else
                    ...visibleBranches.map(
                      (branch) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BranchCard(
                          branch: branch,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    _BranchRoomsScreen(branch: branch),
                              ),
                            );
                            ref.invalidate(roomsProvider);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Lỗi tải phòng: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải chi nhánh: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoomFormScreen()),
          );
          ref.invalidate(roomsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm phòng'),
      ),
    );
  }
}

class _BranchRoomsScreen extends ConsumerStatefulWidget {
  final _BranchSummary branch;

  const _BranchRoomsScreen({required this.branch});

  @override
  ConsumerState<_BranchRoomsScreen> createState() => _BranchRoomsScreenState();
}

class _BranchRoomsScreenState extends ConsumerState<_BranchRoomsScreen> {
  String _query = '';
  _RoomStatusFilter _filter = _RoomStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider(widget.branch.hotelId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.branch.name)),
      body: roomsAsync.when(
        data: (rooms) {
          final visibleRooms = rooms
              .where((room) => _matchesRoom(room, _query, _filter))
              .toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(
              roomsProvider(widget.branch.hotelId).future,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _BranchSummaryPanel(
                  branch: widget.branch.copyWithRooms(rooms),
                ),
                const SizedBox(height: 16),
                _RoomFilters(
                  hintText: 'Tìm tên phòng hoặc loại phòng',
                  query: _query,
                  filter: _filter,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onFilterChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 16),
                if (rooms.isEmpty)
                  const _EmptyState(message: 'Chi nhánh này chưa có phòng')
                else if (visibleRooms.isEmpty)
                  const _EmptyState(message: 'Không tìm thấy phòng phù hợp')
                else
                  ...visibleRooms.map(
                    (room) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RoomTile(
                        room: room,
                        onEdit: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomFormScreen(room: room),
                            ),
                          );
                          ref.invalidate(roomsProvider(widget.branch.hotelId));
                          ref.invalidate(roomsProvider(null));
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải phòng: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoomFormScreen(
                initialHotelId: widget.branch.hotelId,
              ),
            ),
          );
          ref.invalidate(roomsProvider(widget.branch.hotelId));
          ref.invalidate(roomsProvider(null));
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm phòng'),
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  final int totalRooms;
  final int availableRooms;
  final int occupiedRooms;
  final int maintenanceRooms;

  const _RoomHeader({
    required this.totalRooms,
    required this.availableRooms,
    required this.occupiedRooms,
    required this.maintenanceRooms,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng quan phòng',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Theo dõi tình trạng phòng theo từng chi nhánh',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 560;
            final cards = [
              _MetricCard(
                label: 'Tổng phòng',
                value: totalRooms,
                icon: Icons.meeting_room,
                color: const Color(0xFF2563EB),
              ),
              _MetricCard(
                label: 'Trống',
                value: availableRooms,
                icon: Icons.check_circle_outline,
                color: const Color(0xFF0F766E),
              ),
              _MetricCard(
                label: 'Đang thuê',
                value: occupiedRooms,
                icon: Icons.key,
                color: const Color(0xFF7C3AED),
              ),
              _MetricCard(
                label: 'Bảo trì',
                value: maintenanceRooms,
                icon: Icons.build_outlined,
                color: const Color(0xFFB45309),
              ),
            ];

            if (isNarrow) {
              return GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.75,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: cards,
              );
            }

            return Row(
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  Expanded(child: cards[index]),
                  if (index < cards.length - 1) const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RoomFilters extends StatelessWidget {
  final String hintText;
  final String query;
  final _RoomStatusFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_RoomStatusFilter> onFilterChanged;

  const _RoomFilters({
    required this.hintText,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in _RoomStatusFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(option.label),
                    selected: filter == option,
                    onSelected: (_) => onFilterChanged(option),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BranchCard extends StatelessWidget {
  final _BranchSummary branch;
  final VoidCallback onTap;

  const _BranchCard({required this.branch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.apartment,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${branch.totalRooms} phòng',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 14),
              _RoomStatusProgress(branch: branch),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CountBadge(
                    label: 'Trống',
                    value: branch.availableRooms,
                    color: const Color(0xFF0F766E),
                  ),
                  _CountBadge(
                    label: 'Đang thuê',
                    value: branch.occupiedRooms,
                    color: const Color(0xFF7C3AED),
                  ),
                  _CountBadge(
                    label: 'Bảo trì',
                    value: branch.maintenanceRooms,
                    color: const Color(0xFFB45309),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchSummaryPanel extends StatelessWidget {
  final _BranchSummary branch;

  const _BranchSummaryPanel({required this.branch});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branch.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _RoomStatusProgress(branch: branch),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CountBadge(
                  label: 'Tổng',
                  value: branch.totalRooms,
                  color: const Color(0xFF2563EB),
                ),
                _CountBadge(
                  label: 'Trống',
                  value: branch.availableRooms,
                  color: const Color(0xFF0F766E),
                ),
                _CountBadge(
                  label: 'Đang thuê',
                  value: branch.occupiedRooms,
                  color: const Color(0xFF7C3AED),
                ),
                _CountBadge(
                  label: 'Bảo trì',
                  value: branch.maintenanceRooms,
                  color: const Color(0xFFB45309),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomStatusProgress extends StatelessWidget {
  final _BranchSummary branch;

  const _RoomStatusProgress({required this.branch});

  @override
  Widget build(BuildContext context) {
    if (branch.totalRooms == 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(height: 8, color: const Color(0xFFE5E7EB)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Row(
        children: [
          _ProgressSegment(
            value: branch.availableRooms,
            color: const Color(0xFF0F766E),
          ),
          _ProgressSegment(
            value: branch.occupiedRooms,
            color: const Color(0xFF7C3AED),
          ),
          _ProgressSegment(
            value: branch.maintenanceRooms,
            color: const Color(0xFFB45309),
          ),
          _ProgressSegment(
            value: branch.otherRooms,
            color: const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final int value;
  final Color color;

  const _ProgressSegment({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (value == 0) return const SizedBox.shrink();

    return Expanded(
      flex: value,
      child: Container(height: 8, color: color),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onEdit;

  const _RoomTile({required this.room, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(room);
    final typeName = room.typeRoomName?.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusStyle.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.bed, color: statusStyle.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.nameRoom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    typeName == null || typeName.isEmpty
                        ? 'Chưa có loại phòng'
                        : typeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(style: statusStyle),
            IconButton(
              tooltip: 'Sửa phòng',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _CountBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 72),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _StatusStyle style;

  const _StatusBadge({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  final String label;
  final Color color;

  const _StatusStyle(this.label, this.color);
}

class _BranchSummary {
  final String hotelId;
  final String name;
  final List<RoomModel> rooms;

  const _BranchSummary({
    required this.hotelId,
    required this.name,
    required this.rooms,
  });

  int get totalRooms => rooms.length;
  int get availableRooms => rooms.where(_isAvailableRoom).length;
  int get occupiedRooms => rooms.where(_isOccupiedRoom).length;
  int get maintenanceRooms => rooms.where(_isMaintenanceRoom).length;
  int get otherRooms =>
      totalRooms - availableRooms - occupiedRooms - maintenanceRooms;

  _BranchSummary copyWithRooms(List<RoomModel> nextRooms) {
    return _BranchSummary(
      hotelId: hotelId,
      name: name,
      rooms: nextRooms,
    );
  }
}

List<_BranchSummary> _buildBranchSummaries(
  List<HotelModel> hotels,
  List<RoomModel> rooms,
) {
  final branches = hotels.map((hotel) {
    final branchRooms = rooms
        .where((room) => room.hotelId == hotel.hotelId)
        .toList(growable: false);
    return _BranchSummary(
      hotelId: hotel.hotelId,
      name: hotel.name,
      rooms: branchRooms,
    );
  }).toList();

  final hotelIds = hotels.map((hotel) => hotel.hotelId).toSet();
  final roomsWithoutKnownHotel = rooms.where(
    (room) =>
        (room.hotelId ?? '').isNotEmpty && !hotelIds.contains(room.hotelId),
  );
  final fallbackGroups = <String, List<RoomModel>>{};

  for (final room in roomsWithoutKnownHotel) {
    fallbackGroups.putIfAbsent(room.hotelId!, () => []).add(room);
  }

  for (final entry in fallbackGroups.entries) {
    final branchRooms = entry.value;
    branches.add(
      _BranchSummary(
        hotelId: entry.key,
        name: branchRooms.first.hotelName ?? 'Chi nhánh chưa đặt tên',
        rooms: branchRooms,
      ),
    );
  }

  branches.sort((a, b) => a.name.compareTo(b.name));
  return branches;
}

bool _matchesBranch(
  _BranchSummary branch,
  String query,
  _RoomStatusFilter filter,
) {
  final normalizedQuery = query.trim().toLowerCase();
  final matchesQuery = normalizedQuery.isEmpty ||
      branch.name.toLowerCase().contains(normalizedQuery) ||
      branch.rooms.any((room) => _roomSearchText(room).contains(normalizedQuery));

  final matchesFilter =
      filter == _RoomStatusFilter.all || branch.rooms.any((room) {
        return _matchesStatusFilter(room, filter);
      });

  return matchesQuery && matchesFilter;
}

bool _matchesRoom(
  RoomModel room,
  String query,
  _RoomStatusFilter filter,
) {
  final normalizedQuery = query.trim().toLowerCase();
  final matchesQuery =
      normalizedQuery.isEmpty || _roomSearchText(room).contains(normalizedQuery);

  return matchesQuery && _matchesStatusFilter(room, filter);
}

bool _matchesStatusFilter(RoomModel room, _RoomStatusFilter filter) {
  return switch (filter) {
    _RoomStatusFilter.all => true,
    _RoomStatusFilter.available => _isAvailableRoom(room),
    _RoomStatusFilter.occupied => _isOccupiedRoom(room),
    _RoomStatusFilter.maintenance => _isMaintenanceRoom(room),
  };
}

String _roomSearchText(RoomModel room) {
  return [
    room.nameRoom,
    room.typeRoomName,
    room.hotelName,
    room.status,
  ].whereType<String>().join(' ').toLowerCase();
}

_StatusStyle _statusStyle(RoomModel room) {
  if (_isAvailableRoom(room)) {
    return const _StatusStyle('Trống', Color(0xFF0F766E));
  }
  if (_isOccupiedRoom(room)) {
    return const _StatusStyle('Đang thuê', Color(0xFF7C3AED));
  }
  if (_isMaintenanceRoom(room)) {
    return const _StatusStyle('Bảo trì', Color(0xFFB45309));
  }

  final label = (room.status ?? '').trim();
  return _StatusStyle(
    label.isEmpty ? 'Chưa rõ' : label,
    const Color(0xFF64748B),
  );
}

bool _isAvailableRoom(RoomModel room) {
  final status = _normalizedStatus(room);
  return status.contains('trong') ||
      status.contains('vacant') ||
      status.contains('available') ||
      status.contains('empty');
}

bool _isOccupiedRoom(RoomModel room) {
  final status = _normalizedStatus(room);
  return status.contains('dang thue') ||
      status.contains('da thue') ||
      status.contains('occupied') ||
      status.contains('booked') ||
      status.contains('using');
}

bool _isMaintenanceRoom(RoomModel room) {
  final status = _normalizedStatus(room);
  return status.contains('bao tri') ||
      status.contains('maintenance') ||
      status.contains('repair');
}

String _normalizedStatus(RoomModel room) {
  final status = (room.status ?? '').toLowerCase();
  return status
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ả', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('ạ', 'a')
      .replaceAll('ă', 'a')
      .replaceAll('ắ', 'a')
      .replaceAll('ằ', 'a')
      .replaceAll('ẳ', 'a')
      .replaceAll('ẵ', 'a')
      .replaceAll('ặ', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ấ', 'a')
      .replaceAll('ầ', 'a')
      .replaceAll('ẩ', 'a')
      .replaceAll('ẫ', 'a')
      .replaceAll('ậ', 'a')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ẻ', 'e')
      .replaceAll('ẽ', 'e')
      .replaceAll('ẹ', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ế', 'e')
      .replaceAll('ề', 'e')
      .replaceAll('ể', 'e')
      .replaceAll('ễ', 'e')
      .replaceAll('ệ', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ì', 'i')
      .replaceAll('ỉ', 'i')
      .replaceAll('ĩ', 'i')
      .replaceAll('ị', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ò', 'o')
      .replaceAll('ỏ', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ọ', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('ố', 'o')
      .replaceAll('ồ', 'o')
      .replaceAll('ổ', 'o')
      .replaceAll('ỗ', 'o')
      .replaceAll('ộ', 'o')
      .replaceAll('ơ', 'o')
      .replaceAll('ớ', 'o')
      .replaceAll('ờ', 'o')
      .replaceAll('ở', 'o')
      .replaceAll('ỡ', 'o')
      .replaceAll('ợ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('ủ', 'u')
      .replaceAll('ũ', 'u')
      .replaceAll('ụ', 'u')
      .replaceAll('ư', 'u')
      .replaceAll('ứ', 'u')
      .replaceAll('ừ', 'u')
      .replaceAll('ử', 'u')
      .replaceAll('ữ', 'u')
      .replaceAll('ự', 'u')
      .replaceAll('ý', 'y')
      .replaceAll('ỳ', 'y')
      .replaceAll('ỷ', 'y')
      .replaceAll('ỹ', 'y')
      .replaceAll('ỵ', 'y')
      .replaceAll('đ', 'd');
}
