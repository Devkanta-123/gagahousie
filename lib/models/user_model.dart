class UserModel {
  final dynamic id;
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String status;
  final String role;
  final DateTime? createdAt;

  UserModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    this.status = 'active',
    this.role = 'user',
    this.createdAt,
  });

  /// Backward-compatible alias for mobileNumber
  String get mobileNumber => phone;

  /// Helper to check if account is active
  bool get isActive => status.toLowerCase() == 'active';

  /// Helper to check if user has admin role
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Helper to check if user has standard user role
  bool get isUser => role.toLowerCase() == 'user';

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'fullname': fullName,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'mobileNumber': phone,
      'password': password,
      'status': status,
      'role': role,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final email = json['email'] ?? '';
    final defaultRole = email == 'admin@gmail.com' ? 'admin' : 'user';

    return UserModel(
      id: json['id'],
      fullName: json['fullname'] ?? json['fullName'] ?? '',
      email: email,
      phone: json['phone'] ??
          json['mobileNumber'] ??
          json['phone_no'] ??
          json['mobile'] ??
          '',
      password: json['password'] ?? '',
      status: json['status'] ?? json['account_status'] ?? 'active',
      role: json['role'] ?? defaultRole,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  UserModel copyWith({
    dynamic id,
    String? fullName,
    String? email,
    String? phone,
    String? password,
    String? status,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      status: status ?? this.status,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
