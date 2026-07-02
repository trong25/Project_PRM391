// lib/models/user_management_model.dart

class UserManagementModel {
  final String userId;
  final String fullName;
  final String? phone;
  final String? email;
  final String? imageCccd;
  final String? roleId;
  final String? roleName;

  UserManagementModel({
    required this.userId,
    required this.fullName,
    this.phone,
    this.email,
    this.imageCccd,
    this.roleId,
    this.roleName,
  });

  factory UserManagementModel.fromJson(Map<String, dynamic> json) {
    return UserManagementModel(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      email: json['email'],
      imageCccd: json['imageCccd'],
      roleId: json['roleId'],
      roleName: json['roleName'],
    );
  }
}
