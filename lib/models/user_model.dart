class UserModel {
  final String id;
  final String email;
  final String password;

  UserModel({required this.id, required this.email, required this.password});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'password': password};
  }
}
