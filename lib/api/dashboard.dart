import 'dart:convert';
import 'package:http/http.dart' as http;
import 'path.dart';

class DashboardApi {
  static Future<Map<String, dynamic>> fetchDashboardData(String token) async {
    final res = await http.get(
      Uri.parse(ApiPath.dashboardData),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'];
    } else {
      throw Exception('Failed to load dashboard data: ${res.body}');
    }
  }

  static Future<List<dynamic>> fetchDashboardClasses(String token) async {
    final res = await http.get(
      Uri.parse(ApiPath.dashboardClass),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['data'] as List<dynamic>;
    } else {
      throw Exception('Failed to load dashboard classes: ${res.body}');
    }
  }
}
