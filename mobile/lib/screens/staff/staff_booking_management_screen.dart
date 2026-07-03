import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/room_provider.dart';
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
  String _selectedFilter = 'Tất cả'; // Tất cả, Chờ nhận phòng, Đang ở, Đã trả phòng, Đã hủy

  final List<String> _filters = [
    'Tất cả',
    'Chờ nhận phòng',
    'Đang ở',
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
      bottomNavigationBar: const StaffBottomNavBar(currentIndex: 2),
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
                    // Match Search Text
                    final roomMatch = b.roomId.toLowerCase().contains(_searchText);
                    final userMatch = b.userId.toLowerCase().contains(_searchText);
                    final isSearchMatch = roomMatch || userMatch;

                    // Match Filter Type
                    bool isFilterMatch = true;
                    if (_selectedFilter == 'Chờ nhận phòng') {
                      isFilterMatch = b.status == 'Chưa thanh toán' || b.status == 'Chờ nhận phòng';
                    } else if (_selectedFilter == 'Đang ở') {
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
    final bool canCheckIn = booking.status == 'Chưa thanh toán' || booking.status == 'Chờ nhận phòng';
    final bool canCheckOut = booking.status == 'Đang ở';
    final bool canCancel = booking.status == 'Chưa thanh toán' || booking.status == 'Chờ nhận phòng';

    // Status colors
    Color statusBgColor = Colors.grey.shade100;
    Color statusTextColor = AppTheme.textGray;
    if (booking.status == 'Chưa thanh toán' || booking.status == 'Chờ nhận phòng') {
      statusBgColor = const Color(0xFFEFF6FF);
      statusTextColor = const Color(0xFF3B82F6);
    } else if (booking.status == 'Đang ở') {
      statusBgColor = const Color(0xFFFFF7ED);
      statusTextColor = const Color(0xFFF97316);
    } else if (booking.status == 'Đã thanh toán') {
      statusBgColor = const Color(0xFFECFDF5);
      statusTextColor = const Color(0xFF10B981);
    } else if (booking.status == 'Đã hủy') {
      statusBgColor = const Color(0xFFFEF2F2);
      statusTextColor = const Color(0xFFEF4444);
    }

    final String checkInStr = DateFormat('dd/MM/yyyy HH:mm').format(booking.checkIn);
    final String checkOutStr = booking.checkOut != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(booking.checkOut!)
        : 'Chưa xác định';
    final String priceStr = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
        .format(booking.totalPrice ?? 0);

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
                        booking.status ?? 'Chưa thanh toán',
                        style: TextStyle(
                          color: statusTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
            _buildDetailRow(Icons.meeting_room_outlined, 'Phòng:', booking.roomId),
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
      _updateBookingStatus(bookingId, 'Đang ở');
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

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
          child: Text(
            'HÓA ĐƠN THANH TOÁN',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark, fontSize: 18),
          ),
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(thickness: 1.5),
              const SizedBox(height: 8),
              _buildInvoiceRow('Mã Đặt Phòng:', '#${booking.bookingId}'),
              _buildInvoiceRow('Phòng:', booking.roomId),
              _buildInvoiceRow('Mã Khách:', booking.userId),
              _buildInvoiceRow('Loại hình:', booking.typeBookingId),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildInvoiceRow('Nhận phòng:', checkInStr),
              _buildInvoiceRow('Trả phòng:', checkOutStr),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildInvoiceRow('Tiền phòng:', NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(basePrice)),
              if (discount > 0)
                _buildInvoiceRow('Khuyến mãi (Voucher):', '- ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(discount)}', valueColor: Colors.red),
              const SizedBox(height: 12),
              const Divider(thickness: 1.5),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TỔNG CỘNG:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(finalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận & Thanh toán'),
          ),
        ],
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
}

// Dialog content with state handling
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
  String _customerId = 'USER-CUST-001';
  String _selectedComboId = 'TB_2H';
  DateTime _checkInDate = DateTime.now();
  TimeOfDay _checkInTime = TimeOfDay.now();
  DateTime _checkOutDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _checkOutTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));
  double _price = 150000;
  String _note = '';
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
    _priceController = TextEditingController(text: _price.toStringAsFixed(0));
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
      case 'TB002': return 12; // qua đêm
      case 'TB003': return 24; // nguyên ngày
      case 'TB004': return 168; // theo tuần
      case 'TB001':
      default:
        return null; // flexible hourly
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

    final duration = _getComboDurationHours(_selectedComboId);
    if (duration != null) {
      final cout = cin.add(Duration(hours: duration));
      _checkOutDate = cout;
      _checkOutTime = TimeOfDay.fromDateTime(cout);
    } else {
      // For flexible hourly TB001, ensure checkout is after checkin
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

    if (_selectedComboId == 'TB_2H') {
      _price = (hourlyPrice * 2).toDouble();
    } else if (_selectedComboId == 'TB_DAY') {
      _price = 196000;
    } else if (_selectedComboId == 'TB_NIGHT') {
      _price = 296000;
    } else {
      // Flexible hourly (TB001) or other custom durations
      final fixedDur = _getComboDurationHours(_selectedComboId);
      if (fixedDur != null) {
        _price = (hourlyPrice * fixedDur).toDouble();
      } else {
        // flexible hourly (TB001) - calculate diff in hours
        final diffMs = cout.difference(cin).inMilliseconds;
        final hours = diffMs / (1000 * 60 * 60);
        final finalHours = hours.clamp(0.5, double.infinity);
        _price = hourlyPrice * finalHours;
      }
    }
    _priceController.text = _price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final roomListState = ref.watch(roomListProvider);
    // Suggest rooms that are empty
    final availableRooms = roomListState.rooms;
    final isFixedCombo = _getComboDurationHours(_selectedComboId) != null;

    return AlertDialog(
      title: const Text('Tạo Đặt Phòng Mới'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Chọn Phòng *'),
                  value: _selectedRoomId,
                  items: availableRooms.map((room) {
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
                const SizedBox(height: 12),

                // Customer ID Textfield
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Mã khách hàng *',
                    hintText: 'Nhập USER-CUST-001 hoặc mã khác',
                  ),
                  initialValue: _customerId,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Vui lòng nhập mã khách hàng' : null,
                  onChanged: (val) => _customerId = val.trim(),
                ),
                const SizedBox(height: 12),

                // Combo Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Loại hình thuê *'),
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
                      
                      // Auto set checkout dates based on type selection
                      if (val == 'TB_DAY') {
                        _checkInTime = const TimeOfDay(hour: 7, minute: 0);
                      } else if (val == 'TB_NIGHT') {
                        _checkInTime = const TimeOfDay(hour: 23, minute: 0);
                      }

                      _recalculateCheckout();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Date Time Pickers (Check in)
                const Text('Thời gian nhận phòng:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(DateFormat('dd/MM/yyyy').format(_checkInDate)),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _checkInDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) {
                          setState(() {
                            _checkInDate = d;
                            _recalculateCheckout();
                          });
                        }
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(_checkInTime.format(context)),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _checkInTime,
                        );
                        if (t != null) {
                          setState(() {
                            _checkInTime = t;
                            _recalculateCheckout();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date Time Pickers (Check out)
                Row(
                  children: [
                    Text(
                      'Thời gian trả phòng:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFixedCombo ? AppTheme.textGray : AppTheme.textPrimary,
                      ),
                    ),
                    if (isFixedCombo)
                      const Text(
                        ' (Cố định theo Combo)',
                        style: TextStyle(fontSize: 12, color: AppTheme.textGray, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(DateFormat('dd/MM/yyyy').format(_checkOutDate)),
                      onPressed: isFixedCombo
                          ? null
                          : () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _checkOutDate,
                                firstDate: _checkInDate,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (d != null) {
                                setState(() {
                                  _checkOutDate = d;
                                  _recalculatePrice();
                                });
                              }
                            },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(_checkOutTime.format(context)),
                      onPressed: isFixedCombo
                          ? null
                          : () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _checkOutTime,
                              );
                              if (t != null) {
                                setState(() {
                                  _checkOutTime = t;
                                  _recalculatePrice();
                                });
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Total Price Input
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Tổng tiền thanh toán (đ) *',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || double.tryParse(val) == null ? 'Vui lòng nhập giá tiền hợp lệ' : null,
                  onChanged: (val) => _price = double.tryParse(val) ?? 0,
                ),
                const SizedBox(height: 12),

                // Note Input
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                  ),
                  onChanged: (val) => _note = val,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Tạo đặt phòng'),
        ),
      ],
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

      if (!cout.isAfter(cin.add(const Duration(minutes: 29)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Thời gian trả phòng phải sau nhận phòng ít nhất 30 phút!')),
        );
        setState(() => _submitting = false);
        return;
      }

      final booking = BookingModel(
        roomId: _selectedRoomId!,
        userId: _customerId,
        typeBookingId: _selectedComboId,
        checkIn: cin,
        checkOut: cout,
        totalPrice: _price,
        status: 'Chờ nhận phòng',
        note: _note.isNotEmpty ? _note : null,
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
