// lib/providers/user_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_management_model.dart';
import '../services/user_management_api.dart';

final userApiProvider = Provider<UserManagementApi>((ref) => UserManagementApi());

final usersProvider = FutureProvider.family<List<UserManagementModel>, String?>((ref, roleId) async {
  final api = ref.watch(userApiProvider);
  return api.getUsers(roleId: roleId);
});
