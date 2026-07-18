// lib/models/room_model.dart

class TypeRoomModel {
  final String typeRoomId;
  final String typeRoom;
  final double? pricePerHour;

  const TypeRoomModel({
    required this.typeRoomId,
    required this.typeRoom,
    this.pricePerHour,
  });

  factory TypeRoomModel.fromJson(Map<String, dynamic> json) => TypeRoomModel(
        typeRoomId: json['typeRoomId']?.toString() ?? '',
        typeRoom: json['typeRoom']?.toString() ??
            json['typeRoomName']?.toString() ??
            '',
        pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
      );
}

class HotelModel {
  final String hotelId;
  final String name;
  final String address;
  final String? phone;
  final String? imageUrl;

  const HotelModel({
    required this.hotelId,
    required this.name,
    this.address = '',
    this.phone,
    this.imageUrl,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) => HotelModel(
        hotelId: json['hotelId']?.toString() ?? '',
        name: json['name']?.toString() ??
            json['hotelName']?.toString() ??
            json['nameHotel']?.toString() ??
            '',
        address: json['address']?.toString() ?? '',
        phone: json['phone']?.toString(),
        imageUrl: json['imageUrl']?.toString(),
      );
}

class RoomModel {
  final String roomId;
  final String nameRoom;
  final TypeRoomModel? typeRoom;
  final HotelModel? hotel;
  final String? status;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? _typeRoomId;
  final String? _typeRoomName;
  final String? _hotelId;
  final String? _hotelName;

  const RoomModel({
    required this.roomId,
    required this.nameRoom,
    this.typeRoom,
    this.hotel,
    this.status,
    this.imageUrl,
    this.imageUrls = const [],
    String? typeRoomId,
    String? typeRoomName,
    String? hotelId,
    String? hotelName,
  })  : _typeRoomId = typeRoomId,
        _typeRoomName = typeRoomName,
        _hotelId = hotelId,
        _hotelName = hotelName;

  String? get typeRoomId => _typeRoomId ?? typeRoom?.typeRoomId;

  String? get typeRoomName => _typeRoomName ?? typeRoom?.typeRoom;

  String? get hotelId => _hotelId ?? hotel?.hotelId;

  String? get hotelName => _hotelName ?? hotel?.name;

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final typeRoomJson = _asMap(json['typeRoom']);
    final hotelJson = _asMap(json['hotel']);
    final imageUrls = _asStringList(json['imageUrls']);
    final imageUrl = json['imageUrl']?.toString();

    return RoomModel(
      roomId: json['roomId']?.toString() ?? '',
      nameRoom: json['nameRoom']?.toString() ??
          json['roomName']?.toString() ??
          json['name']?.toString() ??
          '',
      typeRoom:
          typeRoomJson == null ? null : TypeRoomModel.fromJson(typeRoomJson),
      hotel: hotelJson == null ? null : HotelModel.fromJson(hotelJson),
      typeRoomId: json['typeRoomId']?.toString(),
      typeRoomName: json['typeRoomName']?.toString(),
      hotelId: json['hotelId']?.toString(),
      hotelName: json['hotelName']?.toString(),
      status: json['status']?.toString(),
      imageUrl: imageUrl,
      imageUrls: imageUrls.isNotEmpty
          ? imageUrls
          : [
              if (imageUrl != null && imageUrl.isNotEmpty) imageUrl,
            ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (roomId.isNotEmpty) 'roomId': roomId,
      'nameRoom': nameRoom,
      'typeRoomId': typeRoomId,
      'hotelId': hotelId,
      'status': status,
      'imageUrls': imageUrls,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<String> _asStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item?.toString() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}
