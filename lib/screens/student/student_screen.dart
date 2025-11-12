import 'package:flutter/material.dart';
import 'student_home_screen.dart';
import 'student_classes_screen.dart';
import 'student_results_screen.dart';
import 'student_profile_screen.dart';

class StudentScreen extends StatefulWidget {
  static const routeName = '/student-screens';
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _currentIndex = 0;

  // Lấy token và studentId từ arguments hoặc storage
  String? _token;
  int? _studentId;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Lấy arguments từ route
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _token = args?['token'];
    _studentId = args?['studentId'];

    // TODO: Nếu không có args, lấy từ TokenStorage
    // if (_token == null) {
    //   _token = await TokenStorage.getToken();
    //   _studentId = await TokenStorage.getStudentId();
    // }

    _screens = [
      StudentHomeScreen(token: _token ?? '', studentId: _studentId ?? 0),
      StudentClassesScreen(token: _token ?? '', studentId: _studentId ?? 0),
      StudentResultsScreen(token: _token ?? ''),
      StudentProfileScreen(token: _token ?? ''),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF7B61FF),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_outlined),
            activeIcon: Icon(Icons.class_),
            label: 'Lớp học',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            activeIcon: Icon(Icons.assessment),
            label: 'Kết quả',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
