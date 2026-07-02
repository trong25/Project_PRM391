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
        typeRoomId: json['typeRoomId'] as String? ?? '',
        typeRoom: json['typeRoom'] as String? ?? '',
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
    required this.address,
    this.phone,
    this.imageUrl,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) => HotelModel(
        hotelId: json['hotelId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );
}

class RoomModel {
  final String roomId;
  final String nameRoom;
  final TypeRoomModel? typeRoom;
  final String? status;
  final HotelModel? hotel;
  final String? imageUrl;

  const RoomModel({
    required this.roomId,
    required this.nameRoom,
    this.typeRoom,
    this.status,
    this.hotel,
    this.imageUrl,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        roomId: json['roomId'] as String? ?? '',
        nameRoom: json['nameRoom'] as String? ?? '',
        typeRoom: json['typeRoom'] != null
            ? TypeRoomModel.fromJson(json['typeRoom'] as Map<String, dynamic>)
            : null,
        status: json['status'] as String?,
        hotel: json['hotel'] != null
            ? HotelModel.fromJson(json['hotel'] as Map<String, dynamic>)
            : null,
        imageUrl: json['imageUrl'] as String?,
      );
}
