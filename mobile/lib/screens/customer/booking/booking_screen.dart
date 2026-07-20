// lib/screens/customer/booking/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../models/room_model.dart';
import '../../../models/booking_model.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/discount_code_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final RoomModel room;

  const BookingScreen({super.key, required this.room});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _voucherController = TextEditingController();
  List<BookingModel> _busySlots = [];
  bool _isLoadingBusySlots = true;
  String? _busySlotsError;

  @override
  void initState() {
    super.initState();
    // Khởi tạo room vào provider
    Future.microtask(() {
      ref.read(bookingProvider.notifier).setRoom(widget.room);
      _loadBusySlots();
    });
  }

  Future<void> _loadBusySlots() async {
    try {
      final slots = await ref.read(bookingServiceProvider).getBusySlots(widget.room.roomId);
      if (mounted) {
        setState(() {
          _busySlots = slots;
          _isLoadingBusySlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busySlotsError = e.toString();
          _isLoadingBusySlots = false;
        });
      }
    }
  }

  String? _validateTimeOverlap(BookingState state) {
    if (state.checkIn == null || state.checkOut == null) return null;
    final newStart = state.checkIn!;
    final newEnd = state.checkOut!;

    for (final slot in _busySlots) {
      final existStart = slot.checkIn;
      final existEnd = slot.checkOut;
      if (existEnd == null) continue;

      if (newStart.isBefore(existEnd) && existStart.isBefore(newEnd)) {
        final startStr = "${existStart.day.toString().padLeft(2, '0')}/${existStart.month.toString().padLeft(2, '0')}/${existStart.year} ${existStart.hour.toString().padLeft(2, '0')}:${existStart.minute.toString().padLeft(2, '0')}";
        final endStr = "${existEnd.day.toString().padLeft(2, '0')}/${existEnd.month.toString().padLeft(2, '0')}/${existEnd.year} ${existEnd.hour.toString().padLeft(2, '0')}:${existEnd.minute.toString().padLeft(2, '0')}";
        return 'Khoảng thời gian này đã có người đặt ($startStr - $endStr)';
      }
    }
    return null;
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  // ── Format tiền VND ─────────────────────────────────────────────────────────
  String _formatVND(double amount) {
    final n = amount.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) buf.write('.');
      buf.write(n[i]);
    }
    return '${buf.toString()} đ';
  }

  // ── Format thời gian ─────────────────────────────────────────────────────────
  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  // ── Chọn ngày ───────────────────────────────────────────────────────────────
  Future<void> _pickDate(BuildContext context, BookingState state) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: now,
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
      ref.read(bookingProvider.notifier).setDate(picked);
    }
  }

  // ── Chọn giờ check-in ───────────────────────────────────────────────────────
  Future<void> _pickCheckIn(BuildContext context, BookingState state) async {
    if (state.selectedCombo != BookingComboType.hourly) return;
    final current = state.checkIn ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final now = DateTime.now();
      ref.read(bookingProvider.notifier).setCheckIn(
            DateTime(now.year, now.month, now.day, picked.hour, picked.minute),
          );
    }
  }

  // ── Chọn giờ check-out ──────────────────────────────────────────────────────
  Future<void> _pickCheckOut(BuildContext context, BookingState state) async {
    if (state.selectedCombo != BookingComboType.hourly) return;
    final current = state.checkOut ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final now = DateTime.now();
      ref.read(bookingProvider.notifier).setCheckOut(
            DateTime(now.year, now.month, now.day, picked.hour, picked.minute),
          );
    }
  }

  // ── Bottom sheet Voucher ─────────────────────────────────────────────────────
  Future<void> _showVoucherSheet(BuildContext context, BookingState state) async {
    _voucherController.clear();
    try {
      // Staff may have created or updated a voucher since the previous open.
      ref.invalidate(activeDiscountCodesProvider);
      final discountCodes = await ref.read(activeDiscountCodesProvider.future);
      if (!mounted) return;

      final now = DateTime.now();
      final vouchers = discountCodes
          .where((discount) {
            final endOfDay = DateTime(
              discount.endDate.year,
              discount.endDate.month,
              discount.endDate.day,
              23,
              59,
              59,
              999,
            );
            return discount.status.toLowerCase() == 'active' &&
                discount.quantity > 0 &&
                !now.isBefore(discount.startDate) &&
                !now.isAfter(endOfDay);
          })
          .map((discount) => VoucherModel(
                code: discount.code,
                label: discount.description?.trim().isNotEmpty == true
                    ? discount.description!.trim()
                    : discount.discountType.toUpperCase() == 'PERCENT'
                        ? 'Giảm ${discount.discountValue.toStringAsFixed(0)}%'
                        : 'Giảm ${discount.discountValue.toStringAsFixed(0)}đ',
                discountPercent: discount.discountType.toUpperCase() == 'PERCENT'
                    ? discount.discountValue
                    : 0,
                discountAmount: discount.discountType.toUpperCase() == 'PERCENT'
                    ? null
                    : discount.discountValue,
                discountType: discount.discountType,
                discountValue: discount.discountValue,
                endDate: discount.endDate,
                quantity: discount.quantity,
              ))
          .toList();
      if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoucherSheet(
        vouchers: vouchers,
        appliedVoucher: state.appliedVoucher,
        roomTotal: state.roomTotal,
        onApply: (voucher) {
          ref.read(bookingProvider.notifier).applyVoucher(voucher);
          Navigator.of(context).pop();
        },
        onRemove: () {
          ref.read(bookingProvider.notifier).removeVoucher();
          Navigator.of(context).pop();
        },
      ),
    );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải danh sách voucher')),
      );
    }
  }

  // ── Dialog lời nhắn ─────────────────────────────────────────────────────────
  void _showNoteDialog(BuildContext context, BookingState state) {
    final noteCtrl = TextEditingController(text: state.note);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Lời nhắn cho khách sạn',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: noteCtrl,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Ví dụ: Setup đồ ăn kèm Coca, Cần thêm gối...',
            hintStyle: const TextStyle(color: AppTheme.textGray, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huỷ',
                style: TextStyle(color: AppTheme.textGray)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(bookingProvider.notifier).setNote(noteCtrl.text.trim());
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lưu',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Submit đặt phòng ─────────────────────────────────────────────────────────
  Future<void> _submit(BuildContext context) async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      _showErrorDialog(context, 'Vui lòng đăng nhập lại.');
      return;
    }
    final isAvailable = widget.room.status?.toLowerCase() == 'trống' ||
        widget.room.status?.toLowerCase() == 'available';
    if (!isAvailable) {
      _showErrorDialog(context, 'Phòng hiện tại không còn trống để đặt!');
      return;
    }
    final success =
        await ref.read(bookingProvider.notifier).submitBooking(user.userId);
    if (!mounted) return;
    if (success) {
      final bookingState = ref.read(bookingProvider);
      final bookingId = bookingState.createdBookingId;
      if (bookingId != null) {
        context.go(
          '/payment/$bookingId',
          extra: {
            'totalAmount': bookingState.totalPayment,
            'roomId': widget.room.roomId ?? '',
          },
        );
      } else {
        _showSuccessDialog(context);
      }
    } else {
      final error = ref.read(bookingProvider).error;
      _showErrorDialog(context, error ?? 'Đặt phòng thất bại!');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi đặt phòng', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 44, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đặt phòng thành công!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                'Cảm ơn bạn đã đặt phòng tại GenzCinema.\nNhân viên sẽ xác nhận qua điện thoại.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/rooms');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Về trang phòng',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoomCard(state),
            const SizedBox(height: 16),
            _buildComboSection(state),
            const SizedBox(height: 12),
            _buildDateSection(context, state),
            const SizedBox(height: 10),
            _buildTimeSection(context, state),
            const SizedBox(height: 10),
            _buildVoucherRow(context, state),
            const SizedBox(height: 6),
            _buildNoteRow(context, state),
            const SizedBox(height: 16),
            _buildBillCard(state),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, state),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: AppTheme.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Thanh toán',
        style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary),
      ),
    );
  }

  // ── Room card ────────────────────────────────────────────────────────────────
  Widget _buildRoomCard(BookingState state) {
    final room = widget.room;
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
          // Ảnh phòng
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.15),
                    AppTheme.primaryDark.withOpacity(0.15)
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
          // Thông tin phòng
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${room.nameRoom} · ${room.typeRoom?.typeRoom ?? ''}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGray,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  room.hotel?.name ?? room.hotel?.address ?? '',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (b) =>
                      AppTheme.primaryGradient.createShader(b),
                  child: Text(
                    '${_formatVND(price)} / giờ',
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

  // ── Combo section ───────────────────────────────────────────────────────────
  Widget _buildComboSection(BookingState state) {
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
          const Text('Hình thức thuê',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray)),
          const SizedBox(height: 10),
          Row(
            children: BookingComboType.values.map((combo) {
              final isSelected = state.selectedCombo == combo;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      ref.read(bookingProvider.notifier).setCombo(combo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsets.only(
                        right: combo == BookingComboType.night ? 0 : 8),
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppTheme.primaryGradient
                          : null,
                      color: isSelected ? null : const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? null
                          : Border.all(color: const Color(0xFFE8E0FF)),
                    ),
                    child: Center(
                      child: Text(
                        comboLabels[combo]!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (state.selectedCombo != BookingComboType.hourly) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Khung giờ: ${state.comboTimeDesc}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Date section ─────────────────────────────────────────────────────────────
  Widget _buildDateSection(BuildContext context, BookingState state) {
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
            onTap: () => _pickDate(context, state),
            child: Row(
              children: [
                // DD
                _dateField(
                    state.selectedDate.day.toString().padLeft(2, '0'), 'Ngày'),
                const SizedBox(width: 8),
                const Text('/',
                    style: TextStyle(color: AppTheme.textGray, fontSize: 18)),
                const SizedBox(width: 8),
                // MM
                _dateField(
                    state.selectedDate.month
                        .toString()
                        .padLeft(2, '0'),
                    'Tháng'),
                const SizedBox(width: 8),
                const Text('/',
                    style: TextStyle(color: AppTheme.textGray, fontSize: 18)),
                const SizedBox(width: 8),
                // YYYY
                _dateField(
                    state.selectedDate.year.toString(), 'Năm',
                    flex: 2),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_outlined,
                      size: 16, color: Colors.white),
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

  // ── Time section ─────────────────────────────────────────────────────────────
  Widget _buildTimeSection(BuildContext context, BookingState state) {
    final isLocked = state.selectedCombo != BookingComboType.hourly;
    final overlapError = _validateTimeOverlap(state);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
      ),
      child: Column(
        children: [
          // Check-in
          GestureDetector(
            onTap: () => _pickCheckIn(context, state),
            child: _timeRow(
              icon: Icons.login_rounded,
              label: 'Check in',
              value: _formatTime(state.checkIn),
              isLocked: isLocked,
            ),
          ),
          const Divider(height: 20, color: Color(0xFFEDE7FF)),
          // Check-out
          GestureDetector(
            onTap: () => _pickCheckOut(context, state),
            child: _timeRow(
              icon: Icons.logout_rounded,
              label: 'Check out',
              value: _formatTime(state.checkOut),
              isLocked: isLocked,
              isError: true,
            ),
          ),
          if (overlapError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      overlapError,
                      style: const TextStyle(
                        color: AppTheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  // ── Voucher row ──────────────────────────────────────────────────────────────
  Widget _buildVoucherRow(BuildContext context, BookingState state) {
    return GestureDetector(
      onTap: () => _showVoucherSheet(context, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE7FF)),
        ),
        child: Row(
          children: [
            ShaderMask(
              shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
              child: const Icon(Icons.local_offer_outlined,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'Voucher',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary),
            ),
            const Spacer(),
            Text(
              state.appliedVoucher != null
                  ? state.appliedVoucher!.code
                  : 'Nhập mã >',
              style: TextStyle(
                fontSize: 13,
                fontWeight: state.appliedVoucher != null
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: state.appliedVoucher != null
                    ? AppTheme.primary
                    : AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Note row ─────────────────────────────────────────────────────────────────
  Widget _buildNoteRow(BuildContext context, BookingState state) {
    return GestureDetector(
      onTap: () => _showNoteDialog(context, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE7FF)),
        ),
        child: Row(
          children: [
            ShaderMask(
              shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'Lời nhắn',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                state.note.isNotEmpty ? state.note : 'Để lại lời nhắn >',
                style: TextStyle(
                  fontSize: 13,
                  color: state.note.isNotEmpty
                      ? AppTheme.textPrimary
                      : AppTheme.textGray,
                  fontWeight: state.note.isNotEmpty
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bill card ────────────────────────────────────────────────────────────────
  Widget _buildBillCard(BookingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7FF)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thanh toán',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          _billRow(
            'Tổng tiền phòng',
            _formatVND(state.roomTotal),
          ),
          const SizedBox(height: 8),
          _billRow(
            'Giảm giá combo',
            state.selectedCombo != BookingComboType.hourly
                ? '– Gói cố định'
                : '0 đ',
            isGray: true,
          ),
          const SizedBox(height: 8),
          _billRow(
            'Voucher giảm giá',
            state.voucherDiscount > 0
                ? '– ${_formatVND(state.voucherDiscount)}'
                : '0 đ',
            highlight: state.voucherDiscount > 0,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEDE7FF)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary),
              ),
              ShaderMask(
                shaderCallback: (b) =>
                    AppTheme.primaryGradient.createShader(b),
                child: Text(
                  _formatVND(state.totalPayment),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value,
      {bool isGray = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 13,
              color: isGray ? AppTheme.textGray : AppTheme.textPrimary),
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

  // ── Bottom bar ───────────────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context, BookingState state) {
    final hasOverlap = _validateTimeOverlap(state) != null;
    final isBtnDisabled = state.isLoading || hasOverlap;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tổng cộng
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng cộng',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
              const SizedBox(height: 2),
              ShaderMask(
                shaderCallback: (b) =>
                    AppTheme.primaryGradient.createShader(b),
                child: Text(
                  _formatVND(state.totalPayment),
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Nút đặt phòng

          Expanded(
            child: SizedBox(
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isBtnDisabled ? null : AppTheme.primaryGradient,
                  color: isBtnDisabled ? Colors.grey.shade300 : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isBtnDisabled ? null : [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isBtnDisabled
                      ? null
                      : () => _submit(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Đặt phòng',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Voucher bottom sheet ──────────────────────────────────────────────────────
class _VoucherSheet extends StatefulWidget {
  final List<VoucherModel> vouchers;
  final VoucherModel? appliedVoucher;
  final double roomTotal;
  final void Function(VoucherModel) onApply;
  final VoidCallback onRemove;

  const _VoucherSheet({
    required this.vouchers,
    required this.appliedVoucher,
    required this.roomTotal,
    required this.onApply,
    required this.onRemove,
  });

  @override
  State<_VoucherSheet> createState() => _VoucherSheetState();
}

class _VoucherSheetState extends State<_VoucherSheet> {
  final _ctrl = TextEditingController();
  String _selectedCode = '';
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.appliedVoucher?.code ?? '';
    _ctrl.text = _selectedCode;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tryManualCode() {
    final code = _ctrl.text.trim().toUpperCase();
    final found = widget.vouchers.firstWhere(
      (v) => v.code.toUpperCase() == code,
      orElse: () => const VoucherModel(code: '', label: ''),
    );
    if (found.code.isEmpty) {
      setState(() => _errorMsg = 'Mã voucher không hợp lệ');
      return;
    }
    setState(() {
      _selectedCode = found.code;
      _ctrl.text = found.code;
      _errorMsg = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ListView(
          controller: scrollCtrl,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
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
            // Ô nhập mã thủ công
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã voucher (ví dụ: GENZ20)',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppTheme.textGray),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF5F3FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) =>
                        setState(() => _errorMsg = null),
                  ),
                ),
                const SizedBox(width: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: _tryManualCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Áp dụng',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Mã Giảm Giá Phù Hợp',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray),
            ),
            const SizedBox(height: 10),
            // Danh sách voucher
            if (widget.vouchers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Hiện chưa có voucher khả dụng'),
                ),
              ),
            ...widget.vouchers.map((v) {
              final isSelected =
                  _selectedCode.toUpperCase() == v.code.toUpperCase();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCode = v.code;
                    _ctrl.text = v.code;
                    _errorMsg = null;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 90,
                        height: 80,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                          ),
                          borderRadius: BorderRadius.only(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF5722)
                                  : const Color(0xFFF0EFFF),
                              width: isSelected ? 1.5 : 1,
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
                                v.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textGray,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    v.endDate == null
                                        ? ''
                                        : 'Hạn dùng: ${DateFormat('dd/MM/yyyy').format(v.endDate!)}',
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
                        onChanged: (value) {
                          setState(() {
                            _selectedCode = value ?? '';
                            _ctrl.text = value ?? '';
                            _errorMsg = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onPressed: widget.onRemove,
                    child: const Text(
                      'Bỏ chọn',
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontWeight: FontWeight.bold,
                      ),
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
                        setState(() =>
                            _errorMsg = 'Vui lòng chọn mã voucher');
                        return;
                      }
                      final selected = widget.vouchers.firstWhere(
                        (v) =>
                            v.code.toUpperCase() ==
                            _selectedCode.toUpperCase(),
                        orElse: () =>
                            const VoucherModel(code: '', label: ''),
                      );
                      if (selected.code.isEmpty) {
                        setState(() =>
                            _errorMsg = 'Mã voucher không còn khả dụng');
                        return;
                      }
                      widget.onApply(selected);
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
      ),
    );
  }
}
