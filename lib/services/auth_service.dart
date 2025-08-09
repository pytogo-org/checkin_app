import 'dart:convert';

import 'package:checking_app/constants.dart';
import 'package:checking_app/services/token_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = Constants.baseUrl;

  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final accessToken = responseData['access_token'];

        if (accessToken == null) {
          throw Exception('Token not found in response');
        }

        await TokenStorage.saveToken(accessToken);

        return accessToken;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }
}
