class UserModel {
  final String fullName;
  final String email;
  final String mobileNumber;
  final String password;

  UserModel({
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'password': password,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      fullName: json['fullName'],
      email: json['email'],
      mobileNumber: json['mobileNumber'],
      password: json['password'],
    );
  }
}