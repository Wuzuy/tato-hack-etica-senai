import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tato/database/models/user_model.dart';

class AuthService {
  final String _baseUrl =
      'https://xyladptiqj.execute-api.sa-east-1.amazonaws.com';

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
      final url = Uri.parse('$_baseUrl/login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserModel.fromJson(data['user']);
      } else {
        throw Exception('Falha ao fazer login');
      }
  }
}
