import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/booking_model.dart';
import '../../models/room_model.dart';
import '../../models/discount_code_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/discount_code_provider.dart';
import 'widgets/staff_bottom_nav_bar.dart';

class StaffBookingManagementScreen extends ConsumerStatefulWidget {
  const StaffBookingManagementScreen({super.key});

  @override
  ConsumerState<StaffBookingManagementScreen> createState() =>
      _StaffBookingManagementScreenState();
}

class _StaffBookingManagementScreenState
    extends ConsumerState<StaffBookingManagementScreen> {
  String _searchText = '';
  String _selectedFilter = 'Tất cả'; // Tất cả, Chờ nhận phòng, Đang thuê, Đã trả phòng, Đã hủy

  final List<String> _filters = [
    'Tất cả',
    'Chờ nhận phòng',
    'Đang thuê',
    'Đã trả phòng',
    'Đã hủy'
  ];

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(allBookingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Quản lý Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Tạo booking mới',
            icon: ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: const Icon(Icons.add_circle, color: Colors.white, size: 28),
            ),
            onPressed: () => _showCreateBookingDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: const StaffBottomNavBar(currentIndex: 3),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo mã phòng hoặc mã khách...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textGray),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                fillColor: AppTheme.surface,
                filled: true,
              ),
              onChanged: (val) {
                setState(() {
                  _searchText = val.trim().toLowerCase();
                });
              },
            ),
          ),

          // Horizontal Filter Chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surface,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Bookings List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(allBookingsProvider),
              child: bookingsAsync.when(
                data: (bookings) {
                  // Filter list
                  var filteredList = bookings.where((b) {
                    final room = ref.read(roomListProvider).rooms.firstWhere(
                          (r) => r.roomId == b.roomId,
                          orElse: () => RoomModel(roomId: b.roomId, nameRoom: b.roomId, status: 'Chưa xác định'),
                        );
                    final isRoomOccupied = (room.status ?? '').toLowerCase() == 'đang thuê';

                    // Match Search Text
                    final roomMatch = b.roomId.toLowerCase().contains(_searchText);
                    final userMatch = b.userId.toLowerCase().contains(_searchText);
                    final isSearchMatch = roomMatch || userMatch;

                    // Match Filter Type
                    bool isFilterMatch = true;
                    if (_selectedFilter == 'Chờ nhận phòng') {
                      isFilterMatch = b.status == 'Chưa thanh toán' || b.status == 'Chờ nhận phòng';
                    } else if (_selectedFilter == 'Đang thuê') {
                      isFilterMatch = b.status == 'Đang ở';
                    } else if (_selectedFilter == 'Đã trả phòng') {
                      isFilterMatch = b.status == 'Đã thanh toán';
                    } else if (_selectedFilter == 'Đã hủy') {
                      isFilterMatch = b.status == 'Đã hủy';
                    }

                    return isSearchMatch && isFilterMatch;
                  }).toList();

                  // Sort by Booking ID descending
                  filteredList.sort((a, b) => (b.bookingId ?? 0).compareTo(a.bookingId ?? 0));

                  if (filteredList.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'Không tìm thấy booking nào',
                            style: TextStyle(color: AppTheme.textGray),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final booking = filteredList[index];
                      return _buildBookingCard(context, booking);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Lỗi tải danh sách: $err', textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    final room = ref.watch(roomListProvider).rooms.firstWhere(
          (r) => r.roomId == booking.roomId,
          orElse: () => RoomModel(roomId: booking.roomId, nameRoom: booking.roomId, status: 'Chưa xác định'),
        );
    final String roomStatus = room.status ?? 'Chưa xác định';
    final bool isRoomOccupied = roomStatus.toLowerCase() == 'đang thuê';
    final bool isUnpaid = booking.status == 'Chưa thanh toán' || booking.status == 'Chờ nhận phòng' || booking.status == 'Đang ở';
    final bool canCheckIn = booking.status == 'Chưa thanh toán' || booking.status == 'Chờ nhận phòng';
    final bool canCheckOut = booking.status == 'Đang ở';
    final bool canCancel = booking.status == 'Chưa thanh toán' || booking.status == 'Chờ nhận phòng';

    // Status colors and labels
    Color statusBgColor = Colors.grey.shade100;
    Color statusTextColor = AppTheme.textGray;
    String displayStatus = booking.status ?? 'Chờ nhận phòng';

    if (booking.status == 'Đang ở') {
      displayStatus = 'Đang thuê';
      statusBgColor = const Color(0xFFFFF7ED);
      statusTextColor = const Color(0xFFF97316);
    } else if (booking.status == 'Chờ nhận phòng' || booking.status == 'Chưa thanh toán') {
      displayStatus = 'Chờ nhận phòng';
      statusBgColor = const Color(0xFFEFF6FF);
      statusTextColor = const Color(0xFF3B82F6);
    } else if (booking.status == 'Đã thanh toán') {
      displayStatus = 'Đã trả phòng';
      statusBgColor = const Color(0xFFECFDF5);
      statusTextColor = const Color(0xFF10B981);
    } else if (booking.status == 'Đã hủy') {
      displayStatus = 'Đã hủy';
      statusBgColor = const Color(0xFFFEF2F2);
      statusTextColor = const Color(0xFFEF4444);
    }

    final String checkInStr = DateFormat('dd/MM/yyyy HH:mm').format(booking.checkIn);
    final String checkOutStr = booking.checkOut != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(booking.checkOut!)
        : 'Chưa xác định';
    final String priceStr = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
        .format(booking.totalPrice ?? 0);

    Color roomStatusColor = Colors.grey.shade600;
    if (roomStatus.toLowerCase() == 'trống') roomStatusColor = Colors.green.shade600;
    if (roomStatus.toLowerCase() == 'đang thuê') roomStatusColor = Colors.orange.shade700;
    if (roomStatus.toLowerCase() == 'dọn dẹp') roomStatusColor = Colors.blue.shade600;
    if (roomStatus.toLowerCase() == 'bảo trì') roomStatusColor = Colors.red.shade600;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: ID & Delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mã Đặt: #${booking.bookingId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          color: statusTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isUnpaid) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                        onPressed: () => _showEditBookingDialog(context, booking),
                      ),
                      const SizedBox(width: 4),
                    ],
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                      onPressed: () => _confirmDeleteBooking(context, booking.bookingId),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),

            // Content Rows
            Row(
              children: [
                const Icon(Icons.meeting_room_outlined, size: 18, color: AppTheme.textGray),
                const SizedBox(width: 8),
                const Text('Phòng:', style: TextStyle(color: AppTheme.textGray, fontSize: 13)),
                const SizedBox(width: 6),
                Text(booking.roomId, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  enabled: isUnpaid,
                  tooltip: isUnpaid ? 'Đổi trạng thái phòng thủ công' : 'Đơn đã hoàn thành/hủy, không thể đổi trạng thái phòng',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: roomStatusColor.withOpacity(0.1),
                      border: Border.all(color: roomStatusColor, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          roomStatus,
                          style: TextStyle(color: roomStatusColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        if (isUnpaid) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, size: 14, color: roomStatusColor),
                        ],
                      ],
                    ),
                  ),
                  onSelected: (newStatus) async {
                    try {
                      await ref.read(roomServiceProvider).updateRoomStatus(booking.roomId, newStatus);
                      ref.read(roomListProvider.notifier).loadRooms();
                      ref.invalidate(allBookingsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã cập nhật phòng ${booking.roomId} sang "$newStatus"')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi cập nhật trạng thái phòng: $e')),
                        );
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'Trống', child: Text('Trống')),
                    const PopupMenuItem(value: 'Đang thuê', child: Text('Đang thuê')),
                    const PopupMenuItem(value: 'Dọn dẹp', child: Text('Dọn dẹp')),
                    const PopupMenuItem(value: 'Bảo trì', child: Text('Bảo trì')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildDetailRow(Icons.person_outline, 'Mã Khách:', booking.userId),
            const SizedBox(height: 6),
            _buildDetailRow(Icons.login, 'Nhận Phòng:', checkInStr),
            const SizedBox(height: 6),
            _buildDetailRow(Icons.logout, 'Trả Phòng:', checkOutStr),
            const SizedBox(height: 6),
            _buildDetailRow(
              Icons.payments_outlined,
              'Tổng Tiền:',
              priceStr,
              valueColor: AppTheme.primaryDark,
              isBold: true,
            ),
            if (booking.note != null && booking.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildDetailRow(Icons.note_alt_outlined, 'Ghi chú:', booking.note!),
            ],

            // Action Buttons
            if (canCheckIn || canCheckOut || canCancel) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canCancel)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () => _confirmCancel(context, booking.bookingId),
                      child: const Text('Hủy'),
                    ),
                  const SizedBox(width: 8),
                  if (canCheckIn)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: () => _confirmCheckIn(context, booking.bookingId),
                      child: const Text('Nhận Phòng'),
                    ),
                  if (canCheckOut)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: () => _showCheckoutInvoiceModal(context, booking),
                      child: const Text('Trả Phòng'),
                    ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textGray),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textGray, fontSize: 13),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --- ACTIONS ---

  Future<void> _updateBookingStatus(int? bookingId, String status) async {
    if (bookingId == null) return;
    try {
      await ref.read(bookingServiceProvider).updateBookingStatus(bookingId, status);
      ref.invalidate(allBookingsProvider);
      ref.read(roomListProvider.notifier).loadRooms(); // refresh free rooms count
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái sang "$status"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật trạng thái: $e')),
        );
      }
    }
  }

  Future<void> _confirmCheckIn(BuildContext context, int? bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận nhận phòng'),
        content: const Text('Bạn có chắc chắn muốn cho khách nhận phòng này? Trạng thái phòng sẽ chuyển sang "Đang thuê".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (bookingId != null) {
        await _updateBookingStatus(bookingId, 'Đang ở');
      }
    }
  }

  Future<void> _confirmCancel(BuildContext context, int? bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đặt phòng'),
        content: const Text('Bạn có chắc chắn muốn hủy đặt phòng này? Trạng thái phòng tương ứng sẽ được trả về "Trống".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy đặt phòng'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _updateBookingStatus(bookingId, 'Đã hủy');
    }
  }

  Future<void> _showCheckoutInvoiceModal(BuildContext context, BookingModel booking) async {
    final String checkInStr = DateFormat('dd/MM/yyyy HH:mm').format(booking.checkIn);
    final String checkOutStr = booking.checkOut != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(booking.checkOut!)
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final double basePrice = booking.totalPrice ?? 0;
    final double discount = booking.discountAmount ?? 0;
    final double finalAmount = (basePrice - discount).clamp(0.0, double.infinity);

    // Khách đã thanh toán trước qua app → kiểm tra marker trong note
    // Dùng note thay vì status vì status có thể đã đổi sang "Đang ở" sau check-in
    final bool isPrepaid = booking.note?.contains('[PREPAID_ONLINE]') == true;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _CheckoutInvoiceDialog(
          booking: booking,
          checkInStr: checkInStr,
          checkOutStr: checkOutStr,
          basePrice: basePrice,
          discount: discount,
          finalAmount: finalAmount,
          isPrepaid: isPrepaid,
        ),
      ),
    );

    if (confirm == true) {
      _updateBookingStatus(booking.bookingId, 'Đã thanh toán');
    }
  }

  Widget _buildInvoiceRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteBooking(BuildContext context, int? bookingId) async {
    if (bookingId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa lịch sử đặt phòng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(bookingServiceProvider).deleteBooking(bookingId);
        ref.invalidate(allBookingsProvider);
        ref.read(roomListProvider.notifier).loadRooms();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa booking thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa booking: $e')),
          );
        }
      }
    }
  }

  // Dialog to create a booking for walk-in guest
  void _showCreateBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _CreateBookingDialogContent(),
    ).then((success) {
      if (success == true) {
        ref.invalidate(allBookingsProvider);
        ref.read(roomListProvider.notifier).loadRooms();
      }
    });
  }

  void _showEditBookingDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditBookingDialogContent(booking: booking),
    ).then((success) {
      if (success == true) {
        ref.invalidate(allBookingsProvider);
        ref.read(roomListProvider.notifier).loadRooms();
      }
    });
  }
}

class _CreateBookingDialogContent extends ConsumerStatefulWidget {
  const _CreateBookingDialogContent();

  @override
  ConsumerState<_CreateBookingDialogContent> createState() =>
      __CreateBookingDialogContentState();
}

class __CreateBookingDialogContentState
    extends ConsumerState<_CreateBookingDialogContent> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRoomId;
  String _customerName = '';
  String _customerPhone = '';
  String _selectedComboId = 'TB_2H';

  DateTime _checkInDate = DateTime.now();
  TimeOfDay _checkInTime = TimeOfDay.now();
  DateTime _checkOutDate = DateTime.now();
  TimeOfDay _checkOutTime = TimeOfDay.now();

  double _price = 0.0;
  double _basePrice = 0.0;
  String _voucherCode = '';
  double _discountAmount = 0.0;
  String _noteInput = '';
  bool _submitting = false;

  late final TextEditingController _priceController;

  final List<Map<String, String>> _combos = [
    {'id': 'TB_2H', 'name': 'Combo 2h xem phim + đồ ăn'},
    {'id': 'TB_4H', 'name': 'Combo 4h'},
    {'id': 'TB_5H', 'name': 'Combo 5h'},
    {'id': 'TB_6H', 'name': 'Combo 6h'},
    {'id': 'TB_DAY', 'name': 'Combo ngày 7h-12h'},
    {'id': 'TB_NIGHT', 'name': 'Combo đêm 23h-7h'},
    {'id': 'TB001', 'name': 'Thuê theo giờ'},
    {'id': 'TB002', 'name': 'Qua đêm'},
    {'id': 'TB003', 'name': 'Thuê nguyên ngày'},
    {'id': 'TB004', 'name': 'Thuê theo tuần'},
  ];

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: '0');
    final roomListState = ref.read(roomListProvider);
    if (roomListState.rooms.isNotEmpty) {
      _selectedRoomId = roomListState.rooms.first.roomId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculateCheckout();
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  int? _getComboDurationHours(String comboId) {
    switch (comboId) {
      case 'TB_2H': return 2;
      case 'TB_4H': return 4;
      case 'TB_5H': return 5;
      case 'TB_6H': return 6;
      case 'TB_DAY': return 5;
      case 'TB_NIGHT': return 8;
      case 'TB002': return 12;
      case 'TB003': return 24;
      case 'TB004': return 168;
      case 'TB001':
      default:
        return null;
    }
  }

  void _recalculateCheckout() {
    final cin = DateTime(
      _checkInDate.year,
      _checkInDate.month,
      _checkInDate.day,
      _checkInTime.hour,
      _checkInTime.minute,
    );

    if (_selectedComboId == 'TB_DAY') {
      _checkInTime = const TimeOfDay(hour: 7, minute: 0);
      final cout = DateTime(
        _checkInDate.year,
        _checkInDate.month,
        _checkInDate.day,
        12,
        0,
      );
      _checkOutDate = cout;
      _checkOutTime = const TimeOfDay(hour: 12, minute: 0);
    } else if (_selectedComboId == 'TB_NIGHT') {
      _checkInTime = const TimeOfDay(hour: 23, minute: 0);
      final cout = DateTime(
        _checkInDate.year,
        _checkInDate.month,
        _checkInDate.day,
        23,
        0,
      ).add(const Duration(hours: 8));
      _checkOutDate = cout;
      _checkOutTime = const TimeOfDay(hour: 7, minute: 0);
    } else {
      final duration = _getComboDurationHours(_selectedComboId);
      if (duration != null) {
        final cout = cin.add(Duration(hours: duration));
        _checkOutDate = cout;
        _checkOutTime = TimeOfDay.fromDateTime(cout);
      } else {
        final cout = DateTime(
          _checkOutDate.year,
          _checkOutDate.month,
          _checkOutDate.day,
          _checkOutTime.hour,
          _checkOutTime.minute,
        );
        if (!cout.isAfter(cin)) {
          final newCout = cin.add(const Duration(hours: 2));
          _checkOutDate = newCout;
          _checkOutTime = TimeOfDay.fromDateTime(newCout);
        }
      }
    }
    _recalculatePrice();
  }

  void _recalculatePrice() {
    if (_selectedRoomId == null) return;
    
    final roomListState = ref.read(roomListProvider);
    final room = roomListState.rooms.firstWhere(
      (r) => r.roomId == _selectedRoomId,
      orElse: () => roomListState.rooms.first,
    );
    final hourlyPrice = room.typeRoom?.pricePerHour ?? 96000;

    final cin = DateTime(
      _checkInDate.year,
      _checkInDate.month,
      _checkInDate.day,
      _checkInTime.hour,
      _checkInTime.minute,
    );

    final cout = DateTime(
      _checkOutDate.year,
      _checkOutDate.month,
      _checkOutDate.day,
      _checkOutTime.hour,
      _checkOutTime.minute,
    );

    double basePrice = 0.0;
    if (_selectedComboId == 'TB_2H') {
      basePrice = (hourlyPrice * 2).toDouble();
    } else if (_selectedComboId == 'TB_DAY') {
      basePrice = 196000;
    } else if (_selectedComboId == 'TB_NIGHT') {
      basePrice = 296000;
    } else {
      final fixedDur = _getComboDurationHours(_selectedComboId);
      if (fixedDur != null) {
        basePrice = (hourlyPrice * fixedDur).toDouble();
      } else {
        final diffMs = cout.difference(cin).inMilliseconds;
        final hours = diffMs / (1000 * 60 * 60);
        final finalHours = hours.clamp(0.5, double.infinity);
        basePrice = hourlyPrice * finalHours;
      }
    }

    setState(() {
      _basePrice = basePrice;
      _price = (basePrice - _discountAmount).clamp(0.0, double.infinity);
      _priceController.text = _price.toStringAsFixed(0);
    });
  }

  double _calculateRoomTotal(RoomModel room) {
    final hourlyPrice = room.typeRoom?.pricePerHour ?? 96000;
    final duration = _getComboDurationHours(_selectedComboId);
    if (duration != null) {
      return (hourlyPrice * duration).toDouble();
    } else {
      final cin = DateTime(
        _checkInDate.year,
        _checkInDate.month,
        _checkInDate.day,
        _checkInTime.hour,
        _checkInTime.minute,
      );
      final cout = DateTime(
        _checkOutDate.year,
        _checkOutDate.month,
        _checkOutDate.day,
        _checkOutTime.hour,
        _checkOutTime.minute,
      );
      final diffMs = cout.difference(cin).inMilliseconds;
      final hours = diffMs / (1000 * 60 * 60);
      final finalHours = hours.clamp(0.5, double.infinity);
      return hourlyPrice * finalHours;
    }
  }

  double _calculateComboDiscount(RoomModel room) {
    final roomTotalVal = _calculateRoomTotal(room);
    final hourlyPrice = room.typeRoom?.pricePerHour ?? 96000;
    double basePrice = 0.0;
    if (_selectedComboId == 'TB_2H') {
      basePrice = (hourlyPrice * 2).toDouble();
    } else if (_selectedComboId == 'TB_DAY') {
      basePrice = 196000;
    } else if (_selectedComboId == 'TB_NIGHT') {
      basePrice = 296000;
    } else {
      final fixedDur = _getComboDurationHours(_selectedComboId);
      if (fixedDur != null) {
        basePrice = (hourlyPrice * fixedDur).toDouble();
      } else {
        basePrice = roomTotalVal;
      }
    }
    final discount = roomTotalVal - basePrice;
    return discount > 0 ? discount : 0.0;
  }

  String _formatVND(double amount) {
    final n = amount.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) buf.write('.');
      buf.write(n[i]);
    }
    return '${buf.toString()} đ';
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi nhập liệu', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate.isBefore(today) ? today : _checkInDate,
      firstDate: today,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      DateTime newDate = picked;
      TimeOfDay newTime = _checkInTime;
      final now = DateTime.now();
      final combined = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        newTime.hour,
        newTime.minute,
      );
      if (combined.isBefore(now.subtract(const Duration(minutes: 5)))) {
        newTime = TimeOfDay.now();
      }
      setState(() {
        _checkInDate = newDate;
        _checkInTime = newTime;
        _recalculateCheckout();
      });
    }
  }

  Future<void> _pickCheckIn() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkInTime,
    );
    if (picked != null) {
      final now = DateTime.now();
      final selectedCin = DateTime(
        _checkInDate.year,
        _checkInDate.month,
        _checkInDate.day,
        picked.hour,
        picked.minute,
      );
      if (selectedCin.isBefore(now.subtract(const Duration(minutes: 5)))) {
        _showErrorDialog('Giờ nhận phòng không được ở quá khứ!');
        return;
      }
      setState(() {
        _checkInTime = picked;
        _recalculateCheckout();
      });
    }
  }

  Future<void> _pickCheckOut() async {
    if (_getComboDurationHours(_selectedComboId) != null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkOutTime,
    );
    if (picked != null) {
      setState(() {
        _checkOutTime = picked;
        _recalculatePrice();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomListState = ref.watch(roomListProvider);
    final availableRooms = roomListState.rooms;
    final isFixedCombo = _getComboDurationHours(_selectedComboId) != null;

    final selectedRoom = availableRooms.firstWhere(
      (r) => r.roomId == _selectedRoomId,
      orElse: () => RoomModel(roomId: '', nameRoom: 'Chọn phòng'),
    );

    final double roomTotal = selectedRoom.roomId.isNotEmpty ? _calculateRoomTotal(selectedRoom) : 0.0;
    final double comboDiscount = selectedRoom.roomId.isNotEmpty ? _calculateComboDiscount(selectedRoom) : 0.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 480,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5FF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            _buildDialogHeader(context, 'Tạo Đặt Phòng'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildRoomSelector(availableRooms),
                      const SizedBox(height: 12),
                      if (_selectedRoomId != null && selectedRoom.roomId.isNotEmpty)
                        _buildRoomCard(selectedRoom),
                      const SizedBox(height: 12),
                      _buildGuestInfoCard(),
                      const SizedBox(height: 12),
                      _buildComboDropdown(),
                      const SizedBox(height: 12),
                      _buildDateSection(),
                      const SizedBox(height: 10),
                      _buildTimeSection(isFixedCombo),
                      const SizedBox(height: 10),
                      _buildVoucherNoteCard(),
                      const SizedBox(height: 12),
                      _buildBillCard(roomTotal, comboDiscount),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context, false),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildRoomSelector(List<RoomModel> rooms) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Chọn Phòng *',
          border: InputBorder.none,
          floatingLabelStyle: TextStyle(color: AppTheme.primary),
        ),
        value: _selectedRoomId,
        items: rooms.map((room) {
          final isFree = room.status?.toLowerCase() == 'trống';
          return DropdownMenuItem(
            value: room.roomId,
            child: Text(
              'Phòng ${room.nameRoom} (${isFree ? 'Trống' : room.status})',
              style: TextStyle(
                color: isFree ? Colors.green.shade700 : AppTheme.textGray,
                fontWeight: isFree ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
        validator: (val) => val == null ? 'Vui lòng chọn phòng' : null,
        onChanged: (val) {
          setState(() {
            _selectedRoomId = val;
            _recalculatePrice();
          });
        },
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final price = room.typeRoom?.pricePerHour ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.15),
                    AppTheme.primaryDark.withOpacity(0.15),
                  ],
                ),
              ),
              child: room.imageUrl != null && room.imageUrl!.isNotEmpty
                  ? Image.network(room.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.bedroom_parent_outlined,
                          size: 32,
                          color: AppTheme.primary))
                  : const Icon(Icons.bedroom_parent_outlined,
                      size: 32, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${room.nameRoom} · ${room.typeRoomName ?? ''}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  room.hotelName ?? '',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                  child: Text(
                    '${_formatVND(price.toDouble())} / giờ',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin khách hàng',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray)),
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Họ tên khách hàng *',
              hintText: 'Nhập họ tên khách hàng',
              prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.primary),
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên khách hàng' : null,
            onChanged: (val) => _customerName = val.trim(),
          ),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Số điện thoại *',
              hintText: 'Nhập số điện thoại khách hàng',
              prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppTheme.primary),
            ),
            keyboardType: TextInputType.phone,
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
            onChanged: (val) => _customerPhone = val.trim(),
          ),
        ],
      ),
    );
  }

  Widget _buildComboDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Hình thức thuê *',
          border: InputBorder.none,
          floatingLabelStyle: TextStyle(color: AppTheme.primary),
        ),
        value: _selectedComboId,
        items: _combos.map((combo) {
          return DropdownMenuItem(
            value: combo['id'],
            child: Text(combo['name']!),
          );
        }).toList(),
        onChanged: (val) {
          if (val == null) return;
          setState(() {
            _selectedComboId = val;
            _recalculateCheckout();
          });
        },
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ngày đặt phòng',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Row(
              children: [
                _dateField(_checkInDate.day.toString().padLeft(2, '0'), 'Ngày'),
                const SizedBox(width: 8),
                const Text('/', style: TextStyle(color: AppTheme.textGray, fontSize: 18)),
                const SizedBox(width: 8),
                _dateField(_checkInDate.month.toString().padLeft(2, '0'), 'Tháng'),
                const SizedBox(width: 8),
                const Text('/', style: TextStyle(color: AppTheme.textGray, fontSize: 18)),
                const SizedBox(width: 8),
                _dateField(_checkInDate.year.toString(), 'Năm', flex: 2),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String value, String label, {int flex = 1}) {
    return Flexible(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E0FF)),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection(bool isFixedCombo) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickCheckIn,
            child: _timeRow(
              icon: Icons.login_rounded,
              label: 'Check in',
              value: _formatTime(_checkInTime),
              isLocked: false,
            ),
          ),
          const Divider(height: 20, color: Color(0xFFEDE7FF)),
          GestureDetector(
            onTap: isFixedCombo ? null : _pickCheckOut,
            child: _timeRow(
              icon: Icons.logout_rounded,
              label: 'Check out',
              value: _formatTime(_checkOutTime),
              isLocked: isFixedCombo,
              isError: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLocked = false,
    bool isError = false,
  }) {
    final color = isError ? AppTheme.primaryDark : AppTheme.primary;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary)),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isLocked ? AppTheme.textGray : AppTheme.primary),
        ),
        const SizedBox(width: 6),
        Icon(
          isLocked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
          size: 18,
          color: AppTheme.textGray,
        ),
      ],
    );
  }

  Widget _buildVoucherNoteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: const Icon(Icons.local_offer_outlined, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text('Voucher / Giảm giá',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray)),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _ShopeeVoucherPickerBottomSheet(
                  initialVoucherCode: _voucherCode,
                  currentBasePrice: _basePrice,
                  onVoucherSelected: (code, discountAmt) {
                    setState(() {
                      _voucherCode = code;
                      _discountAmount = discountAmt;
                      _recalculatePrice();
                    });
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEBE5FF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_num_outlined, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _voucherCode.isNotEmpty
                        ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFECE8),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFFF5722)),
                                ),
                                child: Text(
                                  _voucherCode,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF5722),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Giảm ${_formatVND(_discountAmount)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Chọn hoặc nhập mã giảm giá',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGray,
                            ),
                          ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textGray, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ShaderMask(
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text('Ghi chú',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Nhập ghi chú đặt phòng (VD: đồ uống kèm, gối phụ...)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (val) => _noteInput = val.trim(),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(double roomTotal, double comboDiscount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thanh toán',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          _billRow('Tổng tiền phòng', _formatVND(roomTotal)),
          const SizedBox(height: 8),
          _billRow('Giảm giá combo', comboDiscount > 0 ? '– ${_formatVND(comboDiscount)}' : '0 đ', isGray: true),
          const SizedBox(height: 8),
          _billRow('Voucher giảm giá', _discountAmount > 0 ? '– ${_formatVND(_discountAmount)}' : '0 đ', highlight: _discountAmount > 0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEDE7FF)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              ShaderMask(
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: Text(
                  _formatVND(_price),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {bool isGray = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: isGray ? AppTheme.textGray : AppTheme.textPrimary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlight
                ? AppTheme.primary
                : (isGray ? AppTheme.textGray : AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tổng cộng:', style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
              Text(_formatVND(_price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context, false),
                child: const Text('Hủy', style: TextStyle(color: AppTheme.textGray)),
              ),
              const SizedBox(width: 8),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Đặt phòng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedRoomId == null) return;
    setState(() => _submitting = true);

    try {
      final cin = DateTime(
        _checkInDate.year,
        _checkInDate.month,
        _checkInDate.day,
        _checkInTime.hour,
        _checkInTime.minute,
      );

      final cout = DateTime(
        _checkOutDate.year,
        _checkOutDate.month,
        _checkOutDate.day,
        _checkOutTime.hour,
        _checkOutTime.minute,
      );

      final now = DateTime.now();
      if (cin.isBefore(now.subtract(const Duration(minutes: 5)))) {
        _showErrorDialog('Thời gian nhận phòng không được ở quá khứ!');
        setState(() => _submitting = false);
        return;
      }

      if (!cout.isAfter(cin.add(const Duration(minutes: 29)))) {
        _showErrorDialog('Thời gian trả phòng phải sau nhận phòng ít nhất 30 phút!');
        setState(() => _submitting = false);
        return;
      }

      final combinedNote = 'Khách: ${_customerName.trim()} - SĐT: ${_customerPhone.trim()}\nGhi chú: ${_noteInput.trim()}';
      final loggedInUserId = ref.read(authProvider).user?.userId ?? '';

      if (loggedInUserId.isEmpty) {
        throw Exception('Vui lòng đăng nhập lại trước khi tạo đặt phòng.');
      }

      final booking = BookingModel(
        roomId: _selectedRoomId!,
        userId: loggedInUserId,
        typeBookingId: _selectedComboId,
        checkIn: cin,
        checkOut: cout,
        totalPrice: _price,
        status: 'Chưa thanh toán',
        voucherCode: _voucherCode.isNotEmpty ? _voucherCode : null,
        discountAmount: _discountAmount > 0 ? _discountAmount : null,
        note: combinedNote,
      );

      await ref.read(bookingServiceProvider).createBooking(booking);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo đặt phòng thành công')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo đặt phòng: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _EditBookingDialogContent extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _EditBookingDialogContent({required this.booking});

  @override
  ConsumerState<_EditBookingDialogContent> createState() =>
      __EditBookingDialogContentState();
}

class __EditBookingDialogContentState
    extends ConsumerState<_EditBookingDialogContent> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRoomId;
  String _customerName = '';
  String _customerPhone = '';
  String _selectedComboId = 'TB_2H';

  DateTime _checkInDate = DateTime.now();
  TimeOfDay _checkInTime = TimeOfDay.now();
  DateTime _checkOutDate = DateTime.now();
  TimeOfDay _checkOutTime = TimeOfDay.now();

  double _price = 0.0;
  double _basePrice = 0.0;
  String _voucherCode = '';
  double _discountAmount = 0.0;
  String _noteInput = '';
  bool _submitting = false;

  late final TextEditingController _priceController;

  final List<Map<String, String>> _combos = [
    {'id': 'TB_2H', 'name': 'Combo 2h xem phim + đồ ăn'},
    {'id': 'TB_4H', 'name': 'Combo 4h'},
    {'id': 'TB_5H', 'name': 'Combo 5h'},
    {'id': 'TB_6H', 'name': 'Combo 6h'},
    {'id': 'TB_DAY', 'name': 'Combo ngày 7h-12h'},
    {'id': 'TB_NIGHT', 'name': 'Combo đêm 23h-7h'},
    {'id': 'TB001', 'name': 'Thuê theo giờ'},
    {'id': 'TB002', 'name': 'Qua đêm'},
    {'id': 'TB003', 'name': 'Thuê nguyên ngày'},
    {'id': 'TB004', 'name': 'Thuê theo tuần'},
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    _selectedRoomId = b.roomId;
    _selectedComboId = b.typeBookingId;
    _checkInDate = b.checkIn;
    _checkInTime = TimeOfDay.fromDateTime(b.checkIn);
    if (b.checkOut != null) {
      _checkOutDate = b.checkOut!;
      _checkOutTime = TimeOfDay.fromDateTime(b.checkOut!);
    }
    _price = b.totalPrice ?? 0.0;
    _voucherCode = b.voucherCode ?? '';
    _discountAmount = b.discountAmount ?? 0.0;

    _priceController = TextEditingController(text: _price.toStringAsFixed(0));

    String noteText = b.note ?? '';
    if (noteText.startsWith('Khách: ')) {
      final lines = noteText.split('\n');
      final firstLine = lines[0];
      final match = RegExp(r'^Khách:\s*(.*?)\s*-\s*SĐT:\s*(.*?)$').firstMatch(firstLine);
      if (match != null) {
        _customerName = match.group(1) ?? '';
        _customerPhone = match.group(2) ?? '';
        _noteInput = lines.sublist(1).join('\n').replaceFirst('Ghi chú: ', '');
      } else {
        _noteInput = noteText;
      }
    } else {
      _noteInput = noteText;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  int? _getComboDurationHours(String comboId) {
    switch (comboId) {
      case 'TB_2H': return 2;
      case 'TB_4H': return 4;
      case 'TB_5H': return 5;
      case 'TB_6H': return 6;
      case 'TB_DAY': return 5;
      case 'TB_NIGHT': return 8;
      case 'TB002': return 12;
      case 'TB003': return 24;
      case 'TB004': return 168;
      case 'TB001':
      default:
        return null;
    }
  }

  void _recalculateCheckout() {
    final cin = DateTime(
      _checkInDate.year,
      _checkInDate.month,
      _checkInDate.day,
      _checkInTime.hour,
      _checkInTime.minute,
    );

    if (_selectedComboId == 'TB_DAY') {
      _checkInTime = const TimeOfDay(hour: 7, minute: 0);
      final cout = DateTime(
        _checkInDate.year,
        _checkInDate.month,
        _checkInDate.day,
        12,
        0,
      );
      _checkOutDate = cout;
      _checkOutTime = const TimeOfDay(hour: 12, minute: 0);
    } else if (_selectedComboId == 'TB_NIGHT') {
      _checkInTime = const TimeOfDay(hour: 23, minute: 0);
      final cout = DateTime(
        _checkInDate.year,
        _checkInDate.month,
        _checkInDate.day,
        23,
        0,
      ).add(const Duration(hours: 8));
      _checkOutDate = cout;
      _checkOutTime = const TimeOfDay(hour: 7, minute: 0);
    } else {
      final duration = _getComboDurationHours(_selectedComboId);
      if (duration != null) {
        final cout = cin.add(Duration(hours: duration));
        _checkOutDate = cout;
        _checkOutTime = TimeOfDay.fromDateTime(cout);
      } else {
        final cout = DateTime(
          _checkOutDate.year,
          _checkOutDate.month,
          _checkOutDate.day,
          _checkOutTime.hour,
          _checkOutTime.minute,
        );
        if (!cout.isAfter(cin)) {
          final newCout = cin.add(const Duration(hours: 2));
          _checkOutDate = newCout;
          _checkOutTime = TimeOfDay.fromDateTime(newCout);
        }
      }
    }
    _recalculatePrice();
  }

  void _recalculatePrice() {
    if (_selectedRoomId == null) return;
    
    final roomListState = ref.read(roomListProvider);
    final room = roomListState.rooms.firstWhere(
      (r) => r.roomId == _selectedRoomId,
      orElse: () => roomListState.rooms.first,
    );
    final hourlyPrice = room.typeRoom?.pricePerHour ?? 96000;

    final cin = DateTime(
      _checkInDate.year,
      _checkInDate.month,
      _checkInDate.day,
      _checkInTime.hour,
      _checkInTime.minute,
    );

    final cout = DateTime(
      _checkOutDate.year,
      _checkOutDate.month,
      _checkOutDate.day,
      _checkOutTime.hour,
      _checkOutTime.minute,
    );

    double basePrice = 0.0;
    if (_selectedComboId == 'TB_2H') {
      basePrice = (hourlyPrice * 2).toDouble();
    } else if (_selectedComboId == 'TB_DAY') {
      basePrice = 196000;
    } else if (_selectedComboId == 'TB_NIGHT') {
      basePrice = 296000;
    } else {
      final fixedDur = _getComboDurationHours(_selectedComboId);
      if (fixedDur != null) {
        basePrice = (hourlyPrice * fixedDur).toDouble();
      } else {
        final diffMs = cout.difference(cin).inMilliseconds;
        final hours = diffMs / (1000 * 60 * 60);
        final finalHours = hours.clamp(0.5, double.infinity);
        basePrice = hourlyPrice * finalHours;
      }
    }

    setState(() {
      _basePrice = basePrice;
      _price = (basePrice - _discountAmount).clamp(0.0, double.infinity);
      _priceController.text = _price.toStringAsFixed(0);
    });
  }

  double _calculateRoomTotal(RoomModel room) {
    final hourlyPrice = room.typeRoom?.pricePerHour ?? 96000;
    final duration = _getComboDurationHours(_selectedComboId);
    if (duration != null) {
      return (hourlyPrice * duration).toDouble();
    } else {
      final cin = DateTime(
        _checkInDate.year,
        _checkInDate.month,
        _checkInDate.day,
        _checkInTime.hour,
        _checkInTime.minute,
      );
      final cout = DateTime(
        _checkOutDate.year,
        _checkOutDate.month,
        _checkOutDate.day,
        _checkOutTime.hour,
        _checkOutTime.minute,
      );
      final diffMs = cout.difference(cin).inMilliseconds;
      final hours = diffMs / (1000 * 60 * 60);
      final finalHours = hours.clamp(0.5, double.infinity);
      return hourlyPrice * finalHours;
    }
  }

  double _calculateComboDiscount(RoomModel room) {
    final roomTotalVal = _calculateRoomTotal(room);
    final hourlyPrice = room.typeRoom?.pricePerHour ?? 96000;
    double basePrice = 0.0;
    if (_selectedComboId == 'TB_2H') {
      basePrice = (hourlyPrice * 2).toDouble();
    } else if (_selectedComboId == 'TB_DAY') {
      basePrice = 196000;
    } else if (_selectedComboId == 'TB_NIGHT') {
      basePrice = 296000;
    } else {
      final fixedDur = _getComboDurationHours(_selectedComboId);
      if (fixedDur != null) {
        basePrice = (hourlyPrice * fixedDur).toDouble();
      } else {
        basePrice = roomTotalVal;
      }
    }
    final discount = roomTotalVal - basePrice;
    return discount > 0 ? discount : 0.0;
  }

  String _formatVND(double amount) {
    final n = amount.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) buf.write('.');
      buf.write(n[i]);
    }
    return '${buf.toString()} đ';
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi nhập liệu', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // If the check-in is already in the past, allow picking that date, otherwise today is the limit
    final limitDate = widget.booking.checkIn.isBefore(today)
        ? DateTime(widget.booking.checkIn.year, widget.booking.checkIn.month, widget.booking.checkIn.day)
        : today;

    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate.isBefore(limitDate) ? limitDate : _checkInDate,
      firstDate: limitDate,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      DateTime newDate = picked;
      TimeOfDay newTime = _checkInTime;
      final now = DateTime.now();
      final combined = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        newTime.hour,
        newTime.minute,
      );
      // Auto adjust if checking-in is changed and falls in the past
      if (combined.isBefore(now.subtract(const Duration(minutes: 5))) &&
          combined != widget.booking.checkIn) {
        newTime = TimeOfDay.now();
      }
      setState(() {
        _checkInDate = newDate;
        _checkInTime = newTime;
        _recalculateCheckout();
      });
    }
  }

  Future<void> _pickCheckIn() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkInTime,
    );
    if (picked != null) {
      final now = DateTime.now();
      final selectedCin = DateTime(
        _checkInDate.year,
        _checkInDate.month,
        _checkInDate.day,
        picked.hour,
        picked.minute,
      );
      if (selectedCin.isBefore(now.subtract(const Duration(minutes: 5))) &&
          selectedCin != widget.booking.checkIn) {
        _showErrorDialog('Giờ nhận phòng mới không được ở quá khứ!');
        return;
      }
      setState(() {
        _checkInTime = picked;
        _recalculateCheckout();
      });
    }
  }

  Future<void> _pickCheckOut() async {
    if (_getComboDurationHours(_selectedComboId) != null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _checkOutTime,
    );
    if (picked != null) {
      setState(() {
        _checkOutTime = picked;
        _recalculatePrice();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomListState = ref.watch(roomListProvider);
    final availableRooms = roomListState.rooms;
    final isFixedCombo = _getComboDurationHours(_selectedComboId) != null;

    final selectedRoom = availableRooms.firstWhere(
      (r) => r.roomId == _selectedRoomId,
      orElse: () => RoomModel(roomId: '', nameRoom: 'Chọn phòng'),
    );

    final double roomTotal = selectedRoom.roomId.isNotEmpty ? _calculateRoomTotal(selectedRoom) : 0.0;
    final double comboDiscount = selectedRoom.roomId.isNotEmpty ? _calculateComboDiscount(selectedRoom) : 0.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 480,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5FF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            _buildDialogHeader(context, 'Cập Nhật Đặt Phòng'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildRoomSelector(availableRooms),
                      const SizedBox(height: 12),
                      if (_selectedRoomId != null && selectedRoom.roomId.isNotEmpty)
                        _buildRoomCard(selectedRoom),
                      const SizedBox(height: 12),
                      _buildGuestInfoCard(),
                      const SizedBox(height: 12),
                      _buildComboDropdown(),
                      const SizedBox(height: 12),
                      _buildDateSection(),
                      const SizedBox(height: 10),
                      _buildTimeSection(isFixedCombo),
                      const SizedBox(height: 10),
                      _buildVoucherNoteCard(),
                      const SizedBox(height: 12),
                      _buildBillCard(roomTotal, comboDiscount),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context, false),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildRoomSelector(List<RoomModel> rooms) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Chọn Phòng *',
          border: InputBorder.none,
          floatingLabelStyle: TextStyle(color: AppTheme.primary),
        ),
        value: _selectedRoomId,
        items: rooms.map((room) {
          final isFree = room.status?.toLowerCase() == 'trống' || room.roomId == widget.booking.roomId;
          return DropdownMenuItem(
            value: room.roomId,
            child: Text(
              'Phòng ${room.nameRoom} (${isFree ? 'Trống' : room.status})',
              style: TextStyle(
                color: isFree ? Colors.green.shade700 : AppTheme.textGray,
                fontWeight: isFree ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
        validator: (val) => val == null ? 'Vui lòng chọn phòng' : null,
        onChanged: (val) {
          setState(() {
            _selectedRoomId = val;
            _recalculatePrice();
          });
        },
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final price = room.typeRoom?.pricePerHour ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.15),
                    AppTheme.primaryDark.withOpacity(0.15),
                  ],
                ),
              ),
              child: room.imageUrl != null && room.imageUrl!.isNotEmpty
                  ? Image.network(room.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.bedroom_parent_outlined,
                          size: 32,
                          color: AppTheme.primary))
                  : const Icon(Icons.bedroom_parent_outlined,
                      size: 32, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${room.nameRoom} · ${room.typeRoomName ?? ''}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  room.hotelName ?? '',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                  child: Text(
                    '${_formatVND(price.toDouble())} / giờ',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin khách hàng',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _customerName,
            decoration: const InputDecoration(
              labelText: 'Họ tên khách hàng *',
              hintText: 'Nhập họ tên khách hàng',
              prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.primary),
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên khách hàng' : null,
            onChanged: (val) => _customerName = val.trim(),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: _customerPhone,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại *',
              hintText: 'Nhập số điện thoại khách hàng',
              prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppTheme.primary),
            ),
            keyboardType: TextInputType.phone,
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
            onChanged: (val) => _customerPhone = val.trim(),
          ),
        ],
      ),
    );
  }

  Widget _buildComboDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Hình thức thuê *',
          border: InputBorder.none,
          floatingLabelStyle: TextStyle(color: AppTheme.primary),
        ),
        value: _selectedComboId,
        items: _combos.map((combo) {
          return DropdownMenuItem(
            value: combo['id'],
            child: Text(combo['name']!),
          );
        }).toList(),
        onChanged: (val) {
          if (val == null) return;
          setState(() {
            _selectedComboId = val;
            _recalculateCheckout();
          });
        },
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ngày đặt phòng',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Row(
              children: [
                _dateField(_checkInDate.day.toString().padLeft(2, '0'), 'Ngày'),
                const SizedBox(width: 8),
                const Text('/', style: TextStyle(color: AppTheme.textGray, fontSize: 18)),
                const SizedBox(width: 8),
                _dateField(_checkInDate.month.toString().padLeft(2, '0'), 'Tháng'),
                const SizedBox(width: 8),
                const Text('/', style: TextStyle(color: AppTheme.textGray, fontSize: 18)),
                const SizedBox(width: 8),
                _dateField(_checkInDate.year.toString(), 'Năm', flex: 2),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String value, String label, {int flex = 1}) {
    return Flexible(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8E0FF)),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection(bool isFixedCombo) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickCheckIn,
            child: _timeRow(
              icon: Icons.login_rounded,
              label: 'Check in',
              value: _formatTime(_checkInTime),
              isLocked: false,
            ),
          ),
          const Divider(height: 20, color: Color(0xFFEDE7FF)),
          GestureDetector(
            onTap: isFixedCombo ? null : _pickCheckOut,
            child: _timeRow(
              icon: Icons.logout_rounded,
              label: 'Check out',
              value: _formatTime(_checkOutTime),
              isLocked: isFixedCombo,
              isError: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLocked = false,
    bool isError = false,
  }) {
    final color = isError ? AppTheme.primaryDark : AppTheme.primary;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary)),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isLocked ? AppTheme.textGray : AppTheme.primary),
        ),
        const SizedBox(width: 6),
        Icon(
          isLocked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
          size: 18,
          color: AppTheme.textGray,
        ),
      ],
    );
  }

  Widget _buildVoucherNoteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: const Icon(Icons.local_offer_outlined, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text('Voucher / Giảm giá',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray)),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _ShopeeVoucherPickerBottomSheet(
                  initialVoucherCode: _voucherCode,
                  currentBasePrice: _basePrice,
                  onVoucherSelected: (code, discountAmt) {
                    setState(() {
                      _voucherCode = code;
                      _discountAmount = discountAmt;
                      _recalculatePrice();
                    });
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEBE5FF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_num_outlined, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _voucherCode.isNotEmpty
                        ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFECE8),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFFF5722)),
                                ),
                                child: Text(
                                  _voucherCode,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF5722),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Giảm ${_formatVND(_discountAmount)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Chọn hoặc nhập mã giảm giá',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGray,
                            ),
                          ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textGray, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ShaderMask(
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text('Ghi chú',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: _noteInput,
            decoration: const InputDecoration(
              hintText: 'Nhập ghi chú đặt phòng (VD: đồ uống kèm, gối phụ...)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (val) => _noteInput = val.trim(),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(double roomTotal, double comboDiscount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thanh toán',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          _billRow('Tổng tiền phòng', _formatVND(roomTotal)),
          const SizedBox(height: 8),
          _billRow('Giảm giá combo', comboDiscount > 0 ? '– ${_formatVND(comboDiscount)}' : '0 đ', isGray: true),
          const SizedBox(height: 8),
          _billRow('Voucher giảm giá', _discountAmount > 0 ? '– ${_formatVND(_discountAmount)}' : '0 đ', highlight: _discountAmount > 0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEDE7FF)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              ShaderMask(
                shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                child: Text(
                  _formatVND(_price),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {bool isGray = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: isGray ? AppTheme.textGray : AppTheme.textPrimary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlight
                ? AppTheme.primary
                : (isGray ? AppTheme.textGray : AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tổng cộng:', style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
              Text(_formatVND(_price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context, false),
                child: const Text('Hủy', style: TextStyle(color: AppTheme.textGray)),
              ),
              const SizedBox(width: 8),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedRoomId == null) return;
    setState(() => _submitting = true);

    try {
      final cin = DateTime(
        _checkInDate.year,
        _checkInDate.month,
        _checkInDate.day,
        _checkInTime.hour,
        _checkInTime.minute,
      );

      final cout = DateTime(
        _checkOutDate.year,
        _checkOutDate.month,
        _checkOutDate.day,
        _checkOutTime.hour,
        _checkOutTime.minute,
      );

      final now = DateTime.now();
      // Block only if the check-in time was changed to a past time (original past times are allowed to remain unmodified)
      if (cin.isBefore(now.subtract(const Duration(minutes: 5))) &&
          cin != widget.booking.checkIn) {
        _showErrorDialog('Thời gian nhận phòng mới không được ở quá khứ!');
        setState(() => _submitting = false);
        return;
      }

      if (!cout.isAfter(cin.add(const Duration(minutes: 29)))) {
        _showErrorDialog('Thời gian trả phòng phải sau nhận phòng ít nhất 30 phút!');
        setState(() => _submitting = false);
        return;
      }

      final combinedNote = 'Khách: ${_customerName.trim()} - SĐT: ${_customerPhone.trim()}\nGhi chú: ${_noteInput.trim()}';

      final updatedBooking = BookingModel(
        bookingId: widget.booking.bookingId,
        roomId: _selectedRoomId!,
        userId: widget.booking.userId,
        typeBookingId: _selectedComboId,
        checkIn: cin,
        checkOut: cout,
        totalPrice: _price,
        status: widget.booking.status,
        voucherCode: _voucherCode.isNotEmpty ? _voucherCode : null,
        discountAmount: _discountAmount > 0 ? _discountAmount : null,
        note: combinedNote,
      );

      await ref.read(bookingServiceProvider).updateBooking(widget.booking.bookingId!, updatedBooking);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật đặt phòng thành công')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật đặt phòng: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _ShopeeVoucherPickerBottomSheet extends ConsumerStatefulWidget {
  final String initialVoucherCode;
  final double currentBasePrice;
  final Function(String voucherCode, double discountAmt) onVoucherSelected;

  const _ShopeeVoucherPickerBottomSheet({
    required this.initialVoucherCode,
    required this.currentBasePrice,
    required this.onVoucherSelected,
  });

  @override
  ConsumerState<_ShopeeVoucherPickerBottomSheet> createState() =>
      __ShopeeVoucherPickerBottomSheetState();
}

class __ShopeeVoucherPickerBottomSheetState
    extends ConsumerState<_ShopeeVoucherPickerBottomSheet> {
  final TextEditingController _inputController = TextEditingController();
  String _selectedCode = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.initialVoucherCode;
    _inputController.text = widget.initialVoucherCode;
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final vouchersAsync = ref.watch(activeDiscountCodesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn Genz Cinema Voucher',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã voucher (ví dụ: GENZ20)',
                    hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textGray),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF5F3FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final code = _inputController.text.trim().toUpperCase();
                  if (code.isEmpty) return;
                  
                  vouchersAsync.when(
                    data: (list) {
                      final found = list.cast<DiscountCodeModel?>().firstWhere(
                        (v) => v?.code.toUpperCase() == code,
                        orElse: () => null,
                      );
                      if (found != null) {
                        setState(() {
                          _selectedCode = found.code;
                          _errorMessage = null;
                        });
                      } else {
                        setState(() {
                          _errorMessage = 'Mã voucher không hợp lệ hoặc đã hết hạn!';
                        });
                      }
                    },
                    loading: () {},
                    error: (_, __) {},
                  );
                },
                child: const Text('Áp dụng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Mã Giảm Giá Phù Hợp',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: vouchersAsync.when(
              data: (vouchers) {
                final activeList = vouchers.where((v) => v.status.toLowerCase() == 'active').toList();
                if (activeList.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Không có mã giảm giá nào khả dụng',
                        style: TextStyle(color: AppTheme.textGray),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: activeList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final v = activeList[index];
                    final isSelected = _selectedCode.toUpperCase() == v.code.toUpperCase();
                    final discAmt = v.calculateDiscount(widget.currentBasePrice);
                    final isUsable = discAmt > 0 && v.quantity > 0;

                    return GestureDetector(
                      onTap: isUsable
                          ? () {
                              setState(() {
                                _selectedCode = v.code;
                                _errorMessage = null;
                                _inputController.text = v.code;
                              });
                            }
                          : null,
                      child: Opacity(
                        opacity: isUsable ? 1.0 : 0.5,
                        child: Row(
                          children: [
                            Container(
                              width: 90,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF5722),
                                    Color(0xFFFF8A65),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    v.discountType.toUpperCase() == 'PERCENT'
                                        ? Icons.percent
                                        : Icons.card_giftcard,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    v.discountType.toUpperCase() == 'PERCENT'
                                        ? '${v.discountValue.toStringAsFixed(0)}%'
                                        : '${(v.discountValue / 1000).toStringAsFixed(0)}k',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 80,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFF0EFFF),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      v.code,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      v.description ?? 'Giảm giá hóa đơn phòng',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textGray,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Hạn dùng: ${DateFormat('dd/MM/yyyy').format(v.endDate)}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Còn lại: ${v.quantity}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Radio<String>(
                              value: v.code,
                              groupValue: _selectedCode,
                              activeColor: AppTheme.primary,
                              onChanged: isUsable
                                  ? (val) {
                                      setState(() {
                                        _selectedCode = val ?? '';
                                        _errorMessage = null;
                                        _inputController.text = val ?? '';
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Lỗi tải mã giảm giá: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  onPressed: () {
                    widget.onVoucherSelected('', 0.0);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Bỏ chọn',
                    style: TextStyle(color: AppTheme.textGray, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (_selectedCode.isEmpty) {
                      widget.onVoucherSelected('', 0.0);
                      Navigator.pop(context);
                      return;
                    }
                    
                    vouchersAsync.whenData((list) {
                      final found = list.cast<DiscountCodeModel?>().firstWhere(
                        (v) => v?.code.toUpperCase() == _selectedCode.toUpperCase(),
                        orElse: () => null,
                      );
                      if (found != null) {
                        final discAmt = found.calculateDiscount(widget.currentBasePrice);
                        widget.onVoucherSelected(found.code, discAmt);
                      } else {
                        widget.onVoucherSelected('', 0.0);
                      }
                      Navigator.pop(context);
                    });
                  },
                  child: const Text(
                    'Áp dụng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutInvoiceDialog extends ConsumerStatefulWidget {
  final BookingModel booking;
  final String checkInStr;
  final String checkOutStr;
  final double basePrice;
  final double discount;
  final double finalAmount;
  final bool isPrepaid; // true = khách đã thanh toán trước qua app

  const _CheckoutInvoiceDialog({
    required this.booking,
    required this.checkInStr,
    required this.checkOutStr,
    required this.basePrice,
    required this.discount,
    required this.finalAmount,
    this.isPrepaid = false,
  });

  @override
  ConsumerState<_CheckoutInvoiceDialog> createState() => _CheckoutInvoiceDialogState();
}

class _CheckoutInvoiceDialogState extends ConsumerState<_CheckoutInvoiceDialog> {
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
    // Polling ngầm tuần tự không chồng chéo luồng kết nối
    while (!_isDisposed && !_isPaid) {
      try {
        final latest = await ref.read(bookingServiceProvider).getBookingById(widget.booking.bookingId!);
        debugPrint('PRM391_POLLING: Booking #${widget.booking.bookingId} status from server: "${latest.status}"');
        if (latest.status != null && latest.status!.toLowerCase() == 'đã thanh toán') {
          if (_isDisposed) return;
          setState(() {
            _isPaid = true;
          });
          // Chờ 1.5 giây để nhân viên thấy màn hình thông báo rồi đóng
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted && !_isDisposed) {
            Navigator.pop(context, true);
          }
          break;
        }
      } catch (e) {
        debugPrint('PRM391_POLLING_ERROR: Lỗi quét trạng thái: $e');
      }
      await Future.delayed(const Duration(seconds: 4));
    }
  }

  Widget _buildInvoiceRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textGray, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isPaid) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 64),
            const SizedBox(height: 16),
            const Text(
              'THANH TOÁN THÀNH CÔNG!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.success),
            ),
            const SizedBox(height: 8),
            Text(
              'Đơn đặt phòng #${widget.booking.bookingId} đã nhận được tiền từ hệ thống chuyển khoản ngân hàng.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Center(
        child: Text(
          widget.isPrepaid ? 'XÁC NHẬN TRẢ PHÒNG' : 'HÓA ĐƠN THANH TOÁN',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark, fontSize: 18),
        ),
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(thickness: 1.5),
              const SizedBox(height: 8),
              _buildInvoiceRow('Mã Đặt Phòng:', '#${widget.booking.bookingId}'),
              _buildInvoiceRow('Phòng:', widget.booking.roomId),
              _buildInvoiceRow('Mã Khách:', widget.booking.userId),
              _buildInvoiceRow('Loại hình:', widget.booking.typeBookingId),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildInvoiceRow('Nhận phòng:', widget.checkInStr),
              _buildInvoiceRow('Trả phòng:', widget.checkOutStr),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildInvoiceRow('Tiền phòng:', fmt.format(widget.basePrice)),
              if (widget.discount > 0)
                _buildInvoiceRow('Khuyến mãi (Voucher):', '- ${fmt.format(widget.discount)}', valueColor: Colors.red),
              const SizedBox(height: 12),
              const Divider(thickness: 1.5),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TỔNG CỘNG:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    fmt.format(widget.finalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryDark),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Đã thanh toán trước qua app ──────────────────────────────
              if (widget.isPrepaid) ...
                [
                  const Divider(),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.success.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Khách đã thanh toán trước qua ứng dụng.\nKhông cần thu tiền thêm.',
                            style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

              // ── Chưa thanh toán → hiện QR ─────────────────────────────
              if (!widget.isPrepaid) ...
                [
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'QUÉT MÃ QR ĐỂ THANH TOÁN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEDE7FF)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.network(
                      'https://img.vietqr.io/image/TPB-00001041606-print.png?amount=${widget.finalAmount.toInt()}&addInfo=GENZ%20${widget.booking.bookingId}',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text('Không thể tải mã QR thanh toán', style: TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cú pháp CK: GENZ ${widget.booking.bookingId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary),
                  ),
                ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(widget.isPrepaid ? 'Xác nhận trả phòng' : 'Xác nhận nhận tiền mặt'),
        ),
      ],
    );
  }
}
