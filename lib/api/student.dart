import 'dart:convert';
import 'package:http/http.dart' as http;
import 'path.dart';

class StudentAPI {
  /// Học sinh tham gia vào lớp bằng mã lớp
  static Future<Map<String, dynamic>> joinClass({
    required String token,
    required int studentId,
    required String classCode,
  }) async {
    final body = {
      "studentId": studentId,
      "classCode": classCode,
    };

    final res = await http.post(
      Uri.parse(ApiPath.studentJoinClass),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded;
    } else {
      throw Exception('Failed to join class: ${res.body}');
    }
  }

  /// Lấy danh sách lớp học của học sinh
  static Future<List<dynamic>> getClasses(String token) async {
    final res = await http.get(
      Uri.parse(ApiPath.studentGetClasses),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'] ?? [];
    } else {
      throw Exception('Failed to load classes: ${res.body}');
    }
  }

  /// Lấy chi tiết đề thi cho học sinh (không có đáp án đúng)
  static Future<Map<String, dynamic>> getExamDetailForStudent({
    required String token,
    required String examId,
  }) async {
    final res = await http.get(
      Uri.parse(ApiPath.examDetailForStudent(examId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'];
    } else {
      throw Exception('Failed to load exam detail: ${res.body}');
    }
  }

  /// Lấy kết quả thi của học sinh
  static Future<List<dynamic>> getExamResults(String token) async {
    final res = await http.get(
      Uri.parse(ApiPath.examResults),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'] ?? [];
    } else {
      throw Exception('Failed to load exam results: ${res.body}');
    }
  }
}
