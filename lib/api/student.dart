import 'dart:convert';
import 'package:http/http.dart' as http;
import 'path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Lấy danh sách bài thi trong lớp
  static Future<List<dynamic>> getExamsByClass({
    required String token,
    required String classId,
  }) async {
    final res = await http.get(
      Uri.parse(ApiPath.getExamsInclas(classId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'] ?? [];
    } else {
      throw Exception('Failed to load exams: ${res.body}');
    }
  }

  /// Lấy 5 bài thi mới nhất từ tất cả các lớp
  static Future<List<Map<String, dynamic>>> getRecentExams({
    required String token,
    int limit = 5,
  }) async {
    try {
      // Bước 1: Lấy danh sách tất cả các lớp
      final classes = await getClasses(token);

      if (classes.isEmpty) {
        return [];
      }

      // Bước 2: Lấy bài thi từ tất cả các lớp
      List<Map<String, dynamic>> allExams = [];

      for (var classData in classes) {
        try {
          final exams = await getExamsByClass(
            token: token,
            classId: classData['id'].toString(),
          );

          // Thêm thông tin lớp vào mỗi bài thi
          for (var exam in exams) {
            allExams.add({
              ...exam,
              'className': classData['className'],
              'classCode': classData['classCode'],
              'classId': classData['id'],
            });
          }
        } catch (e) {
          // Bỏ qua lỗi của từng lớp, tiếp tục với lớp khác
          print('Error loading exams for class ${classData['id']}: $e');
        }
      }

      // Bước 3: Sắp xếp theo thời gian tạo (mới nhất trước)
      allExams.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['createdAt']);
          final dateB = DateTime.parse(b['createdAt']);
          return dateB.compareTo(dateA); // Giảm dần (mới nhất trước)
        } catch (e) {
          return 0;
        }
      });

      // Bước 4: Lấy N bài mới nhất
      return allExams.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to load recent exams: $e');
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

  /// Nộp bài thi của học sinh
  static Future<Map<String, dynamic>> submitExam({
    required String token,
    required String examId,
    required List<Map<String, int>> answers,
  }) async {
    final body = {
      "answers": answers,
    };

    final res = await http.post(
      Uri.parse(ApiPath.submitExam(examId)),
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
      throw Exception('Failed to submit exam: ${res.body}');
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

  static Future<List<Map<String, dynamic>>> getNotifications(int studentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

}
