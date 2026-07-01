// lib/services/user_management_api.dart

import 'package:dio/dio.dart';
import '../models/user_management_model.dart';
import 'api_client.dart';

class UserManagementApi {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<UserManagementModel>> getUsers({String? roleId}) async {
    try {
      final queryParams = roleId != null ? {'roleId': roleId} : null;
      final response = await _dio.get('/users', queryParameters: queryParams);
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => UserManagementModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  Future<UserManagementModel> createUser(Map<String, dynamic> data, {String? type}) async {
    try {
      String path = '/users';
      if (type == 'STAFF') path = '/users/staff';
      if (type == 'ADMIN') path = '/users/admin';
      
      final response = await _dio.post(path, data: data);
      if (response.data['success'] == true) {
        return UserManagementModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<UserManagementModel> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/$id', data: data);
      if (response.data['success'] == true) {
        return UserManagementModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete('/users/$id');
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
