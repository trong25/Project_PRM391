// lib/models/hotel_model.dart

class HotelModel {
  final String hotelId;
  final String name;

  HotelModel({required this.hotelId, required this.name});

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      hotelId: json['hotelId'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

// lib/models/type_room_model.dart

class TypeRoomModel {
  final String typeRoomId;
  final String typeRoom;

  TypeRoomModel({required this.typeRoomId, required this.typeRoom});

  factory TypeRoomModel.fromJson(Map<String, dynamic> json) {
    return TypeRoomModel(
      typeRoomId: json['typeRoomId'] ?? '',
      typeRoom: json['typeRoom'] ?? '',
    );
  }
}
