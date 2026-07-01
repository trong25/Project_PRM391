// lib/providers/booking_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../models/room_model.dart';
import '../services/booking_service.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final bookingServiceProvider =
    Provider<BookingService>((_) => BookingService());

// ── Voucher tĩnh (Hardcoded) ───────────────────────────────────────────────────
final availableVouchers = [
  const VoucherModel(
    code: 'GENZ10',
    label: 'Giảm 10% (tối thiểu 200k)',
    discountPercent: 10,
    minOrderAmount: 200000,
  ),
  const VoucherModel(
    code: 'CINEMA50',
    label: 'Giảm 50.000đ (tối thiểu 150k)',
    discountAmount: 50000,
    minOrderAmount: 150000,
  ),
  const VoucherModel(
    code: 'WEEKEND20',
    label: 'Giảm 20% (tối thiểu 300k)',
    discountPercent: 20,
    minOrderAmount: 300000,
  ),
  const VoucherModel(
    code: 'NEWUSER',
    label: 'Giảm 100.000đ cho khách mới',
    discountAmount: 100000,
    minOrderAmount: 100000,
  ),
];

// ── Combo types ────────────────────────────────────────────────────────────────
enum BookingComboType {
  hourly,  // Theo giờ (linh hoạt)
  day,     // Combo ngày (7h-12h)
  night,   // Combo đêm (23h-7h sáng hôm sau)
}

const Map<BookingComboType, String> comboLabels = {
  BookingComboType.hourly: 'Theo giờ',
  BookingComboType.day: 'Combo ngày',
  BookingComboType.night: 'Combo đêm',
};

// TypeBookingId tương ứng trong DB
const Map<BookingComboType, String> comboTypeBookingIds = {
  BookingComboType.hourly: 'TB_2H',    // mặc định TB_2H khi thuê giờ lẻ
  BookingComboType.day: 'TB_DAY',
  BookingComboType.night: 'TB_NIGHT',
};

// Giá combo theo loại phòng (TypeRoomId -> price) từ DB PriceConfig
const Map<String, Map<BookingComboType, double>> comboPrices = {
  'QUEEN': {
    BookingComboType.day: 196000,
    BookingComboType.night: 296000,
  },
  'KING': {
    BookingComboType.day: 246000,
    BookingComboType.night: 336000,
  },
};

// ── Booking screen state ───────────────────────────────────────────────────────
class BookingState {
  final RoomModel? room;
  final BookingComboType selectedCombo;
  final DateTime selectedDate;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final VoucherModel? appliedVoucher;
  final String note;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const BookingState({
    this.room,
    this.selectedCombo = BookingComboType.hourly,
    required this.selectedDate,
    this.checkIn,
    this.checkOut,
    this.appliedVoucher,
    this.note = '',
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  /// Tổng tiền phòng (trước giảm giá voucher)
  double get roomTotal {
    final typeRoomId =
        room?.typeRoom?.typeRoomId?.toUpperCase() ?? 'QUEEN';
    final pricePerHour = room?.typeRoom?.pricePerHour ?? 0;

    if (selectedCombo == BookingComboType.day) {
      return comboPrices[typeRoomId]?[BookingComboType.day] ??
          pricePerHour * 5;
    } else if (selectedCombo == BookingComboType.night) {
      return comboPrices[typeRoomId]?[BookingComboType.night] ??
          pricePerHour * 8;
    } else {
      // Theo giờ: tính số giờ thực tế
      if (checkIn != null && checkOut != null) {
        final hours = checkOut!.difference(checkIn!).inMinutes / 60.0;
        return (hours.clamp(1, 24) * pricePerHour).roundToDouble();
      }
      return pricePerHour * 2; // mặc định 2 giờ
    }
  }

  /// Số tiền giảm từ voucher
  double get voucherDiscount =>
      appliedVoucher?.calculateDiscount(roomTotal) ?? 0;

  /// Tổng thanh toán cuối
  double get totalPayment => (roomTotal - voucherDiscount).clamp(0, double.infinity);

  /// Mô tả giờ cho combo
  String get comboTimeDesc {
    switch (selectedCombo) {
      case BookingComboType.day:
        return '07:00 – 12:00';
      case BookingComboType.night:
        return '23:00 – 07:00 (hôm sau)';
      default:
        return '';
    }
  }

  BookingState copyWith({
    RoomModel? room,
    BookingComboType? selectedCombo,
    DateTime? selectedDate,
    DateTime? checkIn,
    DateTime? checkOut,
    VoucherModel? appliedVoucher,
    String? note,
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool clearVoucher = false,
    bool clearError = false,
    bool clearCheckOut = false,
  }) =>
      BookingState(
        room: room ?? this.room,
        selectedCombo: selectedCombo ?? this.selectedCombo,
        selectedDate: selectedDate ?? this.selectedDate,
        checkIn: checkIn ?? this.checkIn,
        checkOut: clearCheckOut ? null : (checkOut ?? this.checkOut),
        appliedVoucher:
            clearVoucher ? null : (appliedVoucher ?? this.appliedVoucher),
        note: note ?? this.note,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isSuccess: isSuccess ?? this.isSuccess,
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────────
class BookingNotifier extends StateNotifier<BookingState> {
  final BookingService _service;

  BookingNotifier(this._service)
      : super(BookingState(
          selectedDate: DateTime.now(),
          checkIn: _defaultCheckIn(),
          checkOut: _defaultCheckOut(),
        ));

  static DateTime _defaultCheckIn() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1, 0);
  }

  static DateTime _defaultCheckOut() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 3, 0);
  }

  void setRoom(RoomModel room) {
    state = state.copyWith(room: room);
  }

  void setCombo(BookingComboType combo) {
    final date = state.selectedDate;
    DateTime? cin, cout;

    switch (combo) {
      case BookingComboType.day:
        cin = DateTime(date.year, date.month, date.day, 7, 0);
        cout = DateTime(date.year, date.month, date.day, 12, 0);
        break;
      case BookingComboType.night:
        cin = DateTime(date.year, date.month, date.day, 23, 0);
        cout = DateTime(date.year, date.month, date.day + 1, 7, 0);
        break;
      case BookingComboType.hourly:
        // giữ nguyên check-in/out hiện tại
        cin = state.checkIn;
        cout = state.checkOut;
        break;
    }

    state = state.copyWith(
      selectedCombo: combo,
      checkIn: cin,
      checkOut: cout,
    );
  }

  void setDate(DateTime date) {
    final combo = state.selectedCombo;
    state = state.copyWith(selectedDate: date);
    // Re-apply combo logic với ngày mới
    setCombo(combo);
  }

  void setCheckIn(DateTime time) {
    // Chỉ cho phép thay đổi khi ở chế độ Theo giờ
    if (state.selectedCombo != BookingComboType.hourly) return;
    final date = state.selectedDate;
    final newCheckIn =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    // Đảm bảo check-out luôn sau check-in ít nhất 1 giờ
    final currentCheckOut = state.checkOut;
    final newCheckOut =
        (currentCheckOut != null && currentCheckOut.isAfter(newCheckIn))
            ? currentCheckOut
            : newCheckIn.add(const Duration(hours: 2));
    state = state.copyWith(checkIn: newCheckIn, checkOut: newCheckOut);
  }

  void setCheckOut(DateTime time) {
    if (state.selectedCombo != BookingComboType.hourly) return;
    final date = state.selectedDate;
    DateTime newCheckOut =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    // Nếu checkout <= checkin, thêm 1 ngày (qua đêm)
    if (state.checkIn != null && !newCheckOut.isAfter(state.checkIn!)) {
      newCheckOut = newCheckOut.add(const Duration(days: 1));
    }
    state = state.copyWith(checkOut: newCheckOut);
  }

  void applyVoucher(VoucherModel voucher) {
    state = state.copyWith(appliedVoucher: voucher);
  }

  void removeVoucher() {
    state = state.copyWith(clearVoucher: true);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  Future<bool> submitBooking(String userId) async {
    if (state.room == null || state.checkIn == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final booking = BookingModel(
        roomId: state.room!.roomId,
        userId: userId,
        typeBookingId:
            comboTypeBookingIds[state.selectedCombo] ?? 'TB_2H',
        checkIn: state.checkIn!,
        checkOut: state.checkOut,
        totalPrice: state.totalPayment,
        status: 'Chưa thanh toán',
        voucherCode: state.appliedVoucher?.code,
        discountAmount: state.voucherDiscount > 0
            ? state.voucherDiscount
            : null,
        note: state.note.isNotEmpty ? state.note : null,
      );
      await _service.createBooking(booking);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: 'Đặt phòng thất bại. Vui lòng thử lại!');
      return false;
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────
final bookingProvider =
    StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier(ref.read(bookingServiceProvider));
});
