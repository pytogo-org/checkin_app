import 'dart:convert';
import 'package:checking_app/constants.dart';
import 'package:checking_app/services/token_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = Constants.baseUrl;

  Future<Map<String, dynamic>> checkInAttendee(String attendeeId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        throw 'Not authenticated';
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/api/checkregistration/$attendeeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body)['message'];

      if (response.statusCode == 200 &&
          responseData != "Registration already checked.") {
        return {'status': 'success', 'data': json.decode(response.body)};
      } else if (responseData == "Registration already checked.") {
        return {
          'status': 'already_checked_in',
          'data': json.decode(response.body),
        };
      } else {
        throw json.decode(response.body)['message'];
      }
    } catch (e) {
      rethrow;
    }
  }
}
