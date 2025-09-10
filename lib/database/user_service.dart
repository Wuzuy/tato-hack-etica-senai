import "dart:convert";
import "package:http/http.dart" as http;
import "package:tato/models/user_model.dart";

class UserService {
  final String _baseUrl =
      'https://xyladptiqj.execute-api.sa-east-1.amazonaws.com';

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Future<UserModel?> GetUserData() async {
    if (_authToken == null) {
      throw Exception("Usuário não autenticado.");
    }

    final url = Uri.parse('$_baseUrl/user');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $_authToken"},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    } else {
      throw Exception('Falha ao obter dados do usuário: ${response.body}');
    }
  }

  Future<bool> updateUserData(UserModel user) async {
    if (_authToken == null) {
      throw Exception("Usuário não autenticado.");
    }

    final url = Uri.parse('$_baseUrl/user');
    final response = await http.put(
      url,
      headers: {"Authorization": "Bearer $_authToken"},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Falha ao atualizar dados do usuário: ${response.body}');
    }
  }
}
