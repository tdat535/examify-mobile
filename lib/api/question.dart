import 'dart:convert';
import 'package:http/http.dart' as http;
import 'path.dart';

class QuestionApi {
  static Future<Map<String, dynamic>> addQuestionsToExam({
    required String token,
    required String examId,
    required List<Map<String, dynamic>> questions,
  }) async {
    final body = {
      "questionList": questions.map((q) {
        return {
          "content": q['question'],
          "answers":
              (q['options'] as List).map((opt) => {"content": opt}).toList(),
          "correctAnswerIndex": (q['correctIndex'] ?? 0) + 1,
        };
      }).toList(),
    };

    final res = await http.post(
      Uri.parse(ApiPath.addQuestion(examId)),
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
      throw Exception('Failed to add questions: ${res.body}');
    }
  }
}
