class RevenueBreakdown {
  final double day;
  final double month;
  final double year;

  const RevenueBreakdown({
    required this.day,
    required this.month,
    required this.year,
  });

  factory RevenueBreakdown.fromJson(Map<String, dynamic>? json) {
    return RevenueBreakdown(
      day: (json?['day'] as num?)?.toDouble() ?? 0,
      month: (json?['month'] as num?)?.toDouble() ?? 0,
      year: (json?['year'] as num?)?.toDouble() ?? 0,
    );
  }
}

class HotelRevenue {
  final String hotelId;
  final String hotelName;
  final RevenueBreakdown revenue;

  const HotelRevenue({
    required this.hotelId,
    required this.hotelName,
    required this.revenue,
  });

  factory HotelRevenue.fromJson(Map<String, dynamic> json) {
    return HotelRevenue(
      hotelId: json['hotelId']?.toString() ?? '',
      hotelName: json['hotelName']?.toString() ?? 'Chi nhánh',
      revenue: RevenueBreakdown.fromJson(_asStringMap(json['revenue'])),
    );
  }
}

class RevenueOverview {
  final RevenueBreakdown total;
  final List<HotelRevenue> hotels;

  const RevenueOverview({
    required this.total,
    required this.hotels,
  });

  factory RevenueOverview.fromJson(Map<String, dynamic> json) {
    final hotelsJson = json['hotels'];
    return RevenueOverview(
      total: RevenueBreakdown.fromJson(_asStringMap(json['total'])),
      hotels: hotelsJson is List
          ? hotelsJson
              .map(_asStringMap)
              .whereType<Map<String, dynamic>>()
              .map(HotelRevenue.fromJson)
              .toList()
          : const [],
    );
  }
}

Map<String, dynamic>? _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
