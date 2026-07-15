// lib/models/discount_code_model.dart

class DiscountCodeModel {
  final int? discountId;
  final String code;
  final String? description;
  final String discountType; // PERCENT or AMOUNT
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final int quantity;
  final String status; // Active, Expired, Disable

  DiscountCodeModel({
    this.discountId,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.quantity,
    required this.status,
  });

  factory DiscountCodeModel.fromJson(Map<String, dynamic> json) => DiscountCodeModel(
        discountId: json['discountId'] as int?,
        code: json['code'] as String? ?? '',
        description: json['description'] as String?,
        discountType: json['discountType'] as String? ?? 'PERCENT',
        discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        quantity: json['quantity'] as int? ?? 0,
        status: json['status'] as String? ?? 'Active',
      );

  double calculateDiscount(double total) {
    if (quantity <= 0 || status.toLowerCase() != 'active') return 0.0;
    final now = DateTime.now();
    if (now.isBefore(startDate) || now.isAfter(endDate)) return 0.0;

    if (discountType.toUpperCase() == 'PERCENT') {
      return total * (discountValue / 100.0);
    } else {
      return discountValue;
    }
  }
}
