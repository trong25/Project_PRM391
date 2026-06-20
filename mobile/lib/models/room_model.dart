// lib/models/room_model.dart

class RoomModel {
  final String roomId;
  final String nameRoom;
  final String? typeRoomId;
  final String? typeRoomName;
  final String? hotelId;
  final String? hotelName;
  final String? status;

  RoomModel({
    required this.roomId,
    required this.nameRoom,
    this.typeRoomId,
    this.typeRoomName,
    this.hotelId,
    this.hotelName,
    this.status,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      roomId: json['roomId'] ?? '',
      nameRoom: json['nameRoom'] ?? '',
      typeRoomId: json['typeRoomId'],
      typeRoomName: json['typeRoomName'],
      hotelId: json['hotelId'],
      hotelName: json['hotelName'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'nameRoom': nameRoom,
      'typeRoomId': typeRoomId,
      'hotelId': hotelId,
      'status': status,
    };
  }
}
