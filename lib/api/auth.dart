import 'dart:convert';
import 'package:http/http.dart' as http;
import 'path.dart';

class AuthAPI {
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final res = await http.post(
      Uri.parse(ApiPath.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Đăng nhập thất bại (${res.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> register(
      String username, String password, String email, String role) async {
    final res = await http.post(
      Uri.parse(ApiPath.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        'roleId': role,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Đăng nhập thất bại (${res.body})');
    }
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final res = await http.get(
      Uri.parse(ApiPath.profile),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'];
    } else {
      throw Exception('Failed to load profile: ${res.body}');
    }
  }

  static Future<Map<String, dynamic>> editProfile(
      String token, String realName, String email, String phone) async {
    final res = await http.put(
      Uri.parse(ApiPath.editProfile),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'realName': realName,
        'email': email,
        'phone': phone,
      }),
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'];
    } else {
      throw Exception('Failed to edit profile: ${res.body}');
    }
  }

  static Future<Map<String, dynamic>> socialLogin({
    required String name,
    required String email,
    required String provider,
    required String providerId,
    String? roleId,
  }) async {
    final res = await http.post(
      Uri.parse(ApiPath.social),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'provider': provider,
        'providerId': providerId,
        'roleId': roleId,
      }),
    );

    print('--- socialLogin HTTP response ---');
    print('Status code: ${res.statusCode}');
    print('Headers: ${res.headers}');
    print('Body: ${res.body}');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception(
          'Failed to login with $provider: ${res.statusCode} ${res.body}');
    }
  }
}
