// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/authentication/login_screen.dart';
import 'screens/teacher/dashboard_screen.dart';
import 'screens/teacher/class_list_screen.dart';
import 'screens/teacher/class_detail_screen.dart';
import 'screens/student/student_screen.dart';
import 'screens/teacher/notification_screen.dart';
import 'screens/teacher/profile_screen.dart';
import 'screens/teacher/exam_question_screen.dart';
import 'screens/authentication/register_screen.dart';

void main() {
  runApp(const ExamifyTeacherApp());
}

class ExamifyTeacherApp extends StatelessWidget {
  const ExamifyTeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorSchemeSeed: const Color(0xFF7B61FF), // primary seed
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.poppinsTextTheme(),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Examify - Teacher',
      theme: base.copyWith(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
      ),
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        DashboardScreen.routeName: (_) => const DashboardScreen(),
        StudentScreen.routeName: (_) => const StudentScreen(),
        ClassListScreen.routeName: (_) => const ClassListScreen(),
        ExamQuestionScreen.routeName: (_) => const ExamQuestionScreen(exam: {}),
        NotificationScreen.routeName: (_) => const NotificationScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == ClassDetailScreen.routeName) {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => ClassDetailScreen(classData: args ?? {}),
          );
        }
        return null;
      },
    );
  }
}
