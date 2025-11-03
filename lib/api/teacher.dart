import 'dart:convert';
import 'package:http/http.dart' as http;
import 'path.dart';

class TeacherAPI {
  static Future<Map<String, dynamic>> getClasses(String token) async {
    final res = await http.get(
      Uri.parse(ApiPath.getClasses),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'];
    } else {
      throw Exception('Failed to load classes: ${res.body}');
    }
  }
}
