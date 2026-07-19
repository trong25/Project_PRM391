// lib/models/booking_model.dart

import 'room_model.dart';

class TypeBookingModel {
  final String typeBookingId;
  final String typeName;
  final String bookingCode;
  final int? durationHours;

  const TypeBookingModel({
    required this.typeBookingId,
    required this.typeName,
    required this.bookingCode,
    this.durationHours,
  });

  factory TypeBookingModel.fromJson(Map<String, dynamic> json) =>
      TypeBookingModel(
        typeBookingId: json['typeBookingId'] as String? ?? '',
        typeName: json['typeName'] as String? ?? '',
        bookingCode: json['bookingCode'] as String? ?? '',
        durationHours: json['durationHours'] as int?,
      );
}

class VoucherModel {
  final String code;
  final String label;
  final double discountPercent; // 0 nếu discountAmount cố định
  final double? discountAmount; // tiền giảm cố định
  final double minOrderAmount; // tổng đơn tối thiểu

  const VoucherModel({
    required this.code,
    required this.label,
    this.discountPercent = 0,
    this.discountAmount,
    this.minOrderAmount = 0,
  });

  /// Tính số tiền giảm thực tế dựa trên tổng đơn
  double calculateDiscount(double total) {
    if (total < minOrderAmount) return 0;
    if (discountAmount != null) return discountAmount!;
    return total * discountPercent / 100;
  }
}

class BookingModel {
  final int? bookingId;
  final RoomModel? room;
  final TypeBookingModel? typeBooking;
  final String roomId;
  final String userId;
  final String typeBookingId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final double? totalPrice;
  final String? status;
  final String? voucherCode;
  final double? discountAmount;
  final String? note;

  const BookingModel({
    this.bookingId,
    this.room,
    this.typeBooking,
    required this.roomId,
    required this.userId,
    required this.typeBookingId,
    required this.checkIn,
    this.checkOut,
    this.totalPrice,
    this.status,
    this.voucherCode,
    this.discountAmount,
    this.note,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final roomJson = _asMap(json['room']);
    final typeBookingJson = _asMap(json['typeBooking']);

    return BookingModel(
      bookingId: json['bookingId'] as int?,
      room: roomJson == null ? null : RoomModel.fromJson(roomJson),
      typeBooking: typeBookingJson == null
          ? null
          : TypeBookingModel.fromJson(typeBookingJson),
      roomId: roomJson?['roomId']?.toString() ?? json['roomId']?.toString() ?? '',
      userId: _asMap(json['user'])?['userId']?.toString() ??
          json['userId']?.toString() ??
          '',
      typeBookingId: typeBookingJson?['typeBookingId']?.toString() ??
          json['typeBookingId']?.toString() ??
          '',
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: json['checkOut'] != null
          ? DateTime.parse(json['checkOut'] as String)
          : null,
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      status: json['status'] as String?,
      voucherCode: json['voucherCode'] as String?,
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'room': {'roomId': roomId},
        'user': {'userId': userId},
        'typeBooking': {'typeBookingId': typeBookingId},
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut?.toIso8601String(),
        'totalPrice': totalPrice,
        'status': status ?? 'Chưa thanh toán',
        'voucherCode': voucherCode,
        'discountAmount': discountAmount,
        'note': note,
      };
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
