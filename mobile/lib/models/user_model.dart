// lib/models/user_model.dart

class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String roleId;
  final String token;

  const UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.roleId,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      userId:   json['userId']   ?? '',
      fullName: json['fullName'] ?? '',
      email:    json['email']    ?? '',
      phone:    json['phone']    ?? '',
      role:     json['role']     ?? '',
      roleId:   json['roleId']   ?? '',
      token:    token,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId':   userId,
    'fullName': fullName,
    'email':    email,
    'phone':    phone,
    'role':     role,
    'roleId':   roleId,
    'token':    token,
  };

  UserModel copyWith({
    String? userId, String? fullName, String? email, String? phone,
    String? role, String? roleId, String? token,
  }) {
    return UserModel(
      userId:   userId   ?? this.userId,
      fullName: fullName ?? this.fullName,
      email:    email    ?? this.email,
      phone:    phone    ?? this.phone,
      role:     role     ?? this.role,
      roleId:   roleId   ?? this.roleId,
      token:    token    ?? this.token,
    );
  }
}