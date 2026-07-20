// lib/services/room_api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/room_model.dart';
import 'api_client.dart';

class RoomApiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<RoomModel>> getAllRooms() async {
    try {
      final response = await _dio.get('/rooms');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => RoomModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không tải được danh sách phòng'));
    } catch (e) {
      throw Exception('Không tải được danh sách phòng: $e');
    }
  }

  Future<List<RoomModel>> getRoomsByHotel(String hotelId) async {
    try {
      final response = await _dio.get('/rooms/hotel/$hotelId');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => RoomModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
          _messageFromDio(e, 'Không tải được phòng theo chi nhánh'));
    } catch (e) {
      throw Exception('Không tải được phòng theo chi nhánh: $e');
    }
  }

  Future<RoomModel> createRoom(RoomModel room) async {
    try {
      final response = await _dio.post('/rooms', data: room.toJson());
      if (response.data['success'] == true) {
        return RoomModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không tạo được phòng'));
    } catch (e) {
      throw Exception('Không tạo được phòng: $e');
    }
  }

  Future<RoomModel> updateRoom(String id, RoomModel room) async {
    try {
      final response = await _dio.put('/rooms/$id', data: room.toJson());
      if (response.data['success'] == true) {
        return RoomModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không cập nhật được phòng'));
    } catch (e) {
      throw Exception('Không cập nhật được phòng: $e');
    }
  }

  Future<String> uploadRoomImage(XFile image) async {
    try {
      final fileName = image.name.isNotEmpty ? image.name : 'room-image.jpg';
      final contentType = _contentTypeForFileName(fileName);
      final formData = FormData.fromMap({
        'file': kIsWeb
            ? MultipartFile.fromBytes(
          await image.readAsBytes(),
          filename: fileName,
          contentType: contentType,
        )
            : await MultipartFile.fromFile(
          image.path,
          filename: fileName,
          contentType: contentType,
        ),
      });
      final response = await _dio.post(
        '/rooms/upload-image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (response.data['success'] == true) {
        return response.data['data']?.toString() ?? '';
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không upload được ảnh phòng'));
    } catch (e) {
      throw Exception('Không upload được ảnh phòng: $e');
    }
  }

  Future<List<String>> uploadRoomImages(List<XFile> images) async {
    if (images.isEmpty) return [];

    try {
      final files = <MultipartFile>[];
      for (final image in images) {
        final fileName = image.name.isNotEmpty ? image.name : 'room-image.jpg';
        final contentType = _contentTypeForFileName(fileName);
        files.add(
          kIsWeb
              ? MultipartFile.fromBytes(
            await image.readAsBytes(),
            filename: fileName,
            contentType: contentType,
          )
              : await MultipartFile.fromFile(
            image.path,
            filename: fileName,
            contentType: contentType,
          ),
        );
      }

      final formData = FormData.fromMap({'files': files});
      final response = await _dio.post(
        '/rooms/upload-images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => e.toString()).toList();
        }
        return [];
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không upload được ảnh phòng'));
    } catch (e) {
      throw Exception('Không upload được ảnh phòng: $e');
    }
  }

  Future<void> deleteRoom(String id) async {
    try {
      await _dio.delete('/rooms/$id');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không xóa được phòng'));
    } catch (e) {
      throw Exception('Không xóa được phòng: $e');
    }
  }

  // Lấy danh mục
  Future<List<HotelModel>> getHotels() async {
    try {
      final response = await _dio.get('/hotels');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => HotelModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<HotelModel> createHotel(HotelModel hotel) async {
    try {
      final response = await _dio.post('/hotels', data: hotel.toJson());
      if (response.data['success'] == true) {
        return HotelModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Không tạo được chi nhánh'));
    } catch (e) {
      throw Exception('Không tạo được chi nhánh: $e');
    }
  }

  Future<List<TypeRoomModel>> getTypeRooms() async {
    try {
      final response = await _dio.get('/type-rooms');
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => TypeRoomModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallback;
  }

  DioMediaType? _contentTypeForFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'heic' => DioMediaType('image', 'heic'),
      'heif' => DioMediaType('image', 'heif'),
      'jpg' || 'jpeg' => DioMediaType('image', 'jpeg'),
      'png' => DioMediaType('image', 'png'),
      'webp' => DioMediaType('image', 'webp'),
      'gif' => DioMediaType('image', 'gif'),
      _ => null,
    };
  }
}
