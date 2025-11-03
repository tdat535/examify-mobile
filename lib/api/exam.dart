import 'dart:convert';
import 'package:http/http.dart' as http;
import 'path.dart';

class ExamApi {

  static Future<Map<String, dynamic>> getExamDetailForTeacher(String token, String examId ) async {
    final res = await http.get(Uri.parse(ApiPath.examDetailForTeacher(examId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'];
    } else {
      throw Exception('Failed to load exams: ${res.body}');
    }
  }

    static Future<Map<String, dynamic>> createExam(String token, Map<String, dynamic> examData) async {
    final res = await http.post(
      Uri.parse(ApiPath.createExam),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(examData),
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'];
    } else {
      throw Exception('Failed to load create exam: ${res.body}');
    }
  }


}
