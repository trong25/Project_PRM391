class RevenueBreakdown {
  final double day;
  final double week;
  final double month;
  final double lastMonth;
  final double year;

  const RevenueBreakdown({
    required this.day,
    required this.week,
    required this.month,
    required this.lastMonth,
    required this.year,
  });

  factory RevenueBreakdown.fromJson(Map<String, dynamic>? json) {
    return RevenueBreakdown(
      day: (json?['day'] as num?)?.toDouble() ?? 0,
      week: (json?['week'] as num?)?.toDouble() ?? 0,
      month: (json?['month'] as num?)?.toDouble() ?? 0,
      lastMonth: (json?['lastMonth'] as num?)?.toDouble() ?? 0,
      year: (json?['year'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RevenuePoint {
  final String label;
  final double value;

  const RevenuePoint({
    required this.label,
    required this.value,
  });

  factory RevenuePoint.fromJson(Map<String, dynamic> json) {
    return RevenuePoint(
      label: json['label']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RevenueTrends {
  final List<RevenuePoint> daysInMonth;
  final List<RevenuePoint> monthsInYear;
  final List<RevenuePoint> years;

  const RevenueTrends({
    required this.daysInMonth,
    required this.monthsInYear,
    required this.years,
  });

  factory RevenueTrends.fromJson(Map<String, dynamic>? json) {
    return RevenueTrends(
      daysInMonth: _asPointList(json?['daysInMonth']),
      monthsInYear: _asPointList(json?['monthsInYear']),
      years: _asPointList(json?['years']),
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
  final RevenueTrends trends;

  const RevenueOverview({
    required this.total,
    required this.hotels,
    required this.trends,
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
      trends: RevenueTrends.fromJson(_asStringMap(json['trends'])),
    );
  }
}

Map<String, dynamic>? _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<RevenuePoint> _asPointList(Object? value) {
  if (value is! List) return const [];
  return value
      .map(_asStringMap)
      .whereType<Map<String, dynamic>>()
      .map(RevenuePoint.fromJson)
      .toList();
}
