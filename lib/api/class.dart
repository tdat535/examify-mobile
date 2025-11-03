import 'dart:convert';
import 'package:http/http.dart' as http;
import 'path.dart';

class ClassApi {
  static Future<List<dynamic>> getClasses(String token) async {
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
      throw Exception('Failed to load class details: ${res.body}');
    }
  }

  static Future<List<dynamic>> getStudentInClass(String token, String classId) async {
    final res = await http.get(Uri.parse(ApiPath.getStudentsInClass(classId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'];
    } else {
      throw Exception('Failed to load class details: ${res.body}');
    }
  }

    static Future<List<dynamic>> getExamInClass(String token, String classId) async {
    final res = await http.get(Uri.parse(ApiPath.getExamsInclas(classId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'];
    } else {
      throw Exception('Failed to load class details: ${res.body}');
    }
  }

  static Future<Map<String, dynamic>> createClass(String token, Map<String, dynamic> classData) async {
    final res = await http.post(
      Uri.parse(ApiPath.createClass),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(classData),
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'];
    } else {
      throw Exception('Failed to load create class: ${res.body}');
    }
  }
  
}
