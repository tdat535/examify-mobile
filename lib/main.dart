import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Authentication
import 'screens/authentication/login_screen.dart';
import 'screens/authentication/register_screen.dart';

// Student screens
import 'screens/student/student_classes_screen.dart' as student;
import 'screens/student/student_screen.dart' as student_screen;

// Teacher screens
import 'screens/teacher/dashboard_screen.dart' as teacher;
import 'screens/teacher/class_list_screen.dart' as teacher;
import 'screens/teacher/class_detail_screen.dart' as teacher;
import 'screens/teacher/notification_screen.dart' as teacher;
import 'screens/teacher/profile_screen.dart' as teacher;
import 'screens/teacher/exam_question_screen.dart' as teacher;

// Utils
import 'screens/teacher/profile_screen.dart';
import 'utils/route_observer.dart';
import 'utils/token_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(const ExamifyApp());
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Yêu cầu quyền trên iOS
    await _messaging.requestPermission();

    // Lắng nghe tin nhắn foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
      // Có thể hiện snackbar hoặc lưu vào local để hiển thị trên màn hình Notification
    });

    // Lắng nghe khi bấm notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked: ${message.notification?.title}');
      // Chuyển hướng tới màn hình nào đó
    });
  }
}

class ExamifyApp extends StatelessWidget {
  const ExamifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorSchemeSeed: const Color(0xFF7B61FF),
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.poppinsTextTheme(),
    );

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Examify App',
        theme: base.copyWith(
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
          ),
        ),
        navigatorObservers: [routeObserver],
        initialRoute: LoginScreen.routeName,
        routes: {
          // Auth
          LoginScreen.routeName: (_) => const LoginScreen(),
          RegisterScreen.routeName: (_) => const RegisterScreen(),

          // Teacher
          teacher.DashboardScreen.routeName: (_) =>
              const teacher.DashboardScreen(),
          teacher.ClassListScreen.routeName: (_) =>
              const teacher.ClassListScreen(),
          teacher.NotificationScreen.routeName: (_) => FutureBuilder<String?>(
                future: TokenStorage.getToken(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final token = snapshot.data;
                  if (token == null || token.isEmpty) {
                    return const Scaffold(
                      body: Center(child: Text('Vui lòng đăng nhập lại.')),
                    );
                  }
                  return teacher.NotificationScreen(token: token);
                },
              ),
          teacher.TeacherProfileScreen.routeName: (_) => FutureBuilder<String?>(
                future: TokenStorage.getToken(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final token = snapshot.data;
                  if (token == null) {
                    return const Scaffold(
                      body: Center(child: Text('Vui lòng đăng nhập lại.')),
                    );
                  }
                  return TeacherProfileScreen(token: token);
                },
              ),
          teacher.ExamQuestionScreen.routeName: (_) =>
              const teacher.ExamQuestionScreen(exam: {}),

          // Student
          student_screen.StudentScreen.routeName: (_) =>
              const student_screen.StudentScreen(),
        },
        onGenerateRoute: (settings) {
          // Teacher ClassDetailScreen
          if (settings.name == teacher.ClassDetailScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => teacher.ClassDetailScreen(classData: args),
            );
          }

          // StudentClassesScreen với token tự động lấy
          if (settings.name == student.StudentClassesScreen.routeName) {
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<String?>(
                future: TokenStorage.getToken(), // lấy token từ storage
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final token = snapshot.data;
                  if (token == null || token.isEmpty) {
                    return const Scaffold(
                      body: Center(
                          child: Text(
                              'Không tìm thấy token. Vui lòng đăng nhập lại.')),
                    );
                  }

                  return student.StudentClassesScreen(token: token);
                },
              ),
            );
          }

          return null;
        });
  }
}
