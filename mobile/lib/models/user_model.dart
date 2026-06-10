// lib/models/user_model.dart

class UserModel {
  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String roleId;
  final String token;

  const UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.roleId,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      userId:   json['userId']   ?? '',
      fullName: json['fullName'] ?? '',
      email:    json['email']    ?? '',
      role:     json['role']     ?? '',
      roleId:   json['roleId']   ?? '',
      token:    token,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId':   userId,
    'fullName': fullName,
    'email':    email,
    'role':     role,
    'roleId':   roleId,
    'token':    token,
  };

  UserModel copyWith({
    String? userId, String? fullName, String? email,
    String? role, String? roleId, String? token,
  }) {
    return UserModel(
      userId:   userId   ?? this.userId,
      fullName: fullName ?? this.fullName,
      email:    email    ?? this.email,
      role:     role     ?? this.role,
      roleId:   roleId   ?? this.roleId,
      token:    token    ?? this.token,
    );
  }
}